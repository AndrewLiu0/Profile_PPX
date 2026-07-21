open Ppxlib
open Ast_builder.Default

(* A PPX rewriter is an ordinary OCaml function from AST to AST *)

(** [wrap_body ~loc ~name expr] rewrites a function's right-hand side so the
   innermost body is timed. *)
let rec wrap_body ~loc ~name expr =
  match expr.pexp_desc with
  | Pexp_function (params, constraint_, Pfunction_body body) ->
      (* Still a function layer: rebuild it unchanged except for the body. *)
      { expr with
        pexp_desc =
          Pexp_function
            (params, constraint_, Pfunction_body (wrap_body ~loc ~name body))
      }
  | _ ->
      (* Innermost body reached. [%expr ...] is a metaquot quotation *)
      [%expr
        let __profile_start = Unix.gettimeofday () in
        Fun.protect
          ~finally:(fun () ->
            Printf.eprintf "[profile] %s: %.12fs\n%!"
              [%e estring ~loc name]
              (Unix.gettimeofday () -. __profile_start))
          (fun () -> [%e expr])]

(* The handler ppxlib calls for each `%profile` node it finds.
   - [~ctxt] is supplied by ppxlib: metadata 
   - [item] is the captured payload: the plain `let ...` structure item
   We must return the structure item that replaces the extension node. *)
let expand ~ctxt item =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  match item.pstr_desc with
  | Pstr_value (rec_flag, bindings) ->
      (* (a list because of `let a = .. and b = ..`) *)
      let bindings =
        List.map
          (fun binding ->
            let name =
              (* binding.pvb_pat is the left side of the `=`.
                 Only extract a label when it is a simple variable. *)
              match binding.pvb_pat.ppat_desc with
              | Ppat_var { txt = name; _ } -> name
              | _ -> "<pattern>"
            in
            (* Rewrite only the right side (pvb_expr) *)
            { binding with pvb_expr = wrap_body ~loc ~name binding.pvb_expr })
          bindings
      in
      { item with pstr_desc = Pstr_value (rec_flag, bindings) }
  | _ -> (* Not a `let` *)
      pstr_extension ~loc
        (Location.error_extensionf ~loc
           "%%profile must be attached to a let binding")
        []

(* Describe the extension (nothing runs yet) *)
let extension =
  Extension.V3.declare "profile" Extension.Context.structure_item
    Ast_pattern.(pstr (__ ^:: nil))
    expand

(* Top-level side effect, executed once when the ppx driver starts  *)
let () =
  Driver.register_transformation
    ~rules:[ Context_free.Rule.extension extension ]
    "ppx_profile"
