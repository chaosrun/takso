defmodule Takso.Sales.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    field :dropoff_address, :string
    field :pickup_address,  :string
    field :status,          :string, default: "OPEN"
    field :distance,        :float
    belongs_to :user, Takso.Accounts.User
    belongs_to :taxi, Takso.Sales.Taxi

    timestamps()
  end

  @doc false
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pickup_address, :dropoff_address, :status])
    |> validate_required([:pickup_address, :dropoff_address])
  end
end
