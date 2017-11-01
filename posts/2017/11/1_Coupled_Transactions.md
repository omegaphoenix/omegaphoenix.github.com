# Coupled Transactions
## Overview
After several iterations of trial and error, I write code to update two databases while keeping them in sync.

## Background
We're writing an application in Typescript.  We have two Postgres databases that we want to keep in sync for the tables that they have in common.  I'll refer to them as our main database and our synced database.

The synced database contains all the tables that our main database has plus other tables that our application won't be touching.  We want to update the main database live while keeping the synced database identical.

We are also assuming that other applications keep the databases in sync which may be a dangerous assumption. This smells like bad architecture design but due to deadline constraints, we didn't have the option to explore changing the architecture.

## Approach
My initial idea was to use transactions.  We could start a transaction in each of the databases and do the insert/update/delete in both databases.  Then we would wait until the changes completed in both databases before committing both transactions.

## Failure Coupling Transactions with pg
*pg stands for Postgres not Pau Gasol or Paul Graham*

We were already using the pg library and we had a `DB` class.

```typescript
export class DB {
  pool: pg.Pool;

  constructor(dbConfig: types.DbConfig) {
    this.pool = new pg.Pool(dbConfig);
  }

  async run(fn: (client: pg.Client) => Promise<any>, txClient?: pg.Client): Promise<any> {
    const client = txClient || (await this.pool.connect());

    try {
      return await fn(client);
    } finally {
      if (!txClient) {
        client.release();
      }
    }
  }

  async tx(fn: (client: pg.Client) => Promise<any>): Promise<void> {
    const client = await this.pool.connect();

    try {
      await client.query('begin');
      await fn(client);
      await client.query('commit');
    } catch (e) {
      await client.query('rollback');
      console.error('we are rolling back a transaction. this SHOULD NOT HAPPEN and is SERIOUS!!');
      throw e;
    } finally {
      client.release();
    }
  }
}
```

We had two DB objects to represent our two databases and all inserts/updates/deletes were being called through an execSetter() function:
    async function execSetter(setter: (db: DB, client: pg.Client) => Promise<void>): Promise<void>()

I added these methods to our DB class.

```typescript
  async startTx(): Promise<pg.Client> {
    const client = await this.pool.connect();
    await client.query('begin');
    return client;
  }

  async doTx(client: pg.Client, fn: (client: pg.Client) => Promise<any>): Promise<void> {
    await fn(client);
  }

  async commitTx(client: pg.Client): Promise<void> {
    client.query('commit');
  }

  async rollbackTx(client: pg.Client): Promise<void> {
    client.query('rollback');
  }
```

Then I implemented the execSetter() function as a coupled transaction:

```typescript
// DBS is an array of two database objects
async function execSetter(setter: (db: DB, client: pg.Client) => Promise<void>): Promise<void> {
  const dbClients = await bluebird.map(DBS, async db => {
    return { db, client: await db.startTx() };
  });
  try {
    await bluebird.each(
      dbClients,
      async dbClient =>
        await dbClient.db.doTx(dbClient.client, async (client: pg.Client) => {
          await setter(dbClient.db, client);
        })
    );

    // Commit if they worked
    await bluebird.each(dbClients, async dbClient => await dbClient.db.commitTx(dbClient.client));
  } catch (err) {
    await bluebird.each(dbClients, async dbClient => await dbClient.db.rollbackTx(dbClient.client));
  } finally {
    await bluebird.each(dbClients, async dbClient => await dbClient.client.release);
  }
}
```

Naively, I ran it and assumed it worked since it worked on a local test run.

