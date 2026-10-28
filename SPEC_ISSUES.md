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

## 09, 37, 54, 189 (header-tested K loops): kept a_K reads 1 at exactly K trips
- Rule: CR §6 (ruling cq-1di, eb8a11a): "the exit test after the K-th body gives a_K ... on an input with at most K trips a_K must read 0"; T1.2 counts a trip as test then body.
- Disagreement: the references run K tests and K bodies and keep the K-th test's predicate (the test before body K), so a_K reads 1 on an input with exactly K trips. Rule 14's sentence ("the last chained predicate already is the test admitting trip K+1: it is a_K") matches the references, not the §6 ruling.
- Evidence: 09 tail_recursion(x0=6, .5, k=2, a=1, b=0xffffffff) runs 4 bodies and exits normally (C returns 4); the reference's kept a[K] rail reads 1. `cqcheck run 37 --oracle c --ours <reference>` fails "a_K ... no kept i1 rail reads" on the n=4 samples.
- Bead: cq-wsbm
