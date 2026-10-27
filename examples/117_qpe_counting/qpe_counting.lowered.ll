; HAND-WRITTEN. Rules: 2, 4, 5, 8, 10, 12, 14, 19, 20, 22.
; Checked: m, the t counting bits c[j] (the rails behind the runtime-sized slot array %6; the measure loop loads each and
; measures it; c[j] lands in bit t-1-j).
; Clean: inside every __cq_q_grover_1000_ctl call: both value(x) accumulator walks (zext, shl, or rails and the |0> seed of
; each, pushed per trip and uncomputed by their mirror loops), the compare flags v == marked[k] (k = 0 .. nmark-1) and
; v == 0, the edge flags of the phase blocks, and is_marked's predicate chain (the seed a_0 = pred & v != marked[0] and
; every continue predicate a_k, the last included, rule 14 classical bound with a quantum exit); in the caller the
; QFT^-1 Toffoli flags (one per (k, j) pair).
; Kept: the nq work rails x[i]: never measured, rotated under control by A and A^dag inside the composite (frozen) and
; left entangled with the counting register; the t counting rails are measured.
; Rotations: (Ry, c[j], pi/2, 1) for j = 0..t-1; (Ry, x[i], pi/2, 1) for i = 0..nq-1; then for j = 0..t-1, repeated 2^j
; times (one controlled grover call each): (P, flag, pi, c[j] & v == marked[0]), and for k = 1..nmark-1
; (P, flag, pi, c[j] & v != marked[0] & .. & v != marked[k-1] & v == marked[k]) [O over the marked list, v = value(x)],
; (Ry, x[i], -pi/2, c[j]) for i = 0..nq-1 [A^dag], (P, flag, pi, c[j] & value(x) != 0) [R], (Ry, x[i], pi/2, c[j]) for
; i = 0..nq-1 [A]; then for j = t-1..0: (P, flag, -pi / 2^(k-j), c[k] & c[j]) for k = t-1..j+1, (P, c[j], pi, c[j])
; (rz_i1 on the bare rail), (Ry, c[j], pi/2, 1). nq <= 0 skips both value walks and R; nmark <= 0 skips O.
; Quantum counting (QPE on the Grover iterate), general size: nq, t and the marked list are inputs, so every register is
; a runtime-sized slot array (rule 20: `bool c[t], x[nq]` are `alloca i32, n` of handle cells) and every loop has a
; classical runtime bound (rule 14). The zero-fill loops -O1 turned into memsets are one seed rail alloc_i1(0) per cell
; (rules 20, 22). The defining operation is a CONTROLLED COMPOSITE U: `if (c[j]) grover(x, nq, marked, nmark)` where
; grover holds loops, rotations and phases. The condition is a bare rail loaded from slot j (59); the callee runs as a
; CONTROLLED CLONE (rule 19: the predicate is the first parameter) and the control is pushed into every gate of the
; composite: a rotation becomes cqrt_ry_i1_controlled on the control; a phase block becomes a kickback on a Toffoli flag
; pred & <edge predicate>, one kickback per incoming edge (the edges are disjoint, so the phases add). Clone mask 1000
; (§1.4) over (x, nq, marked, nmark): x is a pointer to a slot array of RUNTIME length whose cells all hold handles at
; the call; §1.4's one digit per cell cannot be spelled for a runtime length, so the pointer contributes ONE digit, 1;
; nq, marked (a classical int table) and nmark are classical. Inside grover: value(x) is the quantum accumulator of 28 over
; the cells (zext, shl, or into fresh rails, mirrored with the handle stack right after its consumers, before A^dag rotates
; the cells); its seed rail also stands for the phi incoming 0 of the nq <= 0 path. is_marked(v) is the early-return list
; loop with a classical bound and a quantum exit: -O1 peels trip 0 into the edge `marked[0] == v` -> %38 and keeps a loop
; whose exhausted edge carries %35 = false (classical: no phase) and whose found edge from %30 carries %35 = true, so each
; found edge is a kickback on a_k & (v == marked[k+1]); every trip computes its continue predicate as the general rule
; does (the last one is read by no gate: the exhausted edge carries no phase); every chain predicate is a function of the
; inputs and is uncomputed by the mirror (pop per trip), then the seed and the trip-0 compare. R = 2|0><0| - I is the kickback on
; pred & NOT (value == 0). The caller's part is the H^t and A loops, the classical repetition loop `for (k < 2^j)` (-O1
; skips j == 31 and runs smax(1 << j, 1) trips), the QFT^-1 (two nested branches c[k], c[j] are one Toffoli flag;
; `if (c[j]) cq_phi(pi)` is cqrt_rz_i1 directly on the bare rail) and the classical measure loop.
; Replayed on a state vector against exact QPE on G (every free asserted |0>; only the registers stay allocated): call 1
; (nq = 3, t = 4, marked {3, 5}): max |p - p_exact| = 1.4e-15, P(round(M~) = 2) = 0.6885; call 2 (nq = 3, t = 3,
; marked {1}): max |p - p_exact| = 9.4e-16, P(round(M~) = 1) = 0.9816. Off-corpus checks of the chain: nq = 3, t = 3,
; marked {1, 3, 5, 6} (two pushed trips) gives P(round(M~) = 4) = 1.0000, and nmark = 0 gives m = 0 with p = 1.
source_filename = "qpe_counting.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @qpe_counting(i32 noundef %0, i32 noundef %1, ptr noundef %2, i32 noundef %3) {
  %5 = zext i32 %1 to i64    ; IR: %5  (classical cell count t)
  %6 = alloca i32, i64 %5, align 16    ; IR: %6 = alloca i8, i64 %5  (runtime-sized slot array: one handle cell per c[j]; rule 20)
  %7 = zext i32 %0 to i64    ; IR: %7  (classical cell count nq)
  %8 = alloca i32, i64 %7, align 16    ; IR: %8 = alloca i8, i64 %7  (runtime-sized slot array: one handle cell per x[i]; rule 20)
  %9 = icmp sgt i32 %1, 0    ; IR: %9  (classical)
  br i1 %9, label %10, label %18    ; IR: br i1 %9, label %10, label %12

