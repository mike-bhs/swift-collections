defmodule SwiftCollections.SftpFileDownloader do
  use GenServer
  require Logger

  alias SwiftCollections.DownloadRecords

  @incoming_dir "/upload"
  @archive_dir "/archive"

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    send(self(), :download_files)

    {:ok, nil}
  end

  def handle_info(:download_files, _) do
    download_files()

    Process.send_after(self(), :download_files, :timer.minutes(1))

    {:noreply, nil}
  end

  def download_files() do
    with config <- Application.get_env(:swift_collections, :sftp),
         {:ok, conn} <- SFTPClient.connect(config),
         {:ok, filenames} <- SFTPClient.list_dir(conn, @incoming_dir) do
      Enum.take_while(filenames, fn filename ->
        process_file(conn, filename) == :ok
      end)

      SFTPClient.disconnect(conn)
    else
      {:error, error} ->
        Logger.error("Failed to download files form SFTP #{inspect(error)}")
    end
  end

  def process_file(conn, filename) do
    archive_path = "#{@archive_dir}/#{filename}"
    file_path = "#{@incoming_dir}/#{filename}"

    with {:ok, content} <- SFTPClient.read_file(conn, file_path),
         {:ok, download_record} <- DownloadRecords.Create.create(filename, content) do
      Logger.info("Successfully created download record #{download_record.id}")

      archive_file(conn, file_path, archive_path)
    else
      {:error, :duplicate_record, hash} ->
        Logger.error("Found duplicate record with hash #{hash}")
        archive_file(conn, file_path, archive_path)

      {:error, error} ->
        Logger.error("Failed to process file #{inspect(error)}")
        {:error, error}
    end
  end

  def archive_file(conn, file_path, archive_path) do
    case SFTPClient.rename(conn, file_path, archive_path) do
      :ok ->
        :ok

      {:error, error} ->
        Logger.error("Failed to archive file #{inspect(error)}")

        {:error, error}
    end
  end
end
