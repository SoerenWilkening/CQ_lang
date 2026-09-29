#!/usr/bin/env python3
"""Review r2: fail-open paths of round 2's NEW include-order check. Guard imported UNMODIFIED,
USE_PCH=False (the gate's semantics). The header under test is the A5 shape (a raw table under
`#ifdef` of CQLoweringPass.h's guard, written in TaintPropagation.h itself), which the intact
database REFUSES as "preprocesses DIFFERENTLY". A compiler wrapper misbehaves ONLY on the two
include-order `-E` TUs (their names contain `cq_guard_ctx`); every other probe is the real compiler.
usage: fail_open_r2.py <subject-root> <scratch>"""
import json, os, sys
sys.dont_write_bytecode = True
ROOT, SCR = sys.argv[1], sys.argv[2]
sys.path.insert(0, os.path.join(ROOT, "tools"))
import taintset_scrub_guard as G
G.USE_PCH = False
db = json.load(open(os.path.join(ROOT, "build", "compile_commands.json")))
hdr = open(G.HEADER).read(); st = open(G.SELFTEST).read(); sc = open(G.SCRUB_HDR).read()
A5 = hdr.replace("struct TaintSet {", "struct TaintSet {\n#ifdef CQ_IRPASS_CQ_LOWERING_PASS_H_\n"
                 "  std::set<llvm::Value *> RvCtxFO;\n#endif\n", 1)
def wrapper(name, action):
    p = os.path.join(SCR, name)
    open(p, "w").write(f"""#!/bin/sh
for a in "$@"; do case "$a" in *cq_guard_ctx*) {action} ;; esac; done
exec /usr/bin/c++ "$@"
""")
    os.chmod(p, 0o755); return p
def with_compiler(comp):
    out = []
    for e in db:
        e = dict(e); e["command"] = e["command"].replace("/usr/bin/c++", comp, 1); out.append(e)
    p = os.path.join(SCR, "cc_" + os.path.basename(comp) + ".json"); json.dump(out, open(p, "w")); return p
def run(label, dbpath, expect_refused):
    G._SPEC.clear(); G.COMPILE_COMMANDS = dbpath; G._CFGS = None; G.LAST_RUN.clear()
    errs, n = G.check(A5, st, G.ALLOWLIST, sc)
    ok = bool(errs) == expect_refused
    print(f"{'ok ' if ok else 'BAD'} {'refused' if errs else 'CLEAN  '} {label}  [{n} members, passes={G.LAST_RUN.get('passes')}]", flush=True)
    for e in errs[:2]: print("        ERR  " + e.splitlines()[0][:220], flush=True)
intact = os.path.join(SCR, "cc_intact.json"); json.dump(db, open(intact, "w"))
run("CONTROL intact database, A5-shape member", intact, True)
run("G1 compiler exits 0 with NO output on both include-order -E TUs",
    with_compiler(wrapper("cc_ctx_silent.sh", "exit 0")), True)
run("G2 compiler preprocesses the include-order TUs with -P (no line markers)",
    with_compiler(wrapper("cc_ctx_nomarkers.sh", 'exec /usr/bin/c++ "$@" -P')), True)
run("G3 compiler SIGKILLed on the include-order -E TUs",
    with_compiler(wrapper("cc_ctx_kill.sh", "kill -9 $$")), True)
