; HAND-WRITTEN. Rules: 20, 21, 16, 2, 3, 4, 5, 7, 14; §1.3 (the bus, __cq_mem, __cq_alloc, qram_swap).
; Checked: m = sum_i cq_measure(x[i]) << i and f = sum_i cq_measure(y[i]) << i: each measured bit is the i1 load copy of
; cell x + i (IR %66/%67 -> %68) or y + i (IR %84/%85 -> %86). The cells of the blocks x and y on the bus at exit: the
; low bit of cell x + i holds the measured outcome of x[i], that of cell y + i the measured y[i] (their high 7 bits 0).
; Clean: per H trip and per Ry(-pi/2) trip, the swap rail of the in-place form (|0> after its swap-in, freed). Per oracle
; trip: the i8 load copy of x[i] (%34), its zext rail (%35), the and rail (%38) and the compare rail (%39), all
; uncomputed and freed in the trip before the store into y[i] (rule 5 sentence 1: the copy's last reader, the zext _unc,
; precedes the store, the next memory version change). After the oracle loop: the zext rail of the x[j] copy (%18).
; Left allocated, un-copied: the i8 load copy of x[j] (%17), un-copied at the loop exit after its last reader, the zext
; _unc; the stores into y lie between, so it is overtaken and not freed (rule 5 sentence 1).
; Kept: by rule 5 sentence 3 the nq kept stores `store i8 0, ptr %22` of the H loop, each with its tape slot and its
; value seed alloc_i8(0) (rule 7; classical-valued, no qubit), and the nq kept stores into y[i], each with its tape
; slot (the displaced cell: 0 from __cq_alloc) and its value rail, the zext_i1_to_i8 rail of %41 (a basis copy of y[i]);
; by rule 2 the 2 nq measured i1 load copies (%67, %85). The cells x[i] and
; y[i] themselves are the registers.
; Rotations: (Ry, cell x[i], pi/2, 1) for i = 0..nq-1; (Ry, cell x[i], -pi/2, 1) for i = 0..nq-1. No phase gate.
; Simon's problem on nq input qubits, nq and s runtime parameters: every loop is a ROLLED classical loop with the
; classical bound nq (rule 14), and no size is fixed at compile time. ONE BUS (rules 16, 20, 21). `bool x[nq], y[nq]`
; are -O1's two `alloca i8, i64 nq`; each stores a tainted value (x the rotated bit, y the oracle bit), which no user of
; rule 20 (b) allows, so both are BUS-RESIDENT: __cq_alloc(nq, 16) each at its program point, no alloca remains (rule 16:
; zeroed host memory at an address never reused; the size is classical, no K2). m = __cq_mem() is called once, at entry
; (§5). Every index is the classical loop counter (or the classical j), so every getelementptr stays and every access is
; `_hl` at the ptrtoint of its getelementptr. The cells are the registers: no handle is ever stored (§1.1).
; Gate shapes:
;  (0) H layer `x[i] = false; cq_theta(&x[i], pi/2)`: `store i8 0, ptr %22` is a KEPT store of the seed alloc_i8(0)
;      (rules 5 sentence 3, 7); -O1 forwarded the stored 0 into the theta (`cq_theta_i1(false, ..)`), and the theta,
;      `zext`, `store i8 %24, ptr %22` is rule 5's in-place form at width i1 (Readers: y is the forwarded value, the
;      interval runs from the first store; Width casts), as 115: alloc_i1(0), qram_swap_i1_hl, Ry(pi/2) on the swap
;      rail, qram_swap_i1_hl, free.
;  (1) oracle y[i] = x[i] ^ (x[j] & ((s >> i) & 1)): LICM hoisted `load i8 x[j]; zext nneg i8 to i32` into the guarded
;      preheader %14: a bus load at the access type i8 (no trunc), qram_load_i8_hl, and zext_i8_to_i32 into a fresh rail
;      read by every trip. Per trip: x[i] is qram_load_i8_hl and zext_i8_to_i32 (fresh rails), the and against the
;      classical s >> i is and_i32_hl (handle first), the `icmp ne` of the two is icmp_ne_i32 into a fresh i1 rail, and
;      `zext i1 to i8; store i8` into y[i] is the zext_i1_to_i8 template (rule 4) and a kept store qram_store_i8_hl of
;      its rail (rules 5 sentence 3, 20: the access type i8). The compare rail's only consumer is that zext, whose rail
;      is kept, so the compare, the and, the x[i] zext and the x[i] copy are uncomputed right after the zext, before
;      the store. The x[j] copy is read through its zext rail by every trip, the last read is the zext _unc at the loop
;      exit, after the stores: the copy is un-copied right after that _unc and, overtaken, not freed (rule 5 sentence 1).
;  (2) Ry(-pi/2) layer: `load i8; trunc nuw to i1; cq_theta_i1; zext; store i8` on the SSA pointer %50 is rule 5's
;      in-place form at width i1: alloc_i1(0), qram_swap_i1_hl, Ry(-pi/2) on the swap rail, qram_swap_i1_hl, free.
;  (3) measure loops: `load i8; trunc nuw to i1; cq_measure_i1` is a plain bus load at width i1 (SPEC GAP 1), measured
;      and never un-copied (rule 2).
; Nothing is pushed: every rail that rule 5 does not keep dies inside its trip or at the oracle loop's exit (rule 14).
; Expected: the x[j] copy is a computational-basis record of x[j] taken after H^n and before the oracle; it is
;   un-copied at the oracle loop's exit, before the second H^n. The stores between write only y's cells, so the un-copy
;   reads the value it copied and leaves the rail |0> (rule 5 never asks this, so the rail is not freed): x is not
;   entangled with it, and the Simon property holds. Analytic (not replayed): simon(3, 5) -> m in {0, 2, 5, 7}
;   (p = 1/4 each), y uniform over the 4 values with y_0 = 0; simon(4, 6) -> m in {0, 1, 6, 7, 8, 9, 14, 15} (p = 1/8
;   each), y uniform over the 8 values with y_1 = 0; every m . s = 0. The other kept rails are classical-valued (the
;   seeds, the tape slots of zeroed cells) or basis copies of the measured y (the y store value rails), and change no
;   outcome. Return value m | (f << 16).
; -O1 keeps the five loops (H, oracle, Ry(-pi/2), measure x, measure y) in source order: the oracle loop reads x's cells after the Ry(pi/2) loop and before the
; Ry(-pi/2) loop, so every gate is emitted at the position of the instruction it lowers. The `(s >> i) & zext(x[j])`
; keeps all 32 bits of s >> i, but x[j] is 0 or 1, so the and rail is ((s >> i) & 1) & x[j]; `icmp ne` against
; zext(x[i]) is the xor of two bits.
; SPEC GAP 1: rule 5's Width-casts clause fixes the width U = i1 only for a reader's plain load of a form. The measure
; loops' `load i8; trunc nuw to i1` reads no SSA value of a form; chosen as 115 and 117 do: one qram_load_i1_hl at the
; trunc's width (the low bit of the cell), measured, not a qram_load_i8 and a trunc template. The oracle's `load i8`
; feeds `zext nneg i8 to i32` with no trunc and is qram_load_i8_hl at the access type.
source_filename = "simon.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @simon(i32 noundef %0, i32 noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle m (once, at function entry, §5)
  %4 = zext i32 %0 to i64    ; IR: %3 = zext i32 %0 to i64  (classical nq: each block's size in bytes)
  %5 = call ptr @__cq_alloc(i64 %4, i64 16)    ; IR: %4 = alloca i8, i64 %3, align 16  [x: bus-resident (a store of a tainted value): one zeroed block, no alloca remains (rules 16, 20)]
  %6 = call ptr @__cq_alloc(i64 %4, i64 16)    ; IR: %5 = alloca i8, i64 %3, align 16  [y: bus-resident (a store of a tainted value): one zeroed block]
  %7 = icmp eq i32 %1, 0    ; IR: %6  (classical)
  %8 = call i32 @llvm.cttz.i32(i32 %1, i1 true)    ; IR: %7 = llvm.cttz.i32(%1, true)  (classical)
  %9 = select i1 %7, i32 0, i32 %8    ; IR: %8  (classical j)
  %10 = icmp sgt i32 %0, 0    ; IR: %9  (classical)
  br i1 %10, label %11, label %21    ; IR: br i1 %9, label %10, label %12

11:; IR: block %10
  %12 = zext nneg i32 %0 to i64    ; IR: %11  (classical bound)
  br label %13    ; IR: br label %20

13:; IR: block %20  (x[i] = false; H^n: the Ry(pi/2) loop, classical bound nq)
  %14 = phi i64 [ 0, %11 ], [ %19, %13 ]    ; IR: %21  (classical i)
  %15 = getelementptr inbounds i8, ptr %5, i64 %14    ; IR: %22 = getelementptr inbounds i8, ptr %4, i64 %21  (untainted index: stays)
  %16 = ptrtoint ptr %15 to i64    ; IR: %22 as its run-time address (the _hl operand)
  %17 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i8 0, ptr %22  [the seed of the classical 0: the store's value rail, KEPT with it (rules 5, 7)]
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %16, i32 %17)    ; IR: store i8 0, ptr %22  [a kept store at a classical address (rule 5 sentence 3); classical-valued, the cell stays HOST]
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %23 = cq_theta_i1(false, pi/2): in-place form at width i1 on %22, y the 0 -O1 forwarded from the store (rule 5 Readers, Width casts); the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %16, i32 %18)    ; IR: swap-out of the low bit: the rail holds x[i] (= 0), the cell's bit |0>
  call void @cqrt_ry_i1(i32 %18, double 0x3FF921FB54442D18)    ; IR: %23 = cq_theta_i1(false, pi/2)  [Ry(pi/2) on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %16, i32 %18)    ; IR: %24 = zext i1 %23 to i8; store i8 %24, ptr %22: swap-in: the cell holds x[i]
  call void @cqrt_free(i32 %18)    ; IR: release the swap rail (|0>)
  %19 = add nuw nsw i64 %14, 1    ; IR: %25  (classical)
  %20 = icmp eq i64 %19, %12    ; IR: %26  (classical)
  br i1 %20, label %21, label %13    ; IR: br i1 %26, label %12, label %20

