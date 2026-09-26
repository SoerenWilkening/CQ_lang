#!/usr/bin/env python3
"""Apply the bd vsfp re-spell to every DECLINE fixture whose subject the dead-argument
drop removed: insert a dead read of the ignored parameter in the callee, arm the first
RUN line with `env CQ_DEADARG_DBG=1`, add `CHECK-NOT: CQ_DEADARG_DBG` before the first
default-prefix directive, and add the header note after the title line."""
import pathlib
import re
import subprocess

T = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/test")
RESPELL = pathlib.Path(__file__).parent / "respell.py"

COMMON = """; ⚠ bd test_C_libtooling-vsfp (2026-09-26) — RE-SPELLED, and why. `@{callee}` used to
; IGNORE its parameter {pidx}. `dropDeadCallArguments` (SpecializeDetect.h) now replaces
; an integer/fp argument whose callee parameter has NO USES by a constant before any
; stage reads it — what `clang -O1` does to the hand-inlined twin — so that spelling
; never reaches the specializer: {what}
; The ONE added line in `@{callee}`, `%vsfp.read`, is a DEAD READ that keeps the
; parameter used, so this file still reaches the fence it was written for. That
; residual population — a callee that READS the argument yet returns classical — is
; IR-ONLY from C at -O1 (the library TU deletes a dead read). The `env
; CQ_DEADARG_DBG=1` + `CHECK-NOT: CQ_DEADARG_DBG` pair pins that the drop does NOT
; fire here: a widening of the drop (e.g. to dataflow liveness) retires this subject
; and must re-derive it (CLAUDE.md L8).
;"""

WHAT = {
    "d88e": "`t` is classical from the start and the\n; classical-mux guard itself declines with this very string — the verdict AND the\n; string survived while the SUBJECT (the d88e re-ask) vanished, which no stdout/stderr\n; A/B can see (found by the `CQ_DEADARG_DBG` census: 33 lit modules touched).",
    "l3oi": "`t` is classical from the start, no gate ever\n; reads it as a handle, and that spelling now ACCEPTS with the hand-inlined twin's\n; stream (bd cepm's over-decline, removed for a callee that ignores the argument) —\n; pinned by `spec_accept_dropped_arg_scrubbed_handle_branch.ll`.",
    "ret": "the call became an ordinary classical call,\n; `scanBody`'s return fence was never asked, and the module ACCEPTED (the caller reads\n; the call's RESULT as one runtime value, so no undef literal is duplicated).",
    "retnested": "the inner call's argument became a constant\n; (the outer callee still reads `%t`), so the fence still fires in `@inner`'s frame —\n; but through a CLASSICAL inner call, a narrower subject than the one written here.",
    "predmux": "the call became classical, the specializer's\n; return fence was never asked, and the module declined at a DOWNSTREAM owner\n; (`control flow under quantum control`) instead.",
}

JOBS = [
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_arm_chain.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_controlled_consumer.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_fp.ll", "hf", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_ifelse_all_arms.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_l3oi_owner.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_nonmain.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_owner.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_pure_consumer.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_reversed_layout.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_store.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_switch.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_switch_nway_all_arms.ll", "h", 0, "d88e"),
    ("lowering_reject_classical_mux_phi_spec_scrubbed_base_two_lifts.ll", "h", 0, "d88e"),
    ("taint_reject_scrubbed_handle_branch.ll", "h", 0, "l3oi"),
    ("taint_reject_scrubbed_handle_branch2.ll", "h", 0, "l3oi"),
    ("taint_reject_scrubbed_handle_clone_arg.ll", "h", 0, "l3oi"),
    ("taint_reject_scrubbed_handle_clone_arg_branch.ll", "h", 0, "l3oi"),
    ("taint_reject_scrubbed_handle_clone_arg_mixed.ll", "h", 0, "l3oi"),
    ("taint_reject_scrubbed_handle_mixed_select.ll", "h", 0, "l3oi"),
    ("spec_reject_ret_poison.ll", "leaf", 0, "ret"),
    ("spec_reject_ret_undef_derived.ll", "leaf", 0, "ret"),
    ("spec_reject_ret_undef_spelling.ll", "leaf", 0, "ret"),
    ("spec_reject_ret_poison_nested.ll", "inner", 0, "retnested"),
    ("control_predmux_reject_selectform_purecallee_retpoison.ll", "leaf", 0, "predmux"),
]

for name, callee, idx, fam in JOBS:
    p = T / name
    tmp = p.with_suffix(".tmp")
    subprocess.run(["python3", str(RESPELL), str(p), str(tmp), callee, str(idx)], check=True, capture_output=True)
    txt = tmp.read_text()
    tmp.unlink()
    lines = txt.split("\n")
    # header note after the first line
    note = COMMON.format(callee=callee, pidx=idx, what=WHAT[fam])
    lines = [lines[0]] + note.split("\n") + lines[1:]
    # first RUN line: arm the env var
    for i, l in enumerate(lines):
        if l.startswith("; RUN: not %cq-opt"):
            lines[i] = l.replace("; RUN: not %cq-opt", "; RUN: env CQ_DEADARG_DBG=1 not %cq-opt", 1)
            break
    else:
        raise SystemExit(f"{name}: no `; RUN: not %cq-opt` line")
    # CHECK-NOT before the first default-prefix directive
    for i, l in enumerate(lines):
        if re.match(r"^; CHECK(-[A-Z]+)?:", l):
            lines.insert(i, "; CHECK-NOT: CQ_DEADARG_DBG")
            break
    else:
        raise SystemExit(f"{name}: no default CHECK directive")
    p.write_text("\n".join(lines))
    print("respelled", name)
