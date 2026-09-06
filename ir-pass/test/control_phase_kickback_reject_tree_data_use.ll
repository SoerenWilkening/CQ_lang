; control_phase_kickback_reject_tree_data_use.ll — DECLINE. A compound
; branch-phase condition whose LEAF is also read as DATA.
;
;     int f = (q == 5); if (q == 5 && r == 3) cq_phi(0.3); … measure(f)
;
; A single-compare region CAN share its flag with a data use — that is the ziov
; `ShareCondFlag` path: mint at the compare so the one physical flag dominates
; every data use, and SKIP the strip+free because the data lineage owns it. That
; accept CANNOT be lifted to a tree by inspection, and the reason is structural
; rather than conservative: the object a tree's gate rides is the ROOT ANCILLA,
; which this emitter strips and frees INSIDE the region, so a downstream data use
; would read a freed rail. Sharing a tree's predicate means keeping the whole
; network alive past the region with something downstream discharging it — a real
; capability, and a separate increment.
;
; The message is `condition used outside the branch`, the string
; `RegionTreeDetect` already uses for exactly this situation (a shape that would
; be shareable if the emitter had a shared-flag path and does not).
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %ca = icmp eq i32 %q, 5
  %cb = icmp eq i32 %r, 3
  %c = select i1 %ca, i1 %cb, i1 false
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %z = zext i1 %ca to i32
  %d = call i32 @cq_measure_si32(i32 %z)
  %m = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %d
  ret i32 %s
}

; CHECK: cq controlled lowering: condition used outside the branch under quantum control
