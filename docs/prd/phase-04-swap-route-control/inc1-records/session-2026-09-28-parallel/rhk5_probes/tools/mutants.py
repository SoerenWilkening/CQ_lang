#!/usr/bin/env python3
"""mutants.py [NAME...] — build the bd rhk5 mutants in the scratch mutant tree.

Each mutant is ONE textual replacement in the scratch copy of the sources; the anchor
must occur EXACTLY ONCE or the script aborts (a mutant that silently fails to apply
measures nothing). The scratch tree is restored from the subject worktree after every
mutant. Binaries land in scratch/rhk5/bin as cq-opt.<NAME> + cq-opt-debugalloc.<NAME>
(the debugalloc copy is touched so lit's staleness fence accepts it).

The NULL mutant changes a COMMENT only; its binary must be BIT-IDENTICAL to the
subject tree's own build (checked) — otherwise the harness is measuring the build."""
import hashlib
import os
import shutil
import subprocess
import sys

W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9'
S = '/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/rhk5'
M = S + '/mut'
BIN = S + '/bin'
CW = 'ir-pass/src/ChainWalk.cpp'
UN = 'ir-pass/src/Uncomputation.cpp'

MUTANTS = {
    'N0_null': (CW, '// ── bd test_C_libtooling-rhk5 — see the header for the whole argument ────────',
                '// ── bd test_C_libtooling-rhk5 — see the header for the whole argument (null) ─'),
    'M1_trust_record': (CW, '    if (!formalLabelPreserved(*F, K, taint, Active))\n      return false;\n', ''),
    'M2_ccopy_dst': (CW, 'UC->arg_size() == 3 && Slot != 2 &&\n        UC->getArgOperand(2) != A)',
                     'UC->arg_size() == 3)'),
    'M3_no_clause3': (UN, '  if (cloneCallPreservesArg(M, P, taint))\n    return true;\n', ''),
    'M4_no_bprime': (CW, '  if (cloneCallPreservesArg(C, R, taint))\n    return true;\n', ''),
    'M5_skip_noncall': (CW, '    if (!UC || !UC->isArgOperand(&U)) {\n      Preserved = false;\n      break;\n    }',
                        '    if (!UC || !UC->isArgOperand(&U))\n      continue;'),
    'M6_unc_any_slot': (CW, '    if (isUncHandleSlot(N, Slot))', '    if (N.ends_with("_unc"))'),
    'M7_no_handle_mask': (CW, 'if (K >= F->arg_size() || K >= 64 || !((HandleSlots >> K) & 1))',
                          'if (K >= F->arg_size() || K >= 64)'),
    'M8_no_record': (CW, '  if (It == taint.SpecHandleArgMask.end())\n'
                         '    return false;  // not something the specializer recorded building.\n'
                         '  const uint64_t HandleSlots = It->second;',
                     '  const uint64_t HandleSlots =\n'
                     '      It == taint.SpecHandleArgMask.end() ? ~0ull : It->second;'),
}


def sha(p):
    return hashlib.sha256(open(p, 'rb').read()).hexdigest()[:24]


def build():
    r = subprocess.run(['cmake', '--build', M + '/build', '-j4', '--target', 'cq-opt', 'cq-opt-debugalloc'],
                       capture_output=True, text=True)
    if r.returncode:
        print(r.stdout[-3000:], r.stderr[-3000:])
        sys.exit('BUILD FAILED')


def main(names):
    base = sha(M + '/build/ir-pass/cq-opt')
    print('mutant-tree base cq-opt', base)
    for name in names or list(MUTANTS):
        f, old, new = MUTANTS[name]
        path = os.path.join(M, 'src', f)
        orig = open(path).read()
        n = orig.count(old)
        if n != 1:
            sys.exit(f'{name}: anchor found {n} times in {f} — refusing')
        open(path, 'w').write(orig.replace(old, new, 1))
        try:
            build()
            h = sha(M + '/build/ir-pass/cq-opt')
            if name.startswith('N0'):
                if h != base:
                    sys.exit(f'{name}: NULL mutant binary {h} != base {base} — the harness measures the build')
            elif h == base:
                sys.exit(f'{name}: mutant binary IDENTICAL to base — the mutation did not take')
            shutil.copyfile(M + '/build/ir-pass/cq-opt', f'{BIN}/cq-opt.{name}')
            shutil.copyfile(M + '/build/ir-pass/cq-opt-debugalloc', f'{BIN}/cq-opt-debugalloc.{name}')
            os.chmod(f'{BIN}/cq-opt.{name}', 0o755)
            os.chmod(f'{BIN}/cq-opt-debugalloc.{name}', 0o755)
            os.utime(f'{BIN}/cq-opt-debugalloc.{name}')
            print(f'{name}: built {h}')
        finally:
            open(path, 'w').write(orig)
    build()
    if sha(M + '/build/ir-pass/cq-opt') != base:
        sys.exit('restored tree does not rebuild to the base binary')
    print('restored; base rebuilt identical')


if __name__ == '__main__':
    main(sys.argv[1:])
