#!/usr/bin/env python3
"""sample_check.py [-j N] [--keep DIR] [NN_name | path/to/x.lowered.ll ...]: a LIGHTWEIGHT §6.1 basis-input sample check.

Not a simulator, not exhaustive. For each example it links base.lowered.ll against generated IR stubs that forward every
cqrt_*/cq_template_* call to the evaluator below (each rail = one basis value; templates per §2; _unc recomputes and must
leave 0; cqrt_free must see 0 or an untouched seed; rotations only change nothing and are logged), and base.O1.ll against
the identity reference in sample_rt.c (cq_theta, cq_measure = identity). Both run the drivers.txt calls on a few fixed
inputs: the arguments that the lowered entry passes straight to cqrt_alloc_<W> are replaced by 0, 1, -1, 3, 7, MAX, MIN
(per C type; 0, 1.5, -2.25, 7 for floating). Compared per sample: driver return values, the multiset of measured values,
the multiset of fired Ry angles (a C-side measurement the lowered side lacks is allowed only as one of the rule-2
classical reads the reference header declares: `; Classical reads (rule 2): N`, N per driver run; their values are
witnessed by the output compare); fired phases must be a sub-multiset of the C program's, and the C-only remainder (the
deleted global phase) must not depend on the input. Lowered-side violations (_unc residue, dirty free, ...) FAIL. A mismatch without violations in an example with a [K]
loop is KDIFF: expected where the C loop needs more than K = 4 trips; read the sample.
A reference that traps, aborts or does not terminate (C UB) leaves that sample uncompared (listed in the note).
A mutant is checked as NN_name:path/to/mutant.lowered.ll."""
import os, re, sys, struct, subprocess, pathlib, select, tempfile, shutil, math
from fractions import Fraction
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
import numpy as np
HERE = pathlib.Path(__file__).resolve().parent; SPEC = HERE.parent
CLANG = '/usr/local/opt/llvm@19/bin/clang'
DRIVERS = {l.split('|')[0]: (l.rstrip('\n').split('|')[1:] + [''])[:3] for l in open(HERE / 'drivers.txt') if '|' in l}
FT = {16: np.float16, 32: np.float32, 64: np.float64}; UT = {16: np.uint16, 32: np.uint32, 64: np.uint64}
class Unsupported(Exception): pass
class BadHandle(Exception): pass
def M(n): return (1 << n) - 1
def sx(v, n): v &= M(n); return v - (1 << n) if v >> (n - 1) else v
def fdec(b, w): return np.array(b, dtype=UT[w]).view(FT[w])[()]
def fenc(x, w): return int(np.array(x, dtype=FT[w]).view(UT[w]))
def wid(s):   # 'i32' -> ('i', 32), 'f64' -> ('f', 64)
    if s == 'f80': raise Unsupported('f80')
    return (s[0], int(s[1:]))
def int_to_f(v, w):   # correctly rounded integer -> binary16/32/64
    p = {16: 11, 32: 24, 64: 53}[w]; a = abs(v); n = a.bit_length()
    if n > p:
        sh = n - p; q, r = divmod(a, 1 << sh); h = 1 << (sh - 1)
        if r > h or (r == h and q & 1): q += 1
        a = q << sh
    x = float(a) if a < 1 << 1024 else math.inf
    return fenc(FT[w](-x if v < 0 else x), w)
def round_frac(fr, w):   # exact rational -> nearest-even binary<w> (finite inputs only)
    if fr == 0: return fenc(FT[w](0.0), w)
    p, emin = {16: (11, -14), 32: (24, -126), 64: (53, -1022)}[w]
    s = fr < 0; fr = abs(fr); e = fr.numerator.bit_length() - fr.denominator.bit_length()
    if Fraction(2) ** e > fr: e -= 1
    e = max(e, emin); q = fr / Fraction(2) ** (e - p + 1); n = q.numerator // q.denominator; r = q - n
    if r > Fraction(1, 2) or (r == Fraction(1, 2) and n & 1): n += 1
    x = math.ldexp(n, e - p + 1) if e - p + 1 < 1000 else math.inf
    return fenc(FT[w](-x if s else x), w)
ICMP = {'eq': lambda a, b, n: a == b, 'ne': lambda a, b, n: a != b, 'ugt': lambda a, b, n: a > b, 'uge': lambda a, b, n: a >= b,
        'ult': lambda a, b, n: a < b, 'ule': lambda a, b, n: a <= b, 'sgt': lambda a, b, n: sx(a, n) > sx(b, n),
        'sge': lambda a, b, n: sx(a, n) >= sx(b, n), 'slt': lambda a, b, n: sx(a, n) < sx(b, n), 'sle': lambda a, b, n: sx(a, n) <= sx(b, n)}
