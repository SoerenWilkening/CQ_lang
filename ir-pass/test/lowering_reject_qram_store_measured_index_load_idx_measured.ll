; lowering_reject_qram_store_measured_index_load_idx_measured.ll — ACCEPT since
; bd test_C_libtooling-ptue (was bd test_C_libtooling-01po.4's second refusal
; twin). Its own L7 retirement trigger fired: "borrowing `p` as well ... would
; lower it ... when it lands, this becomes an accept". The name is kept so a
; merge cannot resurrect the old decline under it.
;     arr[b] = 0;  v = arr[p];  cq_theta(&b, -.5);
;     return cq_measure(b) + cq_measure(v) + cq_measure(p);
;
; THE LOWERING. The array-frontier retry of lowering_qram_store_measured_index_
; nonmain.ll borrowed only QRAM arrays, so the reduced DAG (the load and the `p`
; wire) was still measured upstream and the module declined. Since ptue every
; rail the scan saw measured is borrowed too: `p` is read-only for the reversal
; — never walked (its prep Ry is NOT reverse-played, unlike the nonmain twin
; where `p` is dead and owned), never freed. The reduced DAG is the load alone.
; Hand trace (index rail T = zext(p), re-derived for the adjoint):
;   load(arr, p)            v = arr[p]             (v minted from |0>)
;   ry(b, -.5); measure(b)  the user's; b is behind the borrowed array, untouched
;   copy(v -> OUT)          the measured-value copy-out into a kept carrier
;   T = zext(p); load_unc(v, arr, T); zext_unc(T, p); free(T)
;                           v ^= arr[p] -> |0>: arr has no store after the load
;                           and p is unmoved between the load and here
;                           (`borrowedParentsUnmoved` proves both)
;   free(v)                 |0> in a product state — no information learned
;   measure(OUT); measure(p) the program's joint distribution of v and p
;
; THE DECLINE NEIGHBOUR, measured rather than argued (bd ptue): rotating `p`
; between the load and the reversal (`cq_theta(&p, .3)` before the measures)
; makes the clause-(d) scan refuse the borrow, and the module keeps the decline
; verbatim — the reversal would re-derive T from a moved `p` and pop the wrong
; cell. lowering_reject_uncompute_measured_parent_moved.ll pins that refusal on
; the scalar surface.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOP < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @idx_measured(i1 %u0, i1 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %zb = zext i1 %b to i64
  %gb = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zb
  store i32 0, ptr %gb, align 4
  %p = call i1 @cq_theta_i1(i1 %u1, double 5.000000e-01)
  %zp = zext i1 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zp
  %v = load i32, ptr %gp, align 4
  %b2 = call i1 @cq_theta_i1(i1 %b, double -5.000000e-01)
  %mb = call i1 @cq_measure_i1(i1 %b2)
  %mv = call i32 @cq_measure_si32(i32 %v)
  %mp = call i1 @cq_measure_i1(i1 %p)
  %zmb = zext i1 %mb to i32
  %zmp = zext i1 %mp to i32
  %r1 = add i32 %mv, %zmb
  %r = add i32 %r1, %zmp
  ret i32 %r
}

; CHECK-LABEL: define i32 @idx_measured(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]],
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u1)
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]],
; CHECK:      call void @cqrt_ry_i1(i32 %[[B]], double -5.000000e-01)
; CHECK:      call i1 @cqrt_measure_i1(i32 %[[B]])
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[V]], i32 %[[OUT]])
; The reduced reversal: the load against the unchanged array and the borrowed,
; unmoved `p`; its rail freed; `p`'s own Ry is NOT reverse-played:
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[P]])
; CHECK-NEXT: call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[T]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[T]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: call i1 @cqrt_measure_i1(i32 %[[P]])
; The store is never reversed and the array never freed:
; CHECK-NOT:  cqrt_qram_store_i32_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[ARR]])
; CHECK:      ret i32

; The measured index `p` is never un-rotated and never freed (window = its
; alloc -> EOF):
; NOP:     %[[P2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u1)
; NOP-NOT: call void @cqrt_ry_i1(i32 %[[P2]], double -5.000000e-01)
; NOP-NOT: call void @cqrt_free(i32 %[[P2]])
