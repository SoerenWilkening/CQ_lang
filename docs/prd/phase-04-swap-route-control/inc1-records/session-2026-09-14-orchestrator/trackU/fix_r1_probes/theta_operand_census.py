#!/usr/bin/env python3
"""Track U FIX round — the theta-operand census, settling F-U1-4(a).

GATES.md row 34 called the unswept-remainder measurement "(grep, not a sweep)";
IMPL_U.md Section 6 called it "parsing every theta call's arg-0, not by grep".
One of the two was false, so this re-measures it with a parser, over the WHOLE
fixture tree rather than a remainder -- and over BOTH operands, because the
F-U1-1 conjunct's trigger is seed AND angle, not seed alone.

Why grep is the wrong instrument here, concretely: `clang -O1` writes
`i1 noundef zeroext undef`, so the substring `undef` appears on EVERY
clang-emitted call via the `noundef` attribute. The operand's value is the LAST
token of the operand text, which is what this reads.

Reports, per `.ll` fixture, every `@cq_theta_<sfx>(...)` call whose arg-0 or
arg-1 is a whole-value `undef`/`poison`.
"""
import re, sys, pathlib

# The call text, non-greedy to the first ')': no cq_theta operand is itself a
# parenthesised ConstantExpr in this tree, and any that is shows up as a
# PARSE-SKIP row below rather than being silently mis-split.
CALL = re.compile(r'@cq_theta_[A-Za-z0-9_]+\(([^()]*)\)')

def whole_undef(op):
    toks = op.strip().split()
    return bool(toks) and toks[-1] in ('undef', 'poison')

seed_rows, angle_rows, both_rows, skipped = [], [], [], []
root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'ir-pass/test')
files = sorted(root.glob('*.ll'))
for f in files:
    txt = f.read_text(errors='replace')
    # a call whose operands contain '(' is not matched by CALL -- record it so a
    # miss is visible rather than counted as 'clean'.
    for m in re.finditer(r'@cq_theta_[A-Za-z0-9_]+\(', txt):
        tail = txt[m.end():m.end()+400]
        depth, end = 1, None
        for i, c in enumerate(tail):
            if c == '(': depth += 1
            elif c == ')':
                depth -= 1
                if depth == 0: end = i; break
        if end is None: continue
        if '(' in tail[:end]:
            skipped.append((f.name, tail[:end][:70]))
    for m in CALL.finditer(txt):
        args = [a for a in m.group(1).split(',')]
        s = whole_undef(args[0]) if len(args) > 0 else False
        a = whole_undef(args[1]) if len(args) > 1 else False
        if s and a: both_rows.append((f.name, m.group(0)[:80]))
        elif s:     seed_rows.append((f.name, m.group(0)[:80]))
        elif a:     angle_rows.append((f.name, m.group(0)[:80]))

print(f"fixtures scanned: {len(files)}  ({root})")
print(f"\nSEED undef/poison only  (the z9t1 rule FIRES): {len(seed_rows)}")
for n, c in seed_rows: print(f"  {n}\n      {c}")
print(f"\nANGLE undef/poison only (blessed 1-slot shape; the z9t1 rule does NOT fire): {len(angle_rows)}")
for n, c in angle_rows: print(f"  {n}\n      {c}")
print(f"\nBOTH  (the F-U1-1 composition -- OPEN, pending owner ruling): {len(both_rows)}")
for n, c in both_rows: print(f"  {n}\n      {c}")
print(f"\nPARSE-SKIP (a parenthesised operand this regex did not split): {len(skipped)}")
for n, c in skipped: print(f"  {n}\n      {c}")
