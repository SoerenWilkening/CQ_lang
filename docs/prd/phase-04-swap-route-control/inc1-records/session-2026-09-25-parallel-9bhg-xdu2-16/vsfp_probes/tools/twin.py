#!/usr/bin/env python3
"""twin.py ABFILE TAG [OUT]: for every mover in an ab.py output whose module came from
a probe source with a hand-inlined twin, build the twin and compare subject vs twin
under binary TAG (verdict; decline string; trace with args 5 7). Prints a table and a
class count. The ORACLE verdict of the subject is shown for reference."""
import collections
import concurrent.futures as cf
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import h  # noqa: E402

R = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16")
AB, TAG = sys.argv[1], sys.argv[2]
OUT = sys.argv[3] if len(sys.argv) > 3 else None

# tag -> source path (the buildcorp naming)
src_of = {}
for d in R.iterdir():
    if not d.is_dir():
        continue
    for src in d.rglob("*.c"):
        if src.name.endswith(".lib.c"):
            continue
        tag = "P_" + d.name + "__" + "_".join(src.relative_to(d).with_suffix("").parts)
        src_of[tag] = src


def twin_of(src):
    n = src.stem
    cands = [n + "T"]
    if n[-1:] in ("C", "S", "W", "f"):
        cands.append(n[:-1] + "T")
    for c in cands:
        p = src.with_name(c + ".c")
        if p.exists() and p != src:
            return p
    return None


def keyof(path):
    return (path.parent.parent.parent.name if path.parent.name == "src" else path.parent.name) + "__" + path.stem


import threading
_locks = collections.defaultdict(threading.Lock)
_memo = {}
_glock = threading.Lock()


def memo(key, fn):
    with _glock:
        lk = _locks[key]
    with lk:
        if key not in _memo:
            _memo[key] = fn()
        return _memo[key]


def verdict_src(path, args=("5", "7")):
    return memo(("v", str(path)), lambda: _verdict_src(path, args))


def _verdict_src(path, args=("5", "7")):
    # build into the harness's out/ via a private dir alias
    d = h.V / "twin_src"
    d.mkdir(exist_ok=True)
    key = keyof(path)
    for suf in (".c", ".lib.c"):
        s = path.with_name(path.stem + suf)
        if s.exists():
            (d / (key + suf)).write_text(s.read_text())
    return h.verdict(TAG, "twin_src", key, args)


def autotwin(path, args=("5", "7")):
    return memo(("a", str(path)), lambda: _autotwin(path, args))


def dropped_callees(path):
    """Names of the callees whose argument the drop removed in the 2-TU subject."""
    import os
    import subprocess
    s1, e = h.build("twin_src", keyof(path))
    if not s1:
        return set()
    r = subprocess.run([str(h.binpath(TAG)), "-passes=cq-lowering", "-S", str(s1), "-o", "/dev/null"],
                       capture_output=True, text=True, env=dict(os.environ, CQ_DEADARG_DBG="1"))
    import re
    return set(re.findall(r"CQ_DEADARG_DBG: drop arg \d+ of @([\w.]+)", r.stderr))


def _autotwin(path, args=("5", "7")):
    """The FAIR -O1-inlined twin: caller + library in ONE TU in which ONLY the
    callees whose argument was dropped are `always_inline` and every OTHER library
    function is `noinline` — so `clang -O1` hand-inlines exactly the call the twin
    rewrites and nothing else (a whole-TU inline also inlines spec-QUANTUM callees
    and const callees, a different circuit). Checked: no dropped callee survives
    as a call, else None."""
    lib = path.with_name(path.stem + ".lib.c")
    if not lib.exists():
        return None
    verdict_src(path)  # materialise twin_src/<key>.c and .lib.c
    drops = dropped_callees(path)
    import re
    libtxt = lib.read_text()
    names = set(re.findall(r"^\s*(?:static\s+)?(?:__attribute__\(\([^)]*\)\)\s*)?(?:const\s+)?[A-Za-z_][\w\s\*]*?\b([A-Za-z_]\w*)\s*\(([^;{)]*)\)\s*\{", libtxt, re.M))
    pre = []
    for n, params in names:
        attr = "always_inline" if n in drops else "noinline"
        pre.append(f"#define CQ_ATTR_{n} __attribute__(({attr}))")
    # re-declare each library function with its attribute, right before the library text
    decls = []
    for n, params in names:
        m = re.search(r"^\s*((?:static\s+)?(?:const\s+)?[A-Za-z_][\w\s\*]*?)\b" + re.escape(n) + r"\s*\(([^;{)]*)\)\s*\{", libtxt, re.M)
        if m and "static" not in m.group(1):
            decls.append(f"{m.group(1).strip()} {n}({m.group(2)}) __attribute__(({'always_inline' if n in drops else 'noinline'}));")
    d = h.V / "twin_src"
    key = keyof(path) + "__AUTOTWIN"
    (d / (key + ".c")).write_text(path.read_text() + "\n" + "\n".join(decls) + "\n" + libtxt)
    s1, e = h.build("twin_src", key)
    if not s1:
        return None
    import re
    txt = s1.read_text()
    defs = set(re.findall(r"^define [^@]*@([\w.]+)\(", txt, re.M))
    calls = set(re.findall(r"call [^@]*@([\w.]+)\(", txt))
    libdefs = set(re.findall(r"^\s*(?:static\s+)?(?:__attribute__\(\([^)]*\)\)\s*)?(?:const\s+)?\w[\w\s\*]*?\b(\w+)\s*\([^;{]*\)\s*\{", lib.read_text(), re.M))
    if calls & drops:
        return None  # a dropped callee survived as a call: not an inlined twin
    return h.verdict(TAG, "twin_src", key, args)


