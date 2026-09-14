# Track T — IMPL_T.md: the `_Bool` (`i1`) axis for `e2e-loop-twin-matrix` (bd `uq96`)

Worktree `/Users/sorenwilkening/Desktop/CQ_twinbool`, branch `twin-matrix-bool`, off `main` 607b6fe4.
**No pass source is touched.** Files changed: `tools/loop_twin_matrix.py` and the table it owns,
`tools/loop_twin_matrix.expected.txt`. `tools/loop_twin_matrix.quarantine.txt` is **byte-unchanged**.

---

> **SECOND PASS, after Track W landed (§8).** Ten more cells for bd `wx8g`'s clause (c) — the
> ITERATION-LOCAL rail, which none of the first 40 could reach. Final counts:
> **338 cells = 309 expected + 29 quarantined.** Everything in §0–§7 describes the first pass and
> stands; §8 is the delta.

## 0. The one-line result (first pass)

The widened matrix goes from **288 cells (259 expected + 29 quarantined)** to
**328 cells (299 expected + 29 quarantined)**. The 288 pre-existing cells' generated source is
**byte-identical** and every one of their committed verdicts is **unmoved**. Of the 40 new `i1`
cells, **ZERO diverge** — so nothing is quarantined, nothing is blessed, and no divergence-class bd
issue is filed. What the new cells do is pin **9 shipped-but-unpinned accepts** (the rolled
bare-`_Bool` branch phase, which had no fixture, no slice and no cell anywhere) and **9 rows that are
bd `wx8g`'s subject row for row**.

One thing did go wrong and it was in the instrument, not the compiler: `--regenerate` silently
**deleted 54 lines of hand-added Rule-13 ruling prose** from the expected table's header. It is
recovered and the hole is closed — §6.

**The generator diff** is the single commit on `twin-matrix-bool`
(`git diff main...twin-matrix-bool -- tools/`): `tools/loop_twin_matrix.py` +451/-21 and
`tools/loop_twin_matrix.expected.txt` **+107/-0** — *zero deletions*, which is the mechanical proof
that §6's recovered header block is fully back and that no committed row was dropped or renamed.
`tools/loop_twin_matrix.quarantine.txt` does not appear in the diffstat at all.

---

## 1. What was built

### 1.1 The axis

A seventh axis in `tools/loop_twin_matrix.py`, recognised the way the Ry axis is — by **which dict
holds the region key**, never by the cell's arity or by a token spelling, so adding it can neither
rename a committed cell nor change another family's source text by one byte.

| axis | values | what it moves |
|---|---|---|
| `B_COND_TEXT` | `b` = `if (b)` · `nb` = `if (!b)` · `ab` = `if (b & (a == off))` | how the BARE RAIL is read: the shipped leaf, the ¬-arm polarity (Rule 9 — the one place the emitter may not `cqrt_x` a user register), and the condition TREE with a rail leaf beside a compare leaf |
| `B_ARM_TEXT` | `phi` · `ry` · `prep` · `val` | the branch-phase KICKBACK · the in-place controlled Ry on a disjoint register (bd `wx8g`'s customer) · the controlled STATE PREP · the 4.4 data select (`if (b) a -= 3`, the owner's own line) |
| `BCARRY` | `binv` · `bcar` | `b` seeded once before the loop (LOOP-INVARIANT, identity carry φ) vs re-rotated per trip (LOOP-CARRIED, an `i8` header φ — bd `r903` is load-bearing here) |
| `RECORD_B` | `bpremark` | `_Bool mark = b;` taken before the region, read after the loop — the `staleRailRecordRead` grouping question at `i1` |
| `B6_COND_TEXT` | `abs` · `abl` | the two NON-core compound spellings, at the phase arm only (§1.3) |

`_wrap`'s `second` parameter became **three-valued** (`none` / `quantum` / `classical`) instead of a
bool, because a controlled state prep needs `int r = 7;` **declared and never seeded** — a prep whose
arg-0 is already quantum is a data mux instead, which is the mistake `rprep`'s own comment regrets.
`bcond` adds the `_Bool b` register and its seeding rotation. Both default to the pre-`uq96`
behaviour.

### 1.2 The sub-grids, declared not producted (the file's standing convention)

