; E2 obligation (b): a residual whose ConstantExpr points AT the undef field.
; RUN: (probe only — measured via e2.sh, not a fixture)
@g = global { i32, i32 } { i32 1, i32 undef }
declare i32 @cq_measure_si32(i32)
define i32 @gep() {
entry:
  %m = call i32 @cq_measure_si32(i32 ptrtoint (ptr getelementptr inbounds ({ i32, i32 }, ptr @g, i32 0, i32 1) to i32))
  ret i32 %m
}
