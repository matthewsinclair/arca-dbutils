# Arca Dbutils Project Guidelines

## Build Commands
- Run all tests: `mix test`
- Run a specific test: `mix test path/to/test_file.exs:line_number`
- Run a specific test file: `mix test path/to/test_file.exs`
- Compile: `mix compile` 
- Format code: `mix format`
- Dump database: `mix arca.dbutils.dump [options]`
- Load database: `mix arca.dbutils.load file=file.sql [options]`

## Code Style Guidelines
- Module names: PascalCase, follow Elixir naming convention (e.g., `Arca.Dbutils.Dumper`)
- Variable/function names: snake_case
- Function documentation: Use `@doc` and `@moduledoc` with triple quotes
- Error handling: Return tagged tuples `{:ok, result}` or `{:error, reason}`
- Use piping (`|>`) for sequential transformations
- Group related functions with section comments (`# ------ SECTION ------`)
- Functions should be grouped logically (public API first, private helpers after)
- Use pattern matching for error handling and flow control
- Explicit function documentation for public-facing functions
- Indentation: 2 spaces

## Project Structure
- Mix tasks in `lib/mix/tasks/`
- Core functionality in `lib/arca_dbutils/`
- Helper modules in `lib/arca_dbutils/helpers/`
- Tests mirror the lib structure in `test/`

## Known Issues & Improvement Areas
- [x] Add typespecs to main functions
- [x] Fix Helper module documentation
- [x] Add return value in do_load/3 function file check condition
- [x] Add validation of SQL file existence before attempting to load
- [x] Add tests for load functionality
- [ ] Add typespecs to remaining private functions
- [ ] Make error handling consistent (remove direct IO.puts, return errors to caller)
- [ ] Add tests for url parsing edge cases
- [ ] Better error handling for System.cmd("hostname", []) call
- [ ] Add logging level configuration