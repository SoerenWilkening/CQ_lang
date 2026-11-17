; HAND-WRITTEN. Rules: 15, 8, 11, 12, 2, 3, 4, 5, 7, 14, 16, 20, 21, 22; §1.3 (the bus, __cq_mem, __cq_alloc, qram_swap).
; Checked: out = sum_j c[j] << (t-1-j) | sum_i k[i] << (t+i): each measured c[j] is the i1 load copy of cell c + j of the
; bus block %8 (the first measure loop), each measured k[i] the i1 load copy of cell k + i of the block %6 (the second
; measure loop). The cells of both blocks on the bus at exit: the low bit of cell c + j (k + i) holds the measured outcome
; of c[j] (k[i]), its high 7 bits 0.
; Clean: the kv accumulator walk (its |0> seed and per trip the zext, shl, or rails, pushed and uncomputed by the mirror
; loop), its sitofp rail (or, for nk <= 0, the 0.0 seed rail of the phi), the angle base A = fl((2 pi / 2^nk) * (double)kv)
; (the program's fmul), the per-trip angle rail A_j = fl(A * 2^j) (one per trip of the phase loop) and the QFT^-1 Toffoli
; flags c[m] & c[j] (one per (m, j) pair), each |0> (or its seed value) at its free; the swap rail of every in-place form
; (the eigenstate Ry, H^t, the QFT^-1 Ry; |0> after its swap-in); the load copy of c[j] that controls the phase primitive
; of trip j, the two load copies of c[m] and c[j] each QFT^-1 flag reads (the c[j] copy loaded under c[m]) and the load
; copy of c[j] that carries the phase cq_phi(pi): all un-copied right after their last reader (rule 5 sentence 1).
; Kept: the two memset value seeds alloc_i8(0) and the tape slots of the nk + t byte stores of the memsets (rules 5
; sentence 3, 7, 22); by rule 5 sentence 1, un-copied after their last reader but left allocated, the nk load copies
; of tk[i] (each overtaken by its trip's in-place form, a memory version change, before its last reader, the qangle
; primitive; un-copied right after the swap-in: HOST cells, classical-valued, no qubit) and the nk i8 load copies of
; k[i] of the kv walk (overtaken by the H^t in-place forms before their last reader, the zext _unc in the mirror, and
; un-copied right after it); by rule 2 the t + nk measured i1 load copies. The cells
; are the registers: no handle is ever stored (§1.1).
; Rotations: (Ry, cell k[i], val(T_i), 1) for i = 0..nk-1, T_i the f64 rail loaded from tk[i] (ry_i1_qangle on the swap
; rail); (Ry, cell c[j], pi/2, 1) for j = 0..t-1; then for j = 0..t-1: (P, A_j, val(A_j), copy of c[j]) with
; A_j = fl(fl((2 pi / 2^nk) * (double)kv) * 2^j), kv = sum_i k[i] << i [the controlled U^(2^j), U = diag(e^{i 2 pi kv /
; 2^nk}), applied by ONE primitive on the angle rail]; then the QFT^-1: for j = t-1..0: (P, flag, -pi / 2^(m-j),
; c[m] & c[j]) for m = t-1..j+1, (P, copy of c[j], pi, c[j]) (rz_i1 on the bare load copy), (Ry, cell c[j], pi/2, 1).
; Expected: for basis kv the counting field reads kv * 2^(t-nk) exactly when t >= nk (c[0] is its top bit); in
; superposition every kv branch reads its own estimate and k is left unchanged. The k copies (un-copied, left allocated)
; are basis copies of a register that no non-diagonal gate touches after its preparation and that is measured: they change no outcome
; distribution. Analytic (not re-replayed in the bus model; val(T_i) = tk[i] exactly, pi and pi/2 lie on the Ry grid):
; call 1 (nk = 2, t = 2, tk = {pi, 0}: kv = 1) reads c = 01, k = (1, 0) with p = 1.0000; call 2 (nk = 3, t = 4,
; tk = {pi/2, pi/2, pi}: kv uniform on {4, 5, 6, 7}) reads c = 2 kv (1000, 1010, 1100, 1110) jointly with its own k,
; p = 0.25 each, nothing else.
; QPE whose phase comes from a QUANTUM angle register, general size: nk, t and the preparation angles tk[] are inputs, so
; every loop has a classical runtime bound (rule 14). ONE BUS (rules 16, 20, 21). `bool k[nk], c[t]` are -O1's
; `alloca i8, i64 n`; each stores a tainted value (a cq_theta result), which no user of rule 20 (b) allows, and c is also
; read under a quantum predicate (the QFT^-1 c[j] load in the arm of c[m]): both are BUS-RESIDENT, __cq_alloc(n, 16) at
; their program points (rule 16: zeroed, a classical size, no K2), and every access is a bus access at its run-time
; address (gep with an untainted index stays, then ptrtoint: classical, _hl). m = __cq_mem() is called once, at entry.
; The zero-fills -O1 turned into memsets are rule 22's host loop of byte stores of ONE i8 seed, kept (emitted although
; the block is zero already: §0). tk is a pointer argument, program memory like any other: tk[i] is a bus load and an
; f64 rail (rule 3; over-taint, a basis copy of HOST cells), so cq_theta(&k[i], tk[i]) rotates by a QUANTUM ANGLE: ONE
; primitive cqrt_ry_i1_qangle (rules 11, 15). Each `load i8; trunc nuw to i1; cq_theta_i1; zext; store i8` on one SSA
; pointer is rule 5's in-place form at width i1 (Width casts): alloc_i1(0), qram_swap_i1_hl, the rotation on the swap
; rail, qram_swap_i1_hl, free; tk[i] is a plain bus load at its own program point, before the swap-out.
; kv = sum k[i] << i is the quantum accumulator of 28 over the cells (a bus load of k[i] at the access type i8, zext from
; i8, shl, or into fresh rails, pushed per trip). -O1 turns (double)kv into `sitofp` at the loop exit and merges it with
; the literal 0.0 of the nk <= 0 path; that incoming is a seed rail cqrt_alloc_f64(0.0), so the phi is a handle on both
; edges. The kv seed alloc_i32(0) is allocated before the guard and is also the kv rail of the nk <= 0 path. -O1 hoists
; 2 pi / 2^nk (classical) and its product with (double)kv out of the phase loop: cq_template_fmul_f64_hl gives the f64
; REGISTER A holding the program's IEEE double, bit-exact (rule 15, as 79 and 143). Each trip multiplies A by the
; classical (double)(1 << j) into the trip rail A_j, computed UNGUARDED (pure arm code is hoisted, rule 9), and
; `if (c[j]) cq_phi(phi)` is ONE primitive cqrt_rz_qangle_controlled(q_j, A_j), q_j the plain i1 load copy of c[j]:
; e^{i val(A_j)} on the branch where c[j] is 1 (rule 15; the backend supplies the N-bit ladder, the IR never spells it;
; the phase is RELATIVE in k, never a deletable global one, rule 12). q_j is un-copied right after the primitive (the
; phase loop has no memory version change); A_j is only read, so it is uncomputed and freed right after. After the loop
; A, the sitofp rail and the kv walk are uncomputed in LIFO order before the QFT^-1 (no non-diagonal gate ever touches
; k). The mirror's zext _unc reads the trip's k[i] load copy, which the H^t swaps overtook: its handle is pushed with
; the trip's rails (SPEC GAP 2), and the mirror un-copies it right after that _unc and leaves it allocated (rule 5
; sentence 1). The QFT^-1 is 117's caller loop: the
; nested branches c[m], c[j] are one Toffoli flag of two load copies, the c[j] load sitting in the arm of c[m] and so
; controlled by it (rule 5); `if (c[j]) cq_phi(pi)` is cqrt_rz_i1 on a plain load copy of c[j] taken before the swap-out
; of the in-place Ry (rule 5 Readers: another reader of y). The measure loops are plain load copies, measured (rule 2),
; and the packing is classical.
; SPEC GAP 1: every read of a _Bool cell here that is `load i8; trunc nuw i8 to i1` with no in-place form around it (the
; phase-loop control, the QFT^-1 flag loads, the measure loops; the cq_phi(pi) reader is a reader of the in-place form
; and is taken at i1 by rule 5 Width casts) has its width fixed by rule 5's Width-casts clause
; only for a reader's plain load of a form. Chosen as 115 and 117: one qram_load_i1_hl at the trunc's width (the low bit
; of the cell), not a qram_load_i8 and a trunc template. The accumulator's `load i8; zext nneg i8 to i32` has no trunc
; and is qram_load_i8_hl with zext_i8_to_i32.
; SPEC GAP 2: rule 14 pushes "every trip-local rail that rule 5 does not keep (and any classical per-trip value its
; _uncs need ...)", and rule 22 names only its hand-over and rule 19's dispatch loop as pushes of kept rails. The kv
; mirror's zext _unc needs each trip's overtaken k[i] load copy. Chosen: its handle is pushed as that per-trip classical
; value, and the mirror pops it for the zext _unc and the copy's own _unc after it (the copy is never freed).
source_filename = "qpe_quantum_angle.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @qpe_quantum_angle(i32 noundef %0, i32 noundef %1, ptr noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = zext i32 %0 to i64    ; IR: %4  (classical byte count nk)
  %6 = call ptr @__cq_alloc(i64 %5, i64 16)    ; IR: %5 = alloca i8, i64 %4, align 16: k[nk] is bus-resident (rule 20 (b): a rail is stored into it), one zeroed block (rule 16; a classical size, no K2)
  %7 = zext i32 %1 to i64    ; IR: %6  (classical byte count t)
  %8 = call ptr @__cq_alloc(i64 %7, i64 16)    ; IR: %7 = alloca i8, i64 %6, align 16: c[t] is bus-resident (a rail is stored into it; read under a quantum predicate), one zeroed block
  %9 = icmp sgt i32 %0, 0    ; IR: %8  (classical)
  br i1 %9, label %10, label %19    ; IR: br i1 %8, label %9, label %11

