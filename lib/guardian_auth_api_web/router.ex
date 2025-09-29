defmodule GuardianAuthApiWeb.Router do
  use GuardianAuthApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug Guardian.Plug.Pipeline,
      module: GuardianAuthApi.Guardian,
      error_handler: GuardianAuthApiWeb.AuthErrorHandler

    plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  scope "/api", GuardianAuthApiWeb do
    pipe_through :api

    # Public routes
    post "/register", AuthController, :register
    post "/login", AuthController, :login
  end

  scope "/api", GuardianAuthApiWeb do
    pipe_through [:api, :auth]

    # Protected routes
    post "/logout", AuthController, :logout
    get "/me", AuthController, :me
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:guardian_auth_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: GuardianAuthApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
