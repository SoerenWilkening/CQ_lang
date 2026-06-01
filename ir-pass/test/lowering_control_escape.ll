; lowering_control_escape.ll — WP6 quantum-controlled ESCAPE (PRD §5, line
; 108/309, IMPLEMENTATION §6, negative). A tainted-condition `br i1` whose
; guarded arm ESCAPES — it contains a `ReturnInst` (also a `@cq_measure_*` or an
; out-of-region `br`) and does NOT reconverge into a controllable diamond — is
; the "return/measure under quantum control" case (PRD line 108). This epic
; emits the loud `DiagnosticInfoUnsupported` ("…under quantum control") and
; fails (non-zero exit); the full reject/bridge refinement is Phase 4.1
; (`-aht.2`). Contrast the controllable shapes (WP3 diamond, WP4/WP5
; select/conjunction) whose arms RECONVERGE to a merge (`br to merge`, no
; `ret`/`measure`) — those lower, this diagnoses.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control
declare i32 @cq_theta_si32(i32, double)
define i32 @example(i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 0.5)
  %c = icmp sgt i32 %q, 0
  br i1 %c, label %ret, label %cont
ret:
  ret i32 %a                 ; escape under quantum control
cont:
  ret i32 0
}
