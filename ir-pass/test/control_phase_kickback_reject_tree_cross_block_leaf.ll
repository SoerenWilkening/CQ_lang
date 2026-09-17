; control_phase_kickback_reject_tree_cross_block_leaf.ll — **ACCEPT since bd
; `test_C_libtooling-drbq.12` (2026-09-17).** It shipped as a DECLINE and its own
; header named this increment as the thing that would flip it. That header is kept
; verbatim below, and then answered.
;
; A compound branch-phase condition with a leaf defined in a DIFFERENT block from the
; branch.
;
; The stale-condition guard has two prongs: a position-FREE wire walk (no window,
; declines any off-ancestry theta on a leaf's provenance) and a POSITIONAL scan
; from each leaf forward to the branch. The positional prong is only a BOUNDED
; window when the leaf lives in the region's `Pred`; a cross-block leaf cannot be
; scanned, so it declined conservatively — the same disposition
; `RegionTreeDetect::staleCond` takes for the same reason.
;
; ⚠ IT IS AN OVER-DECLINE AND A KNOWN ONE. [verbatim from the decline version:]
; "The 4.4 select LIFTED the equivalent blanket cross-block decline (bd 9ymx, owner
; decision 2026-07-03) once it established that the position-free prong has no window
; and the positional one only ever adds other-wire conservatism. That argument
; transfers here, but transferring it is a change to a Rule-13 positional fence and
; belongs to a round with its own probe family — not to the increment that introduced
; the tree."
;
; ⚠ bd `drbq.12` IS THAT ROUND, AND IT DID NOT TRANSFER THE ARGUMENT — IT BUILT THE
; SCAN. The lift here is not "the positional prong only adds other-wire
; conservatism, so drop it": that reading would leave a cross-block leaf with NO
; window at all. Step 5a now calls `crossBlockCompareMintable`, which runs the SAME
; CFG-bounded walk Track P′ built for a claimed prep merge φ
; (`anyInstructionInGap`, visited-set bounded, budget exhaustion DECLINES) over
; every program point that can execute between the leaf and the mint, with the
; evidence scoped to a RAIL-RELABELLING gate on the LEAF's own rail
; (`railWireClosure`, BothWays). So the window is bounded and real, not dropped.
; Here the gap is `entry`'s tail plus `%pred` up to the branch: no theta, nothing.
;
; ⚠ THE NODE PRONG IS UNTOUCHED. `%c`, the `select i1` node, is in `%pred` — as it
; must be. A tree whose NODE is also hoisted still declines `control flow`, pinned by
; `control_phase_kickback_reject_inloop_hoisted_tree_node.ll`, because that prong
; carries a second, non-positional reason (the `ClaimedSelects` per-block hand-off).
;
; ⚠ The file name still says `reject_` on purpose — bd `gahu` precedent: a renamed
; fixture can be resurrected by a merge (L8). The rename is filed, not taken.
;
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
;
; RETIREMENT TRIGGER (L8): if step 5a's cross-block admission is narrowed back, this
; file returns to its inverted form expecting
; `cq controlled lowering: control flow under quantum control`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=NEG --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTRZ %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=CNTFREE %s < %t.cqd0.ll
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
; RUN: %filecheck --check-prefix=MXRZ %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMINT %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXSTRIP %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXFREE %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXTOF %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXMEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXNONE --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" --implicit-check-not="call void @cqrt_cnot(" %s < %t.cqd0.ll

; MXALLOC-COUNT-3: = call i32 @cqrt_alloc_
; MXALLOC-NOT: = call i32 @cqrt_alloc_
; MXRY-COUNT-2: call void @cqrt_ry_i32(
; MXRY-NOT: call void @cqrt_ry_i32(
; MXRZ-COUNT-1: call void @cqrt_rz_i1(
; MXRZ-NOT: call void @cqrt_rz_i1(
; MXMINT-COUNT-2: = call i32 @cq_template_icmp_
; MXMINT-NOT: = call i32 @cq_template_icmp_
; MXSTRIP-COUNT-2: call void @cq_template_icmp_
; MXSTRIP-NOT: call void @cq_template_icmp_
; MXFREE-COUNT-3: call void @cqrt_free(
; MXFREE-NOT: call void @cqrt_free(
; MXTOF-COUNT-2: call void @cqrt_toffoli(
; MXTOF-NOT: call void @cqrt_toffoli(
; MXMEAS-COUNT-2: = call i32 @cqrt_measure_
; MXMEAS-NOT: = call i32 @cqrt_measure_
; MXNONE-NOT: call{{.*}}@cq_theta_
; MXNONE-NOT: call{{.*}}@cq_measure_si32
; MXNONE-NOT: call{{.*}}@cq_phi


; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u1)
; CHECK: %[[FA:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK: %[[FB:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[R]], i32 3)
; CHECK: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[G]])
; CHECK: call void @cqrt_rz_i1(i32 %[[G]], double 3.000000e-01), !cq.branchphase
; CHECK: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[G]])
; CHECK: call void @cqrt_free(i32 %[[G]])
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FB]], i32 %[[R]], i32 3)
; CHECK: call void @cqrt_free(i32 %[[FB]])
; CHECK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[FA]], i32 %[[Q]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[FA]])

; A PHASE arm puts the answer on the FLAG: nothing is emitted on a user register.
; Negatives name the CALL, never the bare symbol (bd `qta2` — unused `declare`s stay).
; NEG-NOT: call void @cqrt_ry_i32_controlled
; NEG-NOT: call void @cqrt_cnot
; NEG-NOT: call{{.*}}@cq_phi
; NEG-NOT: call{{.*}}@cq_theta_

; CNTRZ-COUNT-1: call void @cqrt_rz_i1(
; CNTRZ-NOT: call void @cqrt_rz_i1(
; Three frees: the AND ancilla and the two leaf flags, each returned to |0> first.
; CNTFREE-COUNT-3: call void @cqrt_free(
; CNTFREE-NOT: call void @cqrt_free(

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i1 %g) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %ca = icmp eq i32 %q, 5
  br label %pred
pred:
  %cb = icmp eq i32 %r, 3
  %c = select i1 %ca, i1 %cb, i1 false
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m, %n
  ret i32 %s
}