10:; IR: block %10
  %11 = zext nneg i32 %1 to i64    ; IR: %11  (classical memset length)
  br label %12

12:; IR: memset(%6, 0, %11), one fixed-index cell per trip (rule 22)
  %13 = phi i64 [ 0, %10 ], [ %16, %12 ]    ; IR: (classical cell index of the memset)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: memset: c[j] = 0  [register c[j]: the classical store materialises a seed rail, rule 20]
  %15 = getelementptr inbounds i32, ptr %6, i64 %13    ; IR: (slot j)
  store i32 %14, ptr %15, align 4    ; IR: memset  (slot j holds the handle of c[j])
  %16 = add nuw nsw i64 %13, 1    ; IR: (classical)
  %17 = icmp eq i64 %16, %11    ; IR: (classical: j + 1 == t)
  br i1 %17, label %18, label %12

18:; IR: block %12
  %19 = icmp sgt i32 %0, 0    ; IR: %13  (classical)
  br i1 %19, label %20, label %28    ; IR: br i1 %13, label %14, label %16

20:; IR: block %14
  %21 = zext nneg i32 %0 to i64    ; IR: %15  (classical memset length)
  br label %22

22:; IR: memset(%8, 0, %15), one fixed-index cell per trip (rule 22)
  %23 = phi i64 [ 0, %20 ], [ %26, %22 ]    ; IR: (classical cell index of the memset)
  %24 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: memset: x[i] = 0  [register x[i]]
  %25 = getelementptr inbounds i32, ptr %8, i64 %23    ; IR: (slot i)
  store i32 %24, ptr %25, align 4    ; IR: memset  (slot i holds the handle of x[i])
  %26 = add nuw nsw i64 %23, 1    ; IR: (classical)
  %27 = icmp eq i64 %26, %21    ; IR: (classical: i + 1 == nq)
  br i1 %27, label %28, label %22

28:; IR: block %16
  %29 = icmp sgt i32 %1, 0    ; IR: %17  (classical)
  br i1 %29, label %30, label %38    ; IR: br i1 %17, label %18, label %20

30:; IR: block %18
  %31 = zext nneg i32 %1 to i64    ; IR: %19  (classical)
  br label %32

32:; IR: block %24  (H^t, classical bound t)
  %33 = phi i64 [ 0, %30 ], [ %36, %32 ]    ; IR: %25  (classical j)
  %34 = getelementptr inbounds i32, ptr %6, i64 %33    ; IR: %26  (slot of c[j])
  %35 = load i32, ptr %34, align 4    ; IR: %27 = load i8, ptr %26; %28 = trunc to i1  (handle of c[j]; no gate)
  call void @cqrt_ry_i1(i32 %35, double 0x3FF921FB54442D18)    ; IR: %29 = cq_theta_i1(%28, pi/2)  [H|0>: Ry(pi/2) in place on c[j]]; %30/store: handle unchanged
  %36 = add nuw nsw i64 %33, 1    ; IR: %31  (classical)
  %37 = icmp eq i64 %36, %31    ; IR: %32  (classical)
  br i1 %37, label %38, label %32    ; IR: br i1 %32, label %20, label %24

