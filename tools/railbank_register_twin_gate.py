#!/usr/bin/env python3
"""railbank_register_twin_gate.py — THE INSTRUMENT THAT SEES THE CLASS.

bd `xdu2` / L-1a W1, Rule-13 review F-1 (2026-09-15).  The corpus sweep's
headline safety property is `0 A->D` over a corpus written BEFORE the rail-bank
capability existed, and F-1 — the rail bank laundering bd `3d8q` through memory
— is a `D->A`.  **A sweep over a corpus written before a capability cannot
sample that capability's new accept surface.**  `ir-pass-lit`, the 8 e2e
railbank entries, STRICT stage 2b and every twin-identity gate in the tree were
GREEN on the offending program, because none of them contained a program of that
shape.

The one instrument that sees it is the comparison against the REGISTER SPELLING
of the same program.  The increment already built that discipline for a
different axis (`e2e-railbank-flat-twin-identical`: *does the bank MATCH the
register spelling when both accept?*).  This extends it in the direction that
catches an over-accept:

    THE PROPERTY (P1):  the bank DECLINES whenever the register spelling DECLINES.
    THE PROPERTY (P2):  when BOTH accept, the emitted traces are BYTE-IDENTICAL.

P1 is the safety direction and a breach is a **VIOLATION** (the unforgivable
class: a program with no valid circuit gets one through memory).  The converse —
the bank declining where the register spelling accepts — is an **OVER-DECLINE**,
which per the owner's 2026-09-11 ruling is a defect to FILE, not a miscompile;
it is counted and printed, never failed on, and the reason is stated at
`verdict_pair` rather than left to the reader.

⚠ WHAT IT DOES NOT WITNESS, stated so absence is not read as clearance:
  * it compares the bank against the REGISTER SPELLING **as this compiler
    treats it**, so a defect the register spelling shares is invisible here
    (bd `yiid`'s repeated `cq_measure` of one name is exactly that, and the
    `double_measure` pair is in the corpus as a KNOWN both-accept row);
  * P2 compares the emitted STREAM, not the unitary (Rule 2) and not rail
    identity (stage 2b's, and the two programs differ there by construction);
  * a pair is only as good as its twin-ness.  A `.reg.c` that is not the
    array-free spelling of its `.bank.c` measures the author's mistake.  Each
    pair carries a one-line claim in `PAIRS.md`.

⚠ AN INSTRUMENT'S FAILURE MODE IS TO REPORT A PASS (CLAUDE.md L10), and nine
instrument self-failures were measured in this session alone.  So: this script
EXITS NON-ZERO on an empty corpus, on a pair with a missing half, on a stage-1
module that is vacuous (0 `define` or 0 `@cq_` calls — bd memory
`empty-module-accepts-vacuity-trap`, where a 0-byte module ACCEPTS through the
passthrough early-out), and on a pair whose compile fails.  Its own mutant
validation is `railbank_register_twin_gate_test.py`.
"""
import argparse, concurrent.futures, hashlib, os, re, shutil, subprocess, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import cq_stage_cache  # noqa: E402  (bd 2dfk: stage 1 + link/run are content-addressed)

LLVM = os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin")
# Pairs are independent; they run on a small thread pool (subprocess-bound) and
# are REPORTED in sorted order, so the output does not depend on scheduling.
JOBS = max(1, int(os.environ.get("CQ_MATRIX_JOBS", "4")))

# ── the PURE decision layer.  Kept free of subprocesses so the selftest can
#    drive it directly with synthetic rows (a checker whose verdict logic can
#    only be exercised by a full compile is a checker nobody fuzzes).
VIOLATION, OVERDECLINE, OK_BOTH_DECLINE, OK_IDENTICAL, MISMATCH = (
    "VIOLATION", "OVER-DECLINE", "ok-both-decline", "ok-identical", "TRACE-MISMATCH")


def verdict_pair(bank_rc, reg_rc, bank_trace, reg_trace):
    """(P1, P2) as one verdict.  `*_rc` is the cq-opt exit code (0 = ACCEPT)."""
    if reg_rc != 0 and bank_rc == 0:
        # P1 BREACHED.  The register spelling of this very program has no valid
        # circuit and says so loudly; the bank emitted one.  This is F-1.
        return VIOLATION
    if reg_rc != 0 and bank_rc != 0:
        return OK_BOTH_DECLINE
    if reg_rc == 0 and bank_rc != 0:
        return OVERDECLINE
    return OK_IDENTICAL if bank_trace == reg_trace else MISMATCH


FAIL_VERDICTS = {VIOLATION, MISMATCH}


def stage1(src, work, tag, include_dir):
    rc, err, out = cq_stage_cache.stage1_file(
        os.path.join(LLVM, "clang"),
        ["-I", include_dir, "-include", "CQ.h", "-O1", "-emit-llvm", "-S"],
        src, os.path.join(work, tag + ".s1.ll"))
    if rc != 0:
        return None, "clang failed: " + err.strip().splitlines()[0][:120]
    txt = open(out).read()
    ndef = len(re.findall(r"^define", txt, re.M))
    ncq = txt.count("@cq_")
    if ndef == 0 or ncq == 0:
        return None, "VACUOUS stage-1 (defines=%d cq_calls=%d)" % (ndef, ncq)
    return out, None


