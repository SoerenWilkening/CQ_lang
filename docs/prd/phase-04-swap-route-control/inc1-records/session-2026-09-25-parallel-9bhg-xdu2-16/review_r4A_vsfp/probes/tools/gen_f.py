import pathlib
src = pathlib.Path(__file__).parent / "src"
HDR = '''target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @atoi(ptr nocapture noundef)
declare double @cq_theta_f64(double noundef, double noundef)
declare double @cq_measure_f64(double noundef)
declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)
'''
def main(call, rty):
    meas = ("  %mr = tail call double @cq_measure_f64(double noundef %r)\n  %mri = fptosi double %mr to i32\n" if rty == "double"
            else "  %mri = tail call i32 @cq_measure_si32(i32 noundef %r)\n")
    return f'''define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) {{
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = and i32 %5, 7
  %7 = uitofp nneg i32 %6 to double
  %zd = tail call double @cq_theta_f64(double noundef %7, double noundef 3.000000e-01)
  %zi = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 3.500000e-01)
  %qd = tail call double @cq_theta_f64(double noundef 1.500000e+00, double noundef 5.000000e-01)
{call}
  %q2 = tail call double @cq_theta_f64(double noundef %qd, double noundef 0x3FE6666666666666)
  %mq = tail call double @cq_measure_f64(double noundef %q2)
  %mqi = fptosi double %mq to i32
{meas}  %mzd = tail call double @cq_measure_f64(double noundef %zd)
  %mzdi = fptosi double %mzd to i32
  %mzi = tail call i32 @cq_measure_si32(i32 noundef %zi)
  %s1 = add nsw i32 %mqi, %mri
  %s2 = add nsw i32 %s1, %mzdi
  %s3 = add nsw i32 %s2, %mzi
  ret i32 %s3
}}
'''
GI_DEAD = '''define i32 @g(double noundef %x, i32 noundef %y) {
  %c = fcmp ogt double %x, 3.000000e+00
  br i1 %c, label %e, label %m
e:
  br label %m
m:
  %r = mul nsw i32 %y, 3
  ret i32 %r
}'''
GI_T = '''define i32 @g(i32 noundef %y) {
  %r = mul nsw i32 %y, 3
  ret i32 %r
}'''
GD_DEAD = '''define double @gd(double noundef %x, double noundef %y) {
  %c = fcmp ogt double %x, 3.000000e+00
  br i1 %c, label %e, label %m
e:
  br label %m
m:
  %r = fmul double %y, 3.000000e+00
  ret double %r
}'''
GD_T = '''define double @gd(double noundef %y) {
  %r = fmul double %y, 3.000000e+00
  ret double %r
}'''
def w(n, s): (src / n).write_text(s)
# N4: fp dead slot, integer return, outer dead fmul feeding the inner fp dead slot
w("N4.ll", HDR + main("  %r = tail call i32 @h(double noundef %qd, i32 noundef %zi)", "i32") + '''
define i32 @h(double noundef %a, i32 noundef %b) {
  %t = fmul double %a, 2.000000e+00
  %r = tail call i32 @g(double noundef %t, i32 noundef %b)
  ret i32 %r
}
''' + GI_DEAD + "\n")
w("N4T.ll", HDR + main("  %r = tail call i32 @h(i32 noundef %zi)", "i32") + '''
define i32 @h(i32 noundef %b) {
  %r = tail call i32 @g(i32 noundef %b)
  ret i32 %r
}
''' + GI_T + "\n")
# N7: fp dead slot, fp RETURN at both levels (inner call REBUILT by retargetSite), direct param pass-through
w("N7.ll", HDR + main("  %r = tail call double @h(double noundef %qd, double noundef %zd)", "double") + '''
define double @h(double noundef %a, double noundef %b) {
  %r = tail call double @gd(double noundef %a, double noundef %b)
  ret double %r
}
''' + GD_DEAD + "\n")
w("N7T.ll", HDR + main("  %r = tail call double @h(double noundef %zd)", "double") + '''
define double @h(double noundef %b) {
  %r = tail call double @gd(double noundef %b)
  ret double %r
}
''' + GD_T + "\n")
# N8: fp RETURN, dead fp instruction in the outer feeding the rebuilt inner call's dead slot
w("N8.ll", HDR + main("  %r = tail call double @h(double noundef %qd, double noundef %zd)", "double") + '''
define double @h(double noundef %a, double noundef %b) {
  %t = fadd double %a, 1.000000e+00
  %r = tail call double @gd(double noundef %t, double noundef %b)
  ret double %r
}
''' + GD_DEAD + "\n")
