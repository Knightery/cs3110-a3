open Labyrinth

let usage =
  "Usage: dune exec bin/main.exe -- [seed]\n\
   Seed must be a nonnegative integer. WASD move, . wait, q quit."

let parse_seed text =
  match int_of_string_opt text with
  | Some seed when seed >= 0 -> seed
  | _ ->
      prerr_endline
        "Error: seed must be a nonnegative integer within the OCaml integer \
         range.";
      exit 2

let () =
  let seed =
    match Array.to_list Sys.argv with
    | [ _; ("--help" | "-h") ] ->
        print_endline usage;
        exit 0
    | [ _; text ] -> parse_seed text
    | [ _ ] -> Random.State.int (Random.State.make_self_init ()) 1_000_000_000
    | _ ->
        prerr_endline usage;
        exit 2
  in
  try
    let world, camel, worm = Generate.create ~seed in
    Terminal.run (Game.start ~world ~camel ~worm ~seed)
  with
  | Terminal.Interrupted signal -> exit (128 + signal)
  | exn ->
      prerr_endline ("Game error: " ^ Printexc.to_string exn);
      exit 1