38:; IR: block %20
  %39 = icmp sgt i32 %0, 0    ; IR: %21  (classical)
  br i1 %39, label %40, label %48    ; IR: br i1 %21, label %22, label %33

40:; IR: block %22
  %41 = zext nneg i32 %0 to i64    ; IR: %23  (classical)
  br label %42

42:; IR: block %37  (A, classical bound nq)
  %43 = phi i64 [ 0, %40 ], [ %46, %42 ]    ; IR: %38  (classical i)
  %44 = getelementptr inbounds i32, ptr %8, i64 %43    ; IR: %39  (slot of x[i])
  %45 = load i32, ptr %44, align 4    ; IR: %40 = load i8, ptr %39; %41 = trunc to i1  (handle of x[i]; no gate)
  call void @cqrt_ry_i1(i32 %45, double 0x3FF921FB54442D18)    ; IR: %42 = cq_theta_i1(%41, pi/2)  [A: Ry(pi/2) in place on x[i]]; %43/store: handle unchanged
  %46 = add nuw nsw i64 %43, 1    ; IR: %44  (classical)
  %47 = icmp eq i64 %46, %41    ; IR: %45  (classical)
  br i1 %47, label %48, label %42    ; IR: br i1 %45, label %33, label %37

48:; IR: block %33
  %49 = icmp sgt i32 %1, 0    ; IR: %34  (classical)
  br i1 %49, label %50, label %68    ; IR: br i1 %34, label %35, label %56

50:; IR: block %35
  %51 = zext nneg i32 %1 to i64    ; IR: %36  (classical)
  br label %52

52:; IR: block %46  (controlled G^(2^j), classical j)
  %53 = phi i64 [ 0, %50 ], [ %66, %65 ]    ; IR: %47  (classical j)
  %54 = icmp eq i64 %53, 31    ; IR: %48  (classical: 1 << 31 is negative, the k loop runs no trip)
  br i1 %54, label %65, label %55    ; IR: br i1 %48, label %62, label %49

55:; IR: block %49
  %56 = trunc nuw nsw i64 %53 to i32    ; IR: %50  (classical)
  %57 = shl nuw i32 1, %56    ; IR: %51  (classical 1 << j)
  %58 = getelementptr inbounds i32, ptr %6, i64 %53    ; IR: %52  (slot of c[j])
  %59 = load i32, ptr %58, align 4    ; IR: %53 = load i8, ptr %52; %54 = trunc to i1  (handle of c[j]: a bare rail, the control of block %67, loaded once per j)
  %60 = call i32 @llvm.smax.i32(i32 %57, i32 1)    ; IR: %55  (classical trip count of the k loop)
  br label %61    ; IR: br label %65

61:; IR: block %65  (classical k < 2^j)
  %62 = phi i32 [ 0, %55 ], [ %63, %61 ]    ; IR: %66  (classical k)
  call fastcc void @__cq_q_grover_1000_ctl(i32 %59, ptr %8, i32 %0, ptr %2, i32 %3)    ; IR: br i1 %54 -> block %67: call @grover(%8, %0, %2, %3)  [the controlled clone: every gate of G under the bare rail c[j]]
  %63 = add nuw nsw i32 %62, 1    ; IR: %69  (classical)
  %64 = icmp eq i32 %63, %60    ; IR: %70  (classical)
  br i1 %64, label %65, label %61    ; IR: br i1 %70, label %62, label %65

65:; IR: block %62
  %66 = add nuw nsw i64 %53, 1    ; IR: %63  (classical)
  %67 = icmp eq i64 %66, %51    ; IR: %64  (classical)
  br i1 %67, label %68, label %52    ; IR: br i1 %64, label %56, label %46

68:; IR: block %56  (QFT^-1 without the final swaps)
  %69 = add i32 %1, -1    ; IR: %57  (classical t - 1)
  %70 = icmp sgt i32 %1, 0    ; IR: %58  (classical)
  br i1 %70, label %71, label %99    ; IR: br i1 %58, label %59, label %77

71:; IR: block %59
  %72 = zext i32 %69 to i64    ; IR: %60  (classical)
  %73 = sext i32 %69 to i64    ; IR: %61  (classical)
  br label %74    ; IR: br label %71

