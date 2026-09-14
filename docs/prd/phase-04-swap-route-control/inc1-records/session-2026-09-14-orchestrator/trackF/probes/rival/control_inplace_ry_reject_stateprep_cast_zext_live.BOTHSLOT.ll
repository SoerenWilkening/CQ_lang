; control_inplace_ry_reject_stateprep_cast_zext_live.ll — DECLINE. The `zext`
; sibling of `..._cast_sext_live.ll` (round-3 lens R3, F-R3-2; source
; `$S/review3/R3/p/g04_ull_eq5.c`, `unsigned long long t = (unsigned)q;`).
;
; Both spellings are in the family because `ConstantRange::castOp` reads them
; differently and only one of them is numerically the identity — the fence must
; not accidentally rest on `sext` being value-preserving.
;
;
; ---- STILL A DECLINE AFTER THE 2026-09-11 NARROWING (bd `drbq.14`) ----
;
; F2 was narrowed on 2026-09-11 (owner ruling): a pinned value that lies on the
; CONDITION'S OWN BACKWARD WIRE — `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))` — is
; no longer a collider, and NINETEEN fixtures of this family flipped to ACCEPT
; (they are now `control_inplace_ry_stateprep_*`). **THIS ONE DID NOT, and the
; reason is not an accident:**
;
; the pinned value is a FORWARD user AND is TYPE-DISJOINT from every cone
; member (the cone is at the root's width; the seed is not), so it is out
; of `CondWire` structurally as well as directionally. A cast rail is a
; DIFFERENT PHYSICAL WIRE that EXISTS in the module, which is exactly what
; F-R3-2 measured as eight plain-C accepts through the retired type gate.
;
; So the narrowing is the WIRE and nothing wider, and this file is one of the 21
; that prove it. Measured 2026-09-11 on the narrowed binary: rc=1, same string,
; same anchor.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_theta_ull(i64, double)
declare i64 @cq_measure_ull(i64)

define i64 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %t  = zext i32 %q to i64
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i64 @cq_theta_ull(i64 %t, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i64 [ %rt, %arm ], [ %t, %entry ]
  %mr = call i64 @cq_measure_ull(i64 %rm)
  %mt = call i64 @cq_measure_ull(i64 %t)
  %s  = add i64 %mr, %mt
  ret i64 %s
}
