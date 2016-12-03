defmodule Callbackex.Mixfile do
  use Mix.Project

  def project do
    [app: :callbackex,
     version: "0.1.1",
     elixir: "~> 1.3",
     elixirc_paths: ["lib"],
     description: description,
     package: package,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     # Docs
     name: "Callbackex",
     source_url: "https://github.com/secretworry/callbackex",
     docs: [main: "Callbackex",
            extras: ["README.md"]]]
  end

  defp description do
      """
      Define and execute callbacks with ease in Elixir
      """
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  defp package do
    [
      name: :callbackex,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["dusiyh@gmail.com"],
      licenses: ["Apache 2"],
      links: %{"GitHub" => "https://github.com/secretworry/callbackex"}
    ]
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
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
