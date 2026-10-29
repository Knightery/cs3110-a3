type position = { row : int; col : int }
(** A grid cell. Row 0, column 0 is the top-left corner; coordinates increase
    down and right. *)

type terrain = Wall | Floor | Exit
type lambda = Copper | Silver | Gold

type t
(** Encapsulated terrain and mutable treasure grids. Only [collect_at] mutates a
    world after construction. *)

val of_layout : terrain array array -> (position * lambda) list -> t
(** Copies all input rows. Raises [Invalid_argument] for empty/ragged grids,
    duplicate loot, or loot outside floor cells. Tiny maps need no exit. *)

val copy : t -> t
(** Deep independent copy. *)

val dimensions : t -> int * int
(** [(rows, cols)] of the grid. *)

val terrain_at : t -> position -> terrain option
(** [None] outside the grid. *)

val lambda_at : t -> position -> lambda option
(** [None] outside the grid or without treasure. *)

val collect_at : t -> position -> int
(** Removes treasure in place; returns 0, 1, 3 or 5. *)
