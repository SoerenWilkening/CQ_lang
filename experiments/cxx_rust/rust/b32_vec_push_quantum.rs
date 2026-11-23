#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = q(x); let mut a = Vec::with_capacity(4); a.push(1); if v > 3 { a.push(v); } if v & 1 == 1 { a.push(y); } a.iter().fold(0i32, |s, e| s.wrapping_mul(2).wrapping_add(*e)) }
