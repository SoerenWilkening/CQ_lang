; h2b_inloop_diamond_value_onecond_control.ll — Track X (bd x5fp), 2026-09-18.
; THE ONE-OPERAND ISOLATING CONTROL for h1: byte-identical to h1 except that the
; compare's second operand is the constant 0 instead of the classical carrier
; %a (the φ is kept, and still carries %m, so the CFG and every other value are
; unchanged). It pins the §3c flip to condProvenance MEMBERSHIP and to nothing
; else — and it names the wall that sits BEHIND S-1.
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

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
