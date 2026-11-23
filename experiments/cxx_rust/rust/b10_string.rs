#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut s = String::from("hello quantum"); s.push(((q(x as u8) & 63) + 32) as char); s.push_str("cd"); let mut h = 0i32; for b in s.bytes() { h = h.wrapping_mul(31).wrapping_add(b as i32); } h }