Of course, as soon as we ran the application on multiple games we started running into issues where our pool ran out of connections and our application was deadlocked. (Our application was updating the database for applications downstream based on data from the NBA so it was running live from the NBA's play-by-play data.)

After a well deserved lecture on the dangers of calling `begin`, `commit`, and `rollback` directly from the Typescript code and the multitude of issues with the testibility and design of the code in which golden nuggets of wisdom were bestowed upon me, I went ahead and refactored all the database code using Knex. The idea was that even if this didn't solve our root issue, it would be much easier to debug.

The databases would probably deadlock on the startTx() call since the order in which the database connections were established was not guaranteed.

## First Pass with Knex
Refactoring the code to use Knex really cleaned up the codebase. Although our first approach theoretically allowed us to sync any number of databases (assuming we didn't run into deadlock), syncing more databases probably indicates a need for an architectural redesign.  This time we kept all database connections within a single class.

```typescript
export class DB {
  dbConn: Knex;
  syncedDBConn: Knex; // DB to keep in sync

  constructor(params: types.DBParams, syncedParams?: types.DBParams) {
    this.dbConn = conn.conn(params);
    if (syncedParams) {
      this.syncedDBConn = conn.conn(syncedParams);
    }
  }

  async doubleTransaction(
    fn: (trx: Knex.Transaction, table: string, target: object) => Promise<void>,
    table: string,
    target: object
  ): Promise<void> {
    await this.dbConn.transaction(async trx => {
      try {
        logger.error(`Transaction error ${err}`);
        await fn(trx, table, target);
      } catch (err) {
        throw err;
      }

      await this.syncedDBConn.transaction(async syncedTrx => {
        try {
          await fn(syncedTrx, table, target);
        } catch (err) {
          logger.error(`Transaction error ${err}`);
          throw err;
        }
      });
    });
  }

  async insert(table: string, toInsert: object): Promise<void> {
    this.doubleTransaction(this.insertDB, table, toInsert);
  }

  private async insertDB(trx: Knex.Transaction, table: string, toInsert: object): Promise<void> {
    logger.warn(`Inserting ${table} ${JSON.stringify(toInsert)}`);
    await trx.insert(toInsert).into(table);
  }

  // getters, update, and delete methods omitted
}
```

Looking at the code now, this would have failed without the `syncedParams` passed into the constructor so that shouldn't be optional unless we had a check in the `doubleTransaction()` function for `syncedDBConn` being undefined.

When putting high load on the system, however, we were still running into a timeout issue:

`UnhandledPromiseRejectionWarning: Unhandled promise rejection (rejection id: 1): TimeoutError: Knex: Timeout acquiring a connection. The pool is probably full. Are you missing a .transacting(trx) call?`

## More Refactoring and Current Solution
I tried using a semaphore to avoid deadlock by decrementing the semaphore before any get or exec call.  Although I ended up not using the semaphore code since it seemed to conflict with asynchronous design.  From logging the times that our database queries were taking (on the suggestion of Eric, our VP of Engineering), we noticed that our select queries started taking minutes to complete possibly because we were hammering the database. Caching our select queries reduced our database accesses by several orders of magnitude.

Also, my CTO, Jeff, and a co-worker/contractor, Myron, helped code review the coupled transaction code. They suggested passing in 2 functions to make the code more testable.  They also suggested using a closure or bind instead of passing in the transaction. Now I was able to test the code by passing in one good transaction and one bad one to make sure that it would error and roll back the transactions in both databases.

By caching our select queries, we no longer ran into the Knex connection timeout but we added an exponential backoff in the exec function in case we did run into this issue again.  I think we still have a problem where exec is called after starting a transaction so the backoff is only effective at throttling the select queries which is wrong.

Here is our code after all those changes:

```typescript
export type sqlTransaction = (trx: knex.Transaction) => Promise<void>;

export class DB {
	\\ ...
  async exec<T>(fn: bluebird<T>, backoff: number = 1): Promise<T> {
    let result: T | undefined = undefined;
    await new Promise(async (resolve, reject) => {
      try {
        result = await fn;
        resolve();
      } catch (err) {
        if (err.message !== undefined && err.message.includes('Knex: Timeout acquiring a connection.')) {
          // If we get this error, we already waited at least 2 minutes for a connection.
          logger.error(`Timeout Level ${backoff}: ${err.message}`);

          const exponentialBackoff = Math.floor(Math.random() * Math.pow(2, backoff)) * MILSEC_PER_SEC;
          await bluebird.delay(exponentialBackoff);

          // Maximum wait time is 2^10 = 1024 seconds
          result = await this.exec<T>(fn, Math.min(backoff + 1, 10));
          resolve();
        } else {
          reject(err);
        }
      }
    });

    if (backoff > 1) {
      logger.warn(`Completed with timeout level ${backoff}`);
    }
    return undefToNull(result) as T;
  }

  async doubleTransaction(fn: sqlTransaction, syncedFn: sqlTransaction = fn): Promise<void> {
    try {
      const transactions = this.dbConn.transaction(async trx => {
        const p1 = fn(trx);
        const p2 = this.syncedDBConn.transaction(async syncedTrx => {
          try {
            await syncedFn(syncedTrx);
          } catch (err) {
            logger.error(`Second (synced) database ${err}`);
            throw `Second (synced) database ${err}`;
          }
        });

        return Promise.all([p1, p2]);
      });

      await this.exec<void>(transactions);
    } catch (err) {
      logger.error(`Transaction error - ${err}`);
      throw err;
    }
  }

 async insert(table: string, toInsert: object): Promise<void> {
    if (!config.WRITE_CANONICAL) {
      logger.warn('Not writing to canonical. We will miss inserts');
      return;
    }

    const fn = async (trx: knex.Transaction) => {
      await this.insertDB(table, toInsert, trx);
    };
    await this.doubleTransaction(fn);
  }

  private async insertDB(table: string, toInsert: object, trx: knex.Transaction): Promise<void> {
    logger.info(`Inserting ${table} ${JSON.stringify(toInsert)}`);
    await trx.insert(toInsert).into(table);
  }

}
```

## Miscellaneous
In the process of refactoring, I also removed the prepared statements that we were using which might have been a premature optimization anyways.

Do the scars(edge cases) in our battle tested code make it more or less beautiful?  I once read an article against nuking everything and rewriting it even though it may be ugly because of all the edge cases and errors that it has run into.  The author argued that refactoring it was a much better option.  Even as code gets cleaned up elegantly, the extra code for protecting against edge cases still makes the code more clunky but helps people sleep at night.

It was a great learning experience and fun being on call 24/7 for a piece of code you maintain.  It's great motivation to make it handle error cases well and extra motivation to write testable code and use good practices such as stricter code reviews.  It also helps me sleep at night.

Thanks to Bill, who wrote the original code, and Eric, Jeff, and Myron, whom all weighed in on our bugs and code on different points in the process.

Kareem Abdul-Jabbar (Lew Alcindor) perfected his skyhook through practicing the Mikan drill.  He would slowly move further away from the basket as he warmed up.
