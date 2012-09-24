module O = BatOrd

let ( |? ) = BatOption.( |? )
let ( |- ) f g x = g (f x)

exception Invalid_bounds

type 'a bound_t = [ `o of 'a | `c of 'a | `u]

type ('a, 'b) bounding_f = bounds:('a bound_t * 'a bound_t) -> 'a -> 'b

let ret_some x = Some x
let ret_none _ = None

let bounding_of_ord ?default_low ?default_high ord = 
  fun ~(bounds : 'a bound_t * 'a bound_t) ->
    match bounds with
    | `c l, `c u -> begin
      if ord l u = O.Gt then raise Invalid_bounds;
      fun x ->
        match ord x l, ord x u with
        | O.Lt, _ -> default_low
        | _, O.Gt -> default_high
        | O.Eq, _
        | _, O.Eq
        | O.Gt, _ -> Some x
    end
    | `u, `c u -> begin
      fun x ->
        match ord x u with
        | O.Gt -> default_high
        | O.Eq
        | O.Lt -> Some x
    end
    | `c l, `u -> begin
      fun x ->
        match ord x l with
        | O.Lt -> default_low
        | O.Gt
        | O.Eq -> Some x
    end
    | `u, `u -> ret_some
    | `o l, `o u -> begin
      if ord l u = O.Gt then raise Invalid_bounds;
      fun x ->
        match ord x l, ord x u with
        | O.Lt, _
        | O.Eq, _ -> default_low
        | _, O.Gt
        | _, O.Eq -> default_high
        | O.Gt, _ -> Some x
    end
    | `u, `o u -> begin
      fun x ->
        match ord x u with
        | O.Gt
        | O.Eq -> default_high
        | O.Lt -> Some x
    end
    | `o l, `u -> begin
      fun x ->
        match ord x l with
        | O.Lt
        | O.Eq -> default_low
        | O.Gt -> Some x
    end
    | `c l, `o u -> begin
      if ord l u = O.Gt then raise Invalid_bounds;
      fun x ->
        match ord x l, ord x u with
        | O.Lt, _ -> default_low
        | _, O.Gt
        | _, O.Eq -> default_high
        | O.Eq, _
        | O.Gt, _ -> Some x
    end
    | `o l, `c u -> begin
      if ord l u = O.Gt then raise Invalid_bounds;
      fun x ->
        match ord x l, ord x u with
        | O.Lt, _
        | O.Eq, _ -> default_low
        | _, O.Gt -> default_high
        | _, O.Eq
        | O.Gt, _ -> Some x
    end

(*$T bounding_of_ord
   bounding_of_ord BatInt.ord ~bounds:(`u, `u) 0 = Some 0
   bounding_of_ord BatInt.ord ~bounds:(`c 0, `u) 0 = Some 0
   bounding_of_ord BatInt.ord ~bounds:(`o 0, `u) 0 = None
   bounding_of_ord BatInt.ord ~bounds:(`u, `c 0) 0 = Some 0
   bounding_of_ord BatInt.ord ~bounds:(`u, `o 0) 0 = None

   bounding_of_ord ~default_low:~-10 ~default_high:10 BatInt.ord ~bounds:(`u, `u) 0 = Some 0
   bounding_of_ord ~default_low:~-10 ~default_high:10 BatInt.ord ~bounds:(`c 0, `u) 0 = Some 0
   bounding_of_ord ~default_low:~-10 ~default_high:10 BatInt.ord ~bounds:(`o 0, `u) 0 = Some ~-10
   bounding_of_ord ~default_low:~-10 ~default_high:10 BatInt.ord ~bounds:(`u, `c 0) 0 = Some 0
   bounding_of_ord ~default_low:~-10 ~default_high:10 BatInt.ord ~bounds:(`u, `o 0) 0 = Some 10
*)

