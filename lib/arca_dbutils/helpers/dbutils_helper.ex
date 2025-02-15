defmodule Arca.Dbutils.Helper do
  @doc """
  """
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
