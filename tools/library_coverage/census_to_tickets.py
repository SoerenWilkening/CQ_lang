#!/usr/bin/env python3
"""census_to_tickets.py — the L3b census→tickets bridge (bd 3c6m.9).

Mechanizes the owner operating rule (2026-07-09, bd memory libm-campaign-pivot):
ACCEPT NEEDS PROOF, but a DECLINE BECOMES A BUG TICKET. Every genuine source-
injection decline in the libm census is a WORK-QUEUE item, never a terminal
outcome — so this bridge reconciles the census snapshot (inject_results.json,
written by inject_census.py) into one bd issue per declining libm function under
the campaign epic.

It is an IDEMPOTENT RECONCILER, not a one-shot filer:
  * a declining fn with no ticket        -> CREATE   (child of the epic)
  * a declining fn that already has one   -> UPDATE   (refresh diag/lever/body;
                                                        REOPEN if it was closed)
  * a fn whose ticket exists but now       -> CLOSE   ("census now COMPILES")
    COMPILES (bucket=injection)
Re-runs never duplicate: the stable key is bd metadata `census_fn=<fn>` carried by
every bridge-authored ticket (marker label `libm-census-decline`). Only tickets
carrying that marker are ever touched — human-authored issues are never mutated.

TICKET SET = the GENUINE-INJECTION declines only (bucket=="injection",
status=="decline"). The moot-hardware-kept fns (recognition wins, Rule 18 keep-set)
and the harness-gap fns (no injectable body / asm alias) are NOT libm-path
work-queue items and are deliberately excluded (bd census-honesty-3c6m8).

Each ticket carries, per the 3c6m.9 acceptance: the decline diagnostic string, the
blocking source line (the diagnostic's !dbg `<file>:<line>:<col>`, populated when
the census ran against a -g corpus; see inject_census.py), and the lever
classification (which of the 6 campaign levers unblocks it).

USAGE:
    python3 census_to_tickets.py                 # DRY-RUN: print the plan, write nothing
    python3 census_to_tickets.py --apply         # execute create/update/close against bd
    python3 census_to_tickets.py --results F.json # read a specific census snapshot

The bridge shells out to the `bd` CLI (no bd Python API), so it inherits the
repo's Dolt DB + sync exactly as a human `bd create`/`bd update` would.
"""
import argparse, json, os, subprocess, sys, tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT_RESULTS = HERE / "inject_results.json"

# The campaign epic (bd libm-campaign-pivot: 3c6m repointed as THE libm campaign).
# Per-fn decline tickets hang directly under it — "under the campaign epic"
# (3c6m.9 acceptance). Parenting under the epic (not the lever ticket) is
# deliberate: L5-shadow has no dedicated lever child, so a uniform epic parent is
# the only shape that covers every lever without a wrong-parent hazard.
EPIC = "test_C_libtooling-3c6m"

# Marker label carried by EVERY bridge-authored ticket. The idempotency query
# (`bd list --all --label <MARKER>`) returns exactly this bridge's tickets, so a
# re-run reconciles its own output and never collides with human-authored issues.
MARKER = "libm-census-decline"
BASE_LABELS = ["libm-campaign", "math-demo", "demonstrator"]

