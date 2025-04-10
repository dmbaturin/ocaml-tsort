(* User-friendly topological sort based on Kahn's algorithm.

   Usage example: sort [("foundation", []); ("basement", ["foundation"]);]

   Authors: Daniil Baturin (2019), Martin Jambon (2020).
*)

type 'a sort_result =
  | Sorted of 'a list
  | ErrorCycle of 'a list

(* Deduplicate list items.

   Differences with CCList.uniq:
   - when an item is duplicated, keep the first item encountered rather than
     the last: [1;2;3;1] gives [1;2;3] (not [2;3;1]).
   - complexity is O(n), not O(n^2).
*)
let deduplicate l =
  let tbl = Hashtbl.create (List.length l) in
  List.fold_left (fun acc x ->
    if Hashtbl.mem tbl x then
      acc
    else (
      Hashtbl.add tbl x ();
      x :: acc
    )
  ) [] l
  |> List.rev


let graph_hash_of_list l =
  let update h k v =
    let orig_v = Compat.Hashtbl.find_opt h k in
    match orig_v with
    | None -> Hashtbl.add h k v
    | Some orig_v ->
      (* Allow "partial" dependency lists like [(1, [2]); (1, [3]); (2, [1])].
	 Sometimes it's a more natural way to write cyclic graphs.
       *)
      Hashtbl.replace h k (List.append orig_v v)
  in
  let tbl = Hashtbl.create 100 in
  let () =List.iter (fun (k, v) -> update tbl k v) l in
  let () = Hashtbl.filter_map_inplace (fun _ xs -> Some (deduplicate xs)) tbl in
  tbl

(* Finds "isolated" nodes,
   that is, nodes that have no dependencies *)
let find_isolated_nodes hash =
  let aux id deps acc =
    match deps with
    | [] -> id :: acc
    | _  -> acc
  in Hashtbl.fold aux hash []

(* Takes a node name list and removes all those nodes from a hash *)
let remove_nodes nodes hash =
  List.iter (Hashtbl.remove hash) nodes

(* Walks through a node:dependencies hash and removes a dependency
   from all nodes that have it in their dependency lists *)
let remove_dependency hash dep =
  let aux dep hash id =
    let deps = Hashtbl.find hash id in
    let deps =
      if List.exists ((=) dep) deps then
        Compat.List.remove ~eq:(=) ~key:dep deps
      else deps
    in
    begin
      Hashtbl.remove hash id;
      Hashtbl.add hash id deps
    end
  in
  let ids = Compat.Hashtbl.list_keys hash in
  List.iter (aux dep hash) ids

(* Finds non-existent nodes,
   that is, nodes that are mentioned in the value part of the assoc list,
   but don't exist among the assoc list keys.

   Complexity is O(n), where n = |V| + |E|.
 *)
let find_nonexistent_nodes nodes =
  let graph = Hashtbl.create (List.length nodes) in
  List.iter (fun (u, vl) -> Hashtbl.add graph u vl) nodes;
  Compat.List.filter_map (fun (u, vl) ->
    let missing =
      List.filter (fun v -> not (Hashtbl.mem graph v)) vl
      |> deduplicate
    in
    match missing with
    | [] -> None
    | missing -> Some (u, missing)
  ) nodes

(*
   Append missing nodes to the graph, in the order in which they were
   encountered. This particular order doesn't have to be guaranteed by the
   API but seems nice to have.
*)
let _add_missing_nodes graph_l graph =
  let missing =
    List.fold_left (fun acc (_, vl) ->
      List.fold_left (fun acc v ->
        if not (Hashtbl.mem graph v) then
          (v, []) :: acc
        else
          acc
      ) acc vl
    ) [] graph_l
    |> List.rev
  in
  List.iter (fun (v, vl) -> Hashtbl.replace graph v vl) missing;
  graph_l @ missing

(* The public version of [_add_missing_nodes]
   that doesn't require a graph hash argument.
 *)
let add_missing_nodes graph =
  let graph_hash = graph_hash_of_list graph in
  _add_missing_nodes graph graph_hash

(* The Kahn's algorithm:
    1. Find nodes that have no dependencies ("isolated") and remove them from
       the graph hash.
       Add them to the initial sorted nodes list and the list of isolated
       nodes for the first sorting pass.
    2. For every isolated node, walk through the remaining nodes and
       remove it from their dependency list.
       Nodes that only depended on it now have empty dependency lists.
    3. Find all nodes with empty dependency lists and append them to the sorted
       nodes list _and_ the list of isolated nodes to use for the next step
    4. Repeat until the list of isolated nodes is empty
    5. If the graph hash is still not empty, it means there is a cycle.
 *)
let sort nodes =
  let rec sorting_loop deps hash acc =
    match deps with
    | [] -> acc
    | dep :: deps ->
      let () = remove_dependency hash dep in
      let isolated_nodes = find_isolated_nodes hash in
      let () = remove_nodes isolated_nodes hash in
      sorting_loop
        (List.append deps isolated_nodes) hash (List.append acc isolated_nodes)
  in
  let nodes_hash = graph_hash_of_list nodes in
  let _nodes = _add_missing_nodes nodes nodes_hash in
  let base_nodes = find_isolated_nodes nodes_hash in
  let () = remove_nodes base_nodes nodes_hash in
  let sorted_node_ids = sorting_loop base_nodes nodes_hash [] in
  let sorted_node_ids = List.append base_nodes sorted_node_ids in
  let remaining_ids = Compat.Hashtbl.list_keys nodes_hash in
  match remaining_ids with
  | [] -> Sorted sorted_node_ids
  | _  -> ErrorCycle remaining_ids

