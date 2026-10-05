; control_angle_select_reject_forward_rail_cycle_stale_alias.ll — DECLINE (the
; stale-reader fence; bd 3paw's adversarial twin). `clang -O1` output of
; (attributes and `!llvm.loop` dropped):
;
;     int slice(int u0, int u1, int n) {
;       int q = u0; cq_theta(&q, .5);  int r = u1; cq_theta(&r, .25);
;       int z = r;                                     // the PRE-gate record
;       cq_theta(&r, q == 5 ? .9 : .3);
;       for (int i = 0; i <= n; i++) cq_theta(&z, .1); // rotates the STALE name
;       return cq_measure(q);
;     }
;
; WHY THIS IS THE ATTACK ON bd 3paw. Case-A claims this rail too: the header φ
; `%14 = phi [%15, loop], [%5, entry]` reads the pre-gate name `%5`, its latch
; peels back to itself, its external incoming peels to the clean mint `%5`, and
; `staleRailRecordRead` skips a chain MEMBER's read, so nothing in `tryCaseA`
; refuses it. The collapse then RAUWs `%14` to `%5`, and at detection this
; function is IR-IDENTICAL to `@slice_dead` in
; `control_angle_select_forward_rail_cycle_frozen.ll` (a legal program): the
; consumer's result is dead and the loop rotates `%5` under the dominance of the
; consumer. `classifyAngleSelect`'s bd 3paw skip therefore ADMITS it, and what
; keeps it loud is the fence that recorded the question on the PRE-collapse IR:
; `recordStaleQuantumReaders` (before `lowerLoops`) sees the loop's
; `cq_theta(%14, .1)` read the record `%5` past the consumer's Ry and declines it
; at its late slot. Its uncontrolled twin (`.3` in place of the select) declines
; with the same string; the flat spelling with no loop declines earlier, at S9
; (`stale rail record read past a controlled Ry`).
; If this fixture ever reports `control flow inside a loop body` again, the S7
; skip has been lost; if it ACCEPTS, the premise bd 3paw's skip rests on is gone.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 noundef %0, i32 noundef %1, i32 noundef %2) {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %5 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 2.500000e-01)
  %6 = icmp eq i32 %4, 5
  %7 = select i1 %6, double 9.000000e-01, double 3.000000e-01
  %8 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef %7)
  %9 = icmp slt i32 %2, 0
  br i1 %9, label %10, label %12

10:
  %11 = tail call i32 @cq_measure_si32(i32 noundef %4)
  ret i32 %11

12:
  %13 = phi i32 [ %16, %12 ], [ 0, %3 ]
  %14 = phi i32 [ %15, %12 ], [ %5, %3 ]
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 1.000000e-01)
  %16 = add nuw i32 %13, 1
  %17 = icmp eq i32 %13, %2
  br i1 %17, label %10, label %12
}
