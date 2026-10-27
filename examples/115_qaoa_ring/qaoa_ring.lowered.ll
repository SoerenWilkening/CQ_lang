; HAND-WRITTEN. Rules: 20, 2, 8, 12, 14, 5.
; Checked: m = sum_i cq_measure(x[i]) << i, the n cells measured.
; Clean: the per-edge compare flag x[eu[e]] == x[ev[e]] (uncomputed and freed every trip).
; Kept: the n i1 registers x[0..n-1] (measured).
; Rotations: Ry(pi/2) on each x[i], i = 0..n-1 (control 1); then per layer l = 0..p-1: for each edge e = 0..ne-1,
; P(-gamma[l]) on NOT flag(x[eu[e]] == x[ev[e]]); for each i = 0..n-1, P(pi/2) on x[i], Ry(2 beta[l]) on x[i],
; P(-pi/2) on x[i].
; QAOA MaxCut on a graph given at run time: the vertex count n, the edge count ne, the edge endpoint arrays eu/ev, the
; layer count p and the angle arrays gamma/beta are all parameters, so every loop is a ROLLED classical loop with a
; runtime bound (rule 14) and no size is fixed at compile time.
; `bool x[n]` is a runtime-sized slot array (rule 20): one `alloca i32, n` of handle cells. Every access to it has a
; classical index: i in the H, mixer and measure loops, and the edge endpoints eu[e], ev[e], which are classical host
; loads from the caller's arrays (the sext and the gep into the slots are the same index). It is never a QRAM.
; Gate shapes:
;  (0) H layer `x[i] = 0; cq_theta(&x[i], pi/2)`: -O1 forwards the stored 0 into the theta (`cq_theta_i1(false, ..)`), so
;      each trip mints the cell's register alloc_i1(false) + Ry(pi/2) (rule 2) and stores its handle in slot i; the
;      `store i8 0` before it is overwritten with no read in between and emits nothing.
;  (1) cost phase `if (x[u] != x[v]) cq_phi(-gamma[l])`: -O1 compares the two cells with `icmp eq i8` and puts the phase
;      in the ELSE arm, so the flag is cq_template_icmp_eq_i1 of the two cell rails into a fresh |0> rail and .O1.ll block %52
;      runs under NOT flag: the kickback cqrt_rz_i1 on the flag inside an X bracket (rule 8); the flag is uncomputed from
;      the two (unchanged) cells and freed every trip. The angle gamma[l] is a classical host load that -O1 left in the
;      arm; it is computed unconditionally (it is in bounds whenever the layer runs: l < p).
;  (2) mixer phase `if (x[i]) cq_phi(+-pi/2)`: the condition is a BARE cell rail, its own predicate: cqrt_rz_i1 directly
;      on the user register (diagonal; no flag, no copy). The .O1.ll `br i1 %70` tests the rotated rail, still the same handle.
;  (3) `cq_theta(&x[i], 2 beta[l])`: Ry in place on the cell's rail; the store of its result changes nothing.
; Nothing is pushed: every loop is classical-bound and every flag dies inside its trip. Only the n registers survive and
; are measured.
; Expected (trace replayed on a state vector by a scratch generalisation of _tools/replay/sim_trace_cq.py to an edge list
; and several calls): call 1, the 4-ring, p = 2, gamma = (pi/4, pi/8), beta = (pi/8, pi/16) (the former fixed-size
; example's angles): max |p_trace - p_exact| = 1.1e-16, <C> = 3.1036 of 4; call 2, the 5-path, p = 1, gamma = 0.6,
; beta = 0.35: max |p_trace - p_exact| = 5.6e-17, <C> = 2.9671 of 4. Every free hit |0>; only the registers are live at
; the end of each call.
source_filename = "qaoa_ring.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @qaoa_ring(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef %4, ptr noundef %5, ptr noundef %6) {
  %8 = zext i32 %0 to i64    ; IR: %8 = zext i32 %0 to i64  (classical cell count)
  %9 = alloca i32, i64 %8, align 16    ; IR: %9 = alloca i8, i64 %8  (runtime-sized slot array: one handle cell per x[i]; rule 20)
  %10 = icmp sgt i32 %0, 0    ; IR: %10  (classical)
  br i1 %10, label %11, label %13    ; IR: br i1 %10, label %11, label %13

11:; IR: block %11
  %12 = zext nneg i32 %0 to i64    ; IR: %12  (classical)
  br label %21    ; IR: br label %21

13:; IR: block %13
  %14 = icmp sgt i32 %4, 0    ; IR: %14  (classical)
  br i1 %14, label %15, label %31    ; IR: br i1 %14, label %15, label %32

15:; IR: block %15
  %16 = icmp sgt i32 %1, 0    ; IR: %16  (classical)
  %17 = icmp sgt i32 %0, 0    ; IR: %17  (classical)
  %18 = zext nneg i32 %4 to i64    ; IR: %18  (classical)
  %19 = zext nneg i32 %1 to i64    ; IR: %19  (classical)
  %20 = zext nneg i32 %0 to i64    ; IR: %20  (classical)
  br label %27    ; IR: br label %28

21:; IR: block %21  (H layer, classical bound n)
  %22 = phi i64 [ 0, %11 ], [ %25, %21 ]    ; IR: %22  (classical i)
  %23 = getelementptr inbounds i32, ptr %9, i64 %22    ; IR: %23 = getelementptr i8, ptr %9, %22  (slot of x[i])
  %24 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: store i8 0, ptr %23; %24 = cq_theta_i1(false, pi/2)  [register x[i], seeded with the stored 0]
  call void @cqrt_ry_i1(i32 %24, double 0x3FF921FB54442D18)    ; IR: %24 = cq_theta_i1(false, pi/2)  [Ry(pi/2)]
  store i32 %24, ptr %23, align 4    ; IR: %25 = zext %24; store i8 %25, ptr %23  (slot i holds the handle of x[i])
  %25 = add nuw nsw i64 %22, 1    ; IR: %26  (classical)
  %26 = icmp eq i64 %25, %12    ; IR: %27  (classical)
  br i1 %26, label %13, label %21    ; IR: br i1 %27, label %13, label %21

27:; IR: block %28  (layer loop, classical bound p)
  %28 = phi i64 [ 0, %15 ], [ %56, %55 ]    ; IR: %29  (classical l)
  br i1 %16, label %29, label %35    ; IR: br i1 %16, label %30, label %36

29:; IR: block %30
  %30 = getelementptr inbounds double, ptr %5, i64 %28    ; IR: %31  (classical &gamma[l])
  br label %38    ; IR: br label %39

31:; IR: block %32
  %32 = icmp sgt i32 %0, 0    ; IR: %33  (classical)
  br i1 %32, label %33, label %66    ; IR: br i1 %33, label %34, label %76

33:; IR: block %34
  %34 = zext nneg i32 %0 to i64    ; IR: %35  (classical)
  br label %68    ; IR: br label %78

35:; IR: block %36
  br i1 %17, label %36, label %55    ; IR: br i1 %17, label %37, label %58

36:; IR: block %37
  %37 = getelementptr inbounds double, ptr %6, i64 %28    ; IR: %38  (classical &beta[l])
  br label %58    ; IR: br label %61

38:; IR: block %39  (cost layer, classical bound ne)
  %39 = phi i64 [ 0, %29 ], [ %53, %38 ]    ; IR: %40  (classical e)
  %40 = getelementptr inbounds i32, ptr %2, i64 %39    ; IR: %41  (classical)
  %41 = load i32, ptr %40, align 4    ; IR: %42 = load i32, ptr %41  (classical eu[e])
  %42 = sext i32 %41 to i64    ; IR: %43  (classical)
  %43 = getelementptr inbounds i32, ptr %9, i64 %42    ; IR: %44 = getelementptr i8, ptr %9, %43  (slot of x[eu[e]])
  %44 = load i32, ptr %43, align 4    ; IR: %45 = load i8, ptr %44  (handle of x[eu[e]]; no gate)
  %45 = getelementptr inbounds i32, ptr %3, i64 %39    ; IR: %46  (classical)
  %46 = load i32, ptr %45, align 4    ; IR: %47 = load i32, ptr %46  (classical ev[e])
  %47 = sext i32 %46 to i64    ; IR: %48  (classical)
  %48 = getelementptr inbounds i32, ptr %9, i64 %47    ; IR: %49 = getelementptr i8, ptr %9, %48  (slot of x[ev[e]])
  %49 = load i32, ptr %48, align 4    ; IR: %50 = load i8, ptr %49  (handle of x[ev[e]]; no gate)
  %50 = load double, ptr %30, align 8    ; IR: %53 = load double, ptr %31  (classical gamma[l], hoisted out of block %52)
  %51 = fneg double %50    ; IR: %54  (classical -gamma[l])
  %52 = call i32 @cq_template_icmp_eq_i1(i32 %44, i32 %49)    ; IR: %51 = icmp eq i8 %45, %50  [flag rail: x[u] == x[v]; block %52 runs under NOT %51]
  call void @cqrt_not_i1(i32 %52)    ; IR: bracket: block %52 is the FALSE edge of br i1 %51 (rule 8)
  call void @cqrt_rz_i1(i32 %52, double %51)    ; IR: block %52: cq_phi(%54)  [kickback on the flag]
  call void @cqrt_not_i1(i32 %52)    ; IR: bracket
  call void @cq_template_icmp_eq_i1_unc(i32 %52, i32 %44, i32 %49)    ; IR: uncompute %51 (the two cells are unchanged)
  call void @cqrt_free(i32 %52)    ; IR: release the flag (|0>)
  %53 = add nuw nsw i64 %39, 1    ; IR: %56  (classical; block %55)
  %54 = icmp eq i64 %53, %19    ; IR: %57  (classical)
  br i1 %54, label %35, label %38    ; IR: br i1 %57, label %36, label %39

55:; IR: block %58
  %56 = add nuw nsw i64 %28, 1    ; IR: %59  (classical)
  %57 = icmp eq i64 %56, %18    ; IR: %60  (classical)
  br i1 %57, label %31, label %27    ; IR: br i1 %60, label %32, label %28

58:; IR: block %61  (mixer layer, classical bound n)
  %59 = phi i64 [ 0, %36 ], [ %64, %58 ]    ; IR: %62  (classical i)
  %60 = getelementptr inbounds i32, ptr %9, i64 %59    ; IR: %63 = getelementptr i8, ptr %9, %62  (slot of x[i])
  %61 = load i32, ptr %60, align 4    ; IR: %64 = load i8, ptr %63; %65 = trunc to i1  (handle of x[i]; no gate)
  call void @cqrt_rz_i1(i32 %61, double 0x3FF921FB54442D18)    ; IR: br i1 %65 -> block %66: cq_phi(pi/2)  [the bare rail is its own predicate: the phase goes on the register]
  %62 = load double, ptr %37, align 8    ; IR: %68 = load double, ptr %38  (classical beta[l])
  %63 = fmul double %62, 2.000000e+00    ; IR: %69  (classical 2 beta[l])
  call void @cqrt_ry_i1(i32 %61, double %63)    ; IR: %70 = cq_theta_i1(%65, %69)  [Ry in place on x[i]]; %71/store: handle unchanged
  call void @cqrt_rz_i1(i32 %61, double 0xBFF921FB54442D18)    ; IR: br i1 %70 -> block %72: cq_phi(-pi/2)  [on the rotated rail, same handle]
  %64 = add nuw nsw i64 %59, 1    ; IR: %74  (classical; block %73)
  %65 = icmp eq i64 %64, %20    ; IR: %75  (classical)
  br i1 %65, label %55, label %58    ; IR: br i1 %75, label %58, label %61

66:; IR: block %76
  %67 = phi i32 [ 0, %31 ], [ %77, %68 ]    ; IR: %77  (classical m)
  ret i32 %67    ; IR: ret i32 %77

68:; IR: block %78  (measure loop, classical bound n)
  %69 = phi i64 [ 0, %33 ], [ %78, %68 ]    ; IR: %79  (classical i)
  %70 = phi i32 [ 0, %33 ], [ %77, %68 ]    ; IR: %80  (classical m)
  %71 = getelementptr inbounds i32, ptr %9, i64 %69    ; IR: %81 = getelementptr i8, ptr %9, %79  (slot of x[i])
  %72 = load i32, ptr %71, align 4    ; IR: %82 = load i8, ptr %81; %83 = trunc to i1  (handle of x[i])
  %73 = call i1 @cqrt_measure_i1(i32 %72)    ; IR: %84 = cq_measure_i1(%83)
  %74 = zext i1 %73 to i32    ; IR: %85  (classical)
  %75 = trunc nuw nsw i64 %69 to i32    ; IR: %86  (classical)
  %76 = shl nuw i32 %74, %75    ; IR: %87  (classical)
  %77 = or i32 %76, %70    ; IR: %88  (classical)
  %78 = add nuw nsw i64 %69, 1    ; IR: %89  (classical)
  %79 = icmp eq i64 %78, %34    ; IR: %90  (classical)
  br i1 %79, label %66, label %68    ; IR: br i1 %90, label %76, label %78
}

declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cq_template_icmp_eq_i1(i32, i32)
declare void @cq_template_icmp_eq_i1_unc(i32, i32, i32)
