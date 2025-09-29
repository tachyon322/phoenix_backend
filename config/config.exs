import Config

config :guardian_auth_api,
  ecto_repos: [GuardianAuthApi.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :guardian_auth_api, GuardianAuthApiWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: GuardianAuthApiWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: GuardianAuthApi.PubSub,
  live_view: [signing_salt: "nwjyMEak"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :guardian_auth_api, GuardianAuthApi.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Load .env file
if File.exists?(".env") do
  try do
    Dotenvy.source!(".env", [])
  rescue
    UndefinedFunctionError ->
      # Fallback: manually parse .env file
      File.read!(".env")
      |> String.split("\n", trim: true)
      |> Enum.each(fn line ->
        case String.split(line, "=", parts: 2) do
          [key, value] ->
            System.put_env(key, value)
          _ -> nil
        end
      end)
  end
end

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
