defmodule OffBroadwayAmqp10.MixProject do
  use Mix.Project

  @version "0.1.3"
  @description "An AMQP 1.0 connector for Broadway"
  @source_url "https://github.com/highmobility/off_broadway_amqp10"

  def project do
    [
      app: :off_broadway_amqp10,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: @description,
      deps: deps(),
      docs: docs(),
      package: package(),
      dialyzer: [ignore_warnings: ".dialyzer_ignore.exs"] ++ dialyzer_config(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:broadway, "~> 1.0"},
      {:amqp10_client, "~> 3.10"},
      {:nimble_options, "~> 1.1"},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.19.0", only: :dev}
    ]
  end

  defp dialyzer_config(:test),
    do: [
      plt_core_path: "_plts/",
      plt_file: {:no_warn, "_plts/dialyzer.plt"}
    ]

  defp dialyzer_config(_env), do: []

  defp docs do
    [
      main: "OffBroadwayAmqp10.Producer",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: ["CHANGELOG.md"]
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end
end
