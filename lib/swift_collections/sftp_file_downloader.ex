defmodule SwiftCollections.SftpFileDownloader do
  use GenServer
  require Logger

  alias SwiftCollections.DownloadRecords

  @sftp_folder "/upload"
  @sftp_archive "/archive"

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    send(self(), :process_sftp_files)

    {:ok, nil}
  end

  def handle_info(:process_sftp_files, _) do
    process_sftp_files()

    {:noreply, nil}
  end

  def process_sftp_files() do
    config = Application.get_env(:swift_collections, :sftp)

    case SFTPClient.connect(config) do
      {:ok, conn} ->
        process_files(conn)
        SFTPClient.disconnect(conn)

      {:error, error} ->
        Logger.error("Failed to connect to SFTP #{inspect(error)}")
    end

    Process.send_after(self(), :process_sftp_files, :timer.minutes(1))
  end

  def process_files(conn) do
    case SFTPClient.list_dir(conn, @sftp_folder) do
      {:ok, filenames} ->
        Enum.each(filenames, &process_file(conn, &1))

      {:error, error} ->
        Logger.error("Failed to list directory content #{inspect(error)}")
    end
  end

  def process_file(conn, filename) do
    archive_path = "#{@sftp_archive}/#{filename}"
    file_path = "#{@sftp_folder}/#{filename}"

    with {:ok, content} <- SFTPClient.read_file(conn, file_path),
         {:ok, download_record} <- save_file_content(filename, content) do
      Logger.info("Successfully created download record #{download_record.id}")

      archive_file(conn, file_path, archive_path)
    else
      {:error, :duplicate_record, hash} ->
        Logger.error("Found duplicate record with hash #{hash}")
        archive_file(conn, file_path, archive_path)

      {:error, error} ->
        Logger.error("Failed to process file #{inspect(error)}")
    end
  end

  def archive_file(conn, file_path, archive_path) do
    case SFTPClient.rename(conn, file_path, archive_path) do
      :ok ->
        nil

      {:error, error} ->
        Logger.error("Failed to rename file #{inspect(error)}")
    end
  end

  def save_file_content(filename, content) do
    try do
      DownloadRecords.Create.create(filename, content)
    rescue
      error -> {:error, error}
    end
  end
end