(* Functions for dealing with cyclic graphs. *)

let transpose tbl =
  let tbl2 = Hashtbl.create 100 in
  let init v =
    if not (Hashtbl.mem tbl2 v) then
      Hashtbl.add tbl2 v []
  in
  Hashtbl.iter (fun u vl ->
    init u;
    List.iter (fun v ->
      let ul =
	try Hashtbl.find tbl2 v
	with Not_found -> []
      in
      Hashtbl.replace tbl2 v (u :: ul)
    ) vl
  ) tbl;
  tbl2

let _to_list tbl =
  Hashtbl.fold (fun u vl acc -> (u, vl) :: acc) tbl []

(*
   Sort the results of 'partition' so as to follow the original node
   ordering. If not for the user, it's useful for us for testing.
*)
let sort_partition graph_l clusters =
  let priority = Hashtbl.create 100 in
  let () = List.iteri (fun i (v, _) -> Hashtbl.replace priority v i) graph_l in
  let prio v =
    try Hashtbl.find priority v
    with Not_found -> assert false
  in
  let list_prio vl =
    match vl with
    | [] -> assert false
    | x :: _ -> prio x
  in
  let cmp u v = compare (prio u) (prio v) in
  let cmp_list ul vl = compare (list_prio ul) (list_prio vl) in
  List.map (fun l -> List.sort cmp l) clusters |> List.sort cmp_list

(*
   Implementation of Kosaraju's algorithm for partitioning a graph into its
   strongly connected components.
*)
let partition graph_l =
  let graph = graph_hash_of_list graph_l in
  let graph_l = _add_missing_nodes graph_l graph in
  let tr_graph = transpose graph in
  let visits = Hashtbl.create 100 in
  let is_visited v = Hashtbl.mem visits v in
  let mark_visited v = Hashtbl.replace visits v () in
  let get_out_neighbors v =
    try Hashtbl.find graph v
    with Not_found -> assert false
  in
  let get_in_neighbors v =
    try Hashtbl.find tr_graph v
    with Not_found -> assert false
  in
  let rec visit acc v =
    if not (is_visited v) then
      begin
        mark_visited v;
        let out_neighbors = get_out_neighbors v in
        let acc = List.fold_left (fun acc u -> visit acc u) acc out_neighbors in
        v :: acc
      end
    else acc
  in
  let l =
    List.fold_left (fun acc (v, _vl) -> visit acc v) [] graph_l
  in
  let assignments = Hashtbl.create 100 in
  let is_assigned v = Hashtbl.mem assignments v in
  let rec assign v root =
    if not (is_assigned v) then begin
      Hashtbl.replace assignments v root;
      let in_neighbors = get_in_neighbors v in
      List.iter (fun u -> assign u root) in_neighbors
    end
  in
  let () = List.iter (fun v -> assign v v) l
  (* end Kosaraju's algorithm *)
  in
  let clusters = Hashtbl.create 100 in
  let () = Hashtbl.iter (fun v id ->
    let members =
      try Hashtbl.find clusters id
      with Not_found -> []
    in
    Hashtbl.replace clusters id (v :: members)
  ) assignments
  in
  let partition = Hashtbl.fold (fun _id members acc -> members :: acc) clusters [] in
  graph_l, sort_partition graph_l partition

let find_strongly_connected_components graph_l =
  let _completed_graph_l, components = partition graph_l in
  components

(*
   Algorithm:
   1. Identify the strongly-connected components of the input graph.
   2. Derive a DAG from merging the nodes within each component
      (condensation).
   3. Topologically-sort that DAG.
   4. Re-expand the nodes representing components into the original nodes.
*)
let sort_strongly_connected_components graph_l =
  let graph_l, components = partition graph_l in
  let index = Hashtbl.create 100 in
  let rev_index = Hashtbl.create 100 in
  List.iteri (fun id comp ->
    List.iter (fun v ->
      Hashtbl.add index v id;
      Hashtbl.add rev_index id comp
    ) comp
  ) components;

  let get_comp_id v =
    try Hashtbl.find index v
    with Not_found -> assert false
  in
  let get_comp_members id =
    try Hashtbl.find rev_index id
    with Not_found -> assert false
  in
  let condensation =
    let tbl = Hashtbl.create 100 in
    List.iter (fun (u, vl) ->
      let id = get_comp_id u in
      let idl0 =
        try Hashtbl.find tbl id
        with Not_found -> []
      in
      let idl = List.map get_comp_id vl @ idl0 in
      Hashtbl.replace tbl id idl
    ) graph_l;
    Hashtbl.fold (fun id idl acc ->
      (* Remove v->v edges because they are not supported by tsort.
         Duplicates seem ok. *)
      let filtered = List.filter ((<>) id) idl in
      (id, filtered) :: acc
    ) tbl []
  in
  let sorted_components =
    match sort condensation with
    | Sorted comp_ids -> List.map get_comp_members comp_ids
    | ErrorCycle _ ->
      (* Shouldn't happen if graph partioning etc. work correctly. *)
      failwith "ocaml-tsort internal error: sorting strongly connected components failed. Please report a bug."
  in
  sorted_components

let find_dependencies graph node =
  let rec aux graph node =
    let deps = List.assoc node graph in
    List.concat (List.map (aux graph) deps) |> List.append deps
  in
  let graph_hash = graph_hash_of_list graph in
  let graph = _add_missing_nodes graph graph_hash in
  aux graph node |> deduplicate
