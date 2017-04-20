start:
	@mix phoenix.server

start-interactive:
	@iex -s mix phoenix.server

remigrate:
	@mix ecto.migrate

install:
	@mix deps.get
	@mix deps.compile
	@npm install

createdb:
	@mix ecto.create
