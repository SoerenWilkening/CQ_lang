import sys, h, concurrent.futures as cf, hashlib
names = sys.argv[1:]
def one(n):
    out = {}
    for t in ("main","subj","comp","9bhg"):
        r = h.verdict(t, "src", n)
        out[t] = (r["v"], r.get("msg","")[-60:], hashlib.sha1(r.get("trace","").encode()).hexdigest()[:8] if r["v"]=="ACC" else "")
    return n, out
with cf.ThreadPoolExecutor(6) as ex:
    for n, o in ex.map(one, names):
        s, c, b, m = o["subj"], o["comp"], o["9bhg"], o["main"]
        flag = []
        if c != s: flag.append("COMP!=SUBJ")
        if c[0]=="ACC" and s[0]!="ACC" and b[0]!="ACC": flag.append("COMPOSED-ONLY-ACCEPT")
        print(f"{n:8s} main={m[0]}:{m[2]} subj={s[0]}:{s[2]} comp={c[0]}:{c[2]} 9bhg={b[0]}:{b[2]} {' '.join(flag)}")
