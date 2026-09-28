#!/usr/bin/env python3
"""The guard must FAIL CLOSED (exit != 0, its own diagnostic, no traceback) on a bad
compile database. Each case writes a database into a temp dir and runs the guard's main.
usage: fail_closed.py"""
import json, os, subprocess, sys, tempfile, shutil
W = os.path.abspath(os.path.join(os.path.dirname(__file__), *[".."] * 6))
G = os.path.join(W, "tools", "taintset_scrub_guard.py")
db = json.load(open(os.path.join(W, "build", "compile_commands.json")))
main_repo = os.path.dirname(os.path.dirname(os.path.dirname(W)))   # .../CQ_lang (another tree)
d = tempfile.mkdtemp(prefix="sg_failclosed_")


def write(name, obj=None, text=None):
    p = os.path.join(d, name)
    with open(p, "w") as f:
        f.write(text if text is not None else json.dumps(obj))
    return p


other = [dict(e, file=e["file"].replace(W, main_repo), directory=e["directory"].replace(W, main_repo),
              command=e.get("command", "").replace(W, main_repo)) for e in db]
nocc = [dict(e, command=e["command"].replace("/usr/bin/c++", "/nonexistent/c++", 1)) for e in db]
CASES = [
    ("missing database", ["--compile-commands", os.path.join(d, "absent.json")]),
    ("database of ANOTHER tree (files exist there)", ["--compile-commands", write("other.json", other)]),
    ("garbage JSON", ["--compile-commands", write("garbage.json", text="{not json")]),
    ("JSON object, not a list", ["--compile-commands", write("obj.json", {"a": 1})]),
    ("nonexistent compiler", ["--compile-commands", write("nocc.json", nocc)]),
    ("unknown argument", ["--bogus"]),
]
bad = 0
for label, args in CASES:
    r = subprocess.run([sys.executable, "-B", G] + args, capture_output=True, text=True, cwd=W)
    tb = "Traceback" in r.stderr
    ok = r.returncode != 0 and not tb
    bad += not ok
    last = (r.stdout.strip().splitlines() or r.stderr.strip().splitlines() or [""])[0]
    print(f"{'ok ' if ok else 'BAD'} rc={r.returncode} traceback={tb}  {label}\n      {last[:220]}")
shutil.rmtree(d, ignore_errors=True)
print(f"{len(CASES)} cases, {bad} bad")
sys.exit(1 if bad else 0)
