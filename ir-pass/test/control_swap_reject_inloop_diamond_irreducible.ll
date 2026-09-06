; control_swap_reject_inloop_diamond_irreducible.ll — DECLINE + BROKEN-MODULE
; REGRESSION GUARD (test_C_libtooling-d8jl, adversarial Rule-13 round 2). The
; IRREDUCIBLE-loop sibling of control_swap_reject_inloop_diamond_iterlocal.ll. A
; `goto` INTO a loop body makes clang -O1 emit an IRREDUCIBLE cyclic CFG — a
; cycle with TWO entry edges (`%entry` branches to BOTH `%head` and `%latch`), so
; no natural-loop header dominates the cycle and `LoopInfo`/`getLoopFor` reports
; NO loop. Real, verifier-clean clang -O1 output of:
;
;     int example(int x, double b, int n, int e) {
;         int acc = 0, i = 0;
;         if (e) goto MID;              // jump INTO the loop body -> irreducible
;         for (; i < n; i++) {
;             int q = cq_theta(x, 0.5);
;             if (q > 5) q = cq_phi(q, b);   // the in-body tainted diamond
;             acc += cq_measure(q);
;         MID:;
;         }
;         return acc;
;     }
;
; WHY THIS NEEDS ITS OWN GUARD: the first d8jl guard keyed on `LoopInfo`, which
; recognizes only NATURAL/reducible loops — so this diamond's enclosing cycle was
; INVISIBLE to it, the diamond was accepted + emitted, `RegionFlatten` erased the
; merge `%merge` (a backedge source feeding `%latch`/`%head`), and `opt` aborted
; `PHI node entries do not match predecessors! … Broken module` (SIGABRT). The
; shipped guard `regionEntryInLoop` is a reducibility-INDEPENDENT reachability
; walk (does the region-entry block reach itself?), so it catches the irreducible
; cycle and declines before any mutation. A regression to a `LoopInfo`-based test
; would crash `opt` here.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: control flow inside a loop body under quantum control
; NEW: cq controlled lowering: control flow inside a loop body under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control
; CHECK-NOT: Broken module
; CHECK-NOT: PHI node entries do not match predecessors
; CHECK-NOT: cqrt_cswap
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %x, double %b, i32 %n, i32 %e) {
entry:
  %c0 = icmp eq i32 %e, 0
  br i1 %c0, label %head, label %latch        ; TWO cycle entries -> irreducible
head:                                          ; preds = %entry, %latch
  %acc = phi i32 [ 0, %entry ], [ %accn, %latch ]
  %i   = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %lt  = icmp slt i32 %i, %n
  br i1 %lt, label %body, label %exit
body:                                          ; preds = %head
  %q = call i32 @cq_theta_si32(i32 %x, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5                      ; TAINTED (quantum) condition
  br i1 %c1, label %arm, label %merge
arm:                                           ; preds = %body
  call void @cq_phi(double %b)
  br label %merge
merge:                                         ; preds = %arm, %body
  %m = call i32 @cq_measure_si32(i32 %q)
  %sum = add nsw i32 %m, %acc
  br label %latch
latch:                                         ; preds = %entry, %merge
  %accn = phi i32 [ 0, %entry ], [ %sum, %merge ]
  %iin  = phi i32 [ 0, %entry ], [ %i, %merge ]
  %inext = add nsw i32 %iin, 1
  br label %head
exit:                                          ; preds = %head
  ret i32 %acc
}