```
B1  the CORE product: 3 bare-rail spellings x 4 arms x 2 carries          24
B2  the a-register gate STAR beside the three non-value arms, at `binv`    6
B3  the dtzb in-place VALUE gate beside the VALUE arm                      2
B4  the PREHEADER in-place op (the F-C1-1 axis) under a bare rail          2
B5  the RECORD axis at `i1`, on the rail itself                           4
B6  the two non-core compound spellings, at the phase arm                  2
                                                                        ---
                                                                          40
```

40 is the **top of the 24–40 band** Track L scoped (`$PREV/trackL/SCOPE_loop.md` §2.6) and no more:
this gate is the suite's long pole.

### 1.3 The one design decision that was MEASURED rather than chosen (Rule 11)

The compound-condition spelling. The first cut used `if (b && a == off)` on the reasoning that the
`oeq`/`one`/`oder` comment prescribes an OPAQUE threshold. **Measured on the ORACLE, at the phase
arm, invariant carry** (`probes/probe_cells.log`):

| spelling | verdict | why |
|---|---|---|
| `b && a == off` | `DECLINE-BOTH` `nested control flow` | SHORT-CIRCUIT `&&` + a **volatile** right operand: the load may not be speculated above the `b` test, so `-O1` cannot if-convert and hands the pass a genuine depth-2 **NEST**, not a tree |
| `b && a == 5` | `UNROLLED-ONLY` | speculatable ⇒ `select i1 %b, i1 %cmp, i1 false`; the FLAT side ACCEPTS with the full `collectCondTree` stream, the ROLLED side declines the generic `control flow under quantum control` because `a` and `b` are both loop-invariant and LICM lifts the compare out |
| `b & (a == off)` | **`ACCEPT-IDENTICAL`, 22 trace lines** | BITWISE `&` forces both operands to be evaluated, so the volatile load is unconditional and the tree survives as `and i1`. The rolled form mints and discharges a `cq_template_icmp_eq_i32_hl` rail **per trip** and is byte-identical to its twin |

So `ab` is the **bitwise, opaque** spelling — the only one defeated by neither the hoist nor the
speculation barrier — and the other two are **kept** as sub-grid B6, one cell each, because each
records a different `-O1` phenomenon. Deleting either would leave the `ab` core product looking like
the only reading there is. This is the `oeq`/`one`/`oder` lesson a second time.

The `b & (a == off)` cell is worth naming on its own: it is the **first cell in the file that can see
a leaked TEMPLATE-minted rail under a bare-rail condition** — the 8h7d.5 F-4 class, at `i1`.

### 1.4 The intent that was measured FALSE, and is written into the source as such

`prep` declares `int r = 7;` classically so the cell would decline for **one** reason rather than the
two `rprep` declines for. **That is false and the measurement is worth more than the intent.** All
eight `prep` cells are `DECLINE-BOTH-DIFFERENT`: rolled the loop message, FLAT `state prep merged with
a quantum register`. The classical declaration buys nothing past the **first repetition**, because
the flat twin is the body written out TWICE and repetition 2's pred incoming is repetition 1's MERGE
φ — F1's no-cloning mux. That is **structural to a twin with TRIPS > 1** and cannot be designed away
in this instrument.

⚠ **Those eight rows are therefore a TRAP for bd `wx8g`, not a TODO**, and the source says so at
`B_ARM_TEXT`. The rolled side carries the loop message, so the increment will be tempted to flip
them — but the rolled form's own pred incoming is the header φ of `r`, quantum after trip 1, i.e. the
same no-cloning question the flat side refuses. `ACCEPT-IDENTICAL` is impossible (the flat side
declines); `ROLLED-ONLY` is the expected table header's *"an over-accept and a Prime-Directive red
however green the run looks"*. The only passing flip is `DECLINE-BOTH` on the flat message.

---

## 2. Cell counts

| | expected | quarantined | total |
|---|---|---|---|
| **OLD** (`main` 607b6fe4) | **259** | **29** | **288** |
| **NEW** (this branch) | **299** | **29** | **328** |

Measured with the commands `CLAUDE.md` names:

```
$ grep -c '^m_' tools/loop_twin_matrix.expected.txt      # 259 before, 299 after
$ grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt # 29 before and after
```

