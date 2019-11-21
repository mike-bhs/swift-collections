defmodule SwiftCollections.DownloadRecords.DownloadRecord do
  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          filename: String.t(),
          file_hash: String.t(),
          updated_at: DateTime.t() | nil,
          created_at: DateTime.t() | nil
        }

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, SwiftCollections.EctoTypes.UUID, autogenerate: true}

  schema "download_records" do
    field :filename, :string
    field :file_hash, :string

    timestamps inserted_at: :created_at
  end

  @spec find_by_name_and_hash(String.t(), String.t()) :: t() | nil
  def find_by_name_and_hash(name, file_hash) do
    SwiftCollections.Repo.get_by(__MODULE__, filename: name, file_hash: file_hash)
  end

  @spec create_changeset(String.t(), String.t()) :: Ecto.Changeset.t()
  def create_changeset(filename, file_hash) do
    __struct__()
    |> change(filename: filename, file_hash: file_hash)
    |> validate()
  end

  defp validate(changeset) do
    changeset
    |> validate_required([:free_text, :digest])
    |> unique_constraint(:filename_and_file_hash, name: :filename_and_file_hash_index)
  end
end
