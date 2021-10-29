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
    has_many :bookings, Takso.Sales.Booking

    timestamps()
  end

  @doc false
  def changeset(taxi, attrs) do
    taxi
    |> cast(attrs, [:username, :location, :status, :capacity, :price])
    |> validate_format(:username, ~r/@/)
    |> validate_number(:capacity, greater_than: 0)
    |> validate_number(:price, greater_than: 0)
  end
end
