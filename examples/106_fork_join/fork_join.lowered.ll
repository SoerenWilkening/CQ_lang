; HAND-WRITTEN. Rules: 24, 18, 20, 7, 5, 2, §1.4.
; Checked: s = a.out + b.out (measured, the result rail %16 -> %17).
; Clean: the a.out rail (%14, the handle the worker clone stored into the slot; zeroed by the __cq_q_worker_11_unc twin
; and freed by the caller), the a.out seed rail (%11, the classical initializer 0 as a handle, restored into the slot by
; the twin and freed, rule 7) and the clone's product rail (%3 of the clone and %6 of the twin), uncomputed and freed.
; Kept: x (%9, the rotated user register, held in the a.in slot).
; Rotations: (Ry, x, th, 1).
; SINGLE-THREAD COLLAPSE (Bennett.jl's stance; owner 2026-10-20): a reversible
; program is a function of its inputs, so a thread interleaving that could change the result has nothing to uncompute;
; data-race-free fork/join code gives the same result under every schedule, and the SEQUENTIAL schedule is taken.
; pthread_create(&t, attr, f, arg) becomes a call of f at the create site: f's quantum clone when arg carries quantum data
; (job a: its cell in holds the handle of x), the classical original when it does not (job b). No host thread is started,
; the host pthread_create is not executed, and the pthread_t slots are classical allocas nothing writes or reads.
; pthread_join is nothing: the result already stands in the job struct, a slot of handles (31). Mutex init stays the
; classical memset/store; lock/unlock are no-ops (94's rule: no contention exists on one thread). The clone of worker takes
; the job pointer as a CLASSICAL pointer (31's shape, not 85's (ptr, tag, idx) triple): the pointer value is classical, only
; the cells behind it are quantum, and the callee dereferences it only classically (loads a handle, stores a handle). A
; pointer-to-slot parameter contributes one mask digit per field it carries, 1 iff the cell holds a handle AT THE CALL
; (§1.4): a.in holds x's handle, and a.out holds a handle too, because a slot cell is homogeneous (rule 20): the worker
; stores a handle into it, so the caller's classical a.out = 0 is materialised as the seed rail alloc_i32(0). Hence
; __cq_q_worker_11. The clone's _unc twin takes (args, old slot handles): it zeroes the a.out rail by recomputation and
; restores a.out's handle from before the call (the seed); the caller loads the clone's a.out handle before the twin and
; frees it after, then frees the seed. Job b's cells never hold a handle and stay classical.
; OUT OF SCOPE: condition variables, barriers and busy-waits on another thread's progress need a scheduler and deadlock
; under the sequential schedule. Multi-QPU placement is a backend matter over the handle graph (gates on disjoint rails
; commute); the lowered IR does not change with the number of devices.
source_filename = "fork_join.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.job = type { i32, i32 }    ; IR: %struct.job  (a: cells hold handles; b: classical)
%struct._opaque_pthread_mutex_t = type { i64, [56 x i8] }    ; IR: %struct._opaque_pthread_mutex_t  (classical, never locked)

define i32 @fork_join(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = alloca %struct.job, align 4    ; IR: %4 = alloca %struct.job  (job a: a slot of handles)
  %5 = alloca %struct.job, align 4    ; IR: %5 = alloca %struct.job  (job b: classical)
  %6 = alloca ptr, align 8    ; IR: %6 = alloca ptr  (ta: never written, no host thread)
  %7 = alloca ptr, align 8    ; IR: %7 = alloca ptr  (tb: never written, no host thread)
  %8 = alloca %struct._opaque_pthread_mutex_t, align 8    ; IR: %8 = alloca pthread_mutex_t  (classical)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  store i32 %9, ptr %4, align 4    ; IR: store i32 %9, ptr %4  (a.in holds the handle of x)
  %10 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: %10 = getelementptr i8, ptr %4, i64 4  (&a.out)
  %11 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: store i32 0, ptr %10  (a.out = 0: the cell holds a handle on another path, so the classical 0 is a seed rail, rule 20 / rule 7)
  store i32 %11, ptr %10, align 4    ; IR: store i32 0, ptr %10  (a.out holds the seed's handle)
  store i32 %2, ptr %5, align 4    ; IR: store i32 %2, ptr %5  (classical: b.in)
  %12 = getelementptr inbounds i8, ptr %5, i64 4    ; IR: %11 = getelementptr i8, ptr %5, i64 4  (&b.out)
  store i32 0, ptr %12, align 4    ; IR: store i32 0, ptr %11  (classical: b.out)
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(64) %8, i8 0, i64 64, i1 false)    ; IR: memset %8  (classical: mutex init)
  store i64 850045863, ptr %8, align 8    ; IR: store i64 850045863, ptr %8  (classical: mutex signature)
  call fastcc void @__cq_q_worker_11(ptr %4)    ; IR: %12 = pthread_create(%6, null, @worker, %4): the sequential schedule runs worker's clone here (mask 11: both job cells hold handles at the call); no host call
  %13 = call ptr @worker(ptr %5)    ; IR: %13 = pthread_create(%7, null, @worker, %5): classical job, the original runs here; no host call
  ; IR: %14 = load %6; %15 = pthread_join(%14, null); %16 = load %7; %17 = pthread_join(%16, null): nothing (the results stand in a, b)
  ; IR: %18 = pthread_mutex_lock(%8): no-op (one thread)
  %14 = load i32, ptr %10, align 4    ; IR: %19 = load i32, ptr %10  (the handle the clone stored into a.out)
  %15 = load i32, ptr %12, align 4    ; IR: %20 = load i32, ptr %11  (classical: b.out)
  %16 = call i32 @cq_template_add_i32_hl(i32 %14, i32 %15)    ; IR: %21 = add nsw i32 %20, %19  (commutative: the classical operand moved to the _hl slot)  [result rail]
  ; IR: %22 = pthread_mutex_unlock(%8): no-op
  call fastcc void @__cq_q_worker_11_unc(ptr %4, i32 %11)    ; IR: uncompute the stored a.out (adjoint of the create-site call); the last argument is a.out's handle before the call, the seed rail
  call void @cqrt_free(i32 %14)    ; IR: release the a.out rail the clone stored (|0>)
  call void @cqrt_free(i32 %11)    ; IR: release the a.out seed rail (back in the slot, never written: |0>, rule 7)
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %23 = cq_measure_si32(%21)
  ret i32 %17    ; IR: ret i32 %23
}

define internal fastcc void @__cq_q_worker_11(ptr %0) {
  %2 = load i32, ptr %0, align 4    ; IR: %2 = load i32, ptr %0  (the handle in j->in)
  %3 = call i32 @cq_template_mul_i32(i32 %2, i32 %2)    ; IR: %3 = mul nsw i32 %2, %2
  %4 = call i32 @cq_template_add_i32_hl(i32 %3, i32 1)    ; IR: %4 = add nuw nsw i32 %3, 1  [the out cell's rail]
  %5 = getelementptr inbounds i8, ptr %0, i64 4    ; IR: %5 = getelementptr i8, ptr %0, i64 4  (&j->out)
  store i32 %4, ptr %5, align 4    ; IR: store i32 %4, ptr %5  (store the handle; the displaced seed handle is the twin's last argument)
  call void @cq_template_mul_i32_unc(i32 %3, i32 %2, i32 %2)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret void    ; IR: ret ptr null  (classical, unused by the create site)
}

define internal fastcc void @__cq_q_worker_11_unc(ptr %0, i32 %1) {
  %3 = load i32, ptr %0, align 4    ; IR: the handle in j->in
  %4 = getelementptr inbounds i8, ptr %0, i64 4    ; IR: &j->out
  %5 = load i32, ptr %4, align 4    ; IR: the handle the clone stored into j->out
  %6 = call i32 @cq_template_mul_i32(i32 %3, i32 %3)    ; IR: recompute %3
  call void @cq_template_add_i32_hl_unc(i32 %5, i32 %6, i32 1)    ; IR: uncompute %4 (j->out) in place; the caller frees it
  call void @cq_template_mul_i32_unc(i32 %6, i32 %3, i32 %3)    ; IR: uncompute %3
  call void @cqrt_free(i32 %6)    ; IR: release the %3 rail (|0>)
  store i32 %1, ptr %4, align 4    ; IR: restore j->out's handle from before the call, the caller's seed rail (§1.4: old slot handles last)
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(argmem: readwrite) uwtable
define internal noalias noundef ptr @worker(ptr nocapture noundef %0) {
  %2 = load i32, ptr %0, align 4    ; IR: %2 = load i32, ptr %0  (classical original, runs for job b)
  %3 = mul nsw i32 %2, %2    ; IR: %3 = mul nsw i32 %2, %2
  %4 = add nuw nsw i32 %3, 1    ; IR: %4 = add nuw nsw i32 %3, 1
  %5 = getelementptr inbounds i8, ptr %0, i64 4    ; IR: %5
  store i32 %4, ptr %5, align 4    ; IR: store i32 %4, ptr %5
  ret ptr null    ; IR: ret ptr null
}

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
