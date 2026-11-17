; HAND-WRITTEN. Rules: 2, 3, 5, 7, 8, 9, 10, 11, 14, 15, 16, 20, 21, 22; §1.3 (the bus, qram_swap).
; Checked: controlled_ry_chain: q[0] + q[n-1] (the two load copies of the cells q + 0 and q + n - 1, measured); the n
; cells q + i of the bus block %6 (one byte each, the register in the low bit). controlled_ry_two: q0 + q1 + q2
; (measured).
; Clean: controlled_ry_chain: the swap rail of every in-place form (|0> after its swap-in, on both branches of the
; control in the second loop); un-copied but left allocated (overtaken, rule 5 sentence 1): the n angle load copies of
; theta[i] (f64 rails of HOST cells, overtaken by the swap-out of their own in-place form) and the n-1 control load
; copies of q[i] (overtaken by the swap-out of the controlled form on q[i+1]), each un-copied right after its in-place
; form's swap-in. controlled_ry_two: the conjunction flag q0 & q1.
; Kept: controlled_ry_chain: the cells q[0..n-1] are the registers, rotated in place (never freed, never measured
; directly); by rule 5: the memset's one value seed (alloc_i8(0), rule 7) and the tape slots of its n byte stores
; (sentence 3, rule 22); the two measured load copies of q[0] and q[n-1] (rule 2). controlled_ry_two: the i1 registers
; q0, q1, q2, rotated in place and measured.
; Rotations: controlled_ry_chain: (Ry, cell q[i], angle rail theta[i], 1) for i = 0..n-1; then (Ry, cell q[i+1], c,
; copy of q[i]) for i = 0..n-2 (classical n). controlled_ry_two: (Ry, q0, t0, 1); (Ry, q1, t1, 1); (Ry, q2, c, q0 & q1).
; FLAT MEMORY (rule 20). `bool q[n]` is a runtime-sized alloca that stores rails (the cq_theta results): it is
; BUS-RESIDENT, so it is __cq_alloc(n, 16) at its program point (rule 16: zeroed, a classical size, no K2) and no alloca
; remains; every access is a bus access at its run-time address (gep, then ptrtoint: classical, _hl). The zero-fill
; loop -O1 turned into `llvm.memset(q, 0, n)` under `n > 0` is rule 22's host loop of n byte stores of ONE i8 seed, kept
; (emitted although the block is zero already: §0). The cells are the registers; no handle is ever stored (§1.1).
; Each `load i8; trunc nuw to i1; cq_theta_i1; zext; store i8` on one SSA pointer is rule 5's in-place form through the
; Width-casts clause: alloc_i1(0), qram_swap_i1_hl, the gate on the swap rail, qram_swap_i1_hl, free (117, 205).
; theta is a pointer argument, not a host-resident object, so `load double theta[i]` is a bus load and its result an
; f64 rail (rule 3; over-taint, a basis copy of HOST cells): the angle is a QUANTUM ANGLE (rule 11: a value loaded from
; the bus) and the rotation is ONE cqrt_ry_i1_qangle(h, A) on the swap rail (rule 15). The load stays at its program
; point, before the swap-out (rule 5: no bus access between the two swaps), so the swap-out overtakes it before its last
; reader: the copy is un-copied after the swap-in (its last reader, the rotation, sits between the swaps) and left
; allocated, not freed (rule 5 sentence 1).
; `if (q[i]) cq_theta(&q[i + 1], c)`: the condition is a plain bus load of q[i] at width i1 (rule 5, Width casts: a
; reader of the cell an earlier form wrote), the bare rail is the flag (rule 8). The arm's load-rotate-store of q[i+1]
; is the in-place form under that flag (rules 5, 10): both swaps qram_swap_i1_hl_controlled, the rotation
; ry_i1_controlled on the swap rail; nothing is hoisted (rule 9). The control copy's last reader is the second swap, and
; the first swap (a memory version change) comes before it, so the copy is un-copied right after the second swap and
; left allocated, not freed: no rule asks at compile time whether q[i] and q[i+1] are different cells. Neither loop
; pushes anything (each trip's swap rail is freed and each load copy un-copied in the trip), so neither has a reverse
; loop (rule 14). The final reads are plain load copies at width i1, measured (rule 2); q[n-1] is `q + sext(n) - 1`,
; the two classical byte geps -O1 wrote.
; controlled_ry_two touches no memory: two controls (`q0 && q1`, which -O1 spells `select i1 %4, i1 %5, i1 false`) become
; a Toffoli into a fresh |0> flag, the controlled Ry on that flag, the Toffoli again to return the flag to |0>, and one
; free (rules 8, 10).
source_filename = "controlled_ry_bits.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @controlled_ry_chain(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = zext i32 %1 to i64    ; IR: %4  (classical byte count n)
  %6 = call ptr @__cq_alloc(i64 %5, i64 16)    ; IR: %5 = alloca i8, i64 %4, align 16: q[n] is bus-resident (rule 20 (b): a rail is stored into it), one zeroed block (rule 16; a classical size, no K2)
  %7 = icmp sgt i32 %1, 0    ; IR: %6  (classical)
  br i1 %7, label %8, label %17    ; IR: br i1 %6, label %7, label %9

8:; IR: block %7
  %9 = zext nneg i32 %1 to i64    ; IR: %8  (classical memset length n)
  %10 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%5, i8 0, %8): the byte value as ONE seed rail (rules 7, 22), kept with its stores
  br label %11

