; control_swap_reject_nonreconverging_value_exit.ll — Phase 7.2 Inc 4 DECLINE:
; a tainted-condition `br` that muxes TWO un-merged value `ret`s (the §2.11-C-i
; "two un-merged value rets / musttail" survivor). `clang -O1` reconverges every
; *mergeable* early return to one `select` / merge-φ (already 4.4-accepted), so
; this shape essentially never survives for non-`musttail` code — it is HAND-
; CONSTRUCTED to exercise the OffPattern partition (IMPLEMENTATION-PLAN-7.2 §6 RED
; note: "use musttail or a hand-written .ll").
;
; HISTORY (until bd test_C_libtooling-dm7f.5): recoverRegion saw both arms end in
; `ret` → OffPattern, and `offPatternDisposition` declined `non-reconverging value
; exit` — "7.2 does NOT synthesize the merge".
;
; RE-DERIVED by dm7f.5, which SYNTHESIZES it (`unifyTaintedReturns`, ReturnMerge.cpp):
; the two `ret`s merge into `cq.retmerge` under a `cq.ret` φ, and the module is then
; the single-exit value diamond — which declines `control flow` for a reason that has
; nothing to do with exits: both arms' chains read the CONDITION register `%q` itself
; (bd 3qlq.14, a pre-existing over-decline). MEASURED on main 7b4e6359: the
; hand-merged diamond declines `control flow`, and the same diamond over a register
; disjoint from the condition ACCEPTS (`add %p, 1` / `add %p, 2`, `%p` a second
; `cq_theta`). Retirement trigger: when 3qlq.14 lands this module ACCEPTS through the
; controlled-copy merge — re-derive it then, do not delete it. The `non-reconverging
; value exit` row survives in ControlDetect.cpp only as a backstop behind a REFUSED
; `musttail` demotion (control_multiexit_reject_*_musttail.ll, which diagnose first).
; The two stdout `CHECK-NOT`s this file carried were vacuous on a `not` RUN line
; (CLAUDE.md R10) and are gone.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %a, label %b
a:
  %ra = add i32 %q, 1
  ret i32 %ra
b:
  %rb = add i32 %q, 2
  ret i32 %rb
}
