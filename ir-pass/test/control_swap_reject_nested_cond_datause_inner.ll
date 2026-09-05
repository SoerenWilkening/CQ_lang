; control_swap_reject_nested_cond_datause_inner.ll — DECLINE probe (ziov.3): a
; depth-2 phase nest whose INNER condition is ALSO read as DATA.
;
; `if (q>5) { q=rz(q,b); int f=(q<9); if (q<9) { q=rz(q,a); measure(f); } }` — the
; inner compare `%c2 = icmp slt %g, 9` feeds the inner `br` (control) AND a `zext`
; (`%d`, in `mid`) that is MEASURED in `arm` (`%dm`). The data lineage is dominated
; by `mid` (valid IR — the data use canNOT live in `merge`, which `entry` reaches
; directly), and the measure is downstream of the inner route block (`Mid`), so the
; disposition is ShareOk — the flat path's shared-flag accept.
;
; An inner-condition data use is INHERENTLY also a homogeneity stray (it must live
; in `mid`/`arm` — the only blocks `mid` dominates; `merge` is reached straight from
; `entry`), so the existing `midIsPurePhase`/`innerArmIsPureSpine` whole-block scan
; (criterion 6) would also decline it — but as the generic `impure phase arm`.
; ziov.3 applies the disposition predicate to the INNER condition BEFORE criterion
; 6 (keyed on the inner route block, `Mid`), so the PRECISE cond-data-use string
; fires instead. This is the correct diagnosis (the inner compare is reused as data,
; not an unrelated stray) AND defense-in-depth: when value-arm nests later relax the
; all-phase purity scan, this check still declines the shape before NestedRouteEmit
; would dangle a live use of the Mid gate the flatten erases. The escaped/measured
; lineage is the flat path's ShareOk; the nested path declines it ("condition used
; outside the branch") because nested flag-SHARING is a later WI.
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: condition used outside the branch under quantum control
; NEW: cq controlled lowering: control flow under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  %d  = zext i1 %c2 to i32          ; DATA use of the INNER condition (in mid)
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  %dm = call i32 @cq_measure_si32(i32 %d)   ; the data lineage is MEASURED (owned)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
