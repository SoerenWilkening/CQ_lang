#!/usr/bin/env python3
"""Patch the vendored Berkeley SoftFloat 3e files (softfloat/upstream) for CQ, in place.

SoftFloat keeps the rounding mode, the tininess mode and the exception flags in globals. A lowered
function must touch no global memory, so this patch threads them through a context instead:

  * every SoftFloat function that is not a primitive of primitives.h takes `struct sf_ctx *sf_ctx`
    as its first parameter, and every call of one passes `sf_ctx` on;
  * softfloat.h defines `struct sf_ctx { roundingMode; exceptionFlags; }` and turns the globals
    into macros: softfloat_roundingMode and softfloat_exceptionFlags read the context,
    softfloat_raiseFlags(f) ORs into it, softfloat_detectTininess is the constant
    tininess-after-rounding (x86 SSE), extF80_roundingPrecision is the constant 80 (x87 PC =
    extended, BACKEND_ABI section 2.9);
  * softfloat_state.c (the globals) is not vendored, and 8086-SSE/softfloat_raiseFlags.c is not
    compiled (softfloat/cq/sf_unity.h lists what is).

The roots (softfloat/cq) put the context in a local and give every SoftFloat function
`__attribute__((always_inline))`, so after clang -O1 the context is scalar SSA: mode in, flags out,
no memory access. Run once on the unmodified upstream files; it refuses to run twice.
"""
import re
import sys
from pathlib import Path

UP = Path(__file__).resolve().parent.parent / "upstream"
MARK = "/* CQ: patched by softfloat/tools/patch_upstream.py */"


def c_files():
    return sorted(UP.glob("*.c")) + sorted((UP / "8086-SSE").glob("*.c"))


def headers():
    return [UP / "include" / "softfloat.h", UP / "include" / "internals.h", UP / "8086-SSE" / "specialize.h"]


def defined_name(p: Path) -> str:
    stem = p.stem
    return "softfloat_" + stem[2:] if stem.startswith("s_") else stem


def patch_tables():
    """The 16-entry reciprocal tables read at a computed index would be a memory access (a bus load at a
    quantum address once lowered). Each read becomes a select over four packed 64-bit constants."""
    defs = []
    for f in ["s_approxRecip_1Ks.c", "s_approxRecipSqrt_1Ks.c"]:
        for name, body in re.findall(r"const uint16_t (softfloat_\w+)\[16\] = \{([^}]*)\}", (UP / f).read_text()):
            v = [int(x, 16) for x in re.findall(r"0x[0-9A-Fa-f]+", body)]
            if len(v) != 16:
                sys.exit(f"patch_upstream.py: {name}: {len(v)} entries")
            w = [sum(v[4 * j + i] << (16 * i) for i in range(4)) for j in range(4)]
            defs.append(f"#define {name}_at( i ) softfloat_cq_tbl16( " +
                        ", ".join(f"UINT64_C( 0x{x:016X} )" for x in w) + ", (i) )")
    if len(defs) != 4:
        sys.exit("patch_upstream.py: expected the four reciprocal tables")
    plat = UP / "include" / "platform.h"
    plat.write_text(plat.read_text() + f"""
{MARK}
/* The reciprocal tables of s_approxRecip_1Ks.c and s_approxRecipSqrt_1Ks.c as selects: entry i of a
| 16-entry table is bits 16*(i%4).. of packed word i/4. */
#ifndef softfloat_cq_tbl16_defined
#define softfloat_cq_tbl16_defined 1
#include <stdint.h>
static inline uint16_t
 softfloat_cq_tbl16( uint64_t w0, uint64_t w1, uint64_t w2, uint64_t w3, unsigned int i )
{{
    uint64_t w = (i & 8) ? ((i & 4) ? w3 : w2) : ((i & 4) ? w1 : w0);
    return (uint16_t) (w>>((i & 3) * 16));
}}
""" + "\n".join(defs) + "\n#endif\n")
    n = 0
    for p in c_files():
        if p.name.endswith("_1Ks.c"):
            continue   # the tables themselves stay (unused)
        t = p.read_text()
        t2, k = re.subn(r"\b(softfloat_approx(?:Recip|RecipSqrt)_1k[01]s)\[([^\]]+)\]", r"\1_at( \2 )", t)
        if k:
            p.write_text(t2)
            n += k
    if n == 0:
        sys.exit("patch_upstream.py: no table read found")


