defmodule Test.Zipflow.Support.Helpers do
  @moduledoc false

  def ramdev(next) do
    {:ok, dev} = File.open("", [:ram, :write, :read, :binary])

    readall = fn ->
      {:ok, 0} = :file.position(dev, 0)
      IO.binread(dev, :all)
    end

    try do
      next.(readall, & IO.binwrite(dev, &1))
    after
      :ok = File.close(dev)
    end
  end

  def mkstemp_dir(next) do
    tmpdir = [:erlang.unique_integer([:monotonic]),
              :erlang.monotonic_time,
              :erlang.system_info(:scheduler_id)
             ]
             |> Enum.map(&to_string/1)
             |> Enum.join("-")
             |> Path.expand(System.tmp_dir!)
    File.mkdir!(tmpdir)
    try do
      next.(tmpdir)
    after
      File.rm_rf!(tmpdir)
    end
  end

end
