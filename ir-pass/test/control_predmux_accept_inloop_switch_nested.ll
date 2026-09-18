; control_predmux_accept_inloop_switch_nested.ll — ACCEPT (bd fn1q increment 3,
; Rule-13 round 2 R2-6). A tainted `switch` inside a loop body, whose default arm
; hosts FURTHER tainted control.
;
; ⚠ IT IS HERE BECAUSE THE INCREMENT'S OWN RECORD SAID THIS SHAPE WAS UNCHANGED.
; That record's §6 read: "tainted `switch` inside a loop | IDENTICAL on both
; binaries — the W witness refuses before E2". True of the probe it was measured
; on, and false as a general claim: a switch whose arm carries nested tainted
; control fires the `NestedTainted` witness, so W does NOT refuse, and E2 is then
; the gate that used to. Measured: ORACLE declines `control flow inside a loop
; body under quantum control`; SUBJECT exits 0.
;
; WHY IT IS THE RIGHT CIRCUIT: the emitted select chain is the 4-way mux, the
; loop-free twin of this shape already accepts on the ORACLE, and stage 2b is
; STRICT-clean. The standing trailing-gate probe (a `cq_theta` on the scrutinee's
; own register after the loop) declines at `condition predates a non-diagonal
; gate` on BOTH binaries, so this widening does not open that door.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; The loop is still ROLLED — the region is flattened, the loop is not.
; CHECK: br i1
; NEG-NOT: switch i32
; NEG-NOT: cqrt_rz
; NEG-NOT: cqrt_cswap
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %latch ]
  %a = phi i32 [ 5, %entry ], [ %an, %latch ]
  switch i32 %q, label %c0 [ i32 1, label %c1
                             i32 2, label %c2 ]
c0:
  %t = icmp sgt i32 %q, 7
  br i1 %t, label %c0a, label %c0b
c0a:
  %a0a = add i32 %a, 11
  br label %latch
c0b:
  %a0b = add i32 %a, 12
  br label %latch
c1:
  %a1 = add i32 %a, -3
  br label %latch
c2:
  %a2 = add i32 %a, -4
  br label %latch
latch:
  %an = phi i32 [ %a0a, %c0a ], [ %a0b, %c0b ], [ %a1, %c1 ], [ %a2, %c2 ]
  %in = add i32 %i, 1
  %d = icmp eq i32 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m1 = call i32 @cq_measure_si32(i32 %an)
  ret i32 %m1
}
