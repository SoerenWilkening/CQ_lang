"""Replay a CQ `trace` backend log on a sparse state (basis tuple -> amplitude) and,
for quantum counting, compare the counting-register distribution with exact QPE on G.
usage: python3 sim_qpe.py TRACE                         (distribution of measured regs)
       python3 sim_qpe.py TRACE n t m1,m2,..            (first t measured = c0..c_{t-1}, c_j = bit t-1-j of m;
                                                         search space N = 2^n, marked items m_i)
Extends ../qaoa/sim_trace.py with toffoli, ry_i1_controlled, copy_<W>_controlled and more
templates. Asserts every freed register is |0>. Stopgap for F7/S6 (no simulating backend)."""
import re, sys, numpy as np
from collections import defaultdict
M32 = 0xffffffff
OPS = {'xor': lambda a, b: a ^ b, 'and': lambda a, b: a & b, 'or': lambda a, b: a | b,
       'add': lambda a, b: (a + b) & M32, 'sub': lambda a, b: (a - b) & M32,
       'mul': lambda a, b: (a * b) & M32, 'shl': lambda a, b: (a << b) & M32,
       'lshr': lambda a, b: a >> b,
       'icmp_eq': lambda a, b: int(a == b), 'icmp_ne': lambda a, b: int(a != b),
       'icmp_ult': lambda a, b: int(a < b), 'icmp_ugt': lambda a, b: int(a > b),
       'icmp_ule': lambda a, b: int(a <= b), 'icmp_uge': lambda a, b: int(a >= b)}
names, state, measured, alloc_const, data = [], {(): 1.0 + 0j}, [], {}, set()
def ix(h): return names.index(h)
def val(tok, b): return b[ix(tok)] if tok in names else int(tok, 0) & M32
def unitary1(h, U, ctrl=None):
    global state
    q, c, new = ix(h), (ix(ctrl) if ctrl else None), defaultdict(complex)
    for b, a in state.items():
        if c is not None and not b[c]: new[b] += a; continue
        for o in (0, 1):
            if U[o][b[q]]: new[b[:q] + (o,) + b[q+1:]] += U[o][b[q]] * a
    state = {b: a for b, a in new.items() if abs(a) > 1e-14}
def perm(f):
    global state
    state = {f(b): a for b, a in state.items()}
def ry(t): c, s = np.cos(t/2), np.sin(t/2); return [[c, -s], [s, c]]
ngates = defaultdict(int)
for L in open(sys.argv[1]).read().splitlines():
    m = re.match(r'(cqrt|cq_template)_(\w+)\((.*?)\)(?: -> (\w+))?$', L)
    if not m: continue
    kind, op, args, out = m.groups(); a = [s.strip() for s in args.split(',')]
    ngates[(kind, re.sub(r'_(i1|i8|i16|i32|i64)\b', '', op))] += 1
    if kind == 'cqrt' and op.startswith('alloc'):
        names.append(out); v = int(a[0], 0); alloc_const[out] = v; state = {b + (v,): x for b, x in state.items()}
    elif kind == 'cqrt' and op == 'free':
        q = ix(a[0]); assert all(b[q] == 0 for b in state), f'{a[0]} freed while not |0>'
        state = {b[:q] + b[q+1:]: x for b, x in state.items()}; names.pop(q)
    elif kind == 'cqrt' and op == 'ry_i1':
        data.add(a[0])
        unitary1(a[0], ry(float.fromhex(a[1])))
    elif kind == 'cqrt' and op in ('ry_i1_controlled', 'ry_i1_controlled_inv'):
        t = float.fromhex(a[2]); unitary1(a[1], ry(-t if op.endswith('inv') else t), ctrl=a[0])
    elif kind == 'cqrt' and op == 'rz_i1':
        t = float.fromhex(a[1]); unitary1(a[0], [[np.exp(-1j*t/2), 0], [0, np.exp(1j*t/2)]])
    elif kind == 'cqrt' and op == 'x':
        q = ix(a[0]); perm(lambda b: b[:q] + (b[q] ^ 1,) + b[q+1:])
    elif kind == 'cqrt' and op == 'cnot':
        c, q = ix(a[0]), ix(a[1]); perm(lambda b: b[:q] + (b[q] ^ b[c],) + b[q+1:])
    elif kind == 'cqrt' and op == 'toffoli':
        c1, c2, q = ix(a[0]), ix(a[1]), ix(a[2]); perm(lambda b: b[:q] + (b[q] ^ (b[c1] & b[c2]),) + b[q+1:])
    elif kind == 'cqrt' and re.match(r'copy_i\d+_controlled$', op):
        c, s, d = ix(a[0]), ix(a[1]), ix(a[2]); perm(lambda b: b[:d] + (b[d] ^ (b[s] if b[c] else 0),) + b[d+1:])
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
            key = next((k for k in sorted(OPS, key=len, reverse=True) if base.startswith(k)), None)
            if key is None: raise SystemExit(f'unhandled template: {L}')
            f = OPS[key]; ins = a[1:3] if unc else a[0:2]
        fn = (lambda b, f=f, ins=ins: f(*[val(t, b) for t in ins])) if len(ins) == 2 else \
             (lambda b, f=f, ins=ins: f(val(ins[0], b)))
        if unc:
            q = ix(a[0]); perm(lambda b: b[:q] + (b[q] ^ fn(b),) + b[q+1:])
        else:
            names.append(out); perm(lambda b: b + (fn(b),))
    else: raise SystemExit(f'unhandled: {L}')
