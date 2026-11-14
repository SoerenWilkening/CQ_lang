#!/usr/bin/env python3
"""cq-tdqrq: the leak rule is skipped on a real host exit and nowhere else, and the exit status is compared.

Controls that must pass and mutants of the lowered program that must fail `cqcheck user --light`, each for the
reason it names. Mutants are text edits inside one lowered function.
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PROBES = Path(__file__).parent / "probes"
OUT = ROOT / "build" / "tests" / "pred" / "host_end"


def sub(pat, rep):
    def edit(fn):
        new, n = re.subn(pat, rep, fn, count=1)
        assert n == 1, pat
        return new
    return edit


def RETURN(fn):
    """Return where C exits: the block ends in the return, or inside a loop the call goes and the program runs on."""
    new = re.sub(r"tail call void @exit\(i32 noundef 1\) #\d+\n  unreachable", "ret i32 0", fn, count=1)
    return new if new != fn else sub(r"  tail call void @exit\(i32 noundef 1\) #\d+\n", "")(fn)


# exit where C returns; another status
EXITS = sub(r"(\n  ret i32 %\d+\n)", r"\n  call void @exit(i32 0)\1")
STATUS = sub(r"@exit\(i32 noundef 1\)", "@exit(i32 noundef 7)")
# rule 16's flag gone: fm-rv8's shape, the lowered program runs on and returns where C exits
NO_FLAG = sub(r"  call void @cqrt_abort_i1\(i32 %\d+\)\n", "")
# a rail left live on an exit under a quantum condition
LEAK = sub(r"  call void @cq_template_and_i32_hl_unc\(i32 (%\d+), .*\n  call void @cqrt_free\(i32 \1\)\n", "")


def REAL(fn):
    """A real exit under the quantum condition, the same exit and status as C, with the condition's rails live
    on that path alone: only the samples that exit can report a leak, and they must."""
    fn = sub(r"  call void @cqrt_abort_i1\(i32 %\d+\)\n", "")(fn)
    return sub(r"(  call void @cqrt_xor_i1\(i32 %\d+, i32 (%\d+)\)\n)",
               r"\1  %mq = call i1 @cqrt_measure_i1(i32 \2)\n  br i1 %mq, label %mqe, label %mqc\n\n"
               r"mqe:\n  call void @exit(i32 1)\n  unreachable\n\nmqc:\n")(fn)


# Owner ruling 2026-11-11 Q7 (cq-edr1f): an exit is the ordinary host call only where no event can precede it; owner
# ruling 2026-11-14: on a path inside the lowered code. HOST's classical and LOOP's classical_switch exit before any event
# of their function and no in-module caller calls them, so their exits are real host exits although the module holds
# events (cases 17 to 22); REAL_EXIT is the same in a module with no event.
HOST, LOOP, REAL_EXIT = "noreturn_host_end", "noreturn_classical_loop", "noreturn_real_exit"
CASES = [  # probe, entry, edit, expected reason (None: PASS)
    (LOOP, "classical_switch", None, None),
    (LOOP, "classical_switch_arm", None, None),
    (HOST, "classical", None, None),
    (HOST, "quantum", None, None),
    (HOST, "after_measure", None, None),
    (HOST, "classical_after_arm", None, None),
    (REAL_EXIT, "classical_switch", None, None),
    (REAL_EXIT, "classical", None, None),
    (REAL_EXIT, "classical_switch", RETURN, "a leak"),
    (REAL_EXIT, "classical_switch", EXITS, "returns"),
    (REAL_EXIT, "classical_switch", STATUS, "status 7 and the C program ends with"),
    (REAL_EXIT, "classical", RETURN, "no kept abort flag"),
    (REAL_EXIT, "classical", EXITS, "returns"),
    (REAL_EXIT, "classical", STATUS, "status 7 and the C program ends with"),
    (HOST, "quantum", NO_FLAG, "no kept abort flag"),
    (HOST, "quantum", LEAK, "a leak"),
    (HOST, "quantum", REAL, "a leak"),
    (LOOP, "classical_switch", RETURN, "a leak"),
    (LOOP, "classical_switch", EXITS, "returns"),
    (LOOP, "classical_switch", STATUS, "status 7 and the C program ends with"),
    (HOST, "classical", RETURN, "no kept abort flag"),
    (HOST, "classical", EXITS, "returns"),
    (HOST, "classical", STATUS, "status 7 and the C program ends with"),
]


def mutate(text, entry, edit):
    m = re.search(rf"^define [^\n]*@{entry}\(.*?^\}}\n", text, re.M | re.S)
    out = text[:m.start()] + edit(m.group(0)) + text[m.end():]
    return out + ("declare i1 @cqrt_measure_i1(i32)\n" if edit is REAL and "@cqrt_measure_i1(i32)" not in text else "")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--plugin", required=True)
    ap.add_argument("--opt", required=True)
    ap.add_argument("--only", type=int, nargs="*", help="run only these case numbers")
    a = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    lowered = {}
    for probe in (HOST, LOOP, REAL_EXIT):
        dest = OUT / f"{probe}.lowered.ll"
        subprocess.run([a.opt, f"-load-pass-plugin={a.plugin}", "-passes=cq-lower", "-cq-k-default=4", "-S",
                        str(PROBES / f"{probe}.O1.ll"), "-o", str(dest)], check=True)
        lowered[probe] = dest.read_text()
    failures = 0
    for i, (probe, entry, edit, want) in enumerate(CASES):
        if a.only and i not in a.only:
            continue
        low = OUT / f"{i}_{entry}.lowered.ll"
        low.write_text(mutate(lowered[probe], entry, edit) if edit else lowered[probe])
        r = subprocess.run([sys.executable, "-m", "cqcheck", "user", "--light", "--o1", str(PROBES / f"{probe}.O1.ll"),
                            "--lowered", str(low), "--entry", entry], capture_output=True, text=True, cwd=ROOT / "checker")
        out = r.stdout + r.stderr
        ok = "PASS" in out if want is None else "cqcheck user: FAIL" in out and want in out
        failures += not ok
        print(f"{'ok' if ok else 'FAIL':4} {i} {probe} {entry} want {want or 'PASS'}")
        if not ok:
            print("    " + "\n    ".join(l[:600] for l in out.strip().splitlines()[-4:]))
    print("FAIL" if failures else "ok", f"({failures} failing)")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
