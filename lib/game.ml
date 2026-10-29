type action = Up | Down | Left | Right | Wait
type outcome = Playing | Won | Lost

type visible_cell =
  | Hidden
  | Wall
  | Floor
  | Exit
  | Copper
  | Silver
  | Gold
  | Camel
  | Worm
  | Defeat
  | Victory

type t = {
  world : World.t;
  mutable camel : World.position;
  mutable worm : World.position;
  revealed : bool array array;
  mutable score : int;
  mutable turns : int;
  seed : int;
  mutable outcome : outcome;
}

let dimensions g = World.dimensions g.world
let camel g = g.camel
let worm g = g.worm
let score g = g.score
let required _ = 8
let turns g = g.turns
let seed g = g.seed
let outcome g = g.outcome

let neighbors (p : World.position) =
  [
    { p with row = p.row - 1 };
    { p with col = p.col + 1 };
    { p with row = p.row + 1 };
    { p with col = p.col - 1 };
  ]

let revealed g (p : World.position) =
  match World.terrain_at g.world p with
  | None -> false
  | Some _ -> g.revealed.(p.row).(p.col)

let reveal g =
  List.iter
    (fun (p : World.position) ->
      match World.terrain_at g.world p with
      | None -> ()
      | Some _ -> g.revealed.(p.row).(p.col) <- true)
    (g.camel :: neighbors g.camel)

let walkable w p =
  match World.terrain_at w p with
  | Some World.Floor | Some World.Exit -> true
  | _ -> false

let start ~world ~camel ~worm ~seed =
  if seed < 0 then invalid_arg "Game.start: seed must be nonnegative";
  if
    (not (walkable world camel))
    || World.terrain_at world worm <> Some World.Floor
    || camel = worm
  then invalid_arg "Game.start: invalid actor placements";
  let rows, cols = World.dimensions world in
  let g =
    {
      world = World.copy world;
      camel;
      worm;
      revealed = Array.make_matrix rows cols false;
      score = 0;
      turns = 0;
      seed;
      outcome = Playing;
    }
  in
  reveal g;
  g

let distance (a : World.position) (b : World.position) =
  abs (a.row - b.row) + abs (a.col - b.col)

let move_worm g =
  (* Strict improvement preserves the first candidate on ties: N/E/S/W.
     Do not compare to the current tile: moving away can be mandatory. *)
  let best =
    List.fold_left
      (fun best p ->
        if World.terrain_at g.world p <> Some World.Floor then best
        else
          match best with
          | None -> Some p
          | Some old ->
              if distance p g.camel < distance old g.camel then Some p else best)
      None (neighbors g.worm)
  in
  match best with None -> () | Some p -> g.worm <- p

let apply g action =
  if g.outcome = Playing then begin
    let target =
      match action with
      | Up -> { g.camel with row = g.camel.row - 1 }
      | Down -> { g.camel with row = g.camel.row + 1 }
      | Left -> { g.camel with col = g.camel.col - 1 }
      | Right -> { g.camel with col = g.camel.col + 1 }
      | Wait -> g.camel
    in
    if walkable g.world target then begin
      g.turns <- g.turns + 1;
      g.camel <- target;
      reveal g;
      if g.camel = g.worm then g.outcome <- Lost
      else begin
        g.score <- g.score + World.collect_at g.world g.camel;
        if
          g.score >= required g
          && World.terrain_at g.world g.camel = Some World.Exit
        then g.outcome <- Won
        else begin
          move_worm g;
          if g.camel = g.worm then g.outcome <- Lost
        end
      end
    end
  end

let cell_view g p =
  if p = g.camel then
    match g.outcome with Won -> Victory | Lost -> Defeat | Playing -> Camel
  else if p = g.worm then Worm
  else if not (revealed g p) then Hidden
  else
    match World.lambda_at g.world p with
    | Some World.Copper -> Copper
    | Some World.Silver -> Silver
    | Some World.Gold -> Gold
    | None -> (
        match World.terrain_at g.world p with
        | Some World.Wall -> Wall
        | Some World.Floor -> Floor
        | Some World.Exit -> Exit
        | None -> Hidden)
