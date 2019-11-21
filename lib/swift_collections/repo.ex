defmodule SwiftCollections.Repo do
  use Ecto.Repo,
    otp_app: :swift_collections,
    adapter: Ecto.Adapters.MyXQL
end
