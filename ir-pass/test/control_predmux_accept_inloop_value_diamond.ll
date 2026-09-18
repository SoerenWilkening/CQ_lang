; control_predmux_accept_inloop_value_diamond.ll — ACCEPT (bd
; test_C_libtooling-fn1q increment 3): a tainted-condition VALUE diamond lying
; STRICTLY INSIDE a bounded loop body. Before this increment E2 refused every
; region with a block on any CFG cycle, so this declined `control flow under
; quantum control` while the `select` spelling of the same program compiled.
;
; THE CLEARANCE IS INHERITED, MECHANICALLY. The `diff` RUN lines below assert
; that this module and control_predmux_accept_inloop_value_diamond_twin.ll emit
; the SAME GATE STREAM, byte for byte — 24 calls. The twin is the `select`
; spelling, which accepts on the PRE-INCREMENT ORACLE and reaches the 4.4
; `SelectMergeEmit` merge and bd `zujr`'s loop-carried-handle promotion without
; PredMux being consulted at all. So what this increment does is put a `br`
; spelling onto a path the compiler was ALREADY lowering, in a loop — the axis
; is `br` vs `select` and `-O1` picks it (bd memory
; [`value-arm-br-vs-select-axis-2026-09-22`]).
;
; What is compared is every emitted `cqrt_*` / `cq_template_*` CALL, not the
; whole module: the two modules' residual CLASSICAL instructions differ (the
; `br` form leaves the flattened region's predicates behind), and that is
; expected. `test -s` guards the comparison itself — a `diff` of nothing
; against nothing is the cheapest false green there is (increment 2's Rule-13
; round 1 found exactly that shape).
;
; ⚠ BOTH SIDES OF THE `diff` RUN UNDER THE SUBJECT BINARY. That the ORACLE
; accepts the twin is a claim about the ORACLE and is recorded in the twin's
; own header; it is not something a lit RUN line can assert.
;
; ⚠ THE LOOP MUST STAY ROLLED. The count directive and the whole-file negative
; below are what says so: exactly two controlled-copy merges are emitted (one
; per carried value, ONE trip's worth), not six. If the flatten ever let the
; loop be unrolled, or emitted a per-trip copy, both would move.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %S/control_predmux_accept_inloop_value_diamond_twin.ll > %t.twin.ll
; RUN: grep -oE "call (void|i32|i1) @(cqrt|cq_template)_[a-z0-9_]*\([^)]*\)" %t.cqd0.ll > %t.a.gates
; RUN: grep -oE "call (void|i32|i1) @(cqrt|cq_template)_[a-z0-9_]*\([^)]*\)" %t.twin.ll > %t.b.gates
; RUN: diff %t.a.gates %t.b.gates
; RUN: test -s %t.a.gates
; RUN: %filecheck %s --check-prefix=ROLLED < %t.cqd0.ll
; RUN: grep "call void @cqrt_copy_i32_controlled" %t.cqd0.ll | count 4
; RUN: grep "call i32 @cq_template_icmp_sle_i32_hl(" %t.cqd0.ll | count 2
; RUN: grep "call i32 @cqrt_alloc_i32(i32 0)" %t.cqd0.ll | count 2
; RUN: grep "call void @cqrt_free(" %t.cqd0.ll | count 2
; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll
;
; The back edge survives: the region is flattened, the LOOP is not.
; ROLLED: br i1 %{{.*}}, label %exit, label %head
; ROLLED-NOT: br i1 %{{.*}}, label %arm
;
; THE COUNTS ARE CLOSED BY `grep -c | count`, NOT BY A FILECHECK COUNT
; DIRECTIVE, and that is deliberate. A count directive matches SEQUENTIALLY from
; wherever the previous directive left off, so a following negative closes only
; the RANGE after it, not the file — which is increment 2's Rule-13 round 1
; finding verbatim (an injected ninth controlled copy was missed by all four
; prefixes). `grep -c` counts the whole file and `count N` fails on N+1 as
; loudly as on N-1, so an injected FIFTH copy or a deleted fourth both fail.
; Measured at the increment: 4 controlled copies (two merges x two arms), 2 flag
; mints, 2 fresh `|0>` merge rails, 2 frees.
;
; The remaining negatives are a PURE whole-file prefix with no positives in it.
; NEG-NOT: cqrt_rz
; NEG-NOT: cqrt_cswap
; NEG-NOT: cqrt_toffoli
; The arm block is erased by the flatten, so its label is gone from the module.
; NEG-NOT: label %arm
;
; ⚠ WHAT PINS "IT ACCEPTED" IS THE FIRST RUN LINE'S EXIT CODE, NOT A NEGATIVE.
; An earlier version of this header ended with `CHECK-NOT` lines for the strings
; `cq controlled lowering` and `cq loop lowering` and claimed they proved "no
; tainted `br` is left for ControlDetect". They prove nothing: a diagnostic goes
; to STDERR and these prefixes read the emitted MODULE, so the strings can never
; appear there and the checks can never fail (measured: `grep -c` on the lowered
; module = 0). Removed rather than re-aimed — CLAUDE.md Rule 12 (b), a decline
; writes 0 bytes to stdout and IR-text negatives against it are vacuous. This
; file is a `%cq-opt` run with NO `not`, so a decline fails the RUN line itself.
; And the flatten really happened — no tainted `br` is left for ControlDetect.
; CHECK-NOT: cq controlled lowering
; CHECK-NOT: cq loop lowering

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %in, %latch ]
  %a = phi i32 [ 5, %entry ], [ %an, %latch ]
  %b = phi i32 [ 6, %entry ], [ %bn, %latch ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %latch
arm:
  %a1 = add i32 %a, -3
  %b1 = add i32 %b, -4
  br label %latch
latch:
  %an = phi i32 [ %a, %head ], [ %a1, %arm ]
  %bn = phi i32 [ %b, %head ], [ %b1, %arm ]
  %in = add i32 %i, 1
  %d = icmp eq i32 %in, 3
  br i1 %d, label %exit, label %head
exit:
  %m1 = call i32 @cq_measure_si32(i32 %an)
  %m2 = call i32 @cq_measure_si32(i32 %bn)
  %s = add i32 %m1, %m2
  ret i32 %s
}
