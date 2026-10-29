let symbol = function
  | Game.Hidden -> '?'
  | Wall -> '#'
  | Floor -> '.'
  | Exit -> '>'
  | Copper -> 'c'
  | Silver -> 's'
  | Gold -> 'g'
  | Camel -> 'C'
  | Worm -> 'W'
  | Defeat -> 'X'
  | Victory -> '^'

let color_code = function
  | Game.Hidden -> "90"
  | Wall -> "1;97"
  | Floor -> "37"
  | Exit | Victory -> "1;92"
  | Copper -> "33"
  | Silver -> "1;97"
  | Gold -> "1;93"
  | Camel -> "1;30;106"
  | Worm | Defeat -> "1;97;41"

let render ?(color = false) g =
  let rows, cols = Game.dimensions g in
  let b = Buffer.create ((rows + 6) * (cols + 1)) in
  let styled code text =
    if color then Buffer.add_string b ("\027[" ^ code ^ "m");
    Buffer.add_string b text;
    if color then Buffer.add_string b "\027[0m"
  in
  styled "1;96" "Lambda Labyrinth: The Lambda Must Flow\n";
  for row = 0 to rows - 1 do
    for col = 0 to cols - 1 do
      let cell = Game.cell_view g { World.row; col } in
      styled (color_code cell) (String.make 1 (symbol cell))
    done;
    Buffer.add_char b '\n'
  done;
  styled "1;93"
    (Printf.sprintf "\nLambdas: %d/%d    Turns: %d    Seed: %d\n" (Game.score g)
       (Game.required g) (Game.turns g) (Game.seed g));
  Buffer.add_string b "WASD: move    .: wait    q: quit\n";
  List.iter
    (fun (cell, text) -> styled (color_code cell) text)
    [
      (Game.Camel, "C camel");
      (Worm, " | W worm");
      (Hidden, " | ? unseen");
      (Wall, " | # wall");
      (Floor, " | . floor");
      (Copper, " | c");
      (Silver, "/s");
      (Gold, "/g treasure");
      (Exit, " | > exit\n");
    ];
  (match Game.outcome g with
  | Playing ->
      Buffer.add_string b
        (Printf.sprintf "Collect %d points, then enter > to escape.\n"
           (Game.required g))
  | Won -> styled "1;92" "^ Escaped! The lambda must flow.\n"
  | Lost -> styled "1;91" "X The sandworm caught you.\n");
  Buffer.contents b
