; control_swap_reject_seq_shared_cond.ll — **ACCEPT since bd
; `test_C_libtooling-drbq.12` (2026-09-17).** It shipped as a DECLINE (bd hcrg
; decline partition): two sequential regions branching on ONE CSE'd condition. The
; original header is kept verbatim below because its safety sentence is the thing
; this flip has to answer, and answering it is the whole content of this file.
;
; `if(q>5){φ a}; if(q>5){φ b}` after CSE: a single `%c1` in `entry` feeding
; BOTH conditional branches. The second region's condition is therefore defined
; OUTSIDE its own Pred block, and `condWireDisposition` (named
; `nonDiagonalGateBeforeBranch` before bd lom0 Inc 4) declined any
; condition it could not bound a positional scan for:
;   `if (Cond->getParent() != R.Pred) return true;  // unbounded gap`
;
; NOTE THE MESSAGE IS IMPRECISE AND THAT IS PRE-EXISTING, not something hcrg
; introduced: there is no non-diagonal gate anywhere in this module. [That sentence
; is from the decline version and is worth keeping — it is the tell that the fence
; firing here was POSITIONAL, never a wire finding.]
;
; ⚠ THE DECLINE VERSION'S SAFETY SENTENCE, AND WHY IT NO LONGER HOLDS. It read:
; *"it must hold, because a flag minted at region 2's branch from a compare that
; dominates region 1 has no proven relationship to the wire region 1 left behind."*
; That was TRUE when it was written and is FALSE now, for a reason recorded in this
; very file's own migration note: under the RETIRED register surface a phase arm was
; `q = cq_phi(q, θ)`, so region 1 really did put a gate on `q` and really did leave a
; different wire behind. Under the shipped register-free KICKBACK (bd `3qlq` Inc 1,
; Rule 7) a phase arm emits NOTHING on `q`: it mints a flag from `q`, fires
; `cqrt_rz_i1` on the FLAG, recomputes the compare to strip the flag, and frees it.
; `q` is read twice and left exactly as it was. The relationship region 2 needs is
; therefore proven — by the mechanism, not by an assumption.
;
; ⚠ AND THE ACCEPT IS NOT GRANTED ON THAT ARGUMENT ALONE. `crossBlockCompareMintable`
; WALKS the gap — region 1's arm and merge, every program point between `%c1` and
; region 2's branch — looking for a rail-relabelling gate on `%c1`'s own rail
; closure, and finds none. Had region 1's arm carried `cq_theta(&q, …)`, the walk
; would have found it and this file would still decline; that program is
; `control_inplace_ry_reject_crossblock_cond_wire_gate_in_gap.ll`, with its
; one-line-apart accepting control beside it.
;
; ⚠ The file name still says `reject_` on purpose — bd `gahu` precedent: a renamed
; fixture can be resurrected by a merge (L8). The rename is filed, not taken. The
; `swap_` in the name is older history still (the route is retired; CLAUDE.md's
; Hallucination-Risk callouts).
;
; ⚠ RETIREMENT TRIGGERS (L8), and the FIRST one is NOT the obvious one — it was
; supplied by the independent Rule-13 round (§5, "the single most dangerous accept
; among the 14 movers"), which observed that this file's correctness is now
; **contingent on a convention that lives in another file**:
;   (a) **THE DIRECTION THAT ACTUALLY ENDANGERS THIS FILE: if ANY phase-arm emitter
;       ever again puts a gate on the USER'S REGISTER.** The accept above rests on
;       Rule 7 — a phase arm emits mint → `cqrt_rz_i1` on the FLAG → strip → free and
;       NOTHING on `q`, so region 1 leaves the wire exactly as it found it. CLAUDE.md
;       records that THREE earlier phase-arm forms did put a tensored Rz on `q`, and
;       that all three made every shipped Grover golden the IDENTITY. If one returns,
;       this fixture becomes a silent miscompile with no fence tying the two files
;       together. Re-derive from `SwapRouteEmit`'s emission contract, not from here.
;   (b) if `condWireDisposition`'s cross-block prong is narrowed back, this file
;       returns to its inverted form expecting
;       `cq controlled lowering: condition predates a non-diagonal gate under quantum control`.
; Trigger (b) is the bookkeeping one; trigger (a) is the unitary one.
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
; RUN: %filecheck --check-prefix=MXMEAS %s < %t.cqd0.ll
; RUN: %filecheck --check-prefix=MXNONE --implicit-check-not="call void @cqrt_x(" --implicit-check-not="call void @cqrt_cswap(" --implicit-check-not="call void @cqrt_cnot(" %s < %t.cqd0.ll

; MXALLOC-COUNT-1: = call i32 @cqrt_alloc_
; MXALLOC-NOT: = call i32 @cqrt_alloc_
; MXRY-COUNT-1: call void @cqrt_ry_i32(
; MXRY-NOT: call void @cqrt_ry_i32(
; MXRZ-COUNT-2: call void @cqrt_rz_i1(
; MXRZ-NOT: call void @cqrt_rz_i1(
; MXMINT-COUNT-2: = call i32 @cq_template_icmp_
; MXMINT-NOT: = call i32 @cq_template_icmp_
; MXSTRIP-COUNT-2: call void @cq_template_icmp_
; MXSTRIP-NOT: call void @cq_template_icmp_
; MXFREE-COUNT-2: call void @cqrt_free(
; MXFREE-NOT: call void @cqrt_free(
; MXMEAS-COUNT-1: = call i32 @cqrt_measure_
; MXMEAS-NOT: = call i32 @cqrt_measure_
; MXNONE-NOT: call{{.*}}@cq_theta_
; MXNONE-NOT: call{{.*}}@cq_measure_si32
; MXNONE-NOT: call{{.*}}@cq_phi


; TWO independent kickback groups on ONE register, each with its own flag.
; CHECK: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK: call void @cqrt_rz_i1(i32 %[[F1]], double %a), !cq.branchphase
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F1]])
; CHECK: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK: call void @cqrt_rz_i1(i32 %[[F2]], double %b), !cq.branchphase
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[Q]], i32 5)
; CHECK: call void @cqrt_free(i32 %[[F2]])
; CHECK: call i32 @cqrt_measure_i32(i32 %[[Q]])

; NOTHING is emitted on the user register `%[[Q]]` — it appears only as arg-0 of the
; two mints and the two strips, and in its measure. Negatives name the CALL (bd `qta2`).
; NEG-NOT: call void @cqrt_ry_i32_controlled
; NEG-NOT: call void @cqrt_cnot
; NEG-NOT: call void @cqrt_toffoli
; NEG-NOT: call{{.*}}@cq_phi
; NEG-NOT: call{{.*}}@cq_theta_

; TWO kickbacks, TWO frees — one per region, and no third rail anywhere.
; CNTRZ-COUNT-2: call void @cqrt_rz_i1(
; CNTRZ-NOT: call void @cqrt_rz_i1(
; CNTFREE-COUNT-2: call void @cqrt_free(
; CNTFREE-NOT: call void @cqrt_free(
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  call void @cq_phi(double %a)
  br label %m1
m1:
  br i1 %c1, label %arm2, label %m2    ; the SAME %c1, defined in %entry
arm2:
  call void @cq_phi(double %b)
  br label %m2
m2:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
