; lowering_qram_store_measured_index_nonmain.ll — ACCEPT (bd
; test_C_libtooling-01po.4, a goal-1 over-decline). The NON-main form of
; lowering_qram_index_width_shadow.ll's @main:
;     int arr[8] = {0};  arr[b] = 0;  v = arr[p];  b = cq_theta(b, -.5);
;     return cq_measure(b) + cq_measure(v);          // b, p _Bool
; In `main` it lowers (nothing is reversed there). Outside `main` the measured
; load result is copied out to a kept carrier and its DAG reversed — and the
; whole-DAG walk followed the ARRAY into its store history, reached the store's
; index `b`, found `b` measured, and declined the module: "cq uncompute: dead
; chain would free a measured register".
;
; THE LOWERING. The load's reversal needs only the array's state AT THE LOAD
; and its index `p` — not the array's history. When the whole DAG is measured
; upstream, `reverseTerminalGroup` retries with every QRAM ARRAY root BORROWED
; (`InteriorPlan::Borrowed`: not walked, its stores not reversed, never freed —
; an array handle is never freed anyway) and requires, with the M-B clause-(d)
; scan, that no store touches the array between the load and the reversal. Here
; the only store precedes the load, so the reduced DAG is the load and the `p`
; wire: `qram_load_unc` against the unchanged array and `p`, then `cqrt_free` of
; the load rail (a basis permutation of live parents — clean), and `p`'s own Ry
; reverse-played and left allocated (frozen: recorded through the copy-out). The
; store is NOT reversed: the array keeps its cells — the owner-ruled-deferred
; array-record class (2026-08-27 point 4), exactly what `main` already does —
; and `b`, the user's measured register, is never touched by the spine.
;
; The decline twin (the retry must still refuse):
; lowering_reject_qram_store_measured_index_load_idx_measured.ll — the LOAD's own
; index is measured, so the reduced DAG is measured too. A store on the array
; between the load and the reversal would also refuse the retry (the clause-(d)
; scan), but no C program reaches that today: the 7.5 lowering declines any store
; after a load of the same array ("cq QRAM store: array is observed before its
; last store"), so the scan is defence in depth and has no fixture.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEB < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYPLUS < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=RYMINUS < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)

define i32 @shadow(i1 %u0, i1 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %zb = zext i1 %b to i64
  %gb = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zb
  store i32 0, ptr %gb, align 4                   ; arr[b] = 0 — never reversed
  %p = call i1 @cq_theta_i1(i1 %u1, double 5.000000e-01)
  %zp = zext i1 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %zp
  %v = load i32, ptr %gp, align 4                 ; v = arr[p]
  %b2 = call i1 @cq_theta_i1(i1 %b, double -5.000000e-01)
  %mb = call i1 @cq_measure_i1(i1 %b2)
  %mv = call i32 @cq_measure_si32(i32 %v)
  %zmb = zext i1 %mb to i32
  %r = add i32 %mv, %zmb
  ret i32 %r
}

; CHECK-LABEL: define i32 @shadow(
; CHECK:      %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; CHECK:      %[[B:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; CHECK:      call void @cqrt_qram_store_i32(i32 %[[ARR]],
; CHECK:      %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u1)
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_i32(i32 %[[ARR]],
; CHECK:      call void @cqrt_ry_i1(i32 %[[B]], double -5.000000e-01)
; CHECK:      call i1 @cqrt_measure_i1(i32 %[[B]])
; CHECK:      %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32(i32 %[[V]], i32 %[[OUT]])
; The reduced reversal: the load against the unchanged array, its rail freed,
; then the load index's own Ry reverse-played (the index is left allocated):
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[P]])
; CHECK-NEXT: call void @cqrt_qram_load_i32_unc(i32 %[[V]], i32 %[[ARR]], i32 %[[T]])
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[T]], i32 %[[P]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[V]])
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[P]], double -5.000000e-01)
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[OUT]])
; The store is never reversed and the array never freed:
; CHECK-NOT:  cqrt_qram_store_i32_unc
; CHECK-NOT:  call void @cqrt_free(i32 %[[ARR]])
; CHECK:      ret i32
; The user's measured register is never freed by the spine:
; NOFREEB-LABEL: define i32 @shadow(
; NOFREEB:      %[[B2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 %u0)
; NOFREEB-NOT:  call void @cqrt_free(i32 %[[B2]])
; ...nor adjointed: exactly the two forward Ry(+0.5) (b, p) and two Ry(-0.5) (the
; user's on b, the spine's on p). A walk into `b`'s history would add one of each.
; RYPLUS-COUNT-2: call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; RYPLUS-NOT:     call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 5.000000e-01)
; RYMINUS-COUNT-2: call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double -5.000000e-01)
; RYMINUS-NOT:     call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double -5.000000e-01)
