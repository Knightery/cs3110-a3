(* Exercise exceptional unwinding through the real terminal guard. *)
let () =
  try
    Terminal.with_mode (fun _ ->
        print_endline "READY";
        ignore (input_char stdin);
        failwith "deliberate terminal cleanup probe")
  with Failure _ -> print_endline "Exception guard restored terminal"
