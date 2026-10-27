import re,sys,glob
OPRE=re.compile(r'^\s*(%[\w.]+) = (?!tail call|call)(\w+)')  # non-call producing instr
def funcs(text):
    out={}; cur=None
    for i,l in enumerate(text):
        m=re.match(r'define .*@([\w.]+)\(',l)
        if m: cur=m.group(1); out[cur]=[]; continue
        if l.startswith('}'): cur=None; continue
        if cur: out[cur].append(i)
    return out
def strip_cm(l): return re.sub(r'\s*; (C|IR): .*$','',l)
def annotate_file(d):
    base=d.rstrip('/').split('_',1)[1]
    csrc=open(f'{d}/{base}.c').read()
    o1p=f'{d}/{base}.O1.ll'; lowp=f'{d}/{base}.lowered.ll'
    o1=[strip_cm(l) for l in open(o1p).read().split('\n')]; low=[strip_cm(l) for l in open(lowp).read().split('\n')]
    cfun={}
    for m in re.finditer(r'(\w[\w ]*?\**)\s+(\w+)\s*\(([^)]*)\)\s*\{(.*?)\n?\}',csrc,re.S):
        cfun[m.group(2)]=m.group(4)
    fo=funcs(o1); fl=funcs(low)
    for fn,lines in fo.items():
        body=cfun.get(fn,'')
        thetas=re.findall(r'cq_theta\(&(\w+),\s*(\w+)\)',body)
        decl=re.findall(r'\b(\w[\w ]*?)\s+(\w+)(?:\s*=\s*\w+)?(?:,\s*(\w+)\s*=\s*\w+)?;',body)
        mexpr=re.search(r'cq_measure\((.*)\)\s*;',body); mexpr=mexpr.group(1) if mexpr else '...'
        yexpr=re.search(r'\b\w[\w ]*?\s+(\w+)\s*=\s*([^;=]+);\s*(?:return\s+)?cq_measure',body)
        opexpr=MULTI.get(fn) or ([f'{yexpr.group(1)} = {yexpr.group(2)};'] if yexpr else [mexpr])
        phi=re.search(r'if\s*\((.*?)\)\s*cq_phi\((\w+)\)',body)
        ti=0; oi=0; names={}  # O1 value name -> C
        ops=[]  # O1 op value names in order
        for i in lines:
            l=o1[i]; s=l.strip()
            if 'call' in s and '@cq_theta' in s:
                v,a=thetas[ti] if ti<len(thetas) else ('x','th'); ti+=1
                o1[i]=l.rstrip()+f'    ; C: cq_theta(&{v}, {a});'
            elif '@cq_measure' in s: o1[i]=l.rstrip()+f'    ; C: cq_measure({mexpr})'
            elif '@cq_phi' in s: o1[i]=l.rstrip()+f'    ; C: cq_phi({phi.group(2)});'
            elif s.startswith('ret '): o1[i]=l.rstrip()+f'    ; C: return'
            elif s.startswith('br i1'): o1[i]=l.rstrip()+f'    ; C: if ({phi.group(1)})'
            elif s.startswith('br label'): o1[i]=l.rstrip()+'    ; C: end of if'
            elif re.match(r'%[\w.]+ = ',s) and not s.startswith('%') is False:
                m=re.match(r'(%[\w.]+) = (?:tail call \w+ @(llvm\.[\w.]+)|(\w+))',s)
                if m:
                    name=m.group(1); ops.append(name)
                    c = (f'if ({phi.group(1)})' if phi and ('cmp' in s) else (opexpr[oi] if oi<len(opexpr) else opexpr[-1])); 
                    if not (phi and 'cmp' in s): oi+=1
                    o1[i]=l.rstrip()+f'    ; C: {c}'
        # lowered
        if fn not in fl: continue
        o1body=[o1[i] for i in lines]
        thetal=[strip_cm(o1[i]).strip() for i in lines if '@cq_theta' in o1[i]]
        opl=[strip_cm(o1[i]).strip() for i in lines if re.match(r'\s*%[\w.]+ = ',o1[i]) and '@cq_theta' not in o1[i] and '@cq_measure' not in o1[i]]
        meas=[strip_cm(o1[i]).strip() for i in lines if '@cq_measure' in o1[i]][0]
        retl=[strip_cm(o1[i]).strip() for i in lines if o1[i].strip().startswith('ret ')][0]
        brl=[strip_cm(o1[i]).strip() for i in lines if o1[i].strip().startswith('br i1')]
        phil=[strip_cm(o1[i]).strip() for i in lines if '@cq_phi' in o1[i]]
        def short(s): # "%4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #2" -> "%4 = cq_theta_si32(%0, %1)"
            m=re.match(r'(%[\w.]+) = tail call [\w ]+ @([\w.]+)\((.*)\) #\d+',s)
            if m: args=', '.join(a.split()[-1] for a in m.group(3).split(',')); return f'{m.group(1)} = {m.group(2)}({args})'
            return s
        ti=0; oi=0; prod={}  # lowered handle -> O1 op string
        for i in fl[fn]:
            l=low[i]; s=l.strip()
            m=re.match(r'(%[\w.]+) = call i32 @cqrt_alloc_',s)
            if m: prod[m.group(1)]=None; low[i]=l.rstrip()+f'    ; IR: {short(thetal[ti])}  [register]'; continue
            if s.startswith('call void @cqrt_ry_'): low[i]=l.rstrip()+f'    ; IR: {short(thetal[ti])}  [Ry]'; ti+=1; continue
            m=re.match(r'(%[\w.]+) = call i32 @cq_template_',s)
            if m: prod[m.group(1)]=opl[oi]; low[i]=l.rstrip()+f'    ; IR: {opl[oi]}'; oi+=1; continue
            m=re.match(r'call void @cq_template_\w+_unc\((?:i32 )?(%[\w.]+)',s)
            if m: low[i]=l.rstrip()+f'    ; IR: uncompute {prod[m.group(1)].split(" = ")[0]}'; continue
            m=re.match(r'call void @cqrt_free\(i32 (%[\w.]+)\)',s)
            if m: low[i]=l.rstrip()+f'    ; IR: release the {prod[m.group(1)].split(" = ")[0]} rail (|0>)'; continue
            if s.startswith('call void @cqrt_rz_i1'):
                low[i]=l.rstrip()+f'    ; IR: block under {brl[0]}: {short(phil[0]).replace("tail call void ","")}'; continue
            if '@cqrt_measure_' in s: low[i]=l.rstrip()+f'    ; IR: {short(meas)}'; continue
            if s.startswith('ret '): low[i]=l.rstrip()+f'    ; IR: {retl}'; continue
    open(o1p,'w').write('\n'.join(o1)); open(lowp,'w').write('\n'.join(low))
MULTI={'high_word':['u.d = x;  (bits of x)','u.w[1]  (high word: bits >> 32)','u.w[1]  (as uint32_t)'],
       'from_words':['u.w[0] = l;','u.w[1] = h;','u.w[1] = h;  (into bits 32..63)','u.w[0] = l; u.w[1] = h;  (combined bits)','u.d'],
       'bits_of':['memcpy(&b, &x, 8);']}
for d in sys.argv[1:]: annotate_file(d)
