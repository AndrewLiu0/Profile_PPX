(** PPX rewriter providing the [%profile] extension.

    This library is a PPX: it runs during compilation, not at runtime.

    Example transformation:
    {[
      let rec fib n = if n < 2 then n else fib (n - 1) + fib (n - 2)
    ]}
    ->
    {[
      let rec fib n =
        let __profile_start = Unix.gettimeofday () in
        Fun.protect
          ~finally:(fun () ->
            Printf.eprintf "[profile] %s: %.6fs\n%!" "fib"
              (Unix.gettimeofday () -. __profile_start))
          (fun () -> if n < 2 then n else fib (n - 1) + fib (n - 2))
    ]} 
*)

open Ppxlib

val wrap_body : loc:location -> name:string -> expression -> expression
(** [wrap_body ~loc ~name expr] rewrites a function's right-hand side so the
    innermost body is timed. This funtionality will change over time. *)

(* The handler ppxlib calls for each `%profile` node it finds.
   - [~ctxt] is supplied by ppxlib: metadata 
   - [item] is the captured payload: the plain `let ...` structure item
   We must return the structure item that replaces the extension node. *)
val expand :
  ctxt:Expansion_context.Extension.t -> structure_item -> structure_item

(* Describe the extension (nothing runs yet) *)
val extension : Extension.t
