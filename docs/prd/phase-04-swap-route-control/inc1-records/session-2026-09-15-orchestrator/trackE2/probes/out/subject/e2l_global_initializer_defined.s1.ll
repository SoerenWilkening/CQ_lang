; control for e2k: identical but the global's initializer is fully defined.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
@g = global { i32, i32 } { i32 1, i32 2 }
declare i32 @cq_measure_si32(i32)
define i32 @gi() {
entry:
  %m = call i32 @cq_measure_si32(i32 ptrtoint (ptr @g to i32))
  ret i32 %m
}
; CHECK: ret i32 ptrtoint
