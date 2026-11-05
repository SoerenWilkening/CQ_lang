; HAND-WRITTEN. Rules: 20, 21, 2, 3, 4, 5, 7, 8, 9, 11, 12, 14, 15, 16; §1.3 (the bus, __cq_mem, __cq_alloc, qram_swap).
; Checked: m = sum_i cq_measure(x[i]) << i: each measured x[i] is the i1 load copy of cell x + i (IR %82/%83 -> %84).
; The cells of the block x on the bus at exit: the low bit of cell x + i holds the measured outcome of x[i] (its high 7
; bits 0), 0 <= i < n.
; Clean: per H trip, the swap rail of the in-place form (|0> after its swap-in, freed). Per cost trip: the load copies of
; eu[e] and ev[e] (IR %42, %47), their sext rails (%43, %48), the two address rails x + eu[e], x + ev[e] (%44, %49), the
; two i8 cell copies (%45, %50), the compare flag x[eu[e]] == x[ev[e]] (%51), the controlled load copy of gamma[l] (%53)
; and its fneg rail (%54), all uncomputed and freed in the same trip (rule 5 sentence 1: the cost loop has no memory
; version change). Per mixer trip: the reader copy of x[i] before the swap-out (%64/%65), the swap rail, the reader copy
; of the rotated x[i] after the swap-in (%70) and the angle rail 2 beta[l] (%69).
; Kept: the cells x[0..n-1] themselves (the registers live in memory: rotated in place, read through load copies); by
; rule 5 sentence 3 the n kept stores `store i8 0, ptr %23` of the H loop, each with its tape slot and its value seed
; alloc_i8(0) (rule 7; a classical basis state, 8 qubits, unentangled); by rule 5 sentence 1, the p*n load copies of beta[l] (IR %68: each is
; overtaken by its trip's in-place form, a memory version change, before its last reader, the fmul _unc: un-copied
; right after that _unc and left allocated, 64 qubits each); by rule 2, the n measured i1 load copies (IR %83).
; Rotations: (Ry, cell x[i], pi/2, 1) for i = 0..n-1; then per layer l = 0..p-1: for each edge e = 0..ne-1,
; (P, flag, val(A), NOT flag(x[eu[e]] == x[ev[e]])) with A = fneg of the f64 rail loaded from gamma[l] (rz_qangle_controlled
; on the X-bracketed flag); for each i = 0..n-1, (P, copy of x[i], pi/2, x[i]), (Ry, cell x[i], val(B), 1) with B = 2 *
; the f64 rail loaded from beta[l] (ry_i1_qangle on the swap rail), (P, copy of x[i], -pi/2, x[i]).
; QAOA MaxCut on a graph given at run time: the vertex count n, the edge count ne, the edge endpoint arrays eu/ev, the
; layer count p and the angle arrays gamma/beta are all parameters, so every loop is a ROLLED classical loop with a
; runtime bound (rule 14) and no size is fixed at compile time.
; ONE BUS (rules 16, 20, 21). `bool x[n]` is -O1's `alloca i8, i64 n`; it stores a tainted value (the rotated bit), which
; no user of rule 20 (b) allows, so it is BUS-RESIDENT: __cq_alloc(n, 16) at its program point, no alloca remains (rule
; 16: zeroed host memory at an address never reused; the size is classical, no K2). m = __cq_mem() is called once, at
; entry (§5). The cells are the registers: no handle is ever stored (§1.1). eu, ev, gamma and beta are pointer arguments,
; program memory like any other: every load of them is a bus load and a rail (rule 3; over-taint, a basis copy of HOST
; cells: a classical basis state of W qubits, unentangled). Hence the edge endpoints eu[e], ev[e] are i32 rails, -O1's sext is the sext template, and the
; `getelementptr i8, ptr %9, i64 %43` with a tainted index is rule 20's address arithmetic: add_i64_hl(sext, x) into a
; 64-bit address rail (size 1: no scale), and the cell loads at x[eu[e]], x[ev[e]] are qram_load_i8 at an address rail.
; The angles gamma[l] and beta[l] are f64 rails, so every phase and rotation that reads them is rule 15's single qangle
; primitive (rule 11: a value loaded from the bus is a quantum angle).
; Gate shapes:
;  (0) H layer `x[i] = 0; cq_theta(&x[i], pi/2)`: `store i8 0, ptr %23` is a KEPT store of the seed alloc_i8(0) (rules 5
;      sentence 3, 7); -O1 forwarded the stored 0 into the theta (`cq_theta_i1(false, ..)`), and the theta, `zext`, `store
;      i8 %25, ptr %23` is rule 5's in-place form at width i1 (Readers: y is the forwarded value, the interval runs from
;      the first store; Width casts): alloc_i1(0), qram_swap_i1_hl, Ry(pi/2) on the swap rail, qram_swap_i1_hl, free.
;  (1) cost phase `if (x[u] != x[v]) cq_phi(-gamma[l])`: -O1 compares the two cells with `icmp eq i8` of two `load i8` and
;      puts the phase in the ELSE arm. Each load is a bus load at its address rail (i8, the access type; no trunc); the flag
;      is cq_template_icmp_eq_i8 of the two copies into a fresh |0> rail and .O1.ll block %52 runs under NOT flag: an X
;      bracket (rule 8). The angle load gamma[l] sits in that arm, and a bus access is never hoisted (rule 9): it is
;      qram_load_f64_hl_controlled under the flag inside the bracket, -O1's fneg is the fneg template, and cq_phi of that
;      rail is rz_qangle_controlled(flag, A) (rules 11, 15). The fneg rail and the controlled copy are uncomputed inside
;      the same bracket (rule 5), then the flag from the two (unchanged) cell copies, then each endpoint's chain (cell copy,
;      address rail, sext, endpoint copy); all are |0> again and freed every trip.
;  (2) mixer `if (x[i]) cq_phi(pi/2); cq_theta(&x[i], 2 beta[l]); if (x[i]) cq_phi(-pi/2)`: `load i8; trunc nuw to i1;
;      cq_theta_i1; zext; store i8` on the SSA pointer %63 is rule 5's in-place form at width i1. y (%65) has another
;      reader, `br i1 %65`: it reads a plain load taken before the swap-out (Readers), at width i1 (Width casts), and the
;      phase is cqrt_rz_i1 on that bare copy (diagonal; no flag), which is then un-copied (before the swap-out, the next
;      memory version change). beta[l] is a plain bus load at its own program point before the swap-out, 2 beta[l] the
;      fmul_f64_hl template, and the Ry is cqrt_ry_i1_qangle on the swap rail. The step value %70 has another reader,
;      `br i1 %70`, so the form ends there: that reader reads a plain i1 load taken after the swap-in, rz_i1(-pi/2) on it,
;      un-copied. The fmul rail is a step operand produced by a template: uncomputed after the second swap. The beta copy's
;      last reader is that fmul _unc, after the form (a memory version change): un-copied after it, not freed (rule 5
;      sentence 1, the `*p += *q` case).
;  (3) measure loop: `load i8; trunc nuw to i1; cq_measure_i1` is a plain bus load at width i1 (SPEC GAP 1), measured and
;      never un-copied (rule 2).
; Nothing is pushed: every loop is classical-bound and every rail that rule 5 does not keep dies inside its trip (rule 14).
; Expected: every rail beyond the registers is either un-copied/uncomputed in its trip or a classical-valued copy of HOST
; cells (the seeds, the beta copies, the endpoint copies), so the state of the n registers equals that of the former
; slot-array lowering, up to the qangle grid rounding of val(A), val(B) (§1.3). Its replay (a scratch generalisation of
; _tools/replay/sim_trace_cq.py to an edge list; NOT re-replayed in the bus model): call 1, the 4-ring, p = 2, gamma =
; (pi/4, pi/8), beta = (pi/8, pi/16): max |p_trace - p_exact| = 1.1e-16, <C> = 3.1036 of 4; call 2, the 5-path, p = 1,
; gamma = 0.6, beta = 0.35: max |p_trace - p_exact| = 5.6e-17, <C> = 2.9671 of 4.
; SPEC GAP 1: rule 5's Width-casts clause fixes the width U = i1 only for a reader's plain load of a form (a reader of
; the form's SSA values). The measure loop's `load i8; trunc nuw to i1` is a separate IR load of a cell last written by
; the mixer's form at width i1 and reads no SSA value of a form. Chosen as 117 and 205 do, by the sentence proposed for
; Width casts ("any later `load T p; trunc nuw T to U` of a cell last written by a form at width U, or whose high bits
; are known 0, is one plain load at U, never a load at T and a trunc template"): one qram_load_i1_hl at the trunc's
; width (the low bit of the cell), measured, not a qram_load_i8 and a trunc template. The unitary is the same either
; way (the high 7 bits are 0 and a measured copy is kept). The cost loop's `load i8` feeds
; `icmp eq i8` with no trunc and is qram_load_i8 at the access type.
source_filename = "qaoa_ring.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @qaoa_ring(i32 noundef %0, i32 noundef %1, ptr noundef %2, ptr noundef %3, i32 noundef %4, ptr noundef %5, ptr noundef %6) {
  %8 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle m (once, at function entry, §5)
  %9 = zext i32 %0 to i64    ; IR: %8 = zext i32 %0 to i64  (classical n: the block's size in bytes)
  %10 = call ptr @__cq_alloc(i64 %9, i64 16)    ; IR: %9 = alloca i8, i64 %8, align 16  [bus-resident (a store of a tainted value): one zeroed block, no alloca remains (rules 16, 20)]
  %11 = ptrtoint ptr %10 to i64    ; IR: %9 as its run-time address (the classical base of the address rails x + eu[e], x + ev[e]; rule 21)
  %12 = icmp sgt i32 %0, 0    ; IR: %10  (classical)
  br i1 %12, label %13, label %15    ; IR: br i1 %10, label %11, label %13

13:; IR: block %11
  %14 = zext nneg i32 %0 to i64    ; IR: %12  (classical)
  br label %23    ; IR: br label %21

15:; IR: block %13
  %16 = icmp sgt i32 %4, 0    ; IR: %14  (classical)
  br i1 %16, label %17, label %36    ; IR: br i1 %14, label %15, label %32

17:; IR: block %15
  %18 = icmp sgt i32 %1, 0    ; IR: %16  (classical)
  %19 = icmp sgt i32 %0, 0    ; IR: %17  (classical)
  %20 = zext nneg i32 %4 to i64    ; IR: %18  (classical)
  %21 = zext nneg i32 %1 to i64    ; IR: %19  (classical)
  %22 = zext nneg i32 %0 to i64    ; IR: %20  (classical)
  br label %31    ; IR: br label %28

23:; IR: block %21  (H layer, classical bound n)
  %24 = phi i64 [ 0, %13 ], [ %29, %23 ]    ; IR: %22  (classical i)
  %25 = getelementptr inbounds i8, ptr %10, i64 %24    ; IR: %23 = getelementptr inbounds i8, ptr %9, i64 %22  (untainted index: stays)
  %26 = ptrtoint ptr %25 to i64    ; IR: %23 as its run-time address (the _hl operand)
  %27 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: store i8 0, ptr %23  [the seed of the classical 0: the store's value rail, KEPT with it (rules 5, 7)]
  call void @cqrt_qram_store_i8_hl(i32 %8, i64 %26, i32 %27)    ; IR: store i8 0, ptr %23  [a kept store at a classical address (rule 5 sentence 3); classical-valued, the cell stays HOST]
  %28 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %24 = cq_theta_i1(false, pi/2): in-place form at width i1 on %23, y the 0 -O1 forwarded from the store (rule 5 Readers, Width casts); the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %8, i64 %26, i32 %28)    ; IR: swap-out of the low bit: the rail holds x[i] (= 0), the cell's bit |0>
  call void @cqrt_ry_i1(i32 %28, double 0x3FF921FB54442D18)    ; IR: %24 = cq_theta_i1(false, pi/2)  [Ry(pi/2) on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %8, i64 %26, i32 %28)    ; IR: %25 = zext i1 %24 to i8; store i8 %25, ptr %23: swap-in: the cell holds x[i]
  call void @cqrt_free(i32 %28)    ; IR: release the swap rail (|0>)
  %29 = add nuw nsw i64 %24, 1    ; IR: %26  (classical)
  %30 = icmp eq i64 %29, %14    ; IR: %27  (classical)
  br i1 %30, label %15, label %23    ; IR: br i1 %27, label %13, label %21

31:; IR: block %28  (layer loop, classical bound p)
  %32 = phi i64 [ 0, %17 ], [ %64, %63 ]    ; IR: %29  (classical l)
  br i1 %18, label %33, label %40    ; IR: br i1 %16, label %30, label %36

33:; IR: block %30
  %34 = getelementptr inbounds double, ptr %5, i64 %32    ; IR: %31  (classical &gamma[l]; untainted index: stays)
  %35 = ptrtoint ptr %34 to i64    ; IR: %31 as its run-time address (the _hl operand of the arm's load)
  br label %44    ; IR: br label %39

36:; IR: block %32
  %37 = icmp sgt i32 %0, 0    ; IR: %33  (classical)
  br i1 %37, label %38, label %77    ; IR: br i1 %33, label %34, label %76

38:; IR: block %34
  %39 = zext nneg i32 %0 to i64    ; IR: %35  (classical)
  br label %79    ; IR: br label %78

40:; IR: block %36
  br i1 %19, label %41, label %63    ; IR: br i1 %17, label %37, label %58

41:; IR: block %37
  %42 = getelementptr inbounds double, ptr %6, i64 %32    ; IR: %38  (classical &beta[l]; untainted index: stays)
  %43 = ptrtoint ptr %42 to i64    ; IR: %38 as its run-time address
  br label %66    ; IR: br label %61

44:; IR: blocks %39, %52, %55  (cost layer, classical bound ne)
  %45 = phi i64 [ 0, %33 ], [ %61, %44 ]    ; IR: %40  (classical e)
  %46 = getelementptr inbounds i32, ptr %2, i64 %45    ; IR: %41  (classical &eu[e])
  %47 = ptrtoint ptr %46 to i64    ; IR: %41 as its run-time address
  %48 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %47)    ; IR: %42 = load i32, ptr %41  [a bus load: the rail eu[e] (rule 3; HOST cells, classical-valued)]
  %49 = call i32 @cq_template_sext_i32_to_i64(i32 %48)    ; IR: %43 = sext i32 %42 to i64  (template: a tainted cast)
  %50 = call i32 @cq_template_add_i64_hl(i32 %49, i64 %11)    ; IR: %44 = getelementptr inbounds i8, ptr %9, i64 %43  [tainted index: the address rail x + eu[e] (rule 20; size 1, no scale)]
  %51 = call i32 @cqrt_qram_load_i8(i32 %8, i32 %50)    ; IR: %45 = load i8, ptr %44  [a bus load at an address rail: fresh rail ^= cell x[eu[e]]]
  %52 = getelementptr inbounds i32, ptr %3, i64 %45    ; IR: %46  (classical &ev[e])
  %53 = ptrtoint ptr %52 to i64    ; IR: %46 as its run-time address
  %54 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %53)    ; IR: %47 = load i32, ptr %46  [the rail ev[e]]
  %55 = call i32 @cq_template_sext_i32_to_i64(i32 %54)    ; IR: %48 = sext i32 %47 to i64
  %56 = call i32 @cq_template_add_i64_hl(i32 %55, i64 %11)    ; IR: %49 = getelementptr inbounds i8, ptr %9, i64 %48  [the address rail x + ev[e]]
  %57 = call i32 @cqrt_qram_load_i8(i32 %8, i32 %56)    ; IR: %50 = load i8, ptr %49  [fresh rail ^= cell x[ev[e]]]
  %58 = call i32 @cq_template_icmp_eq_i8(i32 %51, i32 %57)    ; IR: %51 = icmp eq i8 %45, %50  [flag rail: x[u] == x[v]; block %52 runs under NOT %51]
  call void @cqrt_not_i1(i32 %58)    ; IR: bracket: block %52 is the FALSE edge of br i1 %51 (rule 8)
  %59 = call i32 @cqrt_qram_load_f64_hl_controlled(i32 %58, i32 %8, i64 %35)    ; IR: block %52: %53 = load double, ptr %31  [a bus load in the arm, never hoisted: _controlled under the arm flag (rules 5, 9)]
  %60 = call i32 @cq_template_fneg_f64(i32 %59)    ; IR: block %52: %54 = fneg double %53  (the angle rail A, rule 11)
  call void @cqrt_rz_qangle_controlled(i32 %58, i32 %60)    ; IR: block %52: cq_phi(%54)  [kickback of e^{i val(A)} on the flag (rule 15)]
  call void @cq_template_fneg_f64_unc(i32 %60, i32 %59)    ; IR: uncompute %54 (the angle rail, rule 15)
  call void @cqrt_free(i32 %60)    ; IR: release it (|0>)
  call void @cqrt_qram_load_f64_hl_controlled_unc(i32 %59, i32 %58, i32 %8, i64 %35)    ; IR: un-copy %53 under the same flag, inside the same bracket (rule 5 sentence 1: after its last reader, the fneg _unc; inside the same bracket)
  call void @cqrt_free(i32 %59)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %58)    ; IR: bracket
  call void @cq_template_icmp_eq_i8_unc(i32 %58, i32 %51, i32 %57)    ; IR: uncompute %51 (the two cell copies are unchanged)
  call void @cqrt_free(i32 %58)    ; IR: release the flag (|0>)
  call void @cqrt_qram_load_i8_unc(i32 %57, i32 %8, i32 %56)    ; IR: un-copy %50 (no memory version change since the load, rule 5 sentence 1)
  call void @cqrt_free(i32 %57)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %56, i32 %55, i64 %11)    ; IR: uncompute the address rail %49 (it outlives its access's _unc, rule 20)
  call void @cqrt_free(i32 %56)    ; IR: release it (|0>)
  call void @cq_template_sext_i32_to_i64_unc(i32 %55, i32 %54)    ; IR: uncompute %48
  call void @cqrt_free(i32 %55)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %54, i32 %8, i64 %53)    ; IR: un-copy %47
  call void @cqrt_free(i32 %54)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i8_unc(i32 %51, i32 %8, i32 %50)    ; IR: un-copy %45
  call void @cqrt_free(i32 %51)    ; IR: release it (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %50, i32 %49, i64 %11)    ; IR: uncompute the address rail %44
  call void @cqrt_free(i32 %50)    ; IR: release it (|0>)
  call void @cq_template_sext_i32_to_i64_unc(i32 %49, i32 %48)    ; IR: uncompute %43
  call void @cqrt_free(i32 %49)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %48, i32 %8, i64 %47)    ; IR: un-copy %42
  call void @cqrt_free(i32 %48)    ; IR: release it (|0>)
  %61 = add nuw nsw i64 %45, 1    ; IR: %56  (classical; block %55)
  %62 = icmp eq i64 %61, %21    ; IR: %57  (classical)
  br i1 %62, label %40, label %44    ; IR: br i1 %57, label %36, label %39

