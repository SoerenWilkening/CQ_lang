; E2 q4: a NON-whole-value undef at the sink — an undef nested in a ConstantExpr.
; `valueCarriesUndef` (LiteralIntegrity) walks constants RECURSIVELY, so this
; DECLINES today on the clause-4 string even though the operand is not
; `isa<UndefValue>`. It is the exact residual z9t1's seed clause excluded with its
; own `isa<UndefValue>` conjunct ("the predicate gates a DECLINE everywhere else
; and a REWRITE here"). Rewriting THIS to zero would change a partially-defined
; value, not refine an undefined one.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_measure_si32(i32)

define i32 @ce() {
entry:
  %m = call i32 @cq_measure_si32(i32 ptrtoint (ptr undef to i32))
  ret i32 %m
}
; CHECK: error{{.*}}cq_measure_<sfx> operand is an undef/poison literal