rows = []
for l in open(AB):
    if l.startswith(("denominator", "summary")):
        continue
    p = l.rstrip("\n").split("\t")
    k, f = p[0], pathlib.Path(p[1]).name.replace(".s1.ll", "")
    rows.append((k, f))


def one(r):
    k, tag = r
    src = src_of.get(tag)
    if not src:
        return k, tag, "NO-SRC", "", ""
    tw = twin_of(src)
    s = verdict_src(src)
    if tw:
        t = verdict_src(tw)
        kind = "hand"
    else:
        t = autotwin(src)
        kind = "auto"
        if t is None:
            return k, tag, "NO-TWIN", f"S={s['v']} {s.get('msg','')[-90:]}", ""
    c = cmp(s, t)
    # a hand twin that disagrees is re-asked against the -O1-inlined twin: several
    # hand twins in the records are the spec-QUANTUM twin (g3T: `u = q + w`).
    if kind == "hand" and c not in ("TRACE-IDENT", "DECL-SAME"):
        t2 = autotwin(src)
        if t2 is not None:
            c2 = cmp(s, t2)
            return k, tag, c + "/auto:" + c2, f"S={s['v']} {s.get('msg','')[-90:]} w={s.get('warn','')}", f"T={t2['v']} {t2.get('msg','')[-90:]} w={t2.get('warn','')}"
    return k, tag, c + ("" if kind == "hand" else "(auto)"), f"S={s['v']} {s.get('msg','')[-90:]} w={s.get('warn','')}", f"T={t['v']} {t.get('msg','')[-90:]} w={t.get('warn','')}"


def cmp(s, t):
    if s["v"] == "ACC" and t["v"] == "ACC":
        return "TRACE-IDENT" if s["trace"] == t["trace"] else "TRACE-DIFF"
    if s["v"] == "DECL" and t["v"] == "DECL":
        sm = s.get("msg", "").split(": ", 1)[-1]
        tm = t.get("msg", "").split(": ", 1)[-1]
        return "DECL-SAME" if sm == tm else "DECL-DIFFSTR"
    return "VERDICT-DIFF"


def _unused(r):
    k, tag = r
    src = src_of.get(tag)
    if not src:
        return k, tag, "NO-SRC", "", ""
    tw = twin_of(src)
    if not tw:
        return k, tag, "NO-TWIN", "", ""
    s = verdict_src(src)
    t = verdict_src(tw)
    if s["v"] == "ACC" and t["v"] == "ACC":
        c = "TRACE-IDENT" if s["trace"] == t["trace"] else "TRACE-DIFF"
    elif s["v"] == "DECL" and t["v"] == "DECL":
        sm = s.get("msg", "").split(": ", 1)[-1]
        tm = t.get("msg", "").split(": ", 1)[-1]
        c = "DECL-SAME" if sm == tm else "DECL-DIFFSTR"
    else:
        c = "VERDICT-DIFF"
    return k, tag, c, f"S={s['v']} {s.get('msg','')[-90:]} w={s.get('warn','')}", f"T={t['v']} {t.get('msg','')[-90:]} w={t.get('warn','')}"


with cf.ThreadPoolExecutor(8) as ex:
    res = list(ex.map(one, rows))
cnt = collections.Counter((r[0], r[2]) for r in res)
lines = [f"{k}\t{tag}\t{c}\t{s}\t{t}" for k, tag, c, s, t in res]
if OUT:
    open(OUT, "w").write("\n".join(lines) + "\n")
for l in lines:
    if not any(x in l.split("\t")[2] for x in ("TRACE-IDENT", "DECL-SAME")) or "/auto" in l.split("\t")[2]:
        print(l[:330])
print("---")
for (k, c), n in sorted(cnt.items()):
    print(f"{k:7s} {c:14s} {n}")