10:; IR: block %9
  %11 = zext nneg i32 %0 to i64    ; IR: %10  (classical memset length)
  %12 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%5, i8 0, %10): the byte value as ONE seed rail (rules 7, 22), kept with its stores
  br label %13

13:; IR: call @llvm.memset(%5, i8 0, %10): host loop of %10 byte stores (rule 22, classical length)
  %14 = phi i64 [ 0, %10 ], [ %17, %13 ]    ; IR: (classical byte i)
  %15 = getelementptr inbounds i8, ptr %6, i64 %14    ; IR: (the byte k + i)
  %16 = ptrtoint ptr %15 to i64    ; IR: (its run-time address, classical)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %16, i32 %12)    ; IR: memset: byte store i  (kept store, rule 5)
  %17 = add nuw nsw i64 %14, 1    ; IR: (classical)
  %18 = icmp eq i64 %17, %11    ; IR: (classical: i + 1 == nk)
  br i1 %18, label %19, label %13

19:; IR: block %11
  %20 = icmp sgt i32 %1, 0    ; IR: %12  (classical)
  br i1 %20, label %21, label %30    ; IR: br i1 %12, label %13, label %15

21:; IR: block %13
  %22 = zext nneg i32 %1 to i64    ; IR: %14  (classical memset length)
  %23 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%7, i8 0, %14): ONE seed rail, kept with its stores
  br label %24

