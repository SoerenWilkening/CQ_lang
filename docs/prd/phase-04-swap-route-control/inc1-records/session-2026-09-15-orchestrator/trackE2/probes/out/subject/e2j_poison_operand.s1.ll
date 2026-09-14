; E2 q1': the `poison` spelling of the direct clause-4 decline.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_measure_si32(i32)
define i32 @p() {
entry:
  %m = call i32 @cq_measure_si32(i32 poison)
  ret i32 %m
}
; CHECK: error{{.*}}cq_measure_<sfx> operand is an undef/poison literal
