defmodule Arca.Dbutils.Helper do
  @moduledoc """
  Helper functions for Arca.Dbutils modules, particularly for command-line argument parsing.
  """
  
  @doc """
  Parses command line arguments in the form of "key=value" into keyword list.
  
  ## Parameters
    * `args` - List of strings in the format "key=value"
    
  ## Returns
    * Keyword list with atoms as keys and string values
    
  ## Examples
      iex> Arca.Dbutils.Helper.parse_args(["host=localhost", "user=postgres"])
      [host: "localhost", user: "postgres"]
      
      iex> Arca.Dbutils.Helper.parse_args(["invalid"])
      []
  """
  @spec parse_args([String.t()]) :: keyword()
  def parse_args(args) do
    args
    |> Enum.map(fn arg ->
      case String.split(arg, "=", parts: 2) do
        [key, value] -> {String.to_atom(key), value}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
