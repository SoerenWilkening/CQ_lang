; HAND-WRITTEN. Rules: 20 (bool x[nq] and y[nq] are runtime-sized slot arrays: one `alloca i32, nq` of i1 handle cells each,
; as 74), 2 (cq_theta(false, pi/2), -O1's constant-propagated init, mints alloc_i1(0) + ry_i1 and the handle is stored in
; the cell; the second cq_theta rotates the cell's rail in place), 14 (every loop has the classical bound nq and stays a
; ROLLED classical loop), 4 (the oracle bit y[i] = x[i] ^ (x[j] & (s >> i) & 1), at -O1's widths: zext_i1_to_i32 of x[j]
; once, then per trip zext_i1_to_i32 of x[i], and_i32_hl against the classical (s >> i), icmp_ne_i32 of the two: every
; one a fresh rail; the icmp rail IS the output register y[i] and is stored into y's cell), 5 (the two per-trip rails are
; uncomputed in their own trip right after the icmp, their last consumer; nothing is carried, so no handle stack is needed;
; the hoisted x[j] view is uncomputed at the loop exit; all of it before the Ry(-pi/2) loop rotates x), 3 (the cttz/select
; computing j and the lshr of s are classical).
; Checked: x[0..nq-1] (measured after H^n) and y[0..nq-1] (the output register f(x), measured).
; Clean: the x[j] view, and per trip the x[i] view and the and rail (2 * nq + 1 rails).
; Kept: x[0..nq-1] and y[0..nq-1] (all measured). y stays entangled with x by construction (it is f(x)); it is a user
;   register, not garbage.
; Rotations: Ry(pi/2) on x[0..nq-1] (control 1); Ry(-pi/2) on x[0..nq-1] (control 1). No phase gate.
; Expected: f(x) = x ^ (x_j ? s : 0) satisfies f(x) = f(x ^ s), so every outcome m of x satisfies m . s = 0 (mod 2) and is
;   uniform over that subspace (2^(nq-1) values for s != 0); the y outcome is uniform over the image of f and equals f of
;   the collapsed coset. Replayed (state vector over the trace): simon(3, 5) -> m in {0, 2, 5, 7}, p = 1/4 each, for each m
;   y uniform over the 4 values with y_0 = 0; simon(4, 6) -> m in {0, 1, 6, 7, 8, 9, 14, 15}, p = 1/8 each, y uniform over
;   the 8 values with y_1 = 0; every free hits |0>. Return value m | (y << 16).
; -O1 keeps the three loops in source order: the oracle loop reads x's cells after the Ry(pi/2) loop and before the
; Ry(-pi/2) loop, so every gate of the oracle is emitted at the position of the instruction it lowers; no instruction is
; moved across a rotation. LICM hoisted the load of x[j] and its zext out of the oracle loop into the guarded preheader %14:
; that rail is computed once and read by every trip. The `(s >> i) & zext(x[j])` keeps all 32 bits of s >> i, but x[j] is 0
; or 1, so the and rail is ((s >> i) & 1) & x[j]; `icmp ne` against zext(x[i]) is the xor of two bits. The measurement loops
; read the cells (handles unchanged) and measure with cqrt_measure_i1.
source_filename = "simon.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @simon(i32 noundef %0, i32 noundef %1) {
  %3 = zext i32 %0 to i64    ; IR: %3 = zext i32 %0 to i64  (classical cell count)
  %4 = alloca i32, i64 %3, align 16    ; IR: %4 = alloca i8, i64 %3  (slot array of runtime length nq: one i1 handle per cell of x; rule 20)
  %5 = alloca i32, i64 %3, align 16    ; IR: %5 = alloca i8, i64 %3  (slot array of runtime length nq: one i1 handle per cell of y)
  %6 = icmp eq i32 %1, 0    ; IR: %6  (classical)
  %7 = call i32 @llvm.cttz.i32(i32 %1, i1 true)    ; IR: %7 = llvm.cttz.i32(%1, true)  (classical)
  %8 = select i1 %6, i32 0, i32 %7    ; IR: %8  (classical j)
  %9 = icmp sgt i32 %0, 0    ; IR: %9  (classical)
  br i1 %9, label %10, label %18    ; IR: br i1 %9, label %10, label %12

10:; IR: block %10
  %11 = zext nneg i32 %0 to i64    ; IR: %11  (classical bound)
  br label %12    ; IR: br label %20

