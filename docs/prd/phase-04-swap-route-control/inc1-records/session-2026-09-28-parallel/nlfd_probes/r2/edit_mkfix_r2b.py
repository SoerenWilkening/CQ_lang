#!/usr/bin/env python3
"""edit_mkfix_r2b.py — round 2, second pass: the three fence/step-1 decline headers were written
against `main` 9a230646; on `main` ba4fdad4 (bd rhk5) their "the accept is a wrong unitary"
premise is FALSE for every member measured (bd test_C_libtooling-ur72). Say so at the source
(the fixture headers), keeping the 9a230646 history. Anchored, exactly-once replacements."""
import pathlib

p = pathlib.Path(__file__).resolve().parent.parent / "tools" / "mkfix.py"
s = p.read_text()


def rep(a, b):
    global s
    assert s.count(a) == 1, (a[:70], s.count(a))
    s = s.replace(a, b)


rep('''; parameter dead). For THIS caller operand (a DERIVED `p = q * 3`) both accepts are wrong:
; keeping `main`'s slot is bd tzfa's phantom read (what the ORACLE `main` 9a230646 does: exit 0,
; a warning, `p`'s rail dirty across the Ry — TRACE-DIFF vs the twin), and neutralising it
; would lower `t = a * 5` on runtime handle 0 (bd sqjq). ⚠ Not for every caller operand
; (Rule-13 r1A F-r1A-2): with a `cq_theta` SOURCE there the ORACLE's accept WAS the twin's
; unitary and the fence still declines — a known IR-only over-decline, bd
; test_C_libtooling-w109. The hand-inlined twin (`r = m + 1`) ACCEPTS: a knowing over-decline''',
    '''; parameter dead). On `main` 9a230646, for THIS caller operand (a DERIVED `p = q * 3`), both
; accepts were wrong: keeping `main`'s slot was bd tzfa's phantom read (exit 0, a warning, `p`'s
; rail dirty across the Ry — TRACE-DIFF vs the twin), and neutralising it would lower
; `t = a * 5` on runtime handle 0 (bd sqjq); for a `cq_theta` SOURCE operand the keep-the-slot
; accept already was the twin's unitary (Rule-13 r1A F-r1A-2, bd test_C_libtooling-w109).
; ⚠ SINCE bd rhk5 (9ad22639) THE KEEP-THE-SLOT ACCEPT IS CORRECT HERE TOO (bd
; test_C_libtooling-ur72, measured on `main` ba4fdad4): the spine discharges `p` although the
; clone call reads it, and the stream is the twin's plus an identity compute/uncompute pair on a
; scratch rail (2b STRICT, 0 dirty). So this file now pins an IR-only OVER-DECLINE of a program
; `main` compiles correctly, kept pending the owner's decision on bd ur72. The hand-inlined twin
; (`r = m + 1`) ACCEPTS: a knowing over-decline''')

rep('''; `…_inner_inst.ll`. On the ORACLE this module ABORTED (exit 134: the `musttail` call inside
; `h`'s clone was no longer followed by `ret` once `t`'s template was Bennett-reversed after
; it). The fence speaks inside `buildClone` right after the record — before the Bennett wrap
; emits anything — so this file declines with or without the same track's clone-`musttail`
; demotion (commit C).""")''',
    '''; `…_inner_inst.ll`. On the ORACLE this module ABORTED (exit 134: the `musttail` call inside
; `h`'s clone was no longer followed by `ret` once `t`'s template was Bennett-reversed after
; it). The fence speaks inside `buildClone` right after the record — before the Bennett wrap
; emits anything — so this file declines with or without the same track's clone-`musttail`
; demotion (commit C). ⚠ Like `…_inner_inst.ll`, an IR-only over-decline since bd rhk5 (bd
; test_C_libtooling-ur72).""")''')

rep('''; quantum operand — its existing decline. On the ORACLE the record called the parameter live
; and the module ACCEPTED with bd tzfa's phantom read (TRACE-DIFF vs the twin `r = m + 1`, `p`
; dirty across the Ry, warned). A wrong accept became the module-level rule's (IR-only,
; knowing) over-decline; the twin accepts. Retirement trigger: `nullSafeSlot` admitting
; string attributes (owner question bd test_C_libtooling-uyhx).""")''',
    '''; quantum operand — its existing decline. On `main` 9a230646 the record called the parameter
; live and the module ACCEPTED with bd tzfa's phantom read (TRACE-DIFF vs the twin `r = m + 1`,
; `p` dirty across the Ry, warned). ⚠ On `main` ba4fdad4 (bd rhk5) that same accept is
; TRACE-IDENT with the twin (one lyyf-(B) over-warn): this decline is now an IR-only
; OVER-DECLINE of a program `main` compiles correctly, introduced by nlfd in composition with
; rhk5 (bd test_C_libtooling-ur72). Retirement triggers: bd ur72, or `nullSafeSlot` admitting
; string attributes (owner question bd test_C_libtooling-uyhx).""")''')
p.write_text(s)
print("ok")
