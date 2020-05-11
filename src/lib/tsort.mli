(**
   Topological sort
*)

type 'a sort_result =
  | Sorted of 'a list
  | ErrorNonexistent of 'a list
  | ErrorCycle of 'a list

(** Perform a normal topological sort on a directed acyclic graph (DAG).

    The result is in "dependency order", i.e. if there's an edge from
    A to B, then B comes first. For example,
    [sort [1, [2]; 2, []]] returns [[2; 1]].
*)
val sort : ('a * 'a list) list -> 'a sort_result

(** Dealing with cyclic graphs.
*)
module Components : sig
  (** Perform a topological sort on a directed graph that may have cycles.
      Uses [partition] and [Tsort.sort].
  *)
  val sort : ('a * 'a list) list -> 'a list list

  (**
     Partition a graph into its strongly-connected components:
     Two vertices u, v belong to the same component iff there's a path from
     u to v and there's a path from v to u.

     See https://en.wikipedia.org/wiki/Strongly_connected_component

     The current implementation uses the Kosaraju-Sharir algorithm,
     which is described at
     https://en.wikipedia.org/wiki/Kosaraju%27s_algorithm

     The theoretical complexity of the Kosaraju-Sharir algorithm is
     O(n) = O(|V|+|E|) but due to the use of resizable hash tables and a final
     sorting pass, the complexity of this implementation is O(n log n).
  *)
  val partition : ('a * 'a list) list -> 'a list list
end
