# loopgate — ATTRIBUTION: the corpus sweep, per track, BY STRING

**Corpus** `ir-pass/test/*.ll` + every session dir's `track*/probes` and `review_*_probes` under
`docs/prd/phase-04-swap-route-control/inc1-records` — **4220 modules**, identical paths on every
binary (1 genuinely 0-byte module, `review_r1a/probes/h0_empty.ll`, is skipped by name: a 0-byte
`.ll` ACCEPTS through the passthrough early-out).

**Row format** `rel|A|<lowered-IR sha16>|` or `rel|D<exit>|<FULL-STDERR sha16>|<tag>`. Two
deliberate strengthenings over the shared `corpus.sh` (see `probes/README.md`): the **whole of
stderr** is hashed rather than reduced by the tag regex (PROTOCOL S3 — the regex renders the entire
`cq_measure_<sfx>` family as an empty `D:`, hiding decline→decline string moves), and the **lowered
IR** is hashed for accepts, so an ACCEPT whose STREAM moved is a mover too.

**Self-checks that make a silent pass impossible** (the fix agent's first sweep printed *"0 movers"*
while all 2050 rows were exit 127): the script refuses to emit a file unless the binary AND plugin
exist, **no row is exit 127**, and **both verdict classes occur**. Measured on every sweep below:
`accepts=2529 declines=1691`, `127=0`.

---

## 1. TRACK D's ENV-GATE: VERIFIED, NOT ASSUMED — **0 movers over 4220 rows**

With `CQ_BBU0_DEFER_DEPHASE_FENCE` **unset**, MERGED vs the Track-D-free control `loop-group-fix`
`9dd81edb…`:

```
sha256(sweep_FIX_9dd81edb.txt)    = 73224a38ba5c1ff2878ef0efd48a0669…
sha256(sweep_MERGED_f2ee2eb6.txt) = 73224a38ba5c1ff2878ef0efd48a0669…
```

**The two sweep files are BYTE-IDENTICAL.** That is stronger than "0 movers": every one of the 2529
accepts produced the same lowered-IR hash and every one of the 1691 declines the same FULL-STDERR
hash. Structurally corroborated by `git diff --stat loop-group-fix -- ir-pass/` = **267 insertions,
0 deletions**, and by `deferDephasingDecline()` being a single `getenv` evaluated at most once per
module and only on the declining path.

---

## 2. ORACLE `0e280fc6…` vs MERGED `f2ee2eb6…` — **90 movers, 0 UNATTRIBUTED**

| transition | ORACLE string | MERGED string | n | **track** |
|---|---|---|---|---|
| `D→A` | old fence spelling | *(accept)* | **35** | **Track T** — bd `tu9q` pairing: the discharge lands, so the fence no longer fires |
| `A→A` | — | — | **31** | **Track T** — 27 pairing additions, 4 declaration-order only (§3) |
| `D→D` | old fence spelling | **new** fence spelling | **20** | **Track S′** — the decline-string move (bd `c767`/`7845`/`2g52`) |
| `D→D` | old fence spelling | `round-1 iteration-local marking falsified by round-2 taint` | **2** | **Track T** — bd `tu9q`'s new `declineRound2FalsifiedRailGrants` |
| `A→D` | *(accept)* | new fence spelling | **2** | **bd `emkg` fix** — the nested-loop P1 over-accept, closed |
| — | — | — | **0** | ⚠ **UNATTRIBUTED (would be a FINDING)** |

The two `A→D` rows — the **only** direction that adds a refusal — are
`loop_leak_dephase_reject_nested_iterlocal_inner.ll` and
`loop_leak_dephase_reject_nested_depth3_middle_rail.ll`, i.e. the `emkg` fix's `n1` and `r1`. That
these two and no others are ORACLE-reachable matches the fix agent's record exactly: `n1` *"needs
NEITHER track, reproduces on the ORACLE"*, while `n2`/`n3` route through Track T's markers, which do
not exist on the ORACLE, so they were already declining there.

⚠ **The bucketer is not the attribution.** `probes/attribute.py` keys on diagnostic strings, and an
ACCEPT has none — so it put all 31 `A→A` rows in its `⚠ UNATTRIBUTED` bucket. **Every one was then
adjudicated by measuring the stream**, not by trusting the bucket; §3 is that measurement.

---

## 3. The 31 `A→A` stream moves, adjudicated BY MEASUREMENT (`probes/adjudicate_AA.sh`)

Per-symbol call-count delta, ORACLE stream vs MERGED stream. Track T's pairing predicts **additions
only, and only of `*_unc` adjoints and `cqrt_free`** — the rolled form emitting the discharge the
flat form already emitted. A removed gate, or an added non-discharge gate, would be a FINDING.

```
PAIRING-ONLY deltas: 31     OTHER (FINDING candidates): 0
```

**27** carry a real delta, always of the shape `> N @cq_template_*_unc` + `> N @cqrt_free`.
**4** carry an EMPTY call-count delta yet a moved IR hash — and a multiset equality is not an
identity, so they were opened: all four differ **only in the position of a
`declare void @cqrt_addc_i32(i32, i32)` line** in the module's declaration list (lazy
`FunctionCallee` minting order). With `declare` lines stripped, **every instruction is
byte-identical** in all four
(`control_phase_kickback_mixed_{merge_out_rail,value_merge_dtzb_head,value_merge}_preadd_inloop.ll`,
`lowering_uncompute_preserving_sink_in_loop.ll`). No circuit change.

---

