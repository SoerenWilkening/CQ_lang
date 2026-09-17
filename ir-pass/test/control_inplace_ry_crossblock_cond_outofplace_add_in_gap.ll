; control_inplace_ry_crossblock_cond_outofplace_add_in_gap.ll — ACCEPT, and it is the
; **DISCLOSURE** fixture of bd `test_C_libtooling-drbq.12` (2026-09-17): the shape a
; reviewer will reach for first when asking what the widening does about the dtzb
; in-place `add`/`sub`/`xor`, which `crossBlockCompareMintable`'s gap walk does NOT
; name.
;
; The module is `control_inplace_ry_crossblock_cse_cond.ll` — two sequential regions
; over ONE CSE'd `a == 5` compare in the entry block — plus a single instruction:
;
;     %u = add nsw i32 %1, 1        ; in the SHARED MERGE BLOCK, i.e. in the GAP
;
; `%1` is the condition's own register. `railWireClosure` crosses an
; `add`/`sub`/`xor` hop, so `%u` IS an M-C in-place CANDIDATE on the very rail the
; second region's flag mint will read. If it lowered in place, the mint would read a
; PERMUTED basis and the `icmp_..._unc` strip could not return the flag to |0>.
;
; ⚠ IT LOWERS OUT OF PLACE, MEASURED, AND THAT IS WHY THE ACCEPT IS SOUND. The
; emitted form is `%h_op = cq_template_add_i32_hl(i32 %h, i32 1)` — a template that
; MINTS A FRESH RAIL and leaves `%h` untouched. Check that literally below; it is the
; whole property this fixture exists for.
;
; ⚠ THE GROUND IS M-C's G6, NOT ANYTHING THIS BEAD ADDED, AND A FENCE HERE WAS BUILT
; AND REMOVED. `crossBlockCompareMintable` briefly carried an `add`/`sub`/`xor` arm
; on the both-roots reading `railWireClosure` uses. Measured on this module, that arm
; was a pure OVER-DECLINE: it refused a program whose add never touches the condition
; rail. The structural reason it cannot touch it is ORDER — control emission runs
; BEFORE `lowerOps`, so when `classifyInPlaceReassignment` decides, the flag mint, the
; `_unc` strip and the controlled gate are already real instructions reading `%h` and
; already positioned after the add; G6 refuses in-place for a parent with a use it
; cannot prove earlier. Asking M-C from detection instead would be unsound in the
; OTHER direction (its answer is taken at FINAL taint over a FINAL CFG, so a `false`
; at round 1 can become `true` later).
;
; ⚠ RETIREMENT TRIGGER, SHARED NOT NEW: this file is a tripwire for the pin
; `railCondWireDisposition`'s and `chainedThetaBetweenDefAndBranch`'s headers already
; carry — *"if M-C's G6 ever admits an in-place op on a rail with a later read, this
; ground is gone"*. **The day the CHECK below stops saying `cq_template_add_i32_hl`
; and starts saying `cqrt_addc_i32`, this accept has become an OVER-ACCEPT and the
; removed fence is the shape to re-derive.** Its companion
; `control_inplace_ry_crossblock_cond_inplace_add_after_loop.ll` shows the same add
; DOES convert in place when nothing of the region follows it — so the discriminator
; really is position relative to the emitted stream, not the opcode.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NEG %s < %t.cqd0.ll
; ---- MUTATION-MATRIX HARDENING (bd `test_C_libtooling-drbq.12`, 2026-09-17) ----
; Rule 12(c): a fixture is validated by MUTATION, not by re-reading its prefixes.
; The first injection-matrix run over this batch reported 21 MISSED over 9 accept
; fixtures — a stray `cqrt_ry` before the `ret`, a duplicated mint, a duplicated
; free, and a `cqrt_x` injected onto the USER REGISTER all slipped through, because
; no whole-file prefix counted those symbols here. The block below is the closure:
; an EXACT count per symbol (a `COUNT-n` followed by its own `-NOT`, which is what
; turns "at least n" into "exactly n"), ONE PREFIX PER SYMBOL because consecutive
; `COUNT`s under a shared prefix scan FORWARD and fall through to the trailing
; `declare` lines, and a pure-negative prefix for the two gates that must never
; appear. Counts are MEASURED off this fixture's own lowered output, never guessed.
; RUN: %filecheck --check-prefix=MXALLOC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRY %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXRYC %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXNONE --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" --implicit-check-not="call void @cqrt_cnot(" %s < %t.cqd0.ll

; MXALLOC-COUNT-2: = call i32 @cqrt_alloc_
; MXALLOC-NOT: = call i32 @cqrt_alloc_
; MXRY-COUNT-2: call void @cqrt_ry_i32(
; MXRY-NOT: call void @cqrt_ry_i32(
; MXRYC-COUNT-2: call void @cqrt_ry_i32_controlled(
; MXRYC-NOT: call void @cqrt_ry_i32_controlled(
; MXMINT-COUNT-2: = call i32 @cq_template_icmp_
; MXMINT-NOT: = call i32 @cq_template_icmp_
; MXSTRIP-COUNT-2: call void @cq_template_icmp_
; MXSTRIP-NOT: call void @cq_template_icmp_
; MXFREE-COUNT-2: call void @cqrt_free(
; MXFREE-NOT: call void @cqrt_free(
; MXMEAS-COUNT-2: = call i32 @cqrt_measure_
; MXMEAS-NOT: = call i32 @cqrt_measure_
; MXNONE-NOT: call{{.*}}@cq_theta_
; MXNONE-NOT: call{{.*}}@cq_measure_si32
; MXNONE-NOT: call{{.*}}@cq_phi


; CHECK: %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 9.000000e-01)
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F1]])
; THE PROPERTY. An OUT-OF-PLACE add: a fresh handle out, `%[[H]]` unchanged.
; CHECK: %{{[a-zA-Z0-9_.]+}} = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 1)
; CHECK: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[R]], double 9.000000e-01)
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F2]])

; The negative that makes the CHECK above mean something: no IN-PLACE add anywhere.
; NEG-NOT: call void @cqrt_addc_
; NEG-NOT: call void @cqrt_xorc_

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01) #2
  %3 = icmp eq i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 9.000000e-01) #2
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ %2, %0 ]
  %u = add nsw i32 %1, 1
  br i1 %3, label %8, label %10

8:                                                ; preds = %6
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 9.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %6
  %11 = phi i32 [ %9, %8 ], [ %7, %6 ]
  %12 = tail call i32 @cq_measure_si32(i32 noundef %u) #2
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #2
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

attributes #0 = { nounwind ssp uwtable }
attributes #2 = { nounwind }
