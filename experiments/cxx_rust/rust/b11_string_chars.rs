#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut b = *b"hexxo w"; b[3] = (q(x as u8) & 63) + 32; let s = core::str::from_utf8(&b).unwrap_or(""); s.chars().filter(|c| c.is_alphabetic()).count() as i32 + s.len() as i32 * 10 }
