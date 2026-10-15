; carried_fence.ll — cq-merge-selftest input (NOT a lit test: `Inputs/` is
; excluded; ctest `ir-pass-merge-discharge-selftest` runs it). bd
; test_C_libtooling-r2j3.32, routing decision (b) of 2026-10-15: a LEAKED
; loop-carried merge rail (accepted; the reverse loop is bd 8h7d.20) is fenced
; loudly when a non-diagonal gate after the loop acts on a register it records
; (MergeCarriedFence.h).
;
; The loop is the shipped lowering of
;     int a = 5; θ(&c, .5); for (i < 3) if (c > i) a -= 3;
; verbatim (per trip: out ^= f·(a-3), out ^= ¬f·a, strip, free the flag; the
; header φ carries `out` into the next trip, whose merge reads it as a copy
; source, so no trip's rail can be reversed before the next trip's is). Two
; trips' rails stay allocated holding CNOT records of `c > i` — of the
; condition register %h — and of the copied sources.
;
; EVERY SOURCE SPELLING OF THESE `_loud` SHAPES IS DECLINED UPSTREAM TODAY
; (`condition predates a non-diagonal gate under quantum control` for a later
; θ on the condition, `control flow under quantum control` for one on a copied
; source; probes 2026-10-15), so the fence is a second wall that only this
; driver can reach; it is the one that keeps holding if an upstream fence is
; narrowed.
;   * cond_leaf_loud      a later Ry on the CONDITION register %h;
;   * src_leaf_loud       a later Ry on a copied SOURCE register %hx (the
;                         original r2j3.32 shape: the Ry was on the source);
;   * h2a/h2b/h2c         (R11 round 2, revU5) a register CNOT-copied into
;                         what the merge records — after the rail's alloc but
;                         before its copies (h2a), on the back edge into the
;                         next trip (h2b), on one classical path (h2c) — then
;                         rotated after the loop: loud;
;   * h_fence_loud        a later `cqrt_h` on %h — a gate the fence does not
;                         name: it fails closed (R11 round 2 allowlist; the
;                         named-list fence missed it, revU4 probe56);
;   * perm_target_kept    a later controlled copy INTO %h and a `cqrt_cswap`
;                         over it: basis permutations, allowed;
;   * rzctl_target_kept   a later `cqrt_rz_i32_controlled` targeting %h:
;                         diagonal, allowed;
;   * readers_kept        the control: after the loop %h is only measured and
;                         used as the CONTROL of a controlled Ry, and the final
;                         `a` is rotated — none acts non-diagonally on what a
;                         leaked rail records (the final rail is the record's
;                         consumer, not one of its leaves), so no diagnostic and
;                         the rail stays allocated (the accepted leak).

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_copy_i32_controlled(i32, i32, i32)
declare void @cqrt_x(i32)
declare void @cqrt_cnot(i32, i32)
declare void @cqrt_h(i32)
declare void @cqrt_cswap(i32, i32, i32)
declare void @cqrt_rz_i32_controlled(i32, i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)

define i32 @cond_leaf_loud(i32 %u) #0 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  call void @cqrt_ry_i32(i32 %h, double 3.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add nsw i32 %m1, %m
  ret i32 %r
}

define i32 @src_leaf_loud(i32 %u, i32 %w) #0 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %hx = call i32 @cqrt_alloc_i32(i32 %w)
  call void @cqrt_ry_i32(i32 %hx, double 2.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %hx, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cqrt_measure_i32(i32 %h)
  call void @cqrt_ry_i32(i32 %hx, double 3.000000e-01)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %m2 = call i32 @cqrt_measure_i32(i32 %hx)
  %r0 = add nsw i32 %m1, %m
  %r = add nsw i32 %r0, %m2
  ret i32 %r
}

define i32 @h_fence_loud(i32 %u, i32 %w) #0 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  call void @cqrt_h(i32 %h)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add nsw i32 %m1, %m
  ret i32 %r
}

