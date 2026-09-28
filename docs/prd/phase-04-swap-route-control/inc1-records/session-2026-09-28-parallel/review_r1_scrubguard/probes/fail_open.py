#!/usr/bin/env python3
"""Review r1: fail-closed / fail-open paths of the configuration and compile layers.
Guard imported UNMODIFIED; USE_PCH=False (the gate's semantics). Databases are written to
<scratch>. usage: fail_open.py <subject-root> <scratch>"""
import json, os, stat, sys
sys.dont_write_bytecode = True
ROOT, SCR = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(ROOT, "tools"))
import taintset_scrub_guard as G
G.USE_PCH = False
ONLY = sys.argv[3] if len(sys.argv) > 3 else None
db = json.load(open(os.path.join(ROOT, "build", "compile_commands.json")))
hdr = open(G.HEADER).read(); st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
NOTPLUGIN = hdr.replace("struct TaintSet {", "struct TaintSet {\n#ifndef CQPass_EXPORTS\n  std::set<llvm::Value *> RvNotPlugin;\n#endif\n", 1)

def write_db(name, entries):
    p = os.path.join(SCR, name); json.dump(entries, open(p, "w")); return p

def wrapper(name, pattern, action):
    p = os.path.join(SCR, name)
    open(p, "w").write(f"""#!/bin/sh
for a in "$@"; do case "$a" in *{pattern}*) {action} ;; esac; done
exec /usr/bin/c++ "$@"
""")
    os.chmod(p, 0o755); return p

def with_compiler(entries, comp):
    out = []
    for e in entries:
        e = dict(e); e["command"] = e["command"].replace("/usr/bin/c++", comp, 1); out.append(e)
    return out

def run(label, dbpath, header, expect_refused):
    if ONLY and not label.startswith(ONLY):
        return
    # L10 (this review's own instrument): the guard's SPECULATION cache (_SPEC, module-global) lets the
    # root identity TU answer every member question once an earlier check in this process has run, so a
    # compiler that dies only on member-type TUs is never even invoked. The first version of this probe
    # scored F3 'CLEAN' for exactly that reason. Clear it so every case starts cold.
    G._SPEC.clear()
    G.COMPILE_COMMANDS = dbpath; G._CFGS = None; G.LAST_RUN.clear()
    errs, n = G.check(header, st, G.ALLOWLIST, sc)
    ok = bool(errs) == expect_refused
    print(f"{'ok ' if ok else 'BAD'} {'refused' if errs else 'CLEAN  '} {label}  [{n} members, passes={G.LAST_RUN.get('passes')}]", flush=True)
    for e in errs[:2]: print("        ERR  " + e.splitlines()[0][:220], flush=True)

# control: the intact database refuses the NotPlugin member (r3 B3 re-measured)
run("CONTROL intact database, #ifndef CQPass_EXPORTS raw member", write_db("cc_intact.json", db), NOTPLUGIN, True)
# F1: the cq-opt / cq-scrub-selftest entries are MALFORMED ("arguments": [], no "command") —
# _normalize raises, _configs() `continue`s, the configuration silently disappears.
mal = []
for e in db:
    if "cq-opt" in (e.get("output") or e["command"]) or "cq-scrub-selftest" in (e.get("output") or e["command"]):
        e = {k: v for k, v in e.items() if k != "command"}; e["arguments"] = []
    mal.append(e)
run("F1 malformed entries for ONE configuration, same raw member", write_db("cc_malformed.json", mal), NOTPLUGIN, True)
# F2-F4: a compiler that dies (SIGKILL, no output) or silently prints nothing for one probe TU kind
for lab, pat, act in (("F2 compiler SIGKILLed on the final trait/spelling TU", "cq_guard_final_", "kill -9 $$"),
                      ("F3 compiler SIGKILLed on every member-type TU", "cq_guard_rob_", "kill -9 $$"),
                      ("F4 compiler exits 0 with NO output on the final TU", "cq_guard_final_", "exit 0"),
                      ("F5 compiler exits 0 with NO output on every identity TU", "cq_guard_id_", "exit 0")):
    comp = wrapper("cc_" + pat.strip("_") + ("_kill" if "kill" in act else "_silent") + ".sh", pat, act)
    run(lab + " (pristine header)", write_db("cc_" + os.path.basename(comp) + ".json", with_compiler(db, comp)), hdr, True)
