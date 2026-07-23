

type t = {
    file: string;
    line: int; 
    function_name: string ;
    start_time: float ; 
}


val initialize: file:string -> line:int -> function_name:string -> t

val finalize: t -> unit