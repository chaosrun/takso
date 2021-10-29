defmodule Takso.Repo.Migrations.TaxiAddMoreInfo do
  use Ecto.Migration

  def change do
    alter table(:taxis) do
      add :capacity, :integer
      add :price,    :float
    end
  end
end
