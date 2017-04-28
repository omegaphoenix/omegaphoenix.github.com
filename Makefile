start:
	@mix phoenix.server

start-interactive:
	@iex -s mix phoenix.server

remigrate:
	@mix ecto.migrate

routes:
	@mix phoenix.routes

install:
	@mix deps.get
	@mix deps.compile
	@npm install

createdb:
	@mix ecto.create
