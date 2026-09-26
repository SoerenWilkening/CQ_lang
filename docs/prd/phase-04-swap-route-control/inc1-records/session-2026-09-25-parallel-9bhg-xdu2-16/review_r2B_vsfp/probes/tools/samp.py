import pathlib, random, subprocess, sys, difflib
sys.path.insert(0, '.')
import h
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8")
RR = W/"docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16"
R = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16")
V0 = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp")
src_of = {}
for d in R.iterdir():
    if d.is_dir():
        for s in d.rglob("*.c"):
            if not s.name.endswith(".lib.c"):
                src_of["P_"+d.name+"__"+"_".join(s.relative_to(d).with_suffix("").parts)] = s
for root, dn in [(RR,"review_r1A_vsfp"),(RR,"review_r1B_vsfp"),(RR,"vsfp_probes"),(V0,"r1Bv"),(V0/"tools","fx"),(V0,"r2src")]:
    d = root/dn
    if d.exists():
        for s in d.rglob("*.c"):
            if not s.name.endswith(".lib.c") and "/out/" not in str(s):
                src_of["Q_"+dn+"__"+"_".join(s.relative_to(d).with_suffix("").parts)] = s
def twin_of(src):
    n = src.stem
    c = [n+"T", n+"_twin", n+"F"] + ([n[:-1]+"T"] if n[-1:] in "CSWf" else [])
    for x in c:
        p = src.with_name(x+".c")
        if p.exists(): return p
rows = [l.rstrip("\n").split("\t") for l in open(RR/"vsfp_probes/r2/results/twin2_final.txt") if l.startswith(("D->A\t","STREAM\t","A->D\t"))]
random.seed(int(sys.argv[1]))
da = [r for r in rows if r[0]=="D->A" and r[2]=="TRACE-IDENT"]
st = [r for r in rows if r[0]=="STREAM" and r[2]=="TRACE-IDENT"]
ad = [r for r in rows if r[0]=="A->D"]
pick = random.sample(da, 12) + random.sample(st, 6) + random.sample(ad, 3)
import shutil
D = pathlib.Path("src_samp"); D.mkdir(exist_ok=True)
for r in pick:
    s = src_of.get(r[1]); t = twin_of(s) if s else None
    if not s or not t:
        print(r[0], r[1], "NO-SRC/TWIN"); continue
    for p in (s, t):
        shutil.copy(p, D/(r[1]+("__T" if p==t else "")+".c"))
        lib = p.with_name(p.stem+".lib.c")
        if lib.exists(): shutil.copy(lib, D/(r[1]+("__T" if p==t else "")+".lib.c"))
    args = (s.with_name(s.stem+".args").read_text().split() if s.with_name(s.stem+".args").exists() else ["5","7"])
    out = subprocess.run(["python3","h.py","pair","subj","src_samp",r[1],r[1]+"__T"]+args,capture_output=True,text=True).stdout.splitlines()[0]
    sd = [l for l in difflib.unified_diff(s.read_text().splitlines(), t.read_text().splitlines(), lineterm="", n=0) if l[:1] in "+-" and l[:3] not in ("+++","---")]
    print(r[0], out[:230]); print("   DIFF:", " || ".join(x[:170] for x in sd[:4]))
