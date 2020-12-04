ocaml-tsort [![CircleCI badge](https://circleci.com/gh/dmbaturin/ocaml-tsort.svg?style=svg)](https://app.circleci.com/pipelines/github/dmbaturin/ocaml-tsort)
===========

This module provides topological sort based on Kahn's algorithm. It's not very fast, but it's easy to use
and provides friendly error reporting.

It works on assoc lists (`('a * 'a list) list`). The keys are "tasks" and the values are lists of their dependencies.


# Sorting DAGs

Most of the time cyclic dependencies are bad. The main function, `Tsort.sort` returns value of this type:

```
type 'a sort_result =
  Sorted of 'a list 
| ErrorCycle of 'a list
```

The function is:

```
val sort : ('a * 'a list) list -> 'a sort_result
```

Examples:

```
# Tsort.sort [("foundation", []); ("walls", ["foundation"]); ("roof", ["walls"])] ;;
- : string Tsort.sort_result = Tsort.Sorted ["foundation"; "walls"; "roof"]

# Tsort.sort [("foundation", ["building permit"]); ("walls", ["foundation"]); ("roof", ["walls"])] ;;
- : string Tsort.sort_result =
Tsort.Sorted ["building permit"; "foundation"; "walls"; "roof"]

# Tsort.sort [("foundation", ["roof"]); ("walls", ["foundation"]); ("roof", ["walls"])] ;;
- : string Tsort.sort_result = Tsort.ErrorCycle ["roof"; "foundation"; "walls"]
```

As you can see from the second example, if there's a dependency on a node that doesn't exist in the assoc list keys,
it's automatically inserted, and assumed to have no dependencies.

# Detecting non-existent dependencies

If your graph comes directly from user input, there's a good chance that dependency on a non-existent node
is a user error.

To prevent it, use `Tsort.find_nonexistent_nodes`. Example:

```
# Tsort.find_nonexistent_nodes [("foundation", ["building permit"]); ("walls", ["foundation"]); ("roof", ["walls"])] ;;
- : (string * string list) list = [("foundation", ["building permit"])]
```

# Sorting graphs with cycles

Sometimes cycles are fine. In this case you can use `Tsort.sort_strongly_connected_components` to split
your graph into strongly connected components and sort its condensation.

Contrived example: you want to line up the Addams family so that children come after parents,
but spouse and sibling pairs are not separated.

```
Tsort.sort_strongly_connected_components [
  "Morticia",  ["Gomez"; "Grandmama"];
  "Gomez",     ["Morticia"; "Grandmama"];
  "Wednesday", ["Morticia"; "Gomez"; "Pugsley"];
  "Pugsley",   ["Morticia"; "Gomez"; "Wednesday"];
  "Grandmama", [];
  "Fester",    []
]
;;

- : string list list =
[["Fester"]; ["Grandmama"]; ["Morticia"; "Gomez"]; ["Wednesday"; "Pugsley"]]

```

There's also `Tsort.find_strongly_connected_components` if you just want to find what them.
For the data above, it would return `[["Morticia"; "Gomez"]; ["Wednesday"; "Pugsley"]; ["Grandmama"]; ["Fester"]]`.

# Contributing

To run our complete test suite, run `make test-complete` (requires docker).
