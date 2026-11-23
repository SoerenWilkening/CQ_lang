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

## BACKEND_ABI §1.10 Objects: a pointer made from an integer has no object
- Rule: BACKEND_ABI §1.10, Derivation (a classical value derives from the object containing it); CR rule 20, address literals
- Disagreement: the value rule assumes a pointer value lies in its object. LLVM does not guarantee that for an `inttoptr` result: `(long *)((uintptr_t)p - 16)` followed by `b[i + 2]` is a legal access of p's object through a value that lies before it, so the backend would bound the access by the neighbouring object. The spec has no way for the compiler to tell the backend that an address carries no object.
- Evidence: `experiments/repro-round9/addr_literal_inttoptr.c` (f7): the lowered code passes `ptrtoint` of the `inttoptr` as the `_hl` literal of the address computation.
- Bead: cq-gn709
