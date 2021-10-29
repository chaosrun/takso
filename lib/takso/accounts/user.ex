defmodule Takso.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name,     :string
    field :username, :string
    field :password, :string
    field :age,      :integer
    has_many :bookings, Takso.Sales.Booking
    has_one :taxi, Takso.Sales.Taxi

    timestamps()
  end

  @doc false
  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:name, :username, :password, :age])
    |> validate_required([:name, :username, :password, :age])
    |> unique_constraint(:username)
    |> validate_format(:email, ~r/@/)
    |> validate_number(:age, greater_than_or_equal_to: 18)
  end
end
