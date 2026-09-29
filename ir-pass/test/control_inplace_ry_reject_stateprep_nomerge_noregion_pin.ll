; control_inplace_ry_reject_stateprep_nomerge_noregion_pin.ll — DECLINE
; (bd test_C_libtooling-fmt3, owner ruling 2026-09-28, option B).
;
; THE C SOURCE (`fmt3_probes/src/n9.c`) — fmt3's class with NO enclosing region:
;
;     int t = q / 4; int r;
;     if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9);
;     return cq_measure(r) + cq_measure(t);
;
; BEFORE fmt3 the merge left an UNCONDITIONAL `r = cq_theta(5, .9)` — no tainted
; control flow reached the pass at all, so NO fence was ever asked, and the oracle
; compiled a fresh |5> prep with `t` measured unrotated (7 trace lines, exit 0).
; That member is why option (A), a coarse fence at F2, could not close the class:
; there was no region to put a fence on.
;
; SINCE fmt3 (`nomerge` on every `cq_theta_*`) this is what `clang -O1` produces
; (transcribed from `fmt3_probes/out/n9.nomerge.s1.ll`): the compare was moved
; SIDEWAYS onto `q` by InstCombine and `t` was pinned in the true arm, so the two
; arms are identical literal-5 preps — and an if/else of two preps under one
; condition is refused (drbq.13 Q4, owner ruling "two rails = decline").
;
; ⚠ RETIREMENT TRIGGER (L8; Rule-13 r1A F-r1A-6). This file declines ONLY because
; the two-rail clause speaks first. The day that clause lifts — drbq.13 Q4 is an
; owner ruling that can be revisited, and bd `gjn2` works right next to it — this
; module is two IDENTICAL literal-5 preps under `(q & -4) == 20`, which a
; one-rail if/else prep lowering would happily emit as `alloc(5); Ry(.9)` on both
; edges: the fmt3 miscompile again (`t` measured unrotated). It must still
; DECLINE, and the reason it must is that the TRUE edge pins the LIVE register
; `%t` (= `sdiv %q, 4`, defined after the region and measured) to the seed 5 — so
; whatever replaces the two-rail clause must ask F2's question on EACH ARM'S edge
; (the arm-edge pin, not only the region edge). Re-derive the verdict then; do not
; delete this file, and never let it become an ACCEPT that prepares a fresh |5>.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout; the property is pinned by the
; `not` on the RUN line, not by any IR-text check.
; CHECK: error: {{.*}}cq controlled lowering: if/else state prep allocates two rails under quantum control

declare i32 @cq_theta_si32(i32, double) #0
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01) #1
  %o  = and i32 %q, -4
  %c  = icmp eq i32 %o, 20
  br i1 %c, label %armT, label %armF
armT:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01) #1
  br label %merge
armF:
  %rf = call i32 @cq_theta_si32(i32 5, double 9.000000e-01) #1
  br label %merge
merge:
  %r  = phi i32 [ %rt, %armT ], [ %rf, %armF ]
  %t  = sdiv i32 %q, 4
  %m0 = call i32 @cq_measure_si32(i32 %r)
  %m1 = call i32 @cq_measure_si32(i32 %t)
  %s0 = add nsw i32 %m1, %m0
  ret i32 %s0
}

attributes #0 = { nomerge }
attributes #1 = { nomerge nounwind }