# Lever -> (one-line unblock explanation, the campaign lever ticket that resolves
# it). The ticket id is BEST-EFFORT: resolved against the live DB at startup and
# skipped (with a warning) if absent, so a renamed/closed lever ticket degrades to
# a body reference rather than a hard failure. L5-shadow has no dedicated child
# ticket (the Shadow-cell work is 38t2 / iw81.13, tracked outside 3c6m's direct
# children) -> no depends-on edge, explained in the body instead.
LEVER_INFO = {
    "L2-closure": ("nested-transcendental closure injection — link the inner leaf "
                   "body (e.g. sinh->exp, atan2->atan, asinh/acosh->log) so the "
                   "composite inlines leaf-included and lowers", "test_C_libtooling-3c6m.11"),
    "L4-fp-select": ("fp-select chains + compound (or i1) conditions — extend "
                     "SelectClassify/SelectMergeEmit past the single-select shape "
                     "behind the three-legged angle fence", "test_C_libtooling-3c6m.12"),
    "L5-qrom": ("QROM dynamic-index const-global read widening — widen the 7.5 "
                "const-global read accept-shape for straight-line / under-control "
                "tainted-index table reads", "test_C_libtooling-3c6m.13"),
    "L5-shadow": ("tainted scratch store at scale — the fp-bitpattern Shadow cell "
                  "(38t2) / QRAM-in-loop (iw81.13); no dedicated 3c6m child ticket yet",
                  None),
    "L6-nested-ctrl": ("general nested tainted control flow — the CONTINGENT GATE, "
                       "re-evaluated only after L1-L5 (many of these collapse once "
                       "leaves compile / hardware-kept)", "test_C_libtooling-3c6m.14"),
    "opcode-gap": ("a genuinely missing opcode template (none expected under "
                   "injection) — investigate before ticketing a lever", None),
    "other": ("unclassified decline reason — inspect the diagnostic manually", None),
}
# All lever ticket ids the bridge may point a depends-on edge at. Used to isolate
# (and re-point) a fn ticket's lever edge when a census re-run RECLASSIFIES its
# lever (real: the scalarizer moved log2/log10 -> nested-ctrl, erf/erfc -> closure,
# bd census-honesty-3c6m8) — so a stale edge to the old lever is retired, never left.
ALL_LEVER_TICKETS = {t for (_, t) in LEVER_INFO.values() if t}


def bd(args, check=True):
    """Run a `bd` subcommand, returning (rc, stdout, stderr)."""
    r = subprocess.run(["bd"] + args, capture_output=True, text=True)
    if check and r.returncode != 0:
        sys.exit(f"bd {' '.join(args)} failed (rc={r.returncode}):\n{r.stderr.strip()}")
    return r.returncode, r.stdout, r.stderr


def bd_json(args):
    _, out, _ = bd(args + ["--json"])
    return json.loads(out) if out.strip() else []


def resolve_id(issue_id):
    """True iff `issue_id` resolves to a live bd issue."""
    rc, _, _ = bd(["show", issue_id, "--json"], check=False)
    return rc == 0


def blocking_loc_of(rec):
    """The blocking !dbg source line, or a truthful 'unavailable' note.

    inject_census.py stores `blocking_loc` (the diagnostic's <file>:<line>:<col>)
    when the census ran against a -g corpus. A pre-enhancement snapshot (or a
    corpus built without -g) has no source location — say so plainly rather than
    fabricate one."""
    loc = (rec.get("blocking_loc") or "").strip()
    if loc:
        return loc
    return ("(unavailable — census snapshot has no !dbg source location; rebuild the "
            "openlibm corpus with `-g` and re-run inject_census.py to populate it)")


def build_body(fn, rec):
    lever = rec.get("lever") or "other"
    explain, lever_ticket = LEVER_INFO.get(lever, LEVER_INFO["other"])
    surv = rec.get("surviving_llvm") or []
    surv_str = ", ".join(f"`{s}`" for s in surv) if surv else "(none)"
    ref = f" — tracked by lever ticket {lever_ticket}" if lever_ticket else ""
    return f"""Auto-filed by the L3b census→tickets bridge
(`tools/library_coverage/census_to_tickets.py`) from the source-injection census
snapshot (`tools/library_coverage/inject_results.json`). WORK-QUEUE item, NOT a
terminal outcome (owner operating rule 2026-07-09, bd memory libm-campaign-pivot:
accept needs proof, a DECLINE BECOMES A BUG TICKET).

- **Function:** `{fn}()` — openlibm double body, injected per Rule 18 (real source
  inlined to stock opcodes before cq-lowering; NOT name-recognized).
- **Lever:** `{lever}` — {explain}{ref}.
- **Decline diagnostic:** `{(rec.get('detail') or '').strip()}`
- **Blocking source line (!dbg):** {blocking_loc_of(rec)}
- **Surviving `@llvm.*` leaves:** {surv_str} (hardware-backed intrinsics the
  injected body bottoms out in; their presence is expected, Rule 18 keep-set).

Resolves when the `{lever}` lever lands and the census flips `{fn}` from `decline`
to `COMPILES` (body fully inlined + cq-lowering exit 0). Idempotency key: bd
metadata `census_fn={fn}` — re-running the bridge UPDATES this ticket in place,
never duplicates."""


def build_acceptance(fn):
    return (f"`{fn}` census status flips decline -> COMPILES (body fully inlined + "
            f"cq-lowering exit 0); an e2e golden slice links+diffs it; any residual "
            f"decline re-tickets. No accept predicate loosened without Rule-13 clearance.")


