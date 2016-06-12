# zipflow

zipflow is a library for elixir language that allows you to stream the
zip archive while it is being created.

## installation

the package can be installed as:

  1. add zipflow to your list of dependencies in `mix.exs`:

        def deps do
          [{:zipflow, github: "dgvncsz0f/zipflow"}]
        end

## the problem

erlang provides a `:zip` module that can be used to create a zip
archive. however you can not use that to stream the zip file. using
erlang's `:zip` module you only have the option to write to a file or
entirely on memory.

this module solves that problem by streaming the contents of the zip
file while it is being created.

## example

this example writes a zip file to stdout:

```
iex> printer = &IO.binwrite/1
...> Zipflow.Stream.init
...> |> Zipflow.Stream.entry(Zipflow.DataEntry.encode(printer, "foo/bar", "foobar"))
...> |> Zipflow.Stream.flush(printer)
```

Then you should have:

```
$ unzip -l example.zip
Archive:  example.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        6  1980-00-00 00:00   foo/bar
---------                     -------
        6                     1 file
```

## todo

* [ ] encryption;
* [ ] compression;
* [ ] utf encoding;
* [ ] store date/time correctly;
* [ ] support more than 2^16 files;

## licence

bsd3
