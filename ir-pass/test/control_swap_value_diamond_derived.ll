; control_swap_value_diamond_derived.ll — ACCEPT: a two-link value diamond
; lowered by the CONTROLLED-COPY MERGE (bd test_C_libtooling-3qlq Inc 2), and
; the positive contrast pin for control_swap_reject_value_alias_cond.ll (the
; merged register is NOT in condProvenance(icmp %q), so the alias closure must
; not decline it).
;
; ⚠ THE NAME IS HISTORY AND THE DERIVATION IS GONE — SAY IT RATHER THAN LET THE
; FILENAME CARRY A COVERAGE CLAIM THE BODY NO LONGER MAKES. Until Inc 1 the
; merged slot was `%pd = cq_phi(%p, 0.9)`, a pre-region DIAGONAL alias of %p's
; wire (the 9hh derived-base discipline): rotation lowering RAUW'd %p and %pd to
; the SAME i32 handle, and the emitted stream was this one plus one
; unconditional `cqrt_rz_i32` strictly before the hoisted chain. `cq_phi` is
; REGISTER-FREE since Inc 1 (D1/D2), so that spelling does not exist; the Inc-1
; migration DELETED the line (`; 3qlq: migrated …` below) and this body is now a
; PLAIN base. What the file still pins is the merge stream and the alias-closure
; contrast; what it no longer pins is the derivation.
; The derived-base property is carried instead by the e2e slice
; `tests/e2e/slice_control_value_derived.c`, re-spelled at the Inc-2 REBASE with
; `cq_theta` as the pre-region in-place rotation (MEASURED on three binaries:
; accepts on the pre-3qlq oracle 52d7764 and on the landed Inc-1 `main` by the
; ROUTE at 29 trace lines, and here by the MERGE at 24 — the diamond's 23 plus
; one unconditional `cqrt_ry_i32` on the same handle, strictly before the chain).
; Re-spelling THIS body the same way would restore the lit-level property in one
; line and is deliberately NOT done here: the body is an Inc-1 LANDED migration
; decision, not the rebase's to reverse. Every CHECK below is re-derived from the
; REBASED binary's output.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
; Whole-file PURE-NEGATIVE scan (bd drbq Inc-4 lens: a positive COUNT directive
; inside a prefix WINDOWS every negative after it, so the negatives live alone).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exact counts, one symbol per prefix for the same windowing reason.
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p  = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c  = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %p, 5
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %entry ]   ; straight-through = the DERIVED %p
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; THE WHOLE REGION STREAM, CONTIGUOUS. `CHECK-NEXT` adjacency from the first
; alloc to the measure is the contract here, not decoration (bd
; test_C_libtooling-3qlq Inc 2, Rule-13 round-1 review finding F-V2-5): the
; re-derivation that first shipped this file used bare positional directives
; throughout, and a stray gate spliced between two pinned lines — a
; `cqrt_ry_i32` immediately before the first controlled copy — then passed
; EVERY prefix. Symbol ORDER cannot see an insertion; adjacency can.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; the hoisted arm chain, on the merged register
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[V]], i32 15)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; the strip pinned immediately before the free (no dirty free of the flag)
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])

; No route survives anywhere in the module: the swap route is RETIRED for value
; arms (bd test_C_libtooling-3qlq Inc 2), there is no work rail, and no
; uncontrolled basis copy — the merge is the two CONTROLLED copies alone.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy_i32(
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: call i32 @cq_phi
; NOROUTE-NOT: cqrt_free(i32 %out)

; EXACTLY ONE free in the whole module — the flag. `%out`, the source `%p` and
; the hoisted chain's final rail are all left ALLOCATED (keep-source-live: a
; free of any of them is a hidden measurement, Rule 6/8).
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; EXACTLY TWO controlled copies — the whole merge.
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