live = [h for h in names if h not in measured]
datal = [h for h in live if h in data]; live = [h for h in live if h not in data]
leak = [h for h in live if any(b[ix(h)] != alloc_const.get(h, 0) for b in state)]
const = [h for h in live if h not in leak and alloc_const.get(h, 0)]
zero = [h for h in live if h not in leak and h not in const]
print(f'unmeasured data qubits: {len(datal)}; ancillas never freed: {len(live)} (|0> at end of this run: {len(zero)}, classical constant: {len(const)}, '
      f'entangled/garbage: {leak or "none"})')
print('gates:', ', '.join(f'{k[1]}={v}' for k, v in sorted(ngates.items()) if k[0] == 'cqrt' and not k[1].startswith(('alloc', 'free', 'measure'))),
      f'| templates={sum(v for k, v in ngates.items() if k[0] == "cq_template")}')
dist = defaultdict(float)
for b, x in state.items(): dist[tuple(b[ix(h)] for h in measured)] += abs(x)**2
if len(sys.argv) == 2:
    for z, p in sorted(dist.items()):
        if p > 1e-9: print(''.join(map(str, z)), 'p = %.4f' % p)
    sys.exit()
n, t, mk = int(sys.argv[2]), int(sys.argv[3]), [int(s) for s in sys.argv[4].split(',') if s]
N, Tt = 2**n, 2**t
pm = defaultdict(float)
for z, p in dist.items(): pm[sum(bit << (t - 1 - j) for j, bit in enumerate(z[:t]))] += p
# exact: psi[c] = G^c |s> / sqrt(2^t);  p(m) = || sum_c e^{-2 pi i c m / 2^t} psi[c] ||^2 / 2^t
s = np.full(N, N**-0.5); O = np.diag([-1.0 if v in mk else 1.0 for v in range(N)])
G = (2*np.outer(s, s) - np.eye(N)) @ O
psi, v = [], s.copy()
for c in range(Tt): psi.append(v); v = G @ v
psi = np.array(psi) / np.sqrt(Tt)
ex = {mm: np.linalg.norm(np.exp(-2j*np.pi*np.arange(Tt)*mm/Tt) @ psi)**2 / Tt for mm in range(Tt)}
print('max |p_trace - p_exact| = %.2e' % max(abs(pm.get(mm, 0) - ex[mm]) for mm in range(Tt)))
est = lambda mm: N * np.sin(np.pi*mm/Tt)**2
print(' m  p_trace  p_exact  M~')
for mm in range(Tt): print('%2d  %.4f   %.4f   %.3f' % (mm, pm.get(mm, 0), ex[mm], est(mm)))
pr = defaultdict(float)
for mm in range(Tt): pr[int(round(est(mm)))] += pm.get(mm, 0)
print('P(round(M~) = M=%d) = %.4f   (distribution of round(M~): %s)' % (len(mk), pr[len(mk)], dict(sorted((k, round(v, 4)) for k, v in pr.items()))))
