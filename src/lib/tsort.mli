(**
   Topological sort
*)

type 'a sort_result =
  | Sorted of 'a list
  | ErrorCycle of 'a list

(** Perform a normal topological sort on a directed acyclic graph (DAG).

    The result is in "dependency order", i.e. if there's an edge from
    A to B, then B comes first. For example,
    [sort [1, [2]; 2, []]] returns [[2; 1]].

    If your graph may contain legitimate cycles, consider using
    [sort_strongly_connected_components] instead.

    Missing nodes such as node 2 in graph [[1, [2]]] are automatically added,
    resulting in the graph [[1, [2]; 2, []]]. If this is undesirable,
    consider running [find_nonexistent_nodes] on the input graph.
*)
val sort : ('a * 'a list) list -> 'a sort_result

(** Perform a topological sort on a directed graph that may have cycles.
    Uses [find_strongly_connected_components] and [sort].

    Like with [sort], missing nodes are silently added to the graph.

    For example, [find_strongly_connected_components
    ["A", ["B"]; "B", ["C"]; "C", ["B"; "D"]]] returns
    [["D"]; ["B"; "C"]; ["A"]].
*)
val sort_strongly_connected_components : ('a * 'a list) list -> 'a list list

(** Report nodes mentioned in a list of out-neighbors but not explicitly
    listed otherwise. This is useful for detecting user-entry errors,
    since the other functions of the module silently add those nodes to
    the graph.

    For example, [find_nonexistent_nodes ["test", ["biuld"]; "build", []]]
    returns [["biuld"]].
*)
val find_nonexistent_nodes : ('a * 'a list) list -> 'a list

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
val find_strongly_connected_components : ('a * 'a list) list -> 'a list list