21:; IR: block %12
  %22 = icmp sgt i32 %0, 0    ; IR: %13  (classical)
  br i1 %22, label %23, label %46    ; IR: br i1 %13, label %14, label %27

23:; IR: block %14  (the oracle loop's preheader)
  %24 = zext nneg i32 %9 to i64    ; IR: %15  (classical)
  %25 = getelementptr inbounds i8, ptr %5, i64 %24    ; IR: %16 = getelementptr inbounds i8, ptr %4, i64 %15  (the cell x[j]; untainted index: stays)
  %26 = ptrtoint ptr %25 to i64    ; IR: %16 as its run-time address
  %27 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %26)    ; IR: %17 = load i8, ptr %16  [a bus load at the access type i8 (no trunc): the copy of x[j]; the stores into y overtake it before its last reader: un-copied at the loop exit, not freed (rule 5 sentence 1)]
  %28 = call i32 @cq_template_zext_i8_to_i32(i32 %27)    ; IR: %18 = zext nneg i8 %17 to i32  [x[j] widened into a fresh rail]
  %29 = zext nneg i32 %0 to i64    ; IR: %19  (classical bound)
  br label %30    ; IR: br label %31

30:; IR: block %31  (the oracle: y[i] = x[i] ^ (x[j] & s_i), classical bound nq)
  %31 = phi i64 [ 0, %23 ], [ %43, %30 ]    ; IR: %32  (classical i)
  %32 = getelementptr inbounds i8, ptr %5, i64 %31    ; IR: %33 = getelementptr inbounds i8, ptr %4, i64 %32  (untainted index: stays)
  %33 = ptrtoint ptr %32 to i64    ; IR: %33 as its run-time address
  %34 = call i32 @cqrt_qram_load_i8_hl(i32 %3, i64 %33)    ; IR: %34 = load i8, ptr %33  [a bus load at the access type i8: the copy of x[i]]
  %35 = call i32 @cq_template_zext_i8_to_i32(i32 %34)    ; IR: %35 = zext nneg i8 %34 to i32  [fresh rail]
  %36 = trunc nuw nsw i64 %31 to i32    ; IR: %36  (classical)
  %37 = lshr i32 %1, %36    ; IR: %37 = lshr i32 %1, %36  (classical s >> i)
  %38 = call i32 @cq_template_and_i32_hl(i32 %28, i32 %37)    ; IR: %38 = and i32 %37, %18  [commutative: handle first; fresh rail]
  %39 = call i32 @cq_template_icmp_ne_i32(i32 %38, i32 %35)    ; IR: %39 = icmp ne i32 %38, %35  [fresh i1 rail: the bit y[i]]
  %40 = getelementptr inbounds i8, ptr %6, i64 %31    ; IR: %40 = getelementptr inbounds i8, ptr %5, i64 %32  (untainted index: stays)
  %41 = ptrtoint ptr %40 to i64    ; IR: %40 as its run-time address
  %42 = call i32 @cq_template_zext_i1_to_i8(i32 %39)    ; IR: %41 = zext i1 %39 to i8  [fresh rail: the value rail of the store, KEPT with it (rule 5 sentence 3)]
  call void @cq_template_icmp_ne_i32_unc(i32 %39, i32 %38, i32 %35)    ; IR: uncompute %39 (its last consumer was %41, whose rail is kept and never uncomputed)
  call void @cqrt_free(i32 %39)    ; IR: release the %39 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %38, i32 %28, i32 %37)    ; IR: uncompute %38
  call void @cqrt_free(i32 %38)    ; IR: release the %38 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %35, i32 %34)    ; IR: uncompute %35
  call void @cqrt_free(i32 %35)    ; IR: release the %35 rail (|0>)
  call void @cqrt_qram_load_i8_hl_unc(i32 %34, i32 %3, i64 %33)    ; IR: un-copy %34 (rule 5 sentence 1: its last reader, the %35 _unc, precedes the store below, the next memory version change)
  call void @cqrt_free(i32 %34)    ; IR: release the %34 rail (|0>)
  call void @cqrt_qram_store_i8_hl(i32 %3, i64 %41, i32 %42)    ; IR: store i8 %41, ptr %40  [a kept store at a classical address (rule 5 sentence 3): its tape slot and its value rail %41 stay; the cell holds y[i]]
  %43 = add nuw nsw i64 %31, 1    ; IR: %42  (classical)
  %44 = icmp eq i64 %43, %29    ; IR: %43  (classical)
  br i1 %44, label %45, label %30    ; IR: br i1 %43, label %27, label %31

