# `dD1` / `dD4` / `dD5` — the independent round's F-1 probes, carried here on purpose

These three `.c` files are **not Track D2's**. They were constructed by the independent Rule-13
round (`$SES/review_r13_trackD/REVIEW.md` §4 F-1, verdict `CLEAR-WITH-ITEMS`) and are copied into
this track's `probes/` so that the reproducer travels with the landing rather than only with the
review. Their three siblings — `dD2` (no trailing gate), `dD3` (flat twin, the isolating control that
DISCHARGES) and `dD6` (trailing gate made diagonal) — stay in the review's own `probes/` and are
**named here rather than duplicated**, so there is exactly one copy of each module in the tree.

## Say the direction first: for `dD1` this landing is an **OVER-ACCEPT**

`dD1_hoisted_template_cond_then_ry.c` — the condition's operand is a HOISTED loop-invariant
**TEMPLATE** rail (`int t = q & 1;`), the compare `t == 1` is LICM-hoisted (which is what bd
`drbq.12` newly admits), and AFTER the loop a NON-DIAGONAL `q = cq_theta(q, 0.9)` runs on the
register that template rail COPIES, and `q` is measured.

## Verdicts, RE-MEASURED by Track D2 rather than inherited (Rule 11)

Pipeline: `$SES/PROTOCOL.md` per-probe, `clang -O1 -g`, both binaries on the same stage-1 file.

| probe | ORACLE `9bd01598…` | SUBJECT `5ee9d144…` | stage 2b on the SUBJECT |
|---|---|---|---|
| `dD1_hoisted_template_cond_then_ry.c` | **exit 1**, `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | **exit 0** + `warning: cq rotation lowering: non-diagonal gate over a live derived record` | `2 rail mint(s) of which 2 left allocated, 2 template rail mint(s) of which **1 left dirty**, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` |
| `dD4_unrolled_twin_of_dD1.c` (hand-unrolled, same K) | **exit 1**, same string | **exit 0**, **no warning at all** | `2 rail mint(s) of which 2 left allocated, 3 template rail mint(s) of which **0 left dirty**, 3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven` |
| `dD5_loopvariant_cond_oracle_reference.c` | **exit 0** + the same warning | **exit 0**, md5 of the lowered IR **IDENTICAL** (`d288ad205dc4d3e055cb9e64fa55f4fc` on both) | — |

## The two things those rows say

**(1) The hazard.** In `dD1` the emitted stream contains
`cq_template_and_i32_hl(h0, 1) -> h2`, which is **never `_unc`'d and never freed**, while
`cqrt_ry_i32(h0, 0.9)` then runs on `h0` — the register `h2` copies — and `h0` is measured. That is
Rule 8 verbatim: *"a permutation that leaves a rail dirty **and** entangled still dephases under
later interference."* ⚠ `free_pairing_check` reports `0 violation(s)`: it **counts** the dirty
template rail and does not fail on it. CLAUDE.md already says stage 2b is *structurally blind to a
leaked TEMPLATE-minted rail*; this is that blindness, on a fresh customer.

**(2) The divergence, which is why it is a P1 and not a note.** `dD1` and `dD4` are the SAME program
at the same trip count and they now get **different circuits**: `dD4` emits
`cq_template_and_i32_hl_unc(h2, h0, 1)` + `cqrt_free(h2)` **before** the trailing Ry and warns not at
all. Both were loud declines on the ORACLE; both are accepts on the SUBJECT; the divergence is
**newly reachable**. That is bd `1m5p` class A's signature (*"a hoisted loop-invariant derived chain
whose top rail the ROLLED form leaves allocated and the flat form discharges"*).

**And the class is PRE-EXISTING.** `dD5` is the same leak with the condition made loop-VARIANT so P4
never fired: it accepts on the ORACLE with the identical warning and a byte-identical lowered md5.
⚠ **"Pre-existing" is true of the defect and FALSE of its population** — this landing widens it by a
spelling.

## NO FENCE IS ADDED HERE, DELIBERATELY

The class is bd `s82e`'s (with bd `7845` and bd `1m5p`), and a second spelling of another track's
fence is the drbq Inc-3 (b′) defect (Rule 14). Group 1's loop-exit anchor (P2) is the capability the
orchestrator has designated to discharge it, and this landing is therefore **SEQUENCED BEHIND Group
1 under one combined merge-and-gate**, where these three probes are a **required measurement on the
combined binary**. The red-green pair to write WITH that fence is: RED `dD1`, GREEN `dD3` (the flat
twin, which discharges), isolating controls `dD6` (trailing gate diagonal) and `dD2` (no trailing
gate) — all three in `$SES/review_r13_trackD/probes/`.

⚠ **None of Track D2's own gates could see this**, and that is the instrument lesson to carry: there
is no fixture for the shape, stage 2b reports `0 violation(s)`, the track's new e2e twin pair is a
different shape, and `e2e-loop-twin-matrix` — which CLAUDE.md calls the only instrument that can see
a leaked TEMPLATE-minted rail — was correctly not run by this track and has no cell for a
hoisted-TEMPLATE condition.
