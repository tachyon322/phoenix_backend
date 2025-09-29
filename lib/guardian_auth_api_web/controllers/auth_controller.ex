defmodule GuardianAuthApiWeb.AuthController do
  use GuardianAuthApiWeb, :controller

  alias GuardianAuthApi.{Accounts, Guardian}

  action_fallback GuardianAuthApiWeb.FallbackController

  def register(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        case Guardian.encode_and_sign(user) do
          {:ok, token, _claims} ->
            conn
            |> put_status(:created)
            |> json(%{
              message: "User created successfully",
              user: %{
                id: user.id,
                email: user.email
              },
              token: token
            })

          {:error, :secret_not_found} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{
              message: "Server configuration error: Guardian secret not found",
              error: "Please ensure GUARDIAN_SECRET environment variable is set"
            })

          {:error, reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{
              message: "Token generation failed",
              error: inspect(reason)
            })
        end

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          message: "Registration failed",
          errors: format_changeset_errors(changeset)
        })
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)

        conn
        |> json(%{
          message: "Login successful",
          user: %{
            id: user.id,
            email: user.email
          },
          token: token
        })

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{message: "Invalid email or password"})
    end
  end

  def logout(conn, _params) do
    token = Guardian.Plug.current_token(conn)
    Guardian.revoke(token)

    conn
    |> json(%{message: "Logout successful"})
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    conn
    |> json(%{
      user: %{
        id: user.id,
        email: user.email
      }
    })
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