def run_one(s1, work, tag, build):
    """-> (rc, trace).  `trace` is '' unless the module accepts AND links."""
    s2 = os.path.join(work, tag + ".s2.ll")
    r = subprocess.run([os.path.join(build, "ir-pass", "cq-opt"),
                        "-load-pass-plugin", os.path.join(build, "ir-pass", "libCQPass.so"),
                        "-passes=cq-lowering", "-S", s1, "-o", s2],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return r.returncode, ""
    tpl = os.path.join(build, "runtime", "libcq_templates.a")
    rt = os.path.join(build, "runtime", "libcq_runtime.a")
    # ⚠ LINK ORDER IS LOAD-BEARING: `libcq_templates.a` BEFORE `libcq_runtime.a`
    # (template `_hl` symbols call `cqrt_*`, and single-pass `ld` needs the
    # caller first).
    #
    # `$CQ_LD` (bd `dgn5`) is the linker wrapper CMake derives from this same
    # clang via `clang -###`, minus the `-lto_library` that makes `ld` dlopen
    # libLTO->libLLVM (140 MB) on every `-O0` link. `tests/e2e/CMakeLists.txt`
    # exports it to every test registered there, this one included. Unset (a
    # by-hand run) -> the plain driver command, exactly equivalent and only
    # slower. MEASURED here, on this box under concurrent load: 29.4 s -> 22.6 s
    # for the 8 pairs, same verdicts (Rule 19 — the number is a run, not a
    # guess, and the load is stated because the two are not comparable across it).
    #
    # bd 2dfk: link + run through tools/cq_stage_cache.py::link_and_run — the
    # SAME split link (clang -c + $CQ_LD) or driver fallback as above, plus a
    # content-addressed replay of a previous clean run of this exact lowered
    # module against these exact archives and toolchain. The verdict below is
    # recomputed every time from the traces either way.
    lr = cq_stage_cache.link_and_run(os.path.join(LLVM, "clang"),
                                     os.environ.get("CQ_LD", ""), s2, tpl, rt, work, tag)
    if lr.link_rc != 0:
        # A link failure on an ACCEPTED module is a finding in its own right —
        # it is the ONE thing the golden layer proves (every emitted symbol
        # resolves).  Surface it rather than scoring the pair on an empty trace.
        return 0, "<<LINK-FAILED>> " + lr.link_stderr.strip()[:200]
    return 0, lr.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--build", required=True, help="build dir holding ir-pass/cq-opt")
    ap.add_argument("--pairs", required=True, help="dir of <name>.bank.c / <name>.reg.c")
    ap.add_argument("--include", default=None, help="CQ.h include dir (default <pairs>/../../include)")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    inc = a.include or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "include")

    names = sorted(f[:-len(".bank.c")] for f in os.listdir(a.pairs) if f.endswith(".bank.c"))
    if not names:
        print("railbank_register_twin_gate: FAIL — 0 pairs in %s; an empty corpus is an "
              "ABSENCE, not a pass" % a.pairs)
        return 2
    work = tempfile.mkdtemp(prefix="rbtwin.")
    rows, bad = [], 0

    def one(n):
        """-> (line to print or None, row or None, is_bad). Pure per pair."""
        bank_c = os.path.join(a.pairs, n + ".bank.c")
        reg_c = os.path.join(a.pairs, n + ".reg.c")
        if not os.path.exists(reg_c):
            return ("  %-28s FAIL — missing register twin %s" % (n, os.path.basename(reg_c)),
                    None, True)
        b1, e1 = stage1(bank_c, work, n + ".bank", inc)
        r1, e2 = stage1(reg_c, work, n + ".reg", inc)
        if e1 or e2:
            return "  %-28s FAIL — %s" % (n, e1 or e2), None, True
        brc, btr = run_one(b1, work, n + ".bank", a.build)
        rrc, rtr = run_one(r1, work, n + ".reg", a.build)
        v = verdict_pair(brc, rrc, btr, rtr)
        line = None
        if not a.quiet:
            line = ("  %-28s %-14s bank_rc=%d reg_rc=%d%s"
                    % (n, v, brc, rrc,
                       "" if v != MISMATCH else "  bank_sha=%s reg_sha=%s"
                       % (hashlib.sha256(btr.encode()).hexdigest()[:12],
                          hashlib.sha256(rtr.encode()).hexdigest()[:12])))
        return line, (n, v, brc, rrc), v in FAIL_VERDICTS

    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=JOBS) as pool:
            futs = [(n, pool.submit(one, n)) for n in names]
            for n, fut in futs:          # `names` is sorted: output order is fixed
                line, row, is_bad = fut.result()
                if line is not None:
                    print(line)
                if row is not None:
                    rows.append(row)
                if is_bad:
                    bad += 1
    finally:
        shutil.rmtree(work, ignore_errors=True)
    nviol = sum(1 for _, v, _, _ in rows if v == VIOLATION)
    nmis = sum(1 for _, v, _, _ in rows if v == MISMATCH)
    nover = sum(1 for _, v, _, _ in rows if v == OVERDECLINE)
    print("railbank_register_twin_gate: %d pair(s) checked, %d VIOLATION(s) (P1: bank accepted "
          "where the register spelling declined), %d TRACE-MISMATCH(es) (P2), %d over-decline(s) "
          "[filed, not failed]" % (len(rows), nviol, nmis, nover))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
