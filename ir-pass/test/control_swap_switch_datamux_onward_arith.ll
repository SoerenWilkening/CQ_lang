; control_swap_switch_datamux_onward_arith.ll — ACCEPT (dugh, Phase 4×6; was the
; reject fixture control_swap_reject_switch_datamux_datause.ll pre-dugh): an
; all-ConstantInt DATA-MUX switch whose merge result feeds ONWARD-QUANTUM stock
; arithmetic (`%x = add %rm, 100`) that terminates at a measurement.
;
; PRE-dugh this DECLINED: the data-mux merge phi is UNTAINTED (all-ConstantInt
; incomings), so the FIRST forward propagation classified `%x` classical, and the
; `proveSwitchDataMux` G6 merge-out gate declined any non-measure/non-ret merge user
; (`%x = add %rm, 100` reads the i32 %out HANDLE as if it were the value — a
; classical-over-quantum leak). dugh instead RE-SEEDS a second propagation from the
; emitted `%out` (`repropagateControlMerges`, right after `lowerControlRegions`), so
; `%x` is re-tainted and `lowerOps` lowers it as the reversible quantum producer
; `cq_template_add_i32_hl(%out, 100)`; `%m` measures the result. This is the (A2)
; onward-QUANTUM subset the bead accepts. `%out` (a ControlOwnedRail) is left
; allocated; the add result is measured, not uncomputed.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]
  %x = add i32 %rm, 100          ; ONWARD QUANTUM: was a classical-over-quantum leak
  %m = call i32 @cq_measure_si32(i32 %x)
  ret i32 %m
}

; the data-mux preload + XOR-delta copies, then the ONWARD add re-tainted and lowered
; as a reversible quantum producer over %out, then the measure:
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call void @cqrt_copy_i32_controlled(
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[OUT]], i32 100)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OP]])

; the onward add is NOT left as a stock `add` (the pre-dugh leak) and the region
; ACCEPTS (no decline of any kind):
; CHECK-NOT: = add i32
; ACC-NOT: under quantum control
