; HAND-WRITTEN. Rules: 24, 20, 16, 18, 5, 6, 7, 3, 4, 2, §1.4.
; Checked: s = a.out + b.out (the add rail, measured) = (x * x + 1) + (c * c + 1). The cells at exit: a.in = x,
; a.out = x * x + 1, b.in = c, b.out = c * c + 1 (bus cells of the two __cq_alloc blocks; not named outputs).
; Clean: per activation of worker (two: job a, job b): the load copy of j->in (un-copied right after its last reader,
; the product, before the activation's store, the next memory version change, rule 5 sentence 1). fork_join: the load copies of a.out and b.out,
; un-copied right after the add, before the measurement (nothing changes memory after the loads, rule 5 sentence 1).
; Kept: x (the rotated user register; also the value rail of the a.in store); the sum (measured); and by rule 5 the
; tape slots of the six bus stores (a.in, a.out, b.in, b.out in fork_join; j->out in each worker activation) with
; their value rails: the seeds alloc_i32(0) (a.out), alloc_i32(c) (b.in), alloc_i32(0) (b.out) and, per activation,
; the product rail j->in * j->in, updated in place into j->in * j->in + 1, that worker stores into j->out.
; Rotations: (Ry, x, th, 1).
; SINGLE-THREAD COLLAPSE (rule 24; Bennett.jl's stance, owner 2026-10-20): a reversible program is a function of its
; inputs, so a thread interleaving that could change the result has nothing to uncompute; data-race-free fork/join
; code gives the same result under every schedule, and the SEQUENTIAL schedule is taken. pthread_create(&t, attr, f,
; arg) is a direct call of the start routine f(arg) at the create site; no host thread is started, the host
; pthread_create is not executed and the pthread_t is never written. pthread_join is nothing (the start routine has
; already returned). Mutex lock/unlock are no-ops (rule 24).
; ONE BUS (rules 20, 3). The job structs a and b are passed to a callee (the start routine), a user rule 20 (b) does
; not allow, so both are BUS-RESIDENT: __cq_alloc(8, 4) each at the alloca's program point, no alloca remains and
; their lifetime markers are dropped (rule 16). Every store into them is a kept bus store at a classical address (the
; gep has no tainted operand and stays), its classical value first a seed (rule 7); a.in's value is x's handle. Every
; load is a bus load and a rail (rule 3): job b's cells hold classical values, and its worker activation computes on
; rails all the same (over-taint, §0: a rail in a basis state costs no qubit). The pthread_t slots ta, tb and the mutex
; m are HOST-RESIDENT (rule 20 (b)): once the create, join, lock and unlock calls are rule 24's direct call and
; no-ops, their users are lifetime markers, the mutex initializer's memset of the untainted byte 0 and its classical
; signature store; they stay the plain instructions with their lifetime markers (rule 22: a host-resident destination
; keeps the intrinsic).
; A POINTER IS ONE SCALAR (§1.4, rules 18, 21). worker(&a) and worker(&b) both pass a classical ptr (the address of a
; __cq_alloc block): mask digit 0, so both calls reach worker's OWN symbol with its C parameter list, lowered (its body
; makes bus accesses). Nothing about the pointee (which cells hold rails) crosses the call. worker stores into j->out,
; so it WRITES MEMORY: it has no twin (rule 18) and the store's tape slot and value rail stay (rule 5). The `+ 1` is a
; plain add of a dead value, the product (rule-5 garbage, a template result): rule 6's in-place update (owner ruling
; 2026-11-26: it applies though the operand is garbage) makes it ONE core gate addc_i32(product, 1) on the product's
; rail, the stored value from there on; the mul's _unc is never called. The load copy of j->in is un-copied inside the
; activation after the product, its last reader, before that store. In fork_join the loads of a.out and b.out follow the
; last memory version change (the second worker call), so both copies are un-copied after the add.
; SPEC GAP (rule 24, join): rule 24 names pthread_create and mutexes, not pthread_join. Taken (proposed sentence):
; pthread_create is a direct call of the start routine that writes no pthread_t, and pthread_join is nothing (its retval
; out-parameter is not written). The classical loads of ta and tb that only feed the joins are dead and dropped (they
; would read a never-written host slot).
; SPEC GAP (rule 24 against rule 20 (b)): whether the users of an alloca are counted before or after rule 24 rewrites the
; pthread and mutex calls. Taken (proposed sentence): the pthread_t operand of pthread_create and pthread_join and the
; mutex operand of a lock, unlock or trylock are not users for rule 20 (b); the residency test is asked after these
; calls are rewritten. So ta, tb and m stay host-resident. Counting the calls would make all three bus-resident (the
; memset a rolled loop of 64 kept byte stores, the signature a kept i64 store); no gate on a rail of the program changes.
; SPEC GAP (rule 24 against rule 19, address-taken): worker's address is used only as pthread_create's start routine.
; Taken (proposed sentence): a function whose address is used only as the start routine of a pthread_create with a
; constant callee is not address-taken by that use, so worker has no clone-table row and no _t clone.
; OUT OF SCOPE: condition variables, barriers and busy-waits on another thread's progress need a scheduler and deadlock
; under the sequential schedule. Multi-QPU placement is a backend matter over the handle graph (gates on disjoint rails
; commute); the lowered IR does not change with the number of devices.
source_filename = "fork_join.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct._opaque_pthread_mutex_t = type { i64, [56 x i8] }    ; IR: %struct._opaque_pthread_mutex_t  (classical, never locked)

