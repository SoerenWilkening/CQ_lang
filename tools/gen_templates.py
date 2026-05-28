#!/usr/bin/env python3
"""tools/gen_templates.py - Phase 3 template-stub generator.

Reads tools/opcode_table.yaml and emits:
  - cq_templates.h          : extern "C" declarations (~680 symbols)
  - cq_templates.c          : printf-trace stub bodies
  - OpcodeTables.cpp        : IR-pass dispatch tables (linear scan)
  - lit/<opcode>/<sym>.ll   : LIT fixture stubs (placeholder for M16)

Each file embeds the YAML SHA-256 in its banner so consumers can detect
drift. --check mode regenerates into a tempdir and diffs byte-for-byte
against the on-disk artifacts.

Naming ("_hl" then "_inv"):
  fwd Q+Q:   cq_template_<op>[_<pred>]_<W>[_<from>_to_<to>]
  fwd Q+C:   ..._hl    inv Q+Q: ..._inv    inv Q+C: ..._hl_inv

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
# Mirrors Phase 2's existing add/fadd stub format exactly.
WIDTH_INFO = {
    "i1":  {"ctype": "bool",    "fmt": "%d",   "cast": "(int)"},
    "i8":  {"ctype": "int8_t",  "fmt": "%lld", "cast": "(long long)"},
    "i16": {"ctype": "int16_t", "fmt": "%lld", "cast": "(long long)"},
    "i32": {"ctype": "int32_t", "fmt": "%lld", "cast": "(long long)"},
    "i64": {"ctype": "int64_t", "fmt": "%lld", "cast": "(long long)"},
    "f32": {"ctype": "float",   "fmt": "%f",   "cast": "(double)"},
    "f64": {"ctype": "double",  "fmt": "%f",   "cast": ""},
}

TARGETS = ("h", "c", "opcodetables", "lit")


# -------------------- symbol enumeration --------------------

def enumerate_all(table):
    """Return lex-sorted list of row dicts, one per emitted symbol.

    Row fields: sym, kind, op, width (or from/to for casts), variant,
    hl_ctype_w (None for arity-1 / Q+Q variants; width-name for _hl variants).
    Compare rows also carry `pred`.
    """
    rows = []
    # Binary: 4 variants per (op, width).
    for op in table["binary_opcodes"]:
        for w in op["widths"]:
            base = f"cq_template_{op['opcode']}_{w}"
            rows.append({"sym": base,             "kind": "binary", "op": op["opcode"], "width": w, "variant": "fwd_qq", "hl_ctype_w": None})
            rows.append({"sym": base + "_hl",     "kind": "binary", "op": op["opcode"], "width": w, "variant": "fwd_hl", "hl_ctype_w": w})
            rows.append({"sym": base + "_inv",    "kind": "binary", "op": op["opcode"], "width": w, "variant": "inv_qq", "hl_ctype_w": None})
            rows.append({"sym": base + "_hl_inv", "kind": "binary", "op": op["opcode"], "width": w, "variant": "inv_hl", "hl_ctype_w": w})
    # Unary: 2 variants per (op, width).
    for op in table["unary_opcodes"]:
        for w in op["widths"]:
            base = f"cq_template_{op['opcode']}_{w}"
            rows.append({"sym": base,          "kind": "unary", "op": op["opcode"], "width": w, "variant": "fwd", "hl_ctype_w": None})
            rows.append({"sym": base + "_inv", "kind": "unary", "op": op["opcode"], "width": w, "variant": "inv", "hl_ctype_w": None})
    # Compare: 4 variants per (family, pred, width).
    for op in table["compare_opcodes"]:
        for pred in table["predicates"][op["predicate_set"]]:
            for w in op["widths"]:
                base = f"cq_template_{op['opcode']}_{pred}_{w}"
                rows.append({"sym": base,             "kind": "compare", "op": op["opcode"], "width": w, "variant": "fwd_qq", "hl_ctype_w": None, "pred": pred})
                rows.append({"sym": base + "_hl",     "kind": "compare", "op": op["opcode"], "width": w, "variant": "fwd_hl", "hl_ctype_w": w,    "pred": pred})
                rows.append({"sym": base + "_inv",    "kind": "compare", "op": op["opcode"], "width": w, "variant": "inv_qq", "hl_ctype_w": None, "pred": pred})
                rows.append({"sym": base + "_hl_inv", "kind": "compare", "op": op["opcode"], "width": w, "variant": "inv_hl", "hl_ctype_w": w,    "pred": pred})
    # Cast: 2 variants per (kind, from, to). No Q+C - casts are arity-1 at IR level.
    for op in table["cast_opcodes"]:
        for pair in op["pairs"]:
            base = f"cq_template_{op['opcode']}_{pair['from']}_to_{pair['to']}"
            rows.append({"sym": base,          "kind": "cast", "op": op["opcode"], "from": pair["from"], "to": pair["to"], "variant": "fwd"})
            rows.append({"sym": base + "_inv", "kind": "cast", "op": op["opcode"], "from": pair["from"], "to": pair["to"], "variant": "inv"})
    rows.sort(key=lambda r: r["sym"])
    return rows


# -------------------- signature + body helpers --------------------

def signature(row):
    """Return the C declaration (no trailing ';')."""
    sym = row["sym"]
    if row["kind"] in ("cast", "unary"):
        return f"int32_t {sym}(int32_t a_handle)"
    if row["hl_ctype_w"] is None:  # Q+Q binary or compare
        return f"int32_t {sym}(int32_t a_handle, int32_t b_handle)"
    ctype = WIDTH_INFO[row["hl_ctype_w"]]["ctype"]
    return f"int32_t {sym}(int32_t a_handle, {ctype} b_classical)"


def stub_body(row):
    """Return the C body lines (without the signature braces)."""
    sym = row["sym"]
    if row["kind"] in ("cast", "unary"):
        return (
            "    int32_t h = cqrt_alloc_handle();\n"
            f"    printf(\"{sym}(h%d) -> h%d\\n\", a_handle, h);\n"
            "    fflush(stdout);\n    return h;\n"
        )
    if row["hl_ctype_w"] is None:  # Q+Q binary or compare
        return (
            "    int32_t h = cqrt_alloc_handle();\n"
            f"    printf(\"{sym}(h%d, h%d) -> h%d\\n\", a_handle, b_handle, h);\n"
            "    fflush(stdout);\n    return h;\n"
        )
    info = WIDTH_INFO[row["hl_ctype_w"]]
    cast_expr = f"{info['cast']}b_classical" if info["cast"] else "b_classical"
    return (
        "    int32_t h = cqrt_alloc_handle();\n"
        f"    printf(\"{sym}(h%d, {info['fmt']}) -> h%d\\n\", a_handle, {cast_expr}, h);\n"
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


def emit_opcode_tables(rows, table, yaml_sha):
    """Emit dispatch tables consumed by the IR pass (M10-M14).

    Schema: one std::array per opcode-family, rows of {op, width, sym}.
    Linear-scan lookup is fine at table size <= 70.
    """
    parts = [banner(yaml_sha),
             "// OpcodeTables.cpp - dispatch tables for IR-pass lowering (M11-M14).\n\n",
             "#include <array>\n#include <string_view>\n\nnamespace cq {\n\n",
             "struct OpcodeRow { std::string_view op; std::string_view width; "
             "std::string_view sym; };\n\n"]

    def section(name, comment, items):
        parts.append(f"// {comment}\n")
        parts.append(f"inline constexpr std::array<OpcodeRow, {len(items)}> {name} = {{{{\n")
        for op, w, sym in items:
            parts.append(f"    {{\"{op}\", \"{w}\", \"{sym}\"}},\n")
        parts.append("}};\n\n")

    bin_items = [(op["opcode"], w, f"cq_template_{op['opcode']}_{w}")
                 for op in table["binary_opcodes"] for w in op["widths"]]
    section("binaryOpcodeTable", "binary arith + bitwise (Q+Q forward stems)", bin_items)

    una_items = [(op["opcode"], w, f"cq_template_{op['opcode']}_{w}")
                 for op in table["unary_opcodes"] for w in op["widths"]]
    section("unaryOpcodeTable", "unary (fneg only, Q+Q forward stems)", una_items)

    cmp_items = [(f"{op['opcode']}_{pred}", w,
                  f"cq_template_{op['opcode']}_{pred}_{w}")
                 for op in table["compare_opcodes"]
                 for pred in table["predicates"][op["predicate_set"]]
                 for w in op["widths"]]
    section("compareOpcodeTable", "icmp + fcmp (Q+Q forward stems, per-predicate)", cmp_items)

    cast_items = [(op["opcode"], f"{pair['from']}_to_{pair['to']}",
                   f"cq_template_{op['opcode']}_{pair['from']}_to_{pair['to']}")
                  for op in table["cast_opcodes"] for pair in op["pairs"]]
    section("castOpcodeTable", "cast opcodes (forward stems, per from/to pair)", cast_items)

    parts.append("}  // namespace cq\n")
    return "".join(parts)


def emit_lit_fixtures(rows, yaml_sha):
    """Emit a placeholder LIT fixture per forward symbol; real CHECKs land in M16.

    Returns dict {relative-path: content}.
    """
    fixtures = {}
    for r in rows:
        if "inv" in r["variant"]:
            continue
        rel = f"{r['op']}/{r['sym']}.ll"
        fixtures[rel] = (
            f"; AUTOGENERATED - do not edit. yaml-sha256: {yaml_sha}\n"
            f"; Source: tools/opcode_table.yaml; emitter: tools/gen_templates.py\n"
            f"; Placeholder - real CHECK lines land later.\n"
            f"; RUN: true\n"
            f"; Target symbol: {r['sym']}\n"
        )
    return fixtures


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
    if "opcodetables" in targets:
        (out_dir / "OpcodeTables.cpp").write_text(emit_opcode_tables(rows, table, sha))
    if "lit" in targets:
        lit_dir = out_dir / "lit"
        for rel, content in emit_lit_fixtures(rows, sha).items():
            fp = lit_dir / rel
            fp.parent.mkdir(parents=True, exist_ok=True)
            fp.write_text(content)


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
    p = argparse.ArgumentParser(description="Phase 3 template generator")
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