74:; IR: block %71
  %75 = phi i64 [ %72, %71 ], [ %97, %94 ]    ; IR: %72  (classical j, t-1 down to 0)
  %76 = icmp slt i64 %75, %73    ; IR: %73  (classical: j < t - 1, the inner loop runs)
  br i1 %76, label %77, label %94    ; IR: br i1 %73, label %74, label %81

77:; IR: block %74
  %78 = getelementptr inbounds i32, ptr %6, i64 %75    ; IR: %75  (slot of c[j])
  %79 = trunc nuw nsw i64 %75 to i32    ; IR: %76  (classical)
  br label %80    ; IR: br label %85

80:; IR: block %85  (classical k = t-1 down to j+1)
  %81 = phi i32 [ %69, %77 ], [ %91, %80 ]    ; IR: %86  (classical k)
  %82 = zext nneg i32 %81 to i64    ; IR: %87  (classical)
  %83 = getelementptr inbounds i32, ptr %6, i64 %82    ; IR: %88  (slot of c[k])
  %84 = load i32, ptr %83, align 4    ; IR: %89 = load i8, ptr %88; %90 = trunc to i1  (handle of c[k]; no gate)
  %85 = load i32, ptr %78, align 4    ; IR: %92 = load i8, ptr %75; %93 = trunc to i1  (handle of c[j]; no gate)
  %86 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %94 = %90 & %93 (br i1 %90 -> block %91, br i1 %93 -> block %94)
  call void @cqrt_and_i1(i32 %84, i32 %85, i32 %86)    ; IR: one Toffoli flag (rule 8)
  %87 = sub nsw i32 %81, %79    ; IR: %95  (classical k - j)
  %88 = shl nuw i32 1, %87    ; IR: %96  (classical 1 << (k - j))
  %89 = sitofp i32 %88 to double    ; IR: %97  (classical)
  %90 = fdiv double 0xC00921FB54442D18, %89    ; IR: %98  (classical angle -pi / 2^(k-j))
  call void @cqrt_rz_i1(i32 %86, double %90)    ; IR: block %94: cq_phi(%98)  [kickback on the flag]
  call void @cqrt_and_i1(i32 %84, i32 %85, i32 %86)    ; IR: uncompute the %94 predicate
  call void @cqrt_free(i32 %86)    ; IR: release the flag (|0>)
  %91 = add nsw i32 %81, -1    ; IR: %100  (classical)
  %92 = sext i32 %91 to i64    ; IR: %101  (classical)
  %93 = icmp slt i64 %75, %92    ; IR: %102  (classical)
  br i1 %93, label %80, label %94    ; IR: br i1 %102, label %85, label %81

94:; IR: blocks %81, %103, %104
  %95 = getelementptr inbounds i32, ptr %6, i64 %75    ; IR: %82  (slot of c[j])
  %96 = load i32, ptr %95, align 4    ; IR: %83 = load i8, ptr %82; %84 = trunc to i1  (handle of c[j]: a bare rail)
  call void @cqrt_rz_i1(i32 %96, double 0x400921FB54442D18)    ; IR: br i1 %84 -> block %103: cq_phi(pi)  [phase on the bare rail itself: a diagonal gate on the register, no flag]
  call void @cqrt_ry_i1(i32 %96, double 0x3FF921FB54442D18)    ; IR: %105 = cq_theta_i1(%84, pi/2)  [Ry in place on c[j]]; %106/store: handle unchanged
  %97 = add nsw i64 %75, -1    ; IR: %107  (classical)
  %98 = icmp sgt i64 %75, 0    ; IR: %108  (classical)
  br i1 %98, label %74, label %99    ; IR: br i1 %108, label %71, label %77

99:; IR: block %77
  %100 = icmp sgt i32 %1, 0    ; IR: %78  (classical)
  br i1 %100, label %101, label %116    ; IR: br i1 %78, label %79, label %109

101:; IR: block %79
  %102 = zext nneg i32 %1 to i64    ; IR: %80  (classical)
  br label %103

103:; IR: block %111  (measure loop, classical)
  %104 = phi i64 [ 0, %101 ], [ %114, %103 ]    ; IR: %112  (classical j)
  %105 = phi i32 [ 0, %101 ], [ %113, %103 ]    ; IR: %113  (classical m)
  %106 = getelementptr inbounds i32, ptr %6, i64 %104    ; IR: %114  (slot of c[j])
  %107 = load i32, ptr %106, align 4    ; IR: %115 = load i8, ptr %114; %116 = trunc to i1  (handle of c[j])
  %108 = call i1 @cqrt_measure_i1(i32 %107)    ; IR: %117 = cq_measure_i1(%116)
  %109 = zext i1 %108 to i32    ; IR: %118  (classical)
  %110 = trunc i64 %104 to i32    ; IR: %119  (classical)
  %111 = sub i32 %69, %110    ; IR: %120  (classical t - 1 - j)
  %112 = shl nuw i32 %109, %111    ; IR: %121  (classical)
  %113 = or i32 %112, %105    ; IR: %122  (classical)
  %114 = add nuw nsw i64 %104, 1    ; IR: %123  (classical)
  %115 = icmp eq i64 %114, %102    ; IR: %124  (classical)
  br i1 %115, label %116, label %103    ; IR: br i1 %124, label %109, label %111

