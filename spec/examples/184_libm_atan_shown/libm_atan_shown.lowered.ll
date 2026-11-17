; HAND-WRITTEN. Rules: 18 (the musl atan body is static and inlined by clang -O1, so it lowers in the entry), 20 (two bus loads at address rails), 21, 5, 8, 9, 3, 4 (and 1, 2), section 2.
; Checked: atan(x) * c (measured, %74 -> %75).
; Clean: every flag, select and arithmetic rail of the entry; the two address rails of atanhi[id] and atanlo[id] and
; their scaled-index rails; the conjunction flag of block %59; the two bus load copies (un-copied: no memory version
; change follows them); all uncomputed and freed before the measurement.
; Kept: the register x (%4) and the measured result rail %74. No store, no tape slot, no kept load copy.
; Rotations: (Ry, x, tx, 1).
; A transcendental whose body is SHOWN (175 only declares its exp/atan2 clones): musl's atan (FreeBSD msun s_atan.c
; lineage) reproduced as the static atan_musl in the .c. clang -O1 inlines it into the entry, so the O1.ll holds no call
; and no clone __cq_q_atan_musl_1 exists: the whole body is straight-line templates here (what a clone would hold, minus the
; copy-out). The `union { double f; unsigned long long i; }` view is a bitcast template, ix = the high word masked (lshr,
; trunc, and), and the `ix` range tests are compare flags on that i32 bit view (rule 8): %9 (ix >= 0x44100000), %15
; (ix < 0x3fdc0000), %17 (ix < 0x3e400000), %20 (ix < 0x3ff30000), %22 (ix < 0x3fe60000), %32 (ix < 0x40038000). The huge
; branch's `sign ? -z : z` with z = atanhi[3] + 0x1p-120f is const-folded by -O1 to copysign(pi/2, x), a copysign_f64_lh
; template; `x != x` is the fcmp uno flag %11. The four `id` arms (block %23/%27/%33/%37) are pure: computed unguarded (fmul,
; fadd and fdiv templates, each llvm.fmuladd UNFUSED by section 2 into an fmul product rail and an fadd, the product
; uncomputed by its fmul _unc right after the sum; fdiv totalised by section 2) and merged by selects nested like the if tree (rule 9): on %22 and %32
; innermost, then %20, then %15 for the %16 edge that carries x itself. `id` is the same select tree over literals at
; the phi's own type: -O1 typed the phi i64 (the sext of int id into the GEP index folded into the incomings, with
; 4294967295 for the id = -1 edge), and no index is narrowed (rule 20), so the id rail is i64 (select_i64_ll /
; select_i64_lh with 4294967295 on that edge).
; ONE BUS (rules 20, 21): `atanhi[id]` and `atanlo[id]` are constant tables read at a QUANTUM id. Nothing is known about
; an address at compile time and nothing is allocated or seeded for a global: each table lives at its host address and
; is read through the bus as HOST cells. m = __cq_mem() is called once, at entry (section 5). Each getelementptr has a
; tainted index, so it is 64-bit template arithmetic into an address rail: the i64 id rail scaled by mul_i64_hl(id, 8),
; then add_i64_hl of the classical part, the constant expression ptrtoint (ptr @atanhi to i64) (the constant index 0
; contributes 0); the two getelementptrs share the id rail and each emits its own scale and add. Each load is ONE
; qram_load_f64 at its address rail. A bus access is never hoisted or speculated (rules 5, 9): the loads stay at their
; program point in block %59 as the _controlled form under the block's predicate, the conjunction NOT %9 AND NOT %15
; (rule 8: and_i1 into a fresh |0> inside an X bracket on both flags), computed just before the first load and
; uncomputed right after the last load _unc. Under predicate 0 (the paths that return earlier, the id = -1 edge among
; them) no cell is read and the load rail stays |0>, which the select tree discards. No memory version change (a store,
; an allocation, a memory-writing call; rule 5) follows the loads, so both copies are un-copied (rule 5, Memory) with their control at its load value,
; LIFO after their last reader's _unc; each address rail outlives its load's _unc and is uncomputed right after it
; (rule 20). The aT[] coefficients were folded into fmuladd literals by clang (the literals of the fmul/fadd templates)
; and are classical. `br i1 %15` at %39 is -O1's rewrite of `id < 0` (on every path into %39, id < 0 iff %15), so the two
; early returns and the final merge are selects on the same flags: %73 = select(%9, select(%11, x, %13), select(%15,
; select(%17, x, %58), %71)), one select per distinct incoming with the complement arm innermost. sign (%70 = the bit
; view < 0) selects the negated result. Everything but the result rail is uncomputed LIFO before the measurement.
source_filename = "libm_atan_shown.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@atanhi = internal unnamed_addr constant [4 x double] [double 0x3FDDAC670561BB4F, double 0x3FE921FB54442D18, double 0x3FEF730BD281F69B, double 0x3FF921FB54442D18], align 16
@atanlo = internal unnamed_addr constant [4 x double] [double 0x3C7A2B7F222F65E2, double 0x3C81A62633145C07, double 0x3C7007887AF0CBBD, double 0x3C91A62633145C07], align 16

