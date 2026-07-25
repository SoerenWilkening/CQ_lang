#!/usr/bin/env python3
"""tools/abi_codegen.py - C ABI emission for the template generator.

Split out of tools/gen_templates.py (DD-5: the generator crossed the
300-LOC hand-written budget once the void `_unc` family landed). This
module owns the per-symbol C surface - `signature()` (the extern decl)
and `stub_body()` (the printf-trace body), keyed off the row `shape`.
gen_templates.py keeps YAML load / enumeration / file write / `--check`.

Shapes (set by gen_templates.enumerate_all from VARIANT_INFO):
  a1            arity-1 unary / cast              sym(h)              -> i32
  qq            two quantum handles               sym(h, h)           -> i32
  hl / lh       handle+literal / literal+handle   sym(h, W) / (W, h)  -> i32
  cqq/chl/clh   controlled twins (flag is arg 0)  sym(flag, ...)      -> i32
  uqq/uhl/ulh   void in-place uncompute (binary)  sym(out, ...)       -> void
  ua1           void in-place uncompute (arity-1) sym(out, h)         -> void
  qqq/qql/      ternary fma a*b+c (wd2p): the      sym(h,h,h)/(h,h,W)/
   qlq/qll       product's first slot is always a   (h,W,h)/(h,W,W)    -> i32
                a handle (canonicalized); the addend is positional.
  uqqq/uqql/    void in-place ternary uncompute   sym(out, a,b,c)     -> void
   uqlq/uqll

`_unc` bodies are trace-only stubs; real zeroing is Phase 8+ bodies.
The `_unc` family (Phase 5, PRD §2.3 / DD-3) is VOID and in-place: `out`
is prepended as argument 0, the forward operands follow in their ORIGINAL
order, and the stub only traces - it ZEROES the out rail by recomputing f
from the still-live sources (Bennett uncompute), so it mints no handle and
returns nothing. Reusing the fresh-minting `_inv` family for uncompute
would free a dirty rail (a hidden measurement, Rule 6/8); `_unc` does not.
"""
from __future__ import annotations

