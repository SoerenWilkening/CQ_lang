; control_phase_kickback_rail_round2_window_accept.ll — ACCEPT (bd
; test_C_libtooling-r9e5 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1's KICKBACK-side
; DISCRIMINATOR). `control_phase_kickback_reject_rail_round2_sibling_theta.ll`
; with the SIBLING theta deleted and nothing else changed: the condition rail is
; still the 6.5 `%out`-derived seed that only ROUND 2 taints — the same window —
; but nothing else ever touches the register, so the kickback is correct and must
; keep lowering.
;
; GREEN ON BOTH BINARIES, and the lowered modules are BYTE-IDENTICAL (measured
; with `diff` on the two `-S` outputs). That is what makes `reverifyRailCondReads`
; a re-verification: it re-asks the ladder's two rungs and changes nothing when
; they still hold. The emitted stream is the shipped rail kickback — one
; `cqrt_ry_i1` on the register, then the `!cq.branchphase`-recorded
; `cqrt_rz_i1(rail, θ)` DIRECTLY on it, with NO mint, NO strip, NO `cqrt_free` and
; NO `cqrt_x` on a user register.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll
; RUN: %filecheck %s --check-prefix=ORD < %t.ll
; RUN: %filecheck %s --check-prefix=RZCNT < %t.ll
; RUN: %filecheck %s --check-prefix=RYCNT < %t.ll
; RUN: %filecheck %s --check-prefix=NOX < %t.ll

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:
  %r = call i32 @f(i32 4)
  br label %merge

merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  br label %second

second:
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  br i1 %b, label %ph, label %join

ph:
  call void @cq_phi(double 7.000000e-01)
  br label %join

join:
  %mm = call i1 @cq_measure_i1(i1 %b)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }

; The register's own rail carries the rotation and then the branch phase, in
; source order, with nothing between them.
; ORD: %h_cast = call i32 @cq_template_trunc_i32_to_i1(i32 %out)
; ORD-NEXT: call void @cqrt_ry_i1(i32 %h_cast, double 5.000000e-01)
; ORD-NEXT: call void @cqrt_rz_i1(i32 %h_cast, double 0x3FE6666666666666), !cq.branchphase
; ORD-NEXT: %[[M2:m[0-9]*]] = call i1 @cqrt_measure_i1(i32 %h_cast)

; EXACTLY ONE branch phase and EXACTLY ONE rotation on the i1 rail, whole file.
; RZCNT-COUNT-1: call void @cqrt_rz_i1(
; RZCNT-NOT: call void @cqrt_rz_i1(
; RYCNT-COUNT-1: call void @cqrt_ry_i1(
; RYCNT-NOT: call void @cqrt_ry_i1(

; Nothing is minted, stripped or freed FOR THE RAIL, and no `cqrt_x` lands on a
; user register (the 6.5 arm's own flag brackets are on `%h_cmp`, not here).
; NOX-NOT: call void @cqrt_x(i32 %h_cast)
; NOX-NOT: call void @cqrt_free(i32 %h_cast)
; NOX-NOT: @cqrt_cswap
; NOX-NOT: call i1 @cq_theta
; NOX-NOT: @cqrt_rz_i1({{.*}}_inv
