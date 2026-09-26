#!/usr/bin/env python3
"""The ACCEPT half of the bd vsfp re-spell: dead read in the callee, the first RUN
armed with `env CQ_DEADARG_DBG=1` and its stderr captured, a NODROP RUN over it."""
import pathlib
import re
import subprocess

T = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/test")
RESPELL = pathlib.Path(__file__).parent / "respell.py"

NOTE = """; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@{callee}` used to
; IGNORE its parameter 0. `dropDeadCallArguments` (SpecializeDetect.h) now replaces an
; integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; is no longer a Phase-6 site at all: the call stays an ordinary classical call, no
; clone is built and nothing is scrubbed, i.e. the property this file pins would have
; no subject. The ONE added line in `@{callee}`, `%vsfp.read`, is a DEAD READ that keeps
; the parameter used, so the clone is still built, still returns classical and is
; still scrubbed. (Its forward/adjoint template pair now sits in the CLONE body; the
; caller-side checks below are unchanged.) That population — a callee that READS the
; argument yet returns classical — is IR-ONLY from C at -O1. The NODROP prefix pins
; that the drop does NOT fire here; a widening of the drop retires this subject and
; must re-derive it (CLAUDE.md L8).
;"""

JOBS = [
    ("spec_result_classical.ll", "double_classical"),
    ("spec_reseed_theta_source.ll", "cls"),
    ("lowering_classical_mux_phi_onereg_spec_scrubbed_elsewhere.ll", "h"),
    ("lowering_classical_mux_phi_onereg_spec_scrubbed_base_degenerate.ll", "h"),
]

for name, callee in JOBS:
    p = T / name
    tmp = p.with_suffix(".tmp")
    subprocess.run(["python3", str(RESPELL), str(p), str(tmp), callee, "0"], check=True, capture_output=True)
    lines = tmp.read_text().split("\n")
    tmp.unlink()
    lines = [lines[0]] + NOTE.format(callee=callee).split("\n") + lines[1:]
    for i, l in enumerate(lines):
        if l.startswith("; RUN: %cq-opt"):
            l2 = l.replace("; RUN: %cq-opt", "; RUN: env CQ_DEADARG_DBG=1 %cq-opt", 1)
            if " > %t.cqd0.ll" in l2:
                l2 = l2.replace(" > %t.cqd0.ll", " > %t.cqd0.ll 2> %t.vsfp.err")
                lines[i] = l2
                ins = i + 1
            else:
                # `... -S %s \` then `;   | %filecheck %s`
                assert l2.rstrip().endswith("\\"), l2
                lines[i] = l2.rstrip()[:-1].rstrip() + " 2> %t.vsfp.err \\"
                ins = i + 2
            break
    else:
        raise SystemExit(f"{name}: no `; RUN: %cq-opt` line")
    lines.insert(ins, "; RUN: %filecheck %s --check-prefix=NODROP --allow-empty < %t.vsfp.err")
    lines.insert(ins + 1, "; NODROP-NOT: CQ_DEADARG_DBG")
    p.write_text("\n".join(lines))
    print("respelled", name)
