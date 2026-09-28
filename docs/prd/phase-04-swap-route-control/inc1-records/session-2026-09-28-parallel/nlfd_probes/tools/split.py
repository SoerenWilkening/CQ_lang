#!/usr/bin/env python3
"""split.py save|A|B|C — stage the three separable commits of this track.

  save  copy the FINAL version of every file this track changes to the scratchpad
  A     write the bd nlfd versions (ev3m / demotion hunks reverted in mixed files; B/C-only
        files at their `main` versions; B/C-only new files removed from the tree)
  B     A + the bd ev3m files (final versions), demotion still reverted
  C     every file at its final version
Every revert is an anchored replacement that must match exactly once (else abort)."""
import pathlib
import shutil
import subprocess
import sys

W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295")
SAVE = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/nlfd/final")

A_FILES = [
    "ir-pass/include/DeadValueLiveness.h", "ir-pass/src/DeadValueLiveness.cpp",
    "ir-pass/src/Specialization.cpp", "ir-pass/include/SpecializeDetect.h",
    "ir-pass/test/spec_accept_phantom_arg_read_unread_scalar_inner_arg.ll",
    "ir-pass/test/spec_accept_phantom_arg_read_unread_scalar_inner_arg_range.ll",
    "ir-pass/test/spec_accept_phantom_arg_read_unread_scalar_inner_inst_live.ll",
    "ir-pass/test/spec_accept_phantom_arg_read_unread_scalar_nested_arg.ll",
    "ir-pass/test/spec_accept_phantom_arg_read_unread_scalar_classical_inst.ll",
    "ir-pass/test/spec_reject_phantom_arg_read_unread_scalar_inner_inst.ll",
    "ir-pass/test/spec_reject_phantom_arg_read_unread_scalar_inner_inst_musttail.ll",
    "ir-pass/test/spec_reject_phantom_arg_read_unread_scalar_outer_nn.ll",
]
B_FILES = [
    "ir-pass/src/SpecializeDetect.cpp", "ir-pass/src/CQLoweringPass.cpp",
    "ir-pass/test/spec_accept_dropped_arg_musttail_kept.ll",
    "ir-pass/test/spec_accept_phantom_arg_read_musttail_inner_slot.ll",
    "ir-pass/test/spec_accept_dropped_arg_musttail_return.ll",
    "ir-pass/test/spec_accept_dropped_arg_musttail_forward_chain.ll",
    "tests/e2e/CMakeLists.txt", "tests/e2e/slice_spec_dropped_arg_musttail_inner.c",
    "tests/e2e/spec_dropped_arg_musttail_lib.c",
    "tests/e2e/slice_spec_dropped_arg_musttail_return.c",
    "tests/e2e/slice_spec_dropped_arg_musttail_return.expected.log",
    "tests/e2e/slice_spec_dropped_arg_musttail_return_twin.c",
    "tests/e2e/slice_spec_dropped_arg_musttail_return_twin.expected.log",
    "tests/e2e/spec_dropped_arg_musttail_return_lib.c",
]
C_FILES = [
    "ir-pass/src/SpecializeClone.cpp", "ir-pass/include/SpecializeClone.h",
    "ir-pass/test/spec_accept_musttail_in_clone_demoted.ll",
]

# The ev3m hunks inside files that commit A carries (reverted for A, restored for B).
EV3M_IN_A = {
    "ir-pass/include/DeadValueLiveness.h": [(
        "// (`dropEligibleSlot`): round 5 asked that, and its then-`musttail` POLICY conservatism\n// (retired by bd ev3m, 2026-09-28)\n",
        "// (`dropEligibleSlot`): round 5 asked that, and its `musttail` POLICY conservatism\n")],
    "ir-pass/src/Specialization.cpp": [(
        "  //    attributes — `nullSafeSlot`; never the drop's POLICY, bd `w7nm` — whose\n  //    `musttail` refusal bd ev3m has since retired)\n",
        "  //    attributes — `nullSafeSlot`; never the drop's `musttail` policy, bd `w7nm`)\n")],
}


def git_show_main(rel):
    r = subprocess.run(["git", "show", "9a230646:" + rel], cwd=W, capture_output=True)
    return r.stdout if r.returncode == 0 else None


def put(rel, data):
    p = W / rel
    if data is None:
        if p.exists():
            p.unlink()
    else:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)


def final(rel):
    return (SAVE / rel).read_bytes()


def spec_detect_h_A():
    """SpecializeDetect.h for commit A: the nlfd nullSafeSlot hunk only."""
    main = git_show_main("ir-pass/include/SpecializeDetect.h").decode()
    fin = final("ir-pass/include/SpecializeDetect.h").decode()
    old = """// `byval` slot compiled clean and the executable SIGSEGVed. This is the ONLY slot
// question the post-`specialize()` rewrite and the liveness call-slot rule ask
// (`isRewritableDeadSlot`, DeadValueLiveness.h).
"""
    s0, s1 = fin.index("// `byval` slot compiled clean and the executable SIGSEGVed. This is the ONLY slot\n// question the post-`specialize()` REWRITE asks"), None
    s1 = fin.index("// ⚠ IT ASKS NO CALLEE CONJUNCT", s0)
    new = fin[s0:s1]
    if main.count(old) != 1:
        raise SystemExit("SpecializeDetect.h anchor")
    return main.replace(old, new).encode()


def main():
    cmd = sys.argv[1]
    if cmd == "save":
        for rel in A_FILES + B_FILES + C_FILES:
            d = SAVE / rel
            d.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(W / rel, d)
        print("saved", len(A_FILES + B_FILES + C_FILES))
        return
    stage = cmd
    for rel in A_FILES:
        data = final(rel)
        if rel == "ir-pass/include/SpecializeDetect.h" and stage == "A":
            data = spec_detect_h_A()
        if stage == "A" and rel in EV3M_IN_A:
            s = data.decode()
            for new, old in EV3M_IN_A[rel]:
                if s.count(new) != 1:
                    raise SystemExit(f"anchor {rel}")
                s = s.replace(new, old)
            data = s.encode()
        put(rel, data)
    for rel in B_FILES:
        put(rel, final(rel) if stage in ("B", "C") else git_show_main(rel))
    for rel in C_FILES:
        put(rel, final(rel) if stage == "C" else git_show_main(rel))
    print("staged", stage)


if __name__ == "__main__":
    main()