116:; IR: block %109
  %117 = phi i32 [ 0, %99 ], [ %113, %103 ]    ; IR: %110  (classical)
  ret i32 %117    ; IR: ret i32 %110
}

define internal fastcc void @__cq_q_grover_1000_ctl(i32 %0, ptr %1, i32 %2, ptr %3, i32 %4) {
  %6 = icmp sgt i32 %2, 0    ; IR: %5  (classical: nq > 0)
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %10 and of phi %20  [v before trip 0, and v itself when nq <= 0: one |0> seed rail]
  br i1 %6, label %8, label %21    ; IR: br i1 %5, label %6, label %19

8:; IR: block %6
  %9 = zext nneg i32 %2 to i64    ; IR: %7  (classical)
  br label %10

10:; IR: block %8  (value(x), classical bound nq)
  %11 = phi i64 [ 0, %8 ], [ %19, %10 ]    ; IR: %9  (classical i)
  %12 = phi i32 [ %7, %8 ], [ %18, %10 ]    ; IR: %10 = phi i32 [ 0, %6 ], [ %16, %8 ]
  %13 = getelementptr inbounds i32, ptr %1, i64 %11    ; IR: %11  (slot of x[i])
  %14 = load i32, ptr %13, align 4    ; IR: %12 = load i8, ptr %11  (handle of x[i]; no gate)
  %15 = call i32 @cq_template_zext_i1_to_i32(i32 %14)    ; IR: %13 = zext nneg i8 %12 to i32  [x[i] widened into a fresh rail]
  %16 = trunc nuw nsw i64 %11 to i32    ; IR: %14  (classical)
  %17 = call i32 @cq_template_shl_i32_hl(i32 %15, i32 %16)    ; IR: %15 = shl nuw i32 %13, %14
  %18 = call i32 @cq_template_or_i32(i32 %17, i32 %12)    ; IR: %16 = or i32 %15, %10
  call void @cqrt_push(i32 %12)    ; IR: trip-local rails of the accumulator, for the mirror (rule 14)
  call void @cqrt_push(i32 %15)
  call void @cqrt_push(i32 %17)
  %19 = add nuw nsw i64 %11, 1    ; IR: %17  (classical)
  %20 = icmp eq i64 %19, %9    ; IR: %18  (classical)
  br i1 %20, label %21, label %10    ; IR: br i1 %18, label %19, label %8

21:; IR: block %19
  %22 = phi i32 [ %7, %5 ], [ %18, %10 ]    ; IR: %20 = phi i32 [ 0, %4 ], [ %16, %8 ]  (v = value(x))
  %23 = icmp sgt i32 %4, 0    ; IR: %21  (classical: nmark > 0)
  br i1 %23, label %24, label %52    ; IR: br i1 %21, label %22, label %36 (%37 = %21 = false: no phase)

24:; IR: block %22  (trip 0 of is_marked, peeled by -O1)
  %25 = zext nneg i32 %4 to i64    ; IR: %23  (classical)
  %26 = load i32, ptr %3, align 4    ; IR: %24 = load i32, ptr %2  (classical marked[0])
  %27 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 %26)    ; IR: %25 = icmp eq i32 %24, %20  [literal on the left: eq is symmetric, spelled _hl]
  %28 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: the edge %22 -> %38 under the clone's control: pred & %25
  call void @cqrt_and_i1(i32 %0, i32 %27, i32 %28)    ; IR: br i1 %25 -> block %38 (Toffoli flag)
  call void @cqrt_rz_i1(i32 %28, double 0x400921FB54442D18)    ; IR: block %38 via %22: cq_phi(pi)  [kickback: O on v == marked[0]]
  call void @cqrt_and_i1(i32 %0, i32 %27, i32 %28)    ; IR: uncompute the edge flag
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  %29 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %26 = pred & NOT %25: the seed of the loop's chain (rule 14, classical bound with a quantum exit)
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket: NOT %25
  call void @cqrt_and_i1(i32 %0, i32 %27, i32 %29)    ; IR: br i1 %25 not taken, under the control
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket
  br label %30    ; IR: br label %26

