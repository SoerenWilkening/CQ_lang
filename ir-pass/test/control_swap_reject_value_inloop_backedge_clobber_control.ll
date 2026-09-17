; control_swap_reject_value_inloop_backedge_clobber_control.ll — bd x5fp.
;
; THE ONE-OPERAND ISOLATING CONTROL for
; control_swap_reject_value_inloop_backedge_clobber.ll. Byte-identical to it
; except that the compare's SECOND OPERAND is the constant `0` instead of the
; classical carrier `%a`. The `%a` φ is kept, still carries `%m`, and is still
; read (at `exit`), so the CFG and every other value are unchanged — the only
; difference is whether `condProvenance` can reach `%r` at all.
;
; WHAT THE PAIR MEASURES, and it is the reason bd `x5fp` lands as a PARKED
; branch rather than as a capability: this file prints the SAME string on the
; ORACLE (`cq-opt` sha256 9bd01598…) as its partner does on the SUBJECT
; (33bba13b…). Removing the §3c clobber from that module does not buy an accept
; — it buys the wall behind it, `ControlDetect.cpp`'s "IN-LOOP SCOPE FENCE,
; part 2" (a method-B VALUE arm inside a loop). Measured 2026-09-18; the third
; row of the same experiment is that a FLAT diamond of this shape ACCEPTS
; (see control_swap_value_accept_nonclobber.ll), so the wall is the LOOP and
; not the arm class.
;
; ⚠ RETIREMENT TRIGGER (L8): when bd `3qlq.6` / bd `1dbk` item 1 lands, BOTH
; halves of this pair become ACCEPTs and must be re-derived together — a pair
; whose two halves stop agreeing after that landing is a finding, not a rename.
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
  %c = icmp sgt i32 %q, 0
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
  %e = add nsw i32 %m, %a
  ret i32 %e
}
