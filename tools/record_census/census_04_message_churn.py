#!/usr/bin/env python3
"""census_04_message_churn.py — Inc-0 census 0.4: which NEGATIVE lit fixtures
would the new M-A guard steal the diagnostic from?

Sizes the fixture edits Inc 1 must carry (Risk 5 of the record-family plan of
record, bd test_C_libtooling-6uqc). Rule 12 requires every negative fixture to
mirror its diagnostic CHARACTER-FOR-CHARACTER, so a guard that fires EARLIER
than the one a fixture pins turns that fixture red — not because the compiler
regressed, but because a different (also correct) decline now wins the race.

============================== WHY IT IS DIFFERENT =========================
Censuses 0.1 and 0.2 read LOWERED IR. A DECLINING module has none — measured:
`cq-opt` exits non-zero and writes no output file. So this census works on the
PRE-LOWERING IR through `source_ir.py`, whose model, blind spots and validation
against the lowered-IR view are documented in that file. Read it before quoting
anything here: its record predicate is an UPPER BOUND (no liveness, no
discharge), which is the correct direction for the question "which fixtures COULD
lose their message".

================================ THE METHOD ================================
1. NEGATIVE FIXTURES are the ones whose own `RUN:` line runs `%cq-opt` under
   `not`. Their ACTUAL diagnostic is read from the real `cq-opt` stderr (cached
   by `census_common.lower_ll`), not from their `CHECK` lines — the stderr is
   what the fixture is pinning, and reading it removes a whole class of
   CHECK-parsing error.
2. EMITTING SITE. Each message is located in `ir-pass/src` / `ir-pass/include`
   by literal substring, longest-first with a shrinking prefix fallback for the
   messages that interpolate a symbol name.
3. STAGE ORDER is DERIVED, never hand-listed: the script reads
   `CQLoweringPass::run`'s body, records the source line of every pass-entry call
   in it, finds which file defines each of those entry points, and takes each
   file's position to be its earliest entry call. The M-A slot is the line of
   `declineStaleRecordOps`. A file whose earliest entry call is BEFORE that line
   still wins the race with M-A and is reported as SAFE.
4. AT RISK = the fixture has a chained theta with a non-empty record set (the
   `source_ir` predicate) AND its current message is emitted at or after the M-A
   slot.

================================= CAVEATS ==================================
  C1  This is an UPPER BOUND on churn in two independent ways: source_ir's U1
      (no liveness) over-counts records, and step 4 assumes M-A fires whenever
      the predicate holds, whereas the real guard will carry the carve-outs
      census 0.1 measured. Both directions inflate, never deflate. NOTE what C1
      does NOT cover under `--predicate ruled`: source_ir DOES model the ruled
      deadness clause (its U1c), so the ruled column is an upper bound only via
      step 4 and the U-series blind spots, not via U1.
  C2  Step 2's substring search reports UNMAPPED for any message it cannot
      locate, and those are listed rather than dropped. An unmapped message is
      counted AT RISK (the conservative direction).
  C3  A fixture can pin more than one message. All are read; a fixture is at risk
      if ANY of its messages is emitted at or after the M-A slot.
  C4  The RECORD PREDICATE is selectable and is recorded in the report, because
      this census's answer MOVES with it — measured 2026-08-27: 13 at-risk
      fixtures under `plan-v1`, 9 under `ruled`, and only 4 fixtures are in both
      sets. A 0.4 number quoted without its predicate is meaningless.

================================== RE-RUN ==================================
    python3 tools/record_census/census_04_message_churn.py \
        --json docs/prd/record-family/census-0.4-message-churn.json

    # the SUPERSEDED pre-ruling population, retained for the delta
    python3 tools/record_census/census_04_message_churn.py --predicate plan-v1 \
        --json docs/prd/record-family/census-0.4-message-churn-preruling.json
"""

import argparse
import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import census_common as cc  # noqa: E402
import source_ir as si      # noqa: E402

MSG_RE = re.compile(r"\bcq .*$")


def run_stage_order(repo=cc.REPO):
    """-> ({entry_name: line}, anchor_line) derived from CQLoweringPass::run."""
    path = os.path.join(repo, "ir-pass", "src", "CQLoweringPass.cpp")
    lines = open(path, errors="replace").read().split("\n")
    start = next(i for i, l in enumerate(lines)
                 if "CQLoweringPass::run" in l)
    # A pass ENTRY is a statement-level call taking the Module as its first
    # argument — `propagate(M, wd)`, `declineStaleRecordOps(M, taint)`,
    # `while (flattenPredMuxRegions(M, taint))`. Keying on `(M` is what keeps
    # ordinary method calls (`taint.ThetaCalls.empty()`) out of the table; an
    # earlier draft matched every `name(` and mapped CQLoweringPass.cpp itself
    # to run-line 59, which silently marked two control-stage fixtures SAFE.
    entries, depth = {}, 0
    for i in range(start, len(lines)):
        l = lines[i]
        depth += l.count("{") - l.count("}")
        for m in re.finditer(r"\b([a-z][A-Za-z0-9_]*)\s*\(\s*M\s*[,)]", l):
            entries.setdefault(m.group(1), i + 1)
        if i > start and depth <= 0:
            break
    anchor = entries.get("declineStaleRecordOps")
    if anchor is None:
        raise SystemExit("census 0.4: declineStaleRecordOps not found in run()")
    return entries, anchor


