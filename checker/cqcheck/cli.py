"""Stub (cq-w0-scaffold): the frozen cqcheck CLI of cq-arch; every command fails with
"cq: unimplemented: <module>: <command>". Ownership passes to cq-w0-chk-report."""
import argparse
import sys


def _unimplemented(what: str) -> int:
    print(f"cq: unimplemented: {what}", file=sys.stderr)
    return 1


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="cqcheck")
    sub = p.add_subparsers(dest="cmd", required=True)
    run = sub.add_parser("run")
    run.add_argument("examples", nargs="*")
    run.add_argument("--all", action="store_true")
    run.add_argument("--ours")
    run.add_argument("--oracle", choices=["ref", "c", "both"], default="both")
    run.add_argument("--json")
    sub.add_parser("selftest")
    sub.add_parser("baseline")
    sub.add_parser("progress")
    user = sub.add_parser("user")
    user.add_argument("--o1", required=True)
    user.add_argument("--lowered", required=True)
    user.add_argument("--entry", required=True)
    user.add_argument("--samples", type=int)
    a = p.parse_args(argv)
    owner = {"run": "chk-core: run", "selftest": "chk-selftest: selftest", "baseline": "chk-selftest: baseline",
             "progress": "chk-report: progress", "user": "usercheck: user"}[a.cmd]
    return _unimplemented(owner)
