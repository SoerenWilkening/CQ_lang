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
#
# LABEL INJECTIVITY (bd `ni15`, 2026-07-28) is the governing invariant here:
# the classical-operand field of a trace label MUST be a one-to-one function of
# the IR constant, because the Rule-2 golden byte-diff is the only gate that
# witnesses an emitted immediate at all. Two distinct IR constants that render
# to the same label make a miscompile of that constant INVISIBLE — which is a
# silent-miscompile blind spot, not a cosmetic issue. Every entry below is
# therefore round-trip exact for its width:
#   * i1..i64  — decimal via (long long)/%lld (or %d for bool). Already
#                injective: every value fits the promoted type losslessly.
#   * i80/i128 — FIXED-WIDTH HEX of the full bit pattern, printed as two
#                unsigned-long-long halves because printf has no >64-bit
#                specifier (see the per-entry notes).
#   * f16..f80 — HEX FLOAT (%a / %La). Exact for every finite value and for
#                ±inf at every width, and mechanically comparable against the
#                IR's own hex constant. Supersedes the old %f/%Lf 6-digit
#                prints, under which 0x1p-128 and +0.0 both rendered
#                `0.000000`.
# RESIDUE, stated so nobody reads the invariant as total: every NaN encoding
# still renders as the bare string `nan` — sign, quiet/signalling bit and
# payload are all dropped. NaN<->NaN is the ONE surviving collision class (no
# NaN can alias a finite, an inf, or a signed zero); it is unchanged from the
# %f era rather than a regression, and closing it needs raw-bit-pattern
# printing, not another format specifier. Tracked on bd `ni15`.
# PORTABILITY: the leading-digit style of `%La` is implementation-defined. Apple
# libc and glibc both use the explicit-integer-bit nibble (1.5L -> `0xcp-3`), so
# the f80 goldens are byte-identical on macOS and Linux; musl normalizes via
# frexpl and would render differently. That is a loud spurious golden diff (the
# safe direction), on a corpus already pinned to x86-64 + clang-19 by Rule 9.
# `arg_exprs()` below turns a C expression into the matching printf argument
# list; every body builder in this module routes through it, so a width's
# rendering is defined in exactly one place. If you add a width, it must be
# injective at that width or the golden gate silently weakens.
WIDTH_INFO = {
    "i1":  {"ctype": "bool",    "fmt": "%d",   "cast": "(int)"},
    "i8":  {"ctype": "int8_t",  "fmt": "%lld", "cast": "(long long)"},
    "i16": {"ctype": "int16_t", "fmt": "%lld", "cast": "(long long)"},
    "i32": {"ctype": "int32_t", "fmt": "%lld", "cast": "(long long)"},
    "i64": {"ctype": "int64_t", "fmt": "%lld", "cast": "(long long)"},
    # i128 (n0ui Tier-1): __int128 is a valid C type but printf has NO 128-bit
    # specifier, so the body prints the full 128-bit pattern as two %016llx
    # halves — `0x` + 32 fixed hex digits, high word first. Fixed width keeps
    # the concatenation unambiguous (a variable-width high word could alias a
    # different (high, low) split).
    "i128": {"ctype": "__int128", "fmt": "0x%016llx%016llx",
             "args": "(unsigned long long)((unsigned __int128)({e}) >> 64), "
                     "(unsigned long long)({e})"},
    # i80 (bd 3c6m.51): the x86_fp80 bit-pattern extraction width. i80 is not a
    # C type, so it rides __int128; LLVM promotes the i80 call argument into the
    # i128 parameter and the 48 bits above bit 79 are ABI PADDING — the mask
    # below drops them, so the label depends only on the 80 value bits and is
    # independent of how the backend materialized the padding. Printed as `0x` +
    # 20 fixed hex digits (4 for the high 16 bits, 16 for the low 64), i.e. the
    # exact 80-bit pattern as LLVM writes it.
    #
    # HISTORY (bd `ni15`): this width used to print via (long long)/%lld — the
    # LOW 64 BITS ONLY. bd 3c6m.58 landed the cells that note predicted (a LIVE
    # SET_LDOUBLE_WORDS/IEEEl2bits field-insert at a sub-64 offset emits an
    # and-clear keep-mask above 2^64): nextafterl, modfl, lroundl, llroundl,
    # frexpl (1 each) and sinhl (2). slice_libm_real_nextafterl printed
    # `cq_template_and_i80_hl(h520, 4294967295)` for the true operand
    # i80 0xFFFF_00000000_FFFFFFFF, so a miscompile of ANY bit above 63 of that
    # mask was invisible to the Rule-2 diff. It now reads
    # `cq_template_and_i80_hl(h520, 0xffff00000000ffffffff)`.
    "i80": {"ctype": "__int128", "fmt": "0x%04llx%016llx",
            "args": "(unsigned long long)(((unsigned __int128)({e}) >> 64) & 0xFFFFu), "
                    "(unsigned long long)({e})"},
    # _Float16: the explicit (double) cast is MANDATORY — a bare _Float16 passed
    # to printf trips -Wdouble-promotion / a format-arg type mismatch under
    # -Werror. The promotion to double is EXACT (f16 ⊂ f64), so %a of the
    # promoted value is still injective on the f16 operand. f16 is fp-domain; it
    # has a runtime template surface (fadd_f16 etc.) but, like all fp widths, NO
    # cqrt_copy_f16 (copyFn null-guards on isIntegerTy — the f16-angle-vs-data
    # fence; see WidthDispatch.cpp).
    "f16": {"ctype": "_Float16", "fmt": "%a",   "cast": "(double)"},
    # f32: the (double) promotion is likewise exact, so %a round-trips the float.
    "f32": {"ctype": "float",   "fmt": "%a",   "cast": "(double)"},
    "f64": {"ctype": "double",  "fmt": "%a",   "cast": ""},
    # f80 (bd 3c6m.4): the long-double width on x86-64, where `long double` IS
    # x86_fp80. c_type `long double`, printed with the `L` length modifier (no
    # cast; %La takes a bare long double) — %Lf would round the 64-bit
    # significand to 6 decimals, which is what made 0x1p-128 read as `0.000000`
    # (bd ni15). Cast templates are handle-only (i32→i32), so `long double`
    # appears only in _hl/_lh classical-operand slots. f128 (IEEE quad, ==
    # long double on AArch64) is NOT shipped here: `long double` == fp80 on
    # x86-64, so an fp128 c_type of `long double` would be an fp128-into-fp80
    # ABI miscompile — a tainted fp128 declines instead (deferred to AArch64).
    "f80":  {"ctype": "long double", "fmt": "%La", "cast": ""},
}


