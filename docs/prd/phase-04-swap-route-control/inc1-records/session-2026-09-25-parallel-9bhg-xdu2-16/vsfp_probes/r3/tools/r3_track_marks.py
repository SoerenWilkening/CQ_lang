p = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md'
s = open(p).read()
R = [
("| SLOT A | no stage has READ the dropped operand (no mask, no rail, no record keyed on it) | nothing runs before it | no (shrinks; `propagate` restarts) |",
 "| SLOT A | no stage has READ the dropped operand (no mask, no rail, no record keyed on it) | nothing runs before it | ⚠ **YES, it can** (r2A F-WA-2 #3: its fold can mint a tainted `select`); the `propagate` restart it already performs is the whole obligation — right conclusion, wrong ground (§R3.6) |"),
("| (5) const fold + arm fold | an arm it emptied has no effect (it is empty) and a φ fold's incomings are available at the branch | the fold runs inside the stage, on blocks the stage just emptied; nothing between | no; the fold's `select` is on values already present |",
 "| (5) const fold + arm fold | an arm it emptied has no effect (it is empty) and a φ fold's incomings are available at the branch | the fold runs inside the stage, on blocks the stage just emptied; nothing between | ⚠ **FALSE — YES** (bd otam, r2A F-WA-1/F-WA-2 #2): a `select` on a TAINTED condition is a new tainted value, and round 2 never re-propagated. Round 3: re-`propagate` on a true return (§R3.2) |"),
("| (6) erase + cone | the cone is DEAD under liveness at this point | liveness is computed at the call; the deleted instructions are dead by definition; front-end sites are roots | no; deleted keys self-scrub (`ScrubOnDelete`) |",
 "| (6) erase + cone | the cone is DEAD under liveness at this point | liveness is computed at the call; the deleted instructions are dead by definition; front-end sites are roots | ⚠ **FALSE — YES** (bd otam, r2A `stale3a/b/c`, `loop2`): the arm fold behind the cone deletion mints a tainted `select`. Round 3: re-`propagate` on a true return (§R3.2) |"),
("Its C-reachable customer count is **zero** as far as measured — ⚠ after one was FOUND and removed",
 "⚠ **FALSE (r2B F-WB-2, bd stl3): the C-reachable count was NOT zero** — every `(void)K` / `__builtin_expect` / `? K : 0` spelling on a volatile GLOBAL reached this fence (the global fold had no arm fold), and a keeper made it ACCEPT a Rule-8 wrong unitary (bd tzfa). Corrected in §R3. Its C-reachable customer count is **zero** as far as measured — ⚠ after one was FOUND and removed"),
]
for a, b in R:
    assert s.count(a) == 1, a[:60]
    s = s.replace(a, b)
open(p, 'w').write(s)
print('ok')
