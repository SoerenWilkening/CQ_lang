; control_phase_nest_reject_block_order.ll — DECLINE. A depth-2 register-free
; phase nest whose `Mid` block appears BEFORE its `Pred` in the function's block
; list.
;
; ⚠ THIS FIXTURE PINS AN ORDERING ASSUMPTION THAT PRE-DATES THIS INCREMENT, and
; it is here so the assumption is a TEST rather than a comment.
; `detectControlRegions` walks blocks in list order and dispatches each
; terminator as it goes, so an accepted nest's INNER `br` is skipped only because
; the OUTER one was already visited and put it in `Claimed` (the FA0 blocker —
; the inner branch recovers FLAT in isolation, its merge has no φ, and it would
; false-decline). The 4.3 nest documented that as "`-O1` visits the outer Pred
; before the inner Mid, so the outer's claim lands first"; the register-free nest
; inherits it verbatim, and so does the `ClaimedSelects` hand-off that keeps a
; compound level's logical `select i1` out of the tainted-select scan.
;
; WHEN THE ASSUMPTION FAILS THE OUTCOME IS A LOUD DECLINE, MEASURED, NOT A
; MISCOMPILE — the inner `br` is visited first, recovers `OffPattern` on its own,
; and fires `control flow` — `opt` exits non-zero before any output is written.
; Verified clean under `DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib` (no
; use-after-free from the region that IS accepted a moment later), and no module
; is emitted at all.
;
; The fix, if this ever becomes reachable from a real frontend, is to dispatch
; terminators in reverse post-order rather than list order — NOT to widen any
; classifier. Nothing `clang -O1` produces has this layout.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

; Mid appears BEFORE Pred in the function's block list.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %pred
mid:
  call void @cq_phi(double 2.500000e-01)
  %ca = icmp slt i32 %q, 9
  %cb = icmp eq i32 %r, 3
  %c2 = select i1 %ca, i1 %cb, i1 false
  br i1 %c2, label %inner, label %merge
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
pred:
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m, %n
  ret i32 %s
}

; CHECK: cq controlled lowering: control flow under quantum control
