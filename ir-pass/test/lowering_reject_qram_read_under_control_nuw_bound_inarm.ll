; lowering_reject_qram_read_under_control_nuw_bound_inarm.ll — DECLINE (bd s6ao).
; THE SAME FLAG-DERIVED BOUND, WITH THE FLAGGED INSTRUCTION INSIDE THE ARM.
;
; Sibling of lowering_reject_qram_read_under_control_nuw_bound.ll, which places
; the `sub nuw` in the PRED. Here it sits in the region ARM — the block whose
; every non-terminator `moveBody` (PredMuxFlatten.cpp) unconditionally runs
; `dropPoisonGeneratingFlags` over. This placement is a SEPARATE fixture and not
; a second function in the first one, because `opt` emits the first `DS_Error`
; and exits, so one file can only ever assert one diagnostic.
;
; WHY BOTH PLACEMENTS ARE PINNED. Measured on the pre-fix plugin, the two
; placements emitted a BYTE-IDENTICAL unmasked `cqrt_qram_load_f64` — the claim
; is taken PRE-strip in both cases, so `moveBody`'s later drop changes nothing,
; and the top-level path never re-proves (`lowerQramReads` gates its re-proof on
; `inBennettClone`; a top-level read is left to the source's own obligation).
; That is why bd m9d2 — which observed the SAME flag drop causing a spurious
; DECLINE — and bd s6ao are two faces of one defect: the sign flips with block
; topology, so a fixture at only one placement would leave the other unpinned
; and a future reader would mistake the pair for two unrelated bugs.
;
; The fix (`UseInstrInfo=false` in `qromIndexKnownInBounds`) makes the proof
; poison-independent, so the verdict no longer depends on WHERE the flag sits —
; which is exactly what makes both placements decline identically here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s
@t3 = internal unnamed_addr constant [3 x double] [double 1.0, double 2.0, double 3.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @probe(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %hi = lshr i64 %bits, 63
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %sx = sub nuw i64 %hi, 1                 ; IN-ARM: moveBody strips this flag
  %g = getelementptr inbounds [3 x double], ptr @t3, i64 0, i64 %sx
  %v = load double, ptr %g, align 8
  %hd = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hd, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; Mirrored character-for-character from `kMsgQromUnderControlBounds`.
; CHECK: error: {{.*}}cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)
