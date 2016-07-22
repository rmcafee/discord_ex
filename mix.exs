defmodule DiscordElixir.Mixfile do
  use Mix.Project

  def project do
    [app: :discord_elixir,
     version: "1.1.3",
     elixir: "~> 1.3",
     name: "Discord Elixir",
     source_url: "https://github.com/rmcafee/discord_elixir",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     docs: [extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :porcelain]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poison, "~> 2.0"},
      {:websocket_client, github: "jeremyong/websocket_client"},
      {:httpoison, "~> 0.9.0"},
      {:kcl, "~> 0.6.3"},
      {:poly1305, "~> 0.4.2"},
      {:socket, "~> 0.3.5"},
      {:dns, "~> 0.0.3"},
      {:porcelain, "~> 2.0.1"},
      {:temp, "~> 0.4"},
      {:credo, "~> 0.4.5", only: [:dev, :test]},

      # Docs dependencies
      {:earmark, "~> 0.1", only: :docs},
      {:ex_doc, "~> 0.11", only: :docs},
      {:inch_ex, "~> 0.2", only: :docs}
    ]
  end
end
