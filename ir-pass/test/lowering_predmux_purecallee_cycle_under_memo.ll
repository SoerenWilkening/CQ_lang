; lowering_predmux_purecallee_cycle_under_memo.ll — bd ziuw, the CYCLE dimension.
;
; The ziuw worklist rewrite re-spelled two things the recursion used to get from
; the C++ stack: the `OnStack` cycle test (now the third clause of `enter`, whose
; FALSE is deliberately NOT memoised) and the memo write (now `leave`, reached
; only where the old body walk `return`ed). Nothing in the tree pinned their
; INTERACTION.
;
; *** THE GAP, MEASURED (the Rule-13 round's lens 2), AND STATED AS OF BEFORE
; THIS FILE LANDED — a census written in the present tense is invalidated by its
; own commit. *** A reach census of the committed fixtures with
; `CQ_PREDMUX_COUNT=1`, using the exact identity
; `Invocations = Bodies + Hits + CycleReturns`: BEFORE this file, of the 89
; fixtures that reach this walk, EXACTLY ONE exercised an OnStack cycle return
; (`lowering_predmux_leave_speccall_recursive.ll`: `inv=2 bodies=1 hits=0` — a
; callee that calls itself, at depth 1, with no memo entries live) and exactly
; three roots had any memo hits. So the combination the rewrite most plausibly
; breaks — a cycle discovered BELOW a node already memoised TRUE, unwinding
; through several frames — was pinned by nothing. WITH this file the tree reads
; 91 fixtures / 98 (fixture,root) pairs / 5 roots at `bodies>=2` / 4 with hits /
; 2 with cycle returns.
;
; WHAT THIS FILE COMPOSES, in one 5-invocation query:
;   @f0 calls @fs (clean, walked, memoised TRUE) then @fa
;   @fa calls @fs  -> MEMO HIT, served TRUE from inside the cyclic subtree
;        then @fa   -> ONSTACK HIT, FALSE, and NOT memoised
;   the FALSE then unwinds @fa -> @f0 -> the root, ending the query
; It therefore pins, at once: (i) the OnStack FALSE is not written to the memo,
; (ii) a TRUE entry written before the cycle is still served after it, (iii) the
; unwind reaches the root and produces the ordinary loud decline rather than a
; crash or a wrong accept, and (iv) the cascade ORDER of the DBG stream.
;
; NOT A BUG PIN — a REGRESSION pin. Measured byte-identical (stdout, stderr and
; exit code, both debug streams on) through a `cq-opt` built from the pre-change
; commit 72da1f2 and through the current one.
;
; THE COUNTERS READ OFF THE STRUCTURE: 5 invocations (root f0; f0->fs, f0->fa;
; fa->fs, fa->fa), 3 bodies walked (f0, fs, fa), 1 memo hit (the second @fs).
; The fifth invocation is the cycle return, which is why bodies+hits is 4 and not
; 5 — that difference IS the cycle, and it is why the identity above can count
; cycle returns without a dedicated counter.
;
; ONE spawn: the pass is SPAWN-bound, not work-bound (CLAUDE.md), and this file
; asserts only on the merged diagnostic stream, so a second `%cq-opt` writing a
; lowered module nobody FileChecks would be pure cost.
; RUN: env CQ_PREDMUX_COUNT=1 CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin \
; RUN:   %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \
; RUN:   | %filecheck %s --check-prefix=DBG

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @fs(i32 %a) #0 {
  %r = add i32 %a, 3
  ret i32 %r
}

define i32 @fa(i32 %a) #0 {
  %h = call i32 @fs(i32 %a)       ; memo HIT (TRUE), inside the cyclic subtree
  %c = call i32 @fa(i32 %h)       ; OnStack HIT: cycle, FALSE, NOT memoised
  ret i32 %c
}

define i32 @f0(i32 %a) #0 {
  %s = call i32 @fs(i32 %a)       ; walked, memoised TRUE
  %t = call i32 @fa(i32 %s)
  ret i32 %t
}

define void @example(i32 %u0, i32 %arg) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 2.500000e-01)
  %cnd = icmp sgt i32 %q, 3
  br i1 %cnd, label %arm, label %merge
arm:
  %r = call i32 @f0(i32 %arg)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret void
}
attributes #0 = { nounwind willreturn memory(none) }

; THE UNWIND, IN ORDER: the cycle is reported by @fa's frame, then by its caller,
; and the root produces the ordinary loud decline. (`--check-prefix=DBG` reads the
; merged stream, so the diagnostic really is in scope here — a CHECK on stdout
; alone would be vacuous after a DS_Error.)
; DBG:      CQ_PREDMUX_DBG: pure-callee fa fails at call:{{.*}}@fa
; DBG-NEXT: CQ_PREDMUX_DBG: pure-callee f0 fails at call:{{.*}}@fa
; DBG:      CQ_PREDMUX_COUNT: pure-callee mode=strict root=f0 verdict=0 invocations=5 bodies=3 hits=1
; DBG:      error: {{.*}}cq controlled lowering: control flow under quantum control
