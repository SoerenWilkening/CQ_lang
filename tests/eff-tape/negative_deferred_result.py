#!/usr/bin/env python3
"""Negative probe (owner ruling 2026-11-12 item 4): the C reference takes an output call's result from musl's source, so a
lowering whose result is wrong must FAIL `cqcheck user`.

probes/deferred_fputc.c is lowered by driver/cqcc; putc's result ((unsigned char)c, musl putc.h) is then mutated to
(unsigned short)c: the trunc to i8 and the zext back, with their uncomputes, become i16. The tape and the effects stay as
they were; only the measured sum differs where x - 1 is outside 0..255. The check must exit 1 with a measurement reason.
Then the unmutated lowering must PASS (the C side's value is musl's, not the stand-in's hash).

    CQ_BUILD_DIR=<build> python3 tests/eff-tape/negative_deferred_result.py
"""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBE = ROOT / "tests" / "eff-tape" / "probes" / "deferred_fputc.c"
EDITS = [
    ("%20 = call i32 @cq_template_trunc_i32_to_i8(i32 %18)", "%20 = call i32 @cq_template_trunc_i32_to_i16(i32 %18)"),
    ("%21 = call i32 @cq_template_zext_i8_to_i32(i32 %20)", "%21 = call i32 @cq_template_zext_i16_to_i32(i32 %20)"),
    ("@cq_template_zext_i8_to_i32_unc(i32 %21, i32 %20)", "@cq_template_zext_i16_to_i32_unc(i32 %21, i32 %20)"),
    ("@cq_template_trunc_i32_to_i8_unc(i32 %20, i32 %18)", "@cq_template_trunc_i32_to_i16_unc(i32 %20, i32 %18)"),
]
DECLS = ("declare i32 @cq_template_trunc_i32_to_i16(i32)\ndeclare i32 @cq_template_zext_i16_to_i32(i32)\n"
         "declare void @cq_template_trunc_i32_to_i16_unc(i32, i32)\ndeclare void @cq_template_zext_i16_to_i32_unc(i32, i32)\n")


def check(o1: Path, low: Path) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, "-m", "cqcheck", "user", "--o1", str(o1), "--lowered", str(low), "--entry", "probe",
                           "--samples", "64"], cwd=ROOT / "checker", capture_output=True, text=True)


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="cq-negdef-") as t:
        d = Path(t)
        r = subprocess.run([sys.executable, str(ROOT / "driver" / "cqcc"), "-S", str(PROBE), "--save-temps", str(d),
                            "-o", str(d / "out.ll")], capture_output=True, text=True)
        if r.returncode:
            print("FAIL cqcc:", r.stderr)
            return 1
        whole = (d / "lowered.ll").read_text()
        start = whole.index("@probe(")       # the entry's own body (the module may hold its twins)
        end = whole.index("\n}\n", start)
        text = whole[start:end]
        for old, new in EDITS:
            if text.count(old) != 1:
                print(f"FAIL the mutation no longer applies: {old!r} occurs {text.count(old)} times")
                return 1
            text = text.replace(old, new)
        (d / "mutant.ll").write_text(whole[:start] + text + whole[end:] + DECLS)
        bad = check(d / "linked.ll", d / "mutant.ll")
        good = check(d / "linked.ll", d / "lowered.ll")
    fails = []
    if bad.returncode != 1 or not re.search(r"measure", bad.stdout):
        fails.append(f"mutant: exit {bad.returncode}, want 1 with a measurement reason:\n{bad.stdout[-1500:]}{bad.stderr[-500:]}")
    if good.returncode != 0:
        fails.append(f"unmutated: exit {good.returncode}, want 0:\n{good.stdout[-1500:]}{good.stderr[-500:]}")
    print("\n".join(fails) if fails else "ok   negative deferred result: the mutant FAILS, the lowering PASSES")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
