open OUnit2
open Labyrinth

let p row col : World.position = { row; col }

let layout rows =
  let loot = ref [] in
  let terrain =
    Array.of_list
      (List.mapi
         (fun r line ->
           Array.init (String.length line) (fun c ->
               (match line.[c] with
               | 'c' -> loot := (p r c, World.Copper) :: !loot
               | 's' -> loot := (p r c, World.Silver) :: !loot
               | 'g' -> loot := (p r c, World.Gold) :: !loot
               | _ -> ());
               match line.[c] with
               | '#' -> World.Wall
               | '>' -> World.Exit
               | _ -> World.Floor))
         rows)
  in
  World.of_layout terrain !loot

let start rows camel worm =
  Game.start ~world:(layout rows) ~camel ~worm ~seed:42

let isolated =
  [
    "#########"; "#.......#"; "#.......#"; "#########"; "#######.#"; "#########";
  ]

let fresh () = start isolated (p 1 1) (p 4 7)

let snapshot g =
  ( Display.render g,
    Game.camel g,
    Game.worm g,
    Game.turns g,
    Game.score g,
    Game.outcome g )

let check_pos expected actual = assert_equal expected actual

let core_tests =
  [
    ( "world copies rows and loot" >:: fun _ ->
      let cells = Array.make_matrix 2 3 World.Floor in
      let w =
        World.of_layout cells [ (p 0 0, World.Gold); (p 1 0, World.Copper) ]
      in
      cells.(0).(0) <- World.Wall;
      let other = World.copy w in
      assert_equal (Some World.Floor) (World.terrain_at w (p 0 0));
      assert_equal 5 (World.collect_at w (p 0 0));
      assert_equal 0 (World.collect_at w (p 0 0));
      assert_equal 1 (World.collect_at w (p 1 0));
      assert_equal 5 (World.collect_at other (p 0 0));
      assert_equal None (World.terrain_at w (p (-1) 0)) );
    ( "world rejects malformed layouts" >:: fun _ ->
      List.iter
        (fun f ->
          try
            ignore (f ());
            assert_failure "accepted invalid layout"
          with Invalid_argument _ -> ())
        [
          (fun () -> World.of_layout [||] []);
          (fun () -> World.of_layout [| [||] |] []);
          (fun () -> World.of_layout [| [| World.Floor |]; [||] |] []);
          (fun () ->
            World.of_layout [| [| World.Wall |] |] [ (p 0 0, World.Gold) ]);
          (fun () ->
            World.of_layout [| [| World.Floor |] |]
              [ (p 0 0, World.Gold); (p 0 0, World.Silver) ]);
          (fun () ->
            World.of_layout [| [| World.Floor |] |] [ (p 1 0, World.Gold) ]);
        ] );
    ( "blocked and boundary moves change nothing" >:: fun _ ->
      let g = fresh () in
      let before = snapshot g in
      Game.apply g Game.Up;
      Game.apply g Game.Left;
      assert_equal before (snapshot g);
      let edge = start [ "..."; "###"; "..#" ] (p 0 0) (p 2 0) in
      let before = snapshot edge in
      Game.apply edge Game.Up;
      Game.apply edge Game.Left;
      assert_equal before (snapshot edge) );
    ( "move wait and persistent discovery" >:: fun _ ->
      let g = fresh () in
      assert_bool "starting cross" (Game.revealed g (p 0 1));
      assert_bool "diagonal hidden" (not (Game.revealed g (p 2 2)));
      Game.apply g Game.Right;
      check_pos (p 1 2) (Game.camel g);
      assert_equal 1 (Game.turns g);
      assert_bool "new cross" (Game.revealed g (p 2 2));
      Game.apply g Game.Right;
      Game.apply g Game.Left;
      assert_bool "old discovery persists" (Game.revealed g (p 1 4));
      Game.apply g Game.Wait;
      assert_equal 4 (Game.turns g);
      check_pos (p 4 7) (Game.worm g) );
    ( "worm visible without revealing" >:: fun _ ->
      let g = fresh () in
      assert_equal Game.Worm (Game.cell_view g (p 4 7));
      assert_bool "worm tile stays hidden" (not (Game.revealed g (p 4 7)));
      assert_equal Game.Hidden (Game.cell_view g (p 4 6));
      assert_equal Game.Wall (Game.cell_view g (p 0 1));
      assert_equal Game.Camel (Game.cell_view g (p 1 1)) );
    ( "treasure values and collection once" >:: fun _ ->
      let g =
        start
          [ "#########"; "#.csg>..#"; "#########"; "#######.#"; "#########" ]
          (p 1 1) (p 3 7)
      in
      Game.apply g Game.Right;
      assert_equal 1 (Game.score g);
      Game.apply g Game.Left;
      Game.apply g Game.Right;
      assert_equal 1 (Game.score g);
      Game.apply g Game.Right;
      assert_equal 4 (Game.score g);
      Game.apply g Game.Right;
      assert_equal 9 (Game.score g);
      Game.apply g Game.Right;
      assert_equal Game.Won (Game.outcome g);
      assert_equal Game.Victory (Game.cell_view g (p 1 5)) );
    ( "exit below threshold traversable" >:: fun _ ->
      let g =
        start
          [ "#########"; "#.>.....#"; "#########"; "#######.#"; "#########" ]
          (p 1 1) (p 3 7)
      in
      Game.apply g Game.Right;
      check_pos (p 1 2) (Game.camel g);
      assert_equal Game.Playing (Game.outcome g);
      Game.apply g Game.Right;
      assert_equal Game.Exit (Game.cell_view g (p 1 2)) );
    ( "collision before pickup and no further turns" >:: fun _ ->
      let g = start [ "#####"; "#.g.#"; "#####" ] (p 1 1) (p 1 2) in
      Game.apply g Game.Right;
      assert_equal Game.Lost (Game.outcome g);
      assert_equal 0 (Game.score g);
      assert_equal 1 (Game.turns g);
      assert_equal Game.Defeat (Game.cell_view g (p 1 2));
      let before = snapshot g in
      Game.apply g Game.Left;
      assert_equal before (snapshot g) );
    ( "worm collision after wait" >:: fun _ ->
      let g = start [ "#####"; "#...#"; "#####" ] (p 1 1) (p 1 2) in
      Game.apply g Game.Wait;
      assert_equal Game.Lost (Game.outcome g);
      check_pos (p 1 1) (Game.worm g) );
    ( "worm north wins equal distance" >:: fun _ ->
      let g =
        start [ "#####"; "#...#"; "#...#"; "#...#"; "#####" ] (p 1 1) (p 2 2)
      in
      Game.apply g Game.Wait;
      check_pos (p 1 2) (Game.worm g) );
    ( "worm east beats south" >:: fun _ ->
      let g =
        start [ "#####"; "#...#"; "#...#"; "#...#"; "#####" ] (p 3 3) (p 2 2)
      in
      Game.apply g Game.Wait;
      check_pos (p 2 3) (Game.worm g) );
    ( "worm south beats west" >:: fun _ ->
      let g =
        start [ "#####"; "#...#"; "#...#"; "#...#"; "#####" ] (p 3 1) (p 2 2)
      in
      Game.apply g Game.Wait;
      check_pos (p 3 2) (Game.worm g) );
    ( "worm must move away and cannot enter exit" >:: fun _ ->
      let g =
        start [ "#######"; "#..>.##"; "####.##"; "#######" ] (p 1 1) (p 1 4)
      in
      Game.apply g Game.Wait;
      check_pos (p 2 4) (Game.worm g) );
    ( "worm does not collect loot or reveal its trail" >:: fun _ ->
      let g = start [ "########"; "#....g.#"; "########" ] (p 1 1) (p 1 6) in
      Game.apply g Game.Wait;
      check_pos (p 1 5) (Game.worm g);
      assert_bool "unseen trail" (not (Game.revealed g (p 1 5)));
      Game.apply g Game.Wait;
      Game.apply g Game.Wait;
      assert_equal 0 (Game.score g) );
    ( "treasure remains after worm passes over it" >:: fun _ ->
      let g = start [ "#####"; "#.g.#"; "#...#"; "#####" ] (p 1 1) (p 1 3) in
      Game.apply g Game.Wait;
      check_pos (p 1 2) (Game.worm g);
      Game.apply g Game.Down;
      check_pos (p 2 2) (Game.worm g);
      assert_equal Game.Gold (Game.cell_view g (p 1 2));
      assert_equal 0 (Game.score g) );
    ( "victory skips worm and freezes state" >:: fun _ ->
      let g = start [ "########"; "#.gs>.##"; "########" ] (p 1 1) (p 1 5) in
      Game.apply g Game.Right;
      assert_equal 5 (Game.score g);
      check_pos (p 1 5) (Game.worm g);
      Game.apply g Game.Right;
      assert_equal 8 (Game.score g);
      check_pos (p 1 5) (Game.worm g);
      Game.apply g Game.Right;
      assert_equal Game.Won (Game.outcome g);
      check_pos (p 1 5) (Game.worm g);
      let before = snapshot g in
      Game.apply g Game.Wait;
      assert_equal before (snapshot g) );
    ( "games and renderer are independent" >:: fun _ ->
      let w =
        layout
          [ "#########"; "#.g.....#"; "#########"; "#######.#"; "#########" ]
      in
      let make () = Game.start ~world:w ~camel:(p 1 1) ~worm:(p 3 7) ~seed:42 in
      let a = make () and b = make () in
      let before = snapshot b in
      Game.apply a Game.Right;
      assert_equal 5 (Game.score a);
      assert_equal before (snapshot b);
      let own = snapshot a in
      ignore (Display.render a);
      ignore (Display.render a);
      assert_equal own (snapshot a);
      assert_equal (Some World.Gold) (World.lambda_at w (p 1 2)) );
    ( "invalid game placement rejected" >:: fun _ ->
      let w = layout [ "###"; "#>."; "###" ] in
      List.iter
        (fun (camel, worm, seed) ->
          try
            ignore (Game.start ~world:w ~camel ~worm ~seed);
            assert_failure "accepted invalid game"
          with Invalid_argument _ -> ())
        [
          (p 0 0, p 1 2, 0);
          (p 1 1, p 1 1, 0);
          (p 1 2, p 1 1, 0);
          (p 1 1, p 1 2, -1);
        ] );
  ]

