; control_peel_reject_cond_tree.ll — DECLINE `control flow` (bd
; test_C_libtooling-b6ap, P7 / **OQ-4**): the region's condition is an `and` of two
; tainted compares — a legitimate `CondTreeEmit::collectCondTree` condition — and
; P7 admits only a single `CmpInst` in the pred or a bare rail leaf. NOT PEELED.
;
; ⚠ A DELIBERATE, RECORDED OMISSION rather than an oversight: cloning a TREE is a
; materially bigger rewrite than cloning one compare, and it would put a second
; copy of a MULTI-NODE network (leaf flags + `cqrt_toffoli` conjunction ancillae +
; its LIFO teardown) on the condition wire. Over-declining is safe; the shape keeps
; the `control flow` it has today. Widening P7 to the tree is OQ-4 and is its own
; increment row.;
; bd `test_C_libtooling-b6ap` — THE MULTI-PHI MERGE PEEL (`MergePhiPeel.cpp`), one
; row of its P1-P9 DECLINE PARTITION. The peel is ACCEPT-ONLY and NEVER diagnoses:
; a shape that fails any clause is left BYTE-UNTOUCHED and reaches its existing
; loud owner unchanged. Over-declining is safe (Prime Directive); the peel's job is
; to remove a BOOKKEEPING over-decline, not to widen the accept class.

; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

define i32 @example() {
entry:
  %b0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %r0 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
  %c1 = icmp eq i32 %b0, 1
  %c2 = icmp eq i32 %r0, 3
  %c = and i1 %c1, %c2
  br i1 %c, label %m, label %a
a:
  %t = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  br label %m
m:
  %b1 = phi i32 [ %t, %a ], [ 0, %entry ]
  %mux = phi i32 [ 5, %a ], [ 2, %entry ]
  %x0 = tail call i32 @cq_measure_si32(i32 noundef %b1)
  %x1 = tail call i32 @cq_measure_si32(i32 noundef %mux)
  %s = add nsw i32 %x0, %x1
  ret i32 %s
}
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

; CHECK: <unknown>:0:0: in function example i32 (): cq controlled lowering: control flow under quantum control
