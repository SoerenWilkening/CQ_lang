import hashlib, os, re, sys, collections
d = "/Users/sorenwilkening/Desktop/CQ_merge/ir-pass/test"
groups = collections.defaultdict(list)
verd = {}
for fn in sorted(os.listdir(d)):
    if not fn.endswith(".ll"): continue
    p = os.path.join(d, fn)
    body, runs = [], []
    for line in open(p, encoding="utf-8", errors="replace"):
        s = line.strip()
        if s.startswith(";"):
            if "RUN:" in s: runs.append(s)
            continue
        if not s: continue
        body.append(s)
    h = hashlib.sha256("\n".join(body).encode()).hexdigest()
    groups[h].append(fn)
    v = set()
    for r in runs:
        if re.search(r'\bnot\s+%cq-opt', r): v.add("DECLINE")
        elif "%cq-opt" in r: v.add("ACCEPT")
    verd[fn] = ",".join(sorted(v)) or "NONE"
dups = {h: fs for h, fs in groups.items() if len(fs) > 1}
mixed = 0
print("fixtures scanned:", sum(len(f) for f in groups.values()))
print("duplicate-body groups:", len(dups))
for h, fs in sorted(dups.items()):
    vs = {verd[f] for f in fs}
    tag = "  *** MIXED VERDICT ***" if len(vs) > 1 else ""
    if len(vs) > 1: mixed += 1
    print("  [%s] %s -> %s%s" % (h[:12], ", ".join(fs), " | ".join(sorted(vs)), tag))
print("groups with CONTRADICTORY verdicts:", mixed)
