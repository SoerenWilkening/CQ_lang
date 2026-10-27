; HAND-WRITTEN. Rules: 15, 8, 12, 2, 4, 5, 7, 14, 20, 22.
; Checked: out = sum_j c[j] << (t-1-j) | sum_i k[i] << (t+i): the t counting rails c[j] (behind the runtime-sized slot
; array %7; the first measure loop loads and measures each) and the nk eigenphase rails k[i] (behind %5; the second
; measure loop), all measured.
; Clean: the kv accumulator walk (its |0> seed and per trip the zext, shl, or rails, pushed and uncomputed by the mirror
; loop), its sitofp rail (or, for nk <= 0, the 0.0 seed rail of the phi), the angle base A = fl((2 pi / 2^nk) * (double)kv)
; (the program's fmul), the per-trip angle rail A_j = fl(A * 2^j) (one per trip of the phase loop) and the QFT^-1 Toffoli
; flags c[m] & c[j] (one per (m, j) pair), each |0> (or its seed value) at its free.
; Kept: the user registers k[i] and c[j] (measured; a measured rail stays allocated). No other rail survives.
; Rotations: (Ry, k[i], tk[i], 1) for i = 0..nk-1; (Ry, c[j], pi/2, 1) for j = 0..t-1; then for j = 0..t-1:
; (P, A_j, val(A_j), c[j]) with A_j = fl(fl((2 pi / 2^nk) * (double)kv) * 2^j), kv = sum_i k[i] << i [the controlled
; U^(2^j), U = diag(e^{i 2 pi kv / 2^nk}), applied by ONE primitive on the angle rail]; then the QFT^-1: for j = t-1..0:
; (P, flag, -pi / 2^(m-j), c[m] & c[j]) for m = t-1..j+1, (P, c[j], pi, c[j]) (rz_i1 on the bare rail), (Ry, c[j], pi/2, 1).
; Expected: for basis kv the counting field reads kv * 2^(t-nk) exactly when t >= nk (c[0] is its top bit); in
; superposition every kv branch reads its own estimate and k is left unchanged. Replayed on a state vector (the phase
; primitive modelled as e^{i val(A_j)} on the c[j] = 1 branch, val(A_j) the double the chain computes from the basis
; value of k; every free asserted at its seed value; only the registers stay allocated): call 1 (nk = 2, t = 2,
; tk = {pi, 0}: kv = 1) reads c = 01, k = (1, 0) with p = 1.0000; call 2 (nk = 3, t = 4, tk = {pi/2, pi/2, pi}: kv uniform
; on {4, 5, 6, 7}) reads c = 2 kv (1000, 1010, 1100, 1110) jointly with its own k, p = 0.25 each, nothing else.
; QPE whose phase comes from a QUANTUM angle register, general size: nk, t and the preparation angles tk[] are inputs, so
; both registers are runtime-sized slot arrays (rule 20: `bool k[nk], c[t]` are `alloca i32, n` of handle cells; the
; memset zero-fills are one seed rail alloc_i1(0) per cell, rules 20, 22) and every loop has a classical runtime bound
; (rule 14). kv = sum k[i] << i is the quantum accumulator of 28 (zext, shl, or into fresh rails, pushed per trip). -O1
; turns (double)kv into `sitofp` at the loop exit and merges it with the literal 0.0 of the nk <= 0 path; that incoming is a
; seed rail cqrt_alloc_f64(0.0), so the phi is a handle on both edges. The kv seed alloc_i32(0) is allocated before the
; guard and is also the kv rail of the nk <= 0 path. -O1 hoists 2 pi / 2^nk (classical) and its product with (double)kv out
; of the phase loop: cq_template_fmul_f64_hl gives the f64 REGISTER A holding the program's IEEE double, bit-exact (rule 15,
; as 79 and 143). Each trip multiplies A by the classical (double)(1 << j) into the trip rail A_j, computed UNGUARDED (pure
; arm code is hoisted, rule 9), and `if (c[j]) cq_phi(phi)` is ONE primitive cqrt_rz_qangle_controlled(c[j], A_j):
; e^{i val(A_j)} on the branch where the bare rail c[j] is 1 (rule 15; the backend supplies the N-bit ladder, the IR never
; spells it; the phase is RELATIVE in k, never a deletable global one, rule 12). A_j is only read, so it is uncomputed and
; freed right after the primitive; after the loop A, the sitofp rail and the kv walk are uncomputed in LIFO order before
; the QFT^-1 (no non-diagonal gate ever touches k). The QFT^-1 is 117's caller loop: the nested branches c[m], c[j] are one
; Toffoli flag with a kickback cqrt_rz_i1(flag, -pi / 2^(m-j)); `if (c[j]) cq_phi(pi)` on the bare rail is cqrt_rz_i1 on
; the rail itself; cq_theta(&c[j], pi/2) is cqrt_ry_i1 in place. The measure loops and the packing are classical (rule 2).
source_filename = "qpe_quantum_angle.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @qpe_quantum_angle(i32 noundef %0, i32 noundef %1, ptr noundef %2) {
  %4 = zext i32 %0 to i64    ; IR: %4  (classical cell count nk)
  %5 = alloca i32, i64 %4, align 16    ; IR: %5 = alloca i8, i64 %4  (runtime-sized slot array: one handle cell per k[i]; rule 20)
  %6 = zext i32 %1 to i64    ; IR: %6  (classical cell count t)
  %7 = alloca i32, i64 %6, align 16    ; IR: %7 = alloca i8, i64 %6  (runtime-sized slot array: one handle cell per c[j]; rule 20)
  %8 = icmp sgt i32 %0, 0    ; IR: %8  (classical)
  br i1 %8, label %9, label %17    ; IR: br i1 %8, label %9, label %11

