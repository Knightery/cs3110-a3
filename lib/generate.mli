val create : seed:int -> World.t * World.position * World.position
(** [create ~seed] returns a connected 17 by 41 four-room labyrinth, camel and
    worm. Uses only a fresh local RNG. Actors/exit are distinct and both exit
    and worm are at least six Manhattan steps from camel. Reachable treasure
    totals 10 points. Raises [Invalid_argument] for negative seed, or [Failure]
    if no valid placement can be found. *)
