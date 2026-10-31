# Spec issues

Contradictions found in the pinned CQ_spec (see `spec.lock`). CONSTRUCTION_RULES.md wins over an
example; the fix lands in CQ_spec (tracked in its §7 table), never as a workaround here. An entry is
removed when the fix is in CQ_spec and `spec.lock` is re-pinned to it. Version 1 requires this list
to be empty.

Entry format:

```
## <example or CR section>: <one-line summary>
- Rule: <CR rule/section the example or text should follow>
- Disagreement: <what the reference, header or text says vs what the rule requires>
- Evidence: <checker output, input sample, line references>
- Bead: <cq-… id>
```

## Open

## 194_complex_builtin_lifted: the reference uses a template CR §1.2 does not name
- Rule: CR §1.2 template list (intrinsic routes name `uadd_sat usub_sat`, no signed saturating forms); BACKEND_ABI §2 likewise.
- Disagreement: complex_builtin_lifted.lowered.ll calls `cq_template_sadd_sat_i32` (11 uses), from compiler-rt's inline `__compiler_rt_logb`/`scalbn` path.
- Evidence: our structural verifier rejects the reference: "malformed ABI call: @cq_template_sadd_sat_i32 is not a template name (CR §1.2)".
- Bead: cq-75bz