define i32 @fork_join(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = call ptr @__cq_alloc(i64 8, i64 4)    ; IR: %4 = alloca %struct.job, align 4  (job a: bus-resident, rule 20; one zeroed block, rule 16)
  %6 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address (&a.in)
  %7 = call ptr @__cq_alloc(i64 8, i64 4)    ; IR: %5 = alloca %struct.job, align 4  (job b: bus-resident, rule 20)
  %8 = ptrtoint ptr %7 to i64    ; IR: %5 as its run-time address (&b.in)
  %9 = alloca ptr, align 8    ; IR: %6 = alloca ptr  (ta: host-resident, never written: no host thread)
  %10 = alloca ptr, align 8    ; IR: %7 = alloca ptr  (tb: host-resident, never written: no host thread)
  %11 = alloca %struct._opaque_pthread_mutex_t, align 8    ; IR: %8 = alloca pthread_mutex_t  (host-resident)
  %12 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %12, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %6, i32 %12)    ; IR: store i32 %9, ptr %4  (a.in = x; kept store, its value rail the user register; llvm.lifetime.start dropped)
  %13 = getelementptr inbounds i8, ptr %5, i64 4    ; IR: %10 = getelementptr inbounds i8, ptr %4, i64 4  (&a.out; nothing tainted: the gep stays)
  %14 = ptrtoint ptr %13 to i64    ; IR: %10 as its run-time address
  %15 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: store i32 0, ptr %10: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %14, i32 %15)    ; IR: store i32 0, ptr %10  (a.out = 0; kept store)
  %16 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %5: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %8, i32 %16)    ; IR: store i32 %2, ptr %5  (b.in = c; kept store; llvm.lifetime.start dropped)
  %17 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %11 = getelementptr inbounds i8, ptr %5, i64 4  (&b.out; the gep stays)
  %18 = ptrtoint ptr %17 to i64    ; IR: %11 as its run-time address
  %19 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: store i32 0, ptr %11: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %18, i32 %19)    ; IR: store i32 0, ptr %11  (b.out = 0; kept store)
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %9)    ; IR: call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6)  [kept: host-resident]
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %10)    ; IR: call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %7)  [kept: host-resident]
  call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %11)    ; IR: call void @llvm.lifetime.start.p0(i64 64, ptr nonnull %8)  [kept: host-resident]
  call void @llvm.memset.p0.i64(ptr noundef nonnull align 8 dereferenceable(64) %11, i8 0, i64 64, i1 false)    ; IR: memset %8  (host-resident destination: the intrinsic stays, rule 22)
  store i64 850045863, ptr %11, align 8    ; IR: store i64 850045863, ptr %8  (host-resident: the plain store, mutex signature)
  %20 = call ptr @worker(ptr noundef %5)    ; IR: %12 = pthread_create(%6, null, @worker, %4): the start routine called here (rule 24); &a is a classical ptr, mask 0: worker's own symbol; no host call
  %21 = call ptr @worker(ptr noundef %7)    ; IR: %13 = pthread_create(%7, null, @worker, %5): the same, for job b; no host call
  ; IR: %14 = load %6; %15 = pthread_join(%14, null); %16 = load %7; %17 = pthread_join(%16, null): nothing (the start routines already ran)
  ; IR: %18 = pthread_mutex_lock(%8): no-op (one thread)
  %22 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %14)    ; IR: %19 = load i32, ptr %10  [a.out: a bus load, a rail]
  %23 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %18)    ; IR: %20 = load i32, ptr %11  [b.out: a bus load, a rail (rule 3)]
  %24 = call i32 @cq_template_add_i32(i32 %23, i32 %22)    ; IR: %21 = add nsw i32 %20, %19  [result rail]
  ; IR: %22 = pthread_mutex_unlock(%8): no-op
  call void @cqrt_qram_load_i32_hl_unc(i32 %23, i32 %4, i64 %18)    ; IR: un-copy %20 (its consumer %21 is done; no memory version change since the load, rule 5)
  call void @cqrt_qram_load_i32_hl_unc(i32 %22, i32 %4, i64 %14)    ; IR: un-copy %19
  call void @cqrt_free(i32 %23)    ; IR: release the %20 rail (|0>)
  call void @cqrt_free(i32 %22)    ; IR: release the %19 rail (|0>)
  %25 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %23 = cq_measure_si32(%21)  [the sum rail stays allocated]
  call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %11)    ; IR: call void @llvm.lifetime.end.p0(i64 64, ptr nonnull %8)  [kept: host-resident]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %10)    ; IR: call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %7)  [kept: host-resident]
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %9)    ; IR: call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6)  [kept: host-resident]
  ret i32 %25    ; IR: ret i32 %23  (the lifetime.end of %5 and %4 dropped: bus-resident)
}

