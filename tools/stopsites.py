#!/usr/bin/env python3
"""stopsites.py: the stop-site census for the landing gate (owner 2026-11-03).

Usage: tools/stopsites.py [--list] [--diff BEFORE.txt]
Counts every unimplemented( and internalError( call site under pass/lib and pass/include (declarations, macro
definitions and comments excluded) and prints the count. --list prints one line per site: kind<TAB>first string
literal of the message (the site's text; a site with no literal prints the call line). --diff BEFORE.txt (a
--list output taken on main before landing) prints every site text not present before and exits 1 if there is
one, or if the count rose. Grouping by text, not file:line, so a site that moves lines is not new.
"""
import os, re, sys, collections

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CALL = re.compile(r'\b(unimplemented|internalError)\s*\(')
LIT = re.compile(r'"((?:[^"\\]|\\.)*)"')


def sites():
    out = []
    for root in ('pass/lib', 'pass/include'):
        for dp, _, fs in os.walk(os.path.join(REPO, root)):
            for f in fs:
                if not f.endswith(('.cpp', '.h')):
                    continue
                lines = open(os.path.join(dp, f)).read().split('\n')
                for i, l in enumerate(lines):
                    code = l.split('//')[0]
                    for m in CALL.finditer(code):
                        pre = code[:m.start()]
                        if re.search(r'\bvoid\s+\(?$', pre) or '#define' in pre or 'void (' in pre:
                            continue   # a declaration, definition or the macro
                        # the message: the first string literal from the call on, possibly on the next lines
                        after = code[m.end():] + ' ' + ' '.join(lines[i + 1:i + 3])
                        lit = LIT.search(after)
                        out.append((m.group(1), lit.group(1) if lit else code.strip()))
    return out


def main():
    s = sites()
    if '--list' in sys.argv:
        for k, t in sorted(s):
            print(f'{k}\t{t}')
        return
    if '--diff' in sys.argv:
        before = [l.rstrip('\n').split('\t', 1) for l in open(sys.argv[sys.argv.index('--diff') + 1]) if l.strip()]
        bc = collections.Counter(tuple(b) for b in before)
        new = [x for x in s if bc[x] == 0]
        print(f'stop sites: {len(before)} -> {len(s)}')
        for k, t in sorted(set(new)):
            print(f'NEW SITE: {k}\t{t}')
        sys.exit(1 if new or len(s) > len(before) else 0)
    print(len(s))


if __name__ == '__main__':
    main()