12:; IR: block %20  (x[i] = false; H^n: the Ry(pi/2) loop, classical bound nq)
  %13 = phi i64 [ 0, %10 ], [ %16, %12 ]    ; IR: %21  (classical i)
  %14 = getelementptr inbounds i32, ptr %4, i64 %13    ; IR: %22  (slot of x[i])
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: store i8 0, ptr %22; %23 = cq_theta_i1(false, pi/2)  [register x[i], minted from the literal false]
  call void @cqrt_ry_i1(i32 %15, double 0x3FF921FB54442D18)    ; IR: %23 = cq_theta_i1(false, pi/2)  [Ry(pi/2) on x[i]]
  store i32 %15, ptr %14, align 4    ; IR: %24 = zext; store i8 %24, ptr %22  (the cell holds the handle of x[i])
  %16 = add nuw nsw i64 %13, 1    ; IR: %25  (classical)
  %17 = icmp eq i64 %16, %11    ; IR: %26  (classical)
  br i1 %17, label %18, label %12    ; IR: br i1 %26, label %12, label %20

18:; IR: block %12
  %19 = icmp sgt i32 %0, 0    ; IR: %13  (classical)
  br i1 %19, label %20, label %39    ; IR: br i1 %13, label %14, label %27

20:; IR: block %14  (the oracle loop's preheader)
  %21 = zext nneg i32 %8 to i64    ; IR: %15  (classical)
  %22 = getelementptr inbounds i32, ptr %4, i64 %21    ; IR: %16  (slot of x[j])
  %23 = load i32, ptr %22, align 4    ; IR: %17 = load i8, ptr %16  (handle of x[j]; no gate)
  %24 = call i32 @cq_template_zext_i1_to_i32(i32 %23)    ; IR: %18 = zext nneg i8 %17 to i32  [x[j] widened into a fresh rail]
  %25 = zext nneg i32 %0 to i64    ; IR: %19  (classical bound)
  br label %26    ; IR: br label %31

26:; IR: block %31  (the oracle: y[i] = x[i] ^ (x[j] & s_i), classical bound nq)
  %27 = phi i64 [ 0, %20 ], [ %36, %26 ]    ; IR: %32  (classical i)
  %28 = getelementptr inbounds i32, ptr %4, i64 %27    ; IR: %33  (slot of x[i])
  %29 = load i32, ptr %28, align 4    ; IR: %34 = load i8, ptr %33  (handle of x[i]; no gate)
  %30 = call i32 @cq_template_zext_i1_to_i32(i32 %29)    ; IR: %35 = zext nneg i8 %34 to i32  [fresh rail]
  %31 = trunc nuw nsw i64 %27 to i32    ; IR: %36  (classical)
  %32 = lshr i32 %1, %31    ; IR: %37 = lshr i32 %1, %36  (classical s >> i)
  %33 = call i32 @cq_template_and_i32_hl(i32 %24, i32 %32)    ; IR: %38 = and i32 %37, %18  [commutative: handle first; fresh rail]
  %34 = call i32 @cq_template_icmp_ne_i32(i32 %33, i32 %30)    ; IR: %39 = icmp ne i32 %38, %35  [fresh i1 rail: the register y[i]]
  %35 = getelementptr inbounds i32, ptr %5, i64 %27    ; IR: %40  (slot of y[i])
  store i32 %34, ptr %35, align 4    ; IR: %41 = zext i1 %39 to i8; store i8 %41, ptr %40  (the cell holds the handle of y[i])
  call void @cq_template_and_i32_hl_unc(i32 %33, i32 %24, i32 %32)    ; IR: uncompute %38 (its last consumer was %39)
  call void @cqrt_free(i32 %33)    ; IR: release the %38 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %30, i32 %29)    ; IR: uncompute %35
  call void @cqrt_free(i32 %30)    ; IR: release the %35 rail (|0>)
  %36 = add nuw nsw i64 %27, 1    ; IR: %42  (classical)
  %37 = icmp eq i64 %36, %25    ; IR: %43  (classical)
  br i1 %37, label %38, label %26    ; IR: br i1 %43, label %27, label %31

