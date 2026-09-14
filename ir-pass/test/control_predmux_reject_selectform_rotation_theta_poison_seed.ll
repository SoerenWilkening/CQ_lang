; control_predmux_reject_selectform_rotation_theta_poison_seed.ll — ⚠ **ACCEPT
; SINCE bd z9t1 (owner ruling 2026-09-14). THE `reject` IN THE FILE NAME IS
; HISTORY.** The rename is deferred to a rename-only change (lesson L8: a
; `git mv` can be resurrected by a merge, leaving one module under two names with
; contradictory verdicts).
;
; THIS IS THE COLLATERAL OF THE z9t1 RULE, PINNED RATHER THAN LEFT UNWITNESSED,
; and it was the one corpus mover OUTSIDE the strings Track U's brief predicted
; — so it is written down here in full rather than explained away.
;
; WHAT IT USED TO PIN (bd u1rp): `classifyConeNode` treats a `cq_theta` as a
; ConeNode::Leaf — its result is a fresh `cqrt_alloc_<W>` handle that does not
; depend on the seed, so the cone walk STOPS and never recurses into the
; arguments. The explicit `Call->args()` undef/poison scan was therefore the ONLY
; protection for a `cq_theta`, and this module was its only witness. Its own
; header called the refusal "a deliberate, cheap over-decline" whose measured
; cost was ZERO, on the ground that the poison reaches exactly one emitted site
; (`cqrt_alloc_i32(i32 poison)`) and one site cannot break a forward/`_unc` pair.
;
; WHY IT IS NOW AN ACCEPT, AND WHY THAT IS SOUND. The z9t1 normalizer rewrites
; the whole-value `poison` SEED to `i32 0` at collection time — BEFORE
; `flattenPredMuxRegions` runs — so by the time `classifyConeNode` asks, there is
; no poison in the cone to find. The over-decline's own premise is gone: the
; emitted module carries no undef/poison slot at all (NOUNDEF below), so there is
; nothing left to be conservative about. Under the owner's 2026-09-11 ruling
; ("our end-goal is to not decline any code that will lead to a valid quantum
; circuit") removing it is a defect removed, not a fence relaxed.
;
; *** THE u1rp PIN MOVED, IT WAS NOT DROPPED ***:
; `control_predmux_reject_selectform_rotation_theta_poison_angle.ll` is the same
; module with the poison in ARG-1, the ANGLE, which Rule 3 keeps permanently
; outside the z9t1 rule's scope — so it reaches the argument scan exactly as this
; file used to, and both binaries (oracle f7b65d8c and the z9t1 build) decline it
; identically. Delete the `Call->args()` scan and THAT file goes red.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The normalized seed, then the ordinary PredMux stream the defined-seed control
; already emits — the `select i1` condition tree as a `cqrt_toffoli` AND, and the
; two X-bracketed controlled copies of the select merge:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_toffoli(
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     call void @cqrt_copy_i32_controlled(
;
; RUN: %filecheck %s --check-prefix=NOUNDEF < %t.cqd0.ll
; NOUNDEF-NOT: i32 undef
; NOUNDEF-NOT: i32 poison
; NOUNDEF-NOT: double poison

;
; *** THE WHOLE EMITTED STREAM, PINNED IN ORDER, WITH NOTHING ELSE ALLOWED. ***
; The two `--implicit-check-not` patterns carry a negative over the ENTIRE file
; between every pair of STREAM lines, so ANY extra emitted gate — an injected
; `cqrt_x` on a user register, a second `cqrt_ry`, a `cqrt_cswap`, a `cqrt_free`,
; a measurement the user did not write (Rule 5) — reddens this prefix wherever it
; is placed. MEASURED with `$SES/trackU/probes/impl/inject_u.py`, not asserted:
; strip this prefix and 11 of 17 mutations over two of these fixtures go MISSED
; (injected `cqrt_x`, extra `cqrt_free`, extra `cqrt_ry`, `cqrt_cswap`, swapped
; copy pair, extra measurement); with it, 0 MISSED of 67 over all nine. The
; patterns match CALL SITES only (`call {{.*}}@cqrt_`), so the module's trailing
; `declare` lines are untouched.
; RUN: %filecheck %s --check-prefix=STREAM \
; RUN:   --implicit-check-not='call {{.*}}@cqrt_' \
; RUN:   --implicit-check-not='call {{.*}}@cq_template_' < %t.cqd0.ll
; STREAM:      %h = call i32 @cqrt_alloc_i32(i32 0)
; STREAM:      call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; STREAM:      %h_op = call i32 @cq_template_add_i32_hl(i32 %h, i32 7)
; STREAM:      %h_op6 = call i32 @cq_template_mul_i32_hl(i32 %h, i32 3)
; STREAM:      %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 3)
; STREAM:      %h_cmp1 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 11)
; STREAM:      %g = call i32 @cqrt_alloc_i1(i1 false)
; STREAM:      call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
; STREAM:      %out = call i32 @cqrt_alloc_i32(i32 0)
; STREAM:      call void @cqrt_copy_i32_controlled(i32 %g, i32 %h_op, i32 %out)
; STREAM:      call void @cqrt_x(i32 %g)
; STREAM:      call void @cqrt_copy_i32_controlled(i32 %g, i32 %h, i32 %out)
; STREAM:      call void @cqrt_x(i32 %g)
; STREAM:      call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)
; STREAM:      call void @cqrt_free(i32 %g)
; STREAM:      call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp1, i32 %h, i32 11)
; STREAM:      call void @cqrt_free(i32 %h_cmp1)
; STREAM:      call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 3)
; STREAM:      call void @cqrt_free(i32 %h_cmp)
; STREAM:      %h_cmp2 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 3)
; STREAM:      %h_cmp3 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 11)
; STREAM:      %g4 = call i32 @cqrt_alloc_i1(i1 false)
; STREAM:      call void @cqrt_toffoli(i32 %h_cmp2, i32 %h_cmp3, i32 %g4)
; STREAM:      %out5 = call i32 @cqrt_alloc_i32(i32 0)
; STREAM:      call void @cqrt_copy_i32_controlled(i32 %g4, i32 %h_op6, i32 %out5)
; STREAM:      call void @cqrt_x(i32 %g4)
; STREAM:      call void @cqrt_copy_i32_controlled(i32 %g4, i32 %h, i32 %out5)
; STREAM:      call void @cqrt_x(i32 %g4)
; STREAM:      call void @cqrt_toffoli(i32 %h_cmp2, i32 %h_cmp3, i32 %g4)
; STREAM:      call void @cqrt_free(i32 %g4)
; STREAM:      call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp3, i32 %h, i32 11)
; STREAM:      call void @cqrt_free(i32 %h_cmp3)
; STREAM:      call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp2, i32 %h, i32 3)
; STREAM:      call void @cqrt_free(i32 %h_cmp2)
; STREAM:      %h_op7 = call i32 @cq_template_add_i32(i32 %out, i32 %out5)
; STREAM:      %m = call i32 @cqrt_measure_i32(i32 %h_op7)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 poison, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = icmp sgt i32 %q, 11
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}
