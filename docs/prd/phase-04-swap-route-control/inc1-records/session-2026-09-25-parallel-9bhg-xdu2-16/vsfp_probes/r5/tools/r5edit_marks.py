W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'
T = 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md'


def sub(path, old, new, n=1):
    p = W + path
    s = open(p).read()
    assert s.count(old) == n, (path, s.count(old), old[:70])
    s = s.replace(old, new)
    open(p, 'w').write(s)


sub('ir-pass/src/Specialization.cpp', '''  // fold cannot fire and no tainted value is created: the call only deletes dead
  // instructions, whose `cloneTaint` keys self-scrub (`ScrubOnDelete.h`), and none
  // of them is in `TaintedCloneCalls` (a clone call is a liveness root).''', '''  // fold cannot fire and no tainted value is created: the call deletes dead
  // instructions, whose `cloneTaint` keys self-scrub (`ScrubOnDelete.h`), none of
  // them in `TaintedCloneCalls` (a clone call is a liveness root), and REWRITES a
  // live inner call's rewritable dead-slot operand to a constant (step 3 — a
  // shrink, never a growth; r4A F-YA-3 corrected "only deletes").''')

sub(T, '''a logical `select i1` condition. SimplifyCFG's own `FoldTwoEntryPHINode` goes through the folder, which
returns `%c`; the fold now calls `simplifySelectInst` first (an existing value, never a new instruction).''',
    '''a logical `select i1` condition. SimplifyCFG's own `FoldTwoEntryPHINode` goes through the folder, which
returns `%c`; the fold now calls `simplifySelectInst` first (an existing value, never a new instruction).
⚠ **FALSE (bd w9xe, Rule-13 r4B F-YB-2, measured):** stock SimplifyCFG builds through
`IRBuilder<NoFolder>` and emits `select i1 %c, i1 true, i1 false`; the `-O1` twin loses it only in the
later InstCombine. The code is sound and the conclusion holds; the parity bar is SimplifyCFG + InstCombine.
Corrected at the source in round 5 (§R5.4).''')

sub(T, '''`foldVolatileConstGlobalLoads` had every conjunct but the last; it now skips a global with `hasSection()`,
`isAbsoluteSymbolRef()` or `!absolute_symbol`.''', '''`foldVolatileConstGlobalLoads` had every conjunct but the last; it now skips a global with `hasSection()`,
`isAbsoluteSymbolRef()` or `!absolute_symbol`. ⚠ **INCOMPLETE (bd qce6, Rule-13 r4B F-YB-1, a P1):**
`#pragma clang section bss=/data=/rodata=/relro=` sets an IMPLICIT section (global attributes the backend
honours) that `hasSection()` does not see, so an MMIO `static volatile int STATUS;` under the pragma still
folded in a quantum branch; and `isAbsoluteSymbolRef()` IS the `!absolute_symbol` test (the second test
was redundant). Round 5 adds `hasImplicitSection()` and refuses any non-default address space (owner
decision 2026-09-27) — §R5.3.''')
print('ok')
