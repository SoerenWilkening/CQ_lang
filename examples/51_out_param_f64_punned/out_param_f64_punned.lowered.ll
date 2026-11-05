; HAND-WRITTEN. Rules: 18, 20, 21, 5, 8, 9, 3, 16; §1.3, §1.4.
; Checked: f = split(x, &ip, k, mask) (the clone's copied-out return rail, measured) and ip (the bus load copy of the
; 8 cells at &ip after the call, measured).
; Clean: every clone-internal SSA rail that no kept store holds: the bit view chain bits, bits >> 52, its trunc, e;
; the arm-2 predicate e > k+51; the hoisted arm rails x - x, e - k, its zext, mask >> (e - k), its complement, the
; bit view i of t, x - i; both rails of the return select ladder. Each is uncomputed by its _unc and freed.
; Kept: x (the rotated register, a source of both results and the value rail of arm 2's store); f (the clone's result
; rail, measured; the clone writes memory, so it has no twin) and the load copy of ip (measured, rule 2). By rule 5
; sentence 3, the three kept stores to ip in split: each one's tape slot, its value rail (z = bits & mask for arm 1,
; x for arm 2, t = bits & ~(mask >> (e - k)) for arm 3) and its control rail (the arm-1 flag e < k, the arm-2
; conjunction !(e < k) & (e > k+51), the arm-3 conjunction !(e < k) & !(e > k+51)).
; Rotations: (Ry_f64, x, th, 1).
; THE OUT-PARAMETER IS BUS MEMORY (rules 20, 21, 18). `double ip` is an alloca passed to a callee, a user that is
; not on rule 20 (b)'s list, so it is bus-resident: __cq_alloc(8, 8) at the alloca's program point, no alloca remains
; and the lifetime markers are dropped. Its address is a classical ptr, so split's clone keeps the pointer formal as
; the C ptr (mask digit 0: __cq_q_split_1000, nothing about the pointee crosses the call) and every access through it
; is an _hl bus access at its run-time i64 (ptrtoint once at entry, after __cq_mem()).
; Each of the three stores is a bus store in its own arm: the arms are quantum (e is computed from x), so each store
; is cqrt_qram_store_<W>_hl_controlled under its arm's predicate (rules 5, 9: a bus access is never hoisted). The
; type-punned `store i64` arms are i64 accesses of the same 8 cells (rule 20: a union view needs no rule), the
; `store double` arm an f64 access; arm 2's and arm 3's predicates are conjunction flags (rule 8: and_i1 into a fresh
; |0>, the false edges X-bracketed), because a store takes ONE control rail. The three stores are exclusive, so the
; 8 cells end up holding the one arm's value. Every store is KEPT (rule 5): no _unc, its tape slot, value rail and
; control rail stay; so split writes memory and has no twin (rule 18), and its result rail is kept by the caller and
; measured. The pure arm code is hoisted as before and the return value is the select ladder over the arm rails
; (a2 inside, where !a1 holds), copied into a fresh rail (rule 18) and uncomputed with every other garbage rail.
; The caller reads ip back with cqrt_qram_load_f64_hl at the block's address after the call (a memory version
; change), and measures that copy.
; SPEC GAP: rule 9 says a conjunction flag is needed only where a phase or in-place gate sits in the inner arm; a bus
; access in a nested quantum arm (here the stores of arms 2 and 3) needs one too, since a _controlled access takes ONE
; control rail and rule 5 keeps it. Chosen: and_i1 into a fresh |0> with the false edges X-bracketed (rule 8), the
; arm-3 conjunction over both negated flags in one double bracket; the conjunctions are kept, their operand a2 is not
; a store control and is uncomputed as usual.
source_filename = "out_param_f64_punned.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define double @out_param_f64_punned(double noundef %0, double noundef %1, i32 noundef %2, i64 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle, once at function entry
  %6 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %5 = alloca double, align 8  [bus-resident: passed to a callee, rule 20; one zeroed block, rule 16]
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address
  %8 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %6 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %8, double %1)    ; IR: %6 = cq_theta_f64(%0, %1)  [Ry]; llvm.lifetime.start dropped
  %9 = call fastcc i32 @__cq_q_split_1000(i32 %8, ptr %6, i32 %2, i64 %3)    ; IR: %7 = call @split(%6, %5, %2, %3), clone of mask 1000 (quantum, classical ptr, classical, classical); it stores, so no twin
  %10 = call double @cqrt_measure_f64(i32 %9)    ; IR: %8 = cq_measure_f64(%7)
  %11 = call i32 @cqrt_qram_load_f64_hl(i32 %5, i64 %7)    ; IR: %9 = load double, ptr %5  [a bus load: the cells split stored]
  %12 = call double @cqrt_measure_f64(i32 %11)    ; IR: %10 = cq_measure_f64(%9)  [the load copy is the measured rail, rule 2]
  %13 = fadd double %10, %12    ; IR: %11 = fadd double %8, %10  (classical)
  ret double %13    ; IR: ret double %11  (llvm.lifetime.end dropped)
}