def file_stage_positions(repo, entries):
    """-> {source_file_basename: earliest entry-call line in run()}.

    A file that DEFINES a pass entry gets that entry's call line directly. A
    file that defines none — `ArmClassify.cpp`, `SwitchClassify.cpp`, the other
    helper modules the control emitters call into — is attributed ONE HOP: the
    earliest stage position among the entry-defining files that `#include` its
    header. That keeps the map derived rather than hand-listed, and files it
    still cannot reach stay out of the map and are reported UNMAPPED.
    """
    srcs = sorted(glob.glob(os.path.join(repo, "ir-pass", "src", "*.cpp")))
    texts = {os.path.basename(p): open(p, errors="replace").read()
             for p in srcs}
    pos = {}
    for base, text in texts.items():
        best = None
        for name, line in entries.items():
            # a real DEFINITION in this file: `<type> name(Module &M`
            if re.search(rf"^[A-Za-z_][\w:<>,&*\s]*\b{re.escape(name)}"
                         rf"\s*\(\s*(?:const\s+)?Module\s*&", text, re.M):
                best = line if best is None else min(best, line)
        if best is not None:
            pos[base] = best
    for base in texts:
        if base in pos:
            continue
        hdr = base[:-4] + ".h"
        cands = [pos[b] for b, t in texts.items()
                 if b in pos and f'#include "{hdr}"' in t]
        if cands:
            pos[base] = min(cands)
    return pos


SUFFIXES = (" under quantum control", " under quantum lift")

_BLOCK_COMMENT = re.compile(r"/\*.*?\*/", re.S)
_LINE_COMMENT = re.compile(r"//[^\n]*")


def strip_comments(text):
    """Remove C/C++ comments so a message search matches CODE, not prose."""
    return _LINE_COMMENT.sub("", _BLOCK_COMMENT.sub("", text))


