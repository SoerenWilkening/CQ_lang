/* cq kernel passthrough: host shim for Linux's <asm/types.h> (x86-64, LP64) */
#ifndef CQ_HOST_ASM_TYPES_H
#define CQ_HOST_ASM_TYPES_H
typedef signed char __s8;   typedef unsigned char __u8;
typedef signed short __s16; typedef unsigned short __u16;
typedef signed int __s32;   typedef unsigned int __u32;
typedef signed long long __s64; typedef unsigned long long __u64;
#endif