# Per-width C type + printf format + (optional) cast for the Q+C trace body.
# Mirrors the existing add/fadd stub format exactly.
WIDTH_INFO = {
    "i1":  {"ctype": "bool",    "fmt": "%d",   "cast": "(int)"},
    "i8":  {"ctype": "int8_t",  "fmt": "%lld", "cast": "(long long)"},
    "i16": {"ctype": "int16_t", "fmt": "%lld", "cast": "(long long)"},
    "i32": {"ctype": "int32_t", "fmt": "%lld", "cast": "(long long)"},
    "i64": {"ctype": "int64_t", "fmt": "%lld", "cast": "(long long)"},
    # i128 (n0ui Tier-1): __int128 is a valid C type but printf has NO 128-bit
    # specifier, so the trace-only body prints the classical operand via the same
    # (long long)/%lld path as the other int widths. A literal that does not fit in
    # 64 bits is TRUNCATED in the trace label (deterministic; the trace is a gate-
    # sequence contract, not a value simulation). Tier-1 literals (shift amounts,
    # small masks) fit; a genuine >64-bit literal prints its low 64 bits.
    "i128": {"ctype": "__int128", "fmt": "%lld", "cast": "(long long)"},
    # i80 (bd 3c6m.51): the x86_fp80 bit-pattern extraction width. Like i128 it
    # rides __int128 (i80 is not a C type) and prints via the (long long)/%lld path
    # — printf has no 80-bit specifier. Every shipped i80 literal is a mask or a
    # shift amount that fits in 64 bits (fdiml: `and i80 %h, 0x7fff..`=2^63-1,
    # `lshr i80 %bc, 64`; the Inc-3 RMW packs: field [64,80) keep-mask = 2^64-1,
    # `shl i80 .., 64`), so every shipped trace label is faithful; a >64-bit
    # literal would print its low 64 bits (deterministic gate-sequence contract,
    # not a value simulation — same as i128). NOTE (Inc 3): a LIVE field-insert
    # at a sub-64 offset would emit an and-clear keep-mask above 2^64 (e.g.
    # field [0,64) keeps 0xFFFF<<64) and print truncated — no shipped cell does
    # (fdiml's offset-0 store-back is DEAD and elided; scalbnl/copysignl insert
    # at offset 8 only). Revisit the label format before landing such a cell.
    #   ⚠ THAT CELL HAS NOW LANDED (bd `3c6m.58`, 2026-07-25) — the note above is
    #   STALE and the "every shipped i80 literal fits in 64 bits" argument no
    #   longer holds. The verify-first sweep's SET_LDOUBLE_WORDS/IEEEl2bits
    #   field-insert cells emit exactly the predicted >2^64 keep-mask: nextafterl,
    #   modfl, lroundl, llroundl, frexpl (1 each) and sinhl (2). Example —
    #   slice_libm_real_nextafterl golden line 1333 prints
    #   `cq_template_and_i80_hl(h520, 4294967295)` for the true operand
    #   i80 0xFFFF_00000000_FFFFFFFF, so a miscompile of ANY bit above 63 of that
    #   mask is INVISIBLE to the Rule-2 golden diff. The f80 `%Lf` path has the
    #   same defect in the fp domain (0x1p-128 renders as `0.000000`,
    #   indistinguishable from +0.0 — expm1l golden line 34).
    #   NOT fixed here on purpose: changing the label format regenerates the whole
    #   cq_templates surface (Rule 15 + SHA-256 drift check) and re-blesses EVERY
    #   committed ld80 golden — a deliberate baseline regeneration, never a reflex
    #   (Rule 12). Tracked as bd `ni15` with a proposed hex/two-word (i80/i128) and
    #   round-trip-exact `%La`/`%.21Lg` (f80) label format. The shipped goldens are
    #   known-good regardless: the 3c6m.58 audit IR-verified each constant and
    #   replayed the lowered IR against the vendored openlibm source over 36 edge
    #   inputs + 200k random 80-bit patterns with 0 mismatches.
    "i80": {"ctype": "__int128", "fmt": "%lld", "cast": "(long long)"},
    # _Float16: the explicit (double) cast is MANDATORY — a bare _Float16 passed
    # to printf("%f") trips -Wdouble-promotion / a format-arg type mismatch under
    # -Werror. f16 is fp-domain; it has a runtime template surface (fadd_f16 etc.)
    # but, like all fp widths, NO cqrt_copy_f16 (copyFn null-guards on isIntegerTy
    # — the f16-angle-vs-data fence; see WidthDispatch.cpp).
    "f16": {"ctype": "_Float16", "fmt": "%f",   "cast": "(double)"},
    "f32": {"ctype": "float",   "fmt": "%f",   "cast": "(double)"},
    "f64": {"ctype": "double",  "fmt": "%f",   "cast": ""},
    # f80 (bd 3c6m.4): the long-double width on x86-64, where `long double` IS
    # x86_fp80. c_type `long double`, printed with the `%Lf` specifier (no cast;
    # %Lf takes a bare long double). Cast templates are handle-only (i32→i32), so
    # `long double` appears only in _hl/_lh classical-operand slots. f128 (IEEE
    # quad, == long double on AArch64) is NOT shipped here: `long double` == fp80
    # on x86-64, so an fp128 c_type of `long double` would be an fp128-into-fp80
    # ABI miscompile — a tainted fp128 declines instead (deferred to AArch64).
    "f80":  {"ctype": "long double", "fmt": "%Lf", "cast": ""},
}

# Controlled shapes prepend an i32 control flag as parameter 0 (PRD §1.2).
CONTROLLED_SHAPES = {"cqq", "chl", "clh"}
# Void in-place uncompute shapes prepend an i32 `out` rail as parameter 0
# and return void (PRD §2.3 / DD-3). The ternary fma twins (uqqq/uqql/uqlq/uqll)
# follow the same out-first convention (wd2p).
UNC_SHAPES = {"uqq", "uhl", "ulh", "ua1", "uqqq", "uqql", "uqlq", "uqll"}


# -------------------- signature + body --------------------

