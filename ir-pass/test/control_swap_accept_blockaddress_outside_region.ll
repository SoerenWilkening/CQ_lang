; control_swap_accept_blockaddress_outside_region.ll — ACCEPT (bd 7udx).
; ARM: `declineAddressTakenBlocks`'s SCOPE. The required accept control for the
; bd 7udx guard, and the reason that guard is region-scoped instead of
; function-scoped.
;
; The `blockaddress` here names `%tail`, which is OUTSIDE the claimed region: the
; region is `entry` + `arm`, `%merge` is the post-dominator the flatten branches
; TO, and `%tail` is downstream of it. Nothing erases `%tail`, so no
; `BlockAddress` is destroyed, so no `RAUW`-to-`inttoptr (i32 1 to ptr)` happens —
; and the compared-against address must survive VERBATIM into both the forward
; gate and its `_unc` adjoint.
;
; WITHOUT THIS FIXTURE the guard could quietly be re-spelled as "decline any
; function containing an address-taken block", which would over-decline every
; function containing a computed `goto` — and, because the measured population of
; `blockaddress` across 966 fixtures + 257 e2e modules + 251 openlibm modules is
; ZERO, no corpus measurement and no golden would ever notice. That is exactly the
; failure mode bd 7udx's own Rule-12 note asks for a control against.
;
; The pinned CHECKs below also witness the bd bu96 doctrine live: the SAME uniqued
; `ptrtoint (ptr blockaddress ...)` `ConstantExpr` appears in the forward compare
; and in its adjoint, and that is FINE — a `Constant` becomes ONE link-time
; relocation, so both reads get the same value and the pairing is intact. Contrast
; a literal `undef`/`poison`, which `IMPLICIT_DEF` materialises PER USE; that is
; the bd xy9n guard's business and is declined by
; lowering_reject_undef_literal_paired_dead_chain.ll. The two guards live in one
; TU and must not be conflated: one is about ERASURE, the other about PAIRING.
;
; THIS IS A CONTROL: green on both the pre-change and post-change plugins, by
; design, so it does not appear in the differential. Its discriminating power is
; arm-kill — widen `declineAddressTakenBlocks` from the doomed-block set to the
; whole function and this fixture goes red.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; The region still flattens (no `br i1` / `select i1` survives) …
; RUN: %filecheck %s --check-prefix=FLAT  --implicit-check-not='br i1' --implicit-check-not='select i1' < %t.cqd0.ll
; FLAT: define i32 @probe
;
; … and the address is intact in BOTH the forward gate and the adjoint — never
; the `i32 1` placeholder:
; CHECK: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 ptrtoint (ptr blockaddress(@probe, %tail) to i32))
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %h, i32 ptrtoint (ptr blockaddress(@probe, %tail) to i32))
; CHECK: store ptr blockaddress(@probe, %tail), ptr @slot
;
; A `*-NOT`-only prefix so it scans the WHOLE input rather than only from the last
; CHECK match to EOF: the corrupted form must appear nowhere at all.
; RUN: %filecheck %s --check-prefix=NOCORRUPT < %t.cqd0.ll
; NOCORRUPT-NOT: cq_template_icmp_sgt_i32_hl(i32 %h, i32 1)
; NOCORRUPT-NOT: store ptr inttoptr

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i32 @llvm.ctlz.i32(i32, i1 immarg)

@slot = global ptr null

define i32 @probe(i32 %u, i32 %c) {
entry:
  %seed = add nsw nuw i32 %u, 1
  %q = call i32 @cq_theta_si32(i32 %seed, double 5.000000e-01)
  %a = icmp sgt i32 %q, ptrtoint (ptr blockaddress(@probe, %tail) to i32)
  %r = call i32 @llvm.ctlz.i32(i32 %q, i1 false)
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  br label %tail

tail:
  store ptr blockaddress(@probe, %tail), ptr @slot, align 8
  ret i32 %m2
}
