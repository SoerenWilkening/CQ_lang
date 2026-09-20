#!/usr/bin/env python3
"""Describe and validate CQ static backend implementations.

A backend replaces both CQ trace archives.  It must define every cqrt_* symbol
the lowering pass can emit and every generated cq_template_* symbol.  The two
declared H helpers are excluded because the pass cannot emit them.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


SCHEMA = 1
UNEMITTED_CORE = {"cqrt_h", "cqrt_h_controlled"}
TABLES = ("opcode_table.yaml", "intrinsic_table.yaml", "libm_table.yaml")
HEADERS = (
    "cq_runtime.h",
    "cq_templates.h",
    "cq_intrinsic_templates.h",
    "cq_libm_templates.h",
)


def repository_root() -> Path:
    return Path(__file__).resolve().parent.parent


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def declarations(header: Path, prefix: str) -> dict[str, str]:
    text = strip_comments(header.read_text(encoding="utf-8"))
    found: dict[str, str] = {}
    pattern = re.compile(
        rf"([^;{{}}]*?\b({re.escape(prefix)}[A-Za-z0-9_]+)\s*\([^;{{}}]*\)\s*;)",
        flags=re.S,
    )
    for match in pattern.finditer(text):
        declaration = " ".join(match.group(1).split())
        found[match.group(2)] = declaration
    return found


def contract(root: Path) -> dict[str, object]:
    runtime = root / "runtime"
    tools = root / "tools"
    if not runtime.is_dir():
        runtime = root / "include/cq/backend"
        tools = root / "share/cq/abi"
    if not runtime.is_dir() or not tools.is_dir():
        raise RuntimeError(
            f"{root} is neither a CQ source tree nor an installed CQ prefix"
        )
    core = declarations(runtime / HEADERS[0], "cqrt_")
    for symbol in UNEMITTED_CORE:
        core.pop(symbol, None)

    templates: dict[str, str] = {}
    for name in HEADERS[1:]:
        overlap = templates.keys() & declarations(runtime / name, "cq_template_").keys()
        if overlap:
            raise RuntimeError(f"duplicate template declarations: {sorted(overlap)[:3]}")
        templates.update(declarations(runtime / name, "cq_template_"))

    prototypes = [core[name] for name in sorted(core)]
    prototypes.extend(templates[name] for name in sorted(templates))
    table_hashes = {
        name: hashlib.sha256((tools / name).read_bytes()).hexdigest()
        for name in TABLES
    }
    identity_input = json.dumps(
        {"prototypes": prototypes, "table_sha256": table_hashes},
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    abi_id = "sha256:" + hashlib.sha256(identity_input).hexdigest()
    return {
        "schema": SCHEMA,
        "abi_id": abi_id,
        "core_symbol_count": len(core),
        "template_symbol_count": len(templates),
        "declared_but_unemitted": sorted(UNEMITTED_CORE),
        "table_sha256": table_hashes,
        "required_symbols": sorted((*core.keys(), *templates.keys())),
    }


def nm_defined(archive: Path) -> set[str]:
    try:
        proc = subprocess.run(
            ["nm", "-g", str(archive)],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except FileNotFoundError as exc:
        raise RuntimeError("nm is required to validate a backend archive") from exc
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(f"nm failed for {archive}: {exc.stderr.strip()}") from exc

    result: set[str] = set()
    for line in proc.stdout.splitlines():
        fields = line.split()
        if len(fields) < 2:
            continue
        kind, name = fields[-2], fields[-1]
        if kind.upper() not in {"T", "W", "I"}:
            continue
        if name.startswith("_cqrt_") or name.startswith("_cq_template_"):
            name = name[1:]
        if name.startswith("cqrt_") or name.startswith("cq_template_"):
            result.add(name)
    return result


def read_manifest(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise RuntimeError(f"cannot read backend manifest {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise RuntimeError(f"backend manifest {path} is not a JSON object")
    return value


def write_json(value: dict[str, object], output: str | None) -> None:
    rendered = json.dumps(value, indent=2, sort_keys=True) + "\n"
    if output:
        Path(output).write_text(rendered, encoding="utf-8")
    else:
        try:
            sys.stdout.write(rendered)
        except BrokenPipeError:
            pass


def command_describe(args: argparse.Namespace) -> int:
    write_json(contract(args.root.resolve()), args.output)
    return 0


def command_provider_manifest(args: argparse.Namespace) -> int:
    current = contract(args.root.resolve())
    manifest = {
        "schema": SCHEMA,
        "backend": args.name,
        "cq_backend_abi": current["abi_id"],
    }
    write_json(manifest, args.output)
    return 0


def command_check(args: argparse.Namespace) -> int:
    current = contract(args.root.resolve())
    if args.manifest:
        manifest = read_manifest(args.manifest.resolve())
        if manifest.get("schema") != SCHEMA:
            raise RuntimeError(
                f"backend manifest schema is {manifest.get('schema')!r}; expected {SCHEMA}"
            )
        if manifest.get("cq_backend_abi") != current["abi_id"]:
            raise RuntimeError(
                "backend ABI mismatch: manifest names "
                f"{manifest.get('cq_backend_abi')!r}, CQ requires {current['abi_id']}"
            )

    defined: set[str] = set()
    for archive in args.archive:
        if not archive.is_file():
            raise RuntimeError(f"backend archive does not exist: {archive}")
        defined.update(nm_defined(archive.resolve()))
    required = set(current["required_symbols"])
    missing = sorted(required - defined)
    if missing:
        preview = "\n  ".join(missing[:25])
        suffix = f"\n  ... and {len(missing) - 25} more" if len(missing) > 25 else ""
        raise RuntimeError(
            f"backend is missing {len(missing)} of {len(required)} required symbols:\n"
            f"  {preview}{suffix}"
        )
    backend = " + ".join(str(path) for path in args.archive)
    print(
        f"backend OK: {backend}: {len(required)} required symbols, "
        f"ABI {current['abi_id']}"
    )
    return 0


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument(
        "--root", type=Path, default=repository_root(), help="CQ_lang source root"
    )
    sub = result.add_subparsers(dest="command", required=True)

    describe = sub.add_parser("describe", help="print CQ's backend ABI descriptor")
    describe.add_argument("--output")
    describe.set_defaults(func=command_describe)

    provider = sub.add_parser(
        "provider-manifest", help="write a backend provider manifest for this ABI"
    )
    provider.add_argument("--name", required=True)
    provider.add_argument("--output")
    provider.set_defaults(func=command_provider_manifest)

    check = sub.add_parser("check", help="validate one backend made of static archives")
    check.add_argument("--archive", type=Path, action="append", required=True)
    check.add_argument("--manifest", type=Path)
    check.set_defaults(func=command_check)
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        return args.func(args)
    except RuntimeError as exc:
        print(f"backend contract: ERROR: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
