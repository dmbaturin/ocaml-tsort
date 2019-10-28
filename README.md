ocaml-tsort
===========

This module provides topological sort based on Kahn's algorithm. It's not very fast, but it's easy to use
and provides friendly error reporting.

It works on assoc lists (`('a * 'a list) list`). The keys are "tasks" and the values are lists of their dependencies.

The output is a tri-state sum type. This is the entire module interface:

```
type 'a sort_result =
  Sorted of 'a list 
| ErrorNonexistent of 'a list
| ErrorCycle of 'a list

val sort : ('a * 'a list) list -> 'a sort_result
```

Dependencies on nodes that don't exist in the set of keys cause the `ErrorNonexistent` error, while cycles
produce `ErrorCycle`. Examples:

```
# Tsort.sort [("foundation", []); ("walls", ["foundation"]); ("roof", ["walls"])] ;;
- : string Tsort.sort_result = Tsort.Sorted ["foundation"; "walls"; "roof"]

# Tsort.sort [("foundation", ["building permit"]); ("walls", ["foundation"]); ("roof", ["walls"])] ;;
- : string Tsort.sort_result = Tsort.ErrorNonexistent ["building permit"]

# Tsort.sort [("foundation", ["roof"]); ("walls", ["foundation"]); ("roof", ["walls"])] ;;
- : string Tsort.sort_result = Tsort.ErrorCycle ["roof"; "foundation"; "walls"]
```
