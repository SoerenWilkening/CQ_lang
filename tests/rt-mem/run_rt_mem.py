#!/usr/bin/env python3
"""Build and run the rt-mem differential test (cq-w0-rt-mem).

  run_rt_mem.py --clang <clang-19> --out <dir> [--seeds N]

Compiles native.ll (gen_native.py) with clang-19 -O1 for the corpus triple, links it with
checker/rt/rt_mem.c, the mock core and harness.c, requires every rt_mem.c mutant to fail the harness, runs the
harness for N seeds, then checks the exit event of a QRAM left with unpopped stores (160's Kept cells and slots)."""
import argparse
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
TRIPLE = "x86_64-apple-macosx"


# Mutants of rt_mem.c: each must make the harness fail (the test can see the bug it is for).
MUTANTS = [
    ("align_above_i128", "else align = 16;", "else align = 8;"),
    ("oor_index_reads", "if (!big && idx < n) read_element", "if (!big && idx <= n) read_element"),
    ("index_high_words_ignored", "if (!big && idx < n) read_element", "if (idx < n) read_element"),
    ("qrom_unc_rereads_host", "memcpy(ow, s->val, nw * sizeof *ow);",
     "read_element(ow, &d, table + (uintptr_t)(idx * stride));"),
    ("grow_reexposes_hidden", "v->map[i] = first + (i - keep);", "v->map[i] = i < phys0 ? i : first + (i - keep);"),
    ("store_no_swap", "memset(cp, 0, nw * sizeof *cp);", ";"),
    ("load_ignores_control", "if (c && !ix->big && ix->lo < view->n)", "if (!ix->big && ix->lo < view->n)"),
    ("hl_literal_signed", "ix->j = raw_u64(arg) & 0xFFFFFFFFu;", "ix->j = (uint64_t)(int64_t)(int32_t)raw_u64(arg);"),
    ("f80_alloc_10", "case 80: d->bits = 80; d->alloc = 16;", "case 80: d->bits = 80; d->alloc = 10;"),
    ("store_ignores_control", "s->active = c && in_range;", "s->active = in_range;"),
    ("pop_uses_current_view", "s->p = view->map[ix.lo];", "s->p = ix.lo;"),
    ("realloc_unc_keeps_size", "o->nviews--;", ";"),
    ("free_skips_slot_check", "if (g_slots[i].live && g_slots[i].obj == oi) {", "if (0) {"),
]


def sh(cmd, **kw):
    r = subprocess.run(cmd, **kw)
    if r.returncode:
        sys.exit(f"rt-mem: command failed ({r.returncode}): {' '.join(cmd)}")
    return r


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--clang", default="/usr/local/opt/llvm@19/bin/clang")
    ap.add_argument("--out", required=True)
    ap.add_argument("--seeds", type=int, default=5)
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    sh([sys.executable, os.path.join(HERE, "gen_native.py"), a.out])
    nat_o = os.path.join(a.out, "native.o")
    sh([a.clang, "-O1", "-target", TRIPLE, "-Wno-override-module", "-c", os.path.join(a.out, "native.ll"), "-o", nat_o])
    exe = os.path.join(a.out, "rt_mem_harness")
    sh([a.clang, "-O1", "-g", "-std=c17", "-Wall", "-Wextra", "-Werror", "-target", TRIPLE,
        "-I", os.path.join(ROOT, "checker", "rt"), "-I", HERE, "-I", a.out,
        os.path.join(ROOT, "checker", "rt", "rt_mem.c"), os.path.join(HERE, "mock_core.c"),
        os.path.join(HERE, "harness.c"), nat_o, "-o", exe])
    bad = 0
    src = open(os.path.join(ROOT, "checker", "rt", "rt_mem.c")).read()
    for name, old, new in MUTANTS:
        if src.count(old) != 1:
            print(f"rt-mem: mutant {name}: anchor not found exactly once")
            bad = 1
            continue
        mdir = os.path.join(a.out, "mutants")
        os.makedirs(mdir, exist_ok=True)
        msrc = os.path.join(mdir, name + ".c")
        with open(msrc, "w") as f:
            f.write(src.replace(old, new))
        mexe = os.path.join(mdir, name)
        sh([a.clang, "-O1", "-std=c17", "-w", "-target", TRIPLE, "-I", os.path.join(ROOT, "checker", "rt"),
            "-I", HERE, "-I", a.out, msrc, os.path.join(HERE, "mock_core.c"), os.path.join(HERE, "harness.c"),
            nat_o, "-o", mexe])
        r = subprocess.run([mexe, "0x1007"], env=dict(os.environ, RT_MEM_LOG=os.devnull),
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        killed = r.returncode != 0
        print(f"rt-mem: mutant {name}: {'rejected' if killed else 'SURVIVED'}")
        bad |= not killed
    for s in range(1, a.seeds + 1):
        log = os.path.join(a.out, f"seed{s}.jsonl")
        r = subprocess.run([exe, str(0x1000 + 7919 * s)], env=dict(os.environ, RT_MEM_LOG=log))
        bad |= r.returncode != 0
    log = os.path.join(a.out, "exit.jsonl")
    r = subprocess.run([exe, "--exit-kept"], env=dict(os.environ, RT_MEM_LOG=log))
    events = [json.loads(l) for l in open(log) if l.strip()]
    exits = [e for e in events if e.get("ev") == "qram" and e.get("op") == "exit"]
    ok = r.returncode == 0 and len(exits) == 1
    if ok:
        live = exits[0]["live"]
        cells = [x["v"] for x in live if x["role"] == "qram_cell"]
        slots = [x["v"] for x in live if x["role"] == "qram_slot"]
        ok = cells == ["0x0", "0x0", "0x0", "0x7"] and slots == ["0x0", "0x5", "0x0"] and all(
            x["w"] == "i32" for x in live)
    print(f"rt-mem: exit event {'ok' if ok else 'WRONG'}: {exits}")
    bad |= not ok
    print(f"rt-mem: {'PASS' if not bad else 'FAIL'} ({len(MUTANTS)} mutants, {a.seeds} seeds, exit check)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
