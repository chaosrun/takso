defmodule Takso.Sales.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    field :dropoff_address, :string
    field :pickup_address,  :string
    field :status,          :string, default: "OPEN"
    field :distance,        :float
    field :price,           :float
    has_one :allocation, Takso.Sales.Allocation
    belongs_to :user, Takso.Accounts.User
    belongs_to :taxi, Takso.Sales.Taxi

    timestamps()
  end

  @doc false
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:pickup_address, :dropoff_address, :status])
    |> validate_different_addresses
    |> validate_required([:pickup_address, :dropoff_address], message: "Address can not be empty!")
    |> validate_number(:distance, greater_than: 0)
  end

  defp validate_different_addresses(changeset) do
    p = get_field(changeset, :pickup_address)
    d = get_field(changeset, :dropoff_address)
    validate_different_addresses(changeset, p, d)
  end

  defp validate_different_addresses(changeset, p, d) when p == d do
    add_error(changeset, :same, "Addresses can not be the same!")
  end

  defp validate_different_addresses(changeset, _, _), do: changeset

end
