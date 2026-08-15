; control_predmux_reject_selectform_nofpclass_arg.ll — DECLINE (bd 615s, Option 1).
; ARM: the same `classifyConeNode` Argument clause, on the attribute the ticket is
; NAMED for — `nofpclass`, LLVM 19's FOURTH poison-generating annotation family and
; the one `hasPoisonGeneratingAnnotations()` does not count.
;
; WHY IT IS ITS OWN ROW rather than a spelling of the `range` row. bd u1rp widened
; the emit-time strip to LLVM's three DECLARED families via
; `dropPoisonGeneratingAnnotations()`, and bd 615s then MEASURED a fourth that
; survives the strip verbatim on a node the strip demonstrably visits (its `nnan
; ninf` fast-math flags ARE dropped, the `nofpclass(nan)` beside them is not). The
; two attributes therefore fail `coneDefinedAfterFlagDrop`'s promise by different
; routes, and both belong in the record.
;
; NOT A HAND-WRITTEN-IR SHAPE — MEASURED: stock `clang -O1 -ffinite-math-only` on
;     float f(float x, float y) { return x < y ? x : y; }
; emits
;     define nofpclass(nan inf) float @f(float noundef nofpclass(nan inf) %0,
;                                        float noundef nofpclass(nan inf) %1)
; and the fp survivors of CQ's curated keep-set (sqrt/fabs/copysign/floor/…) are
; exactly where a fast-math build puts such parameters.
;
; *** THE DISCRIMINATOR HERE IS THE DBG LINE, NOT THE ERROR — say so, because the
; error alone would make this row look like a red-green it is not. *** MEASURED by
; arm-kill: with the Argument clause disabled this module ALSO exits non-zero, with
; the SAME `cq controlled lowering` message, because an fp-leaf condition tree
; declines further downstream for an independent, pre-existing reason. What the
; clause changes is WHERE: with it, PredMux LEAVES the region at the cone gate
; (`gate=E6-condtree`, asserted below) instead of CLAIMING it and canonicalizing
; `select(a, b, false)` into `and(a, b)` first. Claiming and then declining later
; is not equivalent — the canonicalization is the mutation the proof licenses, and
; a later decline does not un-license it.
;
; *** AND THIS ROW DOES NOT "CARRY THE FAMILY" — an earlier draft said it did, and
; the Rule-13 round falsified that too. *** It carries the RELOCATION only. The
; `nofpclass` cell's genuine accept LOSS is witnessed by
; control_predmux_reject_selectform_nofpclass_arg_redgreen.ll, which was written
; because of this finding: there the shielded `fcmp` reads a TAINTED rail, so BASE
; emits 18 controlled gates and SHIP declines — a clean exit-0-to-exit-1 pair. The
; `range` sibling carries the third red-green. Between the three rows, two of the
; four attributes have a witnessing fixture and two (`nonnull`/`align`) are
; measured unreachable on this surface; the source comment says which is which.
;
; SCOPE: this closes the ATTRIBUTED argument only, measured population ZERO. The
; BARE `Argument` leaf is STILL treated as defined and bd 615s stays open for it.
; Do not read this file as having closed the Argument-leaf class, and do not quote
; the "28 of 49" budget an earlier draft carried here — see
; control_predmux_accept_selectform_bare_arg.ll for the corrected measurement.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u, float nofpclass(nan) %f) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %b = fcmp ogt float %f, 1.000000e+00   ; the SHIELDED operand, off %f
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; THE ARM. Without the Argument clause this line is ABSENT (the region is claimed
; and canonicalized, and the decline arrives later from another gate); with it, the
; region is left at the cone gate and never rewritten.
; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
