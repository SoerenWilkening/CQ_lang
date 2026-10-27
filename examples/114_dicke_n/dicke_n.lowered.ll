; HAND-WRITTEN. Rules: 20 (`bool q[n]` is a runtime-sized slot array: one `alloca i32, n` of handle cells, every index
; classical; the init loop's classical store makes each cell a seed rail, homogeneous cells), 4 (every `q[m-1] ^= q[..]`
; is cq_template_xor_i1 into a fresh rail that becomes the cell's handle: no in-place CNOT on a user register), 6 (the
; slot's old handle is dead after the store, and t_new = t_old ^ c is a bijection in t_old, so the old rail is cleaned at
; once: compute t_old = t_new ^ c fresh, cqrt_copy_i1 it out, uncompute, free), 10 (CRy / CCRy are cqrt_ry_i1_controlled
; on the cell's current rail; the rotated rail is frozen), 14 (classical-bound loops: the m-loop and the l-loop stay
; rolled; every trip-local rail is cleaned inside its trip, so nothing is pushed and there is no reverse loop), 7, 5, 2, 3.
; Checked: q[0..n-1] (the n measured cells: each trip of the measure loop loads the cell's current handle and measures
; it, IR %101; q[i] in bit i of the returned int, n <= 31).
; Clean: per m-trip, the two superseded rails of q[m-1] (IR %34/%36 -> %37, %52 -> %53) and their rule-6 temporaries;
; per l-trip, the two superseded rails of q[m-1] (IR %65 -> %66, %88 -> %89), their rule-6 temporaries and the CCRy flag
; chain (IR %68, %72, %73, %74); all uncomputed and freed inside the trip that minted them.
; Kept: none beyond the n measured cell rails.
; Rotations: per trip m = n .. 2: (CRy, q[m-2], 2*acos(sqrt(1/m)), q[m-1] ^ q[m-2]) (q[m-1] after its first xor); then
; per l = 2 .. min(k, m-1): (CCRy, q[m-1-l], 2*acos(sqrt(l/m)), 2*(q[m-1] ^ q[m-1-l]) + q[m-l] == 3) (q[m-1] after the
; block's first xor). All angles are computed at run time from the classical trip counters m and l.
; Bärtschi–Eidenbenz |D^n_k> with n and k function inputs (113 is the fixed-size N = 4, K = 2 instance, whose classical
; prefix -O1 folded): `bool q[n]` is the register array of 58/59 at runtime length, a classical SLOT array holding one
; handle per cell (`alloca i8, n` becomes `alloca i32, n`; -O1's byte GEPs over i8 cells are cell indices). The init loop
; mints each cell's rail with its classical start value `i >= n - k` (rule 7 seed rails; nothing folds, so every gate of
; the construction appears). Both loops have classical bounds and stay rolled exactly as -O1 shaped them: the m-loop
; (header %28, latch %22) and the inner l-loop (header %60, do-while latch `l < kk` %92, entered unless kk < 2 %55).
; A cell load is the handle, no gate. `q[m-1] ^= q[..]` is loaded, xor'd (-O1: `icmp ne i8`) and stored back over the
; same slot: the xor is cq_template_xor_i1 into a fresh rail, the store writes that handle into the slot, and the slot's
; old handle (no other reference) is cleaned by rule 6 right there, while the control is still unchanged. The 2-qubit
; block's `if (q[m-1])` is the cell's own (new) rail, the condition of a controlled Ry on q[m-2] (59's bare-rail
; control); its arm (blocks %39) is flattened into the trip. The 3-qubit block's `s == 3` is the strict-Bennett flag
; chain (select, zext, or, icmp) into fresh rails, the CCRy on q[m-1-l] under the flag, then the chain uncomputed and
; freed (its operands q[m-1], q[m-l] were not touched by the rotation; l >= 2 keeps the three cells distinct) BEFORE the
; xor that supersedes q[m-1]. The store of a rotated cell's unchanged handle emits nothing. The measured bits are packed
; classically (`r |= bit << i`). Per call: n seed rails, 2 CRy-block xors per m and 2 xors per l, each with its rule-6
; clean-up; the replay of dicke_n(4,2), (5,2), (5,3) gives every weight-k string with amplitude +1/sqrt(C(n,k)).
source_filename = "dicke_n.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @dicke_n(i32 noundef %0, i32 noundef %1) {
  %3 = zext i32 %0 to i64    ; IR: %3  (classical n)
  %4 = alloca i32, i64 %3, align 16    ; IR: %4 = alloca i8, i64 %3  (runtime-sized classical slots: one handle per cell)
  %5 = icmp sgt i32 %0, 0    ; IR: %5  (classical)
  br i1 %5, label %6, label %10    ; IR: br i1 %5

6:
  %7 = sub nsw i32 %0, %1    ; IR: %7 = n - k  (classical)
  %8 = sext i32 %7 to i64    ; IR: %8  (classical)
  %9 = zext nneg i32 %0 to i64    ; IR: %9  (classical)
  br label %15    ; IR: br label %15

10:
  %11 = getelementptr i32, ptr %4, i64 -2    ; IR: %11 = getelementptr i8, ptr %4, i64 -2  (base of q[m-2] = q - 2 + m)
  %12 = icmp sgt i32 %0, 1    ; IR: %12  (classical)
  br i1 %12, label %13, label %24    ; IR: br i1 %12

13:
  %14 = zext nneg i32 %0 to i64    ; IR: %14  (classical: m starts at n)
  br label %28    ; IR: br label %28

15:
  %16 = phi i64 [ 0, %6 ], [ %20, %15 ]    ; IR: %16  (classical i)
  %17 = icmp sge i64 %16, %8    ; IR: %17 = i >= n - k  (classical: the cell's start value)
  %18 = getelementptr inbounds i32, ptr %4, i64 %16    ; IR: %18  (slot of q[i])
  %19 = call i32 @cqrt_alloc_i1(i1 %17)    ; IR: %19/store i8 %19, ptr %18: q[i] = (i >= n - k)  [register q[i], seeded with its classical start value]
  store i32 %19, ptr %18, align 4    ; IR: store i8 %19, ptr %18  (the slot holds the handle)
  %20 = add nuw nsw i64 %16, 1    ; IR: %20  (classical)
  %21 = icmp eq i64 %20, %9    ; IR: %21  (classical)
  br i1 %21, label %10, label %15    ; IR: br i1 %21

22:
  %23 = icmp sgt i64 %29, 2    ; IR: %23 = m > 2  (classical)
  br i1 %23, label %28, label %24    ; IR: br i1 %23

24:
  %25 = icmp sgt i32 %0, 0    ; IR: %25  (classical)
  br i1 %25, label %26, label %82    ; IR: br i1 %25

26:
  %27 = zext nneg i32 %0 to i64    ; IR: %27  (classical)
  br label %84    ; IR: br label %95

28:
  %29 = phi i64 [ %14, %13 ], [ %30, %22 ]    ; IR: %29  (classical m)
  %30 = add nsw i64 %29, -1    ; IR: %30 = m - 1  (classical)
  %31 = trunc nuw nsw i64 %30 to i32    ; IR: %31  (classical)
  %32 = call i32 @llvm.smin.i32(i32 %31, i32 %1)    ; IR: %32 = kk = min(k, m - 1)  (classical)
  %33 = getelementptr i32, ptr %11, i64 %29    ; IR: %33  (slot of q[m-2])
  %34 = load i32, ptr %33, align 4    ; IR: %34 = load i8, ptr %33  (handle of q[m-2]; no gate)
  %35 = getelementptr inbounds i32, ptr %4, i64 %30    ; IR: %35  (slot of q[m-1])
  %36 = load i32, ptr %35, align 4    ; IR: %36 = load i8, ptr %35  (handle of q[m-1])
  %37 = call i32 @cq_template_xor_i1(i32 %34, i32 %36)    ; IR: %37 = icmp ne i8 %36, %34: q[m-1] ^= q[m-2], out of place into a fresh rail  [q[m-1]'s new rail]
  store i32 %37, ptr %35, align 4    ; IR: %38/store i8 %38, ptr %35  (the slot takes the new handle)
  %38 = call i32 @cq_template_xor_i1(i32 %37, i32 %34)    ; IR: rule 6: the slot's old handle %36 is dead and %37 = %36 ^ %34 is a bijection in it: t = new ^ control = its value
  call void @cqrt_copy_i1(i32 %38, i32 %36)    ; IR: rule 6: the old rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %38, i32 %37, i32 %34)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %38)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %36)    ; IR: release the superseded rail of q[m-1] (|0>)
  %39 = trunc nuw nsw i64 %29 to i32    ; IR: %42  (classical)
  %40 = uitofp nneg i32 %39 to double    ; IR: %43  (classical)
  %41 = fdiv double 1.000000e+00, %40    ; IR: %44 = 1 / m  (classical)
  %42 = call double @llvm.sqrt.f64(double %41)    ; IR: %45  (classical)
  %43 = call double @llvm.acos.f64(double %42)    ; IR: %46  (classical)
  %44 = fmul double %43, 2.000000e+00    ; IR: %47  (classical angle; the arm's pure ops hoisted)
  call void @cqrt_ry_i1_controlled(i32 %37, i32 %34, double %44)    ; IR: br i1 %37 -> block %39: %40 = load q[m-2]; %48 = cq_theta_i1(%41, %47): the condition is q[m-1]'s own rail, the target q[m-2]  [CRy]; %49/store: handle unchanged
  %45 = load i32, ptr %33, align 4    ; IR: %51 = load i8, ptr %33  (handle of q[m-2])
  %46 = load i32, ptr %35, align 4    ; IR: %52 = load i8, ptr %35  (handle of q[m-1])
  %47 = call i32 @cq_template_xor_i1(i32 %45, i32 %46)    ; IR: %53 = icmp ne i8 %52, %51: q[m-1] ^= q[m-2], out of place  [q[m-1]'s new rail]
  store i32 %47, ptr %35, align 4    ; IR: %54/store i8 %54, ptr %35  (the slot takes the new handle)
  %48 = call i32 @cq_template_xor_i1(i32 %47, i32 %45)    ; IR: rule 6: the slot's old handle %52 is dead and %53 = %52 ^ %51 is a bijection in it: t = new ^ control = its value
  call void @cqrt_copy_i1(i32 %48, i32 %46)    ; IR: rule 6: the old rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %48, i32 %47, i32 %45)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %48)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %46)    ; IR: release the superseded rail of q[m-1] (|0>)
  %49 = icmp slt i32 %32, 2    ; IR: %55 = kk < 2  (classical: no 3-qubit block)
  br i1 %49, label %22, label %50    ; IR: br i1 %55

