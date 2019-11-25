use Mix.Config

config :swift_collections, SwiftCollections.Repo,
  database: "swift_collections_test",
  pool: Ecto.Adapters.SQL.Sandbox