**No committed cell was renamed and none was deleted.** The `_Bool` cells take the existing
five-segment grammar with a `B_REGION` region token (`b*`/`nb*`/`ab*`, disjoint from every
`RY_REGION` token) and the carry key in the `<rgate>` slot, so `grep -c '^m_'` keeps counting cells.

**PROVEN, not asserted** (`probes/source_identity.py`, the discipline the `prehead`/`preloop`/
`postloop` axes were added under):

```
$ git show HEAD:tools/loop_twin_matrix.py > /tmp/ltm_old.py
$ python3 .../probes/source_identity.py /tmp/ltm_old.py tools/loop_twin_matrix.py
OLD cells 288   NEW cells 328   added 40
PASS: all 288 OLD cells x 2 surfaces x 2 sides are BYTE-IDENTICAL
      sha256 over the 1152 old-cell texts: 8b54c28e1525329b4b655bacc43b94e0
```

---

## 3. §3 of the brief — the per-divergent-cell verdict table

**There is no divergent new cell.** That is a measurement, not a reassurance, and here is the
measurement: the widened run reports `TRACE-DIVERGENCE 29` against `29 quarantined (pinned
signatures)`, and the only hard-failure lines in the pre-regeneration run were 40 × `NEW CELL, not in
the expected table`. A divergence in a non-quarantined cell is a hard failure that prints a
`ROLLED AND UNROLLED TRACES DIFFER` block with the first differing line and both sides' counts; no
such block appeared.

| divergent new cell | verdict | disposition |
|---|---|---|
| — (none) | — | — |

Consequences, stated plainly so that nobody has to infer them:

* **Nothing was added to `tools/loop_twin_matrix.quarantine.txt`.** It is byte-unchanged.
* **`--refresh-quarantine` was never run.**
* `--regenerate` was run **once**, deliberately, to write the 40 new rows — never to turn a red
  green. Its own refusal path is what would have stopped it: `--regenerate` refuses to write while
  any un-quarantined divergence or any moved boundary control exists, and it did write, which is
  itself a measurement that neither condition held.
* **No divergence-class bd issue is filed**, because there is no divergence to file.
* The `i1` width adds **no member to quarantine class A, B or C** today.

---

## 4. What the 40 new cells actually say (the composition, measured at the ORACLE)

Written **before bd `wx8g` exists**, which is the whole point of regenerating an axis early — the Ry
axis's own precedent at `1bdaa60`: *a table written after the implementation can only say the
implementation agrees with itself.*

