defmodule SwiftCollections.MixProject do
  use Mix.Project

  def project do
    [
      app: :swift_collections,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SwiftCollections.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:sftp_ex, "~> 0.2.6"},
      {:sftp_client, "~> 1.3"},
      {:ecto_sql, "~> 3.1.4"},
      {:myxql, "~> 0.2.9"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
