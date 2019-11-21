defmodule SwiftCollections.Repo.Migrations.CreateDownloadRecords do
  use Ecto.Migration

  def change do
    create table(:download_records, primary_key: false) do
      add :id, :string, size: 36, null: false, primary_key: true
      add :filename, :string, null: false
      add :file_hash, :string, null: false

      timestamps inserted_at: :created_at
    end

    create index(:download_records, [:filename, :file_hash])
    create unique_index(:download_records, [:filename, :file_hash], name: :filename_and_file_hash_index)
  end
end
