; lowering_control_escape_goto.ll — Phase 4.1 WP17 (PRD §8.6, epic `-aht.2`),
; negative. A `goto` out of a quantum-controlled arm is the general
; non-reconverging escape. Janus / reversible-flowchart theory bans arbitrary
; `goto`/`break`/`return` and proves (Structured Reversible Program Theorem)
; that no expressive power is lost — the programmer refactors. Here the
; tainted-condition true arm carries a side effect and jumps to a block reached
; on BOTH paths, so it neither reconverges as a clean diamond nor is a pure
; ret/measure escape: the safety net rejects it loudly rather than branch on the
; handle id.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sink(i32)
define i32 @example(i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 0
  br i1 %c, label %target, label %normal   ; if (q > 0) goto target;
normal:
  call void @sink(i32 1)
  br label %target
target:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
