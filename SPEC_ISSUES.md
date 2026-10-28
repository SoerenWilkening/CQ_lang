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

## 76 param_bounded: QROM length n reads 0 at n = 0, the C program reads t[x]
- Rule: CR §2 `urem(a, 0)` = `a`; CR §2 `qrom_load` index `≥ n` reads `0`; rule 20 (QROM length "the index's upper bound from LLVM's range facts").
- Disagreement: the reference gives `t[x % n]` a QROM of runtime length `n` (header: "the index lies in [0, n)"). At `n = 0` the §2 totalization makes `x % 0 = x`, so the C program reads `t[x]`; the length-0 QROM reads 0 for every index. LLVM's fact `x % n < n` assumes `n ≠ 0`, which §2 overrides.
- Evidence: `param_bounded(0, th, icoef, 0)`: C oracle returns `icoef[0]` = 1, the reference measures 0 (`x = 1`: 2 vs 0). 10 samples at n = 0, from the classical set and the divisor-0 row.
- Bead: cq-hw1a

## 76, 91, 107: quantum inputs where the C program accesses past its object
- Rule: CR §6 item 1 (the permutation part equals "the C program evaluated classically on the same inputs under §2"); rules 20 and 21 (QROM `2^W` fallback reading host memory; QRAM cells past the real size read as their content; a fat-pointer load past the object reads 0).
- Disagreement: on these inputs the C program is undefined. §6 defines indeterminate cells as 0 but says nothing about reads past an object. The references follow rules 20 and 21 and disagree with the C oracle's model, so the comparison depends on host memory layout. 76 `param_unbounded` (`t[x]`, x ≥ 4 past `icoef`): the QROM of 256 entries reads host memory, the C oracle reads 0. 91 `heap_quantum_size` (`n & 3 < 2`: `a[1]` past the block): the reference reads the QRAM cell (`v` stored there), C reads 0 after `realloc` copies `n & 3` bytes. 107 `union_ptr_to_int` (x even: `b + 2`, one past `b`): the reference reads 0 (rule 21), the C oracle reads the adjacent `a[0]`.
- Evidence: `cqcheck baseline`: 76 326 reasons on `param_unbounded` (e.g. x = 4: ours 0x1, C 0x0); 91 18 reasons, all at `n & 3 ∈ {0, 1}`, `k & 3 = 1`; 107 84 reasons, all even x (ours `0 + w`, C `1 + w`). The sampler keeps every quantum sample (edge, random and, for 76's 8-bit index, exhaustive), so these inputs are always compared.
- Bead: cq-nqna

## 65 fenv_tested: plain fmul after fesetround(FE_UPWARD)
- Rule: CR §6 item 1 (C program evaluated classically under §2); rule 23 (applies under `FENV_ACCESS`); LLVM's default floating-point environment for non-constrained ops.
- Disagreement: without `FENV_ACCESS` the `fmul` is a plain op. The reference header takes LLVM's default environment (round to nearest, no flags), so `y` rounds to nearest and `fetestexcept(FE_INEXACT)` sees only the quantum raise. The C program on the target rounds that `fmul` upward and raises INEXACT natively. CR does not say which of the two is "the C program" for §6.
- Evidence: `fenv_tested(0xffefffffffffffff, .5, 2, 1)`: the reference measures y = 0xfff0000000000000 and f = 0, C 0xffefffffffffffff and 0x20; 9 random samples differ by 1 ulp in y and/or f 0 vs 0x20 (27 reasons, call 1 only). If the ruling is the default environment, the fix is in the C oracle (checker), not the reference.
- Bead: cq-0r1i
