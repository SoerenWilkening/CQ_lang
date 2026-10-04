; lowering_reject_inloop_rail_record_merge_theta.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 2, finding F-1 — the MERGE-PHI HOP).
;
;     int mark = q;
;     if (n & 1) q = cq_phi(q, 1.0);   /* a post-loop rail MERGE phi */
;     cq_theta(&q, 0.125);          /* Ry whose arg-0 is the phi */
;     return cq_measure(mark) + cq_measure(q);
;
; The third way a gate reaches the register without appearing on any chain: its
; arg-0 is a PHI that names this rail on at least one incoming edge. Measured at
; the round-2 HEAD: `opt` exit 0 and `cqrt_ry_i32(%h, 0.125)` emitted before both
; `measure(%h)` calls, so `mark` reads iteration-k's register through the pre-Ry
; name.
;
; SOME INCOMING, NOT ALL — and that asymmetry is the sound side, not a shortcut.
; `railGateBetween` asks whether SOME execution path runs the record's def, then a
; gate, then the read; a phi that names this rail on one edge really does put the
; following Ry on this wire along that edge. A phi that ALSO merges a foreign
; value therefore only ever adds declines (Prime Directive: over-declining is
; safe), while an "all incomings" spelling would silently drop exactly this
; program. The merge itself is not a gate — only the rotation behind it is.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %odd = and i32 %n, 1
  %even = icmp eq i32 %odd, 0
  br i1 %even, label %join, label %rzblk
rzblk:
  br label %join
join:
  %qj = phi i32 [ %qn, %rzblk ], [ %qn, %exit ]                  ; rail merge phi
  %post = call i32 @cq_theta_si32(i32 %qj, double 1.250000e-01)  ; arg-0 is the phi
  %m0 = call i32 @cq_measure_si32(i32 %qn)                       ; the STALE record
  %m1 = call i32 @cq_measure_si32(i32 %post)
  %s = add i32 %m0, %m1
  ret i32 %s
}