| verdict | n | which cells, and what the row means |
|---|---|---|
| `ACCEPT-IDENTICAL` | **9** | every one is a `phi` (branch-phase KICKBACK) cell: `if (b)`, `if (!b)` and `if (b & (a == off))`, at both carries, with an a-register `ry` gate and with the preheader `add`. **NEW CAPABILITY BEING PINNED, not arriving** — the rolled bare-`_Bool` phase region already shipped and had no fixture, no slice and no matrix cell (the 2026-09-13 session recorded it as L-0). `m_none_abphi_*` is the strongest: 22 trace lines, a `cq_template_icmp_eq_i32_hl` rail minted **and discharged per trip**, byte-identical to the twin |
| `UNROLLED-ONLY` | **15** | **9** on `cq controlled lowering: control flow inside a loop body under quantum control` — every `ry` arm — which is **bd `wx8g`'s subject row for row**, and the flat twin's stream is measured in `probes/probe_wx8g.log`: `cqrt_ry_i32_controlled(h2, h1, 0.9)` TWICE with `h2` the bare `_Bool` rail as the CONTROL, which is exactly what those nine rolled sides must come to emit; **5** on `cq loop lowering: loop-carried tainted value crosses iterations` (the `val` arm, `LoopLowering`'s X1 clause, reached *before* detection — SCOPE_loop §4); **1** on the generic `control flow under quantum control`, the B6 `m_none_ablphi_none_none_binv` |
| `DECLINE-BOTH-DIFFERENT` | **11** | **8** `prep` cells (rolled the loop message, flat `state prep merged with a quantum register` — see §1.4, they are a trap) and **3** `val` cells at the CARRIED bool |
| `DECLINE-BOTH` | **5** | the `ab` TREE at the `ry` and `prep` arms (4, generic `control flow`: a condition TREE is off-pattern for the rail ladder even where the bare rail is admitted) and the B6 `m_none_absphi_none_none_binv`, `nested control flow` |

The four rows read as one sentence: **the `i1` PHASE path already rolls and is now pinned; the `i1`
Ry / prep / value paths do not roll, and the nine `ry` rows are the diff `wx8g` must produce.**

### 4.1 Two rows worth carrying to the owner / the next increment

* **`m_none_ablphi_none_none_binv` is a recorded OVER-DECLINE with a live flat twin.**
  `for (…) if (b && a == 5) cq_phi(π);` — the FLAT side accepts and emits the whole condition-tree
  stream (`icmp_eq` mint, `cqrt_alloc_i1` node ancilla, `cqrt_toffoli(h_b, h_cmp, node)` with the
  RAIL AS THE CONTROL, the kickback, the LIFO strip, two frees); the ROLLED side declines
  `cq controlled lowering: control flow under quantum control` because `a` and `b` are both
  loop-invariant and LICM lifts the compare out of the body. **This is a new customer of bd
  `drbq.12`** (*"loop-INVARIANT condition register — clang -O1 LICM-hoists the compare out of Pred
  (rolled) / CSEs it (flat)"*), now at a bare-rail-plus-compare TREE rather than a bare compare.
  Track T did not file it (see §5); it belongs as a note on `drbq.12`.
* **The eight `prep` rows are a trap for `wx8g`, not a TODO** — §1.4. The only passing flip is
  `DECLINE-BOTH`; `ROLLED-ONLY` is an over-accept.


---

## 5. What Track T could NOT do, and what it hands on

* **`CLAUDE.md`'s twin-matrix count is now stale** — it says `259 + 29 = 288`. The correct figures
  are `299 + 29 = 328`. Track T does not edit `CLAUDE.md` (it is not in the brief's deliverables and
  it is a cross-track merge hazard); the closing agent re-measures the counts every session and owes
  this line. Same for `$SES/trackL/SCOPE_L1a.md` §5's blind-spot row, which is now HISTORY —
  `grep -c -i bool tools/loop_twin_matrix.py` is no longer 2.
* **The quarantine's boundary-control story is unchanged and untouched.** Both controls ran on every
  invocation including `--regenerate` (`q_noregion ACCEPT-IDENTICAL`, `q_armoncond TRACE-DIVERGENCE`
  at its pinned signature) and neither moved. No weakening of any of the quarantine's four failure
  directions was made or needed.
* **The blind spot this axis inherits, said in the Ry axis's own words:** the ORACLE is the UNROLLED
  twin, and the unrolled twin of a bare-rail cell is itself the l4x4.b FLAT lowering. A defect the
  flat and rolled paths SHARE is byte-identical on both sides and reports `ACCEPT-IDENTICAL`. The
  flat side's own witnesses are the `ir-pass/test/control_*_bool_*.ll` family and the
  `slice_control_*_bool_*` slices; nothing here replaces them. This is written into the axis comment.
* **`ir-pass-lit` was not run and no fixture was touched** — Track T adds no fixture and no decline
  string (PROTOCOL matrix; the brief forbids it).

---

## 6. THE INSTRUMENT FINDING — `--regenerate` silently deleted 54 lines of a Rule-13 ruling

This is an L10 finding ("instruments earn their keep by being attacked") and it is recorded here
because it happened *during* this increment and would otherwise have shipped as a silent loss.

**What happened.** `tools/loop_twin_matrix.expected.txt` is written by `--regenerate` as
`EXPECTED_HEADER` (a constant in `tools/loop_twin_matrix.py`) followed by the rows. On 2026-09-11 the
bd `b6ap` landing hand-added **54 lines** of prose *directly to the table file* — the multi-phi
merge-peel ruling for the five `m_rz_*_rz` cells: the mechanism, the re-derived unitary
(`a == 5: PI + (-0.125) + 0.125 + PI = 2*PI`), the Rule-13 round-1 reviewer's CAVEAT, and an explicit
**retirement trigger** (*"if a later increment widens the angle-select accept class, re-derive them
rather than regenerating them"*). The first `--regenerate` after that — mine — **dropped all 54
lines**, and reported success while doing it. The rows were correct; the ruling was gone.

**Why nothing caught it.** The table's own header carried no statement that it is script-owned. The
QUARANTINE header carries exactly that statement, added as round-2 review finding **F-R2-3**
(*"ANY text hand-added up here is silently lost on the next refresh … A new class paragraph therefore
goes in that constant, never in this file"*) — the lesson was learned for one of the two files and
not transplanted to the other. Nothing in the tree diffs the header, and a regeneration diff is read
for moved ROWS.

**The fix, and it is the permanent one.** The 54 lines were recovered verbatim from
`git show HEAD:tools/loop_twin_matrix.expected.txt` and **moved into `EXPECTED_HEADER`**, which is the
only place a paragraph survives; the same F-R2-3 warning the quarantine header carries is now at the
top of this one too, naming this incident. Verified mechanically — every one of the 222 old header
lines is present in the new 283-line header, and the rows are byte-unchanged:

```
$ python3 -c "old=set(l.rstrip() for l in open('/tmp/exp_old.txt') if l.startswith('#'));
              new=set(l.rstrip() for l in open('tools/loop_twin_matrix.expected.txt') if l.startswith('#'));
              print('old',len(old),'new',len(new),'MISSING',len(old-new))"
old header lines: 222  new: 283
STILL MISSING from the new header: 0
```

**The standing lesson, in the form the next person needs it:** a generated artefact's header is
generated. If a ruling has to live beside a table, it lives in the constant that writes the table —
and the *other* generated artefact in the same family is where you go to check whether that rule has
already been written down once.

⚠ **Two sibling instruments have the same shape and were NOT audited by Track T** (out of scope, no
gate of mine can witness them): `tools/inplace_twin_matrix.py` and
`tools/angle_select_twin_matrix.py` both own regenerated tables. Whether either carries hand-added
prose in a script-owned header is an open question worth one `git log -p` each.

---

## 7. What was deliberately NOT done

* **`--refresh-quarantine` was never run.** No signature moved; nothing needed re-pinning.
* **`--regenerate` was never used to turn a red green.** It was run exactly once, to write the 40 new
  rows, and its own refusal path (it will not write while any un-quarantined divergence or moved
  boundary control exists) is the evidence that neither condition held — it wrote.
* **No quarantine semantics were weakened.** All four failure directions and both boundary controls
  are untouched; `e2e-loop-twin-quarantine-selftest` (27 cases) is green.
* **No bd issue was filed from this worktree.** `.beads/dolt/` is gitignored and per-checkout, so a
  write here would create a DB the orchestrator's main checkout never sees while five other tracks
  are live. The two items that want a tracker entry are handed over instead — §4.1's `drbq.12` note
  and §6's instrument finding.

---

## 8. SECOND PASS — the 10 ITERATION-LOCAL cells (bd `wx8g` clause (c))

### 8.1 Why the first 40 were not enough, and who measured it

Not me. **Track W's landing measured it**: every `B_ARM` in the first pass declares its second
register **OUTSIDE** the loop, so `r` is loop-CARRIED in all 40 and **none of them reaches clause
(c)** — the ITERATION-LOCAL rail, a register declared and minted *inside the body*, which has no
header φ at all and which `railPhiRootMint` therefore could never claim. The 9 rows that flip are
flipped by the increment's *other* half (retiring the l4x4.b in-loop carve). So the increment's
central new capability was unwitnessed by the one instrument that can see a leaked TEMPLATE-minted
rail.

That is the same blind spot bd `uq96` closed one layer up, one layer down — which is the argument
for adding these rather than a reason to feel bad about the first pass: an instrument is only ever
blind in the shape nobody has pointed it at yet.

### 8.2 The ten cells (sub-grid B7; the split is Track W's, IMPL_W §9.3 W-1..W-5)

| cell | shape | witnesses |
|---|---|---|
| `m_none_bilry_none_none_{binv,bcar}` | `for(){ int r = cq_theta(7,.25); if (b) r = cq_theta(r,.9); s += cq_measure(r); }` | **W-1**, clause (c2): K activations must mint K rails |
| `m_none_nbilry_none_none_{binv,bcar}` | the same at `if (!b)` | **W-1**, the rail ¬-arm polarity |
| `m_none_bilprep_none_none_{binv,bcar}` | `int r = 7;` in the body, the arm's `cq_theta` mints | **W-2**, clause (c2)'s `MintSeed = T` branch — ⚠ *this* is the prep shape that lowers, as against the eight CARRIED `*prep*` rows whose flat twin cannot escape F1 |
| `m_none_dilry_none_none_binv` | the DERIVED condition `(a >> i) & 1`, no `_Bool` at all | **W-3**, the only family that mints `cq_template_*` rails in the body, hence the only one that can see a missing SPINE discharge |
| `m_none_ddilry_none_none_binv` | the same + the sub-grid-F POST-LOOP DIFFUSION | **W-3**, what turns a leaked per-trip rail from a Rule-6 leak into a wrong unitary |
| `m_none_dilesc_none_none_binv` | the per-trip register carried out via `last = r;` and read after the loop | **W-4**, clause (c3) — the 19-vs-27 shape |
| `m_none_bil2_none_none_binv` | two independent per-trip rails, each measured in the body | **W-5**, `staleRailRecordRead` non-interference |

Two generator facts that had to be got right:

* **The derived family carries no `_Bool`** (`B_BCOND` is False for it). Its condition register is
  `a`, exactly as Track W's `w_g` uses `q`. An unused `b` would put an `alloc`/`ry`/`measure` triple
  in every trace of the one family whose traces are read for a *missing* discharge.
* ⚠ **An iteration-local body cannot be dedented and repeated, and the fix is the opposite of a
  re-spelling.** `int r = cq_theta(7, 0.25);` written out twice in ONE scope is a redeclaration and
  `clang` rejects it — the same harness artifact the RECORD axis designs around by hoisting `mark`
  out of the loop, which an iteration-local rail may not do by definition. So for these cells each
  flat repetition is wrapped in **the `{ }` the loop body already is**, and the body text is then
  used **verbatim, at its original indentation, with no dedent at all** — a *stronger* statement than
  the dedented form, since the two sides now share the body byte for byte. This matches Track W's own
  per-block twins (`w_d_iterlocal_base_bool_unrolled.c`).
* `B_CORE_ARM` was frozen as an explicit tuple. B7 **adds** keys to `B_ARM_TEXT`, and the B1 core
  product had been iterating `B_ARM_TEXT` live — which silently multiplied the long-pole gate by 24
  cells the first time the dict grew (caught by the size assertion, which is what it is for).

### 8.3 Counts

| | expected | quarantined | total |
|---|---|---|---|
| `main` (pre-`uq96`) | 259 | 29 | 288 |
| first pass (`c12a2afe`) | 299 | 29 | 328 |
| **second pass (this commit)** | **309** | **29** | **338** |

`probes/source_identity.py` again, against the first-pass commit: **all 328 old cells × 2 surfaces ×
2 sides BYTE-IDENTICAL**, 10 added, nothing renamed. `-Wall -Wextra` over all 50 `_Bool` cells × 2
sides: 0 failures, 0 warnings other than `-Wunused-parameter`.

### 8.4 The per-cell verdicts — and the ONE thing that must not be misread

⚠ **These ten rows were measured on the ORACLE `f7b65d8c`, which does NOT have clause (c).** That is
deliberate and it is this file's standing practice: the Ry axis was regenerated at `1bdaa60` *before*
Inc 3 for exactly this reason — *a table written after the implementation can only say that the
implementation agrees with itself*. So the ten rows are a table of DECLINES and **the diff they
produce when bd `wx8g` lands is the witness**.

| cell | ORACLE verdict | rolled-side message |
|---|---|---|
| `m_none_bilry_none_none_binv` | `UNROLLED-ONLY` | `control flow inside a loop body under quantum control` |
| `m_none_bilry_none_none_bcar` | `UNROLLED-ONLY` | same |
| `m_none_nbilry_none_none_binv` | `UNROLLED-ONLY` | same |
| `m_none_nbilry_none_none_bcar` | `UNROLLED-ONLY` | same |
| `m_none_bilprep_none_none_binv` | `UNROLLED-ONLY` | same |
| `m_none_bilprep_none_none_bcar` | `UNROLLED-ONLY` | same |
| `m_none_dilry_none_none_binv` | `UNROLLED-ONLY` | same |
| `m_none_bil2_none_none_binv` | `UNROLLED-ONLY` | same |
| `m_none_ddilry_none_none_binv` | `UNROLLED-ONLY` | ⚠ **`condition predates a non-diagonal gate`** — a DIFFERENT fence |
| `m_none_dilesc_none_none_binv` | `DECLINE-BOTH-DIFFERENT` | rolled the loop message; **flat** `nested control flow` |

**ZERO of the ten diverges.** The regeneration wrote without printing a refusal, which it cannot do
while any un-quarantined divergence or moved boundary control exists; `TRACE-DIVERGENCE` stayed at
29 against 29 quarantined. Nothing added to the quarantine (byte-unchanged, 29 rows);
`--refresh-quarantine` never run; `--regenerate` run once, to write the ten rows.

| divergent new cell | verdict | disposition |
|---|---|---|
| — (none) | — | — |

**What bd `wx8g`'s landing owes, written so the regeneration diff is CHECKED and not rubber-stamped**
(this is also in `EXPECTED_HEADER`, so it ships with the table):

* the **eight** loop-message rows → `ACCEPT-IDENTICAL`. Predicted from Track W's own probe table:
  `w_d` / `w_b2` / `w_g` / `w_k` all ACCEPT and all BYTE-IDENTICAL to their per-block twins.
* `m_none_ddilry_none_none_binv` → **unmoved**. Its rolled side declines at gate 2c, not at the loop
  fence: the post-loop diffusion `a = cq_theta(a, 0.9)` is a non-diagonal gate on the CONDITION's own
  wire. **Do not count it with the other eight**; if it flips, the cause is not clause (c) and must
  be found.
* `m_none_dilesc_none_none_binv` → **unmoved**. Its rolled side must go on declining.

⚠ **The escape cell is the safety pin of the increment — including in what it does NOT do.**
`ROLLED-ONLY` there (the rolled side accepting where its twin declines) *is* clause (c3) gone, and
clause (c3) gone is the 19-vs-27 leak: two entangled which-path rails of the condition's bits left
allocated per activation, at `opt` exit 0, verify-clean, STRICT 2b `0 violation(s)` (2b counts
`cqrt_alloc` sites; those rails are TEMPLATE-minted). A `TRACE-DIVERGENCE` there is the same thing.
Both are reds no table entry and no quarantine may bless.
**But this cell is not a TRACE witness.** Track W's 19-vs-27 pair is hand-written IR
(`trackW/probes/ir/il_{escape,noescape}_{rolled,flat}.ll`) whose flat side *accepts* at 27 lines;
this cell's flat side is `clang -O1` over two `{ }` repetitions that both write `last`, and it
declines `nested control flow` for a reason unrelated to the leak. So the row pins the DISPOSITION —
*the rolled side still refuses* — and the hand-IR pair keeps the trace. **Do not quote this cell as
if it measured 19 against 27.**

### 8.5 The header-deletion defect: checked again, mechanically, and it held

The `EXPECTED_HEADER` fix from §6 was exercised by this second `--regenerate`. Measured after it:

```
header lines: main(pre-uq96) 222 | c12a2afe 283 | now 316
MISSING vs c12a2afe : 0
MISSING vs main     : 0
```

Every header line that has ever been in this table is still in it, including the 54-line `b6ap`
Rule-13 ruling that the first regeneration ate. Both `--regenerate` calls in this branch went through
the constant.

### 8.6 Track W's confirmation of the §1.4 trap

Track W measured the eight CARRIED `prep` rows independently and reports all eight take the passing
move `DECLINE-BOTH-DIFFERENT → DECLINE-BOTH`, **zero `ROLLED-ONLY`**, and *by mechanism rather than
luck*: retiring the carve makes the rolled prep reach F1, which refuses it for the flat side's own
no-cloning reason. The trap note was right and it held — recorded here because a prediction that is
confirmed is worth as much as one that is not, and only one of the two usually gets written down.
