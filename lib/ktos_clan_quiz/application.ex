defmodule KtosClanQuiz.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KtosClanQuizWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:ktos_clan_quiz, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: KtosClanQuiz.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: KtosClanQuiz.Finch},
      # Start a worker by calling: KtosClanQuiz.Worker.start_link(arg)
      # {KtosClanQuiz.Worker, arg},
      # Start to serve requests, typically the last entry
      KtosClanQuizWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KtosClanQuiz.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    KtosClanQuizWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
