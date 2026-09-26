"""polenv.py — the allocator policy of a BIN:MODE spec, as an environment.
MODE: system | lifo | nofree   -> CQ_OPT_DEBUG_ALLOC (needs a debugalloc build)
      rb8-<p>                  -> r1B's INDEPENDENT interposer (any unmodified
                                  binary): DYLD_INSERT_LIBRARIES + RB8_ALLOC=<p>
                                  with <p> in lifo|fifo|lifo2|nofree|rand."""
import os

T = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r"
DYLIB = f"{T}/rb8_interpose.dylib"


def env_for(mode):
    env = dict(os.environ)
    for k in ("CQ_OPT_DEBUG_ALLOC", "RB8_ALLOC", "DYLD_INSERT_LIBRARIES", "RB8_SEED"):
        env.pop(k, None)
    if mode == "system":
        pass
    elif mode.startswith("rb8-"):
        env["DYLD_INSERT_LIBRARIES"] = DYLIB
        env["RB8_ALLOC"] = mode[4:]
    else:
        env["CQ_OPT_DEBUG_ALLOC"] = mode
    return env
