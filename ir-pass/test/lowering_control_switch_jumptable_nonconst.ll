; lowering_control_switch_jumptable_nonconst.ll — Phase 4.x (test_C_libtooling-5zu),
; NEGATIVE safety lock. The jump-table angle normalizer (normalizeJumpTableAngle)
; only rewrites the CANONICAL shape: a CONSTANT global table read at compile time.
; Here `@tbl` is a MUTABLE global (`global`, not `constant`), so its entries are
; not known at compile time and cannot be folded into the eq-flag select chain.
; The recognizer must DECLINE (G->isConstant() fails), leaving the tainted
; `getelementptr`/`load` for the tainted-memory-escape guard to diagnose — the
; "no silent miscompile" fallback. This locks the conservative recognizer: an
; unrecognized table-indexed-by-handle shape is never mislowered.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}memory addressing under quantum control
; CHECK-NOT: cqrt_rz_i32_controlled
@tbl = global [3 x double] [double 1.000000e-01, double 2.000000e-01, double 3.000000e-01], align 8
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %idx = add i32 %q, -1
  %bound = icmp ult i32 %idx, 3
  br i1 %bound, label %lookup, label %merge
lookup:
  %zext = zext i32 %idx to i64
  %gep = getelementptr inbounds [3 x double], ptr @tbl, i64 0, i64 %zext
  %ang = load double, ptr %gep, align 8
  br label %merge
merge:
  %a = phi double [ %ang, %lookup ], [ 9.000000e-01, %entry ]
  %r = call i32 @cq_phi_si32(i32 %v, double %a)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
