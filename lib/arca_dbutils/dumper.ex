defmodule Arca.Dbutils.Dumper do
  @moduledoc """
  Provides database dumping and loading functions using `pg_dump` and `psql`.

  ## Public API

    * `dump(opts)` - dumps a DB to a .sql file
    * `load(opts)` - loads a .sql file into a DB

  Both share the same approach to config (URL or env-based),
  use a spinner, and return `{:ok, value}` or `{:error, reason}`.
  """

  # ------------------------------------------------------------------
  # DUMP
  # ------------------------------------------------------------------

  @doc """
  Dumps the database to a `.sql` file using `pg_dump`.

  Expects either a full DB URL or individual params in `opts`:

    * `:url` (overrides other params)
    * `:host`
    * `:user`
    * `:password`
    * `:dbname`
    * `:port` (optional)

  Returns:
    * `{:ok, filename}` on success
    * `{:error, reason}` on failure
  """
  @type dump_opts :: [
          url: String.t(),
          host: String.t(),
          user: String.t(),
          password: String.t(),
          dbname: String.t(),
          port: non_neg_integer() | nil
        ]
  @spec dump(dump_opts()) :: {:ok, String.t()} | {:error, atom() | String.t()}
  def dump(opts \\ []) do
    # 1) Ensure pg_dump is installed
    case System.find_executable("pg_dump") do
      nil ->
        # Could either print here or let the caller handle printing
        IO.puts("Error: `pg_dump` not found on your PATH.")
        {:error, :pg_dump_not_found}

      pg_dump_path ->
        # 2) Gather DB config
        db_config = fetch_db_config(opts)

        # 3) Check required
        case check_required(db_config) do
          :ok ->
            do_dump(pg_dump_path, db_config)

          {:error, msg} ->
            # IO.puts("Error: #{msg}")
            {:error, msg}
        end
    end
  end

  defp do_dump(pg_dump_path, db_config) do
    # Show start message
    redacted_url = build_redacted_url(db_config)
    IO.puts(redacted_url)

    # Start spinner
    spinner_pid = start_spinner("")

    # Build output filename
    filename = build_filename(db_config.dbname)

    # Build arguments
    cmd_args = build_dump_args(db_config, filename)
    env_vars = [{"PGPASSWORD", db_config.password}]

    # Run pg_dump
    {output, exit_status} =
      System.cmd(pg_dump_path, cmd_args, env: env_vars, stderr_to_stdout: true)

    # Process.sleep(2000)

    # Stop spinner
    stop_spinner(spinner_pid)

    # Check results
    if exit_status == 0 do
      # IO.puts("✅ #{filename}")
      {:ok, filename}
    else
      IO.puts("❌ pg_dump failed with exit code #{exit_status}")
      IO.puts("Output: #{output}")
      {:error, :pg_dump_failed}
    end
  end

  defp build_dump_args(db_config, filename) do
    base = [
      "-h",
      db_config.host,
      "-U",
      db_config.user,
      "-f",
      filename,
      "--no-owner",
      "--no-privileges"
    ]

    base =
      if db_config.port do
        base ++ ["-p", to_string(db_config.port)]
      else
        base
      end

    base ++ [db_config.dbname]
  end

  # ------------------------------------------------------------------
  # LOAD
  # ------------------------------------------------------------------

  @doc """
  Loads a `.sql` file into the database using `psql`.

  Expects either a full DB URL or individual params in `opts`:

    * `:url` (overrides other params)
    * `:host`
    * `:user`
    * `:password`
    * `:dbname`
    * `:port` (optional)

  Also requires:

    * `:file` - path to the SQL file (or env var DB_FILE)

  Returns:
    * `{:ok, :loaded}` on success
    * `{:error, reason}` on failure
  """
  @type load_opts :: [
          url: String.t(),
          host: String.t(),
          user: String.t(),
          password: String.t(),
          dbname: String.t(),
          port: non_neg_integer() | nil,
          file: String.t()
        ]
  @spec load(load_opts()) :: {:ok, :loaded} | {:error, atom() | String.t()}
  def load(opts \\ []) do
    # 1) Ensure psql is installed
    case System.find_executable("psql") do
      nil ->
        IO.puts("Error: `psql` not found on your PATH.")
        {:error, :psql_not_found}

      psql_path ->
        # 2) Gather DB config
        db_config = fetch_db_config(opts)

        # 3) Check required
        case check_required(db_config) do
          :ok ->
            do_load(psql_path, db_config, opts)

          {:error, msg} ->
            # IO.puts("Error: #{msg}")
            {:error, msg}
        end
    end
  end

  defp do_load(psql_path, db_config, opts) do
    # Check for file
    file = Keyword.get(opts, :file, System.get_env("DB_FILE"))

    if is_nil(file) or file == "" do
      IO.puts("Error: Missing SQL file to load.")
      {:error, "Missing SQL file"}
    else
      # Check if file exists
      unless File.exists?(file) do
        IO.puts("Error: SQL file '#{file}' does not exist.")
        {:error, "SQL file does not exist"}
      else
        # Show start message
        redacted_url = build_redacted_url(db_config)
        IO.puts("Starting database load from file. Using DB URL: #{redacted_url}")

        spinner_pid = start_spinner("Loading database...")

        # Build psql args
        cmd_args = build_load_args(db_config, file)
        env_vars = [{"PGPASSWORD", db_config.password}]

        {output, exit_status} =
          System.cmd(psql_path, cmd_args, env: env_vars, stderr_to_stdout: true)

        stop_spinner(spinner_pid)

        if exit_status == 0 do
          # IO.puts("✅ Successfully loaded data from #{file}")
          # IO.puts("Done.")
          {:ok, :loaded}
        else
          IO.puts("❌ psql failed with exit code #{exit_status}")
          IO.puts("Output: #{output}")
          # IO.puts("Done.")
          {:error, :psql_failed}
        end
      end
    end
  end

  defp build_load_args(db_config, file) do
    base = [
      "-h",
      db_config.host,
      "-U",
      db_config.user,
      "-d",
      db_config.dbname,
      "-f",
      file
    ]

    if db_config.port do
      base |> List.insert_at(2, "-p") |> List.insert_at(3, to_string(db_config.port))
    else
      base
    end
  end

  # ------------------------------------------------------------------
  # Shared Helper Functions
  # ------------------------------------------------------------------

  # Gathers DB config from opts or env. If `:url` is present, parse it; else fallback to individual keys.
  defp fetch_db_config(opts) do
    url = Keyword.get(opts, :url, System.get_env("DB_URL"))

    if url do
      parse_db_url(url)
    else
      %{
        host: Keyword.get(opts, :host, System.get_env("DB_HOST")),
        user: Keyword.get(opts, :user, System.get_env("DB_USER")),
        password: Keyword.get(opts, :password, System.get_env("DB_PASSWORD")),
        dbname: Keyword.get(opts, :dbname, System.get_env("DB_NAME")),
        port: nil
      }
    end
  end

  # Parses a postgres://... URL into a map of host/user/password/dbname/port
  defp parse_db_url(url) do
    uri = URI.parse(url)

    {db_user, db_pass} =
      case uri.userinfo do
        nil ->
          {nil, nil}

        userinfo ->
          case String.split(userinfo, ":", parts: 2) do
            [u, p] -> {u, p}
            [u] -> {u, nil}
            _ -> {nil, nil}
          end
      end

    db_name =
      case uri.path do
        nil -> nil
        path -> String.trim_leading(path, "/")
      end

    %{
      host: uri.host,
      user: db_user,
      password: db_pass,
      dbname: db_name,
      port: uri.port
    }
  end

  # Ensure host, user, password, dbname are present
  defp check_required(%{host: h, user: u, password: p, dbname: d}) do
    cond do
      is_nil(h) or h == "" -> {:error, "Missing database host"}
      is_nil(u) or u == "" -> {:error, "Missing database user"}
      is_nil(p) or p == "" -> {:error, "Missing database password"}
      is_nil(d) or d == "" -> {:error, "Missing database name"}
      true -> :ok
    end
  end

  # Prints a redacted postgres:// URL
  defp build_redacted_url(%{user: u, host: h, dbname: d, port: p}) do
    base = "postgres://#{u}:*****@#{h}"
    base = if p, do: base <> ":#{p}", else: base
    base <> "/#{d}"
  end

  # Example: 20250215-140925-HOST-DBNAME.sql (if you're dumping)
  # For the dumper, used in `build_filename(...)`.
  # The loader doesn't need a new filename, so we only call this from dump.
  defp build_filename(dbname) do
    datetime = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Format: YYYYMMDD-HHMMSS
    # e.g. 20250215-140925
    timestamp =
      String.pad_leading("#{datetime.year}", 4, "0") <>
        String.pad_leading("#{datetime.month}", 2, "0") <>
        String.pad_leading("#{datetime.day}", 2, "0") <>
        "-" <>
        String.pad_leading("#{datetime.hour}", 2, "0") <>
        String.pad_leading("#{datetime.minute}", 2, "0") <>
        String.pad_leading("#{datetime.second}", 2, "0")

    {hostname_raw, code} = System.cmd("hostname", [])
    hostname = if code == 0, do: String.trim(hostname_raw), else: "unknown"

    "#{timestamp}-#{hostname}-#{dbname}.sql"
  end

  # ------------------------------------------------------------------
  # Spinner
  # ------------------------------------------------------------------

  defp start_spinner(prefix) do
    parent = self()
    spawn(fn -> spinner_loop(prefix, parent) end)
  end

  defp stop_spinner(spinner_pid) do
    send(spinner_pid, :stop)
  end

  defp spinner_loop(prefix, _parent) do
    frames = ["|", "/", "-", "\\"]
    interval_ms = 150
    IO.write(prefix <> " ")

    do_loop(frames, 0, interval_ms)
  end

  defp do_loop(frames, idx, interval_ms) do
    receive do
      :stop ->
        safe_io_write("\r\n")
        :ok
    after
      interval_ms ->
        frame = Enum.at(frames, rem(idx, length(frames)))
        safe_io_write("\r" <> frame)
        do_loop(frames, idx + 1, interval_ms)
    end
  end

  defp safe_io_write(data) do
    case Process.alive?(Process.group_leader()) do
      true ->
        attempt_io_write(data)

      false ->
        IO.write(:user, data)
    end
  end

  defp attempt_io_write(data) do
    try do
      IO.write(data)
    rescue
      _exception ->
        :error
    end
  end
end
