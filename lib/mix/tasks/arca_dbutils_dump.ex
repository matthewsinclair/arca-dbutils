defmodule Mix.Tasks.Arca.Dbutils.Dump do
  use Mix.Task
  import Arca.Dbutils.Helper

  @shortdoc "Dumps the Postgres DB (mix arca.dbutils.dump)"

  @moduledoc """
  Dumps the PostgreSQL database to a timestamped SQL file.

  ## Usage

      mix arca.dbutils.dump [options]

  Available environment variables:
    DB_HOST, DB_USER, DB_PASSWORD, DB_NAME

  You can also pass them as arguments, e.g.:

      mix arca.dbutils.dump host=myhost user=admin password=secret dbname=my_db

  Pass `-h` or `--help` to see this usage.
  """

  def run(args) do
    if Enum.any?(args, &(&1 in ["-h", "--help"])) do
      print_help()
      exit(:normal)
    end

    # Parse "key=value" style arguments if any
    opts = parse_args(args)

    # Start the application so our code is loaded
    Mix.Task.run("app.start")

    case Arca.Dbutils.Dumper.dump(opts) do
      {:ok, filename} ->
        Mix.shell().info("✅ #{filename}")

      {:error, :pg_dump_not_found} ->
        Mix.shell().error("Error: `pg_dump` not found.")

      {:error, :pg_dump_failed} ->
        Mix.shell().error("Error: Database dump failed (pg_dump error).")

      {:error, msg} when is_binary(msg) ->
        Mix.shell().error("Error: #{msg}")
    end
  end

  defp print_help() do
    IO.puts("""
    mix arca.dbutils.dump [options]

    Dumps the PostgreSQL database to a timestamped SQL file.
    All parameters can be passed via environment variables or via CLI:

      host=...
      user=...
      password=...
      dbname=...

    Environment variables used if these aren’t provided:
      DB_HOST, DB_USER, DB_PASSWORD, DB_NAME

    Example usage:
      mix arca.dbutils.dump host=localhost user=postgres password=my_pass dbname=my_db

    """)
  end
end
