; HAND-WRITTEN. Rules: 20 (bool x[nq] is a runtime-sized slot array: one `alloca i32, nq` of i1 handles; every access has a
; classical index and loads the handle), 2 (each H-loop trip mints x[i] = alloc_i1(false) + Ry; cq_theta on a slot handle
; rotates that rail in place; the measure loop reads the slots), 14 (every loop has a classical runtime bound: the three Ry
; loops, the two value(x) loops and the measure loop run nq trips, the outer loop iters trips; all stay ROLLED classical
; loops; each value(x) trip pushes its three trip-local rails and a reverse loop of nq trips pops and uncomputes them),
; 4 (value(x) is zext_i1_to_i32 / shl_i32_hl / or_i32 into fresh rails; the oracle compare is icmp_eq_i32_hl against the
; runtime target), 8 (the compare rail is the branch flag: the oracle phase arm is rz_i1 on it; R0's phase arm sits on the
; FALSE edge of `v == 0`, so it is the X-bracketed kickback), 5 (LIFO: the flag, then the value chain newest trip first, all
; before the next A^dag / A layer rotates their sources), 7 (the |0> accumulator seed of each value(x) is freed directly),
; 12 (every cq_phi is under a quantum predicate: none is deleted).
; Checked: x[0..nq-1] (the nq measured rails; m = sum x[i] << i).
; Clean: every flag, every value-chain rail (zext, shl, or) and both accumulator seeds, in every iteration.
; Kept: the nq registers only (measured). No rail is left dirty.
; Rotations: Ry(pi/2) on x[0..nq-1] (A; control 1); then per iteration r = 0 .. iters-1:
;   P(pi)  on flag(v == target)       [O;  control predicate: value(x) == target, v = sum_i x[i] << i]
;   Ry(-pi/2) on x[0..nq-1]           [A^dag; control 1]
;   P(pi)  on NOT flag(v == 0)        [R0; control predicate: value(x) != 0, the X-bracketed flag]
;   Ry(pi/2) on x[0..nq-1]            [A; control 1]
; Expected: P(target) = sin^2((2 iters + 1) theta) with sin^2 theta = 2^-nq. Replayed on a state vector (scratch replayer,
; every free asserted |0>): grover_search(3, 5, 2): P(5) = 0.945312 (textbook 0.945312); grover_search(4, 11, 3):
; P(11) = 0.961319 (textbook 0.961319); every other outcome (1 - P) / (2^nq - 1), max deviation 5.6e-16.
; The source is Nielsen & Chuang's G = A R0 A^dag O with A = Ry(pi/2)^nq, written as plain C with the qubit count an
; input. -O1 inlines value(nq, x) twice as an nq-trip accumulator loop (zext nneg i8 -> i32 of the cell, shl by the trip
; index, or into the carried i32) whose carried value starts from the literal 0 (a |0> seed rail, minted before the
; nq > 0 guard so that the zero-trip path reads the seed too: the exit phis %42 / %59 are the seed or the last trip's
; or-rail). The H loop stores 0 and forwards it into `cq_theta_i1(false, pi/2)`: one minted register per trip, the dead
; `store i8 0` emits nothing. The quantum lowering of the accumulator is 117's: fresh rails per trip, handle-stack mirror
; right after the flag's kickback, before A^dag / A rotate the cells (the _unc of zext reads the cell, which must still
; hold the value it read). The mirror runs only when the forward loop ran (the same classical nq > 0 test); its last pop
; is the seed, which is then freed directly. `value(x) != 0` is spelled by -O1 as `icmp eq %59, 0` with the phase block
; on the false edge, so the kickback is bracketed by X on the flag; P(pi) under `v != 0` is R0 = 2|0><0| - I up to a
; global phase. No quantum data crosses the outer back edge except the nq registers (in place), so the handle stack is
; empty at every latch.
source_filename = "grover_search.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @grover_search(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = zext i32 %0 to i64    ; IR: %4 = zext i32 %0 to i64  (classical cell count)
  %5 = alloca i32, i64 %4, align 16    ; IR: %5 = alloca i8, i64 %4  (runtime-sized slot array: one handle cell per x[i]; rule 20)
  %6 = icmp sgt i32 %0, 0    ; IR: %6  (classical)
  br i1 %6, label %7, label %9    ; IR: br i1 %6, label %7, label %9

