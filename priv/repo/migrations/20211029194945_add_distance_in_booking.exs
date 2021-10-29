defmodule Takso.Repo.Migrations.AddDistanceInBooking do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      modify :status,    :string, default: "OPEN"
      add    :distance,  :float
    end
  end
end