11:; IR: call @llvm.memset(%5, i8 0, %8): host loop of %8 byte stores (rule 22, classical length)
  %12 = phi i64 [ 0, %8 ], [ %15, %11 ]    ; IR: (classical byte j)
  %13 = getelementptr inbounds i8, ptr %6, i64 %12    ; IR: (the byte q + j)
  %14 = ptrtoint ptr %13 to i64    ; IR: (its run-time address, classical)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %14, i32 %10)    ; IR: memset: byte store j  (kept store, rule 5)
  %15 = add nuw nsw i64 %12, 1    ; IR: (classical)
  %16 = icmp eq i64 %15, %9    ; IR: (classical: j + 1 == n)
  br i1 %16, label %17, label %11

17:; IR: block %9
  %18 = icmp sgt i32 %1, 0    ; IR: %10  (classical)
  br i1 %18, label %19, label %21    ; IR: br i1 %10

19:; IR: block %11
  %20 = zext nneg i32 %1 to i64    ; IR: %12  (classical)
  br label %26    ; IR: br label %18

21:; IR: block %13
  %22 = icmp sgt i32 %1, 1    ; IR: %14  (classical)
  br i1 %22, label %23, label %36    ; IR: br i1 %14

23:; IR: block %15
  %24 = add nsw i32 %1, -1    ; IR: %16  (classical)
  %25 = zext i32 %24 to i64    ; IR: %17  (classical)
  br label %49    ; IR: br label %42

26:; IR: block %18  (Ry(theta[i]) on q[i], classical bound n)
  %27 = phi i64 [ 0, %19 ], [ %34, %26 ]    ; IR: %19  (classical trip counter i)
  %28 = getelementptr inbounds i8, ptr %6, i64 %27    ; IR: %20 = getelementptr inbounds i8, ptr %5, i64 %19  (the cell q[i])
  %29 = ptrtoint ptr %28 to i64    ; IR: %20 as its run-time address
  %30 = getelementptr inbounds double, ptr %0, i64 %27    ; IR: %23  (classical: &theta[i])
  %31 = ptrtoint ptr %30 to i64    ; IR: %23 as its run-time address
  %32 = call i32 @cqrt_qram_load_f64_hl(i32 %4, i64 %31)    ; IR: %24 = load double, ptr %23  [a bus load: the angle rail A of theta[i] (rules 3, 11); overtaken: the swap-out below comes before its last reader (rule 5 sentence 1)]
  %33 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %21 = load i8, ptr %20; %22 = trunc nuw to i1: in-place form at width i1 (rule 5, Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %29, i32 %33)    ; IR: %21/%22: swap-out: the rail holds q[i], the cell's low bit |0>
  call void @cqrt_ry_i1_qangle(i32 %33, i32 %32)    ; IR: %25 = cq_theta_i1(%22, %24)  [Ry(val(A)) on q[i], rule 15]
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %29, i32 %33)    ; IR: %26 = zext; store i8 %26, ptr %20: swap-in: the cell holds %25
  call void @cqrt_free(i32 %33)    ; IR: release the swap rail (|0>)
  call void @cqrt_qram_load_f64_hl_unc(i32 %32, i32 %4, i64 %31)    ; IR: un-copy %24 (its last reader, the rotation, is done; overtaken by the swap-out, so it stays allocated: rule 5 sentence 1)
  %34 = add nuw nsw i64 %27, 1    ; IR: %27  (classical)
  %35 = icmp eq i64 %34, %20    ; IR: %28  (classical)
  br i1 %35, label %21, label %26    ; IR: br i1 %28

36:; IR: block %29
  %37 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address (the cell q[0])
  %38 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %37)    ; IR: %30 = load i8, ptr %5; %31 = trunc nuw to i1  [a plain bus load at width i1 (rule 5, Width casts); measured, so never un-copied (rule 2)]
  %39 = call i1 @cqrt_measure_i1(i32 %38)    ; IR: %32 = cq_measure_i1(%31)
  %40 = zext i1 %39 to i32    ; IR: %33  (classical)
  %41 = sext i32 %1 to i64    ; IR: %34  (classical)
  %42 = getelementptr i8, ptr %6, i64 %41    ; IR: %35 = getelementptr i8, ptr %5, i64 %34  (classical: q + n)
  %43 = getelementptr i8, ptr %42, i64 -1    ; IR: %36 = getelementptr i8, ptr %35, i64 -1  (the cell q[n-1])
  %44 = ptrtoint ptr %43 to i64    ; IR: %36 as its run-time address
  %45 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %44)    ; IR: %37 = load i8, ptr %36; %38 = trunc nuw to i1  [a plain bus load at width i1; measured, never un-copied]
  %46 = call i1 @cqrt_measure_i1(i32 %45)    ; IR: %39 = cq_measure_i1(%38)
  %47 = zext i1 %46 to i32    ; IR: %40  (classical)
  %48 = add nuw nsw i32 %47, %40    ; IR: %41  (classical)
  ret i32 %48    ; IR: ret i32 %41

