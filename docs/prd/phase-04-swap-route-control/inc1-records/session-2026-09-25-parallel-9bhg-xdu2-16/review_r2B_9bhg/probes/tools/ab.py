#!/usr/bin/env python3
"""ab.py LIST MUTDIR OUT [modes] — compare subject vs mutant (rc, out-hash) per module per mode.
modes: sys,lifo,nofree (mutant dir holds cq-opt + cq-opt-debugalloc). Prints denominator & movers."""
import sys, subprocess, hashlib, os, concurrent.futures as cf
R="/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r2B9"
def run(opt, dbg, mode, f):
    env=dict(os.environ); env.pop("CQ_OPT_DEBUG_ALLOC",None)
    cmd=[opt]
    if mode in ("lifo","nofree"): env["CQ_OPT_DEBUG_ALLOC"]=mode; cmd=[dbg]
    p=subprocess.run(cmd+["-passes=cq-lowering","-S",f,"-o","-"],env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,timeout=600)
    out=b"\n".join(l for l in p.stdout.split(b"\n") if not l.startswith(b"; ModuleID"))
    err=[l for l in p.stderr.decode(errors="replace").split("\n") if "error:" in l]
    return (p.returncode, hashlib.sha256(out).hexdigest()[:12], err[0].split("error:",1)[1].strip()[:110] if err else "")
def one(args):
    f, mut, modes = args
    r=[]
    for m in modes:
        a=run(R+"/cq-opt.subj", R+"/cq-opt-debugalloc.subj", m, f)
        a2=run(R+"/cq-opt.subj", R+"/cq-opt-debugalloc.subj", m, f)
        b=run(mut+"/cq-opt", mut+"/cq-opt-debugalloc", m, f)
        r.append((m,a,a2,b))
    return f,r
if __name__ == "__main__":
    lst,mut,outp=sys.argv[1],sys.argv[2],sys.argv[3]
    modes=(sys.argv[4] if len(sys.argv)>4 else "sys").split(",")
    files=[l.strip() for l in open(lst) if l.strip()]
    print(f"denominator: {len(files)} modules x modes {modes}", flush=True)
    nnull=0; nmov=0
    with cf.ProcessPoolExecutor(max_workers=5) as ex, open(outp,"w") as o:
        for f,r in ex.map(one,[(f,mut,modes) for f in files]):
            for m,a,a2,b in r:
                if a!=a2: nnull+=1; o.write(f"NULLDIFF\t{m}\t{os.path.basename(f)}\t{a}\t{a2}\n")
                if a!=b:
                    nmov+=1; o.write(f"MOVER\t{m}\t{os.path.basename(f)}\tsubj={a}\tmut={b}\n")
    print(f"null (subject self) diffs: {nnull}; movers: {nmov}")
