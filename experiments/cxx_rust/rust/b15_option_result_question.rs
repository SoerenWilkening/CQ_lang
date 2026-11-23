#![allow(unused_imports, dead_code)]
include!("../cq.rs");
fn dv(a: i32, b: i32) -> Option<i32> { a.checked_div(b) }
fn run(a: i32, b: i32, c: i32) -> Result<i32, i32> { let t = dv(a, b).ok_or(-7)?; let u = dv(t, c).ok_or(-8)?; Ok(t.wrapping_add(u)) }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { match run(y, q(x) & 3, 2) { Ok(v) => v, Err(e) => e } }
