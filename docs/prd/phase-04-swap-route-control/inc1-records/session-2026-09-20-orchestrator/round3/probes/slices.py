#!/usr/bin/env python3
"""Run EVERY tests/e2e slice_*.c through MAIN and COMPOSED and byte-diff the
runtime trace against the committed .expected.log.  This is the layer that LINKS
(Rule 19) -- the corpus sweep is IR-only.  Reports, per slice: verdict on each
binary, and whether the trace matches the golden."""
import os, subprocess, sys, tempfile, hashlib

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a8a02006bc710dbc0"
S = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e25cef7b-131a-4e4d-a7b8-d6bf76310076/scratchpad"
LLVM = "/usr/local/opt/llvm@19/bin"
E2E = os.path.join(W, "tests/e2e")
TAGS = sys.argv[1:] or ["MAIN", "COMPOSED"]

slices = sorted(f for f in os.listdir(E2E) if f.startswith("slice_") and f.endswith(".c"))
res = {t: {} for t in TAGS}
tmp = tempfile.mkdtemp(prefix="cqslice")
for t in TAGS:
    opt = os.path.join(S, "bins", "cq-opt." + t)
    plug = os.path.join(S, "bins", "libCQPass.%s.so" % t)
    for i, f in enumerate(slices):
        base = f[:-2]
        src = os.path.join(E2E, f)
        s1 = os.path.join(tmp, base + ".s1.ll")
        s2 = os.path.join(tmp, base + ".s2.ll")
        r = subprocess.run([os.path.join(LLVM, "clang"), "-I" + os.path.join(W, "include"),
                            "-include", "CQ.h", "-O1", "-emit-llvm", "-S", src, "-o", s1],
                           capture_output=True)
        if r.returncode:
            res[t][f] = ("CLANGFAIL", "")
            continue
        r = subprocess.run([opt, "-load-pass-plugin", plug, "-passes=cq-lowering",
                            "-S", s1, "-o", s2], capture_output=True)
        if r.returncode:
            err = r.stderr.decode("utf8", "replace")
            msg = ""
            for line in err.splitlines():
                if line.startswith("error:") and ": cq " in line:
                    msg = line.split(": cq ", 1)[1].strip()
                    break
            res[t][f] = ("DECLINE", msg[:70])
            continue
        exe = os.path.join(tmp, base + ".exe")
        r = subprocess.run([os.path.join(LLVM, "clang"), s2,
                            os.path.join(W, "build/runtime/libcq_templates.a"),
                            os.path.join(W, "build/runtime/libcq_runtime.a"), "-o", exe],
                           capture_output=True)
        if r.returncode:
            res[t][f] = ("LINKFAIL", "")
            continue
        r = subprocess.run([exe], capture_output=True)
        trace = r.stdout
        gold = os.path.join(E2E, base + ".expected.log")
        if os.path.exists(gold):
            ok = open(gold, "rb").read() == trace
            res[t][f] = ("ACCEPT", "GOLD-OK" if ok else "GOLD-DIFF")
        else:
            res[t][f] = ("ACCEPT", "no-golden:" + hashlib.sha256(trace).hexdigest()[:12])
    print("DONE %s (%d slices)" % (t, len(slices)), flush=True)

print("\n== slices whose (verdict, golden) differ between %s ==" % " / ".join(TAGS))
n = 0
for f in slices:
    vals = [res[t][f] for t in TAGS]
    if len(set(vals)) > 1:
        n += 1
        print("  %-62s %s" % (f, "   ".join("%s=%s/%s" % (t, v[0], v[1]) for t, v in zip(TAGS, vals))))
print("differing: %d of %d" % (n, len(slices)))
print("\n== GOLD-DIFF / non-ACCEPT rows per binary ==")
for t in TAGS:
    bad = [(f, res[t][f]) for f in slices if res[t][f][0] != "ACCEPT" or res[t][f][1] not in ("GOLD-OK",)]
    print(" %s: %d" % (t, len(bad)))
    for f, v in bad:
        print("    %-62s %s %s" % (f, v[0], v[1]))
