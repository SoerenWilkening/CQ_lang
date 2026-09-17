; control_swap_reject_value_inloop_backedge_clobber.ll — bd test_C_libtooling-x5fp.
;
; THE §3c CLOBBER FENCE, ASKED PER ACTIVATION. This module's overlap between the
; arm's routed register and the condition's provenance exists ONLY around the
; BACK EDGE, and the fence used to brand it with the PERMANENT string
; `arm rewrites a condition operand` — the string its own §8-review note (2026-06-10,
; `ArmClassify.cpp`, the §3c block) reserves for "the proven diamond identity"
; and forbids using "on unproven evidence".
;
; WHY IT IS NOT A CLOBBER, IN ONE ACTIVATION. `%c = icmp sgt i32 %q, %a` is
; evaluated at the TOP of the body from the header φ `%a` and from `%q`'s own
; fresh rail; the arm then writes `%r`. `%r` reaches the condition's cone at all
; only through `%a`'s LATCH incoming — `%a` -> `%m` (a `cq_measure`, the taint
; SINK, so nothing tainted crosses the back edge) -> `%rm` -> `%r`. So the flag
; is minted strictly before the arm writes, and `%q`'s rail and `%r`'s rail are
; distinct allocations (both are SOURCE thetas re-executed per trip).
;
; ⚠ WHAT MOVED IS THE STRING, NOT THE ACCEPT SET. Removing the clobber does not
; make this module compile; it makes it reach the NEXT wall, which is the honest
; one. ORACLE `cq-opt` sha256 9bd01598…: `arm rewrites a condition operand`.
; SUBJECT 33bba13b…: the string below. Measured, both binaries, 2026-09-18.
;
; ⚠ RETIREMENT TRIGGER (CLAUDE.md L8). The wall this now names is
; `ControlDetect.cpp`'s "IN-LOOP SCOPE FENCE, part 2" — a method-B VALUE arm
; inside a loop — i.e. bd `test_C_libtooling-3qlq.6` / bd `test_C_libtooling-1dbk`
; item 1, NOT bd `ej5w` (whose subject is `LoopLowering`'s X1 clause, a different
; site). WHEN THAT LANDS THIS FILE BECOMES AN ACCEPT: re-derive its stream then,
; against the hand-unrolled twin, and do NOT delete it — it is the only fixture
; that pins the back-edge reading of §3c at the `diagonalAliasHit` prong.
;
; ISOLATING CONTROL: control_swap_reject_value_inloop_backedge_clobber_control.ll
; is this module with ONE operand changed (the compare's second operand is the
; constant 0 instead of `%a`), so §3c cannot fire at all. It printed the string
; below on the ORACLE too — which is what makes the pair the measurement that
; "S-1 is never the only wall".
; NEGATIVE CONTROL for the rail-disjointness conjunct:
; control_swap_reject_value_inloop_dtzb_same_rail.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  br label %hdr

hdr:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %a = phi i32 [ 0, %entry ], [ %m, %latch ]
  %q = call i32 @cq_theta_si32(i32 9, double 3.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.000000e-01)
  %c = icmp sgt i32 %q, %a
  br i1 %c, label %arm, label %merge

arm:
  %r1 = add nsw i32 %r, 3
  br label %merge

merge:
  %rm = phi i32 [ %r1, %arm ], [ %r, %hdr ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  br label %latch

latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %hdr

exit:
  ret i32 %m
}