9:; IR: block %9
  %10 = zext nneg i32 %0 to i64    ; IR: %10  (classical memset length)
  br label %11

11:; IR: memset(%5, 0, %10), one fixed-index cell per trip (rule 22)
  %12 = phi i64 [ 0, %9 ], [ %15, %11 ]    ; IR: (classical cell index of the memset)
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: memset: k[i] = 0  [register k[i]: the classical store materialises a seed rail, rule 20]
  %14 = getelementptr inbounds i32, ptr %5, i64 %12    ; IR: (slot i)
  store i32 %13, ptr %14, align 4    ; IR: memset  (slot i holds the handle of k[i])
  %15 = add nuw nsw i64 %12, 1    ; IR: (classical)
  %16 = icmp eq i64 %15, %10    ; IR: (classical: i + 1 == nk)
  br i1 %16, label %17, label %11

17:; IR: block %11
  %18 = icmp sgt i32 %1, 0    ; IR: %12  (classical)
  br i1 %18, label %19, label %27    ; IR: br i1 %12, label %13, label %15

19:; IR: block %13
  %20 = zext nneg i32 %1 to i64    ; IR: %14  (classical memset length)
  br label %21

21:; IR: memset(%7, 0, %14), one fixed-index cell per trip (rule 22)
  %22 = phi i64 [ 0, %19 ], [ %25, %21 ]    ; IR: (classical cell index of the memset)
  %23 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: memset: c[j] = 0  [register c[j]]
  %24 = getelementptr inbounds i32, ptr %7, i64 %22    ; IR: (slot j)
  store i32 %23, ptr %24, align 4    ; IR: memset  (slot j holds the handle of c[j])
  %25 = add nuw nsw i64 %22, 1    ; IR: (classical)
  %26 = icmp eq i64 %25, %20    ; IR: (classical: j + 1 == t)
  br i1 %26, label %27, label %21

27:; IR: block %15
  %28 = icmp sgt i32 %0, 0    ; IR: %16  (classical)
  br i1 %28, label %29, label %39    ; IR: br i1 %16, label %17, label %19

29:; IR: block %17
  %30 = zext nneg i32 %0 to i64    ; IR: %18  (classical)
  br label %31

31:; IR: block %23  (eigenstate preparation, classical bound nk)
  %32 = phi i64 [ 0, %29 ], [ %37, %31 ]    ; IR: %24  (classical i)
  %33 = getelementptr inbounds i32, ptr %5, i64 %32    ; IR: %25  (slot of k[i])
  %34 = load i32, ptr %33, align 4    ; IR: %26 = load i8, ptr %25; %27 = trunc to i1  (handle of k[i]; no gate)
  %35 = getelementptr inbounds double, ptr %2, i64 %32    ; IR: %28  (classical &tk[i])
  %36 = load double, ptr %35, align 8    ; IR: %29  (classical angle tk[i])
  call void @cqrt_ry_i1(i32 %34, double %36)    ; IR: %30 = cq_theta_i1(%27, %29)  [Ry(tk[i]) in place on k[i]]; %31/store: handle unchanged
  %37 = add nuw nsw i64 %32, 1    ; IR: %32  (classical)
  %38 = icmp eq i64 %37, %30    ; IR: %33  (classical)
  br i1 %38, label %39, label %31    ; IR: br i1 %33, label %19, label %23

