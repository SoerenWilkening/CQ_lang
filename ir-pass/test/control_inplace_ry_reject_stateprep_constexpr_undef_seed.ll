; control_inplace_ry_reject_stateprep_constexpr_undef_seed.ll — DECLINE (F1, the
; FIRST sub-clause: the SEED must be a `ConstantInt` or `ConstantFP`).
;
; ⚠ ADDED 2026-09-14 (bd z9t1) BECAUSE THE RULE THAT LANDED THAT DAY TOOK OVER
; THE TWO FIXTURES THAT USED TO PIN THIS CLAUSE. `..._stateprep_undef_seed.ll`
; and `..._stateprep_poison_seed.ll` were written (2026-09-05, lens L1 finding
; F-L1-2) precisely because relaxing clause 1 to `isa<Constant>` left every other
; fixture green. The z9t1 normalizer now rewrites a whole-value `undef`/`poison`
; SEED to a concrete zero at collection time, so BOTH of those files are now
; ACCEPTS and clause 1 can no longer be reached through an `UndefValue`.
;
; THIS FILE REACHES IT THROUGH THE OTHER DOOR, which the clause's own comment
; names as a SEPARATE reason: a `ConstantExpr` is a LINK-TIME constant whose
; value this compiler cannot read, so "the rail starts at |SEED>" is
; unverifiable. Relax clause 1 to `isa<Constant>` and this file goes red.
;
; IT IS ALSO THE NEGATIVE HALF OF THE NORMALIZER'S RED-GREEN PAIR, and that is
; the more important of its two jobs. The seed here CARRIES a literal `undef`
; (buried in a `getelementptr` index, the LiteralIntegrity.h witness spelling
; that LLVM 19 reads back VERBATIM rather than folding), so
; `valueCarriesUndef(Seed)` — the shared predicate the normalizer asks — is
; TRUE. The normalizer still does not fire, because its ACTION is gated on the
; seed BEING an `UndefValue`, not on it CARRYING one:
;
;   * replacing a whole-value `undef` with zero is a REFINEMENT — LangRef lets
;     any value of the type stand in, so the emitted circuit is one the source
;     already licensed;
;   * replacing an EXPRESSION that merely contains an undef leaf with zero is
;     NOT — `ptrtoint (gep @g, undef, 1)` denotes an address, and no choice of
;     the leaf makes that address 0. Normalizing it would be a silent value
;     change, which is the one unforgivable direction (Prime Directive), and the
;     ruling's own justification does not reach it: a `ConstantExpr` is UNIQUED
;     into ONE link-time relocation (bd bu96), so it has no multi-materialisation
;     hazard for the rule to remove.
;
; Point the normalizer at `valueCarriesUndef` ALONE — the obvious "simplify" —
; and this file goes red as an ACCEPT. That is the mutation it exists to catch.
;
; The pred incoming is the SAME expression as the seed, so clause 2 (the
; incoming must be pointer-identical to the seed) PASSES and the decline is
; clause 1's alone.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed does not match the merge incoming under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

@g = external global [4 x i32]

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 ptrtoint (ptr getelementptr inbounds ([4 x i32], ptr @g, i64 undef, i64 1) to i32), double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ ptrtoint (ptr getelementptr inbounds ([4 x i32], ptr @g, i64 undef, i64 1) to i32), %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mq
}
