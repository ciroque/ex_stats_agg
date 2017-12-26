# StatsAgg

StatsAgg is a library that allows instrumentation of Elixir functions to track durations.

## Overview 

StatsAgg defines a macro, `with_stats_agg`, that makes it simple to add this instrumentation to your projects.

StatsAgg instrumentation includes a customizable `group` to allow related stats, or stats you wish to
display on an Information Radiator to be easily accessible.

StatsAgg is implemented as a GenServer so calls to record durations are asynchronous. Only the durations are stored
for each method to help reduce memory requirements. The durations are stored as a nested map with the keys:

 - `group`: an arbitrary name provided by you, defaults to _main_
 - `module`: the name of the module as returned by `__MODULE__`
 - `function`: the name of the function, in the form: _name/arity_

## Basic Usage

StatsAgg calculates and returns the accumulated stats via a call to the `StatsAgg.retrieve_stats/1` method. Stats
can be retrieved at each level of the hierarchy. Thus you can query as in the following examples:

```elixir
  all_stats_query = []
  group_only_query = ["main"]
  group_and_module_query = ["main", "MyModule"]
  group_module_and_function_query = ["main", "MyModule", "function/0"]
  
  StatsAgg.retrieve_stats(all_stats_query)
  StatsAgg.retrieve_stats(group_only_query)
  StatsAgg.retrieve_stats(group_and_module_query)
  StatsAgg.retrieve_stats(group_module_and_function_query)
```

The results are a list of Maps with the following shape:

```elixir
  %{
    avg_duration: 17, 
    durations: [14, 17, 21],
    function: "function/0", 
    group: "main",
    max_duration: 21, 
    min_duration: 14, 
    module: "MyModule",
    most_recent_duration: 14
  }
```

## Considerations

Being a GenServer module, StatsAgg will lose history if the app is shutdown or restarted. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `stats_agg` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:stats_agg, "~> 0.1.0"}
  ]
end
```

Add `StatsAgg` to your Application start:

```elixir
defmodule MyApp.Application do
  use Application
  
  def start(_type, _args) do
    import Supervisor.Spec
    
    children = [
      worker(Ciroque.Monitoring.StatsAgg, [])
    ]
    
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    
    Supervisor.start_link(children, opts)
  end  
end
```

You can then use the macros to instrument your functions, or call the `StatsAgg` functions directly.

## Miscellany

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/stats_agg](https://hexdocs.pm/stats_agg).

