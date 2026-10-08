# R2 analytic follow-up: entry PHIs and stable literal assertions

Disposition: both historical entry-PHI subjects are sound positive migration candidates. The shared fixed-script lowering and its existing scalar literal admission can represent their source functions. The previously reviewed refreshSpeculationTaint ordering and opaque Freeze negation remain sound. No new helper named classicalCondLiteral exists or is required by this review; the relevant existing owners are collectCondTree, condLiteralAdmissible and the final literal-taint recheck.

Counts: 0 tests, 0 probes, 0 builds, 0 cq-opt executions, 0 mutations. Repository files unchanged by the reviewer. Read current source/diff and existing saved batch artifacts only. This report does not claim the newly migrated fixture assertions passed or that their new emitted modules have already been observed.

## Findings and corrections

During assertion editing, the volatile runtime scalar fixture source parameter was accidentally renamed rt.stable while its body still referred to rt. The implementer restored rt, as confirmed by the current diff. Its output freeze and gate operand assertions now preserve the original source contract.

The RuleB condtree fixture briefly placed entry after the x/y freeze checks. The implementer corrected it to entry then CHECK-DAG freezes. The saved output emits y.stable before x.stable, so the DAG spelling is appropriate. Its bound GF/NF literals now appear in both forward and inverse template calls.

The armbody_flags_stripped saved output contains cc = add c,1; cc.stable = freeze cc; add_hl(Q,cc.stable). The fixture initially retained add_hl(Q,CC). The current edit binds CF to that freeze and uses CF, preserving the actual flags-stripping assertion and its literal provenance.

At the final read before this report, the typed seed checks still used raw u0 in qrom_mask_narrow_source subjects sext_i8_n4, zext_i16_n8 and sext_i8_n256, and qrom_mask_width_bounds subject sext_i8_n512. Existing saved output places freeze i8/i16 u0 to u0.stable before qram_alloc and uses u0.stable in the exact-width cqrt_alloc. Add the typed freeze assertion before the table allocation and use u0.stable. The implementer was notified and is completing these edits.

Migrated historical negatives still had isolated old prose such as "rail/template is minted before the decline" below their now-positive source functions when read. Remove those orphan sentences. No requirement to maintain those historical restrictions follows from the source semantics.

## Entry-PHI source argument

For both subjects, let H = q>5 and let A = C ? q+1 : 3q. All arithmetic is unflagged i32 arithmetic and wraps modulo 2^32. The two outer PHIs select AV=A and AW=A+7 on H, otherwise q and 0. The measured sum is therefore H ? 2*A+7 : q.

For control_predmux_reject_entryphi_via_compare, the existing classical branch is g = u0>0. The surviving entry PHI is eph = g ? arg : 9, and C = eph==0. Neither eph nor arg is a borrowed quantum handle. On the g=false path C is false because eph=9. On g=true defined arg values determine the scalar bit normally.

For control_predmux_reject_i1phi_entry_block, the surviving entry PHI is ep = phi [true,pa],[false,pb], so C=ep=g. The outer classical control flow establishes the PHI on its real predecessor edge. Retaining that scalar PHI is legal; the compiler need not turn it into a quantum rail.

collectCondTree records a condLiteralAdmissible untainted child of an and/or node as a classical literal, skips traversal through that child's quantum grammar, and requires the other child to provide the quantum predicate tree. It does not admit both children as literals. condLiteralAdmissible rejects predicted-quantum residue marks and tainted values, and the final literal-taint recheck preserves that obligation after later transformations. The stable scalar SSA bit can therefore appear in the sanctioned literal slot of the H-and-C predicate. The gate embedding keeps all input values and computes a fresh output; the mechanical adjoint receives the same literal SSA value and clears its flag before free. No runtime interpreter or execution history is needed.

The existing raw entry-PHI grammar fence in buildNegation need not be widened merely to support this separate mixed-tree literal path. If a Freeze reaches negation, the reviewed opaque xor(frozen,true) handling preserves its one stable bit and avoids unsupported ancestry traversal.

## Strong source-derived assertions

Keep the surviving outer classical branch and the exact pa/pb entry-PHI inputs. Bind the quantum Q allocation/rotation and exact ADD(Q,1), MUL(Q,3). Bind the classical predicate's stable scalar value where emitted and require forward/inverse literal operands to use that exact identity. The inner A merge must select ADD on C and MUL on its complement under H; AW must be add_hl(A,7). The outer merges must select A/AW on H and Q/0 on its complement. Bind the final add of those two outputs and its measure. No entry-PHI/classical predicate may be interpreted as a qubit handle. Match concrete ordering and owner-selected gate spelling from the one scoped green's output, rather than inventing an unobserved exact stream.

## Broader assertion edit review

The uniform seed corrections retain exact source widths (including f80 and i64), bind the emitted scalar freeze, and preserve the existing named quantum data operands, copy sources, constants and predicate polarity. QROM freezes belong before the table-handle allocation. Load literal checks preserve actual loads and name their stable SSA consumers; loop loads stay in the rolled loop, so a freeze does not pretend to prove memory access safety.

Both exact gate-equivalence pairs give their seed argument noundef in the original and handwritten twin. These fixtures compare the defined-input control-lowering axis. The contract change is symmetric and prevents only a irrelevant seed-stabilization text difference; bare-parameter poison coverage stays in the other fixtures. The source diff otherwise changes assertions, with the transient accidental volatile signature edit corrected.

Scope: analytic approval of source equations, the owning mixed-tree literal route, the current narrow core fix and assertion adaptation strategy. Exact acceptance-fixture stream assertions and test disposition remain the implementer's scoped green/final checkpoint responsibility. No additional reviewer execution is requested.
