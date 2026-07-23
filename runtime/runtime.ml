type t = {
  file : string;
  line : int;
  function_name : string;
  start_time : float;
}
(** Type definition subject to change *)

let initialize ~file ~line ~function_name : t =
  let start_time = Unix.gettimeofday () in
  { file; line; function_name; start_time }

let finalize (runtime_data : t) =
  Printf.eprintf "[profile] %s (%s: %d): %.12fs\n%!" runtime_data.function_name
    runtime_data.file runtime_data.line
    (Unix.gettimeofday () -. runtime_data.start_time)
