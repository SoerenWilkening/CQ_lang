#![allow(unused_imports, dead_code)]
include!("../cq.rs");
// Rust's float casts saturate: llvm.fptosi.sat
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = q(x as f64) * 1.5e7; (v as i32).wrapping_add((v as f32 as u8) as i32) }