50:
  %51 = trunc nuw nsw i64 %29 to i32    ; IR: %57  (classical)
  %52 = uitofp nneg i32 %51 to double    ; IR: %58 = (double)m  (classical)
  %53 = zext nneg i32 %32 to i64    ; IR: %59  (classical)
  br label %54    ; IR: br label %60

54:
  %55 = phi i64 [ 2, %50 ], [ %80, %54 ]    ; IR: %61  (classical l)
  %56 = sub nsw i64 %30, %55    ; IR: %62 = m - 1 - l  (classical)
  %57 = getelementptr inbounds i32, ptr %4, i64 %56    ; IR: %63  (slot of q[m-1-l])
  %58 = load i32, ptr %57, align 4    ; IR: %64  (handle of q[m-1-l])
  %59 = load i32, ptr %35, align 4    ; IR: %65  (handle of q[m-1])
  %60 = call i32 @cq_template_xor_i1(i32 %58, i32 %59)    ; IR: %66 = icmp ne i8 %65, %64: q[m-1] ^= q[m-1-l], out of place  [q[m-1]'s new rail]
  store i32 %60, ptr %35, align 4    ; IR: %67/store i8 %67, ptr %35  (the slot takes the new handle)
  %61 = call i32 @cq_template_xor_i1(i32 %60, i32 %58)    ; IR: rule 6: the slot's old handle %65 is dead and %66 = %65 ^ %64 is a bijection in it: t = new ^ control = its value
  call void @cqrt_copy_i1(i32 %61, i32 %59)    ; IR: rule 6: the old rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %61, i32 %60, i32 %58)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %61)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %59)    ; IR: release the superseded rail of q[m-1] (|0>)
  %62 = call i32 @cq_template_select_i32_ll(i32 %60, i32 2, i32 0)    ; IR: %68 = select i1 %66, i32 2, i32 0  (2 * q[m-1])
  %63 = sub nsw i64 %29, %55    ; IR: %69 = m - l  (classical)
  %64 = getelementptr inbounds i32, ptr %4, i64 %63    ; IR: %70  (slot of q[m-l])
  %65 = load i32, ptr %64, align 4    ; IR: %71  (handle of q[m-l])
  %66 = call i32 @cq_template_zext_i1_to_i32(i32 %65)    ; IR: %72 = zext nneg i8 %71 to i32
  %67 = call i32 @cq_template_or_i32(i32 %62, i32 %66)    ; IR: %73 = or disjoint i32 %68, %72  (s)
  %68 = call i32 @cq_template_icmp_eq_i32_hl(i32 %67, i32 3)    ; IR: %74 = icmp eq i32 %73, 3  [the CCRy flag]
  %69 = load i32, ptr %57, align 4    ; IR: %76 = load i8, ptr %63  (handle of q[m-1-l])
  %70 = trunc nuw nsw i64 %55 to i32    ; IR: %78  (classical)
  %71 = uitofp nneg i32 %70 to double    ; IR: %79  (classical)
  %72 = fdiv double %71, %52    ; IR: %80 = l / m  (classical)
  %73 = call double @llvm.sqrt.f64(double %72)    ; IR: %81  (classical)
  %74 = call double @llvm.acos.f64(double %73)    ; IR: %82  (classical)
  %75 = fmul double %74, 2.000000e+00    ; IR: %83  (classical angle; the arm's pure ops hoisted)
  call void @cqrt_ry_i1_controlled(i32 %68, i32 %69, double %75)    ; IR: br i1 %74 -> block %75: %84 = cq_theta_i1(%77, %83)  [CCRy on q[m-1-l] under the flag]; %85/store: handle unchanged
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %68, i32 %67, i32 3)    ; IR: uncompute %74 (its operands are untouched by the rotation of q[m-1-l])
  call void @cqrt_free(i32 %68)    ; IR: release the %74 rail (|0>)
  call void @cq_template_or_i32_unc(i32 %67, i32 %62, i32 %66)    ; IR: uncompute %73
  call void @cqrt_free(i32 %67)    ; IR: release the %73 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %66, i32 %65)    ; IR: uncompute %72
  call void @cqrt_free(i32 %66)    ; IR: release the %72 rail (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %62, i32 %60, i32 2, i32 0)    ; IR: uncompute %68, before q[m-1] is superseded again
  call void @cqrt_free(i32 %62)    ; IR: release the %68 rail (|0>)
  %76 = load i32, ptr %57, align 4    ; IR: %87  (handle of q[m-1-l])
  %77 = load i32, ptr %35, align 4    ; IR: %88  (handle of q[m-1])
  %78 = call i32 @cq_template_xor_i1(i32 %76, i32 %77)    ; IR: %89 = icmp ne i8 %88, %87: q[m-1] ^= q[m-1-l], out of place  [q[m-1]'s new rail]
  store i32 %78, ptr %35, align 4    ; IR: %90/store i8 %90, ptr %35  (the slot takes the new handle)
  %79 = call i32 @cq_template_xor_i1(i32 %78, i32 %76)    ; IR: rule 6: the slot's old handle %88 is dead and %89 = %88 ^ %87 is a bijection in it: t = new ^ control = its value
  call void @cqrt_copy_i1(i32 %79, i32 %77)    ; IR: rule 6: the old rail ^= t -> |0>
  call void @cq_template_xor_i1_unc(i32 %79, i32 %78, i32 %76)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %79)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %77)    ; IR: release the superseded rail of q[m-1] (|0>)
  %80 = add nuw nsw i64 %55, 1    ; IR: %91  (classical)
  %81 = icmp ult i64 %55, %53    ; IR: %92 = l < kk  (classical)
  br i1 %81, label %54, label %22    ; IR: br i1 %92

