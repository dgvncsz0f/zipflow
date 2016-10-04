defmodule Zipflow.OS do
  @moduledoc """
  adds files or directories on zip archives.
  """

  alias Zipflow.Stream

  @doc """
  This functions returns a function that makes paths relatives to a
  given path. If `path` is absolute then no tranformation is done.
  Otherwise, it applies the `Path.relative_to/2` function using either
  `File.cwd/0` when path is a subdir of the current working dir or
  `path`.
  """
  def relative_to_cwd_fn(path) do
    abs = Path.expand(path)
    cwd = case File.cwd do
            {:ok, cwd} -> cwd
            _otherwise -> "/"
          end
    case Path.type(path) do
      :absolute  -> & &1
      _otherwise ->
        if String.starts_with?(abs, cwd) do
          & Path.relative_to(&1, cwd)
        else
          & Path.relative_to(&1, abs)
        end
    end
  end

  defp abspath(items, root) do
    Enum.map(items, & Path.expand(&1, root))
  end

  defp maybe_add_file(context, printer, path, options) do
    rename = Keyword.fetch!(options, :rename)
    file_entry(context, printer, rename.(path), path)
  end

  defp dir_loop(context, _, [], _), do: context
  defp dir_loop(context, printer, [[] | xss], options), do: dir_loop(context, printer, xss, options)
  defp dir_loop(context, printer, [[x | xs] | xss], options) do
    accept = Keyword.get(options, :accept, fn _ -> true end)
    if accept.(x) do
      if File.dir?(x) do
        case File.ls(x) do
          {:ok, ys} -> dir_loop(context, printer, [abspath(ys, x) | [xs | xss]], options)
          error     -> error
        end
      else
        maybe_add_file(context, printer, x, options)
        |> case do
             failure = {:error, _} -> failure
             context               -> dir_loop(context, printer, [xs | xss], options)
           end
      end
    else
      dir_loop(context, printer, [xs | xss], options)
    end
  end

  @doc """
  adds a directory to a zip archive.

  this functions traverses the directory recursively using `File.ls/1`
  [1]. you may control the name on the zip archive and which files to
  include using `:rename` and `:accept` options respectively.

  # options #

  * `path`:
     The directory to add;

  * `options`:
     A keyword list; valid values are:

  * `rename` (default: `relative_to_cwd_fn/1`):
      A function that takes a path and return a path. The returning
      value is the name on the zip archive;

      * `accept` (default: `fn _ -> true end`):
      A function that takes a path and returns a boolean. This
      function will be used for every path found in the directory and
      when it returns false that file/directory will not be included
      in the final zip archive.

  # example #

  ```
  iex> devnull = fn _ -> () end
  iex> Zipflow.Stream.init
  ...> |> dir_entry(devnull, "/path/to/dir")
  ...> |> Zipflow.Stream.flush(devnull)
  ```

  [1] I couldn't find support for `openat` in elixir/erlang. Thus, it
  is very well possible that changes in the filesystem while this
  function executes cause it to fail. Also, as there is not `readdir`
  [as far as I can tell] depending on how `File.ls/1` returns this
  function may need to hold the entire file tree in memory which may
  be an issue for large/deep directories.
  """
  @spec dir_entry(Stream.context,
                  (binary -> ()),
                  Path.t,
                  [ {:rename, (Path.t -> Path.t)},
                    {:accept, (Path.t -> boolean)}
                  ]
                 ) :: Stream.context | {:error, any}
  def dir_entry(context, printer, path, options \\ []) do
    options = Keyword.put_new(options, :rename, relative_to_cwd_fn(path))
    if File.dir?(path) do
      dir_loop(context, printer, [[path]], options)
    else
      {:error, :enotdir}
    end
  end

  @doc """
  adds a file to a zip archive

  # example #

  This example adds a file named `/file/to/add` under the name
  `foobar`. Remember to replace `devnull` by an actual printer.

  ```
  iex> devnull = fn _ -> () end
  iex> Zipflow.Stream.init
  ...> |> file_entry(context, devnull, "foobar", "/path/to/file")
  ...> |> Zipflow.Stream.flush(devnull)
  ```
  """
  @spec file_entry(Stream.context, (binary -> ()), Path.t, Path.t) :: Stream.context | {:error, any}
  def file_entry(context, printer, name, path) do
    File.open(path, [:raw, :binary, :read], fn fh ->
      entry = Zipflow.FileEntry.encode(printer, name, fh)
      Zipflow.Stream.entry(context, entry)
    end)
    |> case do
         {:ok, success} -> success
         failure        -> failure
       end
  end

end