30:; IR: block %26  (classical trip k + 1 = 1 .. nmark - 1)
  %31 = phi i64 [ 0, %24 ], [ %33, %35 ]    ; IR: %27  (classical k)
  %32 = phi i32 [ %29, %24 ], [ %40, %35 ]    ; IR: predicate of reaching this trip (a_k)
  %33 = add nuw nsw i64 %31, 1    ; IR: %28  (classical)
  %34 = icmp eq i64 %33, %25    ; IR: %29  (classical: the list is exhausted; edge %26 -> %34 has %35 = false: no phase)
  br i1 %34, label %41, label %35    ; IR: br i1 %29, label %34, label %30

35:; IR: block %30
  %36 = getelementptr inbounds i32, ptr %3, i64 %33    ; IR: %31  (classical &marked[k + 1])
  %37 = load i32, ptr %36, align 4    ; IR: %32  (classical marked[k + 1])
  %38 = call i32 @cq_template_icmp_eq_i32_hl(i32 %22, i32 %37)    ; IR: %33 = icmp eq i32 %32, %20
  %39 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: the edge %30 -> %34 (then %35 = k + 1 < nmark = true, %37 true -> block %38): a_k & %33
  call void @cqrt_and_i1(i32 %32, i32 %38, i32 %39)    ; IR: br i1 %33 -> block %34 -> block %38 (Toffoli flag)
  call void @cqrt_rz_i1(i32 %39, double 0x400921FB54442D18)    ; IR: block %38 via %34: cq_phi(pi)  [kickback: O on v == marked[k + 1]]
  call void @cqrt_and_i1(i32 %32, i32 %38, i32 %39)    ; IR: uncompute the edge flag
  call void @cqrt_free(i32 %39)    ; IR: release it (|0>)
  %40 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: the next trip's predicate a_{k+1} = a_k & NOT %33
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket: NOT %33
  call void @cqrt_and_i1(i32 %32, i32 %38, i32 %40)    ; IR: br i1 %33 not taken -> block %26
  call void @cqrt_not_i1(i32 %38)    ; IR: bracket
  call void @cqrt_push(i32 %32)    ; IR: trip-local rails for the mirror
  call void @cqrt_push(i32 %38)
  br label %30    ; IR: br label %26

41:; IR: block %34 reached by the exhausted edge; mirror of the chain, trips nmark - 1 .. 1
  %42 = phi i64 [ %31, %30 ], [ %50, %45 ]    ; IR: (classical index of the trip being undone)
  %43 = phi i32 [ %32, %30 ], [ %47, %45 ]    ; IR: the predicate that trip computed
  %44 = icmp eq i64 %42, 0    ; IR: (classical: back at the seed)
  br i1 %44, label %51, label %45

45:
  %46 = call i32 @cqrt_pop()    ; IR: %33 of that trip
  %47 = call i32 @cqrt_pop()    ; IR: its reach predicate
  call void @cqrt_not_i1(i32 %46)    ; IR: bracket
  call void @cqrt_and_i1(i32 %47, i32 %46, i32 %43)    ; IR: uncompute that trip's continue predicate
  call void @cqrt_not_i1(i32 %46)    ; IR: bracket
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  %48 = getelementptr inbounds i32, ptr %3, i64 %42    ; IR: (classical &marked[k], reloaded)
  %49 = load i32, ptr %48, align 4    ; IR: (classical marked[k])
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %46, i32 %22, i32 %49)    ; IR: uncompute that trip's %33
  call void @cqrt_free(i32 %46)    ; IR: release it (|0>)
  %50 = add nsw i64 %42, -1    ; IR: (classical)
  br label %41

51:
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket
  call void @cqrt_and_i1(i32 %0, i32 %27, i32 %43)    ; IR: uncompute the seed a_0 (the phi holds it here)
  call void @cqrt_not_i1(i32 %27)    ; IR: bracket
  call void @cqrt_free(i32 %43)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %27, i32 %22, i32 %26)    ; IR: uncompute %25
  call void @cqrt_free(i32 %27)    ; IR: release it (|0>)
  br label %52    ; IR: br label %39 (the phases of block %38 are already applied)

52:; IR: block %36 / %39: mirror of value(x), before A^dag rotates the cells
  br i1 %6, label %53, label %68

53:
  %54 = zext nneg i32 %2 to i64    ; IR: (classical trip count nq)
  %55 = add nsw i64 %54, -1    ; IR: (classical nq - 1)
  br label %56