82:
  %83 = phi i32 [ 0, %24 ], [ %93, %84 ]    ; IR: %94  (classical r)
  ret i32 %83    ; IR: ret i32 %94

84:
  %85 = phi i64 [ 0, %26 ], [ %94, %84 ]    ; IR: %96  (classical i)
  %86 = phi i32 [ 0, %26 ], [ %93, %84 ]    ; IR: %97  (classical r)
  %87 = getelementptr inbounds i32, ptr %4, i64 %85    ; IR: %98  (slot of q[i])
  %88 = load i32, ptr %87, align 4    ; IR: %99 = load i8; %100 = trunc to i1  (handle of q[i])
  %89 = call i1 @cqrt_measure_i1(i32 %88)    ; IR: %101 = cq_measure_i1(%100)
  %90 = zext i1 %89 to i32    ; IR: %102  (classical)
  %91 = trunc nuw nsw i64 %85 to i32    ; IR: %103  (classical)
  %92 = shl nuw i32 %90, %91    ; IR: %104 = bit << i  (classical)
  %93 = or i32 %92, %86    ; IR: %105 = r | (bit << i)  (classical)
  %94 = add nuw nsw i64 %85, 1    ; IR: %106  (classical)
  %95 = icmp eq i64 %94, %27    ; IR: %107  (classical)
  br i1 %95, label %82, label %84    ; IR: br i1 %107
}

declare i32 @llvm.smin.i32(i32, i32)
declare double @llvm.sqrt.f64(double)
declare double @llvm.acos.f64(double)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_copy_i1(i32, i32)
declare i32 @cq_template_xor_i1(i32, i32)
declare void @cq_template_xor_i1_unc(i32, i32, i32)
declare i1 @cqrt_measure_i1(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cq_template_zext_i1_to_i32_unc(i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