def title_of(fn, rec):
    return f"libm decline: {fn}() — {rec.get('lever') or 'other'}"


def metadata_json(fn, rec):
    return json.dumps({
        "census_fn": fn,
        "census_lever": rec.get("lever") or "",
        "census_bucket": rec.get("bucket") or "",
        "census_status": rec.get("status") or "",
    })


def load_census(results_path):
    results = json.loads(Path(results_path).read_text())
    declines, compiles = {}, set()
    for fn, rec in results.items():
        if rec.get("bucket") != "injection":
            continue
        if rec.get("status") == "decline":
            declines[fn] = rec
        elif rec.get("status") == "COMPILES":
            compiles.add(fn)
    return declines, compiles


def existing_tickets():
    """{census_fn: issue} for every bridge-authored ticket (across ALL statuses)."""
    issues = bd_json(["list", "--all", "--label", MARKER, "-n", "0"])
    out = {}
    for i in issues:
        fn = (i.get("metadata") or {}).get("census_fn")
        if fn:
            out[fn] = i
    return out


def main():
    ap = argparse.ArgumentParser(description="L3b census->tickets bridge (bd 3c6m.9)")
    ap.add_argument("--apply", action="store_true",
                    help="execute against bd (default: dry-run, write nothing)")
    ap.add_argument("--results", default=str(DEFAULT_RESULTS),
                    help="census snapshot to read (default: inject_results.json)")
    ap.add_argument("--no-close-resolved", action="store_true",
                    help="do not close tickets whose fn now COMPILES")
    ap.add_argument("--only", default="",
                    help="restrict to a comma-separated set of fns (for targeted "
                         "validation / re-filing); empty = all")
    args = ap.parse_args()
    apply = args.apply
    only = {s.strip() for s in args.only.split(",") if s.strip()}

    declines, compiles = load_census(args.results)
    if only:
        declines = {fn: r for fn, r in declines.items() if fn in only}
        compiles = {fn for fn in compiles if fn in only}
    print(f"census snapshot: {args.results}", file=sys.stderr)
    print(f"  genuine-injection declines: {len(declines)}  "
          f"(fns: {sorted(declines)})", file=sys.stderr)
    print(f"  genuine-injection COMPILES: {len(compiles)}  "
          f"(fns: {sorted(compiles) or '(none)'})", file=sys.stderr)

    if not resolve_id(EPIC):
        sys.exit(f"campaign epic {EPIC} does not resolve — aborting.")
    # Resolve lever tickets once so a stale id degrades to a body reference.
    live_lever = {lv: (t if t and resolve_id(t) else None)
                  for lv, (_, t) in LEVER_INFO.items()}
    for lv, (_, t) in LEVER_INFO.items():
        if t and not live_lever[lv]:
            print(f"  WARN: lever ticket {t} ({lv}) does not resolve — "
                  f"depends-on edge skipped, body reference kept.", file=sys.stderr)

    existing = existing_tickets()
    plan = {"create": [], "update": [], "reopen": [], "close": [], "noop": []}

    # 1) reconcile every current decline into a ticket.
    for fn in sorted(declines):
        rec = declines[fn]
        iss = existing.get(fn)
        if iss is None:
            plan["create"].append((fn, rec))
        else:
            was_closed = iss.get("status") == "closed"
            (plan["reopen"] if was_closed else plan["update"]).append((fn, rec, iss))

    # 2) a fn that used to decline but now COMPILES -> close its ticket.
    if not args.no_close_resolved:
        for fn, iss in sorted(existing.items()):
            if fn in compiles and iss.get("status") != "closed":
                plan["close"].append((fn, iss))

    # ── Report + (optionally) execute.
    def dep_flags(rec):
        lv = rec.get("lever") or "other"
        t = live_lever.get(lv)
        return ["--deps", t] if t else []

    tmpfiles = []

    def write_body(fn, rec):
        f = tempfile.NamedTemporaryFile("w", suffix=".md", delete=False)
        f.write(build_body(fn, rec)); f.close()
        tmpfiles.append(f.name)   # cleaned up after all bd calls (below)
        return f.name

    def refresh_args(fn, rec):
        """The shared field-refresh args for update/reopen (title/body/acceptance/
        marker+lever label/full metadata)."""
        return ["--title", title_of(fn, rec),
                "--body-file", write_body(fn, rec), "--acceptance", build_acceptance(fn),
                "--add-label", MARKER, "--add-label", f"lever-{rec.get('lever') or 'other'}",
                "--set-metadata", f"census_fn={fn}",
                "--set-metadata", f"census_lever={rec.get('lever') or ''}",
                "--set-metadata", f"census_bucket={rec.get('bucket') or ''}",
                "--set-metadata", f"census_status={rec.get('status') or ''}"]

    def reconcile_lever(iss, rec):
        """Retire a STALE lever after a census reclassification: drop any
        `lever-*` label that isn't the current one, and re-point the depends-on
        edge from the old lever ticket to the new. No-op when the lever is
        unchanged (the common case).

        Re-fetches authoritative state with `bd show` — its dependency schema
        (target = `id`) is STABLE, whereas the `bd list` snapshot uses a different
        key (`depends_on_id`); trusting the list snapshot here silently skipped the
        stale-edge removal."""
        want_label = f"lever-{rec.get('lever') or 'other'}"
        want_dep = live_lever.get(rec.get('lever') or 'other')
        cur = bd_json(["show", iss["id"]])
        cur = cur[0] if isinstance(cur, list) else cur
        for lbl in cur.get("labels", []):
            if lbl.startswith("lever-") and lbl != want_label:
                bd(["update", iss["id"], "--remove-label", lbl])
        have_deps = {d.get("id") for d in cur.get("dependencies", [])
                     if d.get("id") in ALL_LEVER_TICKETS}
        for d in have_deps:
            if d != want_dep:
                bd(["dep", "remove", iss["id"], d], check=False)
        if want_dep and want_dep not in have_deps:
            bd(["dep", "add", iss["id"], want_dep], check=False)

    created = updated = reopened = closed = 0

    for fn, rec in plan["create"]:
        print(f"CREATE  {fn:12s} [{rec.get('lever')}]  {title_of(fn, rec)}")
        if apply:
            body = write_body(fn, rec)
            # bd create folds all labels (incl. the per-lever label) into --labels;
            # --add-label is an update-only flag.
            create_args = [
                "create", title_of(fn, rec), "-t", "bug", "-p", "2",
                "--parent", EPIC,
                "--labels", ",".join([MARKER, f"lever-{rec.get('lever') or 'other'}"] + BASE_LABELS),
                "--body-file", body, "--acceptance", build_acceptance(fn),
                "--metadata", metadata_json(fn, rec), "--silent",
            ] + dep_flags(rec)
            _, out, _ = bd(create_args)
            print(f"        -> {out.strip()}")
            created += 1

    for fn, rec, iss in plan["update"]:
        print(f"UPDATE  {fn:12s} [{rec.get('lever')}]  {iss['id']}")
        if apply:
            bd(["update", iss["id"]] + refresh_args(fn, rec))
            reconcile_lever(iss, rec)
            updated += 1

    for fn, rec, iss in plan["reopen"]:
        print(f"REOPEN  {fn:12s} [{rec.get('lever')}]  {iss['id']} (was closed, still declines)")
        if apply:
            bd(["update", iss["id"], "--status", "open"] + refresh_args(fn, rec))
            reconcile_lever(iss, rec)
            reopened += 1

    for fn, iss in plan["close"]:
        print(f"CLOSE   {fn:12s} {iss['id']} (census now COMPILES)")
        if apply:
            bd(["update", iss["id"], "--status", "closed",
                "--append-notes", "census→tickets bridge: census now reports COMPILES "
                "(body fully inlined + cq-lowering exit 0) — decline resolved."])
            closed += 1

    for p in tmpfiles:   # clean up the per-ticket body files bd has finished reading
        try:
            os.unlink(p)
        except OSError:
            pass

    print(f"\nplan: create={len(plan['create'])} update={len(plan['update'])} "
          f"reopen={len(plan['reopen'])} close={len(plan['close'])}", file=sys.stderr)
    if apply:
        print(f"applied: created={created} updated={updated} reopened={reopened} "
              f"closed={closed}", file=sys.stderr)
    else:
        print("DRY-RUN — nothing written. Re-run with --apply to execute.", file=sys.stderr)


if __name__ == "__main__":
    main()