24:; IR: call @llvm.memset(%7, i8 0, %14): host loop of %14 byte stores (rule 22)
  %25 = phi i64 [ 0, %21 ], [ %28, %24 ]    ; IR: (classical byte j)
  %26 = getelementptr inbounds i8, ptr %8, i64 %25    ; IR: (the byte c + j)
  %27 = ptrtoint ptr %26 to i64    ; IR: (its run-time address, classical)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %27, i32 %23)    ; IR: memset: byte store j  (kept store, rule 5)
  %28 = add nuw nsw i64 %25, 1    ; IR: (classical)
  %29 = icmp eq i64 %28, %22    ; IR: (classical: j + 1 == t)
  br i1 %29, label %30, label %24

30:; IR: block %15
  %31 = icmp sgt i32 %0, 0    ; IR: %16  (classical)
  br i1 %31, label %32, label %44    ; IR: br i1 %16, label %17, label %19

32:; IR: block %17
  %33 = zext nneg i32 %0 to i64    ; IR: %18  (classical)
  br label %34

34:; IR: block %23  (eigenstate preparation, classical bound nk)
  %35 = phi i64 [ 0, %32 ], [ %42, %34 ]    ; IR: %24  (classical i)
  %36 = getelementptr inbounds i8, ptr %6, i64 %35    ; IR: %25  (the cell k[i])
  %37 = ptrtoint ptr %36 to i64    ; IR: %25 as its run-time address
  %38 = getelementptr inbounds double, ptr %2, i64 %35    ; IR: %28  (&tk[i], untainted index: stays)
  %39 = ptrtoint ptr %38 to i64    ; IR: %28 as its run-time address
  %40 = call i32 @cqrt_qram_load_f64_hl(i32 %4, i64 %39)    ; IR: %29 = load double, ptr %28  [a bus load at its own program point, before the swap-out: the angle rail T_i (rules 3, 11); overtaken by the form: un-copied after the swap-in, not freed (rule 5 sentence 1)]
  %41 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %26 = load i8, ptr %25; %27 = trunc nuw to i1: in-place form at width i1 (rule 5, Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %37, i32 %41)    ; IR: %26/%27: swap-out: the rail holds k[i], the cell's low bit |0>
  call void @cqrt_ry_i1_qangle(i32 %41, i32 %40)    ; IR: %30 = cq_theta_i1(%27, %29)  [Ry(val(T_i)) in place on k[i]: a quantum angle, ONE primitive (rule 15)]
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %37, i32 %41)    ; IR: %31 = zext; store i8 %31, ptr %25: swap-in: the cell holds %30
  call void @cqrt_qram_load_f64_hl_unc(i32 %40, i32 %4, i64 %39)    ; IR: un-copy %29 after its last reader, the qangle Ry, once the form has closed; the swap-out lies between, so it stays allocated (rule 5 sentence 1)
  call void @cqrt_free(i32 %41)    ; IR: release the swap rail (|0>)
  %42 = add nuw nsw i64 %35, 1    ; IR: %32  (classical)
  %43 = icmp eq i64 %42, %33    ; IR: %33  (classical)
  br i1 %43, label %44, label %34    ; IR: br i1 %33, label %19, label %23

