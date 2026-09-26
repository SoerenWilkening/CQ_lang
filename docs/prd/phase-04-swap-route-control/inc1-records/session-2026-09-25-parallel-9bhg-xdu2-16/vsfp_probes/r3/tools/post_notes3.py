#!/usr/bin/env python3
"""Fill and append the round-3 bead notes (bd update --append-notes, never --notes)."""
import pathlib
import subprocess

V = pathlib.Path(__file__).parent
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8"
SUB = {'@@C3@@': '00989266', '@@SUBJ@@': '3cb890ef25187b4b',
       '@@O1@@': 'KILLED (5 fixtures, through the postcondition)', '@@O2@@': 'KILLED (1)',
       '@@O4@@': 'KILLED (5, as the round-2 miscompile)', '@@O3@@': 'EQUIVALENT (0 of 2378)',
       '@@T1@@': 'KILLED (14)', '@@T2@@': 'KILLED (4)', '@@S1@@': 'KILLED (4)',
       '@@S2@@': 'MISSED over 2377, then KILLED by the new lowering_volatile_globalfold_equal_phi.ll (a dead TAINTED compare left as a dirty flag — C-reachable, single TU)'}
VSFP = ("ROUND 3 (commit 00989266, cq-opt 3cb890ef25187b4b; review records 0979276f). Both Rule-13 rounds on round 2 "
        "were NOT-CLEAR (r2A: otam, F-WA-2..5; r2B: tzfa, stl3, F-WB-3..5). Round 3: every volatile stage re-propagates "
        "when it changed the IR + declineStaleTaintSet (otam); resolvePhantomCloneArgReads neutralises every recorded-dead "
        "slot then declines an unread quantum operand (tzfa); the global fold's arm fold + the condition seed after every "
        "fold (stl3); cloneArgReachesResult asks the record (F-WB-3); false comments corrected at the source. Measured: lit "
        "2378 (2377 + 1 XFAIL); targeted ctest 99/99; 176-row battery (every r1A/r1B/r2A/r2B vsfp + r2A_9bhg probe vs its "
        "twin) 151 TRACE-IDENT, the rest attributed (pre-existing on all four binaries, equivalent, or the twin's verdict); "
        "corpus A/B over 3440 modules (lit + e2e + multi-TU + the five review probe dirs), null 0, oracle->r3 369 movers all "
        "own or twin-classified, r2->r3 76 movers all TRACE-IDENT/DECL-SAME with twins; mutants 7 killed, 1 equivalent "
        "(the postcondition), 0 missed after one new fixture. The C route to the phantom-read resolution is closed as far as "
        "measured; what reaches it is IR-only (branch-only reads). Pre-existing g12 divergence filed as bd 50ho. CLAUDE.md "
        "fenv sentence left to the owner with r2B's replacement text (TRACK §R3.8). NOT self-cleared: owes a Rule-13 round "
        "(TRACK §R3.13).")
BEADS = [('test_C_libtooling-otam', 'otam.txt'), ('test_C_libtooling-tzfa', 'tzfa.txt'),
         ('test_C_libtooling-stl3', 'stl3.txt'), ('test_C_libtooling-vsfp', None)]
for bead, f in BEADS:
    t = VSFP if f is None else (V / 'r3notes' / f).read_text().strip()
    for k, v in SUB.items():
        t = t.replace(k, v)
    if '@@' in t:
        raise SystemExit(f'{bead}: unfilled placeholder')
    r = subprocess.run(['bd', 'update', bead, '--append-notes', t], cwd=W, capture_output=True, text=True)
    out = (r.stdout + r.stderr).strip().splitlines()
    print(bead, r.returncode, out[-1][:100] if out else '')
