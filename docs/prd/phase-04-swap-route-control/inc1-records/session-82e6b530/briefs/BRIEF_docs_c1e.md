# BRIEF_docs_c1e — fold the review_c1e lens items (F-C1E-1..4) into branch `c1-round4` @ aa9d702 before the landing
Read `$SP/briefs/BRIEF_common.md`, `$SP/briefs/BRIEF_rebase_c1d.md`, `$SP/progress/rebase_c1d.md` (the rebase agent's
record) and `$SP/progress/review_c1e.md` IN FULL (the lens; verdict CLEAR-WITH-ITEMS; its reproducers under
`$SP/progress/review_c1e_work/`). Agent name: `docs_c1e`. Model: opus. Progress file `$SP/progress/docs_c1e.md`.
Worktree `$SP1/wt/c1d` (branch `c1-round4` at aa9d702, built, current) is YOURS. The full `ctest` on aa9d702 was
367/367 (`$SP/progress/orch_full_ctest_c1e.log`); the orchestrator re-runs it after you hand back. NO code change
is licensed by this brief — comments, docs, and ONE additive lit fixture only.

## F-C1E-1 (coverage; the one item with a fixture)
The new fixture `control_phase_kickback_mixed_value_merge_preadd_inloop.ll` is cited at TWO shipped sites as the
MEASUREMENT behind "the commit cannot reach an Inc-2 chain head" — `LoopLowering.cpp` `commitOutOfLoopInPlaceOps`'
in-source argument ("MEASURED rather than argued, on the rebased tree: … `HCNT` …") and `ArithLowering.cpp:~709`
(the CONSUMER-2 comment). The lens built a G6/G7-disabled mutant: `control_swap_value_ifelse_head_out_of_place.ll`
goes RED on it (the net is real and pinned THERE), but the new fixture and both e2e goldens stay GREEN — because `-O1`
reassociates `(p+3)*5` into `p*5+15`, so `p`'s only chain user is a `mul`, which `inPlaceValueRailOperand`'s
add/xor-only shape half refuses whatever G6/G7 answer. The `HCNT-NOT` lines are therefore unfalsifiable by that pair.
Do THREE things:
1. Rewrite both comments so they cite `control_swap_value_ifelse_head_out_of_place.ll` as the pin of the G6/G7 net,
   and describe the q4b fixture's `HCNT` for what it IS (the head is out of place in this shape because G2's SHAPE half
   refuses a `mul` — not because of G6/G7). Do not delete the HCNT prefix; correct what it is said to prove.
2. Add ONE lit accept fixture that DOES discriminate: the lens's `a22` — a value diamond whose chain head is a dtzb-shaped
   `add` (`if (q>3){ r = p+3; r = r^9; }`) with a preadd on the merge out-rail and D4's per-bit loop
   (source `$SP/progress/review_c1e_work/a/a22*.c`; read its stage-1 module). Derive assertions from the subject's
   output; prefix conventions as its siblings (one `%cq-opt` spawn, CHECK/ACNT/MDCNT/NOROUTE pure-negative/PCNT/XCNT/
   FCNT/UCNT/RYCNT, handles derived from the output) PLUS the discriminating block: `cqrt_copy_i32_controlled`'s two
   copy SOURCES are DISTINCT rails and there is NO in-place `cqrt_addc`/`cqrt_xorc` on `p`'s rail (the lens measured both
   copies collapsing onto one register on the mutant). Name: `control_phase_kickback_mixed_value_merge_dtzb_head_preadd_inloop.ll`.
   Red-green: RED on main's binary (`$SP/bin/main-258d974/`, the leak: CHECK/FCNT/UCNT), GREEN on the subject. You
   cannot rebuild the lens's mutant cheaply — state in the header that the G6/G7 discrimination is the lens's MEASUREMENT
   (`review_c1e` F-C1E-1, `$W/mut_g67`) and that this fixture pins the two-distinct-sources property the mutant breaks.
   Run the injection matrix (`$SP/progress/rebase_c1d_work/inj.py`) over the new fixture too: 0 MISSED / 0 DIRTY.