44:; IR: block %19
  %45 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: incoming 0 of phi %43  [kv before trip 0; it also stands for kv = 0 when nk <= 0]
  %46 = icmp sgt i32 %0, 0    ; IR: %20  (classical)
  br i1 %46, label %47, label %63    ; IR: br i1 %20, label %21, label %36

47:; IR: block %21
  %48 = zext nneg i32 %0 to i64    ; IR: %22  (classical)
  br label %49

49:; IR: block %41  (kv = sum k[i] << i, the quantum accumulator of 28)
  %50 = phi i64 [ 0, %47 ], [ %59, %49 ]    ; IR: %42  (classical i)
  %51 = phi i32 [ %45, %47 ], [ %58, %49 ]    ; IR: %43 = phi i32 [ 0, %21 ], [ %49, %41 ]
  %52 = getelementptr inbounds i8, ptr %6, i64 %50    ; IR: %44  (the cell k[i])
  %53 = ptrtoint ptr %52 to i64    ; IR: %44 as its run-time address
  %54 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %53)    ; IR: %45 = load i8, ptr %44  [a plain bus load at the access type (no trunc); the H^t swaps overtake it before its last reader, the zext _unc in the mirror: un-copied there, not freed (rule 5 sentence 1)]
  %55 = call i32 @cq_template_zext_i8_to_i32(i32 %54)    ; IR: %46 = zext nneg i8 %45 to i32  [k[i] widened into a fresh rail]
  %56 = trunc nuw nsw i64 %50 to i32    ; IR: %47  (classical)
  %57 = call i32 @cq_template_shl_i32_hl(i32 %55, i32 %56)    ; IR: %48 = shl nuw i32 %46, %47
  %58 = call i32 @cq_template_or_i32(i32 %57, i32 %51)    ; IR: %49 = or i32 %48, %43
  call void @cqrt_push(i32 %51)    ; IR: trip-local rails of the accumulator, for the mirror (rule 14)
  call void @cqrt_push(i32 %54)    ; IR: the handle of the trip's overtaken load copy %45, which the mirror's zext _unc and its own _unc read (SPEC GAP 2)
  call void @cqrt_push(i32 %55)
  call void @cqrt_push(i32 %57)
  %59 = add nuw nsw i64 %50, 1    ; IR: %50  (classical)
  %60 = icmp eq i64 %59, %48    ; IR: %51  (classical)
  br i1 %60, label %61, label %49    ; IR: br i1 %51, label %34, label %41

61:; IR: block %34
  %62 = call i32 @cq_template_sitofp_i32_to_f64(i32 %58)    ; IR: %35 = sitofp i32 %49 to double  [(double)kv into a fresh f64 rail]
  br label %65

63:; IR: the edge %19 -> %36
  %64 = call i32 @cqrt_alloc_f64(double 0.000000e+00)    ; IR: incoming 0.0 of phi %37  [(double)kv with nk <= 0: a seed rail, the phi stays a handle on both edges (rule 7)]
  br label %65

65:; IR: block %36
  %66 = phi i32 [ %58, %61 ], [ %45, %63 ]    ; IR: (the kv rail reaching here: %49, or the seed when nk <= 0; the mirror below needs it)
  %67 = phi i32 [ %62, %61 ], [ %64, %63 ]    ; IR: %37 = phi double [ 0.0, %19 ], [ %35, %34 ]
  %68 = icmp sgt i32 %1, 0    ; IR: %38  (classical)
  br i1 %68, label %69, label %78    ; IR: br i1 %38, label %39, label %52

