; control_inplace_ry_reject_stateprep_nomerge_ifelse_runtime_seed.ll — DECLINE
; (bd test_C_libtooling-fmt3 round 2, 2026-09-29; bd z0re composition, r1B F-r1B-2).
;
; THE C SOURCE — z0re's runtime-base angle select in its ORIGINAL if/else spelling
; (`slice_z0re_angle_select_runtime_base_exact.c` before fmt3 respelled it):
;
;     int q = m; cq_theta(&q, .5); int t = m + 1;
;     int r; if (q > 3) { r = t; cq_theta(&r, .75); } else { r = t; cq_theta(&r, .25); }
;     return cq_measure(r) + cq_measure(q);
;
; BEFORE fmt3, `-O1` sank the two calls into ONE `@cq_theta_si32(t, select(q > 3, .75,
; .25))`, and bd z0re (owner ruling 2026-09-28, option a) lowers that on ONE fresh
; rail by difference: `alloc(t); ry(h, .25); ry_controlled(f, h, .5)`. SINCE fmt3
; (`nomerge` on every `cq_theta_*`) this module — transcribed from `clang -O1` under
; the committed header — is what reaches the pass: an if/else of two RUNTIME-seed
; preps, which the two-rail clause refuses (PRD §14.11 Q4, owner ruling "two
; preps = two rails = decline"). The e2e slices were respelled as the TERNARY
; (`r = t; cq_theta(&r, (q > 3) ? .75 : .25)`), which is the one call with no merge
; and keeps their goldens byte for byte; this file pins what the if/else does now.
;
; ⚠ AN OVER-DECLINE, and a PRICED one (the owner's option-B cost statement): the
; circuit is realizable on ONE rail — it is exactly what the ternary compiles to.
; ⚠ RETIREMENT TRIGGER (L8): bd `gjn2` (teach the pass the unmerged if/else of
; rotations BY DIFFERENCE) or a revisit of Q4 changes this string. When that lands
; this module must ACCEPT with the ternary slice's stream —
; `alloc(t); ry(h,.25); flag(q>3); ry_controlled(f,h,.5); strip; free` — byte for
; byte against `slice_z0re_angle_select_runtime_base_exact.expected.log`. Re-derive
; it then; do not delete it. (Contrast `…_nomerge_noregion_pin.ll`: there the two
; LITERAL preps sit under a condition that pins a LIVE register, and that one must
; stay a decline.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; ⚠ A `DS_Error` decline writes ZERO bytes to stdout; the property is pinned by the
; `not` on the RUN line, not by any IR-text check.
; CHECK: error: {{.*}}cq controlled lowering: if/else state prep allocates two rails under quantum control

declare i32 @cq_theta_si32(i32, double) #0
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %m) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01) #1
  %t  = add nsw i32 %m, 1
  %c  = icmp sgt i32 %q, 3
  br i1 %c, label %armT, label %armF
armT:
  %rt = call i32 @cq_theta_si32(i32 %t, double 7.500000e-01) #1
  br label %merge
armF:
  %rf = call i32 @cq_theta_si32(i32 %t, double 2.500000e-01) #1
  br label %merge
merge:
  %r  = phi i32 [ %rt, %armT ], [ %rf, %armF ]
  %m0 = call i32 @cq_measure_si32(i32 %r)
  %m1 = call i32 @cq_measure_si32(i32 %q)
  %s  = add nsw i32 %m1, %m0
  ret i32 %s
}

attributes #0 = { nomerge }
attributes #1 = { nomerge nounwind }