let bounding_of_ord_chain ?low ?high ord = 
  let low = low |? ret_none in
  let high = high |? ret_none in
  fun ~(bounds : 'a bound_t * 'a bound_t) ->
    match bounds with
    (* Closed bounds (inclusive) *)
    | `c l, `c u -> begin
      if ord l u = O.Gt then raise Invalid_bounds;
      fun x ->
        match ord x l, ord x u with
        | O.Lt, _ -> low x
        | _, O.Gt -> high x
        | O.Eq, _
        | _, O.Eq
        | O.Gt, _ -> Some x
    end
    | `u, `c u -> begin
      fun x ->
        match ord x u with
        | O.Gt -> high x
        | O.Eq
        | O.Lt -> Some x
    end
    | `c l, `u -> begin
      fun x ->
        match ord x l with
        | O.Lt -> low x
        | O.Gt
        | O.Eq -> Some x
    end
    (* Open bounds (exclusive) *)
    | `o l, `o u -> begin
      if ord l u = O.Gt then raise Invalid_bounds;
      fun x ->
        match ord x l, ord x u with
        | O.Lt, _
        | O.Eq, _ -> low x
        | _, O.Gt
        | _, O.Eq -> high x
        | O.Gt, _ -> Some x
    end
    | `u, `o u -> begin
      fun x ->
        match ord x u with
        | O.Gt
        | O.Eq -> high x
        | O.Lt -> Some x
    end
    | `o l, `u -> begin
      fun x ->
        match ord x l with
        | O.Lt
        | O.Eq -> low x
        | O.Gt -> Some x
    end
    (* Mixed open and closed bounds *)
    | `c l, `o u -> begin
      if ord l u = O.Gt then raise Invalid_bounds;
      fun x ->
        match ord x l, ord x u with
        | O.Lt, _ -> low x
        | _, O.Gt
        | _, O.Eq -> high x
        | O.Eq, _
        | O.Gt, _ -> Some x
    end
    | `o l, `c u -> begin
      if ord l u = O.Gt then raise Invalid_bounds;
      fun x ->
        match ord x l, ord x u with
        | O.Lt, _
        | O.Eq, _ -> low x
        | _, O.Gt -> high x
        | _, O.Eq
        | O.Gt, _ -> Some x
    end
    | `u, `u -> ret_some

(*$T bounding_of_ord_chain as f
   f BatInt.ord ~bounds:(`u, `u) 0 = Some 0
   f BatInt.ord ~bounds:(`c 0, `u) 0 = Some 0
   f BatInt.ord ~bounds:(`o 0, `u) 0 = None
   f BatInt.ord ~bounds:(`u, `c 0) 0 = Some 0
   f BatInt.ord ~bounds:(`u, `o 0) 0 = None

   f ~low:(fun x -> Some ~-10) ~high:(fun x -> Some 10) BatInt.ord ~bounds:(`u, `u) 0 = Some 0
   f ~low:(fun x -> Some ~-10) ~high:(fun x -> Some 10) BatInt.ord ~bounds:(`c 0, `u) 0 = Some 0
   f ~low:(fun x -> Some ~-10) ~high:(fun x -> Some 10) BatInt.ord ~bounds:(`o 0, `u) 0 = Some ~-10
   f ~low:(fun x -> Some ~-10) ~high:(fun x -> Some 10) BatInt.ord ~bounds:(`u, `c 0) 0 = Some 0
   f ~low:(fun x -> Some ~-10) ~high:(fun x -> Some 10) BatInt.ord ~bounds:(`u, `o 0) 0 = Some 10
*)

let saturate_of_ord ~(bounds : 'a bound_t * 'a bound_t) ord =
  match bounds with
  | `o l, `o h
  | `c l, `c h
  | `o l, `c h
  | `c l, `o h ->
      bounding_of_ord ~default_low:l ~default_high:h ord ~bounds
      |- BatOption.get
  | `u, `o h
  | `u, `c h ->
      bounding_of_ord ~default_high:h ord ~bounds
      |- BatOption.get
  | `o l, `u
  | `c l, `u ->
      bounding_of_ord ~default_low:l ord ~bounds
      |- BatOption.get
  | `u, `u ->
      bounding_of_ord ord ~bounds
      |- BatOption.get

let opt_of_ord ~(bounds : 'a bound_t * 'a bound_t) ord =
  bounding_of_ord ord ~bounds

module type BoundedType = sig
  type base_t
  type t
  val bounds : base_t bound_t * base_t bound_t
  val bounded : (base_t, t) bounding_f
  val base_of_t : t -> base_t option
  val base_of_t_exn : t -> base_t
  val map : (base_t -> base_t) -> t -> t
  val map2 : (base_t -> base_t -> base_t) -> t -> t -> t
end

module type S = sig
  type base_u
  type u
  type t = private u
  val bounds : base_u bound_t * base_u bound_t
  val make : base_u -> t
  external extract : t -> u = "%identity"
  val map : (base_u -> base_u) -> t -> t option
  val map2 : (base_u -> base_u -> base_u) -> t -> t -> t option
  val map_exn : (base_u -> base_u) -> t -> t
  val map2_exn : (base_u -> base_u -> base_u) -> t -> t -> t
end

module Make(M : BoundedType) : (
  S with type base_u = M.base_t with type u = M.t with type t = private M.t
) = struct
  include M
  type base_u = base_t
  type u = t
  let make = bounded ~bounds
  external extract : t -> u = "%identity"
  let map f x =
    BatOption.map make (base_of_t (M.map f x))
  let map2 f x y =
    BatOption.map make (base_of_t (M.map2 f x y))
  let map_exn f x =
    make (base_of_t_exn (M.map f x))
  let map2_exn f x y =
    make (base_of_t_exn (M.map2 f x y))
end

