; control_swap_reject_post_region_theta_sharecond.ll — DECLINE: precondition P2
; of the Inc-4 position-aware accept (bd test_C_libtooling-lom0). A
; `ShareCondFlag` region keeps the POSITION-FREE reading.
;
; The condition is ALSO read as data (`int f = (q > 5); … measure(f)`), so
; `classifyArms` takes the ziov WI-1 share path and sets `Region.ShareCondFlag`.
; On that path the phase emitter deliberately SKIPS the `_unc` flag strip and the
; `cqrt_free`, because the data lineage owns the flag downstream. MEASURE THAT, do
; not take it on trust: delete the `cq_theta` below and the emitted stream is
;     cq_template_icmp_sgt_i32_hl -> %h_cmp ; cqrt_rz_i1(%h_cmp) ;
;     cq_template_zext_i1_to_i32(%h_cmp) ; measure ; measure
; with NO `..._hl_unc` and NO `cqrt_free(%h_cmp)` anywhere (re-measured 2026-10-05).
;
; SO THE FLAG IS A LIVE, ENTANGLED RECORD OF THE WIRE past the region, and a
; later in-place Ry on that wire dephases exactly the superposition the region
; put there. The Inc-4 accept's whole claim is "once the strip has run, the
; region holds no live record" — on the share path the strip never runs, so the
; claim is false by construction and `condWireDisposition` returns `DeclineNow`
; before it ever asks the dominator tree.
;
; MEASURED IDENTICAL at HEAD (b4e329b) and in this tree:
;     cq controlled lowering: condition predates a non-diagonal gate
; This is the fixture bd lom0's ownership probe said had no accept twin; it now
; has a decline twin instead, which is the safe half.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5              ; the control flag AND a data value
  br i1 %c, label %arm, label %merge

arm:
  call void @cq_phi(double %a)
  br label %merge

merge:
  %fz = zext i1 %c to i32              ; the DATA use — ziov share path
  %mf = call i32 @cq_measure_si32(i32 %fz)
  %w  = call i32 @cq_theta_si32(i32 %q, double 2.500000e-01)  ; POST-region Ry
  %m  = call i32 @cq_measure_si32(i32 %w)
  %r  = add nsw i32 %m, %mf
  ret i32 %r
}

; CHECK: error{{.*}}cq controlled lowering: condition predates a non-diagonal gate under quantum control
