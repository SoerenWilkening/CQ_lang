; control_swap_value_accept_i8_merge_cast.ll — ACCEPT spec: a DOWNSTREAM CAST
; off a VALUE-arm merge, at a sub-i32 width.
;
; ⚠ THIS FIXTURE PINS AN ACCEPT-CLASS WIDENING, and that is its whole point
; (bd test_C_libtooling-3qlq Inc 2, Rule-13 round-1 review finding F-V1-1; owner
; disposition OQ-22: KEEP and PIN). MEASURED on this exact module:
;   ORACLE (52d7764, the pre-3qlq swap route):
;     rc=1  error: … no template for opcode 'sext i32' in tainted context
;   SUBJECT (3qlq Inc 2):
;     rc=0, the stream below, `free_pairing_check.py` STRICT rc=0.
;
; THE MECHANISM IS THE WIDTH TABLE, not the merge gates. Inc 2 routes the value
; diamond through `emitSelectRegion`, which records `taint.HandleWidth[out]`
; (bd p119.6) — the side table `OpcodeLowering`/`CastLowering` read to recover
; the LOGICAL width of a laundered i32 handle. The retired `emitValueRegion`
; wrote no such entry, so every downstream consumer of the merged register
; declined `no template …`. The emitted stream here is the 4.4 select merge's
; OWN stream (identical to `control_swap_value_diamond.ll`'s, at i8), plus the
; cast the oracle could not lower — the widening is that the cast now resolves,
; not that any merge gate changed.
;
; The width is CONSISTENT end to end, which is the property that would be a
; FINDING if it were not: chain `_i8`, out-rail `cqrt_alloc_i8`, merge copies
; `cqrt_copy_i8_controlled`, cast `cq_template_sext_i8_to_i32`. A laundered
; width would show up here as an i32 template over an i8 rail.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
declare i8 @cq_theta_si8(i8, double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i8 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i8 @cq_theta_si8(i8 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i8 %p, 5
  %v2 = add i8 %v1, 15
  br label %merge
merge:
  %pm = phi i8 [ %v2, %arm ], [ %p, %entry ]
  %w  = sext i8 %pm to i32
  %m  = call i32 @cq_measure_si32(i32 %w)
  ret i32 %m
}

; The whole region is one CONTIGUOUS straight-line stream in the pred, so it is
; pinned contiguously: an inserted gate anywhere between the mint and the cast
; reddens the chain (Inc-2 round-1 review finding F-V2-5 — a bare non-NEXT
; directive list cannot see an insertion between two pinned lines).
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 %v0)
; CHECK-NEXT: call void @cqrt_ry_i8(i32 %[[P]], double 2.500000e-01)
; the hoisted arm chain on the ORIGINAL %p (M-C in place on the FRESH rail only)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i8_hl(i32 %[[P]], i8 5)
; CHECK-NEXT: call void @cqrt_addc_i8(i32 %[[V]], i8 15)
; the 4.4 merge: mint -> |0> out -> two X-bracketed controlled copies -> strip -> free
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i8(i8 0)
; CHECK-NEXT: call void @cqrt_copy_i8_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i8_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; THE WIDENING: the cast off the merged register resolves at the RECORDED i8
; width. The oracle declined exactly here.
; CHECK-NEXT: %[[W:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sext_i8_to_i32(i32 %[[OUT]])
; bd r2j3.32: the merge rail is reversed after its last reader -- the copy
; core re-emitted in reverse under the SAME flag, the flag strip DEFERRED to
; after it, then the rail freed (it used to leak; a later gate on the
; condition register dephased against it).
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i8_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i8_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[OUT]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[W]])

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy_i8(
; NOROUTE-NOT: phi i8
; NOROUTE-NOT: call i8 @cq_theta
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: sext i8
; no i32-width gate may touch the i8 merge lineage (the laundered-width hazard)
; NOROUTE-NOT: cqrt_alloc_i32(i32 0)
; NOROUTE-NOT: cqrt_copy_i32_controlled

; EXACTLY ONE free — the flag. `%out`, `%p` and the chain final are left
; ALLOCATED (keep-source-live / the Inc-2 dirty-final leak; Rule 6).
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; CCNT-COUNT-4: call void @cqrt_copy_i8_controlled(
; CCNT-NOT:     call void @cqrt_copy_i8_controlled(