63:; IR: block %58
  %64 = add nuw nsw i64 %32, 1    ; IR: %59  (classical)
  %65 = icmp eq i64 %64, %20    ; IR: %60  (classical)
  br i1 %65, label %36, label %31    ; IR: br i1 %60, label %32, label %28

66:; IR: blocks %61, %66, %67, %72, %73  (mixer layer, classical bound n)
  %67 = phi i64 [ 0, %41 ], [ %75, %66 ]    ; IR: %62  (classical i)
  %68 = getelementptr inbounds i8, ptr %10, i64 %67    ; IR: %63 = getelementptr inbounds i8, ptr %9, i64 %62  (untainted index: stays)
  %69 = ptrtoint ptr %68 to i64    ; IR: %63 as its run-time address (the _hl operand of the loads and the form's swaps)
  %70 = call i32 @cqrt_qram_load_i1_hl(i32 %8, i64 %69)    ; IR: %64 = load i8, ptr %63; %65 = trunc nuw to i1: y of the in-place form below has another reader (br i1 %65): a plain load taken before the swap-out (rule 5 Readers; width i1, Width casts)
  call void @cqrt_rz_i1(i32 %70, double 0x3FF921FB54442D18)    ; IR: br i1 %65 -> block %66: cq_phi(pi/2)  [the bare rail is its own predicate: the phase on the copy, diagonal, no flag]
  call void @cqrt_qram_load_i1_hl_unc(i32 %70, i32 %8, i64 %69)    ; IR: un-copy the reader's copy (before the swap-out, the next memory version change)
  call void @cqrt_free(i32 %70)    ; IR: release it (|0>)
  %71 = call i32 @cqrt_qram_load_f64_hl(i32 %8, i64 %43)    ; IR: %68 = load double, ptr %38  [a bus load at its own program point, before the swap-out: the rail beta[l]; overtaken by the form: un-copied after the fmul _unc, not freed (rule 5 sentence 1)]
  %72 = call i32 @cq_template_fmul_f64_hl(i32 %71, double 2.000000e+00)    ; IR: %69 = fmul double %68, 2.0  (the angle rail B, rules 11, 15)
  %73 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %64/%65: in-place form at width i1 on %63, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %8, i64 %69, i32 %73)    ; IR: %64/%65: swap-out: the rail holds x[i], the cell's bit |0>
  call void @cqrt_ry_i1_qangle(i32 %73, i32 %72)    ; IR: %70 = cq_theta_i1(%65, %69)  [Ry(val(B)) in place on x[i]]
  call void @cqrt_qram_swap_i1_hl(i32 %8, i64 %69, i32 %73)    ; IR: %71 = zext i1 %70 to i8; store i8 %71, ptr %63: swap-in (the form ends: %70 has another reader)
  call void @cqrt_free(i32 %73)    ; IR: release the swap rail (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %72, i32 %71, double 2.000000e+00)    ; IR: uncompute %69 after the second swap (a step operand from a template, rule 5)
  call void @cqrt_free(i32 %72)    ; IR: release it (|0>)
  call void @cqrt_qram_load_f64_hl_unc(i32 %71, i32 %8, i64 %43)    ; IR: un-copy %68 after its last reader, the fmul _unc; the in-place form came between, so it stays allocated (overtaken, rule 5 sentence 1)
  %74 = call i32 @cqrt_qram_load_i1_hl(i32 %8, i64 %69)    ; IR: %70 read by br i1 %70: a plain load taken after the swap-in (rule 5 Readers; width i1)
  call void @cqrt_rz_i1(i32 %74, double 0xBFF921FB54442D18)    ; IR: br i1 %70 -> block %72: cq_phi(-pi/2)  [on the copy of the rotated rail]
  call void @cqrt_qram_load_i1_hl_unc(i32 %74, i32 %8, i64 %69)    ; IR: un-copy it (no memory version change since the load)
  call void @cqrt_free(i32 %74)    ; IR: release it (|0>)
  %75 = add nuw nsw i64 %67, 1    ; IR: %74  (classical; block %73)
  %76 = icmp eq i64 %75, %22    ; IR: %75  (classical)
  br i1 %76, label %63, label %66    ; IR: br i1 %75, label %58, label %61

