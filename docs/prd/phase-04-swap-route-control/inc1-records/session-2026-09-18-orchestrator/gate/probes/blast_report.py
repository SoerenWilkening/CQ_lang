#!/usr/bin/env python3
"""Format blast_out.txt into the coordinator's table + a tally."""
import sys, os, collections

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ac2acfdde3461becc"
CM = os.path.join(W, "tests/e2e/CMakeLists.txt")
cmake = open(CM).read()

rows = []
for line in open(sys.argv[1]):
    f = line.rstrip("\n").split("\t")
    if len(f) < 5:
        continue
    rows.append(f)          # label, dirty, total, verdict, detail

tally = collections.Counter(r[3] for r in rows)
print(f"rows: {len(rows)}")
for k, v in tally.most_common():
    print(f"  {k:28s} {v}")

def shipping(label):
    """Does this file ship as a REGISTERED golden?"""
    if not label.startswith("e2e:"):
        return "no (probe, not registered)"
    base = label.split(":", 1)[1]
    stem = base[:-2] if base.endswith(".c") else base
    golden = os.path.join(W, "tests/e2e", stem + ".expected.log")
    has_golden = os.path.exists(golden)
    # the ctest name is the slice stem with _ -> - and the leading slice_ kept
    tname = "e2e-" + stem.replace("_", "-")
    registered = ("add_test(NAME " + tname + "\n") in cmake or ("add_test(NAME " + tname + " ") in cmake
    if has_golden and registered:
        return "**YES**"
    if has_golden:
        return "golden present, ctest name not matched"
    return "no golden"

print()
print("=== G8-SHAPE ===")
hits = [r for r in rows if "G8-SHAPE" in r[3]]
print(f"{len(hits)} hit(s)")
for r in hits:
    print(f"\n| `{r[0]}` | dirty **{r[1]}** of {r[2]} | {r[4]} | {shipping(r[0])} |")

print()
print("=== DIRTY-NO-TRAILING-GATE (dirty>0 but no interference) : top 25 by dirty ===")
d = [r for r in rows if r[3] == "DIRTY-NO-TRAILING-GATE"]
d.sort(key=lambda r: -int(r[1]) if r[1].isdigit() else 0)
print(f"{len(d)} file(s)")
for r in d[:25]:
    print(f"  {r[1]:>3s} dirty  {r[0]}")

print()
print("=== NOCENSUS / UNPARSED (would have been silent false-CLEANs) ===")
for r in rows:
    if r[3] in ("NOCENSUS", "UNPARSED-CENSUS", "LINKERR", "RUNERR"):
        print(f"  {r[3]:18s} {r[0]}")
