; control_swap_empty_arm.ll — ACCEPT probe: a degenerate EMPTY phase arm.
;
; `if (q > 5) {}` — the arm holds no gate, so the merge phi is just `q` on both
; edges. This is pure identity on q: the swap-route emitter routes NOTHING (no
; flag, no rail, no strip — there is no quantum op to control), just RAUWs the
; phi to q and flattens the dead diamond CFG. The result is a single block that
; allocates/prepares q and measures it, with NO cswap / alloc-rail / icmp flag.
; (clang -O1 normally elides an empty-arm diamond outright; this pins the emitter
; against the shape regardless, so it can never silently strand a tainted br.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %k = icmp sgt i32 %q, 5
  br i1 %k, label %arm, label %merge
arm:
  br label %merge
merge:
  %qm = phi i32 [ %q, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; A CHECK-NEXT chain pins the ENTIRE lowered body to exactly q-prep + measure +
; ret — leaving no room for any cswap / |0> rail alloc / icmp flag / phi.
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %{{[a-zA-Z0-9_.]+}} = call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK-NEXT: ret i32
; Dephasing/shape guards (the §8 probe-6 phase-fixture discipline — the CHECK-NEXT
; chain above already leaves no room, these make the intent explicit and uniform
; with every other phase accept fixture): no method-B copy leaks onto a phase arm
; (Rule 7), zero controlled gates, no surviving data mux.
; CHECK-NOT: cqrt_copy
; CHECK-NOT: _controlled
; CHECK-NOT: phi i32