def arg_exprs(width, expr):
    """Return the printf argument list (a C expression string, possibly
    comma-separated) rendering the classical operand `expr` at `width`.

    Widths whose value fits a single promoted printf argument use the plain
    `cast + expr` form. The wide integer widths (i80/i128) have no >64-bit
    printf specifier, so they expand to TWO unsigned-long-long arguments
    matching the two `%llx` conversions in their `fmt` — see WIDTH_INFO.
    """
    info = WIDTH_INFO[width]
    if "args" in info:
        return info["args"].format(e=expr)
    return f"{info['cast']}{expr}" if info["cast"] else expr

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
    w = row["classical_w"]
    info = WIDTH_INFO[w]
    if shape in ("hl", "chl"):  # handle on LHS, classical scalar on RHS
        cast_expr = arg_exprs(w, "b_classical")
        return (
            "    int32_t h = cqrt_alloc_handle();\n"
            f"    printf(\"{sym}({ctrl_fmt}h%d, {info['fmt']}) -> h%d\\n\", {ctrl_arg}a_handle, {cast_expr}, h);\n"
            "    fflush(stdout);\n    return h;\n"
        )
    if shape in ("qql", "qlq", "qll"):  # ternary fma, mixed handle/literal
        b_expr = arg_exprs(w, "b_classical")
        c_expr = arg_exprs(w, "c_classical")
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
    cast_expr = arg_exprs(w, "a_classical")
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
    w = row["classical_w"]
    info = WIDTH_INFO[w]
    if shape == "uhl":
        cast_expr = arg_exprs(w, "b_classical")
        return (
            f"    printf(\"{sym}(h%d, h%d, {info['fmt']})\\n\", out_handle, a_handle, {cast_expr});\n"
            "    fflush(stdout);\n"
        )
    if shape in ("uqql", "uqlq", "uqll"):  # ternary mixed: out, a, then b/c by shape
        b_expr = arg_exprs(w, "b_classical")
        c_expr = arg_exprs(w, "c_classical")
        b_slot = info["fmt"] if shape in ("uqlq", "uqll") else "h%d"
        c_slot = info["fmt"] if shape in ("uqql", "uqll") else "h%d"
        b_arg = b_expr if shape in ("uqlq", "uqll") else "b_handle"
        c_arg = c_expr if shape in ("uqql", "uqll") else "c_handle"
        return (
            f"    printf(\"{sym}(h%d, h%d, {b_slot}, {c_slot})\\n\", out_handle, a_handle, {b_arg}, {c_arg});\n"
            "    fflush(stdout);\n"
        )
    # ulh: trace order out, classical, handle.
    cast_expr = arg_exprs(w, "a_classical")
    return (
        f"    printf(\"{sym}(h%d, {info['fmt']}, h%d)\\n\", out_handle, {cast_expr}, b_handle);\n"
        "    fflush(stdout);\n"
    )
