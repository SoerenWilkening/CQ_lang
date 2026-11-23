#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = q(x); let o = if v > 5 { Some(v) } else { None }; o.unwrap().wrapping_mul(y) }
