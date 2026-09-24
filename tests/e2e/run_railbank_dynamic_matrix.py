#!/usr/bin/env python3
"""Compile the xdu2.4 C admission matrix at clang -O1 and check each verdict."""

from __future__ import annotations

import pathlib
import subprocess
import sys
import tempfile


CASES = {
    1: (True, None),
    2: (True, None),
    3: (False, "cq rail bank: array has cells no iteration writes"),
    4: (False, "cq rail bank: array has cells no iteration writes"),
    5: (False, "cq taint escape: tainted value stored to memory"),
    6: (False, "cq rail bank: array escapes to an unsupported user"),
    7: (False, "cq taint escape: tainted value reaches an unsupported instruction"),
    8: (False, "cq rail bank: array element is not a reversible rail cell"),
    9: (False, "cq controlled lowering: control flow under quantum control"),
    10: (False, "cq rail bank: cell address has no bounded local-array provenance"),
    11: (False, "cq taint escape: tainted value stored to memory"),
    12: (False, "cq rail bank: array has cells no iteration writes"),
    13: (False, "cq controlled lowering: control flow under quantum control"),
    14: (True, None),
    15: (True, None),
    16: (True, None),
    17: (True, None),
    18: (False, "cq controlled lowering: control flow under quantum control"),
    19: (False, "cq taint escape: tainted value stored to memory"),
    20: (False, "cq rail bank: a cell parks a value that is not a rail handle"),
    21: (False, "cq rail bank: a cell parks a value that is not a rail handle"),
    22: (True, None),
    23: (True, None),
    24: (False, "cq rail bank: the cell walk is re-executed by an enclosing loop"),
    25: (False, "cq rail bank: the cell walk is re-executed by an enclosing loop"),
    26: (False, "cq rail bank: the cell walk is re-executed by an enclosing loop"),
    27: (False, "cq rail bank: the cell walk is re-executed by an enclosing loop"),
}

# (rolled case, unrolled twin, argv tail, identity lines dropped from the twin).
# The loop-twin discipline (CLAUDE.md §1 Witnesses): an in-loop accept is
# witnessed by BYTE IDENTITY with its hand-unrolled twin.
TWINS = [
    (14, 17, ["a", "b"], {"cqrt_ry_i32(h0, 0x0p+0)"}),
]


def run(cmd: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(cmd, text=True, capture_output=True, check=False)


def main() -> int:
    if len(sys.argv) != 8:
        print("usage: run_railbank_dynamic_matrix.py CLANG CQ_OPT PASS INCLUDE "
              "SOURCE RUNTIME_LIB TEMPLATES_LIB", file=sys.stderr)
        return 2
    clang, cq_opt, plugin, include, source, runtime, templates = sys.argv[1:]

    with tempfile.TemporaryDirectory() as temp_dir:
        temp = pathlib.Path(temp_dir)
        for case_id, (should_accept, diagnostic) in CASES.items():
            stage1 = temp / f"case-{case_id}.ll"
            lowered = temp / f"case-{case_id}.lowered.ll"
            compile_result = run([
                clang, f"-I{include}", "-include", "CQ.h", "-O1",
                "-emit-llvm", "-S", f"-DCASE={case_id}", source,
                "-o", str(stage1),
            ])
            if compile_result.returncode != 0:
                sys.stderr.write(compile_result.stderr)
                return 1

            lower_result = run([
                cq_opt, "-load-pass-plugin", plugin, "-passes=cq-lowering",
                "-S", str(stage1), "-o", str(lowered),
            ])
            if should_accept:
                if lower_result.returncode != 0:
                    sys.stderr.write(
                        f"CASE={case_id}: expected accept\n{lower_result.stderr}")
                    return 1
                stage1_text = stage1.read_text()
                lowered_text = lowered.read_text()
                if case_id == 1 and "alloca i32, i64" not in stage1_text:
                    print("CASE=1: clang -O1 did not preserve a runtime i32 VLA",
                          file=sys.stderr)
                    return 1
                if case_id == 2:
                    nonentry_label = stage1_text.find("\n8:")
                    bank_alloca = stage1_text.find("alloca [3 x i32]", nonentry_label)
                    if nonentry_label < 0 or bank_alloca < 0:
                        print("CASE=2: clang -O1 no longer produced the non-entry bank",
                              file=sys.stderr)
                        return 1
                bankless = any(case_id == t for _r, t, _a, _d in TWINS)
                if not bankless and "!cq.railbank" not in lowered_text:
                    print(f"CASE={case_id}: accepted bank lacks !cq.railbank",
                          file=sys.stderr)
                    return 1
                if "cqrt_qram_" in lowered_text:
                    print(f"CASE={case_id}: rail bank emitted cqrt_qram_*",
                          file=sys.stderr)
                    return 1
                if "store i32 0, ptr %cq.bank.addr" in lowered_text:
                    print(f"CASE={case_id}: rail bank stored literal handle 0",
                          file=sys.stderr)
                    return 1
            else:
                if lower_result.returncode == 0:
                    print(f"CASE={case_id}: expected a loud decline", file=sys.stderr)
                    return 1
                if diagnostic not in lower_result.stderr:
                    print(f"CASE={case_id}: missing diagnostic: {diagnostic}",
                          file=sys.stderr)
                    sys.stderr.write(lower_result.stderr)
                    return 1

        for rolled, twin, argv_tail, dropped in TWINS:
            traces = []
            for case_id in (rolled, twin):
                exe = temp / f"case-{case_id}.exe"
                link = run([clang, str(temp / f"case-{case_id}.lowered.ll"),
                            templates, runtime, "-o", str(exe)])
                if link.returncode != 0:
                    sys.stderr.write(f"CASE={case_id}: link failed\n{link.stderr}")
                    return 1
                result = run([str(exe), *argv_tail])
                traces.append(result.stdout.splitlines())
            rolled_trace = traces[0]
            twin_trace = [ln for ln in traces[1] if ln not in dropped]
            if len(traces[1]) - len(twin_trace) != len(dropped):
                print(f"TWIN {rolled}/{twin}: expected to drop exactly "
                      f"{len(dropped)} identity line(s)", file=sys.stderr)
                return 1
            if not rolled_trace or rolled_trace != twin_trace:
                print(f"TWIN {rolled}/{twin}: rolled trace is not byte-identical "
                      "to the hand-unrolled twin", file=sys.stderr)
                return 1

    accepted = sum(1 for ok, _ in CASES.values() if ok)
    print(f"railbank_dynamic_matrix: {accepted} accepted, "
          f"{len(CASES) - accepted} declined, {len(TWINS)} twin(s) identical, "
          "0 cqrt_qram_* operations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
