#!/usr/bin/env python3
"""Build the math.h bundle that tools/cqc injects (bd 3c6m.72).

The bundle is one bitcode module holding the openlibm bodies for every math.h
spelling, resolved as the coverage census resolves them
(`full_surface/wprobe.build_defmap`): hardware-mapped names forward to their
LLVM intrinsic and openlibm's `.set` aliases become real definitions. A name
with a direct backend route at a width (`sin` on a double, Bennett.jl as
reference) forwards to its intrinsic too, so a lifted body that calls it
reaches the same one-call lowering as a user's call (bd 3c6m.78). Every other
body is openlibm's source: CQ ships no C implementation of a math function.

Every definition is renamed `__cq_libm_<name>`, so linking the bundle into a
user module never changes which function a classical call reaches: the pass
retargets only a call with a quantum operand to the bundle, then erases the
bodies nothing uses.

Usage:
    libm_bundle.py --openlibm <src-tree> --bc <corpus-dir> --out <bundle.bc>
                   [--expect-commit <sha>]
The corpus is built by full_surface/build_corpus.py from the same tree. The
build runs both (CMakeLists.txt, target cq_libm_bundle).
"""
import argparse
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
PREFIX = '__cq_libm_'
LIBC_EXTERNALS = {'__maskrune', '__memset_chk'}


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--openlibm', type=Path, required=True)
    ap.add_argument('--bc', type=Path, required=True)
    ap.add_argument('--out', type=Path, required=True)
    ap.add_argument('--expect-commit', default='',
                    help='Refuse an openlibm checkout at any other commit.')
    a = ap.parse_args()
    if a.expect_commit:
        head = subprocess.run(['git', '-C', a.openlibm, 'rev-parse', 'HEAD'],
                              text=True, capture_output=True).stdout.strip()
        if head != a.expect_commit:
            sys.exit(f'libm_bundle: openlibm at {head or "<not a git checkout>"}, '
                     f'expected {a.expect_commit}')
    # wprobe reads the corpus location from the environment at import time.
    os.environ['BC'], os.environ['OPENLIBM'] = str(a.bc.resolve()), str(a.openlibm.resolve())
    sys.path[:0] = [str(HERE/'library_coverage'), str(HERE/'library_coverage/full_surface')]
    import probe as P
    import wprobe as WP

    names = sorted({spec['base'] + suf for spec in P.MATHH_SPEC
                    if 'macro' not in spec['flags'] for suf in spec['variants']})
    defmap = WP.build_defmap(direct=True)
    missing = [n for n in names if n not in defmap]
    with tempfile.TemporaryDirectory(prefix='cq_libm_bundle_') as td:
        wd = Path(td)
        # A stub that references every spelling, so the closure link pulls in
        # each body and everything it reaches.
        stub = ''.join(f'declare void @{n}()\n' for n in names if n not in missing)
        refs = ', '.join(f'ptr @{n}' for n in names if n not in missing)
        count = len(names) - len(missing)
        (wd/'stub.ll').write_text(f'@__cq_libm_refs = global [{count} x ptr] [{refs}]\n' + stub)
        subprocess.run([WP.AS, wd/'stub.ll', '-o', wd/'stub.bc'], check=True)
        linked, err = WP.closure_link(wd/'stub.bc', defmap, wd)
        if linked is None:
            sys.exit(f'libm_bundle: closure link failed: {err}')
        ir = subprocess.run([WP.DIS, linked, '-o', '-'], text=True,
                            capture_output=True, check=True).stdout
    ir = re.sub(r'^@__cq_libm_refs = .*\n', '', ir, flags=re.M)
    # `signgam` is the program's variable, not the library's: lgamma's quantum
    # twin must write the same object its classical twin (the system libm) does.
    ir = re.sub(r'^@signgam = [^\n]*?global (i32) [^\n]*$', r'@signgam = external global \1, align 4',
                ir, flags=re.M)
    # The .set/.weak_reference aliases are already real definitions (build_defmap).
    ir = re.sub(r'^module asm .*\n', '', ir, flags=re.M)
    defined = set(re.findall(r'^define [^@\n]*@([\w.$]+)\(', ir, re.M))
    defined |= {m.group(1) for m in re.finditer(r'^@([\w.$]+) = (?!external)', ir, re.M)}
    undefined = set(re.findall(r'^declare [^@\n]*@([\w.$]+)\(', ir, re.M))
    undefined = {u for u in undefined if not u.startswith('llvm.')}
    # libc helpers (nan's string parsing, fortified memset) stay external: they
    # are classical, and a quantum operand reaching one still fails loudly.
    if undefined - LIBC_EXTERNALS:
        sys.exit(f'libm_bundle: bundle calls undefined functions: {sorted(undefined - LIBC_EXTERNALS)}')
    pat = re.compile(r'@(' + '|'.join(re.escape(d) for d in sorted(defined, key=len, reverse=True))
                     + r')(?![\w.$])')
    ir = pat.sub(lambda m: '@' + PREFIX + m.group(1), ir)
    # Only the math.h entry points stay external under the private prefix:
    # llvm-link drops unreferenced internal bodies, and nothing references an
    # entry point before the pass binds it. Every helper becomes internal, and
    # the pass binds only external bodies, so a private openlibm helper that
    # shares a spelling (`static long double powil(long double, int)`, which an
    # `llvm.powi.f80` call spells) never binds (LibmBinding.h).
    public = {PREFIX + n for n in names}
    def internalize(m):
        sym = re.search(r'@([\w.$]+)', m.group(0)).group(1)
        return m.group(0) if sym in public else m.group(1) + 'internal ' + m.group(2)
    ir = re.sub(r'^(define )(?!internal |private )((?:dso_local |hidden |protected )*[^\n]*)',
                internalize, ir, flags=re.M)
    ir = re.sub(r'^(@[\w.$]+ = )(?!internal |private |external |extern_weak )'
                r'((?:dso_local |hidden |protected |weak |common )*[^\n]*)', internalize, ir, flags=re.M)
    a.out.parent.mkdir(parents=True, exist_ok=True)
    tmp = a.out.with_suffix('.ll')
    tmp.write_text(ir)
    r = subprocess.run([WP.AS, tmp, '-o', a.out], text=True, capture_output=True)
    if r.returncode:
        sys.exit('libm_bundle: llvm-as rejected the renamed bundle:\n' + r.stderr)
    tmp.unlink()
    print(f'libm_bundle: {count} spellings, {len(defined)} definitions -> {a.out}')
    if missing:
        print(f'libm_bundle: no body for {len(missing)} spellings: {" ".join(missing)}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
