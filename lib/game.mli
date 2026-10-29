type t
(** Mutable game state; owns an independent World copy. *)

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

val start :
  world:World.t -> camel:World.position -> worm:World.position -> seed:int -> t
(** Reveals the starting cross. Raises [Invalid_argument] for negative seed,
    overlapping actors, nontraversable camel or worm not on floor. Tiny explicit
    worlds need not meet generation constraints. *)

val apply : t -> action -> unit
(** One legal move or wait; blocked moves and finished games are unchanged.
    Collision precedes pickup; victory precedes worm movement. *)

val cell_view : t -> World.position -> visible_cell
(** Actor/outcome precedence, then fog, treasure and terrain. No mutation. *)

val dimensions : t -> int * int
(** [(rows, cols)] of the underlying world. *)

val camel : t -> World.position
(** Current camel position. *)

val worm : t -> World.position
(** Current sandworm position. *)

val revealed : t -> World.position -> bool
(** Whether the camel has discovered the cell; [false] outside the grid. *)

val score : t -> int
(** Points collected so far. *)

val required : t -> int
(** Points needed before entering the exit ends in victory (8). *)

val turns : t -> int
(** Successful moves and waits so far. *)

val seed : t -> int
(** Seed recorded at [start], for display. *)

val outcome : t -> outcome
(** [Playing] until victory or defeat. *)
