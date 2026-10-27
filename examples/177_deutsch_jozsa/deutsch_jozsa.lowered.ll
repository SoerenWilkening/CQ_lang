; HAND-WRITTEN. Rules: 20 (bool x[nq] is a runtime-sized slot array: one `alloca i32, nq` of i1 handle cells, as 74), 2
; (cq_theta(false, pi/2), -O1's constant-propagated init, mints alloc_i1(0) + ry_i1 and the handle is stored in the cell; the
; second cq_theta rotates the cell's rail in place), 14 (every loop has the classical bound nq and stays a ROLLED classical
; loop; the case-2 parity loop is a classical-bound loop with a quantum body: each trip computes the next parity into a fresh
; rail and pushes the previous one, and a reverse loop pops and uncomputes them after the kickback), 7 (the |0> parity seed
; is freed directly), 13 / 8 (the `switch` on the classical selector stays a classical switch; the one quantum branch
; `br i1 %24` is a flag kickback per incoming arm), 4 (p ^= x[i], -O1's `icmp ne i8 cell, zext(p)` on two i1-valued i8s
; (!range [0,2)), is cq_template_xor_i1 into a fresh rail, as 113: the zext i1 -> i8 of the parity rail is that rail's i1-valued
; view, no gate), 12 (the case-1 edge reaches cq_phi(pi) under no quantum predicate at any depth: a global phase, deleted; the
; other two edges are under the quantum flag and kick back), 5 (the parity rails are uncomputed newest first in their own arm,
; before H^n rotates their sources).
; Checked: x[0..nq-1] (the measured rails; m = sum x[i] << i).
; Clean: the case-2 parity rails (nq of them) and the parity seed. Nothing else is allocated beyond the registers.
; Kept: the nq registers only (measured).
; Rotations: Ry(pi/2) on x[0..nq-1] (control 1); then exactly one of (classical switch on sel):
;   sel == 0: nothing;  sel == 1: nothing (global phase deleted);
;   sel == 2: P(pi) on flag(x0 ^ ... ^ x[nq-1])   [control predicate: the parity of x; nothing when nq <= 0];
;   default:  P(pi) on x[0] itself                [control predicate x0: the bare rail is its own flag];
; then Ry(-pi/2) on x[0..nq-1] (control 1).
; Expected: m == 0 iff f is constant. Replayed (state vector over the trace): deutsch_jozsa(3, 2) -> m = 7, p = 1;
;   deutsch_jozsa(3, 0) -> m = 0, p = 1; deutsch_jozsa(5, 3) -> m = 1, p = 1; deutsch_jozsa(5, 1) -> m = 0, p = 1; every free hits |0>.
; -O1 inlined f_eval: the `switch i32 %1` sends case 0 to the join, case 1 straight to the cq_phi block, case 2 to the parity
; loop (guarded by nq > 0; nq <= 0 goes to the join with p = false), and the default to a load of x[0]; the two quantum arms
; meet in `phi i1 %24` and `br i1 %24` guards the phase block. The handle phi under classical control is not emitted: its
; only consumer is the kickback, which is emitted per arm because the case-2 arm must uncompute its own parity rails (the
; default arm's flag is the register x[0] itself and has nothing to uncompute). The parity loop's carried `phi i1 %13`,
; seeded by the literal false, is a carried rail seeded by alloc_i1(0) (rule 7).
source_filename = "deutsch_jozsa.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @deutsch_jozsa(i32 noundef %0, i32 noundef %1) {
  %3 = zext i32 %0 to i64    ; IR: %3 = zext i32 %0 to i64  (classical cell count)
  %4 = alloca i32, i64 %3, align 16    ; IR: %4 = alloca i8, i64 %3  (slot array of runtime length nq: one i1 handle per cell of x; rule 20)
  %5 = icmp sgt i32 %0, 0    ; IR: %5  (classical)
  br i1 %5, label %6, label %14    ; IR: br i1 %5, label %6, label %8

6:; IR: block %6
  %7 = zext nneg i32 %0 to i64    ; IR: %7  (classical bound)
  br label %8    ; IR: br label %25

8:; IR: block %25  (x[i] = false; H^n: the Ry(pi/2) loop, classical bound nq)
  %9 = phi i64 [ 0, %6 ], [ %12, %8 ]    ; IR: %26  (classical i)
  %10 = getelementptr inbounds i32, ptr %4, i64 %9    ; IR: %27  (slot of x[i])
  %11 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: store i8 0, ptr %27; %28 = cq_theta_i1(false, pi/2)  [register x[i], minted from the literal false]
  call void @cqrt_ry_i1(i32 %11, double 0x3FF921FB54442D18)    ; IR: %28 = cq_theta_i1(false, pi/2)  [Ry(pi/2) on x[i]]
  store i32 %11, ptr %10, align 4    ; IR: %29 = zext; store i8 %29, ptr %27  (the cell holds the handle of x[i])
  %12 = add nuw nsw i64 %9, 1    ; IR: %30  (classical)
  %13 = icmp eq i64 %12, %7    ; IR: %31  (classical)
  br i1 %13, label %14, label %8    ; IR: br i1 %31, label %8, label %25

14:; IR: block %8
  switch i32 %1, label %38 [    ; IR: switch i32 %1 (classical: the function selector); case 0 -> the join (no phase); case 1 -> cq_phi(pi) under no quantum predicate: a global phase, deleted (rule 12), so the edge goes to the join
    i32 0, label %40
    i32 1, label %40
    i32 2, label %15
  ]

15:; IR: block %9  (case 2: f = parity of x)
  %16 = icmp sgt i32 %0, 0    ; IR: %10  (classical)
  br i1 %16, label %17, label %40    ; IR: br i1 %10, label %11, label %33  (nq <= 0: p = false, no phase)

17:; IR: edge %9 -> %11
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: incoming false of phi %13  [p before trip 0: a |0> seed rail]
  br label %19    ; IR: br label %11

19:; IR: block %11  (p ^= x[i], classical bound nq)
  %20 = phi i64 [ %25, %19 ], [ 0, %17 ]    ; IR: %12  (classical i)
  %21 = phi i32 [ %24, %19 ], [ %18, %17 ]    ; IR: %13 = phi i1 [ %17, %11 ], [ false, %9 ]  (the carried parity rail)
  %22 = getelementptr inbounds i32, ptr %4, i64 %20    ; IR: %14  (slot of x[i])
  %23 = load i32, ptr %22, align 4    ; IR: %15 = load i8, ptr %14  (handle of x[i], i1-valued; no gate)
  %24 = call i32 @cq_template_xor_i1(i32 %23, i32 %21)    ; IR: %16 = zext i1 %13 to i8 (a view, no gate); %17 = icmp ne i8 %15, %16  [= x[i] ^ p on i1-valued i8s: the next parity, a fresh rail]
  call void @cqrt_push(i32 %21)    ; IR: trip-local rail on the handle stack (rule 14): the previous parity
  %25 = add nuw nsw i64 %20, 1    ; IR: %18  (classical)
  %26 = icmp eq i64 %25, %3    ; IR: %19  (classical)
  br i1 %26, label %27, label %19    ; IR: br i1 %19, label %23, label %11

27:; IR: block %23 reached from %11  (%24 = phi i1 [ %17, %11 ]; br i1 %24 -> block %32)
  call void @cqrt_rz_i1(i32 %24, double 0x400921FB54442D18)    ; IR: %24 = phi i1 [ %17, %11 ]; br i1 %24 -> block %32: cq_phi(pi)  [kickback on the parity flag]
  %28 = add nsw i64 %3, -1    ; IR: (mirror of the parity loop: undoes trip nq-1 down to 0; classical)
  br label %29    ; IR: (mirror)

29:; IR: reverse loop over the parity trips
  %30 = phi i64 [ %28, %27 ], [ %35, %29 ]    ; IR: i of the trip being undone  (classical)
  %31 = phi i32 [ %24, %27 ], [ %32, %29 ]    ; IR: %17 of the trip being undone
  %32 = call i32 @cqrt_pop()    ; IR: the trip's incoming parity (%13)
  %33 = getelementptr inbounds i32, ptr %4, i64 %30    ; IR: (slot of x[i])
  %34 = load i32, ptr %33, align 4    ; IR: the trip's x[i] handle, reloaded (unchanged: H^n has not run yet)
  call void @cq_template_xor_i1_unc(i32 %31, i32 %34, i32 %32)    ; IR: uncompute %17 of that trip
  call void @cqrt_free(i32 %31)    ; IR: release it (|0>)
  %35 = add nsw i64 %30, -1    ; IR: (classical)
  %36 = icmp eq i64 %30, 0    ; IR: (classical)
  br i1 %36, label %37, label %29    ; IR: (classical)

37:; IR: end of the mirror
  call void @cqrt_free(i32 %32)    ; IR: release incoming false of phi %13 (the seed; never written, |0>; rule 7)
  br label %40    ; IR: br label %33

38:; IR: block %20  (default: f = x[0])
  %39 = load i32, ptr %4, align 4    ; IR: %21 = load i8, ptr %4; %22 = trunc to i1  (handle of x[0]: a bare rail)
  call void @cqrt_rz_i1(i32 %39, double 0x400921FB54442D18)    ; IR: %24 = phi i1 [ %22, %20 ]; br i1 %24 -> block %32: cq_phi(pi)  [phase on the bare rail x[0] itself: a diagonal gate on the register, no flag]
  br label %40    ; IR: br label %23 -> br label %33

40:; IR: block %33 (the join)
  %41 = icmp sgt i32 %0, 0    ; IR: %34  (classical)
  br i1 %41, label %42, label %44    ; IR: br i1 %34, label %35, label %37

42:; IR: block %35
  %43 = zext nneg i32 %0 to i64    ; IR: %36  (classical bound)
  br label %48    ; IR: br label %41

44:; IR: block %37
  %45 = icmp sgt i32 %0, 0    ; IR: %38  (classical)
  br i1 %45, label %46, label %54    ; IR: br i1 %38, label %39, label %50

46:; IR: block %39
  %47 = zext nneg i32 %0 to i64    ; IR: %40  (classical bound)
  br label %56    ; IR: br label %52

48:; IR: block %41  (H^n: the Ry(-pi/2) loop, classical bound nq)
  %49 = phi i64 [ 0, %42 ], [ %52, %48 ]    ; IR: %42  (classical i)
  %50 = getelementptr inbounds i32, ptr %4, i64 %49    ; IR: %43  (slot of x[i])
  %51 = load i32, ptr %50, align 4    ; IR: %44 = load i8, ptr %43; %45 = trunc to i1  (handle of x[i]; no gate)
  call void @cqrt_ry_i1(i32 %51, double 0xBFF921FB54442D18)    ; IR: %46 = cq_theta_i1(%45, -pi/2)  [Ry(-pi/2) in place on x[i]]; %47/store: handle unchanged
  %52 = add nuw nsw i64 %49, 1    ; IR: %48  (classical)
  %53 = icmp eq i64 %52, %43    ; IR: %49  (classical)
  br i1 %53, label %44, label %48    ; IR: br i1 %49, label %37, label %41

54:; IR: block %50
  %55 = phi i32 [ 0, %44 ], [ %65, %56 ]    ; IR: %51  (classical m)
  ret i32 %55    ; IR: ret i32 %51

56:; IR: block %52  (the measure loop, classical bound nq)
  %57 = phi i64 [ 0, %46 ], [ %66, %56 ]    ; IR: %53  (classical i)
  %58 = phi i32 [ 0, %46 ], [ %65, %56 ]    ; IR: %54  (classical m)
  %59 = getelementptr inbounds i32, ptr %4, i64 %57    ; IR: %55  (slot of x[i])
  %60 = load i32, ptr %59, align 4    ; IR: %56 = load i8, ptr %55; %57 = trunc to i1  (handle of x[i])
  %61 = call i1 @cqrt_measure_i1(i32 %60)    ; IR: %58 = cq_measure_i1(%57)
  %62 = zext i1 %61 to i32    ; IR: %59  (classical)
  %63 = trunc nuw nsw i64 %57 to i32    ; IR: %60  (classical)
  %64 = shl nuw i32 %62, %63    ; IR: %61  (classical)
  %65 = or i32 %64, %58    ; IR: %62  (classical)
  %66 = add nuw nsw i64 %57, 1    ; IR: %63  (classical)
  %67 = icmp eq i64 %66, %47    ; IR: %64  (classical)
  br i1 %67, label %54, label %56    ; IR: br i1 %64, label %50, label %52
}

declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cq_template_xor_i1(i32, i32)
declare void @cq_template_xor_i1_unc(i32, i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