define double @libm_atan_shown(double noundef %0, double noundef %1, double noundef %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (section 5)
  %5 = call i32 @cqrt_alloc_f64(double %0)    ; IR: %4 = cq_theta_f64(%0, %1)  [register x]
  call void @cqrt_ry_f64(i32 %5, double %1)    ; IR: %4 = cq_theta_f64(%0, %1)  [Ry]
  %6 = call i32 @cq_template_bitcast_f64_to_i64(i32 %5)    ; IR: %5 = bitcast %4 to i64  (u.i)
  %7 = call i32 @cq_template_lshr_i64_hl(i32 %6, i64 32)    ; IR: %6 = lshr %5, 32  (high word)
  %8 = call i32 @cq_template_trunc_i64_to_i32(i32 %7)    ; IR: %7 = trunc nuw %6 to i32
  %9 = call i32 @cq_template_and_i32_hl(i32 %8, i32 2147483647)    ; IR: %8 = and %7, 0x7fffffff  (ix)
  %10 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 1141899263)    ; IR: %9 = icmp ugt %8, 0x440FFFFF  (ix >= 0x44100000)  [predicate of block %10]
  %11 = call i32 @cq_template_fcmp_uno_f64_hl(i32 %5, double 0.000000e+00)    ; IR: %11 = fcmp uno %4, 0  (x != x)  (block %10)  [br -> exit with x]
  %12 = call i32 @cq_template_copysign_f64_lh(double 0x3FF921FB54442D18, i32 %5)    ; IR: %13 = copysign(pi/2, %4)  (block %12: sign ? -z : z, z = atanhi[3] + 0x1p-120f const-folded)
  %13 = call i32 @cq_template_icmp_ult_i32_hl(i32 %9, i32 1071382528)    ; IR: %15 = icmp ult %8, 0x3FDC0000  (block %14)  [predicate of block %16, and of %55 at %39: id < 0]
  %14 = call i32 @cq_template_icmp_ult_i32_hl(i32 %9, i32 1044381696)    ; IR: %17 = icmp ult %8, 0x3E400000  (block %16)  [br -> exit with x]
  %15 = call i32 @cq_template_fabs_f64(i32 %5)    ; IR: %19 = fabs(%4)  (block %18)
  %16 = call i32 @cq_template_icmp_ult_i32_hl(i32 %9, i32 1072889856)    ; IR: %20 = icmp ult %8, 0x3FF30000  [predicate of block %21]
  %17 = call i32 @cq_template_icmp_ult_i32_hl(i32 %9, i32 1072037888)    ; IR: %22 = icmp ult %8, 0x3FE60000  (block %21)  [predicate of block %23]
  %18 = call i32 @cq_template_fmul_f64_hl(i32 %15, double 2.000000e+00)    ; IR: %24 = fmuladd(%19, 2.0, -1.0)  (block %23: id = 0)  [unfused product]
  %19 = call i32 @cq_template_fadd_f64_hl(i32 %18, double -1.000000e+00)    ; IR: %24 = fmuladd(%19, 2.0, -1.0)  (block %23: id = 0)  [unfused sum]
  %20 = call i32 @cq_template_fadd_f64_hl(i32 %15, double 2.000000e+00)    ; IR: %25 = fadd %19, 2.0
  %21 = call i32 @cq_template_fdiv_f64(i32 %19, i32 %20)    ; IR: %26 = fdiv %24, %25  ((2x - 1) / (2 + x))
  %22 = call i32 @cq_template_fadd_f64_hl(i32 %15, double -1.000000e+00)    ; IR: %28 = fadd %19, -1.0  (block %27: id = 1)
  %23 = call i32 @cq_template_fadd_f64_hl(i32 %15, double 1.000000e+00)    ; IR: %29 = fadd %19, 1.0
  %24 = call i32 @cq_template_fdiv_f64(i32 %22, i32 %23)    ; IR: %30 = fdiv %28, %29  ((x - 1) / (x + 1))
  %25 = call i32 @cq_template_icmp_ult_i32_hl(i32 %9, i32 1073971200)    ; IR: %32 = icmp ult %8, 0x40038000  (block %31)  [predicate of block %33]
  %26 = call i32 @cq_template_fadd_f64_hl(i32 %15, double -1.500000e+00)    ; IR: %34 = fadd %19, -1.5  (block %33: id = 2)
  %27 = call i32 @cq_template_fmul_f64_hl(i32 %15, double 1.500000e+00)    ; IR: %35 = fmuladd(%19, 1.5, 1.0)  [unfused product]
  %28 = call i32 @cq_template_fadd_f64_hl(i32 %27, double 1.000000e+00)    ; IR: %35 = fmuladd(%19, 1.5, 1.0)  [unfused sum]
  %29 = call i32 @cq_template_fdiv_f64(i32 %26, i32 %28)    ; IR: %36 = fdiv %34, %35  ((x - 1.5) / (1 + 1.5x))
  %30 = call i32 @cq_template_fdiv_f64_lh(double -1.000000e+00, i32 %15)    ; IR: %38 = fdiv -1.0, %19  (block %37: id = 3)
  %31 = call i32 @cq_template_select_f64(i32 %17, i32 %21, i32 %24)    ; IR: %40 = phi [ %26, %23 ], [ %30, %27 ], [ %36, %33 ], [ %38, %37 ], [ %4, %16 ]: inner select on %22 (block %21)
  %32 = call i32 @cq_template_select_f64(i32 %25, i32 %29, i32 %30)    ; IR: %40 = phi: inner select on %32 (block %31)
  %33 = call i32 @cq_template_select_f64(i32 %16, i32 %31, i32 %32)    ; IR: %40 = phi: select on %20 (block %18)
  %34 = call i32 @cq_template_select_f64(i32 %13, i32 %5, i32 %33)    ; IR: %40 = phi: outer select on %15 (the %16 edge carries x unchanged)  [x after the argument reduction]
  %35 = call i32 @cq_template_select_i64_ll(i32 %17, i64 0, i64 1)    ; IR: %41 = phi i64 [ 0, %23 ], [ 1, %27 ], [ 2, %33 ], [ 3, %37 ], [ 4294967295, %16 ]: inner select on %22  (id, the i64 index rail at the phi's type: rule 20, never narrowed)
  %36 = call i32 @cq_template_select_i64_ll(i32 %25, i64 2, i64 3)    ; IR: %41 = phi: inner select on %32
  %37 = call i32 @cq_template_select_i64(i32 %16, i32 %35, i32 %36)    ; IR: %41 = phi: select on %20
  %38 = call i32 @cq_template_select_i64_lh(i32 %13, i64 4294967295, i32 %37)    ; IR: %41 = phi: outer select on %15 (4294967295 on the %16 edge; never read: the loads run under NOT %9 AND NOT %15)  [id]
  %39 = call i32 @cq_template_fmul_f64(i32 %34, i32 %34)    ; IR: %42 = fmul %40, %40  (z)
  %40 = call i32 @cq_template_fmul_f64(i32 %39, i32 %39)    ; IR: %43 = fmul %42, %42  (w)
  %41 = call i32 @cq_template_fmul_f64_hl(i32 %40, double 0x3F90AD3AE322DA11)    ; IR: %44 = fmuladd(%43, aT[10], aT[8])  [unfused product]
  %42 = call i32 @cq_template_fadd_f64_hl(i32 %41, double 0x3FA97B4B24760DEB)    ; IR: %44 = fmuladd(%43, aT[10], aT[8])  [unfused sum]
  %43 = call i32 @cq_template_fmul_f64(i32 %40, i32 %42)    ; IR: %45 = fmuladd(%43, %44, aT[6])  [unfused product]
  %44 = call i32 @cq_template_fadd_f64_hl(i32 %43, double 0x3FB10D66A0D03D51)    ; IR: %45 = fmuladd(%43, %44, aT[6])  [unfused sum]
  %45 = call i32 @cq_template_fmul_f64(i32 %40, i32 %44)    ; IR: %46 = fmuladd(%43, %45, aT[4])  [unfused product]
  %46 = call i32 @cq_template_fadd_f64_hl(i32 %45, double 0x3FB745CDC54C206E)    ; IR: %46 = fmuladd(%43, %45, aT[4])  [unfused sum]
  %47 = call i32 @cq_template_fmul_f64(i32 %40, i32 %46)    ; IR: %47 = fmuladd(%43, %46, aT[2])  [unfused product]
  %48 = call i32 @cq_template_fadd_f64_hl(i32 %47, double 0x3FC24924920083FF)    ; IR: %47 = fmuladd(%43, %46, aT[2])  [unfused sum]
  %49 = call i32 @cq_template_fmul_f64(i32 %40, i32 %48)    ; IR: %48 = fmuladd(%43, %47, aT[0])  [unfused product]
  %50 = call i32 @cq_template_fadd_f64_hl(i32 %49, double 0x3FD555555555550D)    ; IR: %48 = fmuladd(%43, %47, aT[0])  [unfused sum]
  %51 = call i32 @cq_template_fmul_f64(i32 %39, i32 %50)    ; IR: %49 = fmul %42, %48  (s1)
  %52 = call i32 @cq_template_fmul_f64_hl(i32 %40, double 0xBFA2B4442C6A6C2F)    ; IR: %50 = fmuladd(%43, aT[9], aT[7])  [unfused product]
  %53 = call i32 @cq_template_fadd_f64_hl(i32 %52, double 0xBFADDE2D52DEFD9A)    ; IR: %50 = fmuladd(%43, aT[9], aT[7])  [unfused sum]
  %54 = call i32 @cq_template_fmul_f64(i32 %40, i32 %53)    ; IR: %51 = fmuladd(%43, %50, aT[5])  [unfused product]
  %55 = call i32 @cq_template_fadd_f64_hl(i32 %54, double 0xBFB3B0F2AF749A6D)    ; IR: %51 = fmuladd(%43, %50, aT[5])  [unfused sum]
  %56 = call i32 @cq_template_fmul_f64(i32 %40, i32 %55)    ; IR: %52 = fmuladd(%43, %51, aT[3])  [unfused product]
  %57 = call i32 @cq_template_fadd_f64_hl(i32 %56, double 0xBFBC71C6FE231671)    ; IR: %52 = fmuladd(%43, %51, aT[3])  [unfused sum]
  %58 = call i32 @cq_template_fmul_f64(i32 %40, i32 %57)    ; IR: %53 = fmuladd(%43, %52, aT[1])  [unfused product]
  %59 = call i32 @cq_template_fadd_f64_hl(i32 %58, double 0xBFC999999998EBC4)    ; IR: %53 = fmuladd(%43, %52, aT[1])  [unfused sum]
  %60 = call i32 @cq_template_fmul_f64(i32 %40, i32 %59)    ; IR: %54 = fmul %43, %53  (s2)
  %61 = call i32 @cq_template_fadd_f64(i32 %60, i32 %51)    ; IR: %56 = fadd %54, %49  (block %55: id < 0, under %15)
  %62 = call i32 @cq_template_fneg_f64(i32 %34)    ; IR: %57 = fneg %40
  %63 = call i32 @cq_template_fmul_f64(i32 %62, i32 %61)    ; IR: %58 = fmuladd(%57, %56, %40)  (x - x * (s1 + s2))  [unfused product]
  %64 = call i32 @cq_template_fadd_f64(i32 %63, i32 %34)    ; IR: %58 = fmuladd(%57, %56, %40)  (x - x * (s1 + s2))  [unfused sum]
  %65 = call i32 @cq_template_mul_i64_hl(i32 %38, i64 8)    ; IR: %60 = getelementptr inbounds [4 x double], ptr @atanhi, i64 0, i64 %41  [the tainted index scaled by the element size (rule 20)]
  %66 = call i32 @cq_template_add_i64_hl(i32 %65, i64 ptrtoint (ptr @atanhi to i64))    ; IR: %60 = getelementptr  [+ the classical part, the table's host address: the address rail of &atanhi[id]]
  %67 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: the predicate of block %59: NOT %9 AND NOT %15 (rule 8: a conjunction into a fresh |0>)
  call void @cqrt_not_i1(i32 %10)    ; IR: X bracket: NOT %9
  call void @cqrt_not_i1(i32 %13)    ; IR: X bracket: NOT %15
  call void @cqrt_and_i1(i32 %10, i32 %13, i32 %67)    ; IR: br i1 %9 and br i1 %15 both not taken: the predicate of block %59
  call void @cqrt_not_i1(i32 %13)    ; IR: X bracket closes
  call void @cqrt_not_i1(i32 %10)    ; IR: X bracket closes
  %68 = call i32 @cqrt_qram_load_f64_controlled(i32 %67, i32 %4, i32 %66)    ; IR: %61 = load double, ptr %60  [a bus load at an address rail under the block predicate: fresh rail ^= the 8 HOST cells, |0> where the predicate is 0] (block %59)
  %69 = call i32 @cq_template_fadd_f64(i32 %60, i32 %51)    ; IR: %62 = fadd %54, %49  (s1 + s2, recomputed by -O1 in block %59)
  %70 = call i32 @cq_template_mul_i64_hl(i32 %38, i64 8)    ; IR: %63 = getelementptr inbounds [4 x double], ptr @atanlo, i64 0, i64 %41  [its own scale of the shared id rail (rule 20)]
  %71 = call i32 @cq_template_add_i64_hl(i32 %70, i64 ptrtoint (ptr @atanlo to i64))    ; IR: %63 = getelementptr  [+ the table's host address: the address rail of &atanlo[id]]
  %72 = call i32 @cqrt_qram_load_f64_controlled(i32 %67, i32 %4, i32 %71)    ; IR: %64 = load double, ptr %63  [a bus load at an address rail under the block predicate]
  %73 = call i32 @cq_template_fneg_f64(i32 %72)    ; IR: %65 = fneg %64
  %74 = call i32 @cq_template_fmul_f64(i32 %34, i32 %69)    ; IR: %66 = fmuladd(%40, %62, %65)  (x * (s1 + s2) - atanlo[id])  [unfused product]
  %75 = call i32 @cq_template_fadd_f64(i32 %74, i32 %73)    ; IR: %66 = fmuladd(%40, %62, %65)  (x * (s1 + s2) - atanlo[id])  [unfused sum]
  %76 = call i32 @cq_template_fsub_f64(i32 %75, i32 %34)    ; IR: %67 = fsub %66, %40
  %77 = call i32 @cq_template_fsub_f64(i32 %68, i32 %76)    ; IR: %68 = fsub %61, %67  (z = atanhi[id] - (...))
  %78 = call i32 @cq_template_fneg_f64(i32 %77)    ; IR: %69 = fneg %68
  %79 = call i32 @cq_template_icmp_slt_i64_hl(i32 %6, i64 0)    ; IR: %70 = icmp slt %5, 0  (sign)
  %80 = call i32 @cq_template_select_f64(i32 %79, i32 %78, i32 %77)    ; IR: %71 = select %70, %69, %68  (sign ? -z : z)
  %81 = call i32 @cq_template_select_f64(i32 %11, i32 %5, i32 %12)    ; IR: %73 = phi [ %13, %12 ], [ %58, %55 ], [ %71, %59 ], [ %4, %10 ], [ %4, %16 ]: select on %11 (block %10: NaN returns x, else copysign)
  %82 = call i32 @cq_template_select_f64(i32 %14, i32 %5, i32 %64)    ; IR: %73 = phi: select on %17 (block %16: tiny returns x, else the id < 0 result of %55)
  %83 = call i32 @cq_template_select_f64(i32 %13, i32 %82, i32 %80)    ; IR: %73 = phi: select on %15 (block %14: the %16 side against the %59 result)
  %84 = call i32 @cq_template_select_f64(i32 %10, i32 %81, i32 %83)    ; IR: %73 = phi: outer select on %9 (block %10 side against block %14 side)  [atan(x)]
  %85 = call i32 @cq_template_fmul_f64_hl(i32 %84, double %2)    ; IR: %74 = fmul %73, %2  [result rail]
  call void @cq_template_select_f64_unc(i32 %84, i32 %10, i32 %81, i32 %83)    ; IR: uncompute %73
  call void @cqrt_free(i32 %84)    ; IR: release the %73 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %83, i32 %13, i32 %82, i32 %80)    ; IR: uncompute %73
  call void @cqrt_free(i32 %83)    ; IR: release the %73 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %82, i32 %14, i32 %5, i32 %64)    ; IR: uncompute %73
  call void @cqrt_free(i32 %82)    ; IR: release the %73 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %81, i32 %11, i32 %5, i32 %12)    ; IR: uncompute %73
  call void @cqrt_free(i32 %81)    ; IR: release the %73 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %80, i32 %79, i32 %78, i32 %77)    ; IR: uncompute %71
  call void @cqrt_free(i32 %80)    ; IR: release the %71 rail (|0>)
  call void @cq_template_icmp_slt_i64_hl_unc(i32 %79, i32 %6, i64 0)    ; IR: uncompute %70
  call void @cqrt_free(i32 %79)    ; IR: release the %70 rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %78, i32 %77)    ; IR: uncompute %69
  call void @cqrt_free(i32 %78)    ; IR: release the %69 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %77, i32 %68, i32 %76)    ; IR: uncompute %68
  call void @cqrt_free(i32 %77)    ; IR: release the %68 rail (|0>)
  call void @cq_template_fsub_f64_unc(i32 %76, i32 %75, i32 %34)    ; IR: uncompute %67
  call void @cqrt_free(i32 %76)    ; IR: release the %67 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %75, i32 %74, i32 %73)    ; IR: uncompute %66  [sum]
  call void @cqrt_free(i32 %75)    ; IR: release the %66 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %74, i32 %34, i32 %69)    ; IR: uncompute %66  [product]
  call void @cqrt_free(i32 %74)    ; IR: release the %66 product rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %73, i32 %72)    ; IR: uncompute %65
  call void @cqrt_free(i32 %73)    ; IR: release the %65 rail (|0>)
  call void @cqrt_qram_load_f64_controlled_unc(i32 %72, i32 %67, i32 %4, i32 %71)    ; IR: un-copy %64 (rule 5, Memory: no memory version change since the load; the predicate at its load value)
  call void @cqrt_free(i32 %72)    ; IR: release the %64 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %71, i32 %70, i64 ptrtoint (ptr @atanlo to i64))    ; IR: uncompute %63  [the address rail outlives its load's _unc (rule 20)]
  call void @cqrt_free(i32 %71)    ; IR: release the %63 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %70, i32 %38, i64 8)    ; IR: uncompute %63 (the scaled index)
  call void @cqrt_free(i32 %70)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %69, i32 %60, i32 %51)    ; IR: uncompute %62
  call void @cqrt_free(i32 %69)    ; IR: release the %62 rail (|0>)
  call void @cqrt_qram_load_f64_controlled_unc(i32 %68, i32 %67, i32 %4, i32 %66)    ; IR: un-copy %61 (rule 5, Memory)
  call void @cqrt_free(i32 %68)    ; IR: release the %61 rail (|0>)
  call void @cqrt_not_i1(i32 %10)    ; IR: X bracket: NOT %9
  call void @cqrt_not_i1(i32 %13)    ; IR: X bracket: NOT %15
  call void @cqrt_and_i1(i32 %10, i32 %13, i32 %67)    ; IR: uncompute the predicate of block %59 (after its last controlled access)
  call void @cqrt_not_i1(i32 %13)    ; IR: X bracket closes
  call void @cqrt_not_i1(i32 %10)    ; IR: X bracket closes
  call void @cqrt_free(i32 %67)    ; IR: release the block-%59 predicate rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %66, i32 %65, i64 ptrtoint (ptr @atanhi to i64))    ; IR: uncompute %60  [the address rail outlives its load's _unc (rule 20)]
  call void @cqrt_free(i32 %66)    ; IR: release the %60 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %65, i32 %38, i64 8)    ; IR: uncompute %60 (the scaled index)
  call void @cqrt_free(i32 %65)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %64, i32 %63, i32 %34)    ; IR: uncompute %58  [sum]
  call void @cqrt_free(i32 %64)    ; IR: release the %58 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %63, i32 %62, i32 %61)    ; IR: uncompute %58  [product]
  call void @cqrt_free(i32 %63)    ; IR: release the %58 product rail (|0>)
  call void @cq_template_fneg_f64_unc(i32 %62, i32 %34)    ; IR: uncompute %57
  call void @cqrt_free(i32 %62)    ; IR: release the %57 rail (|0>)
  call void @cq_template_fadd_f64_unc(i32 %61, i32 %60, i32 %51)    ; IR: uncompute %56
  call void @cqrt_free(i32 %61)    ; IR: release the %56 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %60, i32 %40, i32 %59)    ; IR: uncompute %54
  call void @cqrt_free(i32 %60)    ; IR: release the %54 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %59, i32 %58, double 0xBFC999999998EBC4)    ; IR: uncompute %53  [sum]
  call void @cqrt_free(i32 %59)    ; IR: release the %53 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %58, i32 %40, i32 %57)    ; IR: uncompute %53  [product]
  call void @cqrt_free(i32 %58)    ; IR: release the %53 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %57, i32 %56, double 0xBFBC71C6FE231671)    ; IR: uncompute %52  [sum]
  call void @cqrt_free(i32 %57)    ; IR: release the %52 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %56, i32 %40, i32 %55)    ; IR: uncompute %52  [product]
  call void @cqrt_free(i32 %56)    ; IR: release the %52 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %55, i32 %54, double 0xBFB3B0F2AF749A6D)    ; IR: uncompute %51  [sum]
  call void @cqrt_free(i32 %55)    ; IR: release the %51 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %54, i32 %40, i32 %53)    ; IR: uncompute %51  [product]
  call void @cqrt_free(i32 %54)    ; IR: release the %51 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %53, i32 %52, double 0xBFADDE2D52DEFD9A)    ; IR: uncompute %50  [sum]
  call void @cqrt_free(i32 %53)    ; IR: release the %50 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %52, i32 %40, double 0xBFA2B4442C6A6C2F)    ; IR: uncompute %50  [product]
  call void @cqrt_free(i32 %52)    ; IR: release the %50 product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %51, i32 %39, i32 %50)    ; IR: uncompute %49
  call void @cqrt_free(i32 %51)    ; IR: release the %49 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %50, i32 %49, double 0x3FD555555555550D)    ; IR: uncompute %48  [sum]
  call void @cqrt_free(i32 %50)    ; IR: release the %48 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %49, i32 %40, i32 %48)    ; IR: uncompute %48  [product]
  call void @cqrt_free(i32 %49)    ; IR: release the %48 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %48, i32 %47, double 0x3FC24924920083FF)    ; IR: uncompute %47  [sum]
  call void @cqrt_free(i32 %48)    ; IR: release the %47 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %47, i32 %40, i32 %46)    ; IR: uncompute %47  [product]
  call void @cqrt_free(i32 %47)    ; IR: release the %47 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %46, i32 %45, double 0x3FB745CDC54C206E)    ; IR: uncompute %46  [sum]
  call void @cqrt_free(i32 %46)    ; IR: release the %46 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %45, i32 %40, i32 %44)    ; IR: uncompute %46  [product]
  call void @cqrt_free(i32 %45)    ; IR: release the %46 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %44, i32 %43, double 0x3FB10D66A0D03D51)    ; IR: uncompute %45  [sum]
  call void @cqrt_free(i32 %44)    ; IR: release the %45 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %43, i32 %40, i32 %42)    ; IR: uncompute %45  [product]
  call void @cqrt_free(i32 %43)    ; IR: release the %45 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %42, i32 %41, double 0x3FA97B4B24760DEB)    ; IR: uncompute %44  [sum]
  call void @cqrt_free(i32 %42)    ; IR: release the %44 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %41, i32 %40, double 0x3F90AD3AE322DA11)    ; IR: uncompute %44  [product]
  call void @cqrt_free(i32 %41)    ; IR: release the %44 product rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %40, i32 %39, i32 %39)    ; IR: uncompute %43
  call void @cqrt_free(i32 %40)    ; IR: release the %43 rail (|0>)
  call void @cq_template_fmul_f64_unc(i32 %39, i32 %34, i32 %34)    ; IR: uncompute %42
  call void @cqrt_free(i32 %39)    ; IR: release the %42 rail (|0>)
  call void @cq_template_select_i64_lh_unc(i32 %38, i32 %13, i64 4294967295, i32 %37)    ; IR: uncompute %41
  call void @cqrt_free(i32 %38)    ; IR: release the %41 rail (|0>)
  call void @cq_template_select_i64_unc(i32 %37, i32 %16, i32 %35, i32 %36)    ; IR: uncompute %41
  call void @cqrt_free(i32 %37)    ; IR: release the %41 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %36, i32 %25, i64 2, i64 3)    ; IR: uncompute %41
  call void @cqrt_free(i32 %36)    ; IR: release the %41 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %35, i32 %17, i64 0, i64 1)    ; IR: uncompute %41
  call void @cqrt_free(i32 %35)    ; IR: release the %41 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %34, i32 %13, i32 %5, i32 %33)    ; IR: uncompute %40
  call void @cqrt_free(i32 %34)    ; IR: release the %40 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %33, i32 %16, i32 %31, i32 %32)    ; IR: uncompute %40
  call void @cqrt_free(i32 %33)    ; IR: release the %40 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %32, i32 %25, i32 %29, i32 %30)    ; IR: uncompute %40
  call void @cqrt_free(i32 %32)    ; IR: release the %40 rail (|0>)
  call void @cq_template_select_f64_unc(i32 %31, i32 %17, i32 %21, i32 %24)    ; IR: uncompute %40
  call void @cqrt_free(i32 %31)    ; IR: release the %40 rail (|0>)
  call void @cq_template_fdiv_f64_lh_unc(i32 %30, double -1.000000e+00, i32 %15)    ; IR: uncompute %38
  call void @cqrt_free(i32 %30)    ; IR: release the %38 rail (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %29, i32 %26, i32 %28)    ; IR: uncompute %36
  call void @cqrt_free(i32 %29)    ; IR: release the %36 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %28, i32 %27, double 1.000000e+00)    ; IR: uncompute %35  [sum]
  call void @cqrt_free(i32 %28)    ; IR: release the %35 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %27, i32 %15, double 1.500000e+00)    ; IR: uncompute %35  [product]
  call void @cqrt_free(i32 %27)    ; IR: release the %35 product rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %26, i32 %15, double -1.500000e+00)    ; IR: uncompute %34
  call void @cqrt_free(i32 %26)    ; IR: release the %34 rail (|0>)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %25, i32 %9, i32 1073971200)    ; IR: uncompute %32
  call void @cqrt_free(i32 %25)    ; IR: release the %32 rail (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %24, i32 %22, i32 %23)    ; IR: uncompute %30
  call void @cqrt_free(i32 %24)    ; IR: release the %30 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %23, i32 %15, double 1.000000e+00)    ; IR: uncompute %29
  call void @cqrt_free(i32 %23)    ; IR: release the %29 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %22, i32 %15, double -1.000000e+00)    ; IR: uncompute %28
  call void @cqrt_free(i32 %22)    ; IR: release the %28 rail (|0>)
  call void @cq_template_fdiv_f64_unc(i32 %21, i32 %19, i32 %20)    ; IR: uncompute %26
  call void @cqrt_free(i32 %21)    ; IR: release the %26 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %20, i32 %15, double 2.000000e+00)    ; IR: uncompute %25
  call void @cqrt_free(i32 %20)    ; IR: release the %25 rail (|0>)
  call void @cq_template_fadd_f64_hl_unc(i32 %19, i32 %18, double -1.000000e+00)    ; IR: uncompute %24  [sum]
  call void @cqrt_free(i32 %19)    ; IR: release the %24 rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %18, i32 %15, double 2.000000e+00)    ; IR: uncompute %24  [product]
  call void @cqrt_free(i32 %18)    ; IR: release the %24 product rail (|0>)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %17, i32 %9, i32 1072037888)    ; IR: uncompute %22
  call void @cqrt_free(i32 %17)    ; IR: release the %22 rail (|0>)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %16, i32 %9, i32 1072889856)    ; IR: uncompute %20
  call void @cqrt_free(i32 %16)    ; IR: release the %20 rail (|0>)
  call void @cq_template_fabs_f64_unc(i32 %15, i32 %5)    ; IR: uncompute %19
  call void @cqrt_free(i32 %15)    ; IR: release the %19 rail (|0>)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %14, i32 %9, i32 1044381696)    ; IR: uncompute %17
  call void @cqrt_free(i32 %14)    ; IR: release the %17 rail (|0>)
  call void @cq_template_icmp_ult_i32_hl_unc(i32 %13, i32 %9, i32 1071382528)    ; IR: uncompute %15
  call void @cqrt_free(i32 %13)    ; IR: release the %15 rail (|0>)
  call void @cq_template_copysign_f64_lh_unc(i32 %12, double 0x3FF921FB54442D18, i32 %5)    ; IR: uncompute %13
  call void @cqrt_free(i32 %12)    ; IR: release the %13 rail (|0>)
  call void @cq_template_fcmp_uno_f64_hl_unc(i32 %11, i32 %5, double 0.000000e+00)    ; IR: uncompute %11
  call void @cqrt_free(i32 %11)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_ugt_i32_hl_unc(i32 %10, i32 %9, i32 1141899263)    ; IR: uncompute %9
  call void @cqrt_free(i32 %10)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %8, i32 2147483647)    ; IR: uncompute %8
  call void @cqrt_free(i32 %9)    ; IR: release the %8 rail (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %8, i32 %7)    ; IR: uncompute %7
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %7, i32 %6, i64 32)    ; IR: uncompute %6
  call void @cqrt_free(i32 %7)    ; IR: release the %6 rail (|0>)
  call void @cq_template_bitcast_f64_to_i64_unc(i32 %6, i32 %5)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  %86 = call double @cqrt_measure_f64(i32 %85)    ; IR: %75 = cq_measure_f64(%74)
  ret double %86    ; IR: ret %75
}