7:; IR: block %7
  %8 = zext nneg i32 %0 to i64    ; IR: %8  (classical)
  br label %17    ; IR: br label %17

9:; IR: block %9
  %10 = icmp sgt i32 %2, 0    ; IR: %10  (classical: iters > 0)
  br i1 %10, label %11, label %23    ; IR: br i1 %10, label %11, label %24

11:; IR: block %11
  %12 = icmp sgt i32 %0, 0    ; IR: %12  (classical)
  %13 = icmp sgt i32 %0, 0    ; IR: %13  (classical)
  %14 = icmp sgt i32 %0, 0    ; IR: %14  (classical)
  %15 = zext nneg i32 %0 to i64    ; IR: %15  (classical)
  %16 = zext nneg i32 %0 to i64    ; IR: %16  (classical)
  br label %27    ; IR: br label %28

17:; IR: block %17  (A: the first Ry loop, classical bound nq)
  %18 = phi i64 [ 0, %7 ], [ %21, %17 ]    ; IR: %18  (classical i)
  %19 = getelementptr inbounds i32, ptr %5, i64 %18    ; IR: %19 = getelementptr i8, ptr %5, %18  (slot of x[i])
  %20 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: store i8 0, ptr %19; %20 = cq_theta_i1(false, pi/2)  [register x[i], seeded with the stored 0]
  call void @cqrt_ry_i1(i32 %20, double 0x3FF921FB54442D18)    ; IR: %20 = cq_theta_i1(false, pi/2)  [A: Ry(pi/2)]
  store i32 %20, ptr %19, align 4    ; IR: %21 = zext %20; store i8 %21, ptr %19  (slot i holds the handle of x[i])
  %21 = add nuw nsw i64 %18, 1    ; IR: %22  (classical)
  %22 = icmp eq i64 %21, %8    ; IR: %23  (classical)
  br i1 %22, label %9, label %17    ; IR: br i1 %23, label %9, label %17

23:; IR: block %24
  %24 = icmp sgt i32 %0, 0    ; IR: %25  (classical)
  br i1 %24, label %25, label %103    ; IR: br i1 %25, label %26, label %84

25:; IR: block %26
  %26 = zext nneg i32 %0 to i64    ; IR: %27  (classical)
  br label %105    ; IR: br label %86

27:; IR: block %28  (the outer iteration loop, classical bound iters)
  %28 = phi i32 [ 0, %11 ], [ %95, %94 ]    ; IR: %29  (classical r)
  %29 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phis %32 and %42  [v before trip 0: a |0> seed rail]
  br i1 %12, label %30, label %41    ; IR: br i1 %12, label %30, label %41

30:; IR: block %30  (value(x) of the oracle, classical bound nq)
  %31 = phi i64 [ %39, %30 ], [ 0, %27 ]    ; IR: %31  (classical i)
  %32 = phi i32 [ %38, %30 ], [ %29, %27 ]    ; IR: %32 = phi i32 [ %38, %30 ], [ 0, %28 ]  (the carried accumulator rail)
  %33 = getelementptr inbounds i32, ptr %5, i64 %31    ; IR: %33 = getelementptr i8, ptr %5, %31  (slot of x[i])
  %34 = load i32, ptr %33, align 4    ; IR: %34 = load i8, ptr %33  (handle of x[i]; no gate)
  %35 = call i32 @cq_template_zext_i1_to_i32(i32 %34)    ; IR: %35 = zext nneg i8 %34 to i32  [x[i] widened into a fresh rail]
  %36 = trunc nuw nsw i64 %31 to i32    ; IR: %36  (classical)
  %37 = call i32 @cq_template_shl_i32_hl(i32 %35, i32 %36)    ; IR: %37 = shl nuw i32 %35, %36  [fresh rail]
  %38 = call i32 @cq_template_or_i32(i32 %37, i32 %32)    ; IR: %38 = or i32 %37, %32  [fresh rail: the next accumulator]
  call void @cqrt_push(i32 %32)    ; IR: trip-local rails on the handle stack (rule 14): the previous accumulator
  call void @cqrt_push(i32 %35)    ; IR: ... the zext rail
  call void @cqrt_push(i32 %37)    ; IR: ... the shl rail
  %39 = add nuw nsw i64 %31, 1    ; IR: %39  (classical)
  %40 = icmp eq i64 %39, %4    ; IR: %40  (classical)
  br i1 %40, label %41, label %30    ; IR: br i1 %40, label %41, label %30