(* Independent breadth-first search: test expected reachability rather than
   reusing the generator's traversal or its placement validation. *)
let reachable w origin blocked =
  let seen = Hashtbl.create 300 and q = Queue.create () in
  Hashtbl.add seen origin ();
  Queue.add origin q;
  while not (Queue.is_empty q) do
    let at = Queue.take q in
    List.iter
      (fun (dr, dc) ->
        let next = p (at.World.row + dr) (at.World.col + dc) in
        if Some next <> blocked && not (Hashtbl.mem seen next) then
          match World.terrain_at w next with
          | Some World.Floor | Some World.Exit ->
              Hashtbl.add seen next ();
              Queue.add next q
          | _ -> ())
      [ (0, 1); (1, 0); (0, -1); (-1, 0) ]
  done;
  seen

let world_snapshot (w, c, worm) =
  let rows, cols = World.dimensions w in
  ( Array.init rows (fun r ->
        Array.init cols (fun col ->
            (World.terrain_at w (p r col), World.lambda_at w (p r col)))),
    c,
    worm )

let generator_tests =
  [
    ( "seed repeatability and global RNG independence" >:: fun _ ->
      List.iter
        (fun seed ->
          let first = world_snapshot (Generate.create ~seed) in
          ignore (Generate.create ~seed:999);
          Random.init 31;
          ignore (Random.int 100);
          assert_equal first (world_snapshot (Generate.create ~seed)))
        [ 0; 1; 2; 42; 2026; max_int ] );
    ( "seed properties across 100 worlds" >:: fun _ ->
      for seed = 0 to 99 do
        let w, c, worm = Generate.create ~seed in
        let rows, cols = World.dimensions w in
        assert_bool "bounded grid" (rows <= 20 && cols <= 70);
        assert_equal (Some World.Floor) (World.terrain_at w c);
        assert_equal (Some World.Floor) (World.terrain_at w worm);
        let exits = ref [] and loot = ref [] and floors = ref [] in
        for r = 0 to rows - 1 do
          for col = 0 to cols - 1 do
            let pos = p r col in
            let terrain = World.terrain_at w pos in
            if r = 0 || col = 0 || r = rows - 1 || col = cols - 1 then
              assert_equal (Some World.Wall) terrain;
            (match terrain with
            | Some World.Exit -> exits := pos :: !exits
            | Some World.Floor -> floors := pos :: !floors
            | _ -> ());
            match World.lambda_at w pos with
            | None -> ()
            | Some item -> loot := (pos, item) :: !loot
          done
        done;
        assert_equal 1 (List.length !exits);
        let exit = List.hd !exits in
        assert_bool "distinct" (c <> worm && c <> exit && worm <> exit);
        List.iter
          (fun pos ->
            assert_bool "distance >= 6"
              (abs (pos.World.row - c.row) + abs (pos.col - c.col) >= 6))
          [ worm; exit ];
        let seen = reachable w c None in
        assert_bool "exit reachable" (Hashtbl.mem seen exit);
        List.iter
          (fun pos -> assert_bool "connected rooms" (Hashtbl.mem seen pos))
          !floors;
        assert_bool "worm path excludes exit"
          (Hashtbl.mem (reachable w worm (Some exit)) c);
        assert_bool "multiple treasure" (List.length !loot >= 2);
        let total =
          List.fold_left
            (fun sum (pos, item) ->
              assert_bool "loot not occupied"
                (pos <> c && pos <> worm && pos <> exit);
              assert_equal (Some World.Floor) (World.terrain_at w pos);
              assert_bool "reachable loot" (Hashtbl.mem seen pos);
              sum
              + match item with World.Copper -> 1 | Silver -> 3 | Gold -> 5)
            0 !loot
        in
        assert_bool "enough loot" (total >= 8)
      done );
    ( "terrain varies across seeds" >:: fun _ ->
      let terrain seed =
        let grid, _, _ = world_snapshot (Generate.create ~seed) in
        Array.map (Array.map fst) grid
      in
      let base = terrain 0 in
      assert_bool "variation"
        (List.exists (fun seed -> terrain seed <> base) [ 1; 2; 42; 2026 ]) );
    ( "negative generator seed rejected" >:: fun _ ->
      try
        ignore (Generate.create ~seed:(-1));
        assert_failure "negative seed accepted"
      with Invalid_argument _ -> () );
  ]

let contains text part =
  let n = String.length part in
  let rec go i =
    i + n <= String.length text && (String.sub text i n = part || go (i + 1))
  in
  go 0

let color_tests =
  [
    ( "frame shows score, required, turns, seed and controls" >:: fun _ ->
      let g = fresh () in
      Game.apply g Game.Right;
      let frame = Display.render g in
      List.iter
        (fun part -> assert_bool part (contains frame part))
        [
          "Lambdas: 0/8";
          "Turns: 1";
          "Seed: 42";
          "WASD: move";
          "q: quit";
          "Collect 8 points";
        ] );
    ( "colored frame preserves content and state" >:: fun _ ->
      let g = fresh () in
      let before = snapshot g in
      let colored = Display.render ~color:true g in
      assert_bool "ANSI styling present" (String.contains colored '\027');
      let plain = Buffer.create (String.length colored) in
      let rec strip i =
        if i < String.length colored then
          if colored.[i] = '\027' then begin
            let stop = String.index_from colored i 'm' in
            strip (stop + 1)
          end
          else begin
            Buffer.add_char plain colored.[i];
            strip (i + 1)
          end
      in
      strip 0;
      assert_equal (Display.render g) (Buffer.contents plain);
      assert_equal before (snapshot g) );
  ]

let () =
  run_test_tt_main
    ("Lambda Labyrinth" >::: core_tests @ generator_tests @ color_tests)