define i32 @perm_target_kept(i32 %u, i32 %w) #1 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i32(i32 %g, double 5.000000e-01)
  %hy = call i32 @cqrt_alloc_i32(i32 %w)
  call void @cqrt_copy_i32_controlled(i32 %g, i32 %hy, i32 %h)
  call void @cqrt_cswap(i32 %g, i32 %h, i32 %hy)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add nsw i32 %m1, %m
  ret i32 %r
}

define i32 @rzctl_target_kept(i32 %u, i32 %w) #1 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i32(i32 %g, double 5.000000e-01)
  call void @cqrt_rz_i32_controlled(i32 %g, i32 %h, double 3.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add nsw i32 %m1, %m
  ret i32 %r
}

; H2a: same CNOT AFTER the rail alloc, before the copies (dominates the merge write, not Out)
define i32 @h2a_cnot_after_alloc(i32 %u, i32 %w) #0 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %hz = call i32 @cqrt_alloc_i32(i32 %w)
  call void @cqrt_ry_i32(i32 %hz, double 2.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_cnot(i32 %hz, i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  call void @cqrt_ry_i32(i32 %hz, double 3.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %hz)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add nsw i32 %m1, %m
  ret i32 %r
}

; H2b: in-place write of the condition register %h at the END of the body;
; the next trip's compare (hence its rail) records %hz through %h.
define i32 @h2b_backedge_write(i32 %u, i32 %w) #0 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %hz = call i32 @cqrt_alloc_i32(i32 %w)
  call void @cqrt_ry_i32(i32 %hz, double 2.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_cnot(i32 %hz, i32 %h)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  call void @cqrt_ry_i32(i32 %hz, double 3.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %hz)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add nsw i32 %m1, %m
  ret i32 %r
}

; H2c: path-conditional (classical) write of the flag before Out.
define i32 @h2c_pathcond(i32 %u, i32 %w, i1 %k) #0 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %hz = call i32 @cqrt_alloc_i32(i32 %w)
  call void @cqrt_ry_i32(i32 %hz, double 2.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %join ]
  %a = phi i32 [ %seed, %entry ], [ %out, %join ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  br i1 %k, label %side, label %join0
side:
  call void @cqrt_cnot(i32 %hz, i32 %h_cmp)
  br label %join0
join0:
  br label %join
join:
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  call void @cqrt_ry_i32(i32 %hz, double 3.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %hz)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %r = add nsw i32 %m1, %m
  ret i32 %r
}

define i32 @readers_kept(i32 %u) #1 {
entry:
  %h = call i32 @cqrt_alloc_i32(i32 %u)
  call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
  %seed = call i32 @cqrt_alloc_i32(i32 5)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %a = phi i32 [ %seed, %entry ], [ %out, %loop ]
  %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
  %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %i)
  %out = call i32 @cqrt_alloc_i32(i32 0), !cq.selftest.merge !0
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %h_op, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %a, i32 %out)
  call void @cqrt_x(i32 %h_cmp)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 %i)
  call void @cqrt_free(i32 %h_cmp)
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop
exit:
  %g = call i32 @cqrt_alloc_i1(i1 false)
  call void @cqrt_ry_i1_controlled(i32 %h, i32 %g, double 3.000000e-01)
  call void @cqrt_ry_i32(i32 %out, double 3.000000e-01)
  %m = call i32 @cqrt_measure_i32(i32 %h)
  %m1 = call i32 @cqrt_measure_i32(i32 %out)
  %m2 = call i32 @cqrt_measure_i32(i32 %g)
  %r0 = add nsw i32 %m1, %m
  %r = add nsw i32 %r0, %m2
  ret i32 %r
}

attributes #0 = { "cq-selftest-expect"="loud" "cq-selftest-message"="cq merge discharge: non-diagonal gate on a register a leaked loop-carried merge rail records" }
attributes #1 = { "cq-selftest-expect"="kept" }

!0 = !{}
