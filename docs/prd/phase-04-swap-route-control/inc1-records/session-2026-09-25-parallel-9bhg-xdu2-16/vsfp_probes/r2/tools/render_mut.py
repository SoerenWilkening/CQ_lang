#!/usr/bin/env python3
"""Render the round-2 mutation matrix (mutmatrix4 over 2361 fixtures, mutmatrix5 over
2363 for the rows it re-ran) as a markdown table: mutant, what it removes, failed count,
up to four killing fixtures, verdict."""
import pathlib
import re

V = pathlib.Path(__file__).parent
WHAT = {
    'N0_null': 'NULL CONTROL: a comment in `dropDeadCallArguments`; binary == subject',
    'R1_drop_off': 'the drop never runs (both slots)',
    'R2_no_fixpoint': 'the drop makes one turn per slot',
    'R3_constants_too': 'the drop revisits constant operands (termination)',
    'R4_all_args_dead': 'every parameter reported dead',
    'R5_use_empty_mask': 'round 1\'s `use_empty()` instead of liveness',
    'R6_naked_too': '`naked` callees eligible',
    'R7_musttail_too': '`musttail` sites eligible',
    'R8_no_attr_strip': '`range`/`nofpclass` not stripped',
    'R9_no_intrinsic_skip': 'front-end intrinsic sites not skipped by the drop',
    'R10_no_deadcall_seeds': 'unused calls to definitions not seeded',
    'R11_no_slotB': 'slot B (after the fenv stages) removed',
    'R12_varargs_too': 'variadic callees eligible',
    'L1_calls_always_roots': 'every call is a liveness root (round 1\'s "never a call")',
    'L2_no_frontend_membership': 'no root by front-end MEMBERSHIP',
    'L3_no_clone_root': 'no root by specializer RECORD',
    'L4_no_body_purity': 'no body rule (attributes only)',
    'L10_no_reserved_name': 'no root by RESERVED NAME',
    'L11_no_identity_roots': 'no identity roots at all (membership, record, name)',
    'L5_loops_pure': 'body rule admits cyclic bodies',
    'L6_no_recorded_dead_slot': 'the call-slot rule never fires',
    'L7_no_fold': 'no empty-arm fold',
    'L8_no_phi_fold': 'no two-entry-φ fold',
    'L9_no_block_merge': 'no merge after the φ fold',
    'V1_no_erase_cone': 'the store erasure leaves its cone',
    'V2_no_promote_cone': 'the promotion leaves its residue',
    'V3_no_constfold_arm': 'the const-alloca fold does not fold what it emptied',
    'V4_erase_arm_untouched': 'the erasure does not report the blocks it emptied',
    'B1_backstop_off': 'the backstop never fires',
    'B2_no_theta_exempt': 'no `cq_theta`-result exemption',
    'B3_no_keeper_check': 'no "kept alive elsewhere" check',
    'B4_ignore_quantum': 'classical operands declined too',
    'B5_scan_clone_bodies': 'clone bodies scanned',
    'B6_no_record': '`buildClone` records nothing',
    'D1_d0_off': 'M-C arm (d0) off',
    'D2_d0_any_slot': '(d0) settles every slot',
}
VERDICT = {
    'N0_null': 'null: 0 moved (binary hash = subject)',
    'L2_no_frontend_membership': 'EQUIVALENT since L10: every front-end site\'s callee name starts with `cq_` (membership ⊂ reserved name); L11 kills',
    'L3_no_clone_root': 'EQUIVALENT (doubly covered): a clone\'s name starts with `__cq_` (reserved root) and its body has calls (not body-pure)',
    'B5_scan_clone_bodies': 'EQUIVALENT by construction: the backstop\'s quantum test reads MODULE taint, which does not describe clone-body values (probe `nested_clone_phantom.ll`: subject = mutant = oracle stream)',
}
rows = {}
for f, den in (('mutmatrix4.txt', 2361), ('mutmatrix5.txt', 2363)):
    for l in (V / f).read_text().splitlines():
        m = re.match(r'^(\S+) discovered=(\d+) seen=(\d+) failed=(\d+) :: (.*)$', l)
        if not m:
            continue
        name, d, seen, failed, rest = m.groups()
        kills = [x.split(':', 1)[1] for x in rest.split() if ':' in x]
        rows[name] = (int(d), int(failed), kills)
out = ['| mutant | removes | discovered | failed | killed by (first 3) | verdict |', '|---|---|---|---|---|---|']
killed = missed = equiv = 0
for name in WHAT:
    if name not in rows:
        continue
    d, failed, kills = rows[name]
    if name == 'N0_null':
        v = VERDICT[name]
    elif failed:
        v = 'KILLED'
        killed += 1
    elif name in VERDICT:
        v = VERDICT[name]
        equiv += 1
    else:
        v = '**MISSED**'
        missed += 1
    k = ', '.join('`' + x.replace('.ll', '') + '`' for x in kills[:3]) + (' …' if len(kills) > 3 else '')
    out.append(f'| {name} | {WHAT[name]} | {d} | {failed} | {k} | {v} |')
out.append('')
out.append(f'**{killed} KILLED, {equiv} EQUIVALENT (argued, each with its reason), {missed} MISSED** over '
           f'{len([n for n in WHAT if n in rows]) - 1} real mutants + the null.')
(V / 'fill/MUT_TABLE.md').write_text('\n'.join(out) + '\n')
print(killed, equiv, missed)