def locate_message(msg, sources):
    """-> ([basenames], fragment) for a literal fragment of `msg`.

    The control emitters build their string as `kMsg… + " under quantum
    control"`, so the FULL rendered message appears in no source file; the
    suffix-stripped forms are tried too. Anything still unlocated is reported
    UNMAPPED and counted AT RISK (the conservative direction)."""
    cands = [msg]
    for suf in SUFFIXES:
        if msg.endswith(suf):
            cands.append(msg[: -len(suf)])
    # EXACT forms first.
    for base in cands:
        hits = [b for b, t in sources.items() if base in t]
        if hits:
            return hits, base
    # `diagnoseUnderControl` composes `"cq controlled lowering: " + What +
    # " under quantum control"` (ControlDetect.cpp:53), so the RENDERED message
    # appears in no file — only the bare `What` does, as a C string literal.
    # `"<What>")` is the literal in ARGUMENT position, so a prose comment that
    # merely quotes the phrase does not match.
    for pref in ("cq controlled lowering: ",):
        for base in cands:
            if base.startswith(pref):
                core = '"' + base[len(pref):] + '")'
                hits = [b for b, t in sources.items() if core in t]
                if hits:
                    return hits, core
    # LAST RESORT: a shrinking prefix, for the messages that interpolate a
    # symbol name (`unsupported declared prototype for cq_theta_si32`). Runs
    # last on purpose — a 25-char prefix like `cq controlled lowering: c` is
    # shared by half the pass, and running it FIRST attributed `control flow`
    # to CQLoweringPass.cpp at run-line 441.
    for base in cands:
        for n in (60, 45, 35, 25):
            frag = base[:n]
            hits = [b for b, t in sources.items() if frag in t]
            if hits:
                return hits, frag
    return [], msg[:25]


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--json")
    ap.add_argument("--repo", default=cc.REPO)
    ap.add_argument("--predicate", default="ruled",
                    choices=("ruled", "plan-v1"),
                    help="record predicate handed to source_ir (C4). `ruled` is "
                         "the owner-ruled, liveness-keyed one and the default; "
                         "`plan-v1` reproduces the superseded pre-ruling "
                         "population.")
    args = ap.parse_args(argv)

    entries, anchor = run_stage_order(args.repo)
    pos = file_stage_positions(args.repo, entries)
    # COMMENTS ARE STRIPPED before the search. This pass documents its own
    # diagnostics extensively in prose, so `"control flow under quantum
    # control"` appears verbatim in TWO comments (CQLoweringPass.cpp:287,
    # PredMuxFlatten.cpp:2714) and a naive substring search attributed the
    # message to whichever file sorted first. Only code is searched.
    sources = {}
    for d in ("src", "include"):
        for p in glob.glob(os.path.join(args.repo, "ir-pass", d, "*")):
            if p.endswith((".cpp", ".h")):
                sources[os.path.basename(p)] = strip_comments(
                    open(p, errors="replace").read())

    rows, unmapped = [], set()
    # The narrowing funnel, so §5's modelling note is GENERATED, never typed.
    funnel = {"chained_theta": 0, "record_either_side": 0,
              "record_exists_at_theta": 0, "record_dead_at_theta": 0}
    for name, path, neg in cc.lit_fixtures(args.repo):
        if not neg:
            continue
        rc, out, err = cc.lower_ll(path, args.repo)
        msgs = []
        for line in err.split("\n"):
            if not line.startswith("error:"):
                continue
            m = MSG_RE.search(line)
            msgs.append(m.group(0) if m else line.strip())
        msgs = sorted(set(msgs))
        src = si.analyse(path, args.predicate)
        has_records = any(f["ancestors"] or f["descendants"] for f in src["fns"])
        if src["chained"]:
            funnel["chained_theta"] += 1
            # every record the model saw on either side, BEFORE the position
            # clause (U1b) and BEFORE the ruled deadness clause (U1c)
            wide = (src["anc"] + src["desc"] + src["after_theta"]
                    + src["exempt_live_after"] + src["exempt_measured"]
                    + src["exempt_compare"])
            if wide:
                funnel["record_either_side"] += 1
            if wide - src["after_theta"]:
                funnel["record_exists_at_theta"] += 1
            if has_records:
                funnel["record_dead_at_theta"] += 1
        if not (src["chained"] and has_records):
            continue
        stages = []
        for msg in msgs:
            files, frag = locate_message(msg, sources)
            cand = [f for f in files if f in pos]
            if not cand:
                unmapped.add(msg)
                stages.append((msg, None, None))
                continue
            # the emitting file's stage position; if a message literal lives in a
            # header shared by several stages, take the EARLIEST (safest for the
            # fixture, i.e. least churn — reported, not hidden).
            p = min(pos[f] for f in cand)
            stages.append((msg, sorted(cand), p))
        at_risk = any(p is None or p >= anchor for _, _, p in stages)
        rows.append({
            "fixture": name,
            "rc": rc,
            "messages": [{"text": m, "files": f, "run_line": p}
                         for m, f, p in stages],
            "src_chained_thetas": src["chained"],
            "src_ancestor_records": src["anc"],
            "src_descendant_records": src["desc"],
            "src_exempt_control_compare": src["exempt_compare"],
            "src_exempt_measured": src["exempt_measured"],
            "src_exempt_live_after": src["exempt_live_after"],
            "src_records_after_theta": src["after_theta"],
            "at_risk": at_risk,
        })

    risk = [r for r in rows if r["at_risk"]]
    safe = [r for r in rows if not r["at_risk"]]
    report = {
        "predicate": args.predicate,
        "m_a_slot_run_line": anchor,
        "negative_fixtures": sum(1 for _, _, n in cc.lit_fixtures(args.repo) if n),
        "narrowing_funnel": funnel,
        "with_chained_theta_and_records": len(rows),
        "at_risk": len(risk),
        "message_wins_race_before_m_a": len(safe),
        "unmapped_messages": sorted(unmapped),
        "rows": rows,
    }
    print(f"M-A slot: CQLoweringPass.cpp:{anchor} (declineStaleRecordOps)")
    print(f"record predicate                                   : "
          f"{args.predicate}")
    print(f"negative lit fixtures                              : "
          f"{report['negative_fixtures']}")
    print(f"  with a chained theta                             : "
          f"{funnel['chained_theta']}")
    print(f"  ... + a record on either side (no clauses)       : "
          f"{funnel['record_either_side']}")
    print(f"  ... + the record EXISTS at the theta (U1b)       : "
          f"{funnel['record_exists_at_theta']}")
    print(f"  with a chained theta AND >=1 record (source_ir)  : {len(rows)}")
    print(f"  AT RISK (message emitted at/after the M-A slot)  : {len(risk)}")
    print(f"  safe (their stage runs BEFORE M-A)               : {len(safe)}")
    if unmapped:
        print(f"  messages this census could not locate in source : "
              f"{len(unmapped)} (counted AT RISK)")
        for m in sorted(unmapped):
            print(f"      {m}")
    print("\nAT-RISK FIXTURES (current pinned message -> emitting stage):")
    for r in sorted(risk, key=lambda r: r["fixture"]):
        print(f"  {r['fixture']}")
        print(f"      anc={r['src_ancestor_records']} "
              f"desc={r['src_descendant_records']} "
              f"exempt(cmp={r['src_exempt_control_compare']},"
              f"meas={r['src_exempt_measured']})")
        for m in r["messages"]:
            where = (f"{','.join(m['files'])}@run:{m['run_line']}"
                     if m["files"] else "UNMAPPED")
            print(f"      \"{m['text']}\"  [{where}]")
    print("\nSAFE (an earlier stage still wins the race):")
    for r in sorted(safe, key=lambda r: r["fixture"]):
        for m in r["messages"]:
            print(f"  {r['fixture']}: \"{m['text']}\" "
                  f"[{','.join(m['files'] or [])}@run:{m['run_line']}]")
    if args.json:
        with open(args.json, "w") as f:
            json.dump(report, f, indent=1, sort_keys=True)
        print(f"\nwrote {args.json}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