41:; IR: block %41
  %42 = phi i32 [ %29, %27 ], [ %38, %30 ]    ; IR: %42 = phi i32 [ 0, %28 ], [ %38, %30 ]  (v: the seed, or the last trip's rail)
  %43 = call i32 @cq_template_icmp_eq_i32_hl(i32 %42, i32 %1)    ; IR: %43 = icmp eq i32 %42, %1  [the oracle flag: v == target, target a runtime literal]
  call void @cqrt_rz_i1(i32 %43, double 0x400921FB54442D18)    ; IR: br i1 %43 -> block %44: cq_phi(pi)  [O: kickback on the flag]
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %43, i32 %42, i32 %1)    ; IR: uncompute %43 after its only controlled gate
  call void @cqrt_free(i32 %43)    ; IR: release the flag (|0>)
  br i1 %12, label %44, label %57    ; IR: (mirror of the oracle's value(x) loop iff it ran: pops trip nq-1 .. 0 before A^dag)

44:; IR: reverse loop over the oracle's value(x) trips
  %45 = phi i64 [ 0, %41 ], [ %55, %44 ]    ; IR: reverse trip index (undoes trip nq-1-k)
  %46 = phi i32 [ %42, %41 ], [ %49, %44 ]    ; IR: %38 of the trip being undone
  %47 = call i32 @cqrt_pop()    ; IR: the trip's shl rail (%37)
  %48 = call i32 @cqrt_pop()    ; IR: the trip's zext rail (%35)
  %49 = call i32 @cqrt_pop()    ; IR: the trip's incoming accumulator (%32)
  %50 = xor i64 %45, -1    ; IR: (classical: -1 - k)
  %51 = add nsw i64 %4, %50    ; IR: i of the trip being undone = nq - 1 - k  (classical)
  %52 = getelementptr inbounds i32, ptr %5, i64 %51    ; IR: (slot of x[i])
  %53 = load i32, ptr %52, align 4    ; IR: the trip's x[i] handle, reloaded (unchanged: A^dag has not run yet)
  %54 = trunc nuw nsw i64 %51 to i32    ; IR: %36 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %46, i32 %47, i32 %49)    ; IR: uncompute %38
  call void @cqrt_free(i32 %46)    ; IR: release the %38 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %47, i32 %48, i32 %54)    ; IR: uncompute %37
  call void @cqrt_free(i32 %47)    ; IR: release the %37 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %48, i32 %53)    ; IR: uncompute %35
  call void @cqrt_free(i32 %48)    ; IR: release the %35 rail (|0>)
  %55 = add nuw nsw i64 %45, 1    ; IR: (classical)
  %56 = icmp eq i64 %55, %4    ; IR: (classical)
  br i1 %56, label %57, label %44    ; IR: (classical; the last pop %opa is %seedO)

57:; IR: block %45 (the join after the oracle)
  call void @cqrt_free(i32 %29)    ; IR: release incoming 0 of phis %32 / %42 (the seed; never written, |0>; rule 7)
  br i1 %13, label %88, label %58    ; IR: br i1 %13, label %61, label %46

58:; IR: block %46
  %59 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phis %49 and %59  [v before trip 0: a |0> seed rail]
  br i1 %12, label %60, label %71    ; IR: br i1 %12, label %47, label %58

