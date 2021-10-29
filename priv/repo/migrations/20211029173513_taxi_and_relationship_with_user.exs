defmodule Takso.Repo.Migrations.TaxiAndRelationshipWithUser do
  use Ecto.Migration

  def change do
    alter table(:taxis) do
      add :user_id, references(:users)
    end

    create unique_index(:taxis, [:user_id])
  end
end
