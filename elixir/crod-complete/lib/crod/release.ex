defmodule Crod.Release do
  @moduledoc """
  Release tasks for production deployments.
  """
  
  @app :crod
  
  def migrate do
    load_app()
    
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end
  
  def seed do
    load_app()
    
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, fn repo ->
        # Run the seed script if it exists
        seed_script = priv_path_for(repo, "seeds.exs")
        
        if File.exists?(seed_script) do
          Code.eval_file(seed_script)
        end
      end)
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.ensure_all_started(@app)
  end
  
  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config(), :otp_app)
    repo_underscore = repo |> Module.split() |> List.last() |> Macro.underscore()
    priv_dir = Application.app_dir(app, "priv")
    
    Path.join([priv_dir, repo_underscore, filename])
  end
end