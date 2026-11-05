"""trace_check.py TRACE: two checks over a reference trace (per '# call:' section).
1. allocation: rails/arrays minted and never freed (must equal the example's Kept + measured rails).
2. uncompute pairing: every `<fn>_unc(...)` line must match an EARLIER forward `<fn>(...)` call of the same section
   with identical operands (a forward with a result `-> hN` pairs with `_unc(hN, operands...)`; a forward without a
   result pairs with `_unc(operands...)`), each forward consumed at most once. Unmatched _unc lines are errors.
   Forward calls never uncomputed are listed only as a count (kept results, measured rails, outputs are legitimate).
   A clone twin `__cq_q_*_unc` pairs with its clone call the same way. A twin that recomputes the body uncomputes
   against RECOMPUTED operands (new names, same values): such a line pairs by its result handle and is counted
   separately, since the trace stubs compute no values.
3. bus memory (CR rule 5, BACKEND_ABI §1.10; lines whose handle operand is the bus m<N>). The retired per-object
   lines (array handle a<N>, store _unc pops, realloc, qram_free) are still accepted as before.
   a. a bus store has no _unc: any cqrt_qram_store_*_unc on the bus is an error (no store pop).
   b. a store's value rail and control rail are KEPT: a later cqrt_free of either, or an _unc whose result is one,
      is an error. The trace has no function boundaries: a caller that frees a rail it PASSED to a storing clone is
      legal by rule 5 and is reported the same; read such a line by hand.
   c. a load copy is FREED only when no memory version change lies between its load and its _unc: a load _unc with a
      bus store, a bus swap, an effect entry, a "# __cq_alloc" line or a table-clone call (__cq_q_*_t[_ctl][_unc])
      between the load and itself is legal (overtaken), but a later cqrt_free of that copy is an error. A load copy
      freed without its _unc is check 2's error.
   d. the in-place form: bus swaps come in pairs of the same symbol, bus, address and control inside one section, with
      no bus access between the two; the rail of the second swap must be freed (nothing remains).
Exit status 1 when any error was found."""
import re, sys
L = [l.strip() for l in open(sys.argv[1])]
live = set()
for l in L:
    m = re.search(r'-> ([ha]\d+)$', l)
    if m and 'measure' not in l: live.add(m.group(1))
    m = re.match(r'cqrt_(?:qram_)?(?:free|realloc_\w+_unc)\(([ha]\d+)[,)]', l)
    if m: live.discard(m.group(1))
print("  still allocated:", sorted(live, key=lambda h: (h[0], int(h[1:]))), " measured:", [l for l in L if 'measure' in l and not l.startswith('#')])
SKIP = re.compile(r'(cqrt_(alloc|free|measure|ry|rz|push|pop|tape|abort|not_i1|qram_alloc|qram_free|invert)|#)')
errors, fwd, unc_ok, recomputed, produced, cleaned = [], {}, 0, [], set(), set()
BUS = re.compile(r'cqrt_qram_(load|store|swap)_(\w+?)\((.*?)\)(?: -> (\S+))?$')
VERSION = re.compile(r'cqrt_tape_effect\w*\(|# __cq_alloc\(|__cq_q_\w+_t(_ctl)?(_unc)?\(')
kept, ver, load_ver, overtaken, open_swap, swapped_in, bus_n = {}, 0, {}, {}, None, {}, {'load': 0, 'store': 0, 'swap': 0}
def close_section(n):
    global open_swap
    if open_swap: errors.append(f'line {open_swap[0]}: {open_swap[1]}  (bus swap never swapped back: the in-place form is a pair, rule 5)'); open_swap = None
section = ''
for n, l in enumerate(L, 1):
    if l.startswith('# call:'): close_section(n); section, fwd = l, {}
    if VERSION.match(l): ver += 1
    mb = BUS.match(l)
    if mb and re.search(r'(^|, )m\d+(, |$)', mb.group(3)):   # an access of the one bus
        kind, form, a, ret = mb.group(1), mb.group(2), [x.strip() for x in mb.group(3).split(',')], mb.group(4)
        is_unc, ctl = form.endswith('_unc'), '_controlled' in form
        if open_swap and kind != 'swap':
            errors.append(f'line {n}: {l}  (bus access between the two swaps of the in-place form opened at line {open_swap[0]})')
        if kind == 'store':
            if is_unc: errors.append(f'line {n}: {l}  (a bus store has no _unc: no store pop, rule 5 sentence 3)'); continue
            bus_n['store'] += 1; ver += 1
            kept.setdefault(a[-1], (n, 'value')); 
            if ctl: kept.setdefault(a[0], (n, 'control'))
            continue
        if kind == 'swap':
            bus_n['swap'] += 1; ver += 1
            key = (form, tuple(a[:-1]))
            if open_swap is None: open_swap = (n, l, key)
            else:
                if open_swap[2] != key: errors.append(f'line {n}: {l}  (second swap of the in-place form differs in symbol, bus, address or control from line {open_swap[0]})')
                swapped_in[a[-1]] = n; cleaned.add(a[-1]); open_swap = None
            continue
        if not is_unc: bus_n['load'] += 1; load_ver[ret] = ver
        elif load_ver.get(a[0], ver) != ver: overtaken[a[0]] = n   # legal _unc; the copy must stay allocated
    mf = re.match(r'cqrt_free\(([ha]\d+)\)', l)
    if mf and mf.group(1) in kept:
        errors.append(f'line {n}: {l}  ({kept[mf.group(1)][1]} rail of the bus store at line {kept[mf.group(1)][0]} freed: kept for the shot, rule 5 sentence 3)')
    if mf and mf.group(1) in overtaken:
        errors.append(f'line {n}: {l}  (load copy freed after its _unc at line {overtaken[mf.group(1)]} followed a memory version change: rule 5 sentence 1 leaves it allocated)')
    if mf: swapped_in.pop(mf.group(1), None)
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
            if r in kept: errors.append(f'line {n}: {l}  ({kept[r][1]} rail of the bus store at line {kept[r][0]} uncomputed: kept for the shot, rule 5 sentence 3)')
    else:
        fwd.setdefault(fn, []).append((ret, args))
        if ret and (fn.startswith('cq_template_') or fn.startswith('__cq_q_') or 'qram_load' in fn): produced.add(ret)
close_section(len(L))
for h, n in sorted(swapped_in.items(), key=lambda x: x[1]): errors.append(f'line {n}: {L[n - 1]}  (rail {h} holds the cell\'s |0> after the in-place form and is never freed)')
left = sum(len(v) for v in fwd.values())
print(f"  uncompute pairing (and frees of computed rails): {unc_ok} matched ({len(recomputed)} against recomputed operands, value equality not checked), {len(errors)} unmatched" + ("" if not errors else ":"))
for e in errors[:10]: print("   ", e)
if any(bus_n.values()): print(f"  bus: {bus_n['load']} loads, {bus_n['store']} stores (kept rails: {sorted(kept, key=lambda h: int(h[1:]))}), {bus_n['swap'] // 2} in-place forms")
sys.exit(1 if errors else 0)