declare void @cqrt_free(i32)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_ry_f64(i32, double)
declare i32 @cq_template_bitcast_f64_to_i64(i32)
declare void @cq_template_bitcast_f64_to_i64_unc(i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare void @cq_template_icmp_ugt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_fcmp_uno_f64_hl(i32, double)
declare void @cq_template_fcmp_uno_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_copysign_f64_lh(double, i32)
declare void @cq_template_copysign_f64_lh_unc(i32, double, i32)
declare i32 @cq_template_icmp_ult_i32_hl(i32, i32)
declare void @cq_template_icmp_ult_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_fabs_f64(i32)
declare void @cq_template_fabs_f64_unc(i32, i32)
declare i32 @cq_template_fadd_f64_hl(i32, double)
declare void @cq_template_fadd_f64_hl_unc(i32, i32, double)
declare i32 @cq_template_fdiv_f64(i32, i32)
declare void @cq_template_fdiv_f64_unc(i32, i32, i32)
declare i32 @cq_template_fdiv_f64_lh(double, i32)
declare void @cq_template_fdiv_f64_lh_unc(i32, double, i32)
declare i32 @cq_template_select_f64(i32, i32, i32)
declare void @cq_template_select_f64_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_select_i64(i32, i32, i32)
declare void @cq_template_select_i64_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i64_lh(i32, i64, i32)
declare void @cq_template_select_i64_lh_unc(i32, i32, i64, i32)
declare i32 @cq_template_fmul_f64(i32, i32)
declare void @cq_template_fmul_f64_unc(i32, i32, i32)
declare i32 @cq_template_fadd_f64(i32, i32)
declare void @cq_template_fadd_f64_unc(i32, i32, i32)
declare i32 @cq_template_fneg_f64(i32)
declare void @cq_template_fneg_f64_unc(i32, i32)
declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_f64_controlled(i32, i32, i32)
declare void @cqrt_qram_load_f64_controlled_unc(i32, i32, i32, i32)
declare i32 @cq_template_fsub_f64(i32, i32)
declare void @cq_template_fsub_f64_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i64_hl(i32, i64)
declare void @cq_template_icmp_slt_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare double @cqrt_measure_f64(i32)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
