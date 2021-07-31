(*
   Basic functions not available in older versions of OCaml's standard
   library.
*)

module Hashtbl = struct
  let find_opt tbl key =
    try Some (Hashtbl.find tbl key)
    with Not_found -> None

  let list_keys tbl =
    Hashtbl.fold (fun k _ acc -> k :: acc) tbl []
end

module List = struct
  let filter_map f l =
    List.fold_left (fun acc x ->
      match f x with
      | None -> acc
      | Some y -> y :: acc
    ) [] l
    |> List.rev

  let find_opt f l =
    try Some (List.find f l)
    with Not_found -> None

  let rec remove ?(eq=(=)) ~key xs =
    match xs with
    | [] -> []
    | x :: xs ->
      if eq x key then xs
      else x :: (remove ~eq:eq ~key:key xs)
end