45:; IR: edge %31 -> %27 (the oracle loop's exit)
  call void @cq_template_zext_i8_to_i32_unc(i32 %28, i32 %27)    ; IR: uncompute %18 after its last consumer (the x[j] copy unchanged)
  call void @cqrt_free(i32 %28)    ; IR: release the %18 rail (|0>)
  call void @cqrt_qram_load_i8_hl_unc(i32 %27, i32 %3, i64 %26)    ; IR: un-copy %17 after its last reader, the %18 _unc; the stores into y lie between (memory version changes), so it is not freed (rule 5 sentence 1)
  br label %46    ; IR: br label %27

46:; IR: block %27
  %47 = icmp sgt i32 %0, 0    ; IR: %28  (classical)
  br i1 %47, label %48, label %50    ; IR: br i1 %28, label %29, label %44

48:; IR: block %29
  %49 = zext nneg i32 %0 to i64    ; IR: %30  (classical bound)
  br label %54    ; IR: br label %48

50:; IR: block %44
  %51 = icmp sgt i32 %0, 0    ; IR: %45  (classical)
  br i1 %51, label %52, label %61    ; IR: br i1 %45, label %46, label %57

52:; IR: block %46
  %53 = zext nneg i32 %0 to i64    ; IR: %47  (classical bound)
  br label %66    ; IR: br label %62

54:; IR: block %48  (H^n: the Ry(-pi/2) loop, classical bound nq)
  %55 = phi i64 [ 0, %48 ], [ %59, %54 ]    ; IR: %49  (classical i)
  %56 = getelementptr inbounds i8, ptr %5, i64 %55    ; IR: %50 = getelementptr inbounds i8, ptr %4, i64 %49  (untainted index: stays)
  %57 = ptrtoint ptr %56 to i64    ; IR: %50 as its run-time address
  %58 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %51 = load i8, ptr %50; %52 = trunc nuw to i1: in-place form at width i1 (rule 5, Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %57, i32 %58)    ; IR: %51/%52: swap-out: the rail holds x[i], the cell's bit |0>
  call void @cqrt_ry_i1(i32 %58, double 0xBFF921FB54442D18)    ; IR: %53 = cq_theta_i1(%52, -pi/2)  [Ry(-pi/2) on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %3, i64 %57, i32 %58)    ; IR: %54 = zext i1 %53 to i8; store i8 %54, ptr %50: swap-in: the cell holds %53
  call void @cqrt_free(i32 %58)    ; IR: release the swap rail (|0>)
  %59 = add nuw nsw i64 %55, 1    ; IR: %55  (classical)
  %60 = icmp eq i64 %59, %49    ; IR: %56  (classical)
  br i1 %60, label %50, label %54    ; IR: br i1 %56, label %44, label %48

61:; IR: block %57
  %62 = phi i32 [ 0, %50 ], [ %76, %66 ]    ; IR: %58  (classical m)
  %63 = icmp sgt i32 %0, 0    ; IR: %59  (classical)
  br i1 %63, label %64, label %81    ; IR: br i1 %59, label %60, label %77

64:; IR: block %60
  %65 = zext nneg i32 %0 to i64    ; IR: %61  (classical bound)
  br label %84    ; IR: br label %80

66:; IR: block %62  (measure x, classical bound nq)
  %67 = phi i64 [ 0, %52 ], [ %77, %66 ]    ; IR: %63  (classical i)
  %68 = phi i32 [ 0, %52 ], [ %76, %66 ]    ; IR: %64  (classical m)
  %69 = getelementptr inbounds i8, ptr %5, i64 %67    ; IR: %65 = getelementptr inbounds i8, ptr %4, i64 %63  (untainted index: stays)
  %70 = ptrtoint ptr %69 to i64    ; IR: %65 as its run-time address
  %71 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %70)    ; IR: %66 = load i8, ptr %65; %67 = trunc nuw to i1  (a plain bus load at width i1, SPEC GAP 1)
  %72 = call i1 @cqrt_measure_i1(i32 %71)    ; IR: %68 = cq_measure_i1(%67)  [the load copy is measured and stays allocated (rule 2)]
  %73 = zext i1 %72 to i32    ; IR: %69  (classical)
  %74 = trunc nuw nsw i64 %67 to i32    ; IR: %70  (classical)
  %75 = shl nuw i32 %73, %74    ; IR: %71  (classical)
  %76 = or i32 %75, %68    ; IR: %72  (classical)
  %77 = add nuw nsw i64 %67, 1    ; IR: %73  (classical)
  %78 = icmp eq i64 %77, %53    ; IR: %74  (classical)
  br i1 %78, label %61, label %66    ; IR: br i1 %74, label %57, label %62

