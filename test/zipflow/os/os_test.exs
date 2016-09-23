defmodule Zipflow.OSTest do
  use ExUnit.Case, async: true

  alias Zipflow.OS
  alias Zipflow.Stream

  import Test.Zipflow.Support.Helpers

  test "empty directory" do
    ramdev fn contents, printer ->
      mkstemp_dir fn tmpdir ->
        Stream.init
        |> OS.dir_entry(printer, tmpdir)
        |> Stream.flush(printer)
      end

      assert {:ok, []} == :zip.extract(contents.(), [:memory])
    end
  end

  test "simple directory" do
    ramdev fn contents, printer ->
      mkstemp_dir fn tmpdir ->
        File.touch(Path.expand("foobar", tmpdir))

        Stream.init
        |> OS.dir_entry(printer, tmpdir, [rename: & Path.relative_to(&1, tmpdir)])
        |> Stream.flush(printer)
      end

      assert {:ok, [{'foobar', ""}]} == :zip.extract(contents.(), [:memory])
    end
  end

  test "complex directory" do
    ramdev fn contents, printer ->
      blueprint = mkstemp_dir fn tmpdir ->
        blueprint = build_dir(tmpdir, "")

        Stream.init
        |> OS.dir_entry(printer, tmpdir, [rename: & Path.relative_to(&1, tmpdir)])
        |> Stream.flush(printer)

        blueprint
      end

      blueprint = Enum.map(blueprint, & {String.to_charlist(&1), &1})
      {:ok, zipfiles} = :zip.extract(contents.(), [:memory])

      assert Enum.sort(zipfiles) == Enum.sort(blueprint)
    end
  end

  test "rename function" do
    encode_path = & :erlang.md5(&1) |> Base.encode16

    ramdev fn contents, printer ->
      blueprint = mkstemp_dir fn tmpdir ->
        blueprint = build_dir(tmpdir, "")

        Stream.init
        |> OS.dir_entry(printer, tmpdir, [rename: & encode_path.(Path.relative_to(&1, tmpdir))])
        |> Stream.flush(printer)

        blueprint
      end

      blueprint = Enum.map(blueprint, & {encode_path.(&1) |> String.to_charlist, &1})
      {:ok, zipfiles} = :zip.extract(contents.(), [:memory])

      assert Enum.sort(zipfiles) == Enum.sort(blueprint)
    end
  end

  test "accept function" do
    ramdev fn contents, printer ->
      blueprint = mkstemp_dir fn tmpdir ->
        all_files = build_dir(tmpdir, "")
        acceptset = sample(all_files, :rand.uniform(Enum.count(all_files)))
        |> MapSet.new

        Stream.init
        |> OS.dir_entry(printer, tmpdir, [accept: & File.dir?(&1) or MapSet.member?(acceptset, Path.relative_to(&1, tmpdir)),
                                          rename: & Path.relative_to(&1, tmpdir)])
        |> Stream.flush(printer)

        acceptset
      end

      blueprint = Enum.map(blueprint, & {String.to_charlist(&1), &1})
      {:ok, zipfiles} = :zip.extract(contents.(), [:memory])

      assert Enum.sort(zipfiles) == Enum.sort(blueprint)
    end
  end

  defp sample(xs, samples) do
    Enum.shuffle(xs)
    |> Enum.take(samples)
  end

  @max_dirs 3
  @max_files 42
  defp build_dir(root, parent, acc \\ [], threshold \\ @max_dirs + 1) do
    n_dirs  = :rand.uniform(@max_dirs)
    n_files = :rand.uniform(@max_files)

    dirs = 0..n_dirs
    |> Enum.map(& "d#{&1}")
    |> Enum.map(& Path.join(parent, &1))
    |> Enum.take(threshold)

    files = 0..n_files
    |> Enum.map(& "f#{&1}")
    |> Enum.map(& Path.join(parent, &1))

    dirs
    |> Enum.map(& Path.expand(&1, root))
    |> Enum.each(&File.mkdir!/1)

    files
    |> Enum.map(& Path.expand(&1, root))
    |> Enum.each(& File.write!(&1, Path.relative_to(&1, root)))

    Enum.reduce(dirs, Enum.concat(files, acc), fn dir, acc ->
      build_dir(root, dir, acc, threshold - 1)
    end)
  end

  test "simple file_entry" do
    path = __ENV__.file
    data = File.read!(path)

    ramdev fn contents, printer ->
      Stream.init
      |> OS.file_entry(printer, path, path)
      |> Stream.flush(printer)

      assert {:ok, [{String.to_charlist(path), data}]} == :zip.extract(contents.(), [:memory])
    end
  end

  test "path does not exists" do
    ramdev fn _, printer ->
      result = Stream.init
      |> OS.file_entry(printer, "/not/there", "/not/there")

      assert {:error, :enoent} == result
    end
  end

  test "path does not exists [dir version]" do
    ramdev fn _, printer ->
      result = Stream.init
      |> OS.dir_entry(printer, "/not/there")

      assert {:error, :enotdir} == result
    end
  end

end
