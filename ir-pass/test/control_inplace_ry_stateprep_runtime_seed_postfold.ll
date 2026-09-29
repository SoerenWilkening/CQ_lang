; control_inplace_ry_stateprep_runtime_seed_postfold.ll — ACCEPT.
;
; bd test_C_libtooling-z0re round 2 (Rule-13 r1A F-r1A-1; bd test_C_libtooling-fmt3).
; THE POST-FOLD MODULE, pinned as an ACCEPT on ONE ground: it IS the legitimate
; program. It is what `clang -O1` makes of (review_r1A_z0re/probes/src/a1.c):
;   r = s; if (q2 > 3) { if (q == s) r = cq_theta(q, .9); else r = cq_theta(s, .9); } ... cq_measure(q)
; SimplifyCFG sinks the INNER if/else of two thetas (one differing operand -> one phi),
; FoldTwoEntryPHINode turns the phi into `select (q == s), q, s`, InstSimplify folds
; that to `s`, and the pinning branch is ERASED. What reaches the pass is the body
; below: an OUTER diamond on `q2 > 3` whose arm is `cq_theta(s, .9)` and whose Pred
; incoming is `s` — a runtime-seed state prep F1 admits — and it is the module of the
; legitimate `r = s; if (q2 > 3) r = cq_theta(s, .9);`, IDENTICAL at -O1 up to the order
; of the merge phi's two incomings (MEASURED, z0re_probes/foldcmp.sh vs
; z0re_probes/src/a1legit.c; the pass keys on incoming BLOCKS, not order). bd fmt3 measured
; the class (n12/n13: the rotated register need not even be the erased compare's
; operand), so no question the pass can ask of this IR separates the two readings.
;
; THE DISPOSITION IS AT THE SOURCE LEVEL: bd fmt3 OPTION B (owner ruling 2026-09-28,
; LANDED after z0re on 2026-09-29) puts `__attribute__((nomerge))` on the `cq_theta_*`
; declarations in `CQ.h`, so `-O1` can no longer merge two DIRECT calls; the inner
; branch survives and the C spelling now declines `nested control flow` (measured,
; fmt3 r1A `nm_a*` and the implementer's `zt_a*`). ⚠ ONLY DIRECT CALLS: clang puts
; `nomerge` on the call SITE, so the same source through a FUNCTION POINTER still folds
; to this module and still accepts (r1A `fpzt_a1`, on the composed binary — bd `4e4p`,
; P1, PRE-EXISTING). This file pins the legitimate program's lowering either way.
;
; On the ORACLE (main 9a230646) this module DECLINES at F1's literal-only clause.
; RETIREMENT TRIGGER (L8): none for this file — it pins the legitimate program's
; lowering and stays an ACCEPT whatever fmt3 does. The C-level probe a1.c is what
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
  %mq = call i32 @cq_measure_si32(i32 %q)
  %a = add nsw i32 %mq, %mr
  %mq2 = call i32 @cq_measure_si32(i32 %q2)
  %b = add nsw i32 %a, %mq2
  ret i32 %b
}

; `q` is allocated and rotated ONCE (its own Ry(.5)) and measured unrotated; the fresh
; rail is seeded with the runtime `s` and rotated under the flag from `q2 > 3`.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %m)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[Q2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q2]], double 4.000000e-01)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q2]], i32 3)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %s)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q2]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[Q]])

; NEG-NOT: cq_theta_
; NEG-NOT: = phi