39:; IR: block %19
  %40 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %43  [kv before trip 0; it also stands for kv = 0 when nk <= 0]
  %41 = icmp sgt i32 %0, 0    ; IR: %20  (classical)
  br i1 %41, label %42, label %57    ; IR: br i1 %20, label %21, label %36

42:; IR: block %21
  %43 = zext nneg i32 %0 to i64    ; IR: %22  (classical)
  br label %44

44:; IR: block %41  (kv = sum k[i] << i, the quantum accumulator of 28)
  %45 = phi i64 [ 0, %42 ], [ %53, %44 ]    ; IR: %42  (classical i)
  %46 = phi i32 [ %40, %42 ], [ %52, %44 ]    ; IR: %43 = phi i32 [ 0, %21 ], [ %49, %41 ]
  %47 = getelementptr inbounds i32, ptr %5, i64 %45    ; IR: %44  (slot of k[i])
  %48 = load i32, ptr %47, align 4    ; IR: %45 = load i8, ptr %44  (handle of k[i]; no gate)
  %49 = call i32 @cq_template_zext_i1_to_i32(i32 %48)    ; IR: %46 = zext nneg i8 %45 to i32  [k[i] widened into a fresh rail]
  %50 = trunc nuw nsw i64 %45 to i32    ; IR: %47  (classical)
  %51 = call i32 @cq_template_shl_i32_hl(i32 %49, i32 %50)    ; IR: %48 = shl nuw i32 %46, %47
  %52 = call i32 @cq_template_or_i32(i32 %51, i32 %46)    ; IR: %49 = or i32 %48, %43
  call void @cqrt_push(i32 %46)    ; IR: trip-local rails of the accumulator, for the mirror (rule 14)
  call void @cqrt_push(i32 %49)
  call void @cqrt_push(i32 %51)
  %53 = add nuw nsw i64 %45, 1    ; IR: %50  (classical)
  %54 = icmp eq i64 %53, %43    ; IR: %51  (classical)
  br i1 %54, label %55, label %44    ; IR: br i1 %51, label %34, label %41

55:; IR: block %34
  %56 = call i32 @cq_template_sitofp_i32_to_f64(i32 %52)    ; IR: %35 = sitofp i32 %49 to double  [(double)kv into a fresh f64 rail]
  br label %59

57:; IR: the edge %19 -> %36
  %58 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: incoming 0.0 of phi %37  [(double)kv with nk <= 0: a seed rail, the phi stays a handle on both edges (rule 20 homogeneity, rule 7)]
  br label %59

59:; IR: block %36
  %60 = phi i32 [ %52, %55 ], [ %40, %57 ]    ; IR: (the kv rail reaching here: %49, or the seed when nk <= 0; the mirror below needs it)
  %61 = phi i32 [ %56, %55 ], [ %58, %57 ]    ; IR: %37 = phi double [ 0.0, %19 ], [ %35, %34 ]
  %62 = icmp sgt i32 %1, 0    ; IR: %38  (classical)
  br i1 %62, label %63, label %71    ; IR: br i1 %38, label %39, label %52

63:; IR: block %39
  %64 = zext nneg i32 %1 to i64    ; IR: %40  (classical)
  br label %65

65:; IR: block %60  (H^t)
  %66 = phi i64 [ 0, %63 ], [ %69, %65 ]    ; IR: %61  (classical j)
  %67 = getelementptr inbounds i32, ptr %7, i64 %66    ; IR: %62  (slot of c[j])
  %68 = load i32, ptr %67, align 4    ; IR: %63 = load i8, ptr %62; %64 = trunc to i1  (handle of c[j]; no gate)
  call void @cqrt_ry_i1(i32 %68, double 0x3FF921FB54442D18)    ; IR: %65 = cq_theta_i1(%64, pi/2)  [H|0>: Ry(pi/2) in place on c[j]]; %66/store: handle unchanged
  %69 = add nuw nsw i64 %66, 1    ; IR: %67  (classical)
  %70 = icmp eq i64 %69, %64    ; IR: %68  (classical)
  br i1 %70, label %71, label %65    ; IR: br i1 %68, label %52, label %60

