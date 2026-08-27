; control_predmux_accept_nonroot_shield_no_orphan.ll — ACCEPT (bd kqqv), and the
; RED half of this increment's red-green pair. It is an ACCEPT fixture whose
; content is a NEGATIVE: the module must lower with the condition tree fully
; swept and NO dead 4.4 select merge left behind.
;
; THE SHAPE. A poison-shielded short-circuit select that is NOT the branch
; condition — `%inner = select i1 %b, i1 %c, i1 false` feeding
; `%sc = and i1 %a, %inner` — with the gate arm on the TRUE successor, which is
; the polarity that routes the true-edge literal through `canonicalizePred`.
;
; *** WHAT WENT WRONG. *** `canonicalizePred` REWRITES that shield into
; `and(%b, %c)` and `track()`ed nothing, so the original SelectInst was
; STRANDED: `sweepDead` erases only `MaybeDead` members, and the sole tracked
; member of the original tree was its ROOT (`track(BI->getCondition())` in
; `run()`). One level down, nothing tracked it. The 4.4 select path then lowered
; that dead select into an ENTIRE DEAD CONTROLLED-COPY MERGE, measured on this
; exact module at 3319975:
;     %h_cmp12 = call i32 @cq_template_icmp_ne_i32_hl(i32 %h, i32 7)  <- no _unc,
;                                                                       no free
;     %out     = call i32 @cqrt_alloc_i1(i1 false)                    <- never freed
;     call void @cqrt_copy_i1_controlled(i32 %h_cmp, i32 %h_cmp12, i32 %out)
;     call void @cqrt_x(i32 %h_cmp)
;     %selop   = call i32 @cqrt_alloc_i1(i1 false)                    <- never freed
;     call void @cqrt_copy_i1_controlled(i32 %h_cmp, i32 %selop, i32 %out)
;     call void @cqrt_x(i32 %h_cmp)
; `%out` has exactly three mentions — its definition and the two writes — and is
; NEVER READ. The condition is then lowered a SECOND time as a plain compare
; tree, so the whole merge is dead while `%out` stays entangled with `%h` through
; both its control and its source: three dangling entangled rails (Rules 6/8).
;
; *** THE ROOT-LEVEL MEASUREMENT THAT MISSED IT IS THE LESSON. *** bd `qesi`
; recorded "canonicalizePred also rebuilds and orphans NOTHING, measured 0 at
; both polarities" and told future readers not to fix it. That measurement was
; real and is still true — AT DEPTH 0 ONLY, where `run()`'s
; `track(BI->getCondition())` happens to cover the shield. The scope clause was
; missing, and the capitalized directive would have foreclosed a real leak.
; Re-measured for this increment at 3319975, orphan controlled-copy merges by
; shield DEPTH, gate arm on the TRUE successor:
;     ROOT shield  (`%sc = select i1 %b, i1 %c, i1 false`)              0
;     under `and`  (`%sc = and i1 %a, %inner`)                          2
;     under `or`   (`%sc = or  i1 %a, %inner`, or-form shield)          2
;     under a shield (`%sc = select i1 %inner, i1 %d, i1 false`)        2
;     two `and`s deep                                                   2
; So it is DEPTH, not spelling, and the root row is the only clean one.
;
; BOTH SHIPPED GATES ARE BLIND TO THIS, which is why it needs a fixture at all:
; `opt` exits 0, the verifier is clean, and `free_pairing_check.py` on the
; leaking module printed "9 rail mint(s) of which 5 left allocated, 11 cqrt_free
; site(s): 11 verified, 0 violation(s), 0 unproven", rc=0 — it counts
; `cqrt_alloc_*` mints and an orphan compare flag is TEMPLATE-minted (bd `1739`).
;
; REACH, STATED WITH ITS LIMIT — AND IT IS A REACHED ZERO, NOT A NO-REACH ONE.
; Latent, not shipping: the filing round found 0 occurrences across 1284 corpus
; modules, a census of all 1062 fixtures found ZERO carrying a non-root shielded
; select (accept or reject), and 19 `clang -O1` C spellings failed to produce one;
; this increment tried 9 more (compound `||`/`&&` ladders, fp and i64 variants, a
; bitwise `&` of a short-circuit) and got 0 i1 selects from every one. The A/B over
; 239 real-C e2e stage-1 modules is likewise 0 exit flips / 0 stderr diffs / 0 IR
; diffs.
; *** BUT THE SHIELD REWRITE ITSELF IS EXERCISED BY REAL CODE, which is what makes
; that zero worth anything: an instrumented build enters `canonicalizePred` 3680
; times across 109 of those 239 modules, 16 of them ON A SHIELD — 4 in `coshl`,
; 3 in `sinhl`, one each in `acoshl`, `tanhl`, `pow`, `nextafterl`, `nexttoward`.
; All 16 sit at DEPTH 0. *** So the guarded path is live on openlibm and the depth
; that leaks simply never occurs there — which is precisely why a root-level
; measurement looked complete. Nothing committed exhibits the defect and this
; fixture is the first thing in the tree to cover the cell: the actual finding is
; not that it leaks, but that nothing would have told us.
;
; NO e2e SLICE IS OWED OR POSSIBLE FOR THIS CELL: every e2e slice starts from a
; `.c`, and 28 measured C spellings produce no depth≥1 i1 shield. Hand-written IR
; is the only way to reach it, which is the idiom every reject fixture here uses.
;
; The arm-kill twin is control_predmux_accept_nonroot_shield_armkill.ll (same
; module, successors swapped), which proves these CHECK-NOTs are not satisfied
; trivially by a decline or a rename.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll --check-prefix=SWEPT

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = icmp slt i32 %q, 100
  %c = icmp ne i32 %q, 7
  %inner = select i1 %b, i1 %c, i1 false     ; the NON-ROOT shield
  %sc = and i1 %a, %inner
  br i1 %sc, label %arm, label %merge        ; arm = TRUE successor

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

; The region IS claimed and DOES lower — the shield is rewritten to `and`, so the
; flag tree is a pure and-tree over the three original compare leaves, each
; minted, uncomputed and freed, and the two phis are merged by the i32
; controlled-copy. Without these positives the CHECK-NOTs below could pass on a
; module that simply declined:
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 3)
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H]], i32 100)
; CHECK:     call i32 @cq_template_icmp_ne_i32_hl(i32 %[[H]], i32 7)
; CHECK:     call void @cqrt_toffoli
; CHECK:     call void @cqrt_copy_i32_controlled
; CHECK:     call void @cq_template_icmp_ne_i32_hl_unc
; CHECK:     call void @cqrt_free

; NOT ONE i1 controlled-copy anywhere in the module. There is no i1-typed DATA in
; this function, so every `cqrt_copy_i1_controlled` here would be the stranded
; shield's dead merge — the whole defect, in one symbol:
; SWEPT-NOT: cqrt_copy_i1_controlled
