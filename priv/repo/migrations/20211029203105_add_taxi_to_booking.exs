defmodule Takso.Repo.Migrations.AddTaxiToBooking do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      add :taxi_id, references(:taxis)
    end
  end
end
