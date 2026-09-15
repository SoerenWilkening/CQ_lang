#!/usr/bin/env python3
"""inject_T.py — Rule-12 MUTATION validation for Track T's accept fixtures.

WHY IT RUNS THE FIXTURE'S OWN RUN LINES. An earlier matrix in this tree reported
45 MISSED against fixtures that catch everything, because it ran
`FileCheck --check-prefix` by hand and dropped the RUN line's own flags — "a
harness that runs a weaker command than lit measures itself, not the fixtures"
(CLAUDE.md L10). This one parses each `; RUN:` line of the fixture, substitutes
lit's own `%cq-opt` / `%cq-pass` / `%filecheck` / `%s` / `%t`, runs the cq-opt
line ONCE to get the lowered IR, then applies a mutation to that IR and re-runs
EVERY FileCheck line verbatim.

A mutation that does not apply is N/A and is REPORTED, never scored as a pass.
Exits NON-ZERO on: MISSED > 0, or zero mutations applied overall (the
"0 mutations, MISSED 0" vacuity trap).
"""
import os, re, subprocess, sys, tempfile, shutil

BUILD = os.environ.get("CQ_T_BUILD", "/Users/sorenwilkening/Desktop/CQ_T/build")
LLVM  = "/usr/local/opt/llvm@19/bin"
CQOPT = os.path.join(BUILD, "ir-pass", "cq-opt")
CQPASS= os.path.join(BUILD, "ir-pass", "libCQPass.so")
FC    = os.path.join(LLVM, "FileCheck")

def runlines(path):
    out = []
    for ln in open(path):
        m = re.match(r'^\s*;\s*RUN:\s*(.*)$', ln)
        if m:
            out.append(m.group(1).strip())
    return out

def subst(cmd, src, tprefix):
    cmd = cmd.replace("%cq-opt", CQOPT).replace("%cq-pass", CQPASS)
    cmd = cmd.replace("%filecheck", FC).replace("%s", src).replace("%t", tprefix)
    return cmd

# ---- the mutations. Each returns a NEW text or None (= not applicable). ----
def _lines(t): return t.split("\n")

def m_drop_unc(t):
    ls = _lines(t)
    for i, l in enumerate(ls):
        if "_unc(" in l and "call void" in l:
            return "\n".join(ls[:i] + ls[i+1:])
    return None

def m_drop_free(t):
    ls = _lines(t)
    for i, l in enumerate(ls):
        if "@cqrt_free(" in l:
            return "\n".join(ls[:i] + ls[i+1:])
    return None

def m_free_before_unc(t):
    """THE RULE-6 BRIGHT LINE: free a rail before its adjoint returns it to |0>."""
    ls = _lines(t)
    for i, l in enumerate(ls):
        if "_unc(" in l and "call void" in l:
            for j in range(i + 1, min(i + 4, len(ls))):
                if "@cqrt_free(" in ls[j]:
                    ls[i], ls[j] = ls[j], ls[i]
                    return "\n".join(ls)
    return None

def m_drop_forward(t):
    ls = _lines(t)
    for i, l in enumerate(ls):
        if re.search(r'=\s*call i32 @cq_template_\w+_hl\(', l) and "_unc" not in l:
            return "\n".join(ls[:i] + ls[i+1:])
    return None

def m_free_user_register(t):
    """Free the ALLOC-minted user register — the hidden measurement Rule 6 forbids."""
    ls = _lines(t)
    reg = None
    for l in ls:
        m = re.search(r'(%\w+)\s*=\s*call i32 @cqrt_alloc_', l)
        if m:
            reg = m.group(1); break
    if reg is None:
        return None
    for i, l in enumerate(ls):
        if "@cqrt_free(" in l:
            return "\n".join(ls[:i] + [re.sub(r'@cqrt_free\(i32 [^)]*\)',
                                              '@cqrt_free(i32 %s)' % reg, l)] + ls[i+1:])
    return None