71:; IR: block %52
  %72 = icmp sgt i32 %1, 0    ; IR: %53  (classical)
  br i1 %72, label %73, label %90    ; IR: br i1 %53, label %54, label %69

73:; IR: block %54
  %74 = shl nuw i32 1, %0    ; IR: %55  (classical 1 << nk)
  %75 = sitofp i32 %74 to double    ; IR: %56  (classical)
  %76 = fdiv double 0x401921FB54442D18, %75    ; IR: %57  (classical 2 pi / 2^nk)
  %77 = call i32 @cq_template_fmul_f64_hl(i32 %61, double %76)    ; IR: %58 = fmul double %57, %37  [the angle base A = fl((2 pi / 2^nk) * (double)kv), hoisted out of the loop by -O1; commutative, handle first]
  %78 = zext nneg i32 %1 to i64    ; IR: %59  (classical)
  br label %79

79:; IR: block %75 (+ block %80 hoisted: pure arm code, rule 9)  (controlled U^(2^j))
  %80 = phi i64 [ 0, %73 ], [ %87, %79 ]    ; IR: %76  (classical j)
  %81 = getelementptr inbounds i32, ptr %7, i64 %80    ; IR: %77  (slot of c[j])
  %82 = load i32, ptr %81, align 4    ; IR: %78 = load i8, ptr %77; %79 = trunc to i1  (handle of c[j]: the bare-rail predicate of block %80)
  %83 = trunc nuw nsw i64 %80 to i32    ; IR: %81  (classical)
  %84 = shl nuw i32 1, %83    ; IR: %82  (classical 1 << j)
  %85 = sitofp i32 %84 to double    ; IR: %83  (classical (double)(1 << j))
  %86 = call i32 @cq_template_fmul_f64_hl(i32 %77, double %85)    ; IR: %84 = fmul double %58, %83  [A_j = fl(A * 2^j), computed unguarded into a fresh rail]
  call void @cqrt_rz_qangle_controlled(i32 %82, i32 %86)    ; IR: br i1 %79 -> block %80: cq_phi(%84)  [ONE primitive: e^{i val(A_j)} on the branch where c[j] = 1 (rule 15); a relative phase in k]
  call void @cq_template_fmul_f64_hl_unc(i32 %86, i32 %77, double %85)    ; IR: uncompute %84 (only read by the phase primitive)
  call void @cqrt_free(i32 %86)    ; IR: release the %84 rail (|0>)
  %87 = add nuw nsw i64 %80, 1    ; IR: %86  (classical)
  %88 = icmp eq i64 %87, %78    ; IR: %87  (classical)
  br i1 %88, label %89, label %79    ; IR: br i1 %87, label %69, label %75

89:; IR: the edge %85 -> %69
  call void @cq_template_fmul_f64_hl_unc(i32 %77, i32 %61, double %76)    ; IR: uncompute %58 after its last consumer (the last trip's fmul)
  call void @cqrt_free(i32 %77)    ; IR: release the %58 rail (|0>)
  br label %90

90:; IR: block %69 entry: the angle chain is dead; uncompute it in LIFO order before the QFT^-1 (no non-diagonal gate touches k)
  br i1 %41, label %91, label %106

91:
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %61, i32 %60)    ; IR: uncompute %35
  call void @cqrt_free(i32 %61)    ; IR: release the %35 rail (|0>)
  %92 = zext nneg i32 %0 to i64    ; IR: (classical trip count nk)
  %93 = add nsw i64 %92, -1    ; IR: (classical nk - 1)
  br label %94

94:; IR: reverse trip index of the kv accumulator (undoes trip nk - 1 - r)
  %95 = phi i64 [ 0, %91 ], [ %104, %94 ]    ; IR: (classical r)
  %96 = phi i32 [ %60, %91 ], [ %99, %94 ]    ; IR: %49 of the trip being undone
  %97 = call i32 @cqrt_pop()
  %98 = call i32 @cqrt_pop()
  %99 = call i32 @cqrt_pop()
  %100 = sub nsw i64 %93, %95    ; IR: i of the trip being undone  (classical)
  %101 = getelementptr inbounds i32, ptr %5, i64 %100    ; IR: (slot of k[i])
  %102 = load i32, ptr %101, align 4    ; IR: the trip's k[i] handle, reloaded
  %103 = trunc nuw nsw i64 %100 to i32    ; IR: %47 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %96, i32 %97, i32 %99)    ; IR: uncompute %49
  call void @cqrt_free(i32 %96)    ; IR: release the %49 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %97, i32 %98, i32 %103)    ; IR: uncompute %48
  call void @cqrt_free(i32 %97)    ; IR: release the %48 rail (|0>)
  call void @cq_template_zext_i1_to_i32_unc(i32 %98, i32 %102)    ; IR: uncompute %46
  call void @cqrt_free(i32 %98)    ; IR: release the %46 rail (|0>)
  %104 = add nuw nsw i64 %95, 1
  %105 = icmp eq i64 %104, %92
  br i1 %105, label %107, label %94

