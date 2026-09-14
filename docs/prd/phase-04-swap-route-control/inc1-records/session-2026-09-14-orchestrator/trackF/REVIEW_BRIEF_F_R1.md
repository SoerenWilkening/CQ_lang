# Track F — ADVERSARIAL REVIEW round 1 (Rule 13), bd `om35` — the φ-DESCENDANT conjunct in F2

**Subject:** branch `f2-phi-descendant`, tip `baad186d45a4cc843c8717da70be3f8e1f7f6bab`, worktree
`/Users/sorenwilkening/Desktop/CQ_f2phi`. Its binary: `cq-opt`
`147cb3d69afd816d15eaea84e3d802f3a5b4105431508886583b442bfa7736e4`.
**ORACLE** (main checkout `build/`): `cq-opt` `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`,
`libCQPass.so` `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`.

**FIRST ACT: `shasum -a 256` on both.** A mismatch is a FINDING and you STOP.

**READ FIRST:** `$SES/PROTOCOL.md`, `$SES/trackF/BRIEF_F_IMPL.md` (the owner's ruling and its reasoning),
`$SES/trackF/SCOPE_F.md` **including the ERRATUM block now at its top**, and — in the subject worktree —
`IMPL_F.md` in full. Then `CLAUDE.md` CORRECTNESS RISK §2 (F1/F2), §3 **L5** (*a syntactic answer to a
semantic question loses* — F2 lost **four rounds running** to exactly this), §4 (the previous F2 narrowing's
disclosure paragraph and its retirement triggers), Rules 2, 9, 10, 11, 13, 19.

## What was built

**One conjunct at F2's TEST** (`ArmClassify.cpp:1813`), one file-local helper, one set built once per call —
**23 non-comment lines**. `PhiDesc` is the transitive SSA **user** closure of the region's own state-prep
merge φ, seeded with the φ itself. A pinned value in `PhiDesc` is **not** treated as a collider.

**The stated ground is AVAILABILITY, not "the same wire"** — and the author says the wire reading is false
here, which is why `CondWire` never covered it: F2's register can occupy exactly two slots; the φ is defined
at the join, so a value using it is available at **neither** (the φ does not dominate the arm; the pred slot
would be use-before-def). The claim is that it removes a **witness**, not a decline.

**L1: the author states there is NO record** — the set is recomputed from `Region.Merge` on every call, so
both rounds are correct by construction; no `WeakTrackingVH` hazard, no forgotten-emitter window.

**Measured by the implementer:** 29 of 29 F2-declining fixtures still decline, MOVED 0; of the 1930 shipped
fixtures exactly ONE moved and it is the one they added; corpus sweep 2086 modules with full-stderr byte
compare, 7 movers, 0 unattributable; `ir-pass-lit` Passed (1930); injection matrix 12 mutations, MISSED 0,
N/A 0; duplicate-body scan 9 groups, all pre-existing. Customers: the owner's three-bool file (both
spellings), `vd.c`, `w3_runtime_a.c` and an N=4 cascade all go F2-decline → **exit 0**.

## THE ROUND-1 ASSIGNMENT — the author named it and could not close it

> **Can `-O1` rewrite a source value that did NOT depend on the region's merge φ into a module value that
> DOES?**

That is L5's exact shape. If the answer is yes, the conjunct excludes a value that in the **source** was a
genuine collider, and the fence loses a real witness — an **over-ACCEPT**. The author walked Rule 9's list
and names **two thinnest places, closed in neither direction**:

* the **sideways / downward compare rewrite** — can a guard move from the **pre**-region register onto the
  **post**-region one? (`CLAUDE.md` Rule 9: `-O1` *"rewrites a compare sideways onto a sibling or downward
  onto an ancestor of the register IPSCCP actually pinned"*, and F2 rounds 2–3 were lost to exactly that.)
* **jump threading.**

**Attack both.** Construct, in plain C at `-O1`, a program whose guard is written against the pre-region
register and which `-O1` rewrites into a φ descendant. If you cannot construct one, say precisely what you
tried and why you believe the rewrite is impossible — *"I could not build one"* is a finding of limited
strength and must be labelled as such (L5: when you cannot bound something, say what is skipped and why the
**compiler** could not have folded it either).

## The rest of the surface

1. **The availability argument itself.** Is it true that a φ descendant is available at *neither* slot? Probe
   a φ in a block that also dominates something F2 anchors on; a φ whose region is nested; a φ used by a
   value that is ALSO reachable without the φ (a `select` or `phi` merging a φ-dependent and a
   φ-independent operand — does the transitive **user** closure over-approximate in the safe direction or
   the unsafe one?).
2. **The rival that must still decline.** `control_inplace_ry_reject_stateprep_nonphidesc_collider.ll` pins
   the guard computed from the **pre**-region register. Verify it declines on **both** binaries and that it
   is **not vacuous** (Rule 12(c); run `$PREV/trackM/probes/impl/vacuity.py` over the new accept batch, and
   check every generated `.ll` is non-zero — the author's own scoping was bitten by exactly that, see the
   SCOPE_F erratum).
3. **`Region.Merge` — can it reach F2 as a φ of something else?** The author lists this as an open L1
   residual. A φ that is a region's `Merge` in one round and something else's in another; a peeled φ
   (`MergePhiPeel` manufactures values and grows taint); a φ whose region is claimed only in round 2.
4. **Interaction with the other landings in flight.** Track P (bd `3qps`/`4aiu`) widened the φ leaf grammar
   in `ArmClassify.cpp`'s kickback classifier and `SelectClassify`; Track U (bd `z9t1`) normalizes undef
   seeds to a concrete zero **before classification**, which changes what F2 sees as a seed. You measure the
   **Track F binary only** — but name any interaction the merge gate must test, especially: does a
   normalized zero seed make a φ-descendant collision reachable that was not before?
5. **The disclosure paragraph.** The author claims this narrowing absorbs **no rival program**, unlike the
   2026-09-11 one. Read §4 of `CLAUDE.md` for the words that claim must be made in, and verify it: is there
   a program the ORACLE refused, that now compiles, whose *other* reading has a lowering to be robbed of?

## Verdict — `$SES/trackF/REVIEW_F_R1.md`

Findings **F-F1-<n>**: one-line claim, probe (path + exact commands + both verdicts), severity
(**over-ACCEPT / silent miscompile** · **over-DECLINE** · **fixture/record hygiene** · **documentation**),
minimal fix. End **CLEAR** / **CLEAR-WITH-ITEMS** / **NOT CLEAR**, and state plainly what you did not
examine. Probes into `$SES/trackF/review_r1_probes/` in the MAIN checkout.

## Limits (PROTOCOL matrix — reviewer row)

NO build, NO suite; at most ONE lit fixture re-run. Never write under
`ir-pass/ include/ runtime/ tests/ tools/` of any checkout. Never relink under a running measurement; never
`pkill` by pattern. ⚠ **Do NOT run a corpus sweep** — at most ONE is in flight across the session and it
belongs to the merge gate (bd memory `one-corpus-sweep-at-a-time-load-ceiling`); the box has been at load
330–574 and two tracks' sweeps failed to finish because of it. Rule 2: verify-clean is not evidence; read
emitted STREAMS.