69:; IR: block %39
  %70 = zext nneg i32 %1 to i64    ; IR: %40  (classical)
  br label %71

71:; IR: block %60  (H^t)
  %72 = phi i64 [ 0, %69 ], [ %76, %71 ]    ; IR: %61  (classical j)
  %73 = getelementptr inbounds i8, ptr %8, i64 %72    ; IR: %62  (the cell c[j])
  %74 = ptrtoint ptr %73 to i64    ; IR: %62 as its run-time address
  %75 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %63 = load i8, ptr %62; %64 = trunc nuw to i1: in-place form at width i1, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %74, i32 %75)    ; IR: %63/%64: swap-out (a memory version change)
  call void @cqrt_ry_i1(i32 %75, double 0x3FF921FB54442D18)    ; IR: %65 = cq_theta_i1(%64, pi/2)  [H|0>: Ry(pi/2) in place on c[j]]
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %74, i32 %75)    ; IR: %66 = zext; store i8 %66, ptr %62: swap-in: the cell holds %65
  call void @cqrt_free(i32 %75)    ; IR: release the swap rail (|0>)
  %76 = add nuw nsw i64 %72, 1    ; IR: %67  (classical)
  %77 = icmp eq i64 %76, %70    ; IR: %68  (classical)
  br i1 %77, label %78, label %71    ; IR: br i1 %68, label %52, label %60

78:; IR: block %52
  %79 = icmp sgt i32 %1, 0    ; IR: %53  (classical)
  br i1 %79, label %80, label %98    ; IR: br i1 %53, label %54, label %69

80:; IR: block %54
  %81 = shl nuw i32 1, %0    ; IR: %55  (classical 1 << nk)
  %82 = sitofp i32 %81 to double    ; IR: %56  (classical)
  %83 = fdiv double 0x401921FB54442D18, %82    ; IR: %57  (classical 2 pi / 2^nk)
  %84 = call i32 @cq_template_fmul_f64_hl(i32 %67, double %83)    ; IR: %58 = fmul double %57, %37  [the angle base A = fl((2 pi / 2^nk) * (double)kv), hoisted out of the loop by -O1; commutative, handle first]
  %85 = zext nneg i32 %1 to i64    ; IR: %59  (classical)
  br label %86

86:; IR: block %75 (+ block %80 hoisted: pure arm code, rule 9)  (controlled U^(2^j))
  %87 = phi i64 [ 0, %80 ], [ %95, %86 ]    ; IR: %76  (classical j)
  %88 = getelementptr inbounds i8, ptr %8, i64 %87    ; IR: %77  (the cell c[j])
  %89 = ptrtoint ptr %88 to i64    ; IR: %77 as its run-time address
  %90 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %89)    ; IR: %78 = load i8, ptr %77; %79 = trunc nuw to i1  (a plain bus load of c[j] at width i1, SPEC GAP 1: the bare-rail predicate q_j of block %80)
  %91 = trunc nuw nsw i64 %87 to i32    ; IR: %81  (classical)
  %92 = shl nuw i32 1, %91    ; IR: %82  (classical 1 << j)
  %93 = sitofp i32 %92 to double    ; IR: %83  (classical (double)(1 << j))
  %94 = call i32 @cq_template_fmul_f64_hl(i32 %84, double %93)    ; IR: %84 = fmul double %58, %83  [A_j = fl(A * 2^j), computed unguarded into a fresh rail]
  call void @cqrt_rz_qangle_controlled(i32 %90, i32 %94)    ; IR: br i1 %79 -> block %80: cq_phi(%84)  [ONE primitive: e^{i val(A_j)} on the branch where c[j] = 1 (rule 15); a relative phase in k]
  call void @cqrt_qram_load_i1_hl_unc(i32 %90, i32 %4, i64 %89)    ; IR: un-copy %78 (its last reader is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %90)    ; IR: release it (|0>)
  call void @cq_template_fmul_f64_hl_unc(i32 %94, i32 %84, double %93)    ; IR: uncompute %84 (only read by the phase primitive)
  call void @cqrt_free(i32 %94)    ; IR: release the %84 rail (|0>)
  %95 = add nuw nsw i64 %87, 1    ; IR: %86  (classical)
  %96 = icmp eq i64 %95, %85    ; IR: %87  (classical)
  br i1 %96, label %97, label %86    ; IR: br i1 %87, label %69, label %75

