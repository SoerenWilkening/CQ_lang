; control_inplace_ry_reject_stateprep_sideways_sdiv.ll — DECLINE (F2-semantic:
; the pinned register is a SIBLING of the compare's operand, not a descendant).
;
; ⚠ THIS FIXTURE IS A ROUND-3 RULE-13 FINDING, NOT A DESIGN ROW (lens R3,
; F-R3-1, graded CONFIRMED-MISCOMPILE, 30 plain-C programs). It ACCEPTED after
; the round-2 fix, and the acceptance was a silent miscompile reachable from
; ordinary `clang -O1` C (`$S/review3/R3/p/s06_sdiv4_eq5.c`):
;
;     int q = cq_theta(3,0.3);
;     int t = q / 4;                    /* the rotated register — LIVE          */
;     int r = 5;
;     if (t == 5) r = cq_theta(t, 0.9); /* an IN-PLACE Ry on t                   */
;     return (int) cq_measure(r) + (int) cq_measure(t);
;
; MECHANISM, and it is NOT the round-2 one. Round 2 closed the DOWNWARD rewrite
; (compare moved onto an ANCESTOR of the pinned register, so a FORWARD walk from
; the compare's operand recovers it). InstCombine also rewrites the compare
; SIDEWAYS, onto a value that did not previously exist:
;
;     icmp eq (sdiv X, 4), 5   ->   icmp eq (and X, -4), 20
;
; `and %1,-4` and `sdiv %1,4` are two USERS OF THE SAME ROOT. No forward walk
; from the compare's operand can ever reach the rotated register, so the round-2
; SET was structurally blind to the whole division family: 20 hand-written
; programs plus 10 of a 140-program generated opcode sweep (`s_div_{2,3,4,5,7,
; 8,16}`, `u_div_{3,5,7}`), and `mul`/`shl`/`add`/`sub`/`xor`/`or`/`and`/`rem`/
; `lshr`/`ashr` all correctly declined — which is what isolates the direction as
; the cause rather than the opcode.
;
; Emitted at the round-2 HEAD (RUN, not read): `and_i32_hl(h0,-4) -> h1 ;
; icmp_eq_i32_hl(h1,20) -> h2 ; alloc_i32(5) -> h3 ;
; ry_i32_controlled(h2,h3,.9) ; …strip… ; free(h1) ; free(h2) ;
; sdiv_i32_hl(h0,4) -> h4 ; measure(h3) ; measure(h4)`. `h4` is the register the
; source measures as `t` and it receives NO rotation — two wires where the
; source has one. The control that closes it, byte-identical on BOTH binaries
; (`p/u06_uncond_sdiv4.c`): the same program with the guard removed emits
; `sdiv(h0,4) -> h1 ; ry_i32(h1,.9) ; measure(h1) ; measure(h1)`, i.e. CQ's own
; semantics for `cq_theta(t,θ)` is an IN-PLACE Ry on `t`'s rail.
;
; THE FENCE IS SEMANTIC, NOT A FOURTH SET. `LazyValueInfo` is asked, on both
; edges, about every tainted integer value LIVE ON THE EDGE — it reads the
; branch itself and recovers `%1 ∈ [20,24)` from `(Val & Mask) == C` through its
; own KnownBits idiom — and the forward abstract evaluation then computes
; `sdiv([20,24), {4}) = {5}` = the seed. Decline. See
; `f2SeedPinnedByLiveRegister`'s header in `ArmClassify.cpp` for the three
; syntactic generations this replaced and for what it still skips.
;
;
; ---- STILL A DECLINE AFTER THE 2026-09-11 NARROWING (bd `drbq.14`) ----
;
; F2 was narrowed on 2026-09-11 (owner ruling): a pinned value that lies on the
; CONDITION'S OWN BACKWARD WIRE — `CondWire` =
; `{Region.Condition} ∪ ⋃ railWireClosure(condProvenance(Region.Condition))` — is
; no longer a collider, and NINETEEN fixtures of this family flipped to ACCEPT
; (they are now `control_inplace_ry_stateprep_*`). **THIS ONE DID NOT, and the
; reason is not an accident:**
;
; `-O1` moved the compare SIDEWAYS onto a SIBLING (the compare became `and %q, -4`), so the
; pinned value is neither an ancestor nor a descendant of anything the
; compare names — it is out of `CondWire` twice over, and no direction of
; walk from the condition could reach it.
;
; So the narrowing is the WIRE and nothing wider, and this file is one of the 21
; that prove it. Measured 2026-09-11 on the narrowed binary: rc=1, same string,
; same anchor.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %m = and i32 %q, -4
  %c = icmp eq i32 %m, 20
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %t  = sdiv i32 %q, 7
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}
