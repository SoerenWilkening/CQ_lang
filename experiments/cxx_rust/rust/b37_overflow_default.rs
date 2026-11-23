#![allow(unused_imports, dead_code)]
include!("../cq.rs");
// plain arithmetic operators (release semantics here; OVF=on adds overflow panics)
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = q(x as i16) as i32; v * 3 + (y & 255) - v * v / 7 }