def m_extra_ry(t):
    """A stray uncontrolled Ry on the user register."""
    ls = _lines(t)
    for i, l in enumerate(ls):
        m = re.search(r'(%\w+)\s*=\s*call i32 @cqrt_alloc_i32', l)
        if m:
            inj = "  call void @cqrt_ry_i32(i32 %s, double 1.000000e+00)" % m.group(1)
            return "\n".join(ls[:i+1] + [inj] + ls[i+1:])
    return None

def m_double_unc(t):
    """Duplicate an adjoint — the over-reversed rail (K adjoints, one forward)."""
    ls = _lines(t)
    for i, l in enumerate(ls):
        if "_unc(" in l and "call void" in l:
            return "\n".join(ls[:i+1] + [l] + ls[i+1:])
    return None

def m_inject_unc_free(t):
    """For a LEAK fixture: inject the discharge it must NOT have."""
    ls = _lines(t)
    for i, l in enumerate(ls):
        m = re.search(r'(%\w+)\s*=\s*call i32 @(cq_template_\w+_hl)\(i32 (%\w+), i32 ([^)]*)\)', l)
        if m and "_unc" not in l:
            inj = ["  call void @%s_unc(i32 %s, i32 %s, i32 %s)" %
                   (m.group(2), m.group(1), m.group(3), m.group(4)),
                   "  call void @cqrt_free(i32 %s)" % m.group(1)]
            return "\n".join(ls[:i+1] + inj + ls[i+1:])
    return None

MUTS = [("drop_unc", m_drop_unc), ("drop_free", m_drop_free),
        ("free_before_unc", m_free_before_unc), ("drop_forward", m_drop_forward),
        ("free_user_register", m_free_user_register), ("extra_ry", m_extra_ry),
        ("double_unc", m_double_unc), ("inject_unc_free", m_inject_unc_free)]

def main(argv):
    if len(argv) < 2:
        print("inject_T.py <fixture.ll> [...]  — NO FIXTURE ARGUMENT IS A HOLE", file=sys.stderr)
        return 2
    total = missed = na = 0
    rows = []
    for fx in argv[1:]:
        rl = runlines(fx)
        opt = [c for c in rl if "cq-opt" in c]
        fcs = [c for c in rl if "cq-opt" not in c and "filecheck" in c]
        if not opt or not fcs:
            print("SKIP (not a two-stage accept fixture): %s" % fx, file=sys.stderr)
            continue
        d = tempfile.mkdtemp()
        tpre = os.path.join(d, "t")
        cmd = subst(opt[0], fx, tpre)
        if subprocess.call(cmd, shell=True, stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL) != 0:
            print("SKIP (fixture does not accept): %s" % fx, file=sys.stderr)
            shutil.rmtree(d); continue
        cqd0 = tpre + ".cqd0.ll"
        base = open(cqd0).read()
        # sanity: the UNMUTATED output must pass every FileCheck line.
        for c in fcs:
            rc = subprocess.call(subst(c, fx, tpre), shell=True,
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            assert rc == 0, "baseline FileCheck FAILED for %s: %s" % (fx, c)
        for name, fn in MUTS:
            mt = fn(base)
            if mt is None or mt == base:
                na += 1; rows.append((os.path.basename(fx), name, "N/A")); continue
            total += 1
            open(cqd0, "w").write(mt)
            caught = False
            for c in fcs:
                if subprocess.call(subst(c, fx, tpre), shell=True,
                                   stdout=subprocess.DEVNULL,
                                   stderr=subprocess.DEVNULL) != 0:
                    caught = True; break
            rows.append((os.path.basename(fx), name, "caught" if caught else "MISSED"))
            if not caught:
                missed += 1
            open(cqd0, "w").write(base)
        shutil.rmtree(d)
    w = max((len(r[0]) for r in rows), default=10)
    for r in rows:
        print("%-*s  %-18s  %s" % (w, r[0], r[1], r[2]))
    print("\n%d mutations applied, MISSED %d, N/A %d" % (total, missed, na))
    if total == 0:
        print("FAIL: zero mutations applied — that is a HOLE, not a pass", file=sys.stderr)
        return 2
    return 1 if missed else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
