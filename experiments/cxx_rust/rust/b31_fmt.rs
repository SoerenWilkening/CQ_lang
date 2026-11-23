#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let s = format!("v={}", q(x & 15)); s.as_bytes()[2] as i32 + s.len() as i32 * 10 + y }
