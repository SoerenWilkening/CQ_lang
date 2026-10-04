; control_inplace_ry_reject_stateprep_nomerge_nested_pin.ll — DECLINE
; (bd test_C_libtooling-fmt3, owner ruling 2026-09-28, option B).
;
; THE C SOURCE (fmt3's exhibit `a6.c`, review r1A of bd z0re, F-r1A-2):
;
;     int t = q / 4; int q2 = 7; cq_theta(&q2, .4); int r = 5;
;     if (q2 > 3) { if (t == 5) { r = t; cq_theta(&r, .9); } else { r = 5; cq_theta(&r, .9); } }
;     return cq_measure(r) + cq_measure(t) + cq_measure(q2);
;
; BEFORE fmt3, `-O1` MERGED the two inner calls (IPSCCP pins `t := 5` on the
; inner edge, so both became `@cq_theta_si32(5, .9)`; the late SimplifyCFG hoisted the
; pair and DELETED the inner branch). The pass then saw exactly the stage-1 IR of
; the legitimate `if (q2 > 3) { r = 5; cq_theta(&r, .9); }` and ACCEPTED at exit 0,
; STRICT 2b clean, preparing a fresh |5> while the source rotated `t` in place —
; `t` measured unrotated. No IR predicate can tell the two apart.
;
; SINCE fmt3 every `cq_theta_*` in CQ.h carries `nomerge`, and this module IS what
; `clang -O1` now produces for that source (transcribed from
; `fmt3_probes/out/a6.nomerge.s1.ll`; the C-level half — "the inner branch and
; both calls survive" — is pinned by `tests/frontend/cq_theta_nomerge.c`). The
; pin still happens (both inner calls read the literal 5); what changed is that
; the branch survives, so the pass sees the nest and refuses it.
;
; ⚠ THE STRING IS `nested control flow`, NOT F2's. The flat twin `a6f.c` declines
; at F2 (`state prep seed is proven equal to the condition register`); this one
; never reaches F2 because nesting declines first. Both are declines of the same
; hazard; the verdict is what the TWIN says, the string is whichever fence speaks
; first.
;
; ⚠ RETIREMENT TRIGGER (L8): the day a nested region lowers, this string changes.
; The inner if/else is then two literal-5 preps under one condition and must
; decline `if/else state prep allocates two rails` (the no-region sibling
; `..._nomerge_noregion_pin.ll` pins that fence on the same inner shape). Re-derive
; the verdict then; do not delete this file, and do not let it become an ACCEPT
; that prepares a fresh |5> — that is the fmt3 miscompile.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout; the property is pinned by the
; `not` on the RUN line, not by any IR-text check.
; CHECK: error: {{.*}}cq controlled lowering: nested control flow under quantum control

declare i32 @cq_theta_si32(i32, double) #0
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01) #1
  %q2 = call i32 @cq_theta_si32(i32 7, double 4.000000e-01) #1
  %c  = icmp sgt i32 %q2, 3
  br i1 %c, label %inner, label %merge
inner:
  %o  = and i32 %q, -4
  %ci = icmp eq i32 %o, 20
  br i1 %ci, label %armT, label %armF
armT:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01) #1
  br label %merge
armF:
  %rf = call i32 @cq_theta_si32(i32 5, double 9.000000e-01) #1
  br label %merge
merge:
  %r  = phi i32 [ %rt, %armT ], [ %rf, %armF ], [ 5, %entry ]
  %t  = sdiv i32 %q, 4
  %m0 = call i32 @cq_measure_si32(i32 %r)
  %m1 = call i32 @cq_measure_si32(i32 %t)
  %s0 = add nsw i32 %m1, %m0
  %m2 = call i32 @cq_measure_si32(i32 %q2)
  %s1 = add nsw i32 %s0, %m2
  ret i32 %s1
}

attributes #0 = { nomerge }
attributes #1 = { nomerge nounwind }
