# Coupled Transactions
## Overview
After several iterations of trial and error, I write code to update two databases while keeping them in sync.

## Background
We're writing an application in Typescript.  We have two Postgres databases that we want to keep in sync for the tables that they have in common.  I'll refer to them as our main database and our synced database.

The synced database contains all the tables that our main database has plus other tables that our application won't be touching.  We want to update the main database live while keeping the synced database identical.

We are also assuming that other applications keep the databases in sync which may be a dangerous assumption. This smells like bad architecture design but due to deadline constraints, we didn't have the option to explore changing the architecture.

## Approach
My initial idea was to use transactions.  We could start a transaction in each of the databases and do the insert/update/delete in both databases.  Then we would wait until the changes completed in both databases before committing both transactions.

## Failure Coupling Transactions with pg (stands for Postgres not Pau Gasol or Paul Graham)
We were already using the pg library and we had a `DB` class.

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

We had two DB objects to represent our two databases and all inserts/updates/deletes were being called through an execSetter() function:
    async function execSetter(setter: (db: DB, client: pg.Client) => Promise<void>): Promise<void>()

I added these methods to our DB class.

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

Then I implemented the execSetter() function as a coupled transaction:

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

Naively, I ran it and assumed it worked since it worked on a local test run.

Of course, as soon as we ran the application on multiple games we started running into issues where our pool ran out of connections and our application was deadlocked. (Our application was updating the database for applications downstream based on data from the NBA so it was running live from the NBA's PBP data.)

After a well deserved lecture on the dangers of calling `begin`, `commit`, and `rollback` directly from the Typescript code and the multitude of issues with the testibility and design of the code in which wisdom was bestowed upon me, I went ahead and refactored all the database code using Knex.

## First Pass with Knex

    export class DB {
      dbConn: Knex;
      syncedDBConn: Knex; // DB to keep in sync

      constructor(params: types.DBParams, syncedParams?: types.DBParams) {
        this.dbConn = conn.conn(params);
        if (syncedParams) {
          this.syncedDBConn = conn.conn(syncedParams);
        }
      }
      // ...
    }

		async doubleTransaction(
			fn: (trx: Knex.Transaction, table: string, target: object) => Promise<void>,
			table: string,
			target: object,
		): Promise<void> {
			await this.dbConn.transaction(async trx => {
				try {
					await fn(trx, table, target);
				} catch (err) {
					logger.error(`Transaction error ${err}`);
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

## Miscellaneous Thoughts
We were also using prepared statements before refactoring.
