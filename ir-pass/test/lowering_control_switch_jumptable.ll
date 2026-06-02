; lowering_control_switch_jumptable.ll — Phase 4.1 spike (epic `-aht.3`),
; negative SAFETY guard. `clang -O1` may lower a tainted `switch`/`if-else-if`
; over rotation ANGLES not to a `select` chain (WP16) but to a jump TABLE — a
; constant array + `getelementptr` + `load` indexed by the scrutinee. Because
; there is no `SwitchInst` left, this escapes the WP12 guard; left unguarded the
; diamond matcher lowers it and the program indexes the classical table by the
; quantum HANDLE ID (an allocation counter), not the superposed value, then
; rotates by the garbage angle — a SILENT MISCOMPILE. The spike (`-aht.3`
; diagnose-first) found this; the guard diagnoses any tainted value used as a
; memory address/index (`gep`/`load`/`store`), restoring the "no silent
; miscompile" invariant. (Lowering the jump-table angle dispatch to controlled
; rotations is a future enhancement, tracked separately.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}memory addressing under quantum control
@switch.table = private unnamed_addr constant [3 x double] [double 1.000000e-01, double 2.000000e-01, double 3.000000e-01], align 8
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %idx = add i32 %q, -1
  %bound = icmp ult i32 %idx, 3
  br i1 %bound, label %lookup, label %merge
lookup:
  %zext = zext i32 %idx to i64
  %gep = getelementptr inbounds [3 x double], ptr @switch.table, i64 0, i64 %zext
  %ang = load double, ptr %gep, align 8
  br label %merge
merge:
  %a = phi double [ %ang, %lookup ], [ 9.000000e-01, %entry ]
  %r = call i32 @cq_phi_si32(i32 %v, double %a)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
