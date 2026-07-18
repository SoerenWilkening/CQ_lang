; lowering_predmux_leave_speccall_nonqram.ll — DECLINE probe (bd 20xt.4 Inc 2,
; blocker c): the pending-spec pure-callee proof's QROM-read admit is TIGHT — it
; reuses `qromReadShapeInScope`, which requires a `constant` initialised global
; (an immutable table). A read of a MUTABLE global is NOT a QROM read (the value
; could differ per execution), so `isSpeculatableDataflow` does not admit it: the
; callee is not a pure total function the linker/optimizer can freely re-evaluate,
; and lifting it would bake a stale table read into the speculated hoist + the
; Bennett clone (a verify-clean silent miscompile — the over-accept surface this
; probe fences). The shared `qromReadShapeInScope` also fences the spec-scan's
; `scanBody`, so the loud spec-scan decline fires char-for-char below (the spec
; pre-pass runs before `lowerControlRegions`; the `impure`/`nonconst` precedent).
; The E4 `isSpeculatablePureCalleeBody` fence is defense-in-depth — it too leaves
; the region were the spec-scan ever bypassed. Compare the ACCEPT twin with a
; `constant` table: lowering_predmux_speccall_flatten_qrom.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction)
; CHECK-NOT: @__cq_q_purefn
@G = internal unnamed_addr global [4 x i32] [i32 11, i32 22, i32 33, i32 44], align 16
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; A MUTABLE global read — NOT a QROM table (not `constant`).
define i32 @purefn(i32 %a) {
  %m = and i32 %a, 3
  %idx = zext i32 %m to i64
  %p = getelementptr inbounds [4 x i32], ptr @G, i64 0, i64 %idx
  %v = load i32, ptr %p, align 4
  %r = add i32 %v, %a
  ret i32 %r
}

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = call i32 @purefn(i32 %q)
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ 0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
