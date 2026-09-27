# ---------------------------------------------------------------- write
def write(e):
    mod = pathlib.Path(e["module"])
    rc, out, err = run(BIN, mod)
    drops = [l for l in err.splitlines() if l.startswith("CQ_DEADARG_DBG:")]
    hdr = e["text"]
    if e["src"]:
        hdr = hdr.replace("{src}", src_block(e["src"]))
    hdr = hdr.rstrip("\n")
    body = mod.read_text()
    lines = [hdr]
    if e["kind"] == "decline":
        if rc == 0:
            raise SystemExit(f"{e['name']}: expected a decline, got an accept")
        errl = [l for l in err.splitlines() if "error:" in l][0]
        msg = errl.split(": ", 2)[-1] if "in function" not in errl else errl[errl.index("in function"):]
        lines += [";", "; RUN: env CQ_DEADARG_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o /dev/null 2>&1 \\",
                  "; RUN:   | %filecheck %s"]
        for d in drops:
            lines.append(f"; CHECK: {d}")
        if not drops:
            lines.append("; CHECK-NOT: CQ_DEADARG_DBG")
        lines.append(f"; CHECK: error: {{{{.*}}}}{msg.split('): ', 1)[-1] if '): ' in msg else msg}")
    else:
        if rc != 0:
            raise SystemExit(f"{e['name']}: expected an accept, got: {err}")
        fb = fn_body(out, e["fn"])
        cs = calls(fb)
        orc, oout, oerr = run(ORA, mod)
        neg = []
        if orc == 0:
            ob = fn_body(oout, e["fn"])
            mine = {callee(c) for c in cs}
            neg = sorted({callee(c) for c in calls(ob)} - mine - {None})
        lines += [";", "; RUN: env CQ_DEADARG_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err",
                  "; RUN: %filecheck %s < %t.cqd0.ll"]
        if neg:
            lines.append("; RUN: %filecheck %s --check-prefix=NEG < %t.cqd0.ll")
        lines.append("; RUN: %filecheck %s --check-prefix=" + ("DROP < %t.err" if drops else "NODROP --allow-empty < %t.err"))
        lines.append(";")
        lines.append("; The ordered call sequence of @" + e["fn"] + " (derived from the lowered module; SSA names")
        lines.append("; wildcarded, constants — every dropped `0` and every angle — kept):")
        lines.append("; Between consecutive matches NO other runtime/clone call may appear, so the")
        lines.append("; runtime stream is pinned EXACTLY, not as a subsequence.")
        NOT = "; CHECK-NOT: call {{.*}}@{{(cqrt_|cq_template_|__cq_q_)}}"
        lines.append(f"; CHECK-LABEL: define {{{{.*}}}}@{e['fn']}(")
        lines.append(NOT)
        for c in cs:
            lines.append(f"; CHECK: call {pat(c)}")
            lines.append(NOT)
        lines.append("; CHECK: ret i32")
        if neg:
            lines.append(";")
            lines.append("; Callees the ORACLE emitted in @" + e["fn"] + " and this lowering must not:")
            lines.append(f"; NEG-LABEL: define {{{{.*}}}}@{e['fn']}(")
            for n in neg:
                lines.append(f"; NEG-NOT: @{n}(")
            lines.append("; NEG: ret i32")
        if drops:
            for d in drops:
                lines.append(f"; DROP: {d}")
        else:
            lines.append("; NODROP-NOT: CQ_DEADARG_DBG")
        if e["name"] in NONULL:
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: %filecheck %s --check-prefix=NONULL < %t.cqd0.ll")
            lines.append(";")
            lines.append("; No pointer argument is neutralised to null (bd 91k9):")
            lines.append("; NONULL-NOT: align {{[0-9]+}} null")
            lines.append("; NONULL-NOT: nonnull null")
        if e["name"] in CLONE_NOTPL:
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: %filecheck %s --check-prefix=CLONE < %t.cqd0.ll")
            lines.append(";")
            lines.append("; The clone body reads nothing the caller did not pass: no template call (bd sqjq):")
            lines.append(f"; CLONE-LABEL: define {{{{.*}}}}@{CLONE_NOTPL[e['name']]}")
            lines.append("; CLONE-NOT: cq_template_")
            if e["name"] in INNER_ZERO:
                lines.append("; CLONE: call i32 @__cq_q_g_{{[0-9]+}}(i32 noundef 0,")
                lines.append("; CLONE-NOT: cq_template_")
            lines.append("; CLONE: ret ")
        if e["name"] in ("lowering_volatile_alloca_fold_cascade_uaf.ll",
                         "lowering_volatile_arm_fold_cascade_classical.ll",
                         "lowering_volatile_arm_fold_cascade_tainted.ll",
                         "lowering_volatile_arm_fold_cascade_live_condition.ll",
                         "lowering_volatile_globalfold_cascade.ll"):
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: env CQ_OPT_DEBUG_ALLOC=nofree %debugalloc-cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.nofree.ll")
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 2,
                         "; RUN: %filecheck %s < %t.nofree.ll")
        if e["name"] == "spec_accept_phantom_arg_read_measured_record.ll":
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: %filecheck %s --check-prefix=NOWARN --allow-empty < %t.err")
            lines.append("; No lyyf-(B) warning (the twin emits none):")
            lines.append("; NOWARN-NOT: warning:")
        if e["name"] == "spec_accept_dropped_arg_range_attr_stripped.ll":
            lines.insert(lines.index("; RUN: %filecheck %s < %t.cqd0.ll") + 1,
                         "; RUN: %filecheck %s --check-prefix=ATTR < %t.cqd0.ll")
            lines.append("; No `range` survives on `@h`'s parameter (it precedes @main) nor at the call:")
            lines.append("; ATTR-NOT: range(i32 1, 100)")
            lines.append("; ATTR: call i32 @h(i32 0, i32 %m)")
    (T / e["name"]).write_text("\n".join(lines) + "\n\n" + body)
    print("wrote", e["name"], e["kind"], f"calls={len(fb) if e['kind']!='decline' else '-'}", f"drops={len(drops)}")


only = set(sys.argv[1:])
for e in ENTRIES:
    if only and e["name"] not in only:
        continue
    write(e)
