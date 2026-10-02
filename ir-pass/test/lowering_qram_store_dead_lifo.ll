; lowering_qram_store_dead_lifo.ll — ACCEPT (Phase 7.5 Inc 2): a DEAD scratch
; alloca-backed array mutated by two tainted-index stores and never observed (no
; load, no escape, no measure). The array handle is a tainted in-place-mutated
; register whose stores REVERSE IN STRICT LIFO at scope exit (§2.7): the
; `cqrt_qram_store_i32_unc` twins fire in EXACT reverse program order of the forward
; stores (so the backend's per-store tape stack pops in push order, §2.8(ii)), then
; the index/value rotation rails are reverse-played and KEPT: Ry-dagger restores
; their runtime seeds, not |0> (bd 5c5b, libcqops vmz9). The array handle
; itself is a CLASSICAL resource token — NEVER freed (§2.9). NO measurement (Rule 5).
; (A fully-dead alloca would be DCE'd by clang -O1; this hand-written fixture pins
; the spine's reversal, exactly as lowering_qram_read_dead_uncompute.ll does.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOFREEANY < %t.cqd0.ll
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)

define void @shadow_dead(i32 %u0, i32 %u1, i32 %ux) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %u1, double 5.000000e-01)
  %x = call i32 @cq_theta_si32(i32 %ux, double 5.000000e-01)
  %iq = sext i32 %q to i64
  %gq = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %iq
  store i32 %x, ptr %gq, align 4               ; arr[q] = x  (tainted value)  — S1
  %ip = sext i32 %p to i64
  %gp = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %ip
  store i32 42, ptr %gp, align 4               ; arr[p] = 42 (classical value) — S2
  ret void
}

; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_i32(i32 8)
; Forward stores, in program order (S1 at index %[[IQ]], then S2 at index %[[IP]]):
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[IQ:[a-zA-Z0-9_.]+]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_qram_store_i32(i32 %[[ARR]], i32 %[[IP:[a-zA-Z0-9_.]+]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: call void @cqrt_free
; Reversal fires the `_unc` twins in STRICT LIFO — S2 (index %[[IP]]) BEFORE S1
; (index %[[IQ]]):
; CHECK:     call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[IP]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NEXT: call void @cqrt_qram_store_i32_unc(i32 %[[ARR]], i32 %[[IQ]], i32 %{{[a-zA-Z0-9_.]+}})
; The index/value rotation rails are reverse-played and kept (runtime seeds); the
; ARRAY handle is never freed (a classical resource, §2.9). Nothing in this module
; is provably |0>, so there is no free at all. The unanchored NOFREEANY prefix
; below pins that over the whole output; the main prefix also orders it — a
; CHECK-NOT from the second forward store to the first `_unc`, and CHECK-NEXT
; sealing the reversal from that `_unc` to `ret` (value rail %x, then index %p,
; then index %q).
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %{{[a-zA-Z0-9_.]+}}, double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[IP]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[IQ]], double -5.000000e-01)
; CHECK-NEXT: ret void
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_measure
; CHECK-NOT: cq taint escape

; bd 5c5b review r3: whole-input negative (unanchored on purpose — the window is the
; entire lowered module, before and after every forward store).
; NOFREEANY-NOT: call void @cqrt_free
