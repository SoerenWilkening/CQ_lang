import re,sys,glob,os
# For each lowered module: every cqrt_ry_<W>_controlled(f, h, a): find h's defining cqrt_alloc_<W>(arg) (through
# same-function SSA name). Report RUNTIME if arg is an SSA value (%...), LITERAL if constant, OTHER if h is not an alloc.
for p in sorted(glob.glob(sys.argv[1]+'/*.s2.ll')):
    txt=open(p).read()
    kinds=[]
    for fn in re.findall(r'define [^{]*\{(.*?)\n\}', txt, re.S):
        allocs=dict(re.findall(r'(%[\w.]+) = (?:tail )?call i32 @cqrt_alloc_\w+\((?:[\w ]+) ([^)]*)\)', fn))
        for f,h,a in re.findall(r'call void @cqrt_ry_\w+_controlled\(i32 (%[\w.]+), i32 (%[\w.]+), double ([^)]*)\)', fn):
            if h in allocs:
                arg=allocs[h].strip()
                kinds.append('RUNTIME' if arg.startswith('%') else 'LITERAL:'+arg)
            else:
                kinds.append('OTHER')
    print(os.path.basename(p)[:-6], ' '.join(kinds) if kinds else 'NO-CONTROLLED-RY')
