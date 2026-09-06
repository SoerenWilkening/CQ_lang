#!/usr/bin/env python3
"""migrate_phi_fixtures_kickback.py — the SUBJECT-vs-ORACLE witness for the
kickback stream (MIGRATION_REPORT.md §10 item 4, agent prep_a2).

prep_a's `--verify-oracle` could answer classes U and D exactly, because the
migrated module contains no `cq_phi` at all and the pre-3qlq binary answers it
the same way the Inc-1 binary does.  For classes A/S/MIX it degraded to
well-formedness (`opt -passes=verify`), because the ORACLE cannot lower
`call void @cq_phi(double)` — it has never heard of the prototype.  So nothing
in that sweep ever looked at the emitted GATE STREAM, which is the entire
increment.

This tool closes that gap by comparing DIFFERENT INPUTS on purpose:

    ORACLE  on the PRE-MIGRATION module   (the register `cq_phi_<sfx>` spelling)
    SUBJECT on the POST-MIGRATION module  (the register-free `void @cq_phi`)

PRD §10.2 diff class (a) says those two streams must agree once the retirement is
applied, and names the transformation exactly:

    cqrt_rz_<W>_controlled(%f, %h, θ)   ->   cqrt_rz_i1(%f, θ)
    cqrt_rz_<W>(%h, θ)                  ->   (deleted — an uncontrolled register
                                              Rz is a GLOBAL PHASE, decision D2)

so the check is: apply that rewrite to the ORACLE's output and require BYTE
EQUALITY with the SUBJECT's, modulo SSA renumbering (both sides are canonicalised
to positional names, because the two binaries number independently and a name
difference is not a stream difference).

⚠ WHAT A MISMATCH MEANS, and it is not automatically a bug: the two inputs are
different modules, and for a fixture whose pre-migration form declined on the
ORACLE there is no stream to compare at all.  Those are reported separately
(ORACLE-DECLINES) and are not failures.  A MISMATCH between two streams that
BOTH exist is the interesting row.
"""
import os, re, subprocess, sys
from collections import Counter

R = os.environ["CQ_REPO"]; ORIG = os.environ["ORIG_TREE"]
SUBJ = os.environ["CQ_OPT"]; SUBJ_PL = os.environ["CQ_PASS"]
ORAC = os.environ["ORACLE_OPT"]; ORAC_PL = os.environ["ORACLE_PASS"]

RZ_CTL = re.compile(r"call void @cqrt_rz_[a-z0-9]+_controlled\((i32 [^,]+), i32 [^,]+, (.*)\)$")
RZ_UNC = re.compile(r"call void @cqrt_rz_[a-z0-9]+\(i32 [^,]+, .*\)$")
SSA = re.compile(r"%[A-Za-z0-9_.$-]+")

def run(opt, pl, path):
    r = subprocess.run([opt, "-load-pass-plugin", pl, "-passes=cq-lowering", "-S", path],
                       capture_output=True, text=True)
    return r.returncode, r.stdout

def canon(text, retire):
    out, names = [], {}
    for ln in text.split("\n"):
        s = ln.strip()
        if (not s or s.startswith("; ModuleID") or s.startswith("source_filename")
                or s.startswith("!") or s.startswith("declare ")):
            continue
        s = re.sub(r",\s*!\w[\w.]*\s*!\d+\s*$", "", s)
        if retire:
            m = RZ_CTL.match(s)
            if m:
                s = "call void @cqrt_rz_i1(%s, %s)" % (m.group(1), m.group(2))
            elif RZ_UNC.match(s):
                continue                     # D2: an uncontrolled register Rz is deleted
        def sub(mo):
            n = mo.group(0)
            if n not in names:
                names[n] = "%%v%d" % len(names)
            return names[n]
        out.append(SSA.sub(sub, s))
    return "\n".join(out)

def main():
    names = [l.strip() for l in open(sys.argv[1]) if l.strip()]
    c, mismatches = Counter(), []
    for b in names:
        cur = os.path.join(R, "ir-pass", "test", b)
        old = os.path.join(ORIG, "ir-pass", "test", b)
        if not (os.path.exists(cur) and os.path.exists(old)):
            c["MISSING"] += 1; continue
        srz, sout = run(SUBJ, SUBJ_PL, cur)
        orz, oout = run(ORAC, ORAC_PL, old)
        if srz != 0:
            c["SUBJECT-DECLINES"] += 1; continue
        if orz != 0:
            c["ORACLE-DECLINES"] += 1; continue
        if canon(sout, False) == canon(oout, True):
            c["MATCH"] += 1
        else:
            c["MISMATCH"] += 1; mismatches.append(b)
    print("verdicts:", dict(c))
    for b in mismatches:
        print("  MISMATCH:", b)

main()
