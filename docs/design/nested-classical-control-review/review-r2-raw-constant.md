# R2 analytic follow-up: raw speculative constants

No new blocker found in the narrow correction. Source operand normalization
catches the constant before its quantum consumer disappears. One entry freeze
dominates moved consumers, the typed Constant/function cache shares it locally,
and replacing the selected operand Use cannot rewrite another function.
Correlating undef uses to one fixed choice is a refinement; defined selected-arm
values retain their source value.

This does not establish a shared freeze choice across separate clone/twin
invocations. The existing ensureTwin/findUndefOperandInBody fence still sees the
raw poison operand inside the freeze and protects that unsupported duplication.
The full p3kd.7.7 issue remains open.

Independent reviewer dm7f16_review_r2 delivered this finding after reading the
intended slotCarriesUndef predicate and the source/cache/tag implementation.
Zero tests, builds, cq-opt executions or targeted probes (0/6).