60:; IR: block %47  (value(x) of R0, classical bound nq)
  %61 = phi i64 [ %69, %60 ], [ 0, %58 ]    ; IR: %48  (classical i)
  %62 = phi i32 [ %68, %60 ], [ %59, %58 ]    ; IR: %49 = phi i32 [ %55, %47 ], [ 0, %46 ]  (the carried accumulator rail)
  %63 = getelementptr inbounds i32, ptr %5, i64 %61    ; IR: %50  (slot of x[i])
  %64 = load i32, ptr %63, align 4    ; IR: %51 = load i8, ptr %50  (handle of x[i]; no gate)
  %65 = call i32 @cq_template_zext_i1_to_i32(i32 %64)    ; IR: %52 = zext nneg i8 %51 to i32  [fresh rail]
  %66 = trunc nuw nsw i64 %61 to i32    ; IR: %53  (classical)
  %67 = call i32 @cq_template_shl_i32_hl(i32 %65, i32 %66)    ; IR: %54 = shl nuw i32 %52, %53  [fresh rail]
  %68 = call i32 @cq_template_or_i32(i32 %67, i32 %62)    ; IR: %55 = or i32 %54, %49  [fresh rail]
  call void @cqrt_push(i32 %62)    ; IR: trip-local rails on the handle stack
  call void @cqrt_push(i32 %65)    ; IR: ...
  call void @cqrt_push(i32 %67)    ; IR: ...
  %69 = add nuw nsw i64 %61, 1    ; IR: %56  (classical)
  %70 = icmp eq i64 %69, %4    ; IR: %57  (classical)
  br i1 %70, label %71, label %60    ; IR: br i1 %57, label %58, label %47

71:; IR: block %58
  %72 = phi i32 [ %59, %58 ], [ %68, %60 ]    ; IR: %59 = phi i32 [ 0, %46 ], [ %55, %47 ]
  %73 = call i32 @cq_template_icmp_eq_i32_hl(i32 %72, i32 0)    ; IR: %60 = icmp eq i32 %59, 0  [the R0 flag]
  call void @cqrt_not_i1(i32 %73)    ; IR: bracket: block %70 is the FALSE edge of br i1 %60 (rule 8)
  call void @cqrt_rz_i1(i32 %73, double 0x400921FB54442D18)    ; IR: block %70: cq_phi(pi)  [R0: kickback under v != 0]
  call void @cqrt_not_i1(i32 %73)    ; IR: bracket
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %73, i32 %72, i32 0)    ; IR: uncompute %60
  call void @cqrt_free(i32 %73)    ; IR: release the flag (|0>)
  br i1 %12, label %74, label %87    ; IR: (mirror of R0's value(x) loop iff it ran, before A rotates the cells)

74:; IR: reverse loop over R0's value(x) trips
  %75 = phi i64 [ 0, %71 ], [ %85, %74 ]    ; IR: reverse trip index
  %76 = phi i32 [ %72, %71 ], [ %79, %74 ]    ; IR: %55 of the trip being undone
  %77 = call i32 @cqrt_pop()    ; IR: the trip's shl rail (%54)
  %78 = call i32 @cqrt_pop()    ; IR: the trip's zext rail (%52)
  %79 = call i32 @cqrt_pop()    ; IR: the trip's incoming accumulator (%49)
  %80 = xor i64 %75, -1    ; IR: (classical: -1 - k)
  %81 = add nsw i64 %4, %80    ; IR: i of the trip being undone = nq - 1 - k  (classical)
  %82 = getelementptr inbounds i32, ptr %5, i64 %81    ; IR: (slot of x[i])
  %83 = load i32, ptr %82, align 4    ; IR: the trip's x[i] handle, reloaded (unchanged: A has not run yet)
  %84 = trunc nuw nsw i64 %81 to i32    ; IR: %53 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %76, i32 %77, i32 %79)    ; IR: uncompute %55
  call void @cqrt_free(i32 %76)    ; IR: release the %55 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %77, i32 %78, i32 %84)    ; IR: uncompute %54
  call void @cqrt_free(i32 %77)    ; IR: release the %54 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %78, i32 %83)    ; IR: uncompute %52
  call void @cqrt_free(i32 %78)    ; IR: release the %52 rail (|0>)
  %85 = add nuw nsw i64 %75, 1    ; IR: (classical)
  %86 = icmp eq i64 %85, %4    ; IR: (classical)
  br i1 %86, label %87, label %74    ; IR: (classical; the last pop %rpa is %seedR)

