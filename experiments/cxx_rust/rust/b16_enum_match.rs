#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[derive(Clone, Copy)] enum E { Lit(i32), Neg(i32), Pair(i16, i16), Nil }
#[inline(never)] fn ev(e: &E) -> i32 { match *e { E::Lit(v) => v, E::Neg(v) => v.wrapping_neg(), E::Pair(a, b) => a as i32 * b as i32, E::Nil => 0 } }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = q(x); let e = match v & 3 { 0 => E::Lit(v), 1 => E::Neg(y), 2 => E::Pair(v as i16, 3), _ => E::Nil }; ev(&e) }
