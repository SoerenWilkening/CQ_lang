#!/usr/bin/env python3
"""control_flag_order_check.py — the PER-FUNCTION CONTROL-FLAG ORDERING check.

bd `test_C_libtooling-drbq` (control-in-place Ry arms), Rule-13 ROUND 2, lens C.
Committed as an INSTRUMENT, not as a gate — read "NOT A CTEST GATE" below.

─────────────────────────────────────────────────────────────────────────────────
WHAT IT WITNESSES

For each function in a LOWERED module it linearises the `cqrt_*` /
`cq_template_*` calls and asserts, for every flag that is BOTH minted by a
`cq_template_{i,f}cmp_*` AND used as arg 0 of a `_controlled` gate / `cqrt_cswap`
/ `cqrt_x`:

    exactly one mint, one `_unc` strip and one `cqrt_free`, and
    mint  <  every gate on that flag  <  strip  <  free

That single ordering is what an EMISSION-ORDER defect breaks, and it needs no
golden, no expected table and no simulator — which is exactly why it can be run
over the whole fixture corpus at once. It is the mechanical form of the round-1
L4 §1/§2 finding (`ControlRegion::RoutedBase` dangling across emission order): a
region emitted out of order, a flag freed before a gate that names it, or a strip
that never ran all show up here as an interval violation.

─────────────────────────────────────────────────────────────────────────────────
WHAT IT CANNOT WITNESS — read this before quoting a green run

  * IT IS BLIND TO THE UNITARY. Every gate can be in the right interval and the
    circuit still be wrong (the wrong angle, the wrong register in the DATA slot,
    an R4/R6 violation, a missing gate). It checks ORDER, not meaning. For the
    stream-level comparison use `tools/inplace_twin_matrix.py`; for rail pairing
    use `tools/free_pairing_check.py`.
  * IT ONLY SEES COMPARE-MINTED FLAGS. A flag that is not the result of a
    `cq_template_{i,f}cmp_*` call — a raw i1 qubit control, a flag arriving as a
    function argument — is skipped entirely, not failed.
  * IT IS PURELY TEXTUAL. It parses printed IR with regexes; a call spelled
    across lines, or an operand list containing a nested parenthesis, is not
    matched and is silently absent from the sequence.
  * A FUNCTION WITH NO CONTROL FLAG CONTRIBUTES NOTHING. "0 violations" over a
    corpus is only as strong as the `flags checked` count printed beside it —
    always quote both.
  * NINE BY-DESIGN EXEMPT FIXTURE FILES are hard-coded below (see `EXEMPT`).
    They are correct-by-design shapes, not suppressed failures, and each is
    named — but the skip is per FILE, so anything else in those files is skipped
    with them.

─────────────────────────────────────────────────────────────────────────────────
HOW TO RUN IT (from the repository ROOT)

    python3 tools/control_flag_order_check.py --quick     # ~8 s, control_* only
    python3 tools/control_flag_order_check.py             # ~25 s, whole corpus
    python3 tools/control_flag_order_check.py --dir DIR   # pre-lowered *.ll/*.out.ll

Default source is `ir-pass/test/*.ll`, each lowered with `build/ir-pass/cq-opt`
(`-passes=cq-lowering`); fixtures that decline or fail to parse are counted as
NOT-LOWERED and skipped, which is correct — there is no emitted stream to order.
Build with `cmake --build build -j8` first (NEVER `--target CQPass` alone:
`cq-opt` is a separate target from the same sources and a CQPass-only rebuild
reports FALSE GREEN).

COST, measured 2026-09-02 on this box at `--jobs 8`: whole corpus 25 s (1349
files, 666 of which lower, 362 control flags); `--quick` 8 s (515 files, 205
lower, 258 flags). Re-measure rather than trusting these — they drift with every
fixture batch.

⚠ NOT A CTEST GATE — deliberately, pending an owner cost decision. Adding it
would also need the `EXEMPT` list to become a maintained artifact rather than a
comment: an exemption that rots into a silent skip is the failure mode this
project keeps re-learning (the `165/174` class).
"""

import argparse
import concurrent.futures
import glob
import os
import re
import subprocess
import sys

# ── BY-DESIGN EXEMPTIONS ─────────────────────────────────────────────────────
# Eight FIXTURE FILES (4 + 4, matched by name prefix) whose flag deliberately does
# NOT complete the mint→gate→strip→free interval. Both families self-identify by
# fixture name; neither is a suppressed failure. Skipping is done at FILE level,
# so a future non-exempt function added to one of these files would be skipped
# too — that is the maintenance cost of the list, and the reason it must become a
# maintained artifact before this is ever a gate.
#
#   * `control_swap_abort_park*` (7.2 Inc 3) — the abort/exit park KEEPS its
#     flag: no strip, no free, because the parked graveyard rail stays frozen and
#     entangled (Rule 6).
#   * `control_swap_cond_datause_*` (ziov `ShareCondFlag`) — the eager strip+free
#     is deliberately SKIPPED because the compare's i1 is also read as DATA, so
#     the flag has a second owner.
#   * `control_inplace_rz_share_cond_flag` (bd drbq Inc 2a) — the SAME
#     `ShareCondFlag` shape as the line above, spelled for the §6a Rz peephole
#     instead of the swap route. It is listed SEPARATELY rather than folded into
#     that prefix because the exemption is keyed on the fixture NAME and this file
#     is not in that name family; adding the name is the honest move, silently
#     widening the prefix to `control_` would not be. One function, one flag: the
#     per-file skip costs exactly that flag.
EXEMPT = ("control_swap_abort_park",
          "control_swap_cond_datause_",
          "control_inplace_rz_share_cond_flag")

