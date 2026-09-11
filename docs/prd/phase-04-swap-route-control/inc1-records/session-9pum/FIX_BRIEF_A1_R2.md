# Fix brief — Track A.1, after round-2 Rule-13 review `review_a1_r2.md` (verdict CLEAR-WITH-ITEMS)

Worktree `/Users/sorenwilkening/Desktop/CQ_trackA`, branch `compare-select-parity` (checkpoint b439944).
Read `review_a1_r2.md` in full (F-A1R2-1..5, the Q-1 and containment outcomes), then `FIX_A1_R1.md`,
`IMPL_A1.md`, and the reviewer's `review_a1_r2_probes/` (`run.sh`, README). You are the FIX agent (opus).
Do NOT commit/push; never write under `/Users/sorenwilkening/Desktop/CQ_lang/` or the other worktrees;
ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` + `libCQPass.so`. Report only what
you ran.

## F-A1R2-1 — narrow the `Covered` exemption (closes a PRE-EXISTING ×2 miscompile; decline-monotone)

`io3.c` (7.6 controlled I/O sink) and `gs1.c` (7.5 guarded Shadow store) mint their flag from a register a
sibling in-place Ry already relabelled and ACCEPT (byte-identical to the oracle); the kickback twin `io4.c`
declines. Cause: `Covered` exempts every taint-blind-visible gate on the ground "the classifier ruled on
it", but for these two consumers NO classifier wire walk ever runs (`lowerControlledIOSinks` runs before
`detectControlRegions`; `classifyGuardedStoreArm` returns before `condWireDisposition`;
`declineStaleRecordOps` excludes branch-condition compares on the premise ArmClassify owns their stale
check). `reverifyCmpCondReads` REACHES both (`io1`/`gs2` decline at rung (ii); `multi/io5.c` at rung (iii));
only the exemption stops it. Fix as the reviewer sketches: a per-entry bit on `CmpCondRead` — "a round-1
wire disposition was taken for this mint" — set at the mint ONLY by the callers that actually ran
`condWireDisposition`/the select ladder's gate 2c (enumerate the mint sites and say for each whether the
bit is set and why); `Covered` is passed only when the bit is set, else the re-ask is unexempted. It must
NOT cost the 12 in-loop accepts (all ArmClassify consumers — measure with the round-1 mutation harness) and
must turn `io3`/`gs1` ACCEPT→DECLINE with `condition predates a non-diagonal gate`. Fixtures: `io3`, `gs1`
declines (RED on the oracle AND on b439944), `io4` and the non-sibling I/O-sink / guarded-store accept
controls (GREEN on all). The orchestrator filed the pre-existing hole as a bd issue (grep `bd list` for
"7.6 controlled I/O SINK"); record its id in `FIX_A1_R2.md`.

## F-A1R2-2 — pin the live crossing (corrects Q-3)

`f4f.c` (`measure(h); xorc(h,9) in place; icmp(h,5)`) declines ONLY because `railWireNamesBackward`
crosses `taint.InPlaceRailOps`; control `f4h.c` accepts. Keep the crossing; pin both as fixtures (decline
RED on the oracle; accept control), and retire Q-3.

## F-A1R2-3 — the rail-path accept class is ≥5 plain-C members

`b1`,`b2`,`r3`,`b3`,`b4` — all correct. Rewrite IMPL §5 / BRIEF ERRATA: the increment is decline-monotone
on the COMPARE path; on the RAIL path the per-activation barrier admits the iteration-local class, with
these members measured (not "exactly two by name"). Pin `r3`/`b3`/`b4` as accepts if they add a distinct
shape (say which; do not add duplicates).

## F-A1R2-4 — the containment sentence

`blind ⊆ round-1 ⊆ final` is wrong twice: (a) it presumes a classifier walk (F-A1R2-1's consumers have
none — the per-entry bit is the repair); (b) the return-first walk never pushes a staling gate, so `Covered`
⊋ what round 1 examined. Rewrite the call-site comment with the reviewer's transitivity derivation
(review §Q-2: `condProvenance` seeds every tainted ancestor, so `round1 \ blind` is near-empty by
construction) and state precisely what the exemption now means with the bit: "a gate visible taint-blind
at a mint whose round-1 disposition was actually TAKEN by ArmClassify/SelectClassify".

## F-A1R2-5 — record hygiene

`FIX_A1_R1.md`/`IMPL_A1.md` say "not committed"; the tree is checkpointed at b439944 — correct the
sentences.

## Gates, in order

`lit --filter` → `ctest -R ir-pass-lit` → `ctest -j6 -R '^e2e-'` + `git status --porcelain tests/` →
corpus diff over the 1776 (compare path `0/0/0`; the two rail movers unchanged) → re-run BOTH reviewers'
probe corpora + the implementer's (every verdict listed; `io3`/`gs1`/`f4f` DECLINE; `io4`/`f4h` ACCEPT; the
12 in-loop accepts ACCEPT) → full `ctest -j6` ONCE (predicate changed; never relink under a measurement,
never `pkill` by pattern) → `cq-opt-equivalence-full`. Write `FIX_A1_R2.md`: per finding → change
(file:line) → fixtures → measurements; the mint-site table for the bit; open questions.

Final message ≤25 lines: per finding one line, the mint-site bit table (site → set?), gate lines verbatim,
movers, open questions.
