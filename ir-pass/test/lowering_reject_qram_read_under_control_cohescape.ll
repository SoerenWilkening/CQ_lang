; lowering_reject_qram_read_under_control_cohescape.ll — DECLINE, over-accept COHERENT-ESCAPE
; probe (bd 3c6m.13, Rule-13 clearance). A tainted-index const-global read UNDER tainted
; control whose loaded value COHERENTLY escapes to a non-`main` `ret` (no measure/tape collapse
; first). Control is NOT the sole blocker: hoisted straight-line, the identical shape declines
; with the no-cloning coherent-return fence (kMsgQramCohEscape —
; lowering_reject_qram_read_coherent_return.ll), because the returned value is entangled with
; its local index. Perfect nested-control lowering would STILL hit that wall. So the precise
; `const-global table read under tainted control (needs nested-control lowering)` signpost must
; NOT fire here — it would be a FALSE promise that misdirects future L6 work (the exact failure
; mode this ticket exists to eliminate). The helper excludes coherently-escaping reads (it
; replicates the emitter's straight-line coherent-escape gate), so this falls to the generic
; escape decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK:     error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
; CHECK-NOT: const-global table read under tainted control
@ctbl = internal unnamed_addr constant [4 x i32] [i32 7, i32 9, i32 11, i32 13]
declare i32 @cq_theta_si32(i32, double)

define i32 @coh_escape_under_control(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp slt i32 %q, 4
  br i1 %c, label %arm, label %merge
arm:
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [4 x i32], ptr @ctbl, i64 0, i64 %i
  %v = load i32, ptr %g                       ; coherent value, escapes below
  br label %merge
merge:
  %r = phi i32 [ %v, %arm ], [ 0, %entry ]
  ret i32 %r                                  ; coherent escape (no measure) — no-cloning wall
}