3. Register nothing new in e2e (no slice); the lit fixture is the pin.

## F-C1E-2 (LEAK, pre-existing, byte-identical to main — record only)
Six plain-C spellings where the preheader op's PARENT has a second unlowered tainted user (the commit correctly refuses
via G7 arm (e) or G6, and the O(K) leak stays, byte-identical to `main` 258d974): `a1` (dtzb head read by the loop),
`a2` (preadd on the value arm's SOURCE `p`), `a3` (preadd on the chain-final), `a4`/`a17` (merge `%out` feeding TWO loops
— 8/0 on main, 8/4 on the subject: loop 1 now discharges), `a9` (pre-op value measured later — the `x2_preadd_keep`
control), `a11` (4.4 select). The diffusion variant `a16` declines loudly `cq controlled lowering: control flow under
quantum control` on all three binaries, so none is a wrong unitary. Record them: notes **§3.15** (a short subsection with
the table, reproducer paths copied into `inc1-records/c1-round4/` as `c1e_a{1,2,3,4,9,11,16,17}_*.c` with a README line
each), PRD §0 **E2**'s residual list gains ONE line naming the class ("a preheader in-place op whose PARENT has a second
unlowered tainted user — six measured spellings, review_c1e F-C1E-2, disclosed, OQ-C1D-1's class one shape over"),
and bd `3qlq.13`'s subject list (write the sentence in `$SP/progress/docs_c1e.md` under `## FOR THE BD UPDATE`; the
orchestrator applies it — you do not touch bd).

## F-C1E-3 (DOC): four of the lens's twins are UNFAITHFUL (`p ^ c` / `p + c` with `c`'s low bits clear: `-O1`
distributes the bit test onto the PRE-op register on the UNROLLED side only — the OQ-27 `m_xor_range` class); members
`a8/a10/a15/a17`. One sentence in notes §3.15 so a later round does not file them as compiler defects; note `q4b`'s `+7`
is immune.

## F-C1E-4 (DOC): `inc1-records/session-82e6b530/rebase_c1d.md` claims a `grep -rn 'session-adc5590a/fix_c1d.md'` → 0
hits; measured 5, all prose. Correct the sentence in the record (the deletion is right; no live cross-reference points
at the missing path).

## Record + gates + hand back
Copy `$SP/progress/review_c1e.md` → `inc1-records/session-82e6b530/review_c1e.md`, `$SP/progress/investigate_eqpx.md` →
`inc1-records/session-82e6b530/investigate_eqpx.md`, and `$SP/briefs/BRIEF_{review_c1e,investigate_eqpx,docs_c1e}.md` →
`inc1-records/session-82e6b530/briefs/`; extend that dir's README.md (one line per file). Update
`session-adc5590a/README.md`'s round-4 section and `NEXT_SESSION_PROMPT.md`'s state line to say the lens on the rebased
tree returned CLEAR-WITH-ITEMS (F-C1E-1..4, applied) and the full suite was 367/367 at aa9d702.
Rebuild BOTH targets (comment edits in LoopLowering/ArithLowering change mtimes; a stale binary is FALSE GREEN), confirm
`find … -newer` EMPTY, then: `lit --filter 'control_phase_kickback_mixed_value_merge'` (both fixtures),
`ctest -R ir-pass-lit` (background) → green but the XFAIL, re-measure `ls ir-pass/test/*.ll | wc -l` (expect 1691) and
update the count lines you touch by command. Commit per step (`wip(c1-round4): …`). Do NOT push, do NOT touch bd, do NOT
run the full ctest. Hand back: files changed, the red-green result for the new fixture, the injection result, lit count,
the tip hash, and the `## FOR THE BD UPDATE` sentence.