97:; IR: the edge %85 -> %69
  call void @cq_template_fmul_f64_hl_unc(i32 %84, i32 %67, double %83)    ; IR: uncompute %58 after its last consumer (the last trip's fmul)
  call void @cqrt_free(i32 %84)    ; IR: release the %58 rail (|0>)
  br label %98

98:; IR: block %69 entry: the angle chain is dead; uncompute it in LIFO order before the QFT^-1 (no non-diagonal gate touches k)
  br i1 %46, label %99, label %115

99:
  call void @cq_template_sitofp_i32_to_f64_unc(i32 %67, i32 %66)    ; IR: uncompute %35
  call void @cqrt_free(i32 %67)    ; IR: release the %35 rail (|0>)
  %100 = zext nneg i32 %0 to i64    ; IR: (classical trip count nk)
  %101 = add nsw i64 %100, -1    ; IR: (classical nk - 1)
  br label %102

102:; IR: reverse trip index of the kv accumulator (undoes trip nk - 1 - r)
  %103 = phi i64 [ 0, %99 ], [ %113, %102 ]    ; IR: (classical r)
  %104 = phi i32 [ %66, %99 ], [ %108, %102 ]    ; IR: %49 of the trip being undone
  %105 = call i32 @cqrt_pop()    ; IR: that trip's %48
  %106 = call i32 @cqrt_pop()    ; IR: its %46
  %107 = call i32 @cqrt_pop()    ; IR: its overtaken load copy %45
  %108 = call i32 @cqrt_pop()    ; IR: its %43
  %109 = sub nsw i64 %101, %103    ; IR: i of the trip being undone  (classical)
  %110 = trunc nuw nsw i64 %109 to i32    ; IR: %47 of that trip  (classical)
  call void @cq_template_or_i32_unc(i32 %104, i32 %105, i32 %108)    ; IR: uncompute %49
  call void @cqrt_free(i32 %104)    ; IR: release the %49 rail (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %105, i32 %106, i32 %110)    ; IR: uncompute %48
  call void @cqrt_free(i32 %105)    ; IR: release the %48 rail (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %106, i32 %107)    ; IR: uncompute %46 (reads the copy %45)
  call void @cqrt_free(i32 %106)    ; IR: release the %46 rail (|0>)
  %111 = getelementptr inbounds i8, ptr %6, i64 %109    ; IR: %44 of that trip (the cell k[i]), recomputed from the trip index
  %112 = ptrtoint ptr %111 to i64    ; IR: its run-time address
  call void @cqrt_qram_load_i8_hl_unc(i32 %107, i32 %4, i64 %112)    ; IR: un-copy %45 of that trip after its last reader, the zext _unc; the H^t swaps lie between, so it stays allocated (rule 5 sentence 1)
  %113 = add nuw nsw i64 %103, 1
  %114 = icmp eq i64 %113, %100
  br i1 %114, label %116, label %102

115:
  call void @cqrt_free(i32 %67)    ; IR: release the 0.0 seed of phi %37 (never written)
  br label %116

116:
  call void @cqrt_free(i32 %45)    ; IR: release the seed of phi %43 (never written, |0>)
  br label %117

117:; IR: block %69  (QFT^-1 without the final swaps)
  %118 = add i32 %1, -1    ; IR: %70  (classical t - 1)
  %119 = icmp sgt i32 %1, 0    ; IR: %71  (classical)
  br i1 %119, label %120, label %152    ; IR: br i1 %71, label %72, label %94

120:; IR: block %72
  %121 = zext i32 %118 to i64    ; IR: %73  (classical)
  %122 = sext i32 %118 to i64    ; IR: %74  (classical)
  br label %123    ; IR: br label %88

123:; IR: block %88
  %124 = phi i64 [ %121, %120 ], [ %150, %145 ]    ; IR: %89  (classical j, t-1 down to 0)
  %125 = icmp slt i64 %124, %122    ; IR: %90  (classical: j < t - 1, the inner loop runs)
  br i1 %125, label %126, label %145    ; IR: br i1 %90, label %91, label %98

126:; IR: block %91
  %127 = getelementptr inbounds i8, ptr %8, i64 %124    ; IR: %92  (the cell c[j])
  %128 = ptrtoint ptr %127 to i64    ; IR: %92 as its run-time address
  %129 = trunc nuw nsw i64 %124 to i32    ; IR: %93  (classical)
  br label %130    ; IR: br label %102

130:; IR: block %102  (classical m = t-1 down to j+1)
  %131 = phi i32 [ %118, %126 ], [ %142, %130 ]    ; IR: %103  (classical m)
  %132 = zext nneg i32 %131 to i64    ; IR: %104  (classical)
  %133 = getelementptr inbounds i8, ptr %8, i64 %132    ; IR: %105  (the cell c[m])
  %134 = ptrtoint ptr %133 to i64    ; IR: %105 as its run-time address
  %135 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %134)    ; IR: %106 = load i8, ptr %105; %107 = trunc nuw to i1  (a plain bus load of c[m], SPEC GAP 1; the flag of br i1 %107)
  %136 = call i32 @cqrt_qram_load_i1_hl_controlled(i32 %135, i32 %4, i64 %128)    ; IR: block %108: %109 = load i8, ptr %92; %110 = trunc nuw to i1  (in the arm of %107: the _controlled load, rule 5)
  %137 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: predicate of block %111 = %107 & %110 (br i1 %107 -> block %108, br i1 %110 -> block %111)
  call void @cqrt_and_i1(i32 %135, i32 %136, i32 %137)    ; IR: one Toffoli flag (rule 8)
  %138 = sub nsw i32 %131, %129    ; IR: %112  (classical m - j)
  %139 = shl nuw i32 1, %138    ; IR: %113  (classical 1 << (m - j))
  %140 = sitofp i32 %139 to double    ; IR: %114  (classical)
  %141 = fdiv double 0xC00921FB54442D18, %140    ; IR: %115  (classical angle -pi / 2^(m-j))
  call void @cqrt_rz_i1(i32 %137, double %141)    ; IR: block %111: cq_phi(%115)  [kickback on the flag]
  call void @cqrt_and_i1(i32 %135, i32 %136, i32 %137)    ; IR: uncompute the %111 predicate
  call void @cqrt_free(i32 %137)    ; IR: release the flag (|0>)
  call void @cqrt_qram_load_i1_hl_controlled_unc(i32 %136, i32 %135, i32 %4, i64 %128)    ; IR: un-copy %109 under the same %107 (its last reader is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %136)    ; IR: release the %109 rail (|0>)
  call void @cqrt_qram_load_i1_hl_unc(i32 %135, i32 %4, i64 %134)    ; IR: un-copy %106
  call void @cqrt_free(i32 %135)    ; IR: release the %106 rail (|0>)
  %142 = add nsw i32 %131, -1    ; IR: %117  (classical)
  %143 = sext i32 %142 to i64    ; IR: %118  (classical)
  %144 = icmp slt i64 %124, %143    ; IR: %119  (classical)
  br i1 %144, label %130, label %145    ; IR: br i1 %119, label %102, label %98

