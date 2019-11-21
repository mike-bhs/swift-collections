defmodule SwiftCollections.DownloadRecords.Create do
  require Logger
  alias SwiftCollections.DownloadRecords.DownloadRecord

  @spec create(String.t(), String.t()) ::
          {:ok, DownloadRecord.t()}
          | {:error, any()}
          | {:error, :duplicate_record, String.t()}
  def create(filename, file_content) do
    try do
      perform_create(filename, file_content)
    rescue
      error -> {:error, error}
    end
  end

  defp perform_create(filename, file_content) do
    file_hash = calculate_hash(file_content)
    changeset = DownloadRecord.create_changeset(filename, file_hash, file_content)

    case SwiftCollections.Repo.insert(changeset) do
      {:ok, record} ->
        {:ok, record}

      {:error, changeset} ->
        Logger.error("Failed to create download record #{inspect(changeset.errors)}")

        if Keyword.keys(changeset.errors) == [:filename_and_file_hash] do
          {:error, :duplicate_record, file_hash}
        else
          {:error, changeset}
        end
    end
  end

  defp calculate_hash(file_content) do
    :crypto.hash(:md5, file_content) |> Base.encode16(case: :lower)
  end
end
