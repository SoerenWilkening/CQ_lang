#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let a = (q(x as u64) as u128) * (y as u32 as u128 + 12345678901234567u128); ((a >> 64) as i32) ^ (a as i32) }
