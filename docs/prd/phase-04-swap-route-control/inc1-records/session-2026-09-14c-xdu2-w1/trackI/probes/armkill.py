#!/usr/bin/env python3
"""armkill.py — bd 21re: MAKE THE NEW INSTRUMENT FAIL ON PURPOSE.

CLAUDE.md L10 and the six-instances paragraph after it: an instrument's failure
mode is to report a PASS, so the only instrument worth citing is one that has
been made to fail on purpose. This script deletes each arm of the bd 21re memory
rule in a COPY of tools/free_pairing_check.py, re-runs the FULL
tools/free_pairing_check_test.py against that copy, and reports which fixtures
go red. An arm whose deletion leaves the suite green has NO coverage and the row
is a lie.

It also runs the opposite direction: two OVER-firing mutants, because a rule
that refuses everything would pass every kill test and over-decline the
increment it exists to protect.

Run from the repo root:  python3 <this file>
"""
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[7]
CHK = ROOT / "tools" / "free_pairing_check.py"
TST = ROOT / "tools" / "free_pairing_check_test.py"


def kill_raise(src, code):
    """Neuter the `raise Undecidable(<code>, ...)` whose code string is `code`.

    Textual, and asserted: the statement is rewritten to a no-op expression so
    the surrounding control flow is untouched and only the REFUSAL disappears.
    """
    pat = re.compile(r"raise Undecidable\(\s*\n?\s*\"" + re.escape(code) + r"\"",
                     re.M)
    m = pat.search(src)
    assert m, f"no `raise Undecidable(\"{code}\"` in the checker"
    return src[:m.start()] + "Undecidable(\"" + code + "\"" + src[m.end():]


MUTANTS = [
    # --- the four arms of the fix -------------------------------------------
    ("kill-L1-rail-store-refusal",
     lambda s: kill_raise(s, "L1-rail-stored-to-unmarked-memory")),
    ("kill-L2-unresolvable-load-refusal",
     lambda s: kill_raise(s, "L2-undecidable-load-provenance")),
    ("kill-L3-rail-slot-refusal",
     lambda s: kill_raise(s, "L3-bank-rail-in-a-modelled-rail-slot")),
    ("kill-rail_defs-fold (the provably_not_a_rail arm)",
     lambda s: s.replace(
         "rail_defs[fn.name] |= adjudicate_memory(",
         "adjudicate_memory(", 1)),
    # --- the supporting machinery -------------------------------------------
    ("kill-the-!cq.railbank-marker-read",
     lambda s: s.replace('if dm.group(2) == "alloca" and RAILBANK_MD in ln:',
                         'if dm.group(2) == "alloca" and False:', 1)),
    ("kill-the-global-bank-marker-read",
     lambda s: s.replace("if gm and RAILBANK_MD in lines[i]:",
                         "if gm and False:", 1)),
    ("kill-resolve_object-refusal (everything forwards)",
     lambda s: s.replace(
         "    if op in PTR_FORWARDING_OPS:\n"
         "        return resolve_object(fn, first_ptr_operand(line), "
         "bank_globals, _seen)\n"
         "    return None",
         "    return resolve_object(fn, first_ptr_operand(line), "
         "bank_globals, _seen) or ptr", 1)),
    ("kill-the-store-pointer-operand-fix (first ptr of the line)",
     lambda s: s.replace('first_ptr_operand(ln.split(",", 1)[1])',
                         "first_ptr_operand(ln)", 1)),
    # --- the OVER-firing direction ------------------------------------------
    ("over-fire: refuse EVERY load while a bank is in scope",
     lambda s: s.replace("        if obj in banks:\n            "
                         "bank_loads.add(res)",
                         "        bank_loads.add(res)", 1)),
    ("over-fire: drop the cqrt_measure exemption from L3",
     lambda s: s.replace('if re.fullmatch(rf"cqrt_measure_{_W}", c.sym):',
                         "if False:", 1)),
]

