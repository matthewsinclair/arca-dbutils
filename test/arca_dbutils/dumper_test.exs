# test/dbutils/dumper_test.exs
defmodule Arca.Dbutils.DumperTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  import Mock

  alias Arca.Dbutils.Dumper

  describe "dump/1" do
    test "succeeds with all required params and finds pg_dump" do
      opts = [
        host: "localhost",
        user: "postgres",
        password: "secret",
        dbname: "test_db"
      ]

      with_mocks([
        {
          System,
          [:passthrough],
          [
            find_executable: fn "pg_dump" ->
              "/usr/local/bin/pg_dump"
            end,
            cmd: fn
              # Mock hostname
              "hostname", [], _cmd_opts ->
                {"my-mock-host\n", 0}

              # Mock the pg_dump call
              "/usr/local/bin/pg_dump", _args, _opts ->
                {"Dump complete", 0}
            end
          ]
        }
      ]) do
        captured_output =
          capture_io(fn ->
            # On success, code returns {:ok, filename}
            assert {:ok, filename} = Dumper.dump(opts)
            # Check that the filename has "test_db.sql"
            assert filename =~ "test_db.sql"
          end)

        assert captured_output =~ "postgres://postgres:*****@localhost/test_db"
      end
    end

    test "fails if pg_dump is not found" do
      opts = [
        host: "localhost",
        user: "postgres",
        password: "secret",
        dbname: "test_db"
      ]

      with_mocks([
        {
          System,
          [:passthrough],
          [
            find_executable: fn "pg_dump" -> nil end
          ]
        }
      ]) do
        captured_output =
          capture_io(fn ->
            assert {:error, :pg_dump_not_found} = Dumper.dump(opts)
          end)

        assert captured_output =~ "Error: `pg_dump` not found on your PATH."
      end
    end

    test "fails if required param (e.g. password) is missing" do
      # Omit password
      opts = [
        host: "localhost",
        user: "postgres",
        dbname: "test_db"
      ]

      with_mocks([
        {
          System,
          [:passthrough],
          [
            find_executable: fn "pg_dump" ->
              "/usr/local/bin/pg_dump"
            end,
            cmd: fn
              "hostname", [], _cmd_opts ->
                {"mock-host\n", 0}
            end
          ]
        }
      ]) do
        captured_output =
          capture_io(fn ->
            assert {:error, "Missing database password"} = Dumper.dump(opts)
          end)

        assert captured_output == ""
      end
    end

    test "can parse url option" do
      opts = [
        url: "postgres://postgres:abc123@myhost:5432/my_db"
      ]

      with_mocks([
        {
          System,
          [:passthrough],
          [
            find_executable: fn "pg_dump" ->
              "/usr/local/bin/pg_dump"
            end,
            cmd: fn
              # Mock hostname
              "hostname", [], _cmd_opts ->
                {"mock-host\n", 0}

              # Mock pg_dump for success
              "/usr/local/bin/pg_dump", _args, _opts ->
                {"Dump complete from URL", 0}
            end
          ]
        }
      ]) do
        captured_output =
          capture_io(fn ->
            assert {:ok, filename} = Dumper.dump(opts)
            assert filename =~ "my_db.sql"
          end)

        assert captured_output =~ "postgres://postgres:*****@myhost:5432/my_db"
      end
    end
  end
end
