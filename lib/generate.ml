open World

let position row col = { row; col }
let distance a b = abs (a.row - b.row) + abs (a.col - b.col)

let shuffle rng items =
  let a = Array.of_list items in
  for i = Array.length a - 1 downto 1 do
    let j = Random.State.int rng (i + 1) in
    let saved = a.(i) in
    a.(i) <- a.(j);
    a.(j) <- saved
  done;
  Array.to_list a

let create ~seed =
  if seed < 0 then invalid_arg "Generate.create: seed must be nonnegative";
  let rng = Random.State.make [| seed |] in
  let rows = 17 and cols = 41 in
  let cells = Array.make_matrix rows cols Wall in
  let carve p = cells.(p.row).(p.col) <- Floor in
  let room top left =
    let height = 4 + Random.State.int rng 3 in
    let width = 10 + Random.State.int rng 6 in
    let row = top + Random.State.int rng (7 - height) in
    let col = left + Random.State.int rng (18 - width) in
    for r = row to row + height - 1 do
      for c = col to col + width - 1 do
        carve (position r c)
      done
    done;
    position (row + (height / 2)) (col + (width / 2))
  in
  let nw = room 1 1 in
  let ne = room 1 22 in
  let sw = room 10 1 in
  let se = room 10 22 in
  let connect a b =
    for col = min a.col b.col to max a.col b.col do
      carve (position a.row col)
    done;
    for row = min a.row b.row to max a.row b.row do
      carve (position row b.col)
    done
  in
  connect nw ne;
  connect ne se;
  connect se sw;
  connect sw nw;
  let floors = ref [] in
  for row = 1 to rows - 2 do
    for col = 1 to cols - 2 do
      if cells.(row).(col) = Floor then floors := position row col :: !floors
    done
  done;
  let floors = shuffle rng !floors in
  let camel = List.hd floors in
  (* Check connectivity explicitly. Treat a proposed exit as blocked while
     choosing the worm, since it may not traverse that cell. *)
  let flood blocked =
    let seen = Array.make_matrix rows cols false in
    let queue = Queue.create () in
    Queue.add camel queue;
    seen.(camel.row).(camel.col) <- true;
    while not (Queue.is_empty queue) do
      let at = Queue.take queue in
      List.iter
        (fun p ->
          if
            p.row >= 0 && p.row < rows && p.col >= 0 && p.col < cols
            && Some p <> blocked
            && cells.(p.row).(p.col) = Floor
            && not seen.(p.row).(p.col)
          then begin
            seen.(p.row).(p.col) <- true;
            Queue.add p queue
          end)
        [
          position (at.row - 1) at.col;
          position at.row (at.col + 1);
          position (at.row + 1) at.col;
          position at.row (at.col - 1);
        ]
    done;
    seen
  in
  let connected = flood None in
  if not (List.for_all (fun p -> connected.(p.row).(p.col)) floors) then
    failwith "Generate.create: room construction produced disconnected terrain";
  let far = List.filter (fun p -> distance camel p >= 6) floors in
  let rec choose = function
    | [] -> failwith "Generate.create: no valid exit and worm placement"
    | exit :: rest -> (
        let seen = flood (Some exit) in
        match
          List.find_opt (fun p -> p <> exit && seen.(p.row).(p.col)) far
        with
        | Some worm -> (exit, worm)
        | None -> choose rest)
  in
  let exit, worm = choose far in
  let remaining =
    List.filter (fun p -> p <> camel && p <> exit && p <> worm) floors
  in
  let loot =
    match remaining with
    | a :: b :: c :: d :: _ ->
        [ (a, Gold); (b, Silver); (c, Copper); (d, Copper) ]
    | _ -> failwith "Generate.create: insufficient treasure cells"
  in
  cells.(exit.row).(exit.col) <- Exit;
  (World.of_layout cells loot, camel, worm)
