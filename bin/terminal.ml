open Labyrinth

exception Interrupted of int

let with_mode f =
  let fd = Unix.stdin in
  let saved = if Unix.isatty fd then Some (Unix.tcgetattr fd) else None in
  let old_int =
    Sys.signal Sys.sigint (Sys.Signal_handle (fun _ -> raise (Interrupted 2)))
  in
  let old_term =
    Sys.signal Sys.sigterm (Sys.Signal_handle (fun _ -> raise (Interrupted 15)))
  in
  Fun.protect
    ~finally:(fun () ->
      (* Restore input before output, so even an output failure cannot leave
         the shell in immediate-input mode. *)
      (match saved with
      | None -> ()
      | Some attrs -> Unix.tcsetattr fd Unix.TCSANOW attrs);
      Sys.set_signal Sys.sigint old_int;
      Sys.set_signal Sys.sigterm old_term;
      if saved <> None then (
        output_string stdout "\027[0m\027[?25h\n";
        flush stdout))
    (fun () ->
      (match saved with
      | None -> ()
      | Some attrs ->
          Unix.tcsetattr fd Unix.TCSANOW
            {
              attrs with
              Unix.c_icanon = false;
              c_echo = false;
              c_vmin = 1;
              c_vtime = 0;
            };
          output_string stdout "\027[?25l\027[2J");
      f (saved <> None))

(* Lowercase only: arrow and function keys arrive as escape sequences ending
   in uppercase letters (up = ESC [ A, left = ESC [ D, F2 = ESC O Q), so
   accepting uppercase would turn those unrecognized keys into moves. *)
let action = function
  | 'w' -> Some Game.Up
  | 'a' -> Some Game.Left
  | 's' -> Some Game.Down
  | 'd' -> Some Game.Right
  | '.' -> Some Game.Wait
  | _ -> None

let run game =
  with_mode (fun interactive ->
      let draw () =
        if interactive then output_string stdout "\027[H";
        output_string stdout
          (Display.render ~color:(interactive && Unix.isatty Unix.stdout) game);
        if interactive then output_string stdout "\027[J";
        flush stdout
      in
      let rec loop () =
        draw ();
        if Game.outcome game = Game.Playing then
          match input_char stdin with
          | 'q' -> ()
          | key ->
              Option.iter (Game.apply game) (action key);
              loop ()
          | exception End_of_file -> ()
      in
      loop ())
