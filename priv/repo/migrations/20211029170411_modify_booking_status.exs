defmodule Takso.Repo.Migrations.ModifyBookingStatus do
  use Ecto.Migration

  def change do
    alter table(:bookings) do
      modify :status, :string, default: "ACCEPTED"
    end
  end
end