## 4. The A × B COMPOSITION — where S′'s refusal does not survive Track T

Four programs are refused by **Track S′ alone** and accepted by **Track T alone**; the merged binary
takes T's verdict. Measured on three binaries plus the rolled-vs-hand-unrolled twin on MERGED:

| program | S′ `15f6a75a` | T `c0029f26` | MERGED `f2ee2eb6` | rolled vs twin on MERGED |
|---|---|---|---|---|
| `b7b_w2k_interfered` | DECLINE | ACCEPT | ACCEPT | **24 == 24**, multiset delta EMPTY, positional |
| `b7c_w2h_interfered` | DECLINE | ACCEPT | ACCEPT | **42 == 42**, multiset delta EMPTY, positional |
| `b11_cmp_rail_data` | DECLINE | ACCEPT | ACCEPT | **14 == 14**, **BYTE-IDENTICAL** |
| `s1_live_shift` | DECLINE | ACCEPT | ACCEPT | **14 == 14**, **BYTE-IDENTICAL** |

The two positional cases are the same shape the fix agent recorded for `c2_inloop_rotation`: `-O1`
LICM-hoists the loop-invariant `y & 1` to the front of the ROLLED spelling and emits it later in the
twin; the gates in between act on the per-trip register and its own ancillas, a support **disjoint**
from the hoisted rail, so the reorder commutes exactly and handle numbering follows. **Stated as
multiset-plus-commutation, not identity** — `CLAUDE.md` §5 records a shipped fixture family that read
a stability measurement as a correctness one.

⚠ **This composition is cleared BY MEASUREMENT AND BY NO INDEPENDENT REVIEW.** Track S′'s Rule-13
round saw a binary on which these four DECLINE; Track T's saw one on which S′'s refusal does not
exist. *A composition is not cleared by clearing its parts* (`CLAUDE.md` §4c, the F × P precedent).

---

## 5. The three non-empty twin deltas among the `D→A` rows — all TWIN-FIDELITY, none a leak

Nine `D→A` stems have hand-unrolled twins; all nine were re-measured on MERGED. Six agree
byte-for-byte (`a1_ry_on_body_rail` 16, `a2_fanout_body_rail` 18, `a7_two_registers` 36,
`b10_inplace_volatile` 7, `r3_two_loops_one_register` 24, plus `s1`/`b11` in §4). Three diverge, and
**in every one the ROLLED side is fully discharged** — the divergence is in the twin:

* **`t3_cmp_rail_data` — 20 vs 20 with a NON-EMPTY multiset.** Exactly trap 3's shape, and it is
  benign: `-O1` canonicalises the twin's constant-shift `(y>>1)==1` into `(y & -2)==2` (`and`), a
  rewrite unavailable to the rolled form because `k` is the induction variable. Structurally
  identical — 2 rail mints + 2 `_unc` + 2 frees, 2 compare rails + 2 `_unc` + 2 frees, same measures,
  same post-loop `Ry`. **Rule 9 territory, not a lowering divergence.**
* **`a9_nested_loop` — rolled 24 vs twin 20, rolled LONGER.** The twin source reads `(y>>2)&1`
  **twice**; `-O1` CSEs them into one rail measured twice (the twin's trace carries
  `cqrt_measure_i32(h4)` on two consecutive lines). The rolled form emits 4 mints / 4 `_unc` / 4
  frees and leaks nothing; it matches the fix agent's recorded accept-control value of **24,
  unmoved**.
* **`r2_two_functions` — rolled 24 vs twin 30.** §6.

**Lesson worth carrying:** a rolled-vs-unrolled twin is evidence only while the twin is a *faithful*
transcription — `-O1` can CSE or re-canonicalise one spelling and not the other, making them
different programs. Read the multiset AND the source before calling a delta a leak.

---

## 6. `r2_two_functions`, and the adversarial probe the gate added — **G1**

`r2_two_functions.c` is Track T's bd `1yeu` cross-function probe. On MERGED it accepts with a
**per-function asymmetry**: `ka()`'s rails are discharged by the pairing (`_unc` + `free`, lines
3–12), while `kb()`'s three rails — the hoisted TEMPLATE rail `int p = y * 3;` and its two per-trip
shifts — are **left allocated**, where the twin discharges all three. That half is the one Track T
states it deliberately did **not** build (`IMPL_T2.md` §0; bd `1m5p`).

**It is benign there, and only for a reason that can be tested:** `kb()` ends in
`cq_measure(y)` with **no post-loop non-diagonal gate**, so the leftover which-path records never
meet an interference — Rule 6's accepted leak. Per `CLAUDE.md` §5 the *divergent* half is *"the same
register rotated by a NON-DIAGONAL gate after the loop and then measured"*.

So the gate added **`probes/g1_twofn_kb_rotated.c`** — `r2_two_functions.c` with exactly one line
added, `y = cq_theta(y, 0.9);` in `kb()` before its measure — and measured it on five binaries:

| ORACLE | S′ | T | FIX | **MERGED** |
|---|---|---|---|---|
| DECLINE | DECLINE | DECLINE | DECLINE | **DECLINE** |

On MERGED the diagnostic is source-located in the **right half**:

```
…/g1_twofn_kb_rotated.c:23:39: in function kb i32 ():
cq loop lowering: rolled body leaks a rail entangled with a rotated register
```

line 23 being `kb()`'s in-loop `(p >> k) & 1`. **The benign/divergent boundary holds across the
composition on the group's only cross-function shape — tested, not assumed.**
