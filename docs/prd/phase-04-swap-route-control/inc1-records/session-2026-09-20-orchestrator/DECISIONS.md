# DECISIONS — session 2026-09-20

## OWNER RULINGS OBTAINED AT OPEN (the three batched from `$PREV/DECISIONS.md`)

**Q1 — bd `h1ip`, the GUARDED / rotated loop: HOIST IT, and ACCEPT THE DEAD
ALLOC.** The promotion's `cqrt_alloc_<W>(seed)` moves ABOVE the loop's zero-trip
guard, so a loop that runs zero times allocates a register it never uses. The
owner took that cost explicitly. It is a Rule-6 accepted leak (left allocated,
never freed dirty), and it is what makes a RUNTIME trip bound beside a carried
handle lower instead of declining.
⚠ This is an ACCEPT-direction widening and it owes its own Rule-13 round and its
own rolled-vs-unrolled probe with a trailing non-diagonal gate (the carried
protocol item 4).

**Q2 — bd `11qv`, the NARROW-WIDTH carried handle: FOLD IT INTO THE bd `h7ee`
ROUNDS.** Build the `mutateType(i32)` widening at the promotion and let rounds 2
and 3 attack it as part of bd `zujr`'s surface, rather than spending a separate
review cycle on it.
⚠ THE HAZARD THE OWNER ACCEPTED, STATED SO IT IS NOT FORGOTTEN: Rule 13 says a
round that reviews code it helped write does not clear it. The mitigation taken
here is that rounds 2 and 3 are INDEPENDENT AGENTS that did not write the
widening, and the round that attacks `11qv` is told what it is looking at. A
round run by the implementer would not satisfy this ruling.

**Q3 — bd `3slt` / bd `s82e`: DECIDE WHEN THE WALL ACTUALLY MOVES.** Nothing is
ruled on the hypothetical. `loop_carried_handle_reject_postloop_rotation.ll`
stays a filed tripwire against bd `s82e`, with the red-green pair named in its
own header.
⚠ THE RISK THE OWNER ACCEPTED: the wall (bd `r903` / bd `fg9k`, the 4.4 select on
a bare `i1`) may move in a session that never reads the tripwire. The mitigation
owed by THIS session is to make the tripwire hard to miss from the r903/fg9k
side, not merely from its own file — see this session's records.
