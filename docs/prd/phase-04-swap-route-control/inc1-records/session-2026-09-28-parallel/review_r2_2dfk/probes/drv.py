#!/usr/bin/env python3
"""r2 reviewer driver (bd 2dfk round 2): run registered e2e entries from the
IMPLEMENTER's ctest json, but with the harness/tool/include/test-source paths
redirected to the PRIVATE review worktree and the stage caches redirected to a
PRIVATE cache dir. Binaries (cq-opt, plugin, runtime archives, cq_link.sh) are
the implementer's, used READ-ONLY. No build is needed.

usage: drv.py <regex> <cachedir> [--nocache] [-v]
prints one line per test: PASS/FAIL name ; summary line last.
"""
import concurrent.futures, json, os, re, subprocess, sys

SP = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad"
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ae7eff02a1262b05e"
MY = SP + "/rev_r2_2dfk"
SUBS = [(W + "/tests/", MY + "/tests/"), (W + "/tools/", MY + "/tools/"),
        (W + "/include", MY + "/include"), (W + "/example/", MY + "/example/")]


def sub(s):
    for a, b in SUBS:
        s = s.replace(a, b)
    return s


def main():
    rx, cache = sys.argv[1], sys.argv[2]
    nocache = "--nocache" in sys.argv
    verbose = "-v" in sys.argv
    tests = json.load(open(SP + "/r2_2dfk_tests.json"))["tests"]
    sel = [t for t in tests if re.search(rx, t["name"])]
    def one(t):
        env = dict(os.environ)
        env.pop("CQ_E2E_NO_CACHE", None)
        wd = None
        for p in t.get("properties", []):
            if p["name"] == "ENVIRONMENT":
                for kv in p["value"]:
                    k, _, v = kv.partition("=")
                    env[k] = sub(v)
            if p["name"] == "WORKING_DIRECTORY":
                wd = sub(p["value"])
        env["CQ_S1CACHE"] = cache + "/s1"
        env["CQ_RUNCACHE"] = cache + "/run"
        if nocache:
            env["CQ_E2E_NO_CACHE"] = "1"
        cmd = [sub(c) for c in t["command"]]
        r = subprocess.run(cmd, env=env, cwd=wd, capture_output=True, text=True)
        return t["name"], r.returncode, r.stdout + r.stderr
    npass = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as ex:
        for name, rc, out in ex.map(one, sel):
            print(("PASS " if rc == 0 else "FAIL ") + name + ("" if rc == 0 else "  rc=%d" % rc))
            if verbose and rc != 0:
                print("   | " + "\n   | ".join(out.strip().splitlines()[-6:]))
            npass += rc == 0
    print("SUMMARY %d/%d passed (%s)" % (npass, len(sel), "NO_CACHE" if nocache else "cache"))


main()
