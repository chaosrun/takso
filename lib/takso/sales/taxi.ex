defmodule Takso.Sales.Taxi do
  use Ecto.Schema
  import Ecto.Changeset

  schema "taxis" do
    field :username, :string
    field :location, :string
    field :status,   :string
    field :capacity, :integer
    field :price,    :float
    belongs_to :user, Takso.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(taxi, attrs) do
    taxi
    |> cast(attrs, [:username, :location, :status, :capacity, :price])
  end
end
