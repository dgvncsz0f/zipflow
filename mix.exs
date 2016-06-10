defmodule Zipflow.Mixfile do
  use Mix.Project

  def project do
    [app: :zipflow,
     deps: deps,
     elixir: "~> 1.2",
     version: "0.0.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:dialyxir, "~> 0.3", only: [:dev]},
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev}]
  end
end
