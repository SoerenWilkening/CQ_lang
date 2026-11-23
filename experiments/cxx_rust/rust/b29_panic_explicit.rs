#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = q(x); if v == 77 { panic!("boom {}", y); } v.wrapping_mul(2) }
