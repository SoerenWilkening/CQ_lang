"""trace_check.py TRACE: two checks over a reference trace (per '# call:' section).
1. allocation: rails/arrays minted and never freed (must equal the example's Kept + measured rails).
2. uncompute pairing: every `<fn>_unc(...)` line must match an EARLIER forward `<fn>(...)` call of the same section
   with identical operands (a forward with a result `-> hN` pairs with `_unc(hN, operands...)`; a forward without a
   result pairs with `_unc(operands...)`), each forward consumed at most once. Unmatched _unc lines are errors.
   Forward calls never uncomputed are listed only as a count (kept results, measured rails, outputs are legitimate).
   A clone twin `__cq_q_*_unc` pairs with its clone call the same way. A twin that recomputes the body uncomputes
   against RECOMPUTED operands (new names, same values): such a line pairs by its result handle and is counted
   separately, since the trace stubs compute no values."""
import re, sys
L = [l.strip() for l in open(sys.argv[1])]
live = set()
for l in L:
    m = re.search(r'-> ([ha]\d+)$', l)
    if m and 'measure' not in l: live.add(m.group(1))
    m = re.match(r'cqrt_(?:qram_)?(?:free|realloc_\w+_unc)\(([ha]\d+)[,)]', l)
    if m: live.discard(m.group(1))
print("  still allocated:", sorted(live, key=lambda h: (h[0], int(h[1:]))), " measured:", [l for l in L if 'measure' in l and not l.startswith('#')])
SKIP = re.compile(r'(cqrt_(alloc|free|measure|ry|rz|push|pop|tape|abort|not_i1|qram_alloc|qram_free)|#)')
errors, fwd, unc_ok, recomputed, produced, cleaned = [], {}, 0, [], set(), set()
section = ''
for n, l in enumerate(L, 1):
    if l.startswith('# call:'): section, fwd = l, {}
    mf = re.match(r'cqrt_free\(([ha]\d+)\)', l)
    if mf and mf.group(1) in produced and mf.group(1) not in cleaned:
        errors.append(f'line {n}: {l}  (template/clone result freed without its _unc or a clean-up copy)')
    mc = re.match(r'cqrt_copy_\w+\((\S+), ([ha]\d+)\)', l)
    if mc: cleaned.add(mc.group(2))
    if not l or SKIP.match(l): continue
    m = re.match(r'([\w.]+)\((.*?)\)(?: -> (\S+))?$', l)
    if not m: continue
    fn, args, ret = m.group(1), [a.strip() for a in m.group(2).split(',')] if m.group(2) else [], m.group(3)
    if fn.endswith('_unc'):
        base = fn[:-4]; cand = fwd.get(base, [])
        hit = None
        for i, (r, a) in enumerate(cand):
            if (r is not None and args == [r] + a) or (r is None and args == a): hit = i; break
            if 'qram_realloc' in base and r is not None and args[:1] == [r]: hit = i; break   # _unc(a', n_old)
        if hit is None:   # a twin may uncompute against RECOMPUTED operands (other names, same values): pair by result
            for i, (r, a) in enumerate(cand):
                lit_same = all(x == y for x, y in zip(args[1:], a) if not re.fullmatch(r'[ha]\d+|P\d+(\+\d+)?', y))
                if r is not None and args[:1] == [r] and len(args) == len(a) + 1 and lit_same:
                    hit = i; recomputed.append(n); break
        if hit is None:
            errors.append(f'line {n}: {l}  (no earlier forward {base} producing / with these operands)')
        else:
            r, _ = cand.pop(hit); unc_ok += 1
            if r is not None: cleaned.add(r)
    else:
        fwd.setdefault(fn, []).append((ret, args))
        if ret and (fn.startswith('cq_template_') or fn.startswith('__cq_q_') or 'qram_load' in fn): produced.add(ret)
left = sum(len(v) for v in fwd.values())
print(f"  uncompute pairing (and frees of computed rails): {unc_ok} matched ({len(recomputed)} against recomputed operands, value equality not checked), {len(errors)} unmatched" + ("" if not errors else ":"))
for e in errors[:10]: print("   ", e)
