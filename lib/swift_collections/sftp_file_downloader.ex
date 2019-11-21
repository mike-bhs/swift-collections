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

  def handle_info({:download_files, conn}, _) do
    download_files(conn)

    {:noreply, nil}
  end

  def handle_info({:save_file_content, filename, content}, _) do
    save_file_content(filename, content)

    {:noreply, nil}
  end

  def process_sftp_files() do
    config = Application.get_env(:swift_collections, :sftp)

    case SFTPClient.connect(config) do
      {:ok, conn} ->
        send(self(), {:download_files, conn})

      {:error, error} ->
        Logger.error("Failed to connect to SFTP #{inspect(error)}")
    end

    Process.send_after(self(), :process_sftp_files, :timer.minutes(5))
  end

  def download_files(conn) do
    case SFTPClient.list_dir(conn, @sftp_folder) do
      {:ok, filenames} ->
        Enum.each(filenames, &process_file(conn, &1))
        SFTPClient.disconnect(conn)

      {:error, error} ->
        Logger.error("Failed to list directory content #{inspect(error)}")
    end
  end

  def process_file(conn, filename) do
    file_path = "#{@sftp_folder}/#{filename}"

    case SFTPClient.read_file(conn, file_path) do
      {:ok, content} ->
        send(self(), {:save_file_content, filename, content})

        archive_path = "#{@sftp_archive}/#{filename}"
        move_file(conn, file_path, archive_path)

      {:error, error} ->
        Logger.error("Failed to read file conent #{inspect(error)}")
    end
  end

  def move_file(conn, old_path, new_path) do
    case SFTPClient.rename(conn, old_path, new_path) do
      :ok ->
        nil

      {:error, error} ->
        Logger.error("Failed to rename file #{inspect(error)}")
    end
  end

  def save_file_content(filename, content) do
    try do
      DownloadRecords.Create.find_or_create(filename, content)
    rescue
      error ->
        # TODO add retry mechanism
        Logger.error("Failed to create download record due to exception: #{inspect(error)}")
    end
  end
end
