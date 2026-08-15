; control_predmux_reject_selectform_nofpclass_arg_redgreen.ll — DECLINE (bd 615s).
; ARM: the `nofpclass` cell of `classifyConeNode`'s Argument clause, as a CLEAN
; exit-0 → exit-1 RED-GREEN over a BASE that emits a WORKING CIRCUIT.
;
; *** THIS ROW EXISTS BECAUSE ITS SIBLING COULD NOT DO THIS JOB, and the Rule-13
; round is what established that. *** control_predmux_reject_selectform_nofpclass_
; arg.ll uses an all-classical fp leaf, which declines DOWNSTREAM for an
; independent pre-existing reason whether the attribute is present or not — so its
; only discriminator is the `CQ_PREDMUX_DBG` gate line, and it witnesses the
; RELOCATION of a decline, never the LOSS of an accept. Rule 12 asks for a fixture
; that actually witnesses the predicate; for `nofpclass` there was none, and the
; four-attribute enumeration rested entirely on the `range` row.
;
; THE DIFFERENCE IS THE TAINTED fcmp. Here the shielded operand compares a TAINTED
; `cq_theta_f64` rail against the attributed parameter, so the whole region is a
; genuine claimable PredMux shape. MEASURED, BASE (pre-batch) vs SHIP:
;
;   nofpclass present  : BASE exit 0, emitting 18 `cqrt_toffoli` /
;                        `cqrt_copy_i32_controlled` gates  ·  SHIP exit 1
;   attribute removed  : BASE exit 0  ·  SHIP exit 0        (the isolation control)
;
; So the attribute ALONE flips a lowering, linking, running program into a loud
; decline. That is an accept LOSS, and it should be read as one: it is the price of
; the clause, paid because `coneDefinedAfterFlagDrop`'s promise ("the cone is
; DEFINED once its poison-generating annotations are dropped") cannot be kept for a
; value whose definedness rests on a fact the CALLER supplies and this pass cannot
; drop — the attribute lives on the caller's call site in another function, while
; `dropPoisonGeneratingAnnotations()` mutates instructions.
;
; The population of the shape is ZERO across the corpora measured (see the source
; comment), and stock `clang -O1 -ffinite-math-only` is where such parameters come
; from — so the loss is real but currently unpopulated.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare double @cq_theta_f64(double, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u, double %uf, double nofpclass(nan inf) %x) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %qf = call double @cq_theta_f64(double %uf, double 2.500000e-01)
  %a  = icmp sgt i32 %q, 3
  %b  = fcmp ogt double %qf, %x        ; the SHIELDED operand, off the attributed %x
  %c  = select i1 %a, i1 %b, i1 false
  br i1 %c, label %arm, label %merge

arm:
  %k1 = add i32 %q, 7
  %k2 = mul i32 %q, 3
  %k3 = add i32 %q, 11
  %k4 = mul i32 %q, 5
  br label %merge

merge:
  %p1 = phi i32 [ %k1, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %p3 = phi i32 [ %k3, %arm ], [ %q, %entry ]
  %p4 = phi i32 [ %k4, %arm ], [ %q, %entry ]
  %s1 = add i32 %p1, %p2
  %s2 = add i32 %s1, %p3
  %s3 = add i32 %s2, %p4
  %m  = call i32 @cq_measure_si32(i32 %s3)
  ret i32 %m
}

; The region is LEFT at the cone gate — never claimed, so never canonicalized:
; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
