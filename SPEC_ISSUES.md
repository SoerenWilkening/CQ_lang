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

## 23_condition_tree (cond_mixed), 180_teleport: a one-i1 `c && q` branches classically on `c`
- Rule: CR rule 8 ("A condition that is a Boolean combination of classical and quantum terms (`c || q`,
  `c && q` as one `i1`, ...) is one flag: each classical `i1` term becomes a seed rail (rule 7) and joins
  by `and_i1`/`or_i1`"); NORTHSTAR principle 2 ("A classical i1 becomes a seed rail only as a term of one
  mixed i1").
- Disagreement: in both examples -O1 produces one `i1`, `select i1 %7, i1 %8, i1 false` with `%7`
  classical (23: `flag != 0`; 180: the measured `m2`) and `%8` quantum, and branches on it. The
  references emit a classical `br i1` on the classical term around `rz_i1` on the quantum flag
  (23 lowered.ll line 58, 180 lowered.ll line 48) instead of `and_i1(seed(c), q)` into a fresh flag.
  69_complex_double seeds the classical disjunct of one `or i1` (lowered.ll lines 139-141), as the rule says.
- Evidence: textual (CR rule 8 against the two references). The readings are §6-equal on these
  examples: with the classical term 0 the seed reading emits a phase whose predicate is constant 0, a
  global phase §6 excludes; with it 1 both emit P on `x == k` (23) or on `c` (180).
- Bead: cq-55s
