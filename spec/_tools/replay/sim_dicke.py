"""Replay a CQ_spec trace on a sparse state vector (basis tuple over live handles -> amplitude). Measurements are the
identity (the state is read out instead). Handles: alloc_i1(v), free (asserts |0>), ry_i1, ry_i1_controlled, xor_i1
(t ^= c), not_i1, and_i1 (t ^= a&b), templates zext/select_ll/or/icmp_eq_hl and their _unc."""
import re, sys, numpy as np
from collections import defaultdict
names, state, measured = [], {(): 1.0+0j}, []
ix = lambda h: names.index(h)
def val(t, b): return b[ix(t)] if t in names else int(t, 0)
def perm(f):
    global state; state = {f(b): a for b, a in state.items()}
def unitary1(h, U, ctrl=None):
    global state; q = ix(h); c = ix(ctrl) if ctrl else None; new = defaultdict(complex)
    for b, a in state.items():
        if c is not None and not b[c]: new[b] += a; continue
        for o in (0, 1):
            if U[o][b[q]]: new[b[:q]+(o,)+b[q+1:]] += U[o][b[q]]*a
    state = {b: a for b, a in new.items() if abs(a) > 1e-14}
ry = lambda t: [[np.cos(t/2), -np.sin(t/2)], [np.sin(t/2), np.cos(t/2)]]
gates = defaultdict(int)
for L in open(sys.argv[1]).read().splitlines():
    m = re.match(r'(cqrt|cq_template)_(\w+)\((.*?)\)(?: -> (\w+))?$', L)
    if not m: continue
    kind, op, args, out = m.groups(); a = [s.strip() for s in args.split(',')]
    if kind == 'cqrt':
        if op.startswith('alloc'): names.append(out); v = int(a[0]); state = {b+(v,): x for b, x in state.items()}
        elif op == 'free':
            q = ix(a[0]); assert all(b[q] == 0 for b in state), f'{a[0]} freed while not |0>'
            state = {b[:q]+b[q+1:]: x for b, x in state.items()}; names.pop(q)
        elif op == 'ry_i1': gates['Ry'] += 1; unitary1(a[0], ry(float.fromhex(a[1])))
        elif op == 'ry_i1_controlled': gates['cRy'] += 1; unitary1(a[1], ry(float.fromhex(a[2])), ctrl=a[0])
        elif op == 'xor_i1': gates['CNOT'] += 1; c, q = ix(a[0]), ix(a[1]); perm(lambda b: b[:q]+(b[q]^b[c],)+b[q+1:])
        elif op == 'not_i1': q = ix(a[0]); perm(lambda b: b[:q]+(b[q]^1,)+b[q+1:])
        elif op == 'and_i1': c1, c2, q = ix(a[0]), ix(a[1]), ix(a[2]); perm(lambda b: b[:q]+(b[q]^(b[c1]&b[c2]),)+b[q+1:])
        elif op.startswith('measure'): measured.append(a[0])
        else: raise SystemExit('unhandled '+L)
    else:
        unc = op.endswith('_unc'); base = op[:-4] if unc else op; ins = a[1:] if unc else a
        if base.startswith('zext'): f = lambda b, ins=ins: val(ins[0], b)
        elif base.startswith('select'): f = lambda b, ins=ins: val(ins[1], b) if val(ins[0], b) else val(ins[2], b)
        elif base.startswith('or_'): f = lambda b, ins=ins: val(ins[0], b) | val(ins[1], b)
        elif base.startswith('icmp_eq'): f = lambda b, ins=ins: int(val(ins[0], b) == val(ins[1], b))
        else: raise SystemExit('unhandled '+L)
        if unc: q = ix(a[0]); perm(lambda b: b[:q]+(b[q]^f(b),)+b[q+1:])
        else: names.append(out); perm(lambda b: b+(f(b),))
print('gates:', dict(gates), '| live handles at end:', names)
amps = defaultdict(complex)
for b, x in state.items(): amps[tuple(b[ix(h)] for h in measured)] += x
for z, x in sorted(amps.items()):
    if abs(x) > 1e-9: print(''.join(map(str, z)), 'amp = %+.6f%+.6fi  p = %.6f' % (x.real, x.imag, abs(x)**2))
print('1/sqrt(6) = %.6f' % (6**-0.5))