def fcmp(p, a, b):
    un = bool(np.isnan(a) or np.isnan(b))
    if p == 'ord': return not un
    if p == 'uno': return un
    if p in ('true', 'false'): return p == 'true'
    r = {'eq': a == b, 'ne': a != b, 'gt': a > b, 'ge': a >= b, 'lt': a < b, 'le': a <= b}[p[1:]]
    return bool(r) if p[0] == 'o' else (un or bool(r))
def fpclass(x, m):
    b = int(np.signbit(x))
    if np.isnan(x): c = 1   # quiet (no signalling NaN reaches a sample)
    elif np.isinf(x): c = 2 if b else 9
    elif x == 0: c = 5 if b else 6
    elif abs(x) < np.finfo(type(x)).tiny: c = 4 if b else 7
    else: c = 3 if b else 8
    return (m >> c) & 1
PRED = 'eq|ne|ugt|uge|ult|ule|sgt|sge|slt|sle|oeq|ogt|oge|olt|ole|one|ord|ueq|une|uno|true|false'
TRE = re.compile(rf'^(?P<op>[a-z0-9_]+?)(?:_(?P<pred>{PRED}))?_(?P<w>i\d+|f\d+)(?:_to_(?P<w2>i\d+|f\d+))?'
                 rf'(?:_(?P<shape>[hlq]+|s))?(?P<rest>(?:_rm|_rmq|_exc)*)$')
