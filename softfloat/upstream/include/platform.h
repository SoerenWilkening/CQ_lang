
/*============================================================================

This C header file is part of the SoftFloat IEEE Floating-Point Arithmetic
Package, Release 3e, by John R. Hauser.

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 The Regents of the
University of California.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
    this list of conditions, and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions, and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the University nor the names of its contributors may
    be used to endorse or promote products derived from this software without
    specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS "AS IS", AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ARE
DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=============================================================================*/

/*----------------------------------------------------------------------------
*----------------------------------------------------------------------------*/
#define LITTLEENDIAN 1

/*----------------------------------------------------------------------------
*----------------------------------------------------------------------------*/
#ifdef __GNUC_STDC_INLINE__
#define INLINE static inline
#else
#define INLINE extern inline
#endif

/*----------------------------------------------------------------------------
*----------------------------------------------------------------------------*/
#define SOFTFLOAT_BUILTIN_CLZ 1
#define SOFTFLOAT_INTRINSIC_INT128 1
#include "opts-GCC.h"


/* CQ: patched by softfloat/tools/patch_upstream.py */
/* The reciprocal tables of s_approxRecip_1Ks.c and s_approxRecipSqrt_1Ks.c as selects: entry i of a
| 16-entry table is bits 16*(i%4).. of packed word i/4. */
#ifndef softfloat_cq_tbl16_defined
#define softfloat_cq_tbl16_defined 1
#include <stdint.h>
static inline uint16_t
 softfloat_cq_tbl16( uint64_t w0, uint64_t w1, uint64_t w2, uint64_t w3, unsigned int i )
{
    uint64_t w = (i & 8) ? ((i & 4) ? w3 : w2) : ((i & 4) ? w1 : w0);
    return (uint16_t) (w>>((i & 3) * 16));
}
#define softfloat_approxRecip_1k0s_at( i ) softfloat_cq_tbl16( UINT64_C( 0xD76FE363F0BEFFC4 ), UINT64_C( 0xB201BA16C2F0CCAD ), UINT64_C( 0x97A69D7AA3C6AA97 ), UINT64_C( 0x8417887E8D32923C ), (i) )
#define softfloat_approxRecip_1k1s_at( i ) softfloat_cq_tbl16( UINT64_C( 0xAC77BFA1D62CF0F1 ), UINT64_C( 0x76BA81858DDB9C0A ), UINT64_C( 0x56B15D5C64D46D3B ), UINT64_C( 0x421146794B5550B6 ), (i) )
#define softfloat_approxRecipSqrt_1k0s_at( i ) softfloat_cq_tbl16( UINT64_C( 0xF11CAA7DFFABB4C9 ), UINT64_C( 0xDA299A43E4C7A1C5 ), UINT64_C( 0xC8B78DEDD0E593B5 ), UINT64_C( 0xBAE18424C16D88C6 ), (i) )
#define softfloat_approxRecipSqrt_1k1s_at( i ) softfloat_cq_tbl16( UINT64_C( 0xC62D8C21EA42A5A5 ), UINT64_C( 0x94B66928AA7F788F ), UINT64_C( 0x74E252A683355CC7 ), UINT64_C( 0x5EFD432B68FE4A3E ), (i) )
#endif