79:; IR: block %75
  %80 = shl i32 %94, 16    ; IR: %76  (classical)
  br label %81    ; IR: br label %77

81:; IR: block %77
  %82 = phi i32 [ 0, %61 ], [ %80, %79 ]    ; IR: %78  (classical)
  %83 = or i32 %82, %62    ; IR: %79  (classical)
  ret i32 %83    ; IR: ret i32 %79

84:; IR: block %80  (measure y, classical bound nq)
  %85 = phi i64 [ 0, %64 ], [ %95, %84 ]    ; IR: %81  (classical i)
  %86 = phi i32 [ 0, %64 ], [ %94, %84 ]    ; IR: %82  (classical f)
  %87 = getelementptr inbounds i8, ptr %6, i64 %85    ; IR: %83 = getelementptr inbounds i8, ptr %5, i64 %81  (untainted index: stays)
  %88 = ptrtoint ptr %87 to i64    ; IR: %83 as its run-time address
  %89 = call i32 @cqrt_qram_load_i1_hl(i32 %3, i64 %88)    ; IR: %84 = load i8, ptr %83; %85 = trunc nuw to i1  (a plain bus load at width i1, SPEC GAP 1)
  %90 = call i1 @cqrt_measure_i1(i32 %89)    ; IR: %86 = cq_measure_i1(%85)  [the load copy is measured and stays allocated (rule 2)]
  %91 = zext i1 %90 to i32    ; IR: %87  (classical)
  %92 = trunc nuw nsw i64 %85 to i32    ; IR: %88  (classical)
  %93 = shl nuw i32 %91, %92    ; IR: %89  (classical)
  %94 = or i32 %93, %86    ; IR: %90  (classical)
  %95 = add nuw nsw i64 %85, 1    ; IR: %91  (classical)
  %96 = icmp eq i64 %95, %65    ; IR: %92  (classical)
  br i1 %96, label %79, label %84    ; IR: br i1 %92, label %75, label %80
}

declare i32 @llvm.cttz.i32(i32, i1 immarg)
declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ne_i32(i32, i32)
declare void @cq_template_icmp_ne_i32_unc(i32, i32, i32)
declare i32 @cq_template_zext_i1_to_i8(i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
