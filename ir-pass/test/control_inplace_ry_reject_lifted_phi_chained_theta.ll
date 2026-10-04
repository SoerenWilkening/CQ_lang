; control_inplace_ry_reject_lifted_phi_chained_theta.ll — DECLINE. The launder
; where the classical arm's own gate is a CHAINED `cq_theta` (a NON-diagonal Ry)
; rather than the diagonal `cq_phi` (round-1 Rule-13 review, lens L2 §1;
; MEASURED accepting before the fix). Read
; `control_inplace_ry_reject_lifted_phi_measure.ll`'s header for the mechanism.
;
;     int m; if (c) { m = r; cq_theta(&m, .1); } else { m = r; }
;     if (q == 5) { cq_theta(&r, .9); }
;     return cq_measure(m) + cq_measure(r) + cq_measure(q);
;
; WHY THIS ONE IS ITS OWN FIXTURE: `railWireClosure`'s forward hop list treats a
; chained `cq_theta` and a `cq_phi` as the same KIND of edge (both keep the
; parent's handle — `RotationLowering`'s `Chained` branch mints no alloc), so a
; fix that reached only the diagonal spelling would look right on every `cq_phi`
; probe and still miss this. Note the pre-fix emitted stream reads
; `cqrt_ry_i32(h1, 0.1); cqrt_ry_i32_controlled(f, h1, 0.9); measure(h1);
; measure(h1)` — two measurements of one rail where the source names two
; different records of it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %c) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.500000e-01)
  %cc = icmp eq i32 %c, 0
  br i1 %cc, label %join, label %alias
alias:
  %m0 = call i32 @cq_theta_si32(i32 %r, double 1.000000e-01)
  br label %join
join:
  %m = phi i32 [ %m0, %alias ], [ %r, %entry ]
  %t = icmp eq i32 %q, 5
  br i1 %t, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %join ]
  %a = call i32 @cq_measure_si32(i32 %m)
  %b = call i32 @cq_measure_si32(i32 %rm)
  %s = add i32 %a, %b
  ret i32 %s
}
