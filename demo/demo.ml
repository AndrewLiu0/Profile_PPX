let%profile rec fib n = if n < 2 then n else fib (n - 1) + fib (n - 2)

let%profile slow_sum a b =
  Unix.sleepf 0.05;
  a + b

let () =
  Printf.printf "fib 10 = %d\n" (fib 10);
  Printf.printf "sum = %d\n" (slow_sum 2 3)