# A mutation that is UNOBSERVABLE BY CONSTRUCTION, with the reason. Listed, not
# hidden: the file's own `SWEEP_EXEMPT_RULES` precedent is that an exemption
# with a written argument is coverage information and an exemption without one
# is a hole.
EXEMPT = {
    "kill-the-store-pointer-operand-fix (first ptr of the line)":
        "A rail handle is ALWAYS an i32 (Rule 15: `a runtime handle is always "
        "i32 regardless of width`), so a `store` whose VALUE type is `ptr` "
        "never carries one, and for every `store <int ty> %v, ptr %p` the "
        "line's first `ptr <name>` already IS the pointer operand. The guard "
        "is kept because `resolve_object` is shared with the load path, where "
        "the same spelling would be wrong the day a pointer-valued rail "
        "exists; it cannot be exercised today and is not counted as covered.",
}


def run(tmp):
    # ⚠ PYTHONDONTWRITEBYTECODE, and it is load-bearing, not hygiene. A `.pyc`
    # is invalidated on (mtime, size) at 1-SECOND resolution, and every
    # `kill_raise` mutation below removes exactly `raise ` — the SAME six
    # bytes — so two consecutive kills produce files of IDENTICAL SIZE. Without
    # this the second kill can import the FIRST one's bytecode and be scored
    # against the wrong arm. MEASURED: it mis-attributed the L2 kill to the
    # three L1 fixtures on one run and attributed it correctly on another, from
    # nothing but which side of a second boundary the writes landed on. An
    # instrument's failure mode is to report a PASS (CLAUDE.md L10); this one's
    # was to report the RIGHT verdict for the WRONG reason, which is worse,
    # because the row still reads as coverage.
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
    r = subprocess.run([sys.executable, "-B",
                        str(tmp / "free_pairing_check_test.py")],
                       capture_output=True, text=True, env=env)
    return r.returncode, r.stdout.strip(), r.stderr.strip()


def caught_by(err):
    return [l.strip()[5:].split(":")[0]
            for l in err.split("\n") if l.strip().startswith("FAIL")]


def main():
    base = CHK.read_text()
    rows, holes = [], 0
    with tempfile.TemporaryDirectory() as d:
        tmp = pathlib.Path(d)
        shutil.copy(CHK, tmp / "free_pairing_check.py")
        shutil.copy(TST, tmp / "free_pairing_check_test.py")
        rc, out, err = run(tmp)
        print(f"CONTROL (unmutated): exit={rc}  {out}")
        assert rc == 0, "the unmutated checker must be green before kill-testing"
        exempt = broken = 0
        for name, fn in MUTANTS:
            mutated = fn(base)
            assert mutated != base, f"{name}: mutation was a NO-OP"
            (tmp / "free_pairing_check.py").write_text(mutated)
            rc, out, err = run(tmp)
            caught = caught_by(err)
            if rc != 0 and not caught:
                # The harness died instead of reporting. That is the mutation
                # being MALFORMED (a syntax error), not the fixtures catching
                # it — scoring it as a catch is the `harness that runs a weaker
                # command than lit` failure, inverted.
                broken += 1
                rows.append((name, "MUTATION MALFORMED — not a catch",
                             [err.split("\n")[-1][:110]]))
            elif rc == 0 and name in EXEMPT:
                exempt += 1
                rows.append((name, "unobservable by construction (exempt)",
                             [EXEMPT[name]]))
            elif rc == 0:
                holes += 1
                rows.append((name, "SURVIVED — NO COVERAGE", []))
            else:
                rows.append((name, f"caught by {len(caught)} fixture(s)",
                             caught))
    w = max(len(n) for n, _, _ in rows)
    for name, verdict, caught in rows:
        print(f"  {name:<{w}}  {verdict}")
        for c in sorted(set(caught))[:6]:
            print(f"  {'':<{w}}    {c}")
    print(f"armkill: {len(rows)} mutation(s), {holes} SURVIVED, {exempt} "
          f"exempt with a written reason, {broken} malformed "
          f"(a survivor is a HOLE, not a pass)")
    return 1 if holes or broken else 0


if __name__ == "__main__":
    sys.exit(main())
