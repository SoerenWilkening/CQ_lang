; lowering_reject_uncompute_measured_parent_open_root_frozen.ll — DECLINE (bd
; test_C_libtooling-01po.8; decline twin of
; lowering_uncompute_measured_parent_open_root.ll). The `clang -O1` IR of
;     int f3_taped(int x){ int q = x; cq_theta(&q, .25); int q2 = q + 1;
;                          int t = q2 ^ 9; cq_theta(&t, .5);
;                          int u = q ^ 5;  cq_theta(&u, .5); printf("%d\n", u);
;                          return cq_measure(q2); }
;
; THE NEIGHBOUR THE GROWN FRONTIER MUST NOT TAKE (bd eqti, kept). The fixpoint
; borrows the open root `q` exactly as in the accept. But `u` is now RECORDED on
; the output tape after its Ry, so it is frozen (kept, never freed), and the
; plan would still reverse-play it: `ry(u,-.5); xor_hl_unc(u, q, 5)` — a gate
; controlled by the LIVE borrowed `q` (entangled with the measured `q2`) onto a
; kept rail, which changes q's coherence. `keptRailAdjointReadsBorrowed` treats
; every borrowed register as live, grown ones included, and the module keeps
; its decline verbatim.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @printf(ptr nocapture noundef readonly, ...)

define i32 @f3_taped(i32 %0) {
  %2 = tail call i32 @cq_theta_si32(i32 %0, double 2.500000e-01)
  %3 = add nsw i32 %2, 1
  %4 = xor i32 %3, 9
  %5 = tail call i32 @cq_theta_si32(i32 %4, double 5.000000e-01)
  %6 = xor i32 %2, 5
  %7 = tail call i32 @cq_theta_si32(i32 %6, double 5.000000e-01)
  %8 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %7)
  %9 = tail call i32 @cq_measure_si32(i32 %3)
  ret i32 %9
}

; CHECK: error{{.*}}cq uncompute: dead chain would free a measured register