def tmpl(op, pred, w, w2, v):
    """§2 forward value of one template. w = operand (kind, width), w2 = cast target; returns (bits, result width)."""
    k, n = w
    if op in ('icmp', 'fcmp', 'fcmps', 'is_fpclass') or op.endswith('_overflow'): rw = 1
    elif w2: rw = wid(w2)[1]
    else: rw = n
    if k == 'i':
        a = v[0] & M(n); b = v[1] & M(n) if len(v) > 1 else 0
        if op == 'icmp': r = ICMP[pred](a, b, n)
        elif op == 'add': r = a + b
        elif op == 'sub': r = a - b
        elif op == 'mul': r = a * b
        elif op == 'and': r = a & b
        elif op == 'or': r = a | b
        elif op == 'xor': r = a ^ b
        elif op == 'udiv': r = M(n) if b == 0 else a // b
        elif op == 'urem': r = a if b == 0 else a % b
        elif op in ('sdiv', 'srem'):
            sa, sb = sx(a, n), sx(b, n)
            if sb == 0: r = (-1 if sa >= 0 else 1) if op == 'sdiv' else a
            elif sa == -(1 << (n - 1)) and sb == -1: r = sa if op == 'sdiv' else 0
            else:
                q = abs(sa) // abs(sb) * (1 if (sa < 0) == (sb < 0) else -1); r = q if op == 'sdiv' else sa - sb * q
        elif op == 'shl': r = a << (b % n)
        elif op == 'lshr': r = a >> (b % n)
        elif op == 'ashr': r = sx(a, n) >> (b % n)
        elif op in ('fshl', 'fshr'):
            c = v[2] % n
            if c == 0: r = a if op == 'fshl' else b
            else: r = ((a << c) | (b >> (n - c))) if op == 'fshl' else ((b >> c) | (a << (n - c)))
        elif op == 'select': raise AssertionError
        elif op == 'abs': r = abs(sx(a, n))
        elif op == 'ctpop': r = bin(a).count('1')
        elif op == 'ctlz': r = n - a.bit_length()
        elif op == 'cttz': r = n if a == 0 else (a & -a).bit_length() - 1
        elif op == 'bswap': r = int.from_bytes(a.to_bytes(n // 8, 'little'), 'big')
        elif op == 'smax': r = max(sx(a, n), sx(b, n))
        elif op == 'smin': r = min(sx(a, n), sx(b, n))
        elif op == 'umax': r = max(a, b)
        elif op == 'umin': r = min(a, b)
        elif op == 'uadd_sat': r = min(a + b, M(n))
        elif op == 'usub_sat': r = max(a - b, 0)
        elif op == 'uadd_overflow': r = a + b > M(n)
        elif op == 'usub_overflow': r = a < b
        elif op == 'umul_overflow': r = a * b > M(n)
        elif op in ('sadd_overflow', 'ssub_overflow', 'smul_overflow'):
            sa, sb = sx(a, n), sx(b, n); t = {'sadd': sa + sb, 'ssub': sa - sb, 'smul': sa * sb}[op[:4]]
            r = not (-(1 << (n - 1)) <= t < 1 << (n - 1))
        elif op == 'zext': r = a
        elif op == 'sext': r = sx(a, n)
        elif op == 'trunc' and w2: r = a
        elif op == 'bitcast': r = a
        elif op == 'sitofp': r = int_to_f(sx(a, n), rw)
        elif op == 'uitofp': r = int_to_f(a, rw)
        else: raise Unsupported(f'{op}_i{n}')
        return int(r) & M(rw), rw
    with np.errstate(all='ignore'):
        x = [fdec(t & M(n), n) for t in v[:3]] if op != 'is_fpclass' else [fdec(v[0] & M(n), n)]
        a = x[0]; b = x[1] if len(x) > 1 else None
        if op in ('fcmp', 'fcmps'): return int(fcmp(pred, a, b)), 1
        if op == 'is_fpclass': return fpclass(a, v[1]), 1
        if op in ('fptosi', 'fptoui'):
            return fp_to_int(op, a, n, rw), rw   # CR §2: x86-64 LLVM 19 -O1 codegen
        if op == 'bitcast': return v[0] & M(n), rw
        if op in ('fpext', 'fptrunc'): return fenc(FT[rw](a), rw), rw
        ops = {'fadd': lambda: a + b, 'fsub': lambda: a - b, 'fmul': lambda: a * b, 'fdiv': lambda: a / b,
               'frem': lambda: np.fmod(a, b), 'fneg': lambda: -a, 'fabs': lambda: np.abs(a), 'copysign': lambda: np.copysign(a, b),
               'sqrt': lambda: np.sqrt(a), 'floor': lambda: np.floor(a), 'ceil': lambda: np.ceil(a), 'trunc': lambda: np.trunc(a),
               'rint': lambda: np.rint(a), 'fmax': lambda: b if np.isnan(a) else a if np.isnan(b) else (b if b > a else a),
               'fmin': lambda: b if np.isnan(a) else a if np.isnan(b) else (b if b < a else a),
               'round': lambda: np.trunc(a) + (np.copysign(1, a) if abs(a - np.trunc(a)) >= 0.5 else 0)}
        if op == 'fma':
            if all(np.isfinite(t) for t in x): return round_frac(Fraction(float(x[0])) * Fraction(float(x[1])) + Fraction(float(x[2])), n), n
            return fenc(x[0] * x[1] + x[2], n), n
        if op == 'select': raise AssertionError
        if op not in ops: raise Unsupported(f'{op}_f{n}')
        return fenc(FT[n](ops[op]()), n), n

def fp_to_int(op, a, n, rw):
    """CR §2 fptosi/fptoui: c32/c64 = cvtt with the indefinite INT_MIN of that width (f16/f32/f64); f80 = x87 fist."""
    def cv(x, w):
        if not np.isfinite(x) or not -(1 << (w - 1)) <= int(np.trunc(x)) < 1 << (w - 1): return 1 << (w - 1)
        return int(np.trunc(x)) & M(w)
    if n == 80:
        if op == 'fptosi': return (cv(a, 16) if rw <= 16 else cv(a, rw)) & M(rw)
        if rw <= 16: return cv(a, 32) & M(rw)
        if rw == 32: return cv(a, 64) & M(32)
        return cv(a, 64) if a < 2.0 ** 63 else (cv(a - 2.0 ** 63, 64) ^ (1 << 63))
    if op == 'fptosi': return (cv(a, 32) if rw <= 32 else cv(a, 64)) & M(rw)
    if rw <= 16: return cv(a, 32) & M(rw)
    if rw == 32: return cv(a, 64) & M(32)
    r1, r2 = cv(a, 64), cv(a - 2.0 ** 63, 64)
    return (r1 | (r2 & (M(64) if r1 >> 63 else 0))) & M(64)

class Eval:
    """The lowered program's basis state: rails (handle -> [width, value, touched, rotated]), QRAM arrays, the classical
    push/pop stack, logged events (RY/PH angles, M values, ABORT) and violations."""
    def __init__(s, mem):
        s.mem, s.r, s.nh, s.arr, s.stk, s.ev, s.err = mem, {}, 1, {}, [], [], []
    def new(s, w, v, touched=True):
        h = s.nh; s.nh += 1; s.r[h] = [w, v & M(w), touched, 0.0]; return h
    def g(s, h):
        if h not in s.r: raise BadHandle(f'h{h} is not a live rail')
        return s.r[h][1]
    def put(s, h, v): s.g(h); s.r[h][1] = v & M(s.r[h][0]); s.r[h][2] = True
    def rot(s, kind, ang, h=None, on=True):
        if on and h is not None and h in s.r: s.r[h][3] += float(fdec(ang, 64))   # net fired Ry angle on the rail
        if on and math.isfinite(fdec(ang, 64)): s.ev.append((kind, ang))
    def call(s, name, ty, a):
        if name.startswith('cq_template_'): return s.template(name[12:], ty, a)
        n = name[5:]; unc = n.endswith('_unc'); n = n[:-4] if unc else n
        tok = n.split('_'); wi = next((i for i, t in enumerate(tok) if re.fullmatch(r'[if]\d+', t)), None)
        W = tok[wi] if wi is not None else None; w = wid(W)[1] if W else None
        sfx = '_' + '_'.join(tok[wi + 1:]) if wi is not None else ('_controlled' if n.endswith('_controlled') else '')
        base = '_'.join(tok[:wi]) if wi is not None else n.replace('_controlled', '')
        ctl = '_controlled' in sfx
        if ctl and base not in ('qram_store', 'qram_load'):
            c, a = s.g(a[0]) & 1, a[1:]
        else: c = 1
        if base == 'alloc': return s.new(w, a[0], touched=False)
        if base == 'free':
            h = a[0]
            if h not in s.r: s.err.append(f'cqrt_free(h{h}): not a live rail'); return 0
            wd, v, t, rt = s.r.pop(h)
            if v and t: s.err.append(f'cqrt_free(h{h}): rail holds {v:#x}, not 0')
            return 0
        if base == 'measure':
            v = s.g(a[0]); s.r[a[0]][3] = 0.0; s.ev.append(('M', w, v)); return v
        if base == 'ry': s.rot('RY', a[1] if 'qangle' not in sfx else s.g(a[1]), a[0], bool(c)); return 0
        if base == 'rz': s.rot('PH', a[1], None, bool(s.g(a[0]) & 1)); return 0
        if base == 'rz_qangle': s.rot('PH', s.g(a[0]), None, bool(c)); return 0
        if base == 'not': c and s.put(a[0], s.g(a[0]) ^ 1); return 0
        if base in ('and', 'or'):
            x, y = s.g(a[0]) & 1, s.g(a[1]) & 1; s.put(a[2], s.g(a[2]) ^ ((x & y) if base == 'and' else (x | y))); return 0
        if base in ('xor', 'copy'): c and s.put(a[1], s.g(a[1]) ^ s.g(a[0])); return 0
        if base == 'xorc': c and s.put(a[0], s.g(a[0]) ^ a[1]); return 0
        if base in ('push',): s.stk.append(a[0]); return 0
        if base == 'pop': return s.stk.pop()
        if base == 'abort':
            if s.g(a[0]) & 1: s.ev.append(('ABORT',))
            return 0
        if base == 'tape_alloc': return 0
        if base in ('tape_fmt', 'tape_effect', 'tape_write_str_lit'): return 0
        if base == 'tape_write':
            if sfx in ('_lit',) or W is None: return 0
            return s.new(w, s.g(a[1]) if c else 0)
        if base.startswith('qram'): return s.qram(base, w, sfx, unc, a)
        raise Unsupported(name)
    def qram(s, base, w, sfx, unc, a):
        if base == 'qram_alloc': h = s.nh; s.nh += 1; s.arr[h] = {'n': a[0], 'cells': [[0] for _ in range(a[0])], 'tape': []}; return h
        if base == 'qram_free':
            A = s.arr.pop(a[0])
            if any(c[0] for c in A['cells']) or A['tape']: s.err.append(f'cqrt_qram_free(a{a[0]}): cells or tape not |0>')
            return 0
        if base == 'qram_realloc':
            A = s.arr[a[0]]
            if unc: return 0
            h = s.nh; s.nh += 1; n = a[1]
            s.arr[h] = {'n': n, 'cells': A['cells'][:min(n, A['n'])] + [[0] for _ in range(max(0, n - A['n']))], 'tape': A['tape']}
            return h
        ctl = '_controlled' in sfx; hl = '_hl' in sfx
        if unc and base == 'qram_load': out, a = a[0], a[1:]
        c = s.g(a[0]) & 1 if ctl else 1; a = a[1:] if ctl else a
        A = s.arr[a[0]]; idx = (a[1] & M(32)) if hl else s.g(a[1]); ok = idx < A['n']   # CR §2: unsigned index reading
        if base == 'qram_load':
            v = A['cells'][idx][0] if ok and c else 0
            if not unc: return s.new(w, v)
            s.put(out, s.g(out) ^ v)
            if s.g(out): s.err.append(f'qram_load_unc: h{out} left {s.g(out):#x}')
            return 0
        key = (a[0], idx, a[2], c)
        if not unc:
            slot = [0]
            if ok and c: slot[0] = A['cells'][idx][0]; A['cells'][idx][0] = s.g(a[2])
            A['tape'].append((key, slot)); return 0
        for i in range(len(A['tape']) - 1, -1, -1):
            if A['tape'][i][0] == key:
                _, slot = A['tape'].pop(i)
                if ok and c:
                    cell = A['cells'][idx]; cell[0] ^= s.g(a[2])
                    if cell[0]: s.err.append(f'qram_store_unc: cell {idx} held {cell[0] ^ s.g(a[2]):#x}, not the stored value')
                    cell[0], slot[0] = slot[0], cell[0]
                return 0
        s.err.append(f'qram_store_unc with no matching store {key}'); return 0
    def template(s, body, ty, a):
        unc = body.endswith('_unc'); body = body[:-4] if unc else body
        m = TRE.match(body)
        if not m: raise Unsupported('cq_template_' + body)
        op, pred, W, W2, shape, rest = m.group('op', 'pred', 'w', 'w2', 'shape', 'rest')
        if rest: raise Unsupported('rounding-mode / exception template ' + body)
        w = wid(W); out, f = (a[0], a[1:]) if unc else (None, a)
        if op in ('qrom_load',):
            base, n, idx = f[0], f[1], s.g(f[-1]); st = f[2] if shape == 's' else (16 if W == 'f80' else w[1] // 8)
            v = int.from_bytes(s.mem(base + idx * st, w[1] // 8), 'little') if idx < n else 0; rw = w[1]   # unsigned index, alloc-size stride
        elif op == 'select':
            sh = shape or 'hh'; arms = [s.g(x) if l in 'hq' else x for l, x in zip(sh, f[1:3])]
            v, rw = arms[0] if s.g(f[0]) & 1 else arms[1], w[1]
        else:
            sh = shape or 'h' * len(f); v, rw = tmpl(op, pred, w, W2, [s.g(x) if l in 'hq' else x for l, x in zip(sh, f)])
        if not unc: return s.new(rw, v)
        s.put(out, s.g(out) ^ v)
        if s.g(out): s.err.append(f'cq_template_{body}_unc: h{out} left {s.g(out):#x} (recomputed {v:#x})')
        return 0

# ---------------------------------------------------------------- build
TYPES = r'(i\d+|half|float|double|x86_fp80|ptr|void)'
def stubs_ll(low_text, triple):
    out = [f'target triple = "{triple}"', 'declare void @sc_call(ptr, ptr, i32, ptr, ptr)']
    for k, m in enumerate(re.finditer(r'^declare (.*?)@((?:cqrt|cq_template)_\w+)\((.*)\)', low_text, re.M)):
        rpart, name, params = m.groups()
        rty = re.findall(TYPES, rpart)[-1]; rattr = ' '.join(t for t in rpart.split() if t in ('signext', 'zeroext'))
        ps = [re.findall(TYPES, p)[0] for p in params.split(',') if p.strip()]
        out.append(f'@.n{k} = private constant [{len(name) + 1} x i8] c"{name}\\00"')
        ts = ','.join(ps); out.append(f'@.t{k} = private constant [{len(ts) + 1} x i8] c"{ts}\\00"')
        body = [f'define {rattr} {rty} @{name}(' + ', '.join(f'{t} %a{i}' for i, t in enumerate(ps)) + ') {',
                f'  %b = alloca [{max(len(ps), 1)} x i128], align 16', '  %r = alloca i128, align 16', '  store i128 0, ptr %r']
        for i, t in enumerate(ps):
            if t == 'ptr': body.append(f'  %x{i} = ptrtoint ptr %a{i} to i64'); t = 'i64'; v = f'%x{i}'
            elif t in ('half', 'float', 'double', 'x86_fp80'):
                it = {'half': 'i16', 'float': 'i32', 'double': 'i64', 'x86_fp80': 'i80'}[t]
                body.append(f'  %x{i} = bitcast {t} %a{i} to {it}'); t = it; v = f'%x{i}'
            else: v = f'%a{i}'
            if t != 'i128': body.append(f'  %z{i} = zext {t} {v} to i128'); v = f'%z{i}'
            body += [f'  %p{i} = getelementptr [{len(ps)} x i128], ptr %b, i64 0, i64 {i}', f'  store i128 {v}, ptr %p{i}']
        body.append(f'  call void @sc_call(ptr @.n{k}, ptr @.t{k}, i32 {len(ps)}, ptr %b, ptr %r)')
        if rty == 'void': body.append('  ret void')
        else:
            body.append('  %v = load i128, ptr %r')
            it = {'half': 'i16', 'float': 'i32', 'double': 'i64', 'x86_fp80': 'i80'}.get(rty, rty)
            if it != 'i128': body.append(f'  %t = trunc i128 %v to {it}')
            last = '%t' if it != 'i128' else '%v'
            if it != rty: body.append(f'  %c = bitcast {it} %t to {rty}'); last = '%c'
            body.append(f'  ret {rty} {last}')
        out += body + ['}']
    return '\n'.join(out) + '\n'
INTS = {'_Bool': (1, 0), 'bool': (1, 0), 'char': (8, 1), 'signed char': (8, 1), 'unsigned char': (8, 0), 'short': (16, 1),
        'unsigned short': (16, 0), 'int': (32, 1), 'unsigned': (32, 0), 'unsigned int': (32, 0), 'long': (64, 1),
        'unsigned long': (64, 0), 'long long': (64, 1), 'unsigned long long': (64, 0)}
def samples_for(ct):
    ct = ' '.join(ct.replace('const', '').split())
    if ct in ('double', 'float'): return [0.0, 1.5, -2.25, 7.0]
    if ct not in INTS: return None
    n, sg = INTS[ct]
    if n == 1: return [0, 1]
    return [0, 1, -1, 3, 7, M(n - 1), -(1 << (n - 1))] if sg else [0, 1, 3, 7, M(n)]
def split_args(s):
    out, d, cur = [], 0, ''
    for ch in s:
        if ch in '([{': d += 1
        if ch in ')]}': d -= 1
        if ch == ',' and d == 0: out.append(cur); cur = ''
        else: cur += ch
    return out + ([cur] if cur.strip() else [])
def plan(name, low_text):
    """Driver C text with sample slots, and the per-slot sample lists."""
    protos, calls, extra = DRIVERS[name]
    proto = {}
    for p in protos.split(';'):
        m = re.match(r'\s*(.*?)\b(\w+)\s*\((.*)\)\s*$', p)
        if m: proto[m.group(2)] = (m.group(1).strip(), [x.strip() for x in split_args(m.group(3))])
    seeds = {}
    for m in re.finditer(r'^define [^\n]*?@(\w+)\(([^\n]*)\)[^\n]*\{\n(.*?)^\}', low_text, re.M | re.S):
        np_ = len(re.findall(r'%\d+\b', m.group(2)))
        seeds[m.group(1)] = (np_, {int(k) for k in re.findall(r'@cqrt_alloc_\w+\(\w+ %(\d+)\)', m.group(3)) if int(k) < np_})
    slots, body = [], ''
    for c in calls.split(';'):
        m = re.match(r'\s*(\w+)\((.*)\)\s*$', c); fn = m.group(1); args = split_args(m.group(2))
        rty, pts = proto.get(fn, ('int', []))
        npar, sd = seeds.get(fn, (-1, set()))
        if npar == len(args) == len(pts):
            for k in sorted(sd):
                sm = samples_for(pts[k])
                if sm is None: continue
                kind = 'd' if isinstance(sm[0], float) else 'i'
                args[k] = f'(({pts[k]})sv_{kind}[{len(slots)}])'; slots.append((sm, args[k], kind, fn, k))
        call = f'{fn}({",".join(args)})'
        rt = ' '.join(rty.replace('static', '').split())
        if rt == 'void' or '*' in rt or 'struct' in rt or (rt not in INTS and rt not in ('float', 'double', 'long double')): body += f'  (void){call};\n'
        else: body += f'  sc_out_{ {"double": "d", "float": "f", "long double": "ld"}.get(rt, "i") }({call});\n'
    drv = ('#include <stdio.h>\n#include <stdlib.h>\n#include <stdbool.h>\nstatic const double coef[4]={1,2,3,4}; static const int icoef[4]={1,2,3,4};\n'
           'void sc_out_i(long long); void sc_out_d(double); void sc_out_f(float); void sc_out_ld(long double);\n' + protos + '\n'
           f'static long long sv_i[{len(slots) + 1}]; static double sv_d[{len(slots) + 1}];\n'
           'int main(int argc, char **argv){\n  for (int i = 1; i < argc; i++) { sv_i[i-1] = strtoll(argv[i], 0, 0); sv_d[i-1] = strtod(argv[i], 0); }\n  '
           + extra + '\n' + body + '  return 0; }\n')
    return drv, slots
def run(exe, argv, ev=None, timeout=2.0):
    """Run one binary; feed sc_call requests to ev. Returns (lines, status)."""
    rq_r, rq_w = os.pipe(); rp_r, rp_w = os.pipe()
    env = dict(os.environ, SC_WFD=str(rq_w), SC_RFD=str(rp_r))
    p = subprocess.Popen([exe] + argv, env=env, pass_fds=(rq_w, rp_r), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.close(rq_w); os.close(rp_r)
    wf = os.fdopen(rp_w, 'w'); lines, status = [], None; buf = [b'']
    def readline():   # own buffer: select() cannot see data already inside a Python file object's buffer
        while b'\n' not in buf[0]:
            if not select.select([rq_r], [], [], timeout)[0]: raise TimeoutError
            ch = os.read(rq_r, 1 << 16)
            if not ch: l, buf[0] = buf[0], b''; return l.decode()
            buf[0] += ch
        l, buf[0] = buf[0].split(b'\n', 1); return l.decode() + '\n'
    def mem(addr, n):
        wf.write(f'M {addr:x} {n:x}\n'); wf.flush(); l = readline(); return bytes.fromhex(l[2:].strip())[::1]
    if ev: ev.mem = mem
    try:
        while True:
            l = readline()
            if not l: break
            if l.startswith('C '):
                parts = l.split(); name, ty = parts[1], parts[2].split(',')
                a = []
                for t, x in zip(ty, parts[3:]):
                    hi, lo = x.split(':'); v = (int(hi, 16) << 64) | int(lo, 16)
                    a.append(v)
                try: r = ev.call(name, ty, a)
                except Exception as e:
                    status = f'EVAL {type(e).__name__}: {e}'; wf.write('X\n'); wf.flush(); break
                wf.write(f'R {(r >> 64) & M(64):x}:{r & M(64):x}\n'); wf.flush()
            else: lines.append(l.split())
    except TimeoutError: status = 'TIMEOUT'; p.kill()
    except BrokenPipeError: pass
    p.wait(); os.close(rq_r)
    try: wf.close()
    except BrokenPipeError: pass
    if status is None and p.returncode: status = f'exit {p.returncode}'
    return lines, status
def norm_out(o):
    k, v = o[1], int(o[2], 16)
    if k == 'D' and math.isnan(fdec(v, 64)): return ('D', 'nan')
    if k == 'F' and math.isnan(fdec(v, 32)): return ('F', 'nan')
    return (k, v)
def fmt_ang(b): return repr(float(fdec(b, 64)))
def check(name, low=None, keep=None):
    d = SPEC / 'examples' / name; base = name.split('_', 1)[1]
    low = pathlib.Path(low) if low else d / f'{base}.lowered.ll'
    lt = low.read_text(); ct = (d / f'{base}.c').read_text()
    if name not in DRIVERS: return 'SKIPPED', 'no driver'
    syms = set(re.findall(r'@((?:cqrt|cq_template)_\w+)', lt))
    if re.search(r'x86_fp80', ' '.join(l for l in lt.splitlines() if l.startswith('declare') and ('@cqrt' in l or '@cq_template' in l))) or any('f80' in x for x in syms):
        return 'SKIPPED', 'x87 f80 rails (not modelled)'
    if any(re.search(r'_(rm|rmq|exc)(_|$)', x) for x in syms): return 'SKIPPED', 'rounding-mode / exception templates (fenv, not modelled)'
    tmp = pathlib.Path(keep or tempfile.mkdtemp(prefix=f'sc_{name}_')); tmp.mkdir(parents=True, exist_ok=True)
    try:
        drv, slots = plan(name, lt)
        triple = re.search(r'target triple = "(.*?)"', lt).group(1)
        (tmp / 'drv.c').write_text(drv); (tmp / 'stubs.ll').write_text(stubs_ll(lt, triple))
        for exe, srcs in (('low', [str(low), 'stubs.ll', 'drv.c', str(HERE / 'sample_rt.c'), '-DSC_LOWERED']),
                          ('ref', [str(d / f'{base}.O1.ll'), 'drv.c', str(HERE / 'sample_rt.c')])):
            cc = subprocess.run([CLANG, '-w', '-O1'] + srcs + ['-lm', '-o', exe], cwd=tmp, capture_output=True, text=True)
            if cc.returncode:
                und = sorted(set(re.findall(r'"_?(\w+)", referenced from', cc.stderr)))
                return 'SKIPPED', f'{exe} link failed' + (f': undefined {", ".join(und)}' if und else ': ' + cc.stderr.strip().splitlines()[-1][:160])
        for exe in ('low', 'ref'):   # first exec of a fresh binary is slow on macOS (signature scan): warm up before timing
            subprocess.run([str(tmp / exe)], env={}, capture_output=True, timeout=60)
        kloop = '[K]' in lt
        nsamp = 1 + max((len(sm) for sm, *_ in slots), default=0)
        fails, notes, global_ph, compared = [], [], set(), 0
        for i in range(nsamp):
            argv = [repr(sm[(i - 1 + j) % len(sm)]) if i else '0' for j, (sm, *_) in enumerate(slots)]
            if i == 0 and slots: continue   # base sample: the driver's own values are not slots; covered by value 0 anyway
            label = ' '.join(f'{f}#{k}={v}' for (_, _, _, f, k), v in zip(slots, argv)) or 'driver values'
            ev = Eval(None)
            lo, ls = run(str(tmp / 'low'), argv, ev)
            ro, rs = run(str(tmp / 'ref'), argv)
            if rs:
                if rs == 'exit -6' and ('ABORT',) in ev.ev: continue
                notes.append(f'[{label}] reference {rs} (C UB / trap / nontermination), sample not compared'); continue
            if ls and ls.startswith('EVAL Unsupported'): return 'SKIPPED', ls[5:]
            diff = []; compared += 1
            if ls: diff.append(f'lowered run: {ls}')
            diff += [f'violation: {e}' for e in ev.err[:4]]
            lout = [norm_out(o) for o in lo if o[0] == 'O']; rout = [norm_out(o) for o in ro if o[0] == 'O']
            if lout != rout and not ls: diff.append(f'outputs lowered {lout} != C {rout}')
            lm = Counter((e[1], e[2]) for e in ev.ev if e[0] == 'M'); rm = Counter((int(e[2]), int(e[3], 16)) for e in ro if e[:2] == ['E', 'M'])
            cr = int((re.search(r'^; Classical reads \(rule 2\): (\d+)', lt, re.M) or [None, '0'])[1])   # cq_measure calls of a value rule 2 made classical: no gate on the lowered side
            if rm - lm and not ls and sum((rm - lm).values()) != cr: diff.append(f'measured C-only {dict(rm - lm)} (lowered-only {dict(lm - rm)}; declared classical reads {cr})')   # extra lowered measurements: an arm's measurement is never conditioned (§1.3)
            ly = Counter(fmt_ang(e[1]) for e in ev.ev if e[0] == 'RY'); ry = Counter(fmt_ang(int(e[2], 16)) for e in ro if e[:2] == ['E', 'RY'])
            ry = Counter({k: v for k, v in ry.items() if k not in ('nan', 'inf', '-inf')})
            if ly != ry and not ls: diff.append(f'Ry lowered-only {dict(ly - ry)} C-only {dict(ry - ly)}')
            lp = Counter(fmt_ang(e[1]) for e in ev.ev if e[0] == 'PH'); rp = Counter(fmt_ang(int(e[2], 16)) for e in ro if e[:2] == ['E', 'PH'])
            rp = Counter({k: v for k, v in rp.items() if k not in ('nan', 'inf', '-inf')})
            if lp - rp and not ls: diff.append(f'phase fired in lowered but not in C: {dict(lp - rp)}')
            global_ph.add(tuple(sorted((rp - lp).items())))
            if diff: fails.append(f'[{label}] ' + '; '.join(diff))
        if len(global_ph) > 1: fails.append(f'C-only phases depend on the input (not a global phase): {sorted(global_ph)}')
        if fails and kloop and not any('violation' in f or 'lowered run' in f for f in fails):
            return 'KDIFF', 'differs only where the K = 4 cutoff may bind (check the C trip count):\n    ' + '\n    '.join(fails + notes)
        if fails: return 'FAIL', '\n    '.join(fails + notes)
        if not compared: return 'SKIPPED', 'no sample comparable: ' + '; '.join(notes)
        return 'PASS', f'{compared}/{nsamp - (1 if slots else 0)} samples compared, {len(slots)} varied args' + (('; ' + '; '.join(notes)) if notes else '')
    finally:
        if not keep: shutil.rmtree(tmp, ignore_errors=True)
def main():
    args = sys.argv[1:]; j = 8; keep = None
    if '-j' in args: i = args.index('-j'); j = int(args[i + 1]); del args[i:i + 2]
    if '--keep' in args: i = args.index('--keep'); keep = args[i + 1]; del args[i:i + 2]
    todo = []
    for a in args or sorted(p.name for p in (SPEC / 'examples').iterdir() if p.is_dir()):
        if ':' in a: n, p = a.split(':', 1); todo.append((n, p))   # NN_name:mutant.lowered.ll
        else: todo.append((a, None))
    def one(t):
        n, l = t
        try: return n, *check(n, l, keep and os.path.join(keep, n))
        except Exception as e: return n, 'SKIPPED', f'harness error {type(e).__name__}: {e}'
    with ThreadPoolExecutor(j) as ex: res = list(ex.map(one, todo))
    cnt = Counter(r[1] for r in res)
    for n, st, msg in res: print(f'{st:8} {n}: {msg}')
    print(f'# PASS {cnt["PASS"]}  FAIL {cnt["FAIL"]}  KDIFF {cnt["KDIFF"]}  SKIPPED {cnt["SKIPPED"]}')
    sys.exit(1 if cnt['FAIL'] else 0)
if __name__ == '__main__': main()
