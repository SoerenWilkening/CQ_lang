/* slice_railbank_owner_cascade.c — THE OWNER'S CANONICAL CUSTOMER PROGRAM,
   COMMITTED AS THE RECORD (owner ruling E4, bd `zwtm`, session 2026-09-15).

   ⚠ THIS SLICE IS DELIBERATELY **NOT REGISTERED** IN `CMakeLists.txt` AND HAS
   **NO GOLDEN**, because the program still DECLINES and the e2e layer has no
   decline shape: `run_slice*.sh` runs under `set -euo pipefail` and byte-diffs a
   golden, so a declining `.c` cannot be a passing entry.  It follows the
   `slice_control_switch_phase.c` precedent (2026-09-05) and the two bd-`3d8q`
   conversions (2026-09-14): the file is KEPT, with this conversion header and
   the retirement trigger below.  The DECLINE itself is pinned in the lit layer
   by `lowering_railbank_bank_anchor_n3.ll` and friends, which mirror the string
   character-for-character.

   ⚠ E4's WHOLE MITIGATION IS A BYTE-IDENTITY OBLIGATION, SO HERE IS THE RECIPE
   THAT CHECKS IT, EXECUTABLE RATHER THAN ASSERTED.  `example/` is in
   `.git/info/exclude`, so the owner's file is local-only and this copy is the
   committed record.  The code body below is BYTE-IDENTICAL to

       example/grover/grover_oracle_uncompute.c

   as measured 2026-09-15, extracted by

       sed -n '83,95p;129,131p' example/grover/grover_oracle_uncompute.c

   (lines 96-128 are the owner's commented-out earlier spellings, so the active
   body is NOT CONTIGUOUS in the file).  sha256 of that extraction:
   `bf3b96de04ef60e577cdfa5a05392ee5fd0d75fd89aa0652d24ab4ff6cf0dbf1`.  The
   trailing space on the blank line inside the loop and the DOUBLE space in
   `cq_measure(b0[1])  + cq_measure(b0[2])` are the owner's and are preserved.

   ⚠ AND THE ORCHESTRATOR'S ORIGINAL E4 CLAIM — that the live file "matches the
   session brief's reproduction exactly" — IS FALSE.  It was an eyeball
   comparison reported as a measurement (the brief normalises both whitespace
   differences above).  The recipe in this header is what a future reader must
   re-run; do not take a brief's code block as the source.

   ⚠ WHY IT STILL DECLINES, AND WHAT IT IS NOT.  bd `xdu2` W1's SECOND HALF
   removed walls 1 and 2 of this program's FOUR:

     1  cq taint escape: tainted value stored to memory        — W1 piece 3  GONE
     2  cq controlled lowering: value-arm swap-route under
        quantum control (at the arm's `zext i1 %q to i8`)      — W1 piece 2  GONE
     3  cq controlled lowering: control flow inside a loop body
        under quantum control                                  — `iterationLocalRollable`
                                                                 conjunct (c3), bd `8h7d.11`
     4  cq loop lowering: loop-carried tainted value crosses
        iterations                                             — X1 / bd `ej5w` / W3

   MEASURED on the subject binary, this file declines row 3.  Owner ruling E5 in
   the words it requires: **the bank compiles; the owner's cascade needs (c3) +
   W3.**  Not "the decline moved".

   ⚠ ROWS 3 AND 4 ARE BANK-INDEPENDENT AND W1 COULD NEVER HAVE MOVED THEM.
   `trackB/probes/b02_scalar_measure_a_outside.c` is the same loop with a SCALAR
   `bool` and no array at all and declines row 3 identically;
   `b05_scalar_classical_acc.c`, identical but with the arm not feeding `a`,
   ACCEPTS.  The discriminator is the tainted loop-carried accumulator.

   ⚠ AND THE FOUR-WALL TABLE IS NOT EXHAUSTIVE.  `LLVMContext::diagnose` EXITS on
   the first `DS_Error`, so each row is only "the first decline once the row
   above is gone".  Rows 3 and 4 were measured by successive hand-removal, never
   on a binary where both were genuinely absent, so they are the first two
   declines of an unknown-length tail.  Whoever lands (c3) + W3 must RUN THE WALL
   SEQUENCE FORWARD ON THE REAL SUBJECT BINARY AND REPORT ITS LENGTH, not assume
   four.

   ⚠ L8 RETIREMENT TRIGGER: the day bd `8h7d.11` ((c3)) and bd `ej5w` / W3 (X1,
   BOTH sites — `LoopLowering.cpp` `:2136` and the round-2 twin `:2579`) land,
   re-derive this file: rename `main` -> `slice`, add a `main` shim, generate the
   golden, and REGISTER it.  bd `zwtm` closes then, and not before — do NOT read
   the committed file as closing it.  Do NOT delete this file in the meantime.

   THE OWNER'S CODE BODY, VERBATIM, BEGINS ON THE NEXT LINE.
*/
#include "CQ.h"
#include <math.h>

int main(void) {
    int a = 5;
    bool b0[3];
    
    for (int i = 0; i < 3; ++i) {
        if (a >= 3){
            b0[i] = cq_theta(b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }
    
    return cq_measure(b0[0]) + cq_measure(b0[1])  + cq_measure(b0[2]) + cq_measure(a);
}
