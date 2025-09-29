defmodule GuardianAuthApi.Repo do
  use Ecto.Repo,
    otp_app: :guardian_auth_api,
    adapter: Ecto.Adapters.Postgres
end