49:; IR: block %42  (Ry(c) on q[i+1] under q[i], classical bound n - 1)
  %50 = phi i64 [ 0, %23 ], [ %60, %58 ]    ; IR: %43  (classical i)
  %51 = phi i64 [ 1, %23 ], [ %59, %58 ]    ; IR: %44  (classical i+1)
  %52 = getelementptr inbounds i8, ptr %6, i64 %50    ; IR: %45  (the cell q[i])
  %53 = ptrtoint ptr %52 to i64    ; IR: %45 as its run-time address
  %54 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %53)    ; IR: %46 = load i8, ptr %45; %47 = trunc nuw to i1  [a plain bus load at width i1: the bare rail that is the flag of br i1 %47 (rule 8); overtaken: the swap-out below comes before its last reader (rule 5 sentence 1)]
  %55 = getelementptr inbounds i8, ptr %6, i64 %51    ; IR: block %48: %49  (the cell q[i+1]; classical address arithmetic, the bus access stays in the arm)
  %56 = ptrtoint ptr %55 to i64    ; IR: %49 as its run-time address
  %57 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %50 = load i8, ptr %49; %51 = trunc nuw to i1: in-place form at width i1 under the flag %47 (rules 5, 10), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %54, i32 %4, i64 %56, i32 %57)    ; IR: %50/%51: swap-out under the flag
  call void @cqrt_ry_i1_controlled(i32 %54, i32 %57, double %2)    ; IR: br i1 %47 -> block %48: %52 = cq_theta_i1(%51, %2)  [Ry(c) on q[i+1] controlled by the bare rail q[i]]
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %54, i32 %4, i64 %56, i32 %57)    ; IR: %53 = zext; store i8 %53, ptr %49: swap-in under the flag
  call void @cqrt_free(i32 %57)    ; IR: release the swap rail (|0> on both branches of the flag)
  call void @cqrt_qram_load_i1_hl_unc(i32 %54, i32 %4, i64 %53)    ; IR: un-copy %47 (its last reader, the swap-in, is done; overtaken by the swap-out, so it stays allocated: rule 5 sentence 1)
  br label %58    ; IR: br label %54

58:; IR: block %54
  %59 = add nuw nsw i64 %51, 1    ; IR: %55  (classical)
  %60 = add nuw nsw i64 %50, 1    ; IR: %56  (classical)
  %61 = icmp eq i64 %60, %25    ; IR: %57  (classical)
  br i1 %61, label %36, label %49    ; IR: br i1 %57
}

define i32 @controlled_ry_two(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %4 = cq_theta_i1(false, %0)  [register q0]
  call void @cqrt_ry_i1(i32 %4, double %0)    ; IR: %4 = cq_theta_i1(false, %0)  [Ry]
  %5 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %5 = cq_theta_i1(false, %1)  [register q1]
  call void @cqrt_ry_i1(i32 %5, double %1)    ; IR: %5 = cq_theta_i1(false, %1)  [Ry]
  %6 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %6 = select i1 %4, i1 %5, i1 false  [flag rail for q0 && q1]
  call void @cqrt_and_i1(i32 %4, i32 %5, i32 %6)    ; IR: %6 = q0 & q1  (Toffoli into the |0> flag)
  %7 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %10 = phi i1 [ %8, %7 ], [ false, %3 ]  [register q2, starts as false]
  call void @cqrt_ry_i1_controlled(i32 %6, i32 %7, double %2)    ; IR: br i1 %6 -> block %7: %8 = cq_theta_i1(false, %2)  [Ry on q2 under the flag]
  call void @cqrt_and_i1(i32 %4, i32 %5, i32 %6)    ; IR: uncompute %6 (q0, q1 unchanged)
  call void @cqrt_free(i32 %6)    ; IR: release the flag (|0>)
  %8 = call i1 @cqrt_measure_i1(i32 %4)    ; IR: %11 = cq_measure_i1(%4)
  %9 = zext i1 %8 to i32    ; IR: %12  (classical)
  %10 = call i1 @cqrt_measure_i1(i32 %5)    ; IR: %13 = cq_measure_i1(%5)
  %11 = zext i1 %10 to i32    ; IR: %14  (classical)
  %12 = add nuw nsw i32 %11, %9    ; IR: %15  (classical)
  %13 = call i1 @cqrt_measure_i1(i32 %7)    ; IR: %16 = cq_measure_i1(%10)
  %14 = zext i1 %13 to i32    ; IR: %17  (classical)
  %15 = add nuw nsw i32 %12, %14    ; IR: %18  (classical)
  ret i32 %15    ; IR: ret i32 %18
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_ry_i1_qangle(i32, i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_f64_hl(i32, i64)
declare void @cqrt_qram_load_f64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_qram_load_i1_hl_unc(i32, i32, i64)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl_controlled(i32, i32, i64, i32)