def signature(row):
    """Return the C declaration (no trailing ';').

    Controlled shapes (cqq/chl/clh) mirror their uncontrolled twins
    (qq/hl/lh) but prepend `int32_t ctrl_flag` as parameter 0 - the single
    control wire (PRD §1.2). The void `_unc` shapes (uqq/uhl/ulh/ua1) are
    routed to `_unc_signature`.
    """
    shape = row["shape"]
    if shape in UNC_SHAPES:
        return _unc_signature(row)
    sym = row["sym"]
    ctrl = "int32_t ctrl_flag, " if shape in CONTROLLED_SHAPES else ""
    if shape == "a1":  # arity-1: cast / unary (never controlled)
        return f"int32_t {sym}(int32_t a_handle)"
    if shape in ("qq", "cqq"):  # Q+Q binary or compare
        return f"int32_t {sym}({ctrl}int32_t a_handle, int32_t b_handle)"
    if shape == "qqq":  # ternary fma, all-handle (no classical operand)
        return f"int32_t {sym}(int32_t a_handle, int32_t b_handle, int32_t c_handle)"
    ctype = WIDTH_INFO[row["classical_w"]]["ctype"]
    if shape in ("hl", "chl"):  # handle on LHS, classical scalar on RHS
        return f"int32_t {sym}({ctrl}int32_t a_handle, {ctype} b_classical)"
    if shape == "qql":  # ternary fma: handle*handle + literal
        return f"int32_t {sym}(int32_t a_handle, int32_t b_handle, {ctype} c_classical)"
    if shape == "qlq":  # ternary fma: handle*literal + handle
        return f"int32_t {sym}(int32_t a_handle, {ctype} b_classical, int32_t c_handle)"
    if shape == "qll":  # ternary fma: handle*literal + literal
        return f"int32_t {sym}(int32_t a_handle, {ctype} b_classical, {ctype} c_classical)"
    # shape lh/clh: classical scalar on LHS, handle on RHS
    return f"int32_t {sym}({ctrl}{ctype} a_classical, int32_t b_handle)"


