#!/usr/bin/env python3
"""tools/gen_templates.py - template-stub generator.

Reads tools/opcode_table.yaml and emits:
  - cq_templates.h          : extern "C" declarations (1562 symbols)
  - cq_templates.c          : printf-trace stub bodies

Each file embeds the YAML SHA-256 in its banner so consumers can detect
drift. --check mode regenerates into a tempdir and diffs byte-for-byte
against the on-disk artifacts. C ABI emission (signature / stub_body) is
split into tools/abi_codegen.py (DD-5).

Naming ("_hl"/"_lh" shape, then "_inv" direction; "_unc" is in-place void):
  fwd Q+Q:     cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>]
  fwd Q+C rhs: ..._hl    fwd C+Q lhs: ..._lh
  inv Q+Q:     ..._inv   inv Q+C rhs: ..._hl_inv   inv C+Q lhs: ..._lh_inv
  unc Q+Q:     ..._unc   unc Q+C rhs: ..._hl_unc  unc C+Q lhs: ..._lh_unc
  unc arity-1: ..._unc   (void in-place; out is arg 0 — Phase 5, §2.3/DD-3)

Trace format mirrors runtime/cq_templates.c.
"""
from __future__ import annotations

import argparse
import filecmp
import hashlib
import pathlib
import sys
import tempfile

import yaml

# C ABI emission (signature / stub_body, incl. the void `_unc` family) lives
# in abi_codegen (DD-5 split). This module owns YAML load / enumeration /
# write / --check / CLI; abi_codegen owns the per-symbol C surface.
from abi_codegen import signature, stub_body

TARGETS = ("h", "c")

# Variant token -> (symbol suffix, operand shape). Single source of truth for
# the variant grid; enumerate_all/signature/stub_body all key off `shape`.
#   qq  : both operands quantum handles            -> sym(h, h)
#   hl  : handle on LHS, classical scalar on RHS    -> sym(h, classical)
#   lh  : classical scalar on LHS, handle on RHS    -> sym(classical, h)
#   a1  : arity-1 (unary / cast)                    -> sym(h)
# The `_inv` direction is folded into the suffix (modifier-then-direction).
#
# Controlled axis (Phase 4, PRD §2.8): `controlled_*` tokens mirror the
# fwd/inv shape grid for binary ops only. `_controlled` follows the shape
# suffix, `_inv` stays last (`…[_hl|_lh]_controlled[_inv]`). Every controlled
# symbol prepends an `int32_t ctrl_flag` as argument 0 (§1.2); this is keyed
# off the shape carrying a `c` prefix below, consumed by signature/stub_body.
#
# Uncompute axis (Phase 5, PRD §2.3 / DD-3): `unc[_qq|_hl|_lh]` tokens add the
# VOID in-place uncompute family `cq_template_<op>_<W>[_hl|_lh]_unc(out, src…)`.
# QQ carries NO shape token — the `_unc` suffix attaches to the BARE base symbol,
# exactly as `fwd_qq`/`inv_qq`/`controlled_qq` are bare (the forward QQ form is
# `cq_template_<op>_<W>`, not `..._qq`; the uncompute twin must match it so the
# emitter's bare-QQ name — TemplateName shapeSuffix(QQ)="" — links). Only `_hl`/
# `_lh` are spelled, then `_unc` last. These carry a `u` shape prefix, consumed
# by signature/stub_body to prepend `int32_t out_handle` as argument 0 and return
# void. Arity-1 (unary/cast) uses the bare `unc` token -> `_unc` suffix, shape `ua1`.
CONTROLLED_SHAPES = {"cqq", "chl", "clh"}
VARIANT_INFO = {
    "fwd_qq": ("",        "qq"),
    "fwd_hl": ("_hl",     "hl"),
    "fwd_lh": ("_lh",     "lh"),
    "inv_qq": ("_inv",    "qq"),
    "inv_hl": ("_hl_inv", "hl"),
    "inv_lh": ("_lh_inv", "lh"),
    "fwd":    ("",        "a1"),
    "inv":    ("_inv",    "a1"),
    "controlled_qq":     ("_controlled",        "cqq"),
    "controlled_hl":     ("_hl_controlled",     "chl"),
    "controlled_lh":     ("_lh_controlled",     "clh"),
    "controlled_inv_qq": ("_controlled_inv",    "cqq"),
    "controlled_inv_hl": ("_hl_controlled_inv", "chl"),
    "controlled_inv_lh": ("_lh_controlled_inv", "clh"),
    "unc_qq": ("_unc",    "uqq"),
    "unc_hl": ("_hl_unc", "uhl"),
    "unc_lh": ("_lh_unc", "ulh"),
    "unc":    ("_unc",    "ua1"),
}


# -------------------- symbol enumeration --------------------

