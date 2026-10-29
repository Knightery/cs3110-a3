type position = { row : int; col : int }
type terrain = Wall | Floor | Exit
type lambda = Copper | Silver | Gold
type t = { terrain : terrain array array; treasure : lambda option array array }

let dimensions w = (Array.length w.terrain, Array.length w.terrain.(0))

let in_bounds w p =
  let rows, cols = dimensions w in
  p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols

let terrain_at w p =
  if in_bounds w p then Some w.terrain.(p.row).(p.col) else None

let lambda_at w p = if in_bounds w p then w.treasure.(p.row).(p.col) else None

let of_layout terrain loot =
  let rows = Array.length terrain in
  if rows = 0 then invalid_arg "World.of_layout: empty grid";
  let cols = Array.length terrain.(0) in
  if cols = 0 || Array.exists (fun row -> Array.length row <> cols) terrain then
    invalid_arg "World.of_layout: grid must be nonempty and rectangular";
  let w =
    {
      terrain = Array.map Array.copy terrain;
      treasure = Array.make_matrix rows cols None;
    }
  in
  List.iter
    (fun (p, item) ->
      if terrain_at w p <> Some Floor then
        invalid_arg "World.of_layout: treasure must be on an in-bounds floor";
      if lambda_at w p <> None then
        invalid_arg "World.of_layout: duplicate treasure";
      w.treasure.(p.row).(p.col) <- Some item)
    loot;
  w

let copy w =
  {
    terrain = Array.map Array.copy w.terrain;
    treasure = Array.map Array.copy w.treasure;
  }

let collect_at w p =
  match lambda_at w p with
  | None -> 0
  | Some item -> (
      w.treasure.(p.row).(p.col) <- None;
      match item with Copper -> 1 | Silver -> 3 | Gold -> 5)
