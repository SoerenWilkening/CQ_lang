"""Batch speculative scrub-guard queries in one compiler translation unit.

Only compiler-resolved aliases and definitions from this pass are reused. A
query missing from the dump falls back to the ordinary identity probe. Template
instances are never speculated: asking their members can instantiate a primary
that the actual header only points at.
"""
import os
import re


def record_identity(api, nodes, target, qname, force=False):
    """Resolve an alias through its RecordType's AST id, never a printed name."""
    stack = list(reversed(target.get("inner") or []))
    while stack:
        node = stack.pop()
        if node.get("kind") == "TemplateArgument":
            continue
        kind = node.get("kind")
        if kind in ("RecordType", "EnumType") and isinstance(node.get("decl"), dict):
            if kind == "EnumType":
                return "enum", None
            ident = node["decl"].get("id")
            if ident is None:
                return "error", f"`{qname}` does not name a record or enum"
            same = [n for n in nodes if n.get("id") == ident
                    and n.get("kind") in api.RECORD_KINDS]
            definitions = [n for n in same if n.get("completeDefinition")]
            if definitions:
                return "record", definitions
            if not force and any(n.get("kind") == "ClassTemplateSpecializationDecl" for n in same):
                return "uninstantiated", None
            return None
        stack.extend(reversed(node.get("inner") or []))
    return "error", f"`{qname}` does not name a record or enum"


def alias_identity(api, nodes, alias, qname, query_nodes):
    target = next((n for n in query_nodes if n.get("kind") == "TypeAliasDecl"
                   and n.get("name") == alias), None)
    return record_identity(api, nodes, target, qname) if target is not None else None


def identify_root(api, ctx, state):
    """Ask known non-template records and their member types alongside the root.

    The guesses contain no previous AST nodes or verdicts. Their aliases and
    member questions are compiled again against this pass's header and flags.
    Errors on guessed lines discard those answers; any other error, missing
    root, or incomplete dump invokes the existing root probe and retry path.
    """
    with api._SPEC_LOCK:
        known = {q: set(pairs) for q, pairs in api._SPEC.items() if "<" not in q}
    known.setdefault(api.ROOT_RECORD, set())
    names = sorted(known)
    pairs = sorted(set().union(*known.values()))
    specs = [(api._new_k(state, f"{p}.{n}"), (p, n)) for p, n in pairs]
    aliases = {q: f"cq_guard_batch_id_{i}" for i, q in enumerate(names)}
    lines = api._head(["cq_guard_batch"] + list(aliases.values())
                      + [api._spell(q) for q in names]
                      + [f"{p}.{n}" for _, (p, n) in specs])
    speculative = {}
    for k, (p, n) in specs:
        lines.append(api._rob_line(k, f"{p}.{n}"))
        speculative[len(lines)] = ("member", k)
    for q, alias in aliases.items():
        lines.append(f"namespace cq_guard_batch {{ using {alias} = {api._spell(q)}; }}")
        if q != api.ROOT_RECORD:
            speculative[len(lines)] = ("identity", q)
    result, docs, tu = api._dump(ctx, "\n".join(lines) + "\n", "cq", "cq_guard_batch")
    errors = api._error_lines(result.stderr, tu)
    bad = {speculative[ln] for ln in errors if ln in speculative}
    basename = re.escape(os.path.basename(tu))
    other = [line for line in api._first_errors(result.stderr, len(result.stderr.splitlines()))
             if not any(re.search(basename + f":{ln}:", line) for ln in speculative)]
    nodes = list(api._iter_nodes(docs))
    # The broad dump also contains project aliases named c0, c1, etc. Only
    # helper namespaces supply query answers; record definitions still come
    # from the full dump and are joined to those answers by compiler AST id.
    query_nodes = list(api._iter_nodes([d for d in docs if d.get("kind") == "NamespaceDecl"
                                       and d.get("name") == "cq_guard_batch"]))
    root = alias_identity(api, nodes, aliases[api.ROOT_RECORD], api.ROOT_RECORD, query_nodes)
    if other or root is None or root[0] != "record" or len(root[1]) != 1:
        return api._identify(ctx, api.ROOT_RECORD, 0, state=state)
    answers = api._rob_results([d for d in docs if d.get("kind") == "NamespaceDecl"
                               and d.get("name") == "cq_guard_canon"])
    for k, pair in specs:
        if ("member", k) not in bad and k in answers:
            state["rob_cache"][pair] = k, answers[k]
    for q, alias in aliases.items():
        if q == api.ROOT_RECORD or ("identity", q) in bad:
            continue
        answer = alias_identity(api, nodes, alias, q, query_nodes)
        if answer is not None:
            ctx.batch_identities[q] = answer
    return root[0], root[1], []
