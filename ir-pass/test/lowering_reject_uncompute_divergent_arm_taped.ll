; lowering_reject_uncompute_divergent_arm_taped.ll — DECLINE. Sibling of
; lowering_reject_uncompute_uninvertible_taped.ll: the same bd 261j(a) mechanism
; claim, aimed at the DOMINANCE scan rather than the invertibility pre-scan.
;
; `lowering_uncompute_divergent_arm.ll`'s shape — `entry` preps `%h` (ry on every
; path), then `cq_phi(a)` in arm-a ONLY and `cq_phi(b)` in arm-b ONLY, so neither
; `rz` dominates the reversal point — PLUS a taped derived terminal `%t = h + 1` in
; `entry`. The record freezes `%h` (it is an ancestor of the recorded `%t`, and its
; own `cqrt_ry` chain has an EMPTY condition set), so `%h` gets no `cqrt_free`.
;
; The module must still decline LOUDLY, and it does — but note WHY this fixture is
; still load-bearing even though the freeze no longer skips any gate: the scans that
; produce this diagnostic run over `D.Calls` BEFORE emission, and the freeze is
; recorded in a separate `FrozenRails` set rather than by pruning `D.Calls`. Had it
; been implemented as a prune inside `recoverDataDag`, the two
; `rz`s would have vanished before the dominance scan ran, the scan would have found
; nothing to complain about, and a module the compiler currently REFUSES would
; compile rc=0.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @printf(ptr, ...)
@.str = private constant [3 x i8] c"%d\00"

define void @slice(i32 %x, i1 %c) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %t = add i32 %h, 1                                      ; taped derived terminal
  %r = call i32 (ptr, ...) @printf(ptr @.str, i32 %t)     ; RECORDED onto the kept tape
  br i1 %c, label %arma, label %armb
arma:
  %ha = call i32 @cq_phi_si32(i32 %h, double 1.000000e-01)   ; mutating gate, arm-a only
  br label %merge
armb:
  %hb = call i32 @cq_phi_si32(i32 %h, double 2.000000e-01)   ; mutating gate, arm-b only
  br label %merge
merge:
  %hp = phi i32 [ %ha, %arma ], [ %hb, %armb ]               ; DEAD live-range merge
  ret void
}

; CHECK: error{{.*}}cq uncompute: dead chain spans divergent control-flow arms