87:; IR: block %71 (the join after R0)
  call void @cqrt_free(i32 %59)    ; IR: release incoming 0 of phis %49 / %59 (the seed; never written, |0>; rule 7)
  br i1 %14, label %97, label %94    ; IR: br i1 %14, label %75, label %72

88:; IR: block %61  (A^dag: the Ry(-pi/2) loop, classical bound nq)
  %89 = phi i64 [ %92, %88 ], [ 0, %57 ]    ; IR: %62  (classical i)
  %90 = getelementptr inbounds i32, ptr %5, i64 %89    ; IR: %63  (slot of x[i])
  %91 = load i32, ptr %90, align 4    ; IR: %64 = load i8, ptr %63; %65 = trunc to i1  (handle of x[i]; no gate)
  call void @cqrt_ry_i1(i32 %91, double 0xBFF921FB54442D18)    ; IR: %66 = cq_theta_i1(%65, -pi/2)  [A^dag: Ry(-pi/2) in place on x[i]]; %67/store: handle unchanged
  %92 = add nuw nsw i64 %89, 1    ; IR: %68  (classical)
  %93 = icmp eq i64 %92, %15    ; IR: %69  (classical)
  br i1 %93, label %58, label %88    ; IR: br i1 %69, label %46, label %61

94:; IR: block %72  (the outer latch)
  %95 = add nuw nsw i32 %28, 1    ; IR: %73  (classical)
  %96 = icmp eq i32 %95, %2    ; IR: %74  (classical)
  br i1 %96, label %23, label %27    ; IR: br i1 %74, label %24, label %28

97:; IR: block %75  (A: the Ry(pi/2) loop, classical bound nq)
  %98 = phi i64 [ %101, %97 ], [ 0, %87 ]    ; IR: %76  (classical i)
  %99 = getelementptr inbounds i32, ptr %5, i64 %98    ; IR: %77  (slot of x[i])
  %100 = load i32, ptr %99, align 4    ; IR: %78 = load i8, ptr %77; %79 = trunc to i1  (handle of x[i]; no gate)
  call void @cqrt_ry_i1(i32 %100, double 0x3FF921FB54442D18)    ; IR: %80 = cq_theta_i1(%79, pi/2)  [A: Ry(pi/2) in place on x[i]]; %81/store: handle unchanged
  %101 = add nuw nsw i64 %98, 1    ; IR: %82  (classical)
  %102 = icmp eq i64 %101, %16    ; IR: %83  (classical)
  br i1 %102, label %94, label %97    ; IR: br i1 %83, label %72, label %75

103:; IR: block %84
  %104 = phi i32 [ 0, %23 ], [ %114, %105 ]    ; IR: %85  (classical m)
  ret i32 %104    ; IR: ret i32 %85

105:; IR: block %86  (the measure loop, classical bound nq)
  %106 = phi i64 [ 0, %25 ], [ %115, %105 ]    ; IR: %87  (classical i)
  %107 = phi i32 [ 0, %25 ], [ %114, %105 ]    ; IR: %88  (classical m)
  %108 = getelementptr inbounds i32, ptr %5, i64 %106    ; IR: %89  (slot of x[i])
  %109 = load i32, ptr %108, align 4    ; IR: %90 = load i8, ptr %89; %91 = trunc to i1  (handle of x[i])
  %110 = call i1 @cqrt_measure_i1(i32 %109)    ; IR: %92 = cq_measure_i1(%91)
  %111 = zext i1 %110 to i32    ; IR: %93  (classical)
  %112 = trunc nuw nsw i64 %106 to i32    ; IR: %94  (classical)
  %113 = shl nuw i32 %111, %112    ; IR: %95  (classical)
  %114 = or i32 %113, %107    ; IR: %96  (classical)
  %115 = add nuw nsw i64 %106, 1    ; IR: %97  (classical)
  %116 = icmp eq i64 %115, %26    ; IR: %98  (classical)
  br i1 %116, label %103, label %105    ; IR: br i1 %98, label %84, label %86
}

declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_not_i1(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cq_template_zext_i1_to_i32_unc(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
