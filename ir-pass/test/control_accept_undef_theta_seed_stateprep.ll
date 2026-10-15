; control_accept_undef_theta_seed_stateprep.ll — ACCEPT (bd z9t1). THE SECOND
; RULED SPELLING: `bool b1; if (c) cq_theta(&b1, 0.5);` — an uninitialized
; `_Bool` prepared UNDER QUANTUM CONTROL.
;
; Owner, 2026-09-14: "both codes are supposed to compie!! also no warnings." On
; the oracle (2026-09-13 primary, f7b65d8c) this module was a LOUD DECLINE —
; `cq controlled lowering: state prep seed does not match the merge incoming
; under quantum control` — because F1's first sub-clause requires the seed to be
; a `ConstantInt`/`ConstantFP` and an `UndefValue` is neither.
;
; *** THIS FILE IS WHY THE NORMALIZER CANNOT LIVE AT THE EMISSION SITE, and it is
; also why normalizing the SEED ALONE is not enough. *** `clang -O1` spells the
; uninitialized `b1` as `undef` at BOTH of its reads — once as the theta's arg-0
; and once as the merge phi's straight-through incoming:
;
;     %3 = call i1 @cq_theta_i1(i1 undef, double 5.0e-01)   ; the SEED
;     %6 = phi i1 [ %3, %2 ], [ undef, %0 ]                 ; the MERGE INCOMING
;
; Normalize only the seed and F1's SECOND sub-clause (the Pred incoming must be
; POINTER-IDENTICAL to the seed) fails on `i1 false` vs `undef`, so the module
; still declines with the same string — MEASURED, not predicted. The rule is
; therefore stated over the OBJECT and not over the operand: one uninitialized
; C object read twice becomes the same concrete zero at both reads, which is a
; refinement of `undef` at each of them (LangRef: `undef` may be replaced by any
; value of its type) and is the only reading under which the two edges agree.
;
; ⚠ CORRECTED — the paragraph that stood here was FALSE and it is the reason
; this correction exists at all. It read: "The scope is TIGHT … a phi incoming is
; normalized ONLY when the phi carries the normalized theta itself as another
; incoming — i.e. only where the same object was undefined on BOTH edges."
; The clause before the dash is what the code asks; THE "i.e." IS FALSE (review
; round 2 F-U2-2, re-measured at scale by round 3 F-U3-2). The clause rewrites
; EVERY `UndefValue` incoming of EVERY phi that has the theta as an operand —
; several phis per theta (164 of 972 carried thetas in the corpus have >1 phi
; user), several incomings per phi (37 phis have >= 2 non-theta incomings, so one
; visit can equate several DISTINCT C objects), and objects the source never
; equated at all. Measured population: 164 modules, all landing byte-identically
; on the zero twin. ⚠ Those two 164s are DIFFERENT QUANTITIES (thetas vs
; modules), equal by coincidence — do not cite one for the other.
;
; The C-level "one object read twice" story above is the MOTIVATION, not the
; precondition, and the widening is DISCLOSED at `RotationLowering.cpp`'s
; disclosure paragraph rather than fenced.
;
; WHY THE SHIPPED DECLINE FIXTURES ARE STILL GREEN — the true reasons:
; `control_inplace_ry_reject_stateprep_undef_incoming.ll` has SEED `i32 0`, so
; `normalizeUndefRotationSeed` returns at the `valueCarriesUndef` gate and never
; reaches its phi loop; `control_peel_reject_{undef,poison}_incoming.ll`'s
; undef-bearing phi does not carry a theta. Neither is a scope narrowing.
;
; The module is `u2.c` from `$PREV/diag_2026-09-14_probes/` at `-O1`, verbatim
; (DIAG_2026-09-14.md Q2 row ii). Its e2e twin is
; `tests/e2e/slice_undef_seed_in_region.c`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The unconditional prep of b0, then the CONTROLLED prep of b1 on a fresh |0>
; rail — the drbq `StatePrep` kind, which is exactly the circuit the source
; describes (start in |0>, rotate iff the condition holds).
;
; ⚠ THE ARM IS THE **FALSE** SUCCESSOR (`clang -O1` canonicalised the guard into
; `br i1 %1, label %4, label %2`, Rule 9), and a negated controlled **Ry** has no
; diagonal escape, so it is spelled by ADDITIVITY and not by an `x` bracket on
; the user register: `ry(h,θ)` unconditionally, then `ry_controlled(h_b,h,−θ)` to
; cancel it on the `b0 == 1` component (`fneg`, exact for every finite angle).
; That is the SAME stream the owner's 2026-09-11 `grover_oracle_uncompute.c`
; emits for its `b1` prep — this file is that program with `bool b1 = 0;`
; replaced by `bool b1;`, and the only line that moves is the seed's:
; CHECK:     %[[H0:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_ry_i1(i32 %[[H0]], double 5.000000e-01)
; CHECK:     %[[H1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_ry_i1(i32 %[[H1]], double 5.000000e-01)
; CHECK:     call void @cqrt_ry_i1_controlled(i32 %[[H0]], i32 %[[H1]], double -5.000000e-01)
;
; Then the peeled `a`-mux as the rail-root CNOT-copy select merge, whose ONE
; `cqrt_free` is a proven-|0> one (x^x = 0 on every branch). `%[[H0]]` is read
; only as a CONTROL — never `cqrt_x`-bracketed, never freed (Rule 6):
; CHECK:     %[[BF:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_cnot(i32 %[[H0]], i32 %[[BF]])
; CHECK:     call void @cqrt_cnot(i32 %[[H0]], i32 %[[BF]])
; CHECK:     call void @cqrt_free(i32 %[[BF]])
;
; RUN: %filecheck %s --check-prefix=NOUNDEF < %t.cqd0.ll
; NOUNDEF-NOT: i1 undef
; NOUNDEF-NOT: i1 poison
;
; And nothing became a MEASUREMENT the user did not write (Rule 5) — three
; measures in, three out:
; RUN: %filecheck %s --check-prefix=MEASURES < %t.cqd0.ll
; MEASURES-COUNT-3: call {{.*}}@cqrt_measure_

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
; STREAM:      %h = call i32 @cqrt_alloc_i1(i1 false)
; STREAM:      call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; STREAM:      %[[N_h2:h[0-9]*]] = call i32 @cqrt_alloc_i1(i1 false)
; STREAM:      call void @cqrt_ry_i1(i32 %[[N_h2]], double 5.000000e-01)
; STREAM:      call void @cqrt_ry_i1_controlled(i32 %h, i32 %[[N_h2]], double -5.000000e-01)
; STREAM:      %bf = call i32 @cqrt_alloc_i1(i1 false)
; STREAM:      call void @cqrt_cnot(i32 %h, i32 %bf)
; STREAM:      %out = call i32 @cqrt_alloc_i32(i32 0)
; STREAM:      call void @cqrt_xorc_i32_controlled(i32 %bf, i32 %{{[0-9a-zA-Z_.]+}}, i32 2)
; STREAM:      call void @cqrt_x(i32 %bf)
; STREAM:      call void @cqrt_xorc_i32_controlled(i32 %bf, i32 %{{[0-9a-zA-Z_.]+}}, i32 5)
; STREAM:      call void @cqrt_x(i32 %bf)
; STREAM:      call void @cqrt_cnot(i32 %h, i32 %bf)
; STREAM:      call void @cqrt_free(i32 %bf)
; STREAM:      %m = call i1 @cqrt_measure_i1(i32 %h)
; STREAM:      %[[N_m3:m[0-9]*]] = call i1 @cqrt_measure_i1(i32 %[[N_h2]])
; STREAM:      %[[N_m4:m[0-9]*]] = call i32 @cqrt_measure_i32(i32 %out)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @main() local_unnamed_addr {
  %1 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext false, double noundef 5.000000e-01)
  br i1 %1, label %4, label %2

2:
  %3 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext undef, double noundef 5.000000e-01)
  br label %4

4:
  %5 = phi i32 [ 5, %2 ], [ 2, %0 ]
  %6 = phi i1 [ %3, %2 ], [ undef, %0 ]
  %7 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %1)
  %8 = zext i1 %7 to i32
  %9 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %6)
  %10 = zext i1 %9 to i32
  %11 = add nuw nsw i32 %10, %8
  %12 = tail call i32 @cq_measure_si32(i32 noundef %5)
  %13 = add nsw i32 %11, %12
  ret i32 %13
}