define internal noalias noundef ptr @worker(ptr noundef %0) {    ; IR: define internal noalias noundef ptr @worker(ptr nocapture noundef %0)  (nocapture dropped: the ptrtoint captures %0)
  %2 = call i32 @__cq_mem()    ; IR: the bus M
  %3 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (mask digit 0: the formal is the C ptr)
  %4 = call i32 @cqrt_qram_load_i32_hl(i32 %2, i64 %3)    ; IR: %2 = load i32, ptr %0  [j->in: a bus load, a rail]
  %5 = call i32 @cq_template_mul_i32(i32 %4, i32 %4)    ; IR: %3 = mul nsw i32 %2, %2
  call void @cqrt_qram_load_i32_hl_unc(i32 %4, i32 %2, i64 %3)    ; IR: un-copy %2 (its last reader, the mul %3, is done; the store below is the next memory version change)
  call void @cqrt_free(i32 %4)    ; IR: release the %2 rail (|0>)
  call void @cqrt_addc_i32(i32 %5, i32 1)    ; IR: %4 = add nuw nsw i32 %3, 1  [rule 6, in-place update (owner ruling 2026-11-26: it applies to the mul result, rule-5 garbage): %3 is dead after the add, so the result IS the %3 rail: %3 += 1; the stored value rail]
  %6 = getelementptr inbounds i8, ptr %0, i64 4    ; IR: %5 = getelementptr inbounds i8, ptr %0, i64 4  (&j->out; the gep stays)
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 %7, i32 %5)    ; IR: store i32 %4, ptr %5  [kept store: no _unc; worker writes memory, so it has no twin]
  ret ptr null    ; IR: ret ptr null  (classical, unused by the create site)
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cqrt_addc_i32(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
