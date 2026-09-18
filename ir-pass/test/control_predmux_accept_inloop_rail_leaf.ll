; control_predmux_accept_inloop_rail_leaf.ll — ACCEPT. ⚠ THE INCREMENT-2 x
; INCREMENT-3 COMPOSITION, and it is here because a composition is not cleared by
; clearing its parts — a filing CLAUDE.md records as having been made in five
; consecutive sessions. Found by bd fn1q increment 3's Rule-13 round 1 (F-8),
; which measured the new accept surface as about ten shapes wide where the
; increment's own record named four.
;
; WHAT COMPOSES. The region's condition is a BARE `_Bool` RAIL — a `cq_theta_i1`
; CALL read directly as `br i1 %b` — which is increment 2's E6 leaf; and the
; region lies STRICTLY INSIDE a bounded loop, which is increment 3's E2
; admission. Neither increment alone lowers this: on the pre-increment ORACLE it
; declines `cq controlled lowering: control flow under quantum control`.
;
; ⚠ THE RAIL IS MINTED OUTSIDE THE LOOP AND READ AS THE BODY'S CONDITION EVERY
; TRIP, then measured after it. `%b` is read ONLY as a control — never
; `cqrt_x`-bracketed on the user's own register, never freed — and the two merges
; each mint a fresh `|0>` rail. That is the Rule-7 invariant for a rail root, and
; the count directives below are what would catch an injected rotation on `%b`.
;
; THE CLEARANCE IS INHERITED, MECHANICALLY: the `diff` asserts this module and
; control_predmux_accept_inloop_rail_leaf_twin.ll emit the SAME 27 calls, and the
; twin accepts on the ORACLE. `test -s` guards the comparison itself.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %S/control_predmux_accept_inloop_rail_leaf_twin.ll > %t.twin.ll
; RUN: grep -oE "call (void|i1|i32) @(cqrt|cq_template)_[a-z0-9_]*\([^)]*\)" %t.cqd0.ll > %t.a.gates
; RUN: grep -oE "call (void|i1|i32) @(cqrt|cq_template)_[a-z0-9_]*\([^)]*\)" %t.twin.ll > %t.b.gates
; RUN: diff %t.a.gates %t.b.gates
; RUN: test -s %t.a.gates
; RUN: grep -c "" %t.a.gates | %filecheck %s --check-prefix=NCALLS
; RUN: grep "call void @cqrt_copy_i32_controlled" %t.cqd0.ll | count 4
; RUN: grep "call void @cqrt_ry_i1(" %t.cqd0.ll | count 1
; RUN: grep "call void @cqrt_cnot(" %t.cqd0.ll | count 4
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; NCALLS: 27
;
; The loop is still ROLLED: the region is flattened, the loop is not.
; CHECK: br i1 %{{.*}}, label %exit, label %head
;
; EXACTLY ONE `cqrt_ry_i1` — the user's own mint, outside the loop. If the rail
; were ever re-rotated, or rotated per trip, that count moves. The rail is read
; only as a control, so the X brackets are on the two merge ANCILLAS (via the
; CNOT-copy root idiom), never on %b.
; NEG-NOT: cqrt_rz
; NEG-NOT: cqrt_cswap
; NEG-NOT: cqrt_toffoli
; NEG-NOT: label %arm
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
define i32 @probe() {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %latch ]
  %x = phi i32 [ 5, %entry ], [ %a4, %latch ]
  %y = phi i32 [ 6, %entry ], [ %b5, %latch ]
  br i1 %b, label %arm, label %merge
arm:
  %x1 = add i32 %x, -3
  %y1 = add i32 %y, -4
  br label %merge
merge:
  %a4 = phi i32 [ %x1, %arm ], [ %x, %head ]
  %b5 = phi i32 [ %y1, %arm ], [ %y, %head ]
  br label %latch
latch:
  %in = add i32 %i, 1
  %d = icmp eq i32 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z = zext i1 %mb to i32
  %s1 = add i32 %m1, %m2
  %s = add i32 %s1, %z
  ret i32 %s
}
