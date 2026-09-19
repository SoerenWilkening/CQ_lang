; (A3) a LOOP-CARRIED rail phi: phi i1 [ false, %entry ], [ %r, %latch ] with %r a
; cq_theta_i1 defined AFTER the phi. Satisfies isStructuralRailPhi; not what
; promoteRailBankCells manufactures.
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  br label %hdr
hdr:
  %i = phi i32 [ 0, %entry ], [ %i1, %latch ]
  %rp = phi i1 [ false, %entry ], [ %r, %latch ]
  br i1 %rp, label %arm, label %join
arm:
  br label %join
join:
  %a = phi i32 [ 2, %arm ], [ 5, %hdr ]
  %b = phi i32 [ 3, %arm ], [ 6, %hdr ]
  %s = add i32 %a, %b
  br label %latch
latch:
  %r = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %i1 = add i32 %i, 1
  %c = icmp slt i32 %i1, 3
  br i1 %c, label %hdr, label %exit
exit:
  %m = call i32 @cq_measure_si32(i32 %s)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %t = add i32 %m, %mq
  ret i32 %t
}
