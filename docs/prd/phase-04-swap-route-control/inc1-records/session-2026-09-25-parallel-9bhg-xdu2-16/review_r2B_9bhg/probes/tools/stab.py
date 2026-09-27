#!/usr/bin/env python3
"""stab.py LISTFILE OUTTSV RUNS — run each module under system/lifo/nofree x RUNS and gmalloc x1
with the SUBJECT cq-opt; record (rc, sha(out minus ModuleID), first error) per run; report variance.
Reference = first nofree run. Prints denominator."""
import sys, subprocess, hashlib, os, concurrent.futures as cf
R = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/r2B9"
SUBJ = os.environ.get("STAB_SUBJ", R + "/cq-opt.subj"); DBG = os.environ.get("STAB_DBG", R + "/cq-opt-debugalloc.subj")
def run(mode, f):
    env = dict(os.environ)
    env.pop("CQ_OPT_DEBUG_ALLOC", None); env.pop("DYLD_INSERT_LIBRARIES", None)
    if mode in ("lifo", "nofree"):
        env["CQ_OPT_DEBUG_ALLOC"] = mode; cmd = [DBG]
    elif mode == "gm":
        env["DYLD_INSERT_LIBRARIES"] = "/usr/lib/libgmalloc.dylib"; cmd = [SUBJ]
    else:
        cmd = [SUBJ]
    p = subprocess.run(cmd + ["-passes=cq-lowering", "-S", f, "-o", "-"], env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=600)
    out = b"\n".join(l for l in p.stdout.split(b"\n") if not l.startswith(b"; ModuleID"))
    err = [l for l in p.stderr.decode(errors="replace").split("\n") if "error:" in l]
    e = err[0].split("error:",1)[1].strip()[:140] if err else ""
    return (p.returncode, hashlib.sha256(out).hexdigest()[:12], e)
def one(f, runs):
    res = {}
    for m in ("nofree", "lifo", "sys"):
        res[m] = [run(m, f) for _ in range(runs)]
    res["gm"] = [run("gm", f)]
    return f, res
if __name__ == "__main__":
    lst, outp, runs = sys.argv[1], sys.argv[2], int(sys.argv[3])
    files = [l.strip() for l in open(lst) if l.strip()]
    print(f"denominator: {len(files)} modules x (3 modes x {runs} + gmalloc x1)", flush=True)
    nvar = 0; ncrash = 0; nnull = 0
    with cf.ProcessPoolExecutor(max_workers=5) as ex, open(outp, "w") as o:
        for f, res in ex.map(one, files, [runs]*len(files)):
            ref = res["nofree"][0]
            allr = [r for m in res for r in res[m]]
            distinct = sorted(set(allr))
            crash = [r for r in allr if r[0] not in (0, 1)]
            null_ok = res["nofree"][1:] == [ref]*(runs-1)
            if not null_ok: nnull += 1
            if len(distinct) > 1: nvar += 1
            if crash: ncrash += 1
            o.write("\t".join([os.path.basename(f), str(ref[0]), ref[1], ref[2],
                               "VAR" if len(distinct) > 1 else "stable",
                               "CRASH" if crash else "-",
                               ";".join(f"{m}:{sum(1 for r in res[m] if r!=ref)}/{len(res[m])}" for m in res)]) + "\n")
    print(f"null(nofree self-variance) modules: {nnull}; variant modules: {nvar}; crash modules: {ncrash}")