106:
  call void @cqrt_free(i32 %61)    ; IR: release the 0.0 seed of phi %37 (never written)
  br label %107

107:
  call void @cqrt_free(i32 %40)    ; IR: release the seed of phi %43 (never written, |0>)
  br label %108

108:; IR: block %69  (QFT^-1 without the final swaps)
  %109 = add i32 %1, -1    ; IR: %70  (classical t - 1)
  %110 = icmp sgt i32 %1, 0    ; IR: %71  (classical)
  br i1 %110, label %111, label %139    ; IR: br i1 %71, label %72, label %94

111:; IR: block %72
  %112 = zext i32 %109 to i64    ; IR: %73  (classical)
  %113 = sext i32 %109 to i64    ; IR: %74  (classical)
  br label %114    ; IR: br label %88

114:; IR: block %88
  %115 = phi i64 [ %112, %111 ], [ %137, %134 ]    ; IR: %89  (classical j, t-1 down to 0)
  %116 = icmp slt i64 %115, %113    ; IR: %90  (classical: j < t - 1, the inner loop runs)
  br i1 %116, label %117, label %134    ; IR: br i1 %90, label %91, label %98

117:; IR: block %91
  %118 = getelementptr inbounds i32, ptr %7, i64 %115    ; IR: %92  (slot of c[j])
  %119 = trunc nuw nsw i64 %115 to i32    ; IR: %93  (classical)
  br label %120    ; IR: br label %102

120:; IR: block %102  (classical m = t-1 down to j+1)
  %121 = phi i32 [ %109, %117 ], [ %131, %120 ]    ; IR: %103  (classical m)
  %122 = zext nneg i32 %121 to i64    ; IR: %104  (classical)
  %123 = getelementptr inbounds i32, ptr %7, i64 %122    ; IR: %105  (slot of c[m])
  %124 = load i32, ptr %123, align 4    ; IR: %106 = load i8, ptr %105; %107 = trunc to i1  (handle of c[m]; no gate)
  %125 = load i32, ptr %118, align 4    ; IR: %109 = load i8, ptr %92; %110 = trunc to i1  (handle of c[j]; no gate)
  %126 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %111 = %107 & %110 (br i1 %107 -> block %108, br i1 %110 -> block %111)
  call void @cqrt_and_i1(i32 %124, i32 %125, i32 %126)    ; IR: one Toffoli flag (rule 8)
  %127 = sub nsw i32 %121, %119    ; IR: %112  (classical m - j)
  %128 = shl nuw i32 1, %127    ; IR: %113  (classical 1 << (m - j))
  %129 = sitofp i32 %128 to double    ; IR: %114  (classical)
  %130 = fdiv double 0xC00921FB54442D18, %129    ; IR: %115  (classical angle -pi / 2^(m-j))
  call void @cqrt_rz_i1(i32 %126, double %130)    ; IR: block %111: cq_phi(%115)  [kickback on the flag]
  call void @cqrt_and_i1(i32 %124, i32 %125, i32 %126)    ; IR: uncompute the %111 predicate
  call void @cqrt_free(i32 %126)    ; IR: release the flag (|0>)
  %131 = add nsw i32 %121, -1    ; IR: %117  (classical)
  %132 = sext i32 %131 to i64    ; IR: %118  (classical)
  %133 = icmp slt i64 %115, %132    ; IR: %119  (classical)
  br i1 %133, label %120, label %134    ; IR: br i1 %119, label %102, label %98

