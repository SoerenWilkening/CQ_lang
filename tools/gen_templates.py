#!/usr/bin/env python3
"""tools/gen_templates.py - template-stub generator.

Reads tools/opcode_table.yaml and emits:
  - cq_templates.h          : extern "C" declarations (~780 symbols)
  - cq_templates.c          : printf-trace stub bodies

Each file embeds the YAML SHA-256 in its banner so consumers can detect
drift. --check mode regenerates into a tempdir and diffs byte-for-byte
against the on-disk artifacts.

Naming ("_hl"/"_lh" shape, then "_inv" direction):
  fwd Q+Q:     cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>]
  fwd Q+C rhs: ..._hl    fwd C+Q lhs: ..._lh
  inv Q+Q:     ..._inv   inv Q+C rhs: ..._hl_inv   inv C+Q lhs: ..._lh_inv

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

# Per-width C type + printf format + (optional) cast for the Q+C trace body.
# Mirrors the existing add/fadd stub format exactly.
WIDTH_INFO = {
    "i1":  {"ctype": "bool",    "fmt": "%d",   "cast": "(int)"},
    "i8":  {"ctype": "int8_t",  "fmt": "%lld", "cast": "(long long)"},
    "i16": {"ctype": "int16_t", "fmt": "%lld", "cast": "(long long)"},
    "i32": {"ctype": "int32_t", "fmt": "%lld", "cast": "(long long)"},
    "i64": {"ctype": "int64_t", "fmt": "%lld", "cast": "(long long)"},
    "f32": {"ctype": "float",   "fmt": "%f",   "cast": "(double)"},
    "f64": {"ctype": "double",  "fmt": "%f",   "cast": ""},
}

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
            # hl/lh (and their controlled twins chl/clh) carry a classical
            # operand whose C type comes from the symbol's width.
            row["classical_w"] = extra.get("width") if shape in ("hl", "lh", "chl", "clh") else None
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


# -------------------- signature + body helpers --------------------

def signature(row):
    """Return the C declaration (no trailing ';').

    Controlled shapes (cqq/chl/clh) mirror their uncontrolled twins
    (qq/hl/lh) but prepend `int32_t ctrl_flag` as parameter 0 — the single
    control wire (PRD §1.2). The control flag is always argument 0.
    """
    sym = row["sym"]
    shape = row["shape"]
    ctrl = "int32_t ctrl_flag, " if shape in CONTROLLED_SHAPES else ""
    if shape == "a1":  # arity-1: cast / unary (never controlled)
        return f"int32_t {sym}(int32_t a_handle)"
    if shape in ("qq", "cqq"):  # Q+Q binary or compare
        return f"int32_t {sym}({ctrl}int32_t a_handle, int32_t b_handle)"
    ctype = WIDTH_INFO[row["classical_w"]]["ctype"]
    if shape in ("hl", "chl"):  # handle on LHS, classical scalar on RHS
        return f"int32_t {sym}({ctrl}int32_t a_handle, {ctype} b_classical)"
    # shape lh/clh: classical scalar on LHS, handle on RHS
    return f"int32_t {sym}({ctrl}{ctype} a_classical, int32_t b_handle)"


def stub_body(row):
    """Return the C body lines (without the signature braces).

    Controlled shapes (cqq/chl/clh) prepend the control flag to the trace as
    a leading `h%d` (the flag is an i32 handle, PRD §1.2); the rest of the
    trace mirrors the uncontrolled twin exactly.
    """
    sym = row["sym"]
    shape = row["shape"]
    ctrl_fmt = "h%d, " if shape in CONTROLLED_SHAPES else ""
    ctrl_arg = "ctrl_flag, " if shape in CONTROLLED_SHAPES else ""
    if shape == "a1":  # arity-1: cast / unary (never controlled)
        return (
            "    int32_t h = cqrt_alloc_handle();\n"
            f"    printf(\"{sym}(h%d) -> h%d\\n\", a_handle, h);\n"
            "    fflush(stdout);\n    return h;\n"
        )
    if shape in ("qq", "cqq"):  # Q+Q binary or compare
        return (
            "    int32_t h = cqrt_alloc_handle();\n"
            f"    printf(\"{sym}({ctrl_fmt}h%d, h%d) -> h%d\\n\", {ctrl_arg}a_handle, b_handle, h);\n"
            "    fflush(stdout);\n    return h;\n"
        )
    info = WIDTH_INFO[row["classical_w"]]
    if shape in ("hl", "chl"):  # handle on LHS, classical scalar on RHS
        cast_expr = f"{info['cast']}b_classical" if info["cast"] else "b_classical"
        return (
            "    int32_t h = cqrt_alloc_handle();\n"
            f"    printf(\"{sym}({ctrl_fmt}h%d, {info['fmt']}) -> h%d\\n\", {ctrl_arg}a_handle, {cast_expr}, h);\n"
            "    fflush(stdout);\n    return h;\n"
        )
    # shape lh/clh: classical scalar on LHS, handle on RHS; trace order classical, handle.
    cast_expr = f"{info['cast']}a_classical" if info["cast"] else "a_classical"
    return (
        "    int32_t h = cqrt_alloc_handle();\n"
        f"    printf(\"{sym}({ctrl_fmt}{info['fmt']}, h%d) -> h%d\\n\", {ctrl_arg}{cast_expr}, b_handle, h);\n"
        "    fflush(stdout);\n    return h;\n"
    )


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
