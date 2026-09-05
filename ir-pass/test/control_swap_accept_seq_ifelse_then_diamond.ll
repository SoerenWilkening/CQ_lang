; control_swap_accept_seq_ifelse_then_diamond.ll — ACCEPT (bd hcrg): an if/else
; whose MERGE hosts the next region's tainted branch, i.e. two SEQUENTIAL
; tainted-control regions.
;
; `if (q>5) {rz a} else {rz b}; if (q>3) {rz c}` — the natural clang -O1 shape
; for two consecutive tainted ifs. Region 2's `Pred` IS region 1's `MergeBB`.
;
; THIS FIXTURE USED TO BE `control_swap_reject_seq_ifelse.ll`, a DECLINE. The
; decline was never semantic: `flattenRegion` splices region 1's merge into its
; pred and ERASES it, so emitting region 1 first dangled region 2's `Pred`
; pointer — a use-after-free, SIGSEGV on valid input (confirmed live by the
; test_C_libtooling-9hh §8 adversarial review, 2026-06-10). Detection declined
; the pair as `nested control flow` to keep that from happening.
;
; The hazard is now handled where it lives. `lowerControlRegions` builds a
; precedence graph over the accepted regions (A must be emitted before B when A
; names a block B's flatten will erase), topologically orders it, and declines
; loudly on any alias ordering cannot resolve. Here that means REGION 2 IS
; EMITTED FIRST: its blocks are all live at that moment, its own flatten erases
; only {arm2, merge2} — none of which is a block of region 1 — and its tail is
; spliced into `merge`, which region 1's flatten then carries up into `entry`.
;
; PROGRAM ORDER IS UNCHANGED BY THE EMISSION ORDER, and that is the whole point
; of the CHECK block below: each emitter inserts POSITIONALLY into its own pred
; block, so region 1's stream still precedes region 2's in the final linear
; block. The SSA NAMES betray the emission order (region 2 got the un-suffixed
; `%rail`/`%h_cmp`), which is exactly why every name below is a regex capture and
; never a literal.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT  < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b, double %c2a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  call void @cq_phi(double %a)
  br label %merge
else:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %c2 = icmp sgt i32 %q, 3                       ; region 2's tainted branch
  br i1 %c2, label %arm2, label %merge2           ;   lives in region 1's MERGE
arm2:
  call void @cq_phi(double %c2a)
  br label %merge2
merge2:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; One rail, one Ry, the pre-region Rz — then REGION 1 in full, then REGION 2.
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
;
; region 1 — the if/else: one flag, both arms CONTROL-IN-PLACE on %[[Q]] (drbq
; Inc 2a: no work rails), the false arm's gate run X-bracketed, both angles
; verbatim, flag stripped + freed. `CHECK-NEXT` throughout, so the bracket cannot
; drift off the gate it makes conditional — under the route the analogous risk was
; a deleted route-BACK, which the pinned pair below used to catch.
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[Q]], double %a)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F1]], i32 %[[Q]], double %b)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F1]])
;
; region 2 — the diamond, STRICTLY AFTER region 1's flag was stripped and freed.
; Its flag is minted from the SAME live wire %[[Q]] (region 1 left the basis
; untouched: every gate it applied was a diagonal Rz).
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F2]], i32 %[[Q]], double %c2a)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 3)
; CHECK:     call void @cqrt_free(i32 %[[F2]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
;
; The CFG is fully flattened — no residual branch, no phi, no leftover compare.
; CHECK-NOT: phi
; CHECK-NOT: br i1
; CHECK-NOT: icmp sgt
;
; Exactly TWO flag mints and TWO strips — one per region, no duplicate mint from
; the shared wire (`-COUNT-n` + a trailing `-NOT` on the same pattern is the
; house idiom for "exactly n"; both patterns anchor on `call` so the `declare`
; lines at the bottom of the module cannot satisfy them).
; (Separate prefixes: FileCheck directives are ORDERED within one prefix, so a
; trailing `-NOT` scanning to EOF would starve any later `-COUNT` on the same
; prefix. One prefix per counted symbol is the only spelling that means what it
; reads as. Extra FileCheck spawns are ~free; extra `%cq-opt` spawns are not,
; which is why all three RUN lines share the single `%t.cqd0.ll`.)
; CNT-COUNT-2:  = call i32 @cq_template_icmp_sgt_i32_hl(
; CNT-NOT:      = call i32 @cq_template_icmp_sgt_i32_hl(
; CNT2-COUNT-2: call void @cq_template_icmp_sgt_i32_hl_unc(
; CNT2-NOT:     call void @cq_template_icmp_sgt_i32_hl_unc(

; No swap route survives on either region — window `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
