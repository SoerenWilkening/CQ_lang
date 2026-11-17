#!/usr/bin/env python3
"""llvmlibc_census.py <llvm-project/libc> : the libc_census.py measurement applied to LLVM libc's generic libm
(libc/src/math/generic/*.cpp, C++17, freestanding, compiled with clang++ -O1 -fno-exceptions -fno-rtti), the most
C23-complete libm that clang can build. Reports (1) how many TUs use only IR constructs that have a corpus example
(the covered intrinsic list is measured from examples/*/*.O1.ll, as in libc_census.py), (2) which C23 math names have
a body here. Sparse checkout: git clone --depth 1 --filter=blob:none --sparse llvm-project && git sparse-checkout set
libc/src/math libc/src/__support libc/include libc/hdr libc/src/errno libc/src/fenv libc/shared."""
import subprocess,re,os,sys,collections
LIBC=sys.argv[1]; L='/usr/local/opt/llvm@19/bin/clang++'
FLAGS=['-std=c++17','-O1','-S','-emit-llvm','-o','-','-I',LIBC,'-DLIBC_NAMESPACE=__llvm_libc','-ffreestanding','-fno-exceptions','-fno-rtti','-nostdinc++','-w']
SPEC=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def covered_intrinsics(spec):
    names=set()
    for d in os.listdir(f'{spec}/examples'):
        for f in os.listdir(f'{spec}/examples/{d}'):
            if f.endswith('.O1.ll'):
                for k in re.findall(r'@(llvm\.[\w.]+)',open(f'{spec}/examples/{d}/{f}').read()):
                    names.add(re.sub(r'\.(?:[fi]\d+|p\d+|v\d+[fi]\d+|bf16)+$','',k))
    return names
COVERED=covered_intrinsics(SPEC)
NOISE=('llvm.lifetime','llvm.dbg','llvm.assume','llvm.expect','llvm.experimental.noalias.scope.decl')
PLAIN_OPS={'fadd','fsub','fmul','fdiv','frem','fcmp','fcmps','fptrunc','fpext','sitofp','uitofp','fptosi','fptoui','fmuladd','fma','sqrt','rint','nearbyint','trunc','floor','ceil','round','lrint','llrint','lround','llround','maxnum','minnum','pow','powi','sin','cos','exp','exp2','log','log2','log10'}
BASIC_OPS={'fadd','fsub','fmul','fdiv','frem','fcmp','fptrunc','fpext','sitofp','uitofp','fptosi','fptoui'}
def constrained_covered(k):
    m=re.match(r'llvm\.experimental\.constrained\.(\w+)',k)
    if not m: return False
    op={'fcmps':'fcmp'}.get(m.group(1),m.group(1))
    return op in PLAIN_OPS and ('llvm.'+op in COVERED or op in BASIC_OPS)
CPP_ONLY=('invoke','landingpad','resume','cleanuppad','catchpad')
res={}; fails=[]
gen=f'{LIBC}/src/math/generic'
for f in sorted(os.listdir(gen)):
    if not f.endswith('.cpp'): continue
    r=subprocess.run([L]+FLAGS+[f'{gen}/{f}'],capture_output=True,text=True)
    if r.returncode: fails.append(f); continue
    ir=r.stdout; bad=set()
    for k in set(re.findall(r'@(llvm\.[\w.]+)',ir)):
        base=re.sub(r'\.(?:[fi]\d+|p\d+|v\d+[fi]\d+|bf16)+$','',k)
        if base not in COVERED and not k.startswith(NOISE) and not constrained_covered(base): bad.add(base)
    for op in CPP_ONLY:
        if re.search(r'^\s*(?:%[\w.]+ = )?'+op+r'\b',ir,re.M): bad.add(op)
    # fixed-width vectors: N lanes are N rails (103 pins the 2-lane form; the rule is per lane) - not a gap
    if re.search(r'\bbfloat\b',ir): bad.add('bfloat')
    if re.search(r'\bfp128\b',ir): bad.add('fp128')
    for a in re.findall(r'asm (?:sideeffect )?"([^"]*)"',ir):
        if a.strip(): bad.add('asm:'+a[:20])
    res[f]=bad
print('LLVM libc generic libm:',len(res),'TUs compiled,',len(fails),'failed',fails[:5])
print('clean (every construct has an example):',sum(1 for b in res.values() if not b))
c=collections.Counter(x for b in res.values() for x in b); print('uncovered constructs:',dict(c))
# C23 math names (from the standard, by hand): which have a body here, in which precisions
C23=['exp10','exp2m1','exp10m1','log2p1','log10p1','logp1','roundeven','fromfp','ufromfp','fromfpx','ufromfpx','llogb','nextup','nextdown','fmaximum','fminimum','fmaximum_num','fminimum_num','fmaximum_mag','fminimum_mag','fmaximum_mag_num','fminimum_mag_num','compoundn','pown','powr','rootn','rsqrt','sinpi','cospi','tanpi','asinpi','acospi','atanpi','atan2pi','totalorder','totalordermag','canonicalize','getpayload','setpayload','setpayloadsig','fadd','fsub','fmul','fdiv','ffma','fsqrt','dadd','dsub','dmul','ddiv','dfma','dsqrt']
# precisions: ordinary names come in double/float/long double; the narrowing f* names in (double args, long double args)
# = ('', 'l'); the narrowing d* names only with long double args = ('l')
def precs(n): return ('l',) if n.startswith('d') and n[1:] in ('add','sub','mul','div','fma','sqrt') else (('','l') if n in ('fadd','fsub','fmul','fdiv','ffma','fsqrt') else ('','f','l'))
have={n:[s for s in precs(n) if f'{n}{s}.cpp' in res] for n in C23}
tot=sum(len(v) for v in have.values()); want=sum(len(precs(n)) for n in C23); print(f'C23 math names with a body: {sum(1 for v in have.values() if v)}/{len(C23)} names, {tot}/{want} (name,precision) pairs')
print('missing names:',[n for n,v in have.items() if not v])
print('missing precisions:',{n:[s for s in precs(n) if s not in v] for n,v in have.items() if v and len(v)<len(precs(n))})
