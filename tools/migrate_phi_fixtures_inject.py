"""Fixture-integrity check (brief step 4): inject a forbidden construct into the
SUBJECT's own output and require the fixture's OWN FileCheck directives to catch
it.  Each fixture is run in three modes:
  CLEAN     the untouched output       -> every prefix must PASS
  <inject>  one forbidden line added   -> at least one prefix must FAIL
A fixture that passes CLEAN and passes every injection is BLIND, and blind is the
Inc-3 F-L6-1 / Inc-4 failure mode this whole re-derive exists to stop.
"""
import os, re, subprocess, sys, tempfile, json
R = os.environ["CQ_REPO"]; CQ = os.environ["CQ_OPT"]; PL = os.environ["CQ_PASS"]
FC = os.environ.get("FILECHECK", "/usr/local/opt/llvm@19/bin/FileCheck")
T = os.path.join(R, "ir-pass", "test")
RUN_RE = re.compile(r"^\s*;\s*RUN:\s*(.*)$")

# ⚠ WHERE THE INJECTION GOES IS THE WHOLE EXPERIMENT, and the first version of
# this harness got it wrong.  Injecting INSIDE the function body puts the extra
# line in the middle of the derived `CHECK-NEXT` chain, so ANY line at all breaks
# adjacency and every injection reports "caught" — which measures the chain, not
# the NOROUTE negatives, and would have reported a perfect score for a fixture
# whose negatives are all blind.  The line is therefore appended AFTER the last
# closing brace, among the declares: the CHECK-NEXT chain has ended there, so a
# catch can ONLY come from a whole-file `NOROUTE-NOT`.  The HARMLESS control at
# the same site is what proves the site is not simply always-fatal.
INJECTIONS = {
    # (a) a swap route resurfacing
    "cswap":      '  call void @cqrt_cswap(i32 0, i32 1, i32 2)',
    # (b) a _controlled Rz -- the pre-Inc-1 TENSORED gate, the defect itself
    "ctl_rz":     '  call void @cqrt_rz_i32_controlled(i32 0, i32 1, double 1.000000e-01)',
    # (c) a surviving front-end phase call the linker would never resolve
    "live_phi":   '  call void @cq_phi(double 1.000000e-01)',
    # (d) a DROPPED flag free -- deletion, not insertion: the one failure mode an
    #     "extra line" injection structurally cannot reach (Rule 6: a rail left
    #     allocated is a leak; a MISSING free is what the count prefix exists for)
    "drop_free":  None,
    # CONTROL: a line no negative names.  It MUST NOT be caught -- if it is, the
    # injection site is fatal for reasons that have nothing to do with the
    # assertions, and every other row above is meaningless.
    "HARMLESS_CONTROL": '  %zzzcontrol = add i32 0, 0',
}

def prefixes_and_cmds(path):
    out = []
    for ln in open(path, encoding="utf-8"):
        m = RUN_RE.match(ln)
        if m and "%filecheck" in m.group(1) and "%t.cqd0.ll" in m.group(1):
            out.append(m.group(1))
    return out

def check(fixture, ir_text, cmds):
    with tempfile.TemporaryDirectory() as td:
        p = os.path.join(td, "t.cqd0.ll"); open(p, "w").write(ir_text)
        for c in cmds:
            argv = c.replace("%filecheck", FC).replace("%s", fixture).replace("%t.cqd0.ll", p)
            argv = argv.split("<")[0].strip().split()
            r = subprocess.run(argv, stdin=open(p), capture_output=True, text=True)
            if r.returncode != 0:
                return False, c
    return True, None

def main():
    names = [l.strip() for l in open(sys.argv[1]) if l.strip()]
    res = {}
    for b in names:
        path = os.path.join(T, b)
        if not os.path.exists(path):
            res[b] = {"skip": "deleted"}; continue
        r = subprocess.run([CQ, "-load-pass-plugin", PL, "-passes=cq-lowering", "-S", path],
                           capture_output=True, text=True)
        if r.returncode != 0:
            res[b] = {"skip": "declines"}; continue
        cmds = prefixes_and_cmds(path)
        if not cmds:
            res[b] = {"skip": "no cqd0 filecheck run lines"}; continue
        ok, why = check(path, r.stdout, cmds)
        rec = {"clean": ok, "clean_fail": why, "caught": {}}
        lines = r.stdout.split("\n")
        # append-site: after the LAST closing brace (past the CHECK-NEXT chain)
        anchor = max((i for i, l in enumerate(lines) if l.startswith("}")), default=None)
        for name, inj in INJECTIONS.items():
            if inj is None:
                # deletion: drop the FIRST cqrt_free
                mod = [l for i, l in enumerate(lines)
                       if not (l.strip().startswith("call void @cqrt_free(")
                               and not any(x.strip().startswith("call void @cqrt_free(")
                                           for x in lines[:i]))]
                if len(mod) == len(lines):
                    rec["caught"][name] = "n/a (no free emitted)"; continue
                txt = "\n".join(mod)
            else:
                if anchor is None:
                    rec["caught"][name] = "n/a"; continue
                mod = lines[:anchor + 1] + [inj] + lines[anchor + 1:]
                txt = "\n".join(mod)
            passed, _ = check(path, txt, cmds)
            rec["caught"][name] = (not passed)   # True == the injection was CAUGHT
        res[b] = rec
    json.dump(res, open(sys.argv[2], "w"), indent=0)
    tot = [v for v in res.values() if "skip" not in v]
    print("fixtures probed:", len(tot), " skipped:", len(res) - len(tot))
    print("CLEAN pass:", sum(1 for v in tot if v["clean"]), "/", len(tot))
    for k in INJECTIONS:
        c = sum(1 for v in tot if v["caught"].get(k) is True)
        na = sum(1 for v in tot if isinstance(v["caught"].get(k), str))
        blind = [b for b, v in res.items() if "skip" not in v and v["caught"].get(k) is False]
        print(f"  {k:10s} caught {c}/{len(tot)-na}  (n/a {na})  BLIND={len(blind)}")
        for b in blind[:10]:
            print("      BLIND:", b)

main()
