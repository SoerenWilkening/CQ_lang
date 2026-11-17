"""Replay a CQ `trace` backend log on a sparse state (basis tuple -> amplitude)
and compare the measured registers with exact QAOA MaxCut on a ring.
usage: python3 sim_trace.py TRACE N "g1,g2,.." "b1,b2,.."     (N = ring size; P = len(gammas))
       python3 sim_trace.py TRACE N - -                        (print distribution only)"""
import re, sys, numpy as np
from itertools import product
from collections import defaultdict
M32 = 0xffffffff
OPS = {'xor': lambda a, b: a ^ b, 'and': lambda a, b: a & b, 'or': lambda a, b: a | b,
       'add': lambda a, b: (a + b) & M32, 'sub': lambda a, b: (a - b) & M32,
       'icmp_eq': lambda a, b: int(a == b), 'icmp_ne': lambda a, b: int(a != b)}
names, state, measured = [], {(): 1.0 + 0j}, []
def ix(h): return names.index(h)
def val(tok, b): return b[ix(tok)] if tok in names else int(tok, 0) & M32
def unitary1(h, U):
    global state
    q, new = ix(h), defaultdict(complex)
    for b, a in state.items():
        for o in (0, 1):
            if U[o][b[q]]: new[b[:q] + (o,) + b[q+1:]] += U[o][b[q]] * a
    state = {b: a for b, a in new.items() if abs(a) > 1e-14}
def perm(f):
    global state
    state = {f(b): a for b, a in state.items()}
for L in open(sys.argv[1]).read().splitlines():
    m = re.match(r'(cqrt|cq_template)_(\w+)\((.*?)\)(?: -> (\w+))?$', L)
    if not m: continue
    kind, op, args, out = m.groups(); a = [s.strip() for s in args.split(',')]
    if kind == 'cqrt' and op.startswith('alloc'):
        names.append(out); v = int(a[0], 0); state = {b + (v,): x for b, x in state.items()}
    elif kind == 'cqrt' and op == 'free':
        q = ix(a[0]); assert all(b[q] == 0 for b in state), f'{a[0]} freed while not |0>'
        state = {b[:q] + b[q+1:]: x for b, x in state.items()}; names.pop(q)
    elif kind == 'cqrt' and op == 'ry_i1':
        t = float.fromhex(a[1]); c, s = np.cos(t/2), np.sin(t/2); unitary1(a[0], [[c, -s], [s, c]])
    elif kind == 'cqrt' and op == 'rz_i1':
        t = float.fromhex(a[1]); unitary1(a[0], [[np.exp(-1j*t/2), 0], [0, np.exp(1j*t/2)]])
    elif kind == 'cqrt' and op == 'x':
        q = ix(a[0]); perm(lambda b: b[:q] + (b[q] ^ 1,) + b[q+1:])
    elif kind == 'cqrt' and op == 'cnot':
        c, q = ix(a[0]), ix(a[1]); perm(lambda b: b[:q] + (b[q] ^ b[c],) + b[q+1:])
    elif kind == 'cqrt' and op.startswith('measure'):
        measured.append(a[0]); continue
    elif kind == 'cq_template':
        unc = op.endswith('_unc'); base = op[:-4] if unc else op
        if base.startswith('zext'): f, ins = (lambda x: x), a[1:2] if unc else a[0:1]
        elif base.startswith('select'):
            ins = a[1:4] if unc else a[0:3]; f = lambda c, x, y: x if c else y
            fn = lambda b, f=f, ins=ins: f(*[val(t, b) for t in ins])
            if unc:
                q = ix(a[0]); perm(lambda b: b[:q] + (b[q] ^ fn(b),) + b[q+1:])
            else:
                names.append(out); perm(lambda b: b + (fn(b),))
            continue
        else:
            key = next(k for k in sorted(OPS, key=len, reverse=True) if base.startswith(k)); f = OPS[key]
            ins = a[1:3] if unc else a[0:2]
        fn = (lambda b, f=f, ins=ins: f(*[val(t, b) for t in ins])) if len(ins) == 2 else \
             (lambda b, f=f, ins=ins: f(val(ins[0], b)))
        if unc:
            q = ix(a[0]); perm(lambda b: b[:q] + (b[q] ^ fn(b),) + b[q+1:])
        else:
            names.append(out); perm(lambda b: b + (fn(b),))
    else: raise SystemExit(f'unhandled: {L}')
live = [h for h in names if h not in measured]
leak = [h for h in live if any(b[ix(h)] for b in state)]
print(f'registers live at end: {names}; not |0> and not measured: {leak or "none"}')
dist = defaultdict(float)
for b, x in state.items(): dist[tuple(b[ix(h)] for h in measured)] += abs(x)**2
n = int(sys.argv[2]); E = [(i, (i+1) % n) for i in range(n)]
cut = lambda z: sum(z[u] != z[v] for u, v in E)
if sys.argv[3] != '-':
    gs = [float(eval(s, {'pi': np.pi})) for s in sys.argv[3].split(',')]
    bs = [float(eval(s, {'pi': np.pi})) for s in sys.argv[4].split(',')]
    bits = list(product([0, 1], repeat=n)); C = np.array([cut(z) for z in bits])
    psi = np.full(2**n, 2**(-n/2) + 0j)
    for g, bt in zip(gs, bs):
        psi = psi * np.exp(-1j * g * C)
        Rx = np.array([[np.cos(bt), -1j*np.sin(bt)], [-1j*np.sin(bt), np.cos(bt)]])
        for q in range(n):
            t = np.moveaxis(psi.reshape([2]*n), q, 0); psi = np.moveaxis(np.tensordot(Rx, t, 1), 0, q).reshape(-1)
    ex = {z: abs(p)**2 for z, p in zip(bits, psi)}
    print('max |p_trace - p_exact| = %.2e' % max(abs(dist.get(z, 0) - ex[z]) for z in bits))
    print('<C> trace = %.4f   exact = %.4f   (max cut %d)' % (sum(p*cut(z) for z, p in dist.items()), sum(p*cut(z) for z, p in ex.items()), n if n % 2 == 0 else n-1))
else:
    for z, p in sorted(dist.items()): print(''.join(map(str, z)), 'p = %.4f' % p)