145:; IR: blocks %98, %120, %121
  %146 = getelementptr inbounds i8, ptr %8, i64 %124    ; IR: %99  (the cell c[j])
  %147 = ptrtoint ptr %146 to i64    ; IR: %99 as its run-time address
  %148 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %147)    ; IR: %100 = load i8, ptr %99; %101 = trunc nuw to i1: y of the in-place form below has another reader (br i1 %101): a plain load taken before the swap-out (rule 5, Readers; width i1 by rule 5 Width casts)
  call void @cqrt_rz_i1(i32 %148, double 0x400921FB54442D18)    ; IR: br i1 %101 -> block %120: cq_phi(pi)  [phase on the bare rail itself: a diagonal gate on the copy, no flag]
  call void @cqrt_qram_load_i1_hl_unc(i32 %148, i32 %4, i64 %147)    ; IR: un-copy the reader's copy (before the swap-out, the next memory version change)
  call void @cqrt_free(i32 %148)    ; IR: release it (|0>)
  %149 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %100/%101: in-place form at width i1 on %99, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %147, i32 %149)    ; IR: %100/%101: swap-out
  call void @cqrt_ry_i1(i32 %149, double 0x3FF921FB54442D18)    ; IR: %122 = cq_theta_i1(%101, pi/2)  [Ry in place on c[j]]
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %147, i32 %149)    ; IR: %123 = zext; store i8 %123, ptr %99: swap-in
  call void @cqrt_free(i32 %149)    ; IR: release the swap rail (|0>)
  %150 = add nsw i64 %124, -1    ; IR: %124  (classical)
  %151 = icmp sgt i64 %124, 0    ; IR: %125  (classical)
  br i1 %151, label %123, label %152    ; IR: br i1 %125, label %88, label %94

