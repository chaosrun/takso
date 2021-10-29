defmodule Takso.Repo.Migrations.UserAddMoreFields do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :age, :integer
    end
  end
end
