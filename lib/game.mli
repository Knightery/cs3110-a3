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
val camel : t -> World.position
val worm : t -> World.position
val revealed : t -> World.position -> bool
val score : t -> int
val required : t -> int
val turns : t -> int
val seed : t -> int
val outcome : t -> outcome
