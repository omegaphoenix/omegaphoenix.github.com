use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :the_juice, TheJuice.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :the_juice, TheJuice.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "the_juice_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Don't spend too much time encrypting password for tests
config :comeonin, bcrypt_log_rounds: 4
