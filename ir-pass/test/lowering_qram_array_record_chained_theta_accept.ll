; lowering_qram_array_record_chained_theta_accept.ll — ACCEPT, and it is a NAMED
; SCOPE GAP, not a proof of soundness. The QRAM-ARRAY record class is RULED
; DEFERRED for M-A Increment 1 (owner ruling 2026-08-27, second round, point 4;
; bd test_C_libtooling-6uqc). This fixture PINS the boundary so the deferral is
; visible in the test suite instead of living only in a comment.
;
; WHAT LOWERS HERE, and why it is uncomfortable:
;     %arr1 = cqrt_qram_alloc_i32(4)
;     %h    = cqrt_alloc_i32(%u0) ; cqrt_ry_i32(%h, 0.5)
;     %h_op = cq_template_and_i32_hl(%h, 3)          <- the index wire
;     %qval = cqrt_alloc_i32(%k)
;     cqrt_qram_store_i32(%arr1, %h_op, %qval)       <- writes %k at cell |h_op>
;     cqrt_ry_i32(%h_op, 0.25)                       <- the chained gate, ACCEPTED
; After the store, the ARRAY register is correlated with the index wire's value
; (cell `h_op` holds `k`, every other cell holds 0), so it is a live basis record
; of `%h_op` in exactly the physical sense clause 1 is about — and the
; non-diagonal gate fires over it. The guard does not see it because clause 1
; admits only the `cq_template_*` / `cqrt_qram_load_*` producer families; a QRAM
; array handle is minted by `cqrt_qram_alloc_*` and its cells are written by a
; VOID store that mints no rail at all, so nothing in the record walk reaches it.
;
; SECOND DEFERRAL VISIBLE IN THE SAME STREAM: `%h` (the `cqrt_alloc`-minted
; parent of `%h_op`) and `%qval` are ANCESTOR-class rails — Increment 3, after
; M-C removes the out-of-place ancestor mint. Increment 1 is the DESCENDANT half
; only, deliberately, so `slice_control_seq_grover`'s golden does not redden
; before the mechanism that fixes it lands.
;
; IF THIS FIXTURE EVER STARTS TO DECLINE, that is a scope change, not a
; regression: update it (and bd test_C_libtooling-6uqc) rather than widening
; something to keep it green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @slice(i32 %u0, i32 %k) {
entry:
  %arr = alloca [4 x i32], align 16
  call void @llvm.memset.p0.i64(ptr nonnull align 16 %arr, i8 0, i64 16, i1 false)
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = and i32 %q, 3
  %ie  = zext nneg i32 %idx to i64
  %pi  = getelementptr inbounds [4 x i32], ptr %arr, i64 0, i64 %ie
  store i32 %k, ptr %pi, align 4                                 ; array cell records the wire
  %q2  = call i32 @cq_theta_si32(i32 %idx, double 2.500000e-01)  ; chained, in-place Ry
  ret i32 %q2
}

; CHECK:      %[[ARR:.*]] = call i32 @cqrt_qram_alloc_i32(i32 4)
; CHECK:      %[[IDX:.*]] = call i32 @cq_template_and_i32_hl(
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[IDX]],
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[IDX]], double 2.500000e-01)
