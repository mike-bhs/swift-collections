# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :swift_collections, SwiftCollections.Repo,
  database: "",
  username: "root",
  password: nil,
  hostname: "mysql",
  port: 3306,
  pool_size: 10

config :swift_collections, ecto_repos: [SwiftCollections.Repo]

config :swift_collections, :sftp,
  host: 'localhost',
  port: 2222,
  user: 'sftp_sandbox',
  password: 'sftp_sandbox'

import_config "#{Mix.env()}.exs"