38:; IR: edge %31 -> %27 (the oracle loop's exit)
  call void @cq_template_zext_i1_to_i32_unc(i32 %24, i32 %23)    ; IR: uncompute %18 after its last consumer (x[j] unchanged: the rotation comes next)
  call void @cqrt_free(i32 %24)    ; IR: release the %18 rail (|0>)
  br label %39    ; IR: br label %27

39:; IR: block %27
  %40 = icmp sgt i32 %0, 0    ; IR: %28  (classical)
  br i1 %40, label %41, label %43    ; IR: br i1 %28, label %29, label %44

41:; IR: block %29
  %42 = zext nneg i32 %0 to i64    ; IR: %30  (classical bound)
  br label %47    ; IR: br label %48

43:; IR: block %44
  %44 = icmp sgt i32 %0, 0    ; IR: %45  (classical)
  br i1 %44, label %45, label %53    ; IR: br i1 %45, label %46, label %57

45:; IR: block %46
  %46 = zext nneg i32 %0 to i64    ; IR: %47  (classical bound)
  br label %58    ; IR: br label %62

47:; IR: block %48  (H^n: the Ry(-pi/2) loop, classical bound nq)
  %48 = phi i64 [ 0, %41 ], [ %51, %47 ]    ; IR: %49  (classical i)
  %49 = getelementptr inbounds i32, ptr %4, i64 %48    ; IR: %50  (slot of x[i])
  %50 = load i32, ptr %49, align 4    ; IR: %51 = load i8, ptr %50; %52 = trunc to i1  (handle of x[i]; no gate)
  call void @cqrt_ry_i1(i32 %50, double 0xBFF921FB54442D18)    ; IR: %53 = cq_theta_i1(%52, -pi/2)  [Ry(-pi/2) in place on x[i]]; %54/store: handle unchanged
  %51 = add nuw nsw i64 %48, 1    ; IR: %55  (classical)
  %52 = icmp eq i64 %51, %42    ; IR: %56  (classical)
  br i1 %52, label %43, label %47    ; IR: br i1 %56, label %44, label %48

53:; IR: block %57
  %54 = phi i32 [ 0, %43 ], [ %67, %58 ]    ; IR: %58  (classical m)
  %55 = icmp sgt i32 %0, 0    ; IR: %59  (classical)
  br i1 %55, label %56, label %72    ; IR: br i1 %59, label %60, label %77

56:; IR: block %60
  %57 = zext nneg i32 %0 to i64    ; IR: %61  (classical bound)
  br label %75    ; IR: br label %80

58:; IR: block %62  (measure x, classical bound nq)
  %59 = phi i64 [ 0, %45 ], [ %68, %58 ]    ; IR: %63  (classical i)
  %60 = phi i32 [ 0, %45 ], [ %67, %58 ]    ; IR: %64  (classical m)
  %61 = getelementptr inbounds i32, ptr %4, i64 %59    ; IR: %65  (slot of x[i])
  %62 = load i32, ptr %61, align 4    ; IR: %66 = load i8, ptr %65; %67 = trunc to i1  (handle of x[i])
  %63 = call i1 @cqrt_measure_i1(i32 %62)    ; IR: %68 = cq_measure_i1(%67)
  %64 = zext i1 %63 to i32    ; IR: %69  (classical)
  %65 = trunc nuw nsw i64 %59 to i32    ; IR: %70  (classical)
  %66 = shl nuw i32 %64, %65    ; IR: %71  (classical)
  %67 = or i32 %66, %60    ; IR: %72  (classical)
  %68 = add nuw nsw i64 %59, 1    ; IR: %73  (classical)
  %69 = icmp eq i64 %68, %46    ; IR: %74  (classical)
  br i1 %69, label %53, label %58    ; IR: br i1 %74, label %57, label %62

70:; IR: block %75
  %71 = shl i32 %84, 16    ; IR: %76  (classical)
  br label %72    ; IR: br label %77

72:; IR: block %77
  %73 = phi i32 [ 0, %53 ], [ %71, %70 ]    ; IR: %78  (classical)
  %74 = or i32 %73, %54    ; IR: %79  (classical)
  ret i32 %74    ; IR: ret i32 %79

75:; IR: block %80  (measure y, classical bound nq)
  %76 = phi i64 [ 0, %56 ], [ %85, %75 ]    ; IR: %81  (classical i)
  %77 = phi i32 [ 0, %56 ], [ %84, %75 ]    ; IR: %82  (classical f)
  %78 = getelementptr inbounds i32, ptr %5, i64 %76    ; IR: %83  (slot of y[i])
  %79 = load i32, ptr %78, align 4    ; IR: %84 = load i8, ptr %83; %85 = trunc to i1  (handle of y[i])
  %80 = call i1 @cqrt_measure_i1(i32 %79)    ; IR: %86 = cq_measure_i1(%85)  [y[i] measured; its rail stays allocated]
  %81 = zext i1 %80 to i32    ; IR: %87  (classical)
  %82 = trunc nuw nsw i64 %76 to i32    ; IR: %88  (classical)
  %83 = shl nuw i32 %81, %82    ; IR: %89  (classical)
  %84 = or i32 %83, %77    ; IR: %90  (classical)
  %85 = add nuw nsw i64 %76, 1    ; IR: %91  (classical)
  %86 = icmp eq i64 %85, %57    ; IR: %92  (classical)
  br i1 %86, label %70, label %75    ; IR: br i1 %92, label %75, label %80
}

declare i32 @llvm.cttz.i32(i32, i1 immarg)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cq_template_zext_i1_to_i32_unc(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ne_i32(i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
