defmodule SwiftCollections.RepoCase do
  @moduledoc """
  This module defines the test case to to establish the database connection ahead of your tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias SwiftCollections.Repo

      import Ecto
      import Ecto.Query
      import SwiftCollections.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SwiftCollections.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(SwiftCollections.Repo, {:shared, self()})
    end

    :ok
  end
end
