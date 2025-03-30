(*
   Test suite and entry point of the test executable.
*)

open Printf

let fmt_list to_string l =
  sprintf "[%s]" (l |> List.map to_string |> String.concat " ")

let fmt_graph l =
  sprintf "[%s]"
    (l
     |> List.map (fun (v, vl) -> sprintf "%i->%s"
                     v (fmt_list string_of_int vl))
     |> String.concat " ")

let fmt_partition l =
  fmt_list (fmt_list string_of_int) l

let fmt_tsort_result res =
  match res with
  | Tsort.Sorted l ->
      sprintf "Sorted %s" (fmt_list string_of_int l)
  | Tsort.ErrorCycle l ->
      sprintf "ErrorCycle %s" (fmt_list string_of_int l)

let test_find_nonexistent_nodes () =
  (* basic functionality *)
  assert (
    (Tsort.find_nonexistent_nodes
       [1, []; 2, [3]]
    )
    = [2, [3]]
  );
  (* check edge filtering *)
  assert (
    (Tsort.find_nonexistent_nodes
       [1, []; 2, [3]; 4, [5; 6; 7; 5]; 6, [2]]
    )
    = [2, [3]; 4, [5; 7]]
  )

let test_tsort () =
  let sort graph =
    printf "input: %s\n%!" (fmt_graph graph);
    let res = Tsort.sort graph in
    printf "output: %s\n%!" (fmt_tsort_result res);
    res
  in
  assert (sort [] = Sorted []);
  assert (
    sort [
      1, [2];
      2, [3; 4];
      3, [4; 5];
      4, [6];
      5, [6];
      6, [7];
      7, [];
    ]
    =
    (* Multiple solutions are valid. This is the one returned by the current
       implementation. *)
    Sorted [7; 6; 4; 5; 3; 2; 1]
  );
  (* Tolerate missing nodes. *)
  assert (
    sort [1, [2]; 2, [3] (* 3 is missing *)] = Sorted [3; 2; 1]
  );
  (* Tolerate partial dependency lists. *)
    assert (
    sort [1, []; 2, []; 3, [2]; 3, [1]] = Sorted [1; 2; 3]
  )

let test_find_sc_components () =
  let p graph =
    printf "input: %s\n%!" (fmt_graph graph);
    let partition = Tsort.find_strongly_connected_components graph in
    printf "output: %s\n%!" (fmt_partition partition);
    partition
  in
  assert (p [] = []);
  assert (p [0, []] = [[0]]);

  (* tolerate duplicate node entries *)
  assert (p [0, [1]; 0, [2]; 1, []; 2, []] = [[0]; [1]; [2]]);

  (* tolerate missing node entries *)
  assert (p [0, [1; 2]] = [[0]; [1]; [2]]);

  (* sort result according to original order *)
  assert (
    p [
      2, [];
      0, [2];
      1, [0]
    ]
    = [[2]; [0]; [1]]
  );

  assert (
    p [
      1, [2];
      2, [3; 4];
      3, [4];
      4, [2; 5]
    ]
    = [[1]; [2; 3; 4]; [5]]
  )

let test_sort_sc_components () =
  let sort graph =
    printf "input: %s\n%!" (fmt_graph graph);
    let components = Tsort.sort_strongly_connected_components graph in
    printf "output: %s\n%!" (fmt_partition components);
    components
  in
  assert (sort [] = []);
  assert (sort [0,[]] = [[0]]);
  assert (
    sort [
      1, [2];
      2, [3; 4];
      3, [4];
      4, [2; 5]
    ]
    = [[5]; [2; 3; 4]; [1]]
  )

let test_find_dependencies () =
  let graph = [1, [2; 3]; 2, [3; 5]; 3, [5; 8]] in
  assert(
    (Tsort.find_dependencies graph 1 |> List.sort compare) =
    [2; 3; 5; 8]
  );
  assert(
    (Tsort.find_dependencies graph 2 |> List.sort compare) =
    [3; 5; 8]
  );
  assert((Tsort.find_dependencies graph 8) = [])

let test_add_missing_nodes () =
  let graph = [1, [2]] in
  assert((Tsort.add_missing_nodes graph) = [1, [2]; 2, []])

let main () =
  Alcotest.run "Tsort" [
    "Tsort", [
      "find nonexistent nodes", `Quick, test_find_nonexistent_nodes;
      "sort", `Quick, test_tsort;
      "find s.c. components", `Quick, test_find_sc_components;
      "sort s.c. components", `Quick, test_sort_sc_components;
      "find dependencies", `Quick, test_find_dependencies;
      "add_missing_nodes", `Quick, test_add_missing_nodes;
    ];
  ]

let () = main ()
