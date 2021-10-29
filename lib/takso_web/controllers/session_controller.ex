defmodule TaksoWeb.SessionController do
  use TaksoWeb, :controller

  alias Takso.{Repo, Accounts.User}

  import Ecto.Query, only: [from: 2]

  def new(conn, _params) do
    render conn, "new.html"
  end

  def create(conn, %{"session" => %{"username" => username, "password" => password}}) do
    query = from t in User, where: t.username == ^username, select: t.name
    name = Repo.all(query)
    case Takso.Authentication.check_credentials(conn, username, password, repo: Takso.Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome #{name}")
        |> redirect(to: Routes.page_path(conn, :index))
      {:error, :unauthorized, conn} ->
        conn
        |> put_flash(:error, "Bad Credentials")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Takso.Authentication.logout()
    |> redirect(to: Routes.page_path(conn, :index))
  end

end
