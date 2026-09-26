import sys, pathlib
src = pathlib.Path(__file__).parent / "src"
N1 = (src / "N1.ll").read_text().splitlines()
HDR = "\n".join(N1[0:7])
PRE = "\n".join(N1[7:14])
POST = "\n".join(N1[15:23])
G_DEAD = "\n".join(N1[N1.index("define i32 @g(i32 noundef %x, i32 noundef %y) {"):])
G_T = """define i32 @g(i32 noundef %y) {
  %r = mul nsw i32 %y, 3
  ret i32 %r
}"""
def mk(name, call, funcs, g=None, hdr=HDR, pre=PRE, post=POST):
    body = [hdr, pre, call, post, funcs, g if g is not None else ""]
    (src / name).write_text("\n".join(body) + "\n")
