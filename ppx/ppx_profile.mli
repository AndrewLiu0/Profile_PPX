(** PPX rewriter providing the [%profile] extension. *)

open Ppxlib

val wrap_body : loc:location -> name:string -> expression -> expression

val expand
  :  ctxt:Expansion_context.Extension.t
  -> structure_item
  -> structure_item

val extension : Extension.t