def stub_body(row):
    """Return the C body lines (without the signature braces).

    Controlled shapes (cqq/chl/clh) prepend the control flag to the trace as
    a leading `h%d` (the flag is an i32 handle, PRD §1.2); the rest of the
    trace mirrors the uncontrolled twin exactly. The void `_unc` shapes are
    routed to `_unc_body`.
    """
    shape = row["shape"]
    if shape in UNC_SHAPES:
        return _unc_body(row)
    sym = row["sym"]
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
    if shape == "qqq":  # ternary fma, all-handle
        return (
            "    int32_t h = cqrt_alloc_handle();\n"
            f"    printf(\"{sym}(h%d, h%d, h%d) -> h%d\\n\", a_handle, b_handle, c_handle, h);\n"
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
    if shape in ("qql", "qlq", "qll"):  # ternary fma, mixed handle/literal
        b_expr = f"{info['cast']}b_classical" if info["cast"] else "b_classical"
        c_expr = f"{info['cast']}c_classical" if info["cast"] else "c_classical"
        b_slot = info["fmt"] if shape in ("qlq", "qll") else "h%d"
        c_slot = info["fmt"] if shape in ("qql", "qll") else "h%d"
        b_arg = b_expr if shape in ("qlq", "qll") else "b_handle"
        c_arg = c_expr if shape in ("qql", "qll") else "c_handle"
        return (
            "    int32_t h = cqrt_alloc_handle();\n"
            f"    printf(\"{sym}(h%d, {b_slot}, {c_slot}) -> h%d\\n\", a_handle, {b_arg}, {c_arg}, h);\n"
            "    fflush(stdout);\n    return h;\n"
        )
    # shape lh/clh: classical scalar on LHS, handle on RHS; trace order classical, handle.
    cast_expr = f"{info['cast']}a_classical" if info["cast"] else "a_classical"
    return (
        "    int32_t h = cqrt_alloc_handle();\n"
        f"    printf(\"{sym}({ctrl_fmt}{info['fmt']}, h%d) -> h%d\\n\", {ctrl_arg}{cast_expr}, b_handle, h);\n"
        "    fflush(stdout);\n    return h;\n"
    )


# -------------------- void in-place `_unc` family (Phase 5) --------------------

def _unc_signature(row):
    """Void in-place uncompute decl (PRD §2.3 / DD-3). `out_handle` is arg 0;
    the forward operands follow in their ORIGINAL order. No return value -
    the op zeroes the `out` rail, mints nothing.
    """
    sym = row["sym"]
    shape = row["shape"]
    if shape == "ua1":  # arity-1 (unary / cast): _unc(out, src)
        return f"void {sym}(int32_t out_handle, int32_t a_handle)"
    if shape == "uqq":  # forward (a_handle, b_handle) -> _unc(out, a_handle, b_handle)
        return f"void {sym}(int32_t out_handle, int32_t a_handle, int32_t b_handle)"
    if shape == "uqqq":  # ternary all-handle -> _unc(out, a, b, c)
        return (f"void {sym}(int32_t out_handle, int32_t a_handle, "
                "int32_t b_handle, int32_t c_handle)")
    ctype = WIDTH_INFO[row["classical_w"]]["ctype"]
    if shape == "uhl":  # forward (a_handle, b_classical) -> _unc(out, a_handle, b_classical)
        return f"void {sym}(int32_t out_handle, int32_t a_handle, {ctype} b_classical)"
    if shape == "uqql":  # ternary h*h+lit -> _unc(out, a, b, c_classical)
        return (f"void {sym}(int32_t out_handle, int32_t a_handle, "
                f"int32_t b_handle, {ctype} c_classical)")
    if shape == "uqlq":  # ternary h*lit+h -> _unc(out, a, b_classical, c)
        return (f"void {sym}(int32_t out_handle, int32_t a_handle, "
                f"{ctype} b_classical, int32_t c_handle)")
    if shape == "uqll":  # ternary h*lit+lit -> _unc(out, a, b_classical, c_classical)
        return (f"void {sym}(int32_t out_handle, int32_t a_handle, "
                f"{ctype} b_classical, {ctype} c_classical)")
    # ulh: forward (a_classical, b_handle) -> _unc(out, a_classical, b_handle)
    return f"void {sym}(int32_t out_handle, {ctype} a_classical, int32_t b_handle)"


def _unc_body(row):
    """Trace-only void body. Prints `out` first (DD-3 slot order), then the
    forward operands in their original order. NO `cqrt_alloc_handle` (mints
    nothing), NO `return`, NO `-> h` result suffix - the handle counter does
    not advance. Real rail-zeroing arrives with the Phase 8+ template bodies.
    """
    sym = row["sym"]
    shape = row["shape"]
    if shape == "ua1":
        return (
            f"    printf(\"{sym}(h%d, h%d)\\n\", out_handle, a_handle);\n"
            "    fflush(stdout);\n"
        )
    if shape == "uqq":
        return (
            f"    printf(\"{sym}(h%d, h%d, h%d)\\n\", out_handle, a_handle, b_handle);\n"
            "    fflush(stdout);\n"
        )
    if shape == "uqqq":  # ternary all-handle: out, a, b, c
        return (
            f"    printf(\"{sym}(h%d, h%d, h%d, h%d)\\n\", out_handle, a_handle, b_handle, c_handle);\n"
            "    fflush(stdout);\n"
        )
    info = WIDTH_INFO[row["classical_w"]]
    if shape == "uhl":
        cast_expr = f"{info['cast']}b_classical" if info["cast"] else "b_classical"
        return (
            f"    printf(\"{sym}(h%d, h%d, {info['fmt']})\\n\", out_handle, a_handle, {cast_expr});\n"
            "    fflush(stdout);\n"
        )
    if shape in ("uqql", "uqlq", "uqll"):  # ternary mixed: out, a, then b/c by shape
        b_expr = f"{info['cast']}b_classical" if info["cast"] else "b_classical"
        c_expr = f"{info['cast']}c_classical" if info["cast"] else "c_classical"
        b_slot = info["fmt"] if shape in ("uqlq", "uqll") else "h%d"
        c_slot = info["fmt"] if shape in ("uqql", "uqll") else "h%d"
        b_arg = b_expr if shape in ("uqlq", "uqll") else "b_handle"
        c_arg = c_expr if shape in ("uqql", "uqll") else "c_handle"
        return (
            f"    printf(\"{sym}(h%d, h%d, {b_slot}, {c_slot})\\n\", out_handle, a_handle, {b_arg}, {c_arg});\n"
            "    fflush(stdout);\n"
        )
    # ulh: trace order out, classical, handle.
    cast_expr = f"{info['cast']}a_classical" if info["cast"] else "a_classical"
    return (
        f"    printf(\"{sym}(h%d, {info['fmt']}, h%d)\\n\", out_handle, {cast_expr}, b_handle);\n"
        "    fflush(stdout);\n"
    )
