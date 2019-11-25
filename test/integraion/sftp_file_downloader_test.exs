defmodule SwiftCollections.SftpFileDownloaderTest do
  use SwiftCollections.RepoCase

  alias SwiftCollections.DownloadRecords
  alias SwiftCollections.DownloadRecords.DownloadRecord

  describe "test sftp consuming" do
    setup do
      {:ok, conn} =
        Application.get_env(:swift_collections, :sftp)
        |> SFTPClient.connect()

      filename = "file_#{Ecto.UUID.generate()}"
      file_content = "Test data for file #{filename}"
      file_hash = :crypto.hash(:md5, file_content) |> Base.encode16(case: :lower)

      :ok = SFTPClient.write_file(conn, "/upload/#{filename}", file_content)

      {:ok, filename: filename, conn: conn, file_hash: file_hash, file_content: file_content}
    end

    test "creates download record", context do
      logs =
        ExUnit.CaptureLog.capture_log(fn ->
          SwiftCollections.SftpFileDownloader.download_files()
        end)

      download_record = Repo.one!(DownloadRecord)
      {:ok, archived_files} = SFTPClient.list_dir(context.conn, "/archive")

      assert download_record.filename == context.filename
      assert download_record.file_hash == context.file_hash
      assert download_record.content == context.file_content

      assert Enum.any?(archived_files, &(&1 == download_record.filename))
      assert logs =~ "Successfully created download record #{download_record.id}"
    end

    test "download record already exists", context do
      {:ok, existing_record} =
        DownloadRecords.Create.create(context.filename, context.file_content)

      logs =
        ExUnit.CaptureLog.capture_log(fn ->
          SwiftCollections.SftpFileDownloader.download_files()
        end)

      download_record = Repo.one!(DownloadRecord)
      {:ok, archived_files} = SFTPClient.list_dir(context.conn, "/archive")

      assert download_record == existing_record
      assert Enum.any?(archived_files, &(&1 == download_record.filename))

      assert logs =~ "Failed to create download record"
      assert logs =~ "Found duplicate record with hash #{download_record.file_hash}"
    end
  end
end