56:; IR: reverse trip index of value(x) (undoes trip nq - 1 - r)
  %57 = phi i64 [ 0, %53 ], [ %66, %56 ]    ; IR: (classical r)
  %58 = phi i32 [ %22, %53 ], [ %61, %56 ]    ; IR: %16 of the trip being undone
  %59 = call i32 @cqrt_pop()
  %60 = call i32 @cqrt_pop()
  %61 = call i32 @cqrt_pop()
  %62 = sub nsw i64 %55, %57    ; IR: i of the trip being undone  (classical)
  %63 = getelementptr inbounds i32, ptr %1, i64 %62    ; IR: (slot of x[i])
  %64 = load i32, ptr %63, align 4    ; IR: the trip's x[i] handle, reloaded (unchanged: A^dag has not run yet)
  %65 = trunc nuw nsw i64 %62 to i32    ; IR: %14 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %58, i32 %59, i32 %61)    ; IR: uncompute %16
  call void @cqrt_free(i32 %58)    ; IR: release the %16 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %59, i32 %60, i32 %65)    ; IR: uncompute %15
  call void @cqrt_free(i32 %59)    ; IR: release the %15 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %60, i32 %64)    ; IR: uncompute %13
  call void @cqrt_free(i32 %60)    ; IR: release the %13 rail (|0>)
  %66 = add nuw nsw i64 %57, 1
  %67 = icmp eq i64 %66, %54
  br i1 %67, label %68, label %56

68:
  call void @cqrt_free(i32 %7)    ; IR: release the seed of phi %10 / %20 (never written, |0>)
  %69 = icmp sgt i32 %2, 0    ; IR: %40  (classical)
  br i1 %69, label %70, label %78    ; IR: br i1 %40, label %41, label %43

70:; IR: block %41
  %71 = zext nneg i32 %2 to i64    ; IR: %42  (classical)
  br label %72

72:; IR: block %59  (A^dag)
  %73 = phi i64 [ 0, %70 ], [ %76, %72 ]    ; IR: %60  (classical i)
  %74 = getelementptr inbounds i32, ptr %1, i64 %73    ; IR: %61  (slot of x[i])
  %75 = load i32, ptr %74, align 4    ; IR: %62 = load i8, ptr %61; %63 = trunc to i1  (handle of x[i]; no gate)
  call void @cqrt_ry_i1_controlled(i32 %0, i32 %75, double 0xBFF921FB54442D18)    ; IR: %64 = cq_theta_i1(%63, -pi/2)  [A^dag: Ry(-pi/2) on x[i] under the clone's control]; %65/store: handle unchanged
  %76 = add nuw nsw i64 %73, 1    ; IR: %66  (classical)
  %77 = icmp eq i64 %76, %71    ; IR: %67  (classical)
  br i1 %77, label %78, label %72    ; IR: br i1 %67, label %43, label %59

78:; IR: block %43
  br i1 %6, label %79, label %110    ; IR: br i1 %5, label %44, label %69 (nq <= 0: value(x) = 0, no phase)

79:; IR: block %44
  %80 = zext nneg i32 %2 to i64    ; IR: %45  (classical)
  %81 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %48  [v before trip 0]
  br label %82

82:; IR: block %46  (the second value(x))
  %83 = phi i64 [ 0, %79 ], [ %91, %82 ]    ; IR: %47  (classical i)
  %84 = phi i32 [ %81, %79 ], [ %90, %82 ]    ; IR: %48 = phi i32 [ 0, %44 ], [ %54, %46 ]
  %85 = getelementptr inbounds i32, ptr %1, i64 %83    ; IR: %49  (slot of x[i])
  %86 = load i32, ptr %85, align 4    ; IR: %50 = load i8, ptr %49  (handle of x[i]; no gate)
  %87 = call i32 @cq_template_zext_i1_to_i32(i32 %86)    ; IR: %51 = zext nneg i8 %50 to i32
  %88 = trunc nuw nsw i64 %83 to i32    ; IR: %52  (classical)
  %89 = call i32 @cq_template_shl_i32_hl(i32 %87, i32 %88)    ; IR: %53 = shl nuw i32 %51, %52
  %90 = call i32 @cq_template_or_i32(i32 %89, i32 %84)    ; IR: %54 = or i32 %53, %48
  call void @cqrt_push(i32 %84)
  call void @cqrt_push(i32 %87)
  call void @cqrt_push(i32 %89)
  %91 = add nuw nsw i64 %83, 1    ; IR: %55  (classical)
  %92 = icmp eq i64 %91, %80    ; IR: %56  (classical)
  br i1 %92, label %93, label %82    ; IR: br i1 %56, label %57, label %46

93:; IR: block %57
  %94 = call i32 @cq_template_icmp_eq_i32_hl(i32 %90, i32 0)    ; IR: %58 = icmp eq i32 %54, 0
  %95 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %68 = pred & NOT %58
  call void @cqrt_not_i1(i32 %94)    ; IR: bracket: NOT %58
  call void @cqrt_and_i1(i32 %0, i32 %94, i32 %95)    ; IR: br i1 %58 not taken -> block %68, under the control
  call void @cqrt_not_i1(i32 %94)    ; IR: bracket
  call void @cqrt_rz_i1(i32 %95, double 0x400921FB54442D18)    ; IR: block %68: cq_phi(pi)  [kickback: R = 2|0><0| - I]
  call void @cqrt_not_i1(i32 %94)    ; IR: bracket
  call void @cqrt_and_i1(i32 %0, i32 %94, i32 %95)    ; IR: uncompute the flag
  call void @cqrt_not_i1(i32 %94)    ; IR: bracket
  call void @cqrt_free(i32 %95)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %94, i32 %90, i32 0)    ; IR: uncompute %58
  call void @cqrt_free(i32 %94)    ; IR: release the %58 rail (|0>)
  %96 = add nsw i64 %80, -1    ; IR: (classical nq - 1)
  br label %97

