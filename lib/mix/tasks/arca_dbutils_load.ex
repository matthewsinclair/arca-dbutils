defmodule Mix.Tasks.Arca.Dbutils.Load do
  use Mix.Task
  import Arca.Dbutils.Helper

  @shortdoc "Loads a previously dumped SQL file into the DB (mix arca.dbutils.load)"

  @moduledoc """
  Loads a .sql file into a PostgreSQL database using `Arca.Dbutils.Dumper.load/1`.

  ## Usage

      mix arca.dbutils.load [options]

  Common options:
    - `file=path/to/file.sql` (the SQL file to load)
    - `host=...`, `user=...`, `password=...`, `dbname=...`
    - `url=postgres://...` (overrides individual host/user/password/dbname)

  For example:

      mix arca.dbutils.load file=some_dump.sql host=localhost user=postgres password=secret dbname=my_db
      mix arca.dbutils.load url=postgres://postgres:secret@localhost/my_db file=some_dump.sql

  Pass `-h` or `--help` to see this usage text.
  """

  def run(args) do
    if Enum.any?(args, &(&1 in ["-h", "--help"])) do
      print_help()
      exit(:normal)
    end

    # Parse "key=value" style arguments if any
    opts = parse_args(args)

    # Ensure the application is started so our code is loaded
    Mix.Task.run("app.start")

    case Arca.Dbutils.Dumper.load(opts) do
      {:ok, :loaded} ->
        Mix.shell().info("Load completed successfully.")

      {:error, :psql_not_found} ->
        Mix.shell().error("Error: `psql` not found on PATH.")

      {:error, :psql_failed} ->
        Mix.shell().error("Error: psql command failed. See above output for details.")

      {:error, msg} when is_binary(msg) ->
        # e.g. "Missing SQL file" or "Missing database password"
        Mix.shell().error("Error: #{msg}")
    end
  end

  defp print_help() do
    IO.puts("""
    mix arca.dbutils.load [options]

    Loads a .sql file into a PostgreSQL database.

    Options:
      file=some_dump.sql
      host=...
      user=...
      password=...
      dbname=...
      url=postgres://...

    Example usage:
      mix arca.dbutils.load file=some_dump.sql host=localhost user=postgres password=secret dbname=my_db
      mix arca.dbutils.load url=postgres://postgres:secret@localhost/my_db file=some_dump.sql
    """)
  end
end
