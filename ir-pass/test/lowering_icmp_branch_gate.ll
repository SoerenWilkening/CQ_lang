; lowering_icmp_branch_gate.ll — Phase-3 → Phase-4 SUPERSESSION (PRD §5, line
; 108/309). Phase 3's premise was: a tainted compare feeding a `br i1` is in
; neither pure data nor measure position, so `isDataPositionCompare` returns
; false and the compare is left COMPLETELY UNTOUCHED — "owned by Phase 4." This
; fixture pinned that hand-off.
;
; Phase 4 has now delivered the verdict. The exact shape below — `if (q < 10)
; return 1; else return 0;` — is the "return under quantum control" ESCAPE row
; of the realized `-O1` control menu (PRD line 108: `if(q) return …;` →
; `br` + escape in an arm). Its guarded arm does NOT reconverge into a
; controllable diamond/select; it `ret`s. Per PRD line 309 this epic emits the
; loud `DiagnosticInfoUnsupported` ("…under quantum control") and FAILS
; (non-zero exit); the full reject/bridge refinement is Phase 4.1 (`-aht.2`).
;
; So this is no longer an "untouched data flag" — it is now a diagnosed escape.
; The fixture is converted (NOT deleted) to a NEGATIVE test, preserving its
; intent: it documents that a tainted branch-feeding compare whose arm escapes
; is rejected loudly, not silently laundered. Contrast `lowering_control_*.ll`,
; whose arms RECONVERGE to a merge and DO lower controlled.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define i32 @example() {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  ; Tainted compare feeding a branch whose arm escapes (`ret` under the guard)
  ; → "return under quantum control" (PRD line 108/309): diagnosed, not lowered.
  %c = icmp slt i32 %a, 10
  br i1 %c, label %t, label %f
t:
  ret i32 1
f:
  ret i32 0
}
