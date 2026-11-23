// The CQ user surface for Rust: include!("cq.rs") in a program. q(v): v made quantum.
#[allow(dead_code)]
mod cq {
    extern "C" {
        fn cq_theta_i1(x: bool, a: f64) -> bool; fn cq_theta_ui8(x: u8, a: f64) -> u8; fn cq_theta_si8(x: i8, a: f64) -> i8;
        fn cq_theta_ui16(x: u16, a: f64) -> u16; fn cq_theta_si16(x: i16, a: f64) -> i16; fn cq_theta_si32(x: i32, a: f64) -> i32;
        fn cq_theta_ui32(x: u32, a: f64) -> u32; fn cq_theta_sl(x: i64, a: f64) -> i64; fn cq_theta_ul(x: u64, a: f64) -> u64;
        fn cq_theta_f32(x: f32, a: f64) -> f32; fn cq_theta_f64(x: f64, a: f64) -> f64;
        fn cq_measure_ui8(x: u8) -> u8; fn cq_phi(a: f64); fn __cq_invert_begin(); fn __cq_invert_end();
    }
    pub trait Q: Sized { fn theta(self, a: f64) -> Self; }
    macro_rules! t { ($($f:ident $t:ty),*) => { $(impl Q for $t { #[inline(always)] fn theta(self, a: f64) -> $t { unsafe { $f(self, a) } } })* } }
    t!(cq_theta_i1 bool, cq_theta_ui8 u8, cq_theta_si8 i8, cq_theta_ui16 u16, cq_theta_si16 i16, cq_theta_si32 i32, cq_theta_ui32 u32,
       cq_theta_sl i64, cq_theta_ul u64, cq_theta_f32 f32, cq_theta_f64 f64);
    #[inline(always)] pub fn q<T: Q>(v: T) -> T { v.theta(0.5) }
    #[inline(always)] pub fn theta<T: Q + Copy>(v: &mut T, a: f64) { *v = v.theta(a); }
    #[inline(always)] pub fn phi(a: f64) { unsafe { cq_phi(a) } }
    #[inline(always)] pub fn measure(x: u8) -> u8 { unsafe { cq_measure_ui8(x) } }
    #[inline(always)] pub fn inverted<R>(f: impl FnOnce() -> R) -> R {
        unsafe { __cq_invert_begin(); core::arch::asm!("", options(nostack, preserves_flags)); let r = f(); core::arch::asm!("", options(nostack, preserves_flags)); __cq_invert_end(); r }
    }
}
use cq::*;
