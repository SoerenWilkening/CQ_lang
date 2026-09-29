#!/usr/bin/env python3
"""mutants_r2.py [NAME...] — bd rhk5 ROUND 2: mutants of the NEW conjuncts only
(8 + a null), built in the scratch mutant tree exactly as mutants.py builds round 1's:
one textual replacement per mutant, anchor required EXACTLY ONCE, NULL binary
bit-identical to the base, tree restored and rebuilt identical at the end. The base
tree must first be synced to the subject (mut_setup.sh)."""
import sys

sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import mutants as M  # noqa: E402  (reuse build/sha/restore machinery)

CW = 'ir-pass/src/ChainWalk.cpp'
UN = 'ir-pass/src/Uncomputation.cpp'
M.MUTANTS = {
    'N0_null': (CW,
                '// ── bd test_C_libtooling-rhk5 — see the header for the whole argument ────────',
                '// ── bd test_C_libtooling-rhk5 — see the header for the whole argument (null) ─'),
    # fb5y F-r1A-1: trust a name-shaped callee even when the module DEFINES it.
    # ⚠ FIRST SPELLING (`if (UCallee) {`) was NOT a re-opening of fb5y: it sent EVERY
    # defined callee — the recorded inner clones included — into the name vocabulary,
    # which refuses a `__cq_q_*` name, so the walk refused at the first inner clone and
    # never reached the evil call (measured: killed 2 nested ACCEPTS, left the fb5y leak
    # fixture green). Re-spelled as the round-1 behaviour exactly: a DEFINED callee
    # whose NAME is a forward template producer is admitted by that name.
    'R1_name_trusts_defined': (CW, '    if (UCallee && UCallee->isDeclaration()) {',
                               '    if (UCallee && (UCallee->isDeclaration() || isTemplateProducer(UC))) {'),
    # fb5y F-r1A-2: accept an interposable (weak) definition.
    'R2_interposable_ok': (CW, '  if (!F || !F->hasExactDefinition() || F->isVarArg())',
                           '  if (!F || F->isDeclaration() || F->isVarArg())'),
    # tcpq: a CYCLE licenses itself (co-inductive "yes").
    'R3_cycle_licenses': (CW, '  if (is_contained(Ctx.Stack, Key) || Ctx.Stack.size() >= kMaxCloneNesting)\n'
                              '    return Proof::NoProvisional;',
                          '  if (is_contained(Ctx.Stack, Key))\n'
                          '    return Proof::Yes;\n'
                          '  if (Ctx.Stack.size() >= kMaxCloneNesting)\n'
                          '    return Proof::NoProvisional;'),
    # the nesting cap, deleted.
    'R4_no_depth_cap': (CW, '  if (is_contained(Ctx.Stack, Key) || Ctx.Stack.size() >= kMaxCloneNesting)',
                        '  if (is_contained(Ctx.Stack, Key))'),
    # the nesting cap, one lower.
    'R5_cap_15': (CW, 'constexpr unsigned kMaxCloneNesting = 16;',
                  'constexpr unsigned kMaxCloneNesting = 15;'),
    # (B3) via isCopyGate: admit the copy DESTINATION.
    'R6_copy_dst_admitted': (CW, '        if (Slot != Last && UC->getArgOperand(Last) != A)',
                             '        if (true)'),
    # kyy1 per-component fallback: the whole (b′) plan always wins.
    # ⚠ FIRST SPELLING WAS EQUIVALENT BY CONSTRUCTION (`bool FullWins = true;`): the
    # superset loop right below still ran and reset it, so the mutant only differed when
    # the pieces discharge nothing — where the fallback pushes nothing either. Measured
    # 0 failures and diagnosed from the code; re-spelled so the fallback branch is dead.
    'R7_whole_plan_always': (UN, '        if (!FullWins) {\n          for (ComponentPlan &Q : PiecePlans)',
                             '        if (false) {\n          for (ComponentPlan &Q : PiecePlans)'),
    # kyy1 per-component fallback: the pieces always win.
    'R8_pieces_always': (UN, '        bool FullWins = Ok;', '        bool FullWins = false;'),
}
# R9 (function-level backstop disabled) is run separately — see TRACK §R2.6.
M.MUTANTS['R9_no_function_backstop'] = (UN, '  for (ComponentPlan &P : OnIsSuperset ? On : Off)',
                                        '  for (ComponentPlan &P : On)')

if __name__ == '__main__':
    M.main(sys.argv[1:])
