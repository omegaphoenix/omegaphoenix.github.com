defmodule TheJuice.UpgradeCallbacks do
  import Gatling.Bash

  def before_mix_digest(env) do
    bash("npm", ~w[install], cd: env.build_dir)
    bash("npm", ~w[run deploy], cd: env.build_dir)
  end

  def before_upgrade_service(env) do
    bash("mix", ~w[ecto.reset], cd: env.build_dir)
    bash("mix", ~w[run priv/repo/seeds.exs], cd: env.build_dir)
  end
end