97:; IR: reverse trip index of the second value(x)
  %98 = phi i64 [ 0, %93 ], [ %107, %97 ]    ; IR: (classical r)
  %99 = phi i32 [ %90, %93 ], [ %102, %97 ]    ; IR: %54 of the trip being undone
  %100 = call i32 @cqrt_pop()
  %101 = call i32 @cqrt_pop()
  %102 = call i32 @cqrt_pop()
  %103 = sub nsw i64 %96, %98    ; IR: i of the trip being undone  (classical)
  %104 = getelementptr inbounds i32, ptr %1, i64 %103    ; IR: (slot of x[i])
  %105 = load i32, ptr %104, align 4    ; IR: the trip's x[i] handle, reloaded (unchanged: A has not run yet)
  %106 = trunc nuw nsw i64 %103 to i32    ; IR: %52 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %99, i32 %100, i32 %102)    ; IR: uncompute %54
  call void @cqrt_free(i32 %99)    ; IR: release the %54 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %100, i32 %101, i32 %106)    ; IR: uncompute %53
  call void @cqrt_free(i32 %100)    ; IR: release the %53 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %101, i32 %105)    ; IR: uncompute %51
  call void @cqrt_free(i32 %101)    ; IR: release the %51 rail (|0>)
  %107 = add nuw nsw i64 %98, 1
  %108 = icmp eq i64 %107, %80
  br i1 %108, label %109, label %97

109:
  call void @cqrt_free(i32 %81)    ; IR: release incoming 0 of phi %48 (never written, |0>)
  br label %110

110:; IR: block %69
  %111 = icmp sgt i32 %2, 0    ; IR: %70  (classical)
  br i1 %111, label %112, label %120    ; IR: br i1 %70, label %71, label %73

112:; IR: block %71
  %113 = zext nneg i32 %2 to i64    ; IR: %72  (classical)
  br label %114

114:; IR: block %74  (A)
  %115 = phi i64 [ 0, %112 ], [ %118, %114 ]    ; IR: %75  (classical i)
  %116 = getelementptr inbounds i32, ptr %1, i64 %115    ; IR: %76  (slot of x[i])
  %117 = load i32, ptr %116, align 4    ; IR: %77 = load i8, ptr %76; %78 = trunc to i1  (handle of x[i]; no gate)
  call void @cqrt_ry_i1_controlled(i32 %0, i32 %117, double 0x3FF921FB54442D18)    ; IR: %79 = cq_theta_i1(%78, pi/2)  [A: Ry(pi/2) on x[i] under the clone's control]; %80/store: handle unchanged
  %118 = add nuw nsw i64 %115, 1    ; IR: %81  (classical)
  %119 = icmp eq i64 %118, %113    ; IR: %82  (classical)
  br i1 %119, label %120, label %114    ; IR: br i1 %82, label %73, label %74

120:; IR: block %73
  ret void    ; IR: ret void
}

declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare i32 @cq_template_zext_i1_to_i32(i32)
declare void @cq_template_zext_i1_to_i32_unc(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @llvm.smax.i32(i32, i32)
