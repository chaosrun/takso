defmodule Takso.Sales.Taxi do
  use Ecto.Schema
  import Ecto.Changeset

  schema "taxis" do
    field :username, :string
    field :location, :string
    field :status,   :string
    field :capacity, :integer
    field :price,    :float
    has_many :bookings, Takso.Sales.Booking
    has_one  :allocation, Takso.Sales.Allocation
    belongs_to :user, Takso.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(taxi, attrs) do
    taxi
    |> cast(attrs, [:username, :location, :status, :capacity, :price])
    |> validate_format(:username, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
    |> validate_number(:capacity, greater_than: 0)
    |> validate_number(:price, greater_than: 0)
  end
end
