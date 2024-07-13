defmodule Expaca.MixProject do
  use Mix.Project

  def project do
    [
      app: :expaca,
      name: "Expaca",
      version: "0.1.1",
      elixir: "~> 1.15",
      erlc_options: [:verbose, :report_errors, :report_warnings, :export_all],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      test_pattern: "*_test.exs",
      dialyzer: [flags: [:no_improper_lists]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def docs do
    [
      main: "readme",
      output: "doc/api",
      assets: %{"assets" => "assets"},
      extras: ["README.md"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # runtime code dependencies ------------------

      {:exa, git: "https://github.com/red-jade/exa_core.git", tag: "v0.1.4"},
      {:exa_space, git: "https://github.com/red-jade/exa_space.git", tag: "v0.1.4"},
      {:exa_color, git: "https://github.com/red-jade/exa_color.git", tag: "v0.1.4"},
      {:exa_image, git: "https://github.com/red-jade/exa_image.git", tag: "v0.1.6"},

      # building, documenting ----------

      # typechecking
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},

      # documentation
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}

      # benchmarking
      # {:benchee, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