77:; IR: block %76
  %78 = phi i32 [ 0, %36 ], [ %89, %79 ]    ; IR: %77  (classical m)
  ret i32 %78    ; IR: ret i32 %77

79:; IR: block %78  (measure loop, classical bound n)
  %80 = phi i64 [ 0, %38 ], [ %90, %79 ]    ; IR: %79  (classical i)
  %81 = phi i32 [ 0, %38 ], [ %89, %79 ]    ; IR: %80  (classical m)
  %82 = getelementptr inbounds i8, ptr %10, i64 %80    ; IR: %81 = getelementptr inbounds i8, ptr %9, i64 %79  (untainted index: stays)
  %83 = ptrtoint ptr %82 to i64    ; IR: %81 as its run-time address
  %84 = call i32 @cqrt_qram_load_i1_hl(i32 %8, i64 %83)    ; IR: %82 = load i8, ptr %81; %83 = trunc nuw to i1  (a plain bus load at width i1, SPEC GAP 1)
  %85 = call i1 @cqrt_measure_i1(i32 %84)    ; IR: %84 = cq_measure_i1(%83)  [the load copy is the measured rail, rule 2: never un-copied]
  %86 = zext i1 %85 to i32    ; IR: %85  (classical)
  %87 = trunc nuw nsw i64 %80 to i32    ; IR: %86  (classical)
  %88 = shl nuw i32 %86, %87    ; IR: %87  (classical)
  %89 = or i32 %88, %81    ; IR: %88  (classical)
  %90 = add nuw nsw i64 %80, 1    ; IR: %89  (classical)
  %91 = icmp eq i64 %90, %39    ; IR: %90  (classical)
  br i1 %91, label %77, label %79    ; IR: br i1 %90, label %76, label %78
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cq_template_sext_i32_to_i64(i32)
declare void @cq_template_sext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i8(i32, i32)
declare void @cqrt_qram_load_i8_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i8(i32, i32)
declare void @cq_template_icmp_eq_i8_unc(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare i32 @cqrt_qram_load_f64_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_f64_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cq_template_fneg_f64(i32)
declare void @cq_template_fneg_f64_unc(i32, i32)
declare void @cqrt_rz_qangle_controlled(i32, i32)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_qram_load_i1_hl_unc(i32, i32, i64)
declare void @cqrt_rz_i1(i32, double)
declare i32 @cqrt_qram_load_f64_hl(i32, i64)
declare void @cqrt_qram_load_f64_hl_unc(i32, i32, i64)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
declare void @cqrt_ry_i1_qangle(i32, i32)
declare i1 @cqrt_measure_i1(i32)
