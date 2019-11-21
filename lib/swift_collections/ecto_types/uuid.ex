defmodule SwiftCollections.EctoTypes.UUID do
  @type t :: Ecto.UUID.t()

  @behaviour Ecto.Type

  @spec cast(any() | String.t()) :: :error | {:ok, String.t()}
  def cast(string) when is_bitstring(string), do: {:ok, string}
  def cast(_), do: :error

  @spec dump(any() | String.t()) :: :error | {:ok, String.t()}
  def dump(string) when is_bitstring(string), do: {:ok, string}
  def dump(_), do: :error

  @spec load(any() | String.t()) :: :error | {:ok, String.t()}
  def load(string) when is_bitstring(string), do: {:ok, string}
  def load(_), do: :error

  @spec type :: :string
  def type, do: :string

  @spec autogenerate :: String.t()
  def autogenerate, do: Ecto.UUID.generate()
end