CALL_RE = re.compile(
    r'^\s*(?:%([\w.]+) = )?(?:tail |musttail |notail )?call [^@]*@([\w.]+)\(([^)]*)\)',
    re.M)
CMP_RE = re.compile(r'cq_template_[if]cmp')


def check_module(text, label):
    """Return (violations, flags_checked) for one lowered module's text."""
    errs = []
    checked = 0
    for fn in re.split(r'^define ', text, flags=re.M)[1:]:
        name = fn.split('(')[0].split()[-1]
        seq = []
        for m in CALL_RE.finditer(fn):
            res, callee, args = m.group(1), m.group(2), m.group(3)
            if not (callee.startswith("cqrt_") or
                    callee.startswith("cq_template_")):
                continue
            seq.append((res, callee, re.findall(r'%([\w.]+)', args)))
        mint, strip, free, gate = {}, {}, {}, {}
        for i, (res, callee, ops) in enumerate(seq):
            if CMP_RE.match(callee):
                if callee.endswith("_unc") and ops:
                    strip.setdefault(ops[0], []).append(i)
                elif res:
                    mint.setdefault(res, []).append(i)
            elif callee == "cqrt_free" and ops:
                free.setdefault(ops[0], []).append(i)
            elif ops and (callee.endswith("_controlled") or
                          callee == "cqrt_cswap" or callee == "cqrt_x"):
                gate.setdefault(ops[0], []).append(i)
        for fl, gts in gate.items():
            if fl not in mint:
                continue  # not a compare-minted control flag — out of scope
            checked += 1
            mi, st, fr = mint[fl], strip.get(fl, []), free.get(fl, [])
            if len(mi) != 1 or len(st) != 1 or len(fr) != 1:
                errs.append("%s :: %s :: flag %%%s: mints=%d strips=%d frees=%d"
                            % (label, name, fl, len(mi), len(st), len(fr)))
                continue
            if not (mi[0] < st[0] < fr[0]):
                errs.append("%s :: %s :: flag %%%s: mint=%d strip=%d free=%d"
                            % (label, name, fl, mi[0], st[0], fr[0]))
            for g in gts:
                if not (mi[0] < g < st[0]):
                    errs.append("%s :: %s :: flag %%%s: gate at %d outside "
                                "mint/strip interval (%d,%d)"
                                % (label, name, fl, g, mi[0], st[0]))
    return errs, checked


def lower(job):
    cqopt, path = job
    label = os.path.basename(path)
    if any(e in label for e in EXEMPT):
        return label, None, [], 0, "EXEMPT"
    r = subprocess.run([cqopt, "-passes=cq-lowering", "-S", path],
                       capture_output=True, text=True)
    if r.returncode != 0 or not r.stdout.strip():
        return label, None, [], 0, "NOT-LOWERED"
    errs, n = check_module(r.stdout, label)
    return label, None, errs, n, "OK"


def read_dir(job):
    _, path = job
    label = os.path.basename(path)
    if any(e in label for e in EXEMPT):
        return label, None, [], 0, "EXEMPT"
    errs, n = check_module(open(path).read(), label)
    return label, None, errs, n, "OK"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.getcwd())
    ap.add_argument("--dir", default="",
                    help="check ALREADY-LOWERED *.ll / *.out.ll in DIR instead "
                         "of lowering ir-pass/test/*.ll")
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--quick", action="store_true",
                    help="control_* fixtures only (~12s); NOT a full run")
    cfg = ap.parse_args()

    if cfg.dir:
        files = sorted(glob.glob(os.path.join(cfg.dir, "*.out.ll")) or
                       glob.glob(os.path.join(cfg.dir, "*.ll")))
        worker, cqopt = read_dir, ""
    else:
        pat = "control_*.ll" if cfg.quick else "*.ll"
        files = sorted(glob.glob(os.path.join(cfg.root, "ir-pass/test", pat)))
        cqopt = os.path.join(cfg.root, "build/ir-pass/cq-opt")
        if not os.access(cqopt, os.X_OK):
            print("no %s — build with `cmake --build build -j8`" % cqopt,
                  file=sys.stderr)
            return 2
        worker = lower
    if not files:
        print("no input files", file=sys.stderr)
        return 2

    tally = {}
    all_errs = []
    flags = 0
    bad_files = set()
    with concurrent.futures.ProcessPoolExecutor(max_workers=cfg.jobs) as ex:
        for label, _, errs, n, status in ex.map(worker,
                                                [(cqopt, f) for f in files]):
            tally[status] = tally.get(status, 0) + 1
            flags += n
            if errs:
                bad_files.add(label)
                all_errs.extend(errs)
    for e in all_errs:
        print(e)
    print("control_flag_order_check: %d file(s) [%s], %d control flag(s) "
          "checked, %d violation(s) in %d file(s)"
          % (len(files),
             ", ".join("%s=%d" % (k, v) for k, v in sorted(tally.items())),
             flags, len(all_errs), len(bad_files)))
    return 1 if all_errs else 0


if __name__ == "__main__":
    sys.exit(main())
