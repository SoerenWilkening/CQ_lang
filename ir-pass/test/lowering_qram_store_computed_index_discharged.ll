; lowering_qram_store_computed_index_discharged.ll — ACCEPT (bd
; test_C_libtooling-r2j3.1, a P1 silent miscompile). A QRAM store that is NEVER
; reversed (the array is read back and the result measured; in `main` nothing is
; reversed at all) reads COMPUTED rails: its index `q & 7` (`and_i32_hl`) and its
; value `r + 1` (`add_i32_hl`). Both sources are then rotated back by a chained
; `cq_theta`.
;
; THE DEFECT. `ChainWalk::isInteriorConsumer` refused a store as a consumer, so
; neither rail was ever discharged: each stood allocated as a live CNOT copy of
; its source across `cqrt_ry_i32(src, -0.5)`. That gate then rotated a register
; entangled with the copy — the source program returns q (and r) to its initial
; basis state, the lowered circuit measures it at random. `opt` exit 0, stage 2b
; clean ("template rail ... left dirty" is a census line, not a gate), one M-A
; `live derived record` warning.
;
; THE FIX (clause (b″) of `isInteriorConsumer`). A store reads its index and its
; value exactly as a load reads its index — it is in place on the ARRAY only —
; so both rails are M-B interior rails, discharged right after the store
; (`_unc` + `cqrt_free`), BEFORE the chained Ry: the record-freeze algebra
; (bd 261j(a)) frees them clean because each is a basis permutation of a source
; that is unchanged between its mint and its `_unc`. The M-A warning goes away
; because the records are gone, not because the guard was relaxed.
;
; The decline-direction twins live in lowering_qram_store_computed_index_leak.ll.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; RUN: %filecheck %s < %t.cqd0.ll
; DIAG-NOT: live derived record
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %u) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %u1 = add nsw i32 %u, 1
  %r = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %val = add nsw i32 %r, 1                        ; computed VALUE
  %idx = and i32 %q, 7                            ; computed INDEX
  %zidx = zext nneg i32 %idx to i64
  %g = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zidx
  store i32 %val, ptr %g, align 4                 ; arr[q & 7] = r + 1 — never reversed
  %u2 = add nsw i32 %u, 2
  %p = call i32 @cq_theta_si32(i32 %u2, double 5.000000e-01)
  %pidx = and i32 %p, 7
  %zp = zext nneg i32 %pidx to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zp
  %v = load i32, ptr %gp, align 4
  %q2 = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)   ; q rotated back
  %r2 = call i32 @cq_theta_si32(i32 %r, double -5.000000e-01)   ; r rotated back
  %mq = call i32 @cq_measure_si32(i32 %q2)
  %mr = call i32 @cq_measure_si32(i32 %r2)
  %mv = call i32 @cq_measure_si32(i32 %v)
  %s1 = add nsw i32 %mr, %mq
  %s2 = add nsw i32 %s1, %mv
  ret i32 %s2
}

; CHECK-LABEL: define i32 @main(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u)
; CHECK:      %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK:      %[[VAL:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[R]], i32 1)
; CHECK-NEXT: %[[IDX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[IDX]], i32 %[[VAL]])
; Both computed rails are discharged IMMEDIATELY after the store, against their
; un-rotated sources, and freed:
; CHECK-NEXT: call void @cq_template_add_i32_hl_unc(i32 %[[VAL]], i32 %[[R]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[VAL]])
; CHECK-NEXT: call void @cq_template_and_i32_hl_unc(i32 %[[IDX]], i32 %[[Q]], i32 7)
; CHECK-NEXT: call void @cqrt_free(i32 %[[IDX]])
; ...and only THEN do the chained rotations fire on the sources:
; CHECK:      call void @cqrt_ry_i32(i32 %[[Q]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double -5.000000e-01)
; The array handle is never freed and the store is never reversed:
; CHECK-NOT:  call void @cqrt_free(i32 %[[ARR]])
; CHECK-NOT:  cqrt_qram_store_i32_unc
; CHECK:      ret i32
