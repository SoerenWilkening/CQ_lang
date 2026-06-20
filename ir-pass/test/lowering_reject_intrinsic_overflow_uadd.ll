; lowering_reject_intrinsic_overflow_uadd.ll — Phase 7.1 Increment E over-accept
; fence (green forever). `llvm.uadd.with.overflow` returns a {iN,i1} aggregate
; (the sum + an overflow bit) — EXCLUDED from the curated set: extracting the
; aggregate needs `extractvalue` routing, a separate heavier mechanism (PRD §2.6
; "OUT"). isCuratedReversibleIntrinsic returns false (not a curated id), so the
; tainted call falls through to the loud kMsgUnknownCallee escape decline — never
; a half-built cq_template_uadd_overflow symbol.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
; CHECK-NOT: cq_template_uadd

declare i32 @cq_theta_si32(i32, double)
declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)

define void @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %r = call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %q, i32 3)
  ret void
}
