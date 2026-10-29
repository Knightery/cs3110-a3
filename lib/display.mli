val render : ?color:bool -> Game.t -> string
(** Returns the map, score, turns, seed, outcome and controls without mutation.
    [color] defaults to [false]; [true] uses ANSI colors with actor backgrounds.
    Removing ANSI styling yields the same text as the plain frame. *)
