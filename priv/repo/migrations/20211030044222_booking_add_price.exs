defmodule Takso.Repo.Migrations.BookingAddPrice do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      add :price, :float
    end
  end
end