define internal fastcc i32 @__cq_q_split_1000(i32 %0, ptr %1, i32 %2, i64 %3) {
  %5 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle
  %6 = ptrtoint ptr %1 to i64    ; IR: %1 as its run-time address (mask digit 0: the formal is the C ptr)
  %7 = call i32 @cq_template_bitcast_f64_to_i64(i32 %0)    ; IR: %5 = bitcast double %0 to i64
  %8 = call i32 @cq_template_lshr_i64_hl(i32 %7, i64 52)    ; IR: %6 = lshr i64 %5, 52
  %9 = call i32 @cq_template_trunc_i64_to_i32(i32 %8)    ; IR: %7 = trunc nuw nsw i64 %6 to i32
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 2047)    ; IR: %8 = and i32 %7, 2047
  %11 = call i32 @cq_template_icmp_slt_i32_hl(i32 %10, i32 %2)    ; IR: %9 = icmp slt i32 %8, %2  [predicate a1 of arm 1, block %10; control of a kept store]
  %12 = call i32 @cq_template_and_i64_hl(i32 %7, i64 %3)    ; IR: %11 = and i64 %5, %3  (arm 1, hoisted: pure)
  call void @cqrt_qram_store_i64_hl_controlled(i32 %11, i32 %5, i64 %6, i32 %12)    ; IR: store i64 %11, ptr %1  [arm 1 under a1, the punned i64 access; kept store: slot, value rail and a1 stay]
  %13 = add nsw i32 %2, 51    ; IR: %13 = add nsw i32 %2, 51  (classical)
  %14 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %10, i32 %13)    ; IR: %14 = icmp sgt i32 %8, %13  [predicate a2, block %15 inside !a1]
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: br i1 %14 inside block %12: the arm-2 conjunction !a1 & a2 (fresh |0>)
  call void @cqrt_not_i1(i32 %11)    ; IR: bracket: block %12 runs under NOT %9
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %15)    ; IR: arm 2 predicate = !%9 & %14
  call void @cqrt_not_i1(i32 %11)    ; IR: bracket closed
  call void @cqrt_qram_store_f64_hl_controlled(i32 %15, i32 %5, i64 %6, i32 %0)    ; IR: store double %0, ptr %1  [arm 2 under !a1 & a2; kept store: slot, value rail x and the conjunction stay]
  %16 = call i32 @cq_template_fsub_f64(i32 %0, i32 %0)    ; IR: %16 = fsub double %0, %0  (arm 2, hoisted; the same operand twice)
  %17 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: br i1 %14 false edge: the arm-3 conjunction !a1 & !a2 (fresh |0>)
  call void @cqrt_not_i1(i32 %11)    ; IR: bracket: block %12 runs under NOT %9
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket: block %17 runs under NOT %14
  call void @cqrt_and_i1(i32 %11, i32 %14, i32 %17)    ; IR: arm 3 predicate = !%9 & !%14
  call void @cqrt_not_i1(i32 %14)    ; IR: bracket closed
  call void @cqrt_not_i1(i32 %11)    ; IR: bracket closed
  %18 = call i32 @cq_template_sub_i32_hl(i32 %10, i32 %2)    ; IR: %18 = sub nsw i32 %8, %2  (arm 3, hoisted)
  %19 = call i32 @cq_template_zext_i32_to_i64(i32 %18)    ; IR: %19 = zext nneg i32 %18 to i64
  %20 = call i32 @cq_template_ashr_i64_lh(i64 %3, i32 %19)    ; IR: %20 = ashr i64 %3, %19  (classical value, quantum shift amount)
  %21 = call i32 @cq_template_xor_i64_hl(i32 %20, i64 -1)    ; IR: %21 = xor i64 %20, -1
  %22 = call i32 @cq_template_and_i64(i32 %21, i32 %7)    ; IR: %22 = and i64 %21, %5
  %23 = call i32 @cq_template_bitcast_i64_to_f64(i32 %22)    ; IR: %23 = bitcast i64 %22 to double
  call void @cqrt_qram_store_i64_hl_controlled(i32 %17, i32 %5, i64 %6, i32 %22)    ; IR: store i64 %22, ptr %1  [arm 3 under !a1 & !a2, the punned i64 access; kept store: slot, value rail t and the conjunction stay]
  %24 = call i32 @cq_template_fsub_f64(i32 %0, i32 %23)    ; IR: %24 = fsub double %0, %23
  %25 = call i32 @cq_template_select_f64(i32 %14, i32 %16, i32 %24)    ; IR: %26 = phi: (%14) ? %16 : %24  (inner merge)
  %26 = call i32 @cq_template_select_f64(i32 %11, i32 %0, i32 %25)    ; IR: %26 = phi: (%9) ? %0 : inner  (the return merge)
  %27 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: ret double %26  [result rail of the call, rule 18]
  call void @cqrt_copy_f64(i32 %26, i32 %27)    ; IR: copy the return value out
  call void @cq_template_select_f64_unc(i32 %26, i32 %11, i32 %0, i32 %25)    ; IR: uncompute the return merge
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cq_template_select_f64_unc(i32 %25, i32 %14, i32 %16, i32 %24)    ; IR: uncompute the inner return merge
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_fsub_f64_unc(i32 %24, i32 %0, i32 %23)    ; IR: uncompute %24
  call void @cqrt_free(i32 %24)    ; IR: release the %24 rail (|0>)
  call void @cq_template_bitcast_i64_to_f64_unc(i32 %23, i32 %22)    ; IR: uncompute %23 (t itself is the value rail of a kept store and stays)
  call void @cqrt_free(i32 %23)    ; IR: release the %23 rail (|0>)
  call void @cq_template_xor_i64_hl_unc(i32 %21, i32 %20, i64 -1)    ; IR: uncompute %21 (its consumer %22 is kept, with no _unc to wait for)
  call void @cqrt_free(i32 %21)    ; IR: release the %21 rail (|0>)
  call void @cq_template_ashr_i64_lh_unc(i32 %20, i64 %3, i32 %19)    ; IR: uncompute %20
  call void @cqrt_free(i32 %20)    ; IR: release the %20 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %19, i32 %18)    ; IR: uncompute %19
  call void @cqrt_free(i32 %19)    ; IR: release the %19 rail (|0>)
  call void @cq_template_sub_i32_hl_unc(i32 %18, i32 %10, i32 %2)    ; IR: uncompute %18
  call void @cqrt_free(i32 %18)    ; IR: release the %18 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %16, i32 %0, i32 %0)    ; IR: uncompute %16
  call void @cqrt_free(i32 %16)    ; IR: release the %16 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %14, i32 %10, i32 %13)    ; IR: uncompute %14 (the two conjunctions computed from it are store controls and stay)
  call void @cqrt_free(i32 %14)    ; IR: release the %14 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 2047)    ; IR: uncompute %8 (a1 = %9 is a store control and stays)
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %9, i32 %8)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %8, i32 %7, i64 52)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %7, i32 %0)    ; IR: uncompute %5 (z and t, computed from it, are kept store values)
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  ret i32 %27    ; IR: ret double %26
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_copy_f64(i32, i32)
declare void @cqrt_ry_f64(i32, double)
declare double @cqrt_measure_f64(i32)
declare void @cqrt_free(i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cqrt_qram_load_f64_hl(i32, i64)
declare void @cqrt_qram_store_i64_hl_controlled(i32, i32, i64, i32)
declare void @cqrt_qram_store_f64_hl_controlled(i32, i32, i64, i32)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
declare i32 @cq_template_bitcast_i64_to_f64(i32)
declare void @cq_template_bitcast_i64_to_f64_unc(i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i64_hl(i32, i64)
declare i32 @cq_template_and_i64(i32, i32)
declare i32 @cq_template_fsub_f64(i32, i32)
declare void @cq_template_fsub_f64_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_ashr_i64_lh(i64, i32)
declare void @cq_template_ashr_i64_lh_unc(i32, i64, i32)
declare i32 @cq_template_xor_i64_hl(i32, i64)
declare void @cq_template_xor_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
