defmodule Takso.Sales.Taxi do
  use Ecto.Schema
  import Ecto.Changeset

  schema "taxis" do
    field :location, :string
    field :status, :string
    field :username, :string
    belongs_to :user, Takso.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(taxi, attrs) do
    taxi
    |> cast(attrs, [:username, :location, :status])
  end
end
