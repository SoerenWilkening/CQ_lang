#!/usr/bin/env python3
"""watch.py — emit one line per new mutation-matrix row, one when the
equivalence sweep's task file shows an exit, and stop when the matrix ends."""
import time, re
T = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6"
L = f"{T}/scratchpad/t8e5r/mutate_run.log"
E = f"{T}/tasks/bdl7y2thq.output"
seen = len(open(L).read().splitlines())
eq = False
while True:
    lines = open(L).read().splitlines()
    for l in lines[seen:]:
        m = re.match(r"(\S+) \{(.*)", l)
        if m:
            d = m.group(2)
            parts = re.findall(r"'(D\d\w*)': '([^']*)'", d)
            short = "; ".join(f"{k}={v[:60]}" for k, v in parts if not k.startswith("D6"))
            d6 = re.search(r"counts: ([^']*)", d)
            print(f"ROW {m.group(1)} :: {short} :: D6 {d6.group(1) if d6 else '-'}", flush=True)
        else:
            print("LOG " + l[:200], flush=True)
    seen = len(lines)
    try:
        es = open(E).read()
    except OSError:
        es = ""
    if not eq and "rc=" in es:
        print("EQUIV " + es.strip().splitlines()[-1][:200], flush=True)
        eq = True
    if any(("restored" in l) or ("Traceback" in l) or ("Error" in l) for l in lines):
        print("MATRIX-END", flush=True)
        break
    time.sleep(20)