152:; IR: block %94
  %153 = icmp sgt i32 %1, 0    ; IR: %95  (classical)
  br i1 %153, label %154, label %170    ; IR: br i1 %95, label %96, label %126

154:; IR: block %96
  %155 = zext nneg i32 %1 to i64    ; IR: %97  (classical)
  br label %156

156:; IR: block %131  (measure c, classical)
  %157 = phi i64 [ 0, %154 ], [ %168, %156 ]    ; IR: %132  (classical j)
  %158 = phi i32 [ 0, %154 ], [ %167, %156 ]    ; IR: %133  (classical out)
  %159 = getelementptr inbounds i8, ptr %8, i64 %157    ; IR: %134  (the cell c[j])
  %160 = ptrtoint ptr %159 to i64    ; IR: %134 as its run-time address
  %161 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %160)    ; IR: %135 = load i8, ptr %134; %136 = trunc nuw to i1  (a plain bus load, SPEC GAP 1)
  %162 = call i1 @cqrt_measure_i1(i32 %161)    ; IR: %137 = cq_measure_i1(%136)  [the load copy is the measured rail, rule 2: never un-copied]
  %163 = zext i1 %162 to i32    ; IR: %138  (classical)
  %164 = trunc i64 %157 to i32    ; IR: %139  (classical)
  %165 = sub i32 %118, %164    ; IR: %140  (classical t - 1 - j)
  %166 = shl nuw i32 %163, %165    ; IR: %141  (classical)
  %167 = or i32 %166, %158    ; IR: %142  (classical)
  %168 = add nuw nsw i64 %157, 1    ; IR: %143  (classical)
  %169 = icmp eq i64 %168, %155    ; IR: %144  (classical)
  br i1 %169, label %170, label %156    ; IR: br i1 %144, label %126, label %131

170:; IR: block %126
  %171 = phi i32 [ 0, %152 ], [ %167, %156 ]    ; IR: %127  (classical)
  %172 = icmp sgt i32 %0, 0    ; IR: %128  (classical)
  br i1 %172, label %173, label %189    ; IR: br i1 %128, label %129, label %145

173:; IR: block %129
  %174 = zext nneg i32 %0 to i64    ; IR: %130  (classical)
  br label %175

175:; IR: block %147  (measure k, classical)
  %176 = phi i64 [ 0, %173 ], [ %187, %175 ]    ; IR: %148  (classical i)
  %177 = phi i32 [ %171, %173 ], [ %186, %175 ]    ; IR: %149  (classical out)
  %178 = getelementptr inbounds i8, ptr %6, i64 %176    ; IR: %150  (the cell k[i])
  %179 = ptrtoint ptr %178 to i64    ; IR: %150 as its run-time address
  %180 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %179)    ; IR: %151 = load i8, ptr %150; %152 = trunc nuw to i1  (a plain bus load, SPEC GAP 1)
  %181 = call i1 @cqrt_measure_i1(i32 %180)    ; IR: %153 = cq_measure_i1(%152)  [the load copy is the measured rail, rule 2: never un-copied]
  %182 = zext i1 %181 to i32    ; IR: %154  (classical)
  %183 = trunc i64 %176 to i32    ; IR: %155  (classical)
  %184 = add i32 %183, %1    ; IR: %156  (classical t + i)
  %185 = shl nuw i32 %182, %184    ; IR: %157  (classical)
  %186 = or i32 %185, %177    ; IR: %158  (classical)
  %187 = add nuw nsw i64 %176, 1    ; IR: %159  (classical)
  %188 = icmp eq i64 %187, %174    ; IR: %160  (classical)
  br i1 %188, label %189, label %175    ; IR: br i1 %160, label %145, label %147

189:; IR: block %145
  %190 = phi i32 [ %171, %170 ], [ %186, %175 ]    ; IR: %146  (classical)
  ret i32 %190    ; IR: ret i32 %146
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_f64(double)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_qram_load_i1_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i1_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i1_hl_controlled_unc(i32, i32, i32, i64)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_f64_hl(i32, i64)
declare void @cqrt_qram_load_f64_hl_unc(i32, i32, i64)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i1_qangle(i32, i32)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_rz_qangle_controlled(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare void @cqrt_free(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_or_i32(i32, i32)
declare void @cq_template_or_i32_unc(i32, i32, i32)
declare i32 @cq_template_sitofp_i32_to_f64(i32)
declare void @cq_template_sitofp_i32_to_f64_unc(i32, i32)
declare i32 @cq_template_fmul_f64_hl(i32, double)
declare void @cq_template_fmul_f64_hl_unc(i32, i32, double)
