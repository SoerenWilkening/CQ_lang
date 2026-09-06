; control_swap_reject_cond_datause_main_dead.ll — DECLINE probe (ziov WI-1,
; Rule-13 adversarial finding B): a DEAD-within-function condition-data-use in
; `main` declines IDENTICALLY to the non-main case — there is NO `main`-name
; short-circuit in the share/strip disposition.
;
; `condDataUseDisposition` must NOT treat `main`-residence as "owned": process
; exit reclaiming the registers (FreePoint's `main` rule) answers the FREE
; question, but it does NOT make a dead, never-measured, never-escaped flag safe
; to leave ENTANGLED with q un-stripped (Rule 6/8 dirty-rail dephasing). The data
; lineage `%d = zext %c; %dead = add %d, 7` is orphaned, so this is the SAME
; hazard as control_swap_reject_cond_datause_dead.ll (a non-main `@example`) and
; takes the SAME loud decline. (An earlier `main`-name short-circuit silently
; accepted this; that was the WI-1 silent-miscompile-class regression.)
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: condition data use neither escaped nor measured under quantum control
; NEW: cq controlled lowering: condition data use neither escaped nor measured under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: condition data use neither escaped nor measured under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %d = zext i1 %c to i32
  %dead = add i32 %d, 7            ; DEAD: never measured, returned, or inverted
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 2.500000e-01)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
