; control_classical_call_arm_reject_qrom_callee.ll — TOTALITY reject, the DEFERRED
; OBLIGATION case (bd wve8). The callee body is visible, pure, acyclic, branchless
; and passes `isSpeculatablePureCallee` — and it is still refused, because the one
; clause that admits it (`qromReadShapeInScope`, the const-global QROM read)
; proves the SHAPE and DEFERS THE BOUNDS PROOF to a stage the 6.5 arm never runs.
;
; *** THIS IS THE PROBE THAT BROKE THE FIRST bd wve8 FIX. *** That fix gated the
; 6.5 arm on `isSpeculatablePureCallee`, which closed the `sdiv` hole the ticket
; was filed on and left this one wide open. A Rule-13 lens exhibited it in plain C
; at -O1 and the orchestrator reproduced it independently:
;     static const int tab[4] = {11, 22, 33, 44};
;     __attribute__((noinline)) static int lookup(int i) { return tab[i]; }
;     int q = cq_theta_si32(0, 0.0);            /* Ry(0) = identity          */
;     int y = q;
;     if (q > 3) y = lookup(idx);               /* guard: ZERO amplitude     */
;     return cq_measure_si32(y);
; clang -O1 infers `memory(none)` on `lookup` — a read of CONSTANT memory is not a
; memory access to FunctionAttrs — so the PURITY gate passes on a function that
; really does load, and the index is a plain classical parameter that no quantum
; guard can constrain. The hoist executes the read. MEASURED: idx = 100000000 gave
; run_exit=139 (SIGSEGV); idx = 9 gave NO crash and `cqrt_alloc_i32(539780133)` in
; the trace — a word read past the end of the table, route-merged into the
; controlled register on a run where the source never evaluated the call. Both at
; `cq-opt` exit 0, verifier clean, free_pairing_check 2 verified / 0 violations /
; 0 unproven.
;
; THE FIX IS A SEPARATE ENTRY POINT, NOT A LOOSER PREDICATE: `classifyClassicalCallArm`
; now calls `isSpeculatableTotalCallee`, the strict twin that refuses every clause
; whose obligation is discharged DOWNSTREAM. S1/S2 (PredMux E4 call admission) and
; S3 (Fp80Union's seed cone) keep the lax form and are byte-identical, because for
; them the deferral is real — the callee is about to be cloned and lowered and the
; clone's own flatten re-proves the bounds. 6.5 is clone-ORTHOGONAL: no clone, no
; lowering of the callee, nothing downstream to discharge anything.
;
; ARM-KILL, and it is the edit that ISOLATED the QROM clause as the admitting one:
; change the ONLY token `constant` to `global` on @tab. `qromReadShapeInScope` then
; refuses the non-constant base, the load leaves the whitelist, and the region
; declines EVEN ON THE PRE-FIX PLUGIN. So the accept this file pins was the QROM
; read and nothing else about the shape.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; the table and the accessor exactly as clang -O1 emits them.
@tab = internal unnamed_addr constant [4 x i32] [i32 11, i32 22, i32 33, i32 44], align 16

define internal i32 @lookup(i32 noundef %i) #0 {
  %w = sext i32 %i to i64
  %p = getelementptr inbounds [4 x i32], ptr @tab, i64 0, i64 %w
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

define i32 @example(i32 %u0, i32 %idx) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 0.000000e+00)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @lookup(i32 %idx)   ; index unbounded — nothing ever proves it
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; NOTE, so nobody adds a vacuous assertion here: there is deliberately NO
; `CHECK-NOT` for the emitted stream. On a `DS_Error` the diagnostic handler exits
; before the module is printed, so cq-opt writes ZERO bytes to stdout and a
; CHECK-NOT over this stream can never match under ANY behaviour of the gate —
; it would read as a second, independent assertion while asserting nothing. The
; decline is fully pinned by `not` (the exit code) plus the message above.