def enumerate_all(table):
    """Return lex-sorted list of row dicts, one per emitted symbol.

    Variant-driven: each opcode's `variants` list is expanded through
    VARIANT_INFO into (suffix, shape) pairs, so the symbol grid follows the
    YAML directly. Row fields: sym, kind, op, shape, variant, width (or
    from/to for casts), classical_w (width-name carrying the classical
    operand's C type for hl/lh shapes; None otherwise). Compare rows also
    carry `pred`.
    """
    rows = []

    def emit(base, kind, variants, extra):
        for v in variants:
            suffix, shape = VARIANT_INFO[v]
            row = {"sym": base + suffix, "kind": kind, "shape": shape, "variant": v}
            row.update(extra)
            # hl/lh (and their controlled twins chl/clh, and the void
            # uncompute twins uhl/ulh) carry a classical operand whose C type
            # comes from the symbol's width.
            row["classical_w"] = (extra.get("width")
                                  if shape in ("hl", "lh", "chl", "clh", "uhl", "ulh")
                                  else None)
            rows.append(row)

    # Binary: variant grid per (op, width).
    for op in table["binary_opcodes"]:
        for w in op["widths"]:
            emit(f"cq_template_{op['opcode']}_{w}", "binary", op["variants"],
                 {"op": op["opcode"], "width": w})
    # Unary: variant grid per (op, width).
    for op in table["unary_opcodes"]:
        for w in op["widths"]:
            emit(f"cq_template_{op['opcode']}_{w}", "unary", op["variants"],
                 {"op": op["opcode"], "width": w})
    # Compare: variant grid per (family, pred, width).
    for op in table["compare_opcodes"]:
        for pred in table["predicates"][op["predicate_set"]]:
            for w in op["widths"]:
                emit(f"cq_template_{op['opcode']}_{pred}_{w}", "compare", op["variants"],
                     {"op": op["opcode"], "width": w, "pred": pred})
    # Cast: variant grid per (kind, from, to). Casts are arity-1 at IR level.
    for op in table["cast_opcodes"]:
        for pair in op["pairs"]:
            emit(f"cq_template_{op['opcode']}_{pair['from']}_to_{pair['to']}", "cast",
                 op["variants"], {"op": op["opcode"], "from": pair["from"], "to": pair["to"]})
    rows.sort(key=lambda r: r["sym"])
    return rows


# -------------------- emitters --------------------

def banner(yaml_sha):
    return (
        f"/* AUTOGENERATED - do not edit. yaml-sha256: {yaml_sha} */\n"
        f"/* Source: tools/opcode_table.yaml; emitter: tools/gen_templates.py */\n"
    )


def emit_header(rows, yaml_sha):
    parts = [banner(yaml_sha),
             "#ifndef CQ_TEMPLATES_H_\n#define CQ_TEMPLATES_H_\n\n",
             "#include <stdbool.h>\n#include <stdint.h>\n\n",
             "#ifdef __cplusplus\nextern \"C\" {\n#endif\n\n"]
    parts.extend(signature(r) + ";\n" for r in rows)
    parts.append("\n#ifdef __cplusplus\n}\n#endif\n\n")
    parts.append("#endif  /* CQ_TEMPLATES_H_ */\n")
    return "".join(parts)


def emit_source(rows, yaml_sha):
    parts = [banner(yaml_sha),
             "#include \"cq_templates.h\"\n",
             "#include \"cq_runtime.h\"\n",
             "#include <stdio.h>\n\n"]
    for r in rows:
        parts.append(signature(r) + " {\n")
        parts.append(stub_body(r))
        parts.append("}\n\n")
    return "".join(parts)


# -------------------- top-level glue --------------------

def load_yaml(path):
    with open(path, "rb") as f:
        raw = f.read()
    return raw, yaml.safe_load(raw)


def write_artifacts(out_dir, yaml_path, targets):
    raw, table = load_yaml(yaml_path)
    sha = hashlib.sha256(raw).hexdigest()
    rows = enumerate_all(table)
    out_dir = pathlib.Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    if "h" in targets:
        (out_dir / "cq_templates.h").write_text(emit_header(rows, sha))
    if "c" in targets:
        (out_dir / "cq_templates.c").write_text(emit_source(rows, sha))


def check_mode(out_dir, yaml_path, targets):
    """Regenerate into a tempdir, diff against out_dir. 0 = clean, 1 = drift."""
    out_dir = pathlib.Path(out_dir)
    with tempfile.TemporaryDirectory() as td:
        write_artifacts(td, yaml_path, targets)
        td_path = pathlib.Path(td)
        drift = []
        for fresh in sorted(td_path.rglob("*")):
            if fresh.is_dir():
                continue
            rel = fresh.relative_to(td_path)
            existing = out_dir / rel
            if not existing.exists() or not filecmp.cmp(str(fresh), str(existing), shallow=False):
                drift.append(str(rel))
        if drift:
            print("DRIFT detected in:")
            for d in drift:
                print(f"  {d}")
            return 1
    return 0


def main():
    p = argparse.ArgumentParser(description="template generator")
    p.add_argument("--yaml", default=str(pathlib.Path(__file__).parent / "opcode_table.yaml"))
    p.add_argument("--output-dir", required=True)
    p.add_argument("--check", action="store_true",
                   help="diff against on-disk artifacts; nonzero exit on drift")
    p.add_argument("--targets", default=",".join(TARGETS),
                   help="comma-separated subset of " + ",".join(TARGETS))
    args = p.parse_args()
    targets = tuple(t.strip() for t in args.targets.split(",") if t.strip())
    if args.check:
        sys.exit(check_mode(args.output_dir, args.yaml, targets))
    write_artifacts(args.output_dir, args.yaml, targets)


if __name__ == "__main__":
    main()
