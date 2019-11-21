defmodule SwiftCollections.DownloadRecords.Create do
  require Logger
  alias SwiftCollections.DownloadRecords.DownloadRecord

  @spec find_or_create(String.t(), String.t()) :: {:ok, DownloadRecord.t()} | {:error, any()}
  def find_or_create(filename, file_content) do
    file_hash = calculate_hash(file_content)

    if record = find_download_record(filename, file_hash) do
      Logger.info("Found existing download record #{record.id}")

      {:ok, record}
    else
      create(filename, file_hash)
    end
  end

  defp create(filename, file_hash) do
    changeset = DownloadRecord.create_changeset(filename, file_hash)

    case SwiftCollections.Repo.insert(changeset) do
      {:ok, record} ->
        Logger.info("Successfully created download record #{record.id}")
        {:ok, record}

      {:error, error} ->
        Logger.error("Failed to create download record #{inspect(error)}")
        {:error, error}
    end
  end

  defp calculate_hash(file_content) do
    :crypto.hash(:md5, file_content) |> Base.encode16(case: :lower)
  end

  defp find_download_record(filename, file_hash) do
    DownloadRecord.find_by_name_and_hash(filename, file_hash)
  end
end