def fix_bf16_nan():
    """Upstream bug (07ebd29, s_commonNaNToBF16UI.c): the payload is shifted by 56, so the top payload bit
    lands on the exponent's low bit and every payload bit one place too high (f32 0x7FA00003 gave 0x7FC0;
    compiler-rt's __truncsfbf2 and CR section 2, "a quiet NaN carrying the high payload bits", give 0x7FE0).
    A bf16 fraction has 7 bits: shift by 57, as commonNaNToF16UI shifts its 10 bits by 54."""
    f = UP / "8086-SSE" / "s_commonNaNToBF16UI.c"
    t = f.read_text()
    old = "aPtr->v64>>56;"
    if t.count(old) != 1:
        sys.exit("patch_upstream.py: s_commonNaNToBF16UI.c: shift not found")
    f.write_text(t.replace(old, "aPtr->v64>>57;   /* CQ: bf16 payload fix, softfloat/tools/patch_upstream.py */"))


def main():
    sfh = UP / "include" / "softfloat.h"
    if MARK in sfh.read_text():
        sys.exit("patch_upstream.py: already patched")
    prim = set(re.findall(r"\b(softfloat_\w+)\s*\(", (UP / "include" / "primitives.h").read_text()))
    names = set()
    for p in c_files():
        n = defined_name(p)
        if n == "softfloat_raiseFlags" or n in prim:
            continue
        if not re.search(rf"\b{re.escape(n)}\s*\(", p.read_text()):
            if not re.search(r"^const \w+ softfloat_\w+\[\d+\] = \{", p.read_text(), re.M):
                sys.exit(f"patch_upstream.py: {p.name} defines neither a function nor a table {n}")
            continue   # a table (the reciprocal and leading-zero tables)
        names.add(n)
    # A parameter list starts with a type; an argument list never does in SoftFloat.
    typ = re.compile(r"(const|struct|union|bool|void|unsigned|signed|int|char|[A-Za-z_]\w*_t)\b")
    call_re = re.compile(r"\b(" + "|".join(sorted(map(re.escape, names), key=len, reverse=True)) + r")(\s*)\(")
    stats = {"decl": 0, "call": 0}

    def patch_text(text: str) -> str:
        out, pos = [], 0
        for m in call_re.finditer(text):
            rest = text[m.end():].lstrip()
            out.append(text[pos:m.end()])
            pos = m.end()
            if typ.match(rest):
                out.append(" struct sf_ctx *sf_ctx,")
                stats["decl"] += 1
            else:
                out.append(" sf_ctx,")
                stats["call"] += 1
        out.append(text[pos:])
        return "".join(out)

    for p in c_files() + headers():
        p.write_text(patch_text(p.read_text()))

    t = sfh.read_text()
    state = re.compile(r"extern THREAD_LOCAL uint_fast8_t (softfloat_detectTininess|softfloat_roundingMode|"
                       r"softfloat_exceptionFlags|extF80_roundingPrecision);\n")
    t, n = state.subn("", t)
    if n != 4:
        sys.exit(f"patch_upstream.py: expected 4 state declarations in softfloat.h, found {n}")
    t, n = re.subn(r"void softfloat_raiseFlags\( uint_fast8_t \);\n", "", t)
    if n != 1:
        sys.exit("patch_upstream.py: softfloat_raiseFlags declaration not found")
    ctx = f"""{MARK}
/*----------------------------------------------------------------------------
| CQ: the floating-point environment is a context the caller owns, never a
| global.  Every non-primitive function takes `struct sf_ctx *sf_ctx' first.
*----------------------------------------------------------------------------*/
struct sf_ctx {{ uint_fast8_t roundingMode; uint_fast8_t exceptionFlags; }};
#define softfloat_roundingMode (sf_ctx->roundingMode)
#define softfloat_exceptionFlags (sf_ctx->exceptionFlags)
#define softfloat_raiseFlags( flags ) ((void) (sf_ctx->exceptionFlags |= (flags)))
#define softfloat_detectTininess softfloat_tininess_afterRounding
#define extF80_roundingPrecision 80

"""
    anchor = ("/*----------------------------------------------------------------------------\n"
              "| Software floating-point underflow tininess-detection mode.")
    if anchor not in t:
        sys.exit("patch_upstream.py: softfloat.h anchor not found")
    sfh.write_text(t.replace(anchor, ctx + anchor, 1))
    patch_tables()
    fix_bf16_nan()
    # internals.h is included before softfloat.h in some files: declare the tag where both see it.
    sft = UP / "include" / "softfloat_types.h"
    t = sft.read_text()
    anchor = "#include <stdint.h>\n"
    if anchor not in t:
        sys.exit("patch_upstream.py: softfloat_types.h anchor not found")
    sft.write_text(t.replace(anchor, anchor + "\nstruct sf_ctx;   " + MARK + "\n", 1))
    print(f"patch_upstream.py: {len(names)} functions take sf_ctx; {stats['decl']} declarations or "
          f"definitions and {stats['call']} calls patched")


if __name__ == "__main__":
    main()
