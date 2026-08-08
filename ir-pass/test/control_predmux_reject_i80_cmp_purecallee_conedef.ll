; control_predmux_reject_i80_cmp_purecallee_conedef.ll — DECLINE (bd 3c6m.14.2).
;
; *** THIS FILE WAS AN ACCEPT FIXTURE ONE SESSION AGO, AND THE REVERSAL IS THE
; POINT. *** bd 3c6m.14.1 shipped it as
; control_predmux_accept_i80_cmp_purecallee_conedef.ll, pinning surface S4 —
; `coneDefinedAfterFlagDrop`'s admission of a call in a poison-shielded cone on
; the strength of `isSpeculatablePureCalleeBody`. bd 3c6m.14.2 DELETED that
; admission. Read the clause in PredMuxFlatten.cpp for the full argument; the
; short version, and the reason a fixture flipped polarity rather than being
; patched:
;
;  * The purity proof answers "pure + total + terminating", which is NOT
;    "returns a defined value". It reaches its verdict through
;    `isSpeculatableDataflow` (variable-amount shifts and fp->int casts admitted
;    unconditionally) and it SKIPS TERMINATORS, so `ret i32 poison` passes
;    VACUOUSLY. Both faces were exhibited END-TO-END as verify-clean silent
;    miscompiles — see control_predmux_reject_selectform_purecallee_retpoison.ll
;    and ..._inherentpoison.ll.
;  * A definedness proof over an arbitrary callee body was WRITTEN FIRST, as the
;    ticket proposed. Its own Rule-13 round found a fresh verify-clean silent
;    miscompile inside it — a curated `ctlz(0, true)` whose poison rides an
;    IMMARG that no `drop*` API can strip — plus an unsound `getZExtValue`
;    shift-width check, in ~40 lines of new proof serving ZERO measured inputs.
;  * MEASURED before choosing, which is what the ticket asked for: the clause was
;    reached by 1 of 949 ir-pass fixtures (this one) and 0 of 238 e2e slices, and
;    of the 39 poison-shielded select-forms `clang -O1` emits across 248 real
;    openlibm TUs, the 5 with a call in the shielded cone carry ONLY curated
;    intrinsics. The surface was empty.
;
; WHAT DID *NOT* REGRESS, because it is a different surface and the ticket
; conflated the two: the pure-callee admission at S1 —
; `recoverRegion`'s E4 CALL admission, where the call sits in an ARM rather than
; in a shielded CONDITION cone — is untouched. That is the plain -O1
; expl→floorl / coshl→expl shape, and lowering_predmux_speccall_flatten.ll,
; lowering_fp80_union_seed_purecall_i80cmp.ll and the multi-TU e2e slice
; e2e-predmux-purecallee-i80cmp all still pass. S1/S2/S3/S5 keep the bd 3c6m.14.1
; `AdmitI80Compare=true` widening in full; only S4 is gone.
;
; The i80 compare below is therefore no longer load-bearing for this file's
; verdict — a callee with NOTHING but an `add` declines here too. It is kept
; verbatim so the fixture still names the exact module bd 3c6m.14.1 cleared, and
; so a future agent re-widening the clause sees its own history.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
e:
  %z = zext i32 %a to i80
  %m = and i80 %z, 4294967295
  %eq = icmp eq i80 %m, 555
  %w = zext i1 %eq to i32
  ret i32 %w
}

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @leaf(i32 %q)
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false     ; clang -O1's poison-shielded `a && b`
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:                                    ; 2 merge phis = the W3 claim witness
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s)
  ret i32 %m2
}

; The gate is still E6-condtree — the shielded-cone proof — and the decline is
; still detect-before-mutate. What changed is the ANSWER, not the site.
; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
