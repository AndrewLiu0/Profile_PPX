open Ppxlib
open Ast_builder.Default

let rec wrap_body ~loc ~name expr =
  match expr.pexp_desc with
  | Pexp_function (params, constraint_, Pfunction_body body) ->
      {
        expr with
        pexp_desc =
          Pexp_function
            (params, constraint_, Pfunction_body (wrap_body ~loc ~name body));
      }
  | _ ->
      (* Innermost body reached. [%expr ...] is a metaquot quotation *)
      [%expr
        let init_data = Runtime.initialize 
        ~file: [%e estring ~loc loc.loc_start.pos_fname]     
        ~line: [%e eint ~loc loc.loc_start.pos_lnum]
        ~function_name: [%e estring ~loc name]
        in
        Fun.protect
          ~finally:(fun () -> Runtime.finalize init_data)
          (fun () -> [%e expr])]

let expand ~ctxt item =
  
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  (* Location.print_loc Format.std_formatter loc; *)
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
  | _ ->
      (* Not a `let` *)
      pstr_extension ~loc
        (Location.error_extensionf ~loc
           "%%profile must be attached to a let binding")
        []

let extension =
  Extension.V3.declare
    "profile"
    Extension.Context.structure_item
    Ast_pattern.(pstr (__ ^:: nil))
    expand
;;

(* Executed once when the ppx driver starts  *)
let () =
  Driver.register_transformation
    ~rules:[ Context_free.Rule.extension extension ]
    "ppx_profile"
;;
