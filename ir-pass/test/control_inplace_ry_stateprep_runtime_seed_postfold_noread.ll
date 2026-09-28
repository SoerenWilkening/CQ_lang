; control_inplace_ry_stateprep_runtime_seed_postfold_noread.ll — ACCEPT.
;
; bd test_C_libtooling-z0re round 2 (Rule-13 r1A F-r1A-1; bd test_C_libtooling-fmt3).
; THE POST-FOLD MODULE, pinned as an ACCEPT on ONE ground: it IS the legitimate
; program. It is what `clang -O1` makes of (review_r1A_z0re/probes/src/a5.c):
;   r = s; if (q2 > 3) { if (q == s) r = cq_theta(q, .9); else r = cq_theta(s, .9); }   (q not read after)
; SimplifyCFG sinks the INNER if/else of two thetas (one differing operand -> one phi),
; FoldTwoEntryPHINode turns the phi into `select (q == s), q, s`, InstSimplify folds
; that to `s`, and the pinning branch is ERASED. What reaches the pass is the body
; below: an OUTER diamond on `q2 > 3` whose arm is `cq_theta(s, .9)` and whose Pred
; incoming is `s` — a runtime-seed state prep F1 admits — and it is the module of the
; legitimate `r = s; if (q2 > 3) r = cq_theta(s, .9);`, IDENTICAL at -O1 up to the order
; of the merge phi's two incomings (MEASURED, z0re_probes/foldcmp.sh vs
; z0re_probes/src/a5legit.c; the pass keys on incoming BLOCKS, not order). bd fmt3 measured
; the class (n12/n13: the rotated register need not even be the erased compare's
; operand), so no question the pass can ask of this IR separates the two readings.
;
; THE DISPOSITION IS AT THE SOURCE LEVEL: bd fmt3 OPTION B (owner ruling 2026-09-28)
; puts `__attribute__((nomerge))` on the `cq_theta_*` declarations in `CQ.h`, so
; `-O1` can no longer merge the two thetas; the inner branch then survives to reach
; F2. That track lands AFTER z0re; until it does, the C spelling above still folds to
; this module and still accepts — the known window, whose LITERAL-seed members
; accept on the oracle today (bd fmt3's own population).
;
; On the ORACLE (main 9a230646) this module DECLINES at F1's literal-only clause.
; RETIREMENT TRIGGER (L8): none for this file — it pins the legitimate program's
; lowering and stays an ACCEPT whatever fmt3 does. The C-level probe a5.c is what
; fmt3's `nomerge` moves (to a decline at F2 or to a nested-region verdict).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %m, i32 %s) {
entry:
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 7, double 4.000000e-01)
  %c = icmp sgt i32 %q2, 3
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %s, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %s, %entry ], [ %rt, %arm ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mq2 = call i32 @cq_measure_si32(i32 %q2)
  %a = add nsw i32 %mq2, %mr
  ret i32 %a
}

; `q` is never read after the region, so the only difference from the source is the
; in-place Ry the fold removed from a register nothing observes afterwards.
; CHECK:      %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %s)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])

; NEG-NOT: cq_theta_
; NEG-NOT: = phi
