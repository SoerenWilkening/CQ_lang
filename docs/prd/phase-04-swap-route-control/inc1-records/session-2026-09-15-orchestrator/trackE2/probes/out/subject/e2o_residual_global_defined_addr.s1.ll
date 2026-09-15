; E2 obligation (b): the residual with a global whose initializer is an AGGREGATE
; of aggregates, undef nested two levels down.
@h = global { { i32, i32 }, i32 } { { i32, i32 } { i32 1, i32 undef }, i32 3 }
declare i64 @cq_measure_sll(i64)
define i64 @nested() {
entry:
  %m = call i64 @cq_measure_sll(i64 ptrtoint (ptr @h to i64))
  ret i64 %m
}
