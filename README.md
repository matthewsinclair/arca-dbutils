# Arca Dbutils

Arca Dbutils is a set of simple database utilities for Elixir projects, focused on PostgreSQL database operations.

## Features

- Dump PostgreSQL databases to SQL files with timestamp and hostname
- Load SQL dumps into databases
- Support for both URL-style and individual parameter configuration
- Environment variable support
- Mix tasks for easy command-line usage

## Requirements

- Elixir ~> 1.18
- PostgreSQL client tools (`pg_dump` and `psql` commands must be available on PATH)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `arca_dbutils` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:arca_dbutils, "~> 0.1.0"}
  ]
end
```

## Usage

### Dumping a database

Via mix task:
```bash
# Using individual parameters
mix arca.dbutils.dump host=localhost user=postgres password=secret dbname=my_db

# Using a database URL
mix arca.dbutils.dump url=postgres://postgres:secret@localhost/my_db
```

Programmatically:
```elixir
# Using individual parameters
Arca.Dbutils.Dumper.dump(host: "localhost", user: "postgres", password: "secret", dbname: "my_db")

# Using a database URL
Arca.Dbutils.Dumper.dump(url: "postgres://postgres:secret@localhost/my_db")
```

### Loading a database

Via mix task:
```bash
# Using individual parameters
mix arca.dbutils.load file=dump.sql host=localhost user=postgres password=secret dbname=my_db

# Using a database URL
mix arca.dbutils.load file=dump.sql url=postgres://postgres:secret@localhost/my_db
```

Programmatically:
```elixir
# Using individual parameters
Arca.Dbutils.Dumper.load(file: "dump.sql", host: "localhost", user: "postgres", password: "secret", dbname: "my_db")

# Using a database URL
Arca.Dbutils.Dumper.load(file: "dump.sql", url: "postgres://postgres:secret@localhost/my_db")
```

### Environment Variables

You can also use environment variables:
- `DB_URL` - Full database URL
- `DB_HOST` - Database host
- `DB_USER` - Database username
- `DB_PASSWORD` - Database password
- `DB_NAME` - Database name
- `DB_FILE` - SQL file path (for load operations)

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/arca_dbutils>.
