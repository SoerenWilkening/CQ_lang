#!/usr/bin/env python3
"""libc_census.py <musl-checkout> : compile every C-standard-library TU of musl at clang -O1 (x86_64-linux-musl) and
report, per directory, how many TUs use only IR constructs the corpus has an example for. The non-clean buckets are
inline asm (syscall / TLS / atomics / traps: the host boundary, classical by design) and real lowering gaps.
Needs `make obj/include/bits/alltypes.h obj/include/bits/syscall.h ARCH=x86_64` run in the checkout once.
Measured 2026-10-20 on musl b1efda5 (C11 threads.h wrappers included): 752 TUs; 666 clean with the stock x86-64 asm
primitives, 752 clean with --arch-cq (musl_arch_cq/ replacing them by builtins). See LIBC_COVERAGE.md."""
import subprocess,re,os,sys,json,collections
M=sys.argv[1]; L='/usr/local/opt/llvm@19/bin/clang'
ARCH_CQ='--arch-cq' in sys.argv   # build with _tools/musl_arch_cq instead of arch/x86_64's asm primitives
DIRS=['ctype','errno','exit','fenv','locale','malloc','multibyte','prng','search','setjmp','signal','stdio','stdlib','string','time','env','math','complex','thread']
C11_THREAD=re.compile(r'^(thrd_|mtx_|cnd_|tss_|call_once)')  # C11 threads.h only; the POSIX pthread implementation is not standard C
INC=(['-I',os.path.join(os.path.dirname(os.path.abspath(__file__)),'musl_arch_cq')] if ARCH_CQ else [])+['-I',f'{M}/arch/x86_64','-I',f'{M}/arch/generic','-I',f'{M}/obj/include','-I',f'{M}/src/include','-I',f'{M}/src/internal','-I',f'{M}/include']
FLAGS=['-std=c99','-nostdinc','-ffreestanding','-frounding-math','-fno-strict-aliasing','-D_XOPEN_SOURCE=700','-w','-O1','-S','-emit-llvm','-o','-','-target','x86_64-linux-musl']
# Covered intrinsics are MEASURED: every llvm.* name that occurs in some examples/*/*.O1.ll (by base name, width
# suffix stripped), so the census can never count an intrinsic as covered without an example (R17).
def covered_intrinsics(spec):
    names=set()
    for d in os.listdir(f'{spec}/examples'):
        for f in os.listdir(f'{spec}/examples/{d}'):
            if f.endswith('.O1.ll'):
                for k in re.findall(r'@(llvm\.[\w.]+)',open(f'{spec}/examples/{d}/{f}').read()):
                    names.add(re.sub(r'\.(?:[fi]\d+|p\d+|v\d+[fi]\d+)+$','',k))
    return names
SPEC=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COVERED=covered_intrinsics(SPEC)
NOISE=('llvm.lifetime','llvm.dbg','llvm.assume','llvm.expect','llvm.experimental.noalias.scope.decl')   # no semantics to lower
# llvm.experimental.constrained.<op>: 80-82 define the _rm/_rmq/_exc grammar for EVERY FP op; such an intrinsic counts as
# covered when the plain <op> instruction/intrinsic has an example (musl is built with -frounding-math, so every FP op is
# constrained there).
PLAIN_OPS={'fadd','fsub','fmul','fdiv','frem','fcmp','fcmps','fptrunc','fpext','sitofp','uitofp','fptosi','fptoui','fmuladd','fma','sqrt','rint','nearbyint','trunc','floor','ceil','round','lrint','llrint','lround','llround','maxnum','minnum','pow','powi','sin','cos','exp','exp2','log','log2','log10'}
def constrained_covered(k):
    m=re.match(r'llvm\.experimental\.constrained\.(\w+)',k)
    if not m: return False
    op=m.group(1); op={'fcmps':'fcmp'}.get(op,op)
    return op in PLAIN_OPS and ('llvm.'+op in COVERED or op in BASIC_OPS)
BASIC_OPS={'fadd','fsub','fmul','fdiv','frem','fcmp','fptrunc','fpext','sitofp','uitofp','fptosi','fptoui'}  # instructions, every one in examples 13-19
VECTOR_OPS=('extractelement','insertelement','shufflevector')
def asm_kind(a):
    if 'syscall' in a: return 'asm:syscall'
    if 'fs:' in a or 'gs:' in a: return 'asm:tls'
    if 'lock' in a or 'xchg' in a or 'mfence' in a: return 'asm:atomic'
    if 'hlt' in a or 'ud2' in a or 'int' in a: return 'asm:trap'
    if a.strip()=='' or 'nop' in a: return None   # an empty asm with a memory clobber is a compiler fence: no semantics
    return 'asm:other:'+a[:24]
res={}
for d in DIRS:
    p=f'{M}/src/{d}'
    for f in sorted(os.listdir(p)):
        if not f.endswith('.c'): continue
        if d=='thread' and not C11_THREAD.match(f): continue
        r=subprocess.run([L]+FLAGS+INC+[f'{p}/{f}'],capture_output=True,text=True)
        if r.returncode: res[f'{d}/{f}']={'fail'}; continue
        ir=r.stdout; bad=set()
        # fixed 2-lane vectors (complex float ABI) are covered by example 103; wider vectors would be a gap
        if re.search(r'<(?:[3-9]|\d\d+) x ',ir): bad.add('vector')
        for k in set(re.findall(r'@(llvm\.[\w.]+)',ir)):
            base=re.sub(r'\.(?:[fi]\d+|p\d+|v\d+[fi]\d+)+$','',k)
            if base not in COVERED and not k.startswith(NOISE) and not constrained_covered(base): bad.add(base)
        for a in re.findall(r'asm (?:sideeffect )?"([^"]*)"',ir):
            k=asm_kind(a)
            if k: bad.add(k)
        res[f'{d}/{f}']=bad
d=collections.defaultdict(lambda:[0,0,collections.Counter()])
for f,b in res.items():
    k=f.split('/')[0]; d[k][0]+=1; d[k][1]+=(not b)
    for x in b: d[k][2][x]+=1
print('covered intrinsics (measured from examples):',len(COVERED))
print('TUs',len(res),'clean',sum(1 for b in res.values() if not b))
for k in sorted(d): print(f'{k:10s} {d[k][1]:3d}/{d[k][0]:3d}  {dict(d[k][2])}')