134:; IR: blocks %98, %120, %121
  %135 = getelementptr inbounds i32, ptr %7, i64 %115    ; IR: %99  (slot of c[j])
  %136 = load i32, ptr %135, align 4    ; IR: %100 = load i8, ptr %99; %101 = trunc to i1  (handle of c[j]: a bare rail)
  call void @cqrt_rz_i1(i32 %136, double 0x400921FB54442D18)    ; IR: br i1 %101 -> block %120: cq_phi(pi)  [phase on the bare rail itself: a diagonal gate on the register, no flag]
  call void @cqrt_ry_i1(i32 %136, double 0x3FF921FB54442D18)    ; IR: %122 = cq_theta_i1(%101, pi/2)  [Ry in place on c[j]]; %123/store: handle unchanged
  %137 = add nsw i64 %115, -1    ; IR: %124  (classical)
  %138 = icmp sgt i64 %115, 0    ; IR: %125  (classical)
  br i1 %138, label %114, label %139    ; IR: br i1 %125, label %88, label %94

139:; IR: block %94
  %140 = icmp sgt i32 %1, 0    ; IR: %95  (classical)
  br i1 %140, label %141, label %156    ; IR: br i1 %95, label %96, label %126

141:; IR: block %96
  %142 = zext nneg i32 %1 to i64    ; IR: %97  (classical)
  br label %143

143:; IR: block %131  (measure c, classical)
  %144 = phi i64 [ 0, %141 ], [ %154, %143 ]    ; IR: %132  (classical j)
  %145 = phi i32 [ 0, %141 ], [ %153, %143 ]    ; IR: %133  (classical out)
  %146 = getelementptr inbounds i32, ptr %7, i64 %144    ; IR: %134  (slot of c[j])
  %147 = load i32, ptr %146, align 4    ; IR: %135 = load i8, ptr %134; %136 = trunc to i1  (handle of c[j])
  %148 = call i1 @cqrt_measure_i1(i32 %147)    ; IR: %137 = cq_measure_i1(%136)
  %149 = zext i1 %148 to i32    ; IR: %138  (classical)
  %150 = trunc i64 %144 to i32    ; IR: %139  (classical)
  %151 = sub i32 %109, %150    ; IR: %140  (classical t - 1 - j)
  %152 = shl nuw i32 %149, %151    ; IR: %141  (classical)
  %153 = or i32 %152, %145    ; IR: %142  (classical)
  %154 = add nuw nsw i64 %144, 1    ; IR: %143  (classical)
  %155 = icmp eq i64 %154, %142    ; IR: %144  (classical)
  br i1 %155, label %156, label %143    ; IR: br i1 %144, label %126, label %131

156:; IR: block %126
  %157 = phi i32 [ 0, %139 ], [ %153, %143 ]    ; IR: %127  (classical)
  %158 = icmp sgt i32 %0, 0    ; IR: %128  (classical)
  br i1 %158, label %159, label %174    ; IR: br i1 %128, label %129, label %145

159:; IR: block %129
  %160 = zext nneg i32 %0 to i64    ; IR: %130  (classical)
  br label %161

161:; IR: block %147  (measure k, classical)
  %162 = phi i64 [ 0, %159 ], [ %172, %161 ]    ; IR: %148  (classical i)
  %163 = phi i32 [ %157, %159 ], [ %171, %161 ]    ; IR: %149  (classical out)
  %164 = getelementptr inbounds i32, ptr %5, i64 %162    ; IR: %150  (slot of k[i])
  %165 = load i32, ptr %164, align 4    ; IR: %151 = load i8, ptr %150; %152 = trunc to i1  (handle of k[i])
  %166 = call i1 @cqrt_measure_i1(i32 %165)    ; IR: %153 = cq_measure_i1(%152)
  %167 = zext i1 %166 to i32    ; IR: %154  (classical)
  %168 = trunc i64 %162 to i32    ; IR: %155  (classical)
  %169 = add i32 %168, %1    ; IR: %156  (classical t + i)
  %170 = shl nuw i32 %167, %169    ; IR: %157  (classical)
  %171 = or i32 %170, %163    ; IR: %158  (classical)
  %172 = add nuw nsw i64 %162, 1    ; IR: %159  (classical)
  %173 = icmp eq i64 %172, %160    ; IR: %160  (classical)
  br i1 %173, label %174, label %161    ; IR: br i1 %160, label %145, label %147

174:; IR: block %145
  %175 = phi i32 [ %157, %156 ], [ %171, %161 ]    ; IR: %146  (classical)
  ret i32 %175    ; IR: ret i32 %146
}

declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_rz_qangle_controlled(i32, i32)
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
declare i32 @cq_template_sitofp_i32_to_f64(i32)
declare void @cq_template_sitofp_i32_to_f64_unc(i32, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
