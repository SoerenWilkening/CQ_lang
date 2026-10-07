	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 16, 0
	.section	__TEXT,__literal8,8byte_literals
	.p2align	3, 0x0                          ## -- Begin function bool_mix
LCPI0_0:
	.quad	0x3ff0000000000000              ## double 1
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_bool_mix
	.p2align	4, 0x90
_bool_mix:                              ## @bool_mix
	.cfi_startproc
## %bb.0:                               ## %entry
	movsd	LCPI0_0(%rip), %xmm1            ## xmm1 = [1.0E+0,0.0E+0]
	addsd	%xmm0, %xmm1
	testl	%esi, %esi
	movapd	%xmm1, %xmm3
	jne	LBB0_2
## %bb.1:                               ## %entry
	movapd	%xmm0, %xmm3
LBB0_2:                                 ## %entry
	xorpd	%xmm2, %xmm2
	cmpltsd	%xmm0, %xmm2
	movapd	%xmm2, %xmm0
	andnpd	%xmm3, %xmm0
	testl	%edi, %edi
	jne	LBB0_4
## %bb.3:                               ## %entry
	movapd	%xmm3, %xmm1
LBB0_4:                                 ## %entry
	andpd	%xmm1, %xmm2
	orpd	%xmm2, %xmm0
	retq
	.cfi_endproc
                                        ## -- End function
	.section	__TEXT,__literal8,8byte_literals
	.p2align	3, 0x0                          ## -- Begin function main
LCPI1_0:
	.quad	0x3fd0000000000000              ## double 0.25
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_main
	.p2align	4, 0x90
_main:                                  ## @main
	.cfi_startproc
## %bb.0:                               ## %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -32
	.cfi_offset %r14, -24
	.cfi_offset %rbp, -16
	movl	%esi, %ebx
	movl	%edi, %ebp
	callq	_cqrt_alloc_f64
	movl	%eax, %r14d
	movsd	LCPI1_0(%rip), %xmm0            ## xmm0 = [2.5E-1,0.0E+0]
	movl	%eax, %edi
	callq	_cqrt_ry_f64
	movl	%r14d, %edi
	movl	%ebp, %esi
	movl	%ebx, %edx
	callq	___cq_q_bool_mix_001
	movl	%eax, %edi
	callq	_cqrt_measure_f64
	xorl	%eax, %eax
	popq	%rbx
	popq	%r14
	popq	%rbp
	retq
	.cfi_endproc
                                        ## -- End function
	.section	__TEXT,__literal8,8byte_literals
	.p2align	3, 0x0                          ## -- Begin function __cq_q_bool_mix_001
LCPI2_0:
	.quad	0x3ff0000000000000              ## double 1
	.section	__TEXT,__text,regular,pure_instructions
	.p2align	4, 0x90
___cq_q_bool_mix_001:                   ## @__cq_q_bool_mix_001
	.cfi_startproc
## %bb.0:                               ## %entry
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$24, %rsp
	.cfi_def_cfa_offset 80
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movl	%edx, %r12d
	movl	%edx, 12(%rsp)                  ## 4-byte Spill
	movl	%esi, %r15d
	movl	%esi, 20(%rsp)                  ## 4-byte Spill
	movl	%edi, %ebx
	movsd	LCPI2_0(%rip), %xmm0            ## xmm0 = [1.0E+0,0.0E+0]
	callq	_cq_template_fadd_f64_hl
	movl	%eax, %ebp
	xorps	%xmm0, %xmm0
	movl	%ebx, %edi
	callq	_cq_template_fcmp_ogt_f64_hl
	movl	%eax, %r14d
	movl	%eax, %edi
	movl	%r15d, %esi
	callq	_cq_template_and_i1_hl
	movl	%eax, %r15d
	movl	%eax, %edi
	movl	%r12d, %esi
	callq	_cq_template_or_i1_hl
	movl	%eax, %r12d
	xorps	%xmm0, %xmm0
	callq	_cqrt_alloc_f64
	movl	%eax, %r13d
	movl	%r12d, %edi
	movl	%ebp, %esi
	movl	%eax, %edx
	callq	_cqrt_copy_f64_controlled
	movl	%r12d, %edi
	callq	_cqrt_x
	movl	%r12d, %edi
	movl	%ebx, %esi
	movl	%r13d, %edx
	callq	_cqrt_copy_f64_controlled
	xorps	%xmm0, %xmm0
	callq	_cqrt_alloc_f64
	movl	%eax, 16(%rsp)                  ## 4-byte Spill
	movl	%r13d, %edi
	movl	%eax, %esi
	callq	_cqrt_copy_f64
	movl	%r12d, %edi
	movl	%ebx, %esi
	movl	%r13d, %edx
	callq	_cqrt_copy_f64_controlled
	movl	%r12d, %edi
	callq	_cqrt_x
	movl	%r12d, %edi
	movl	%ebp, %esi
	movl	%r13d, %edx
	callq	_cqrt_copy_f64_controlled
	movl	%r12d, %edi
	movl	%r15d, %esi
	movl	12(%rsp), %edx                  ## 4-byte Reload
	callq	_cq_template_or_i1_hl_unc
	movl	%r15d, %edi
	movl	%r14d, %esi
	movl	20(%rsp), %edx                  ## 4-byte Reload
	callq	_cq_template_and_i1_hl_unc
	xorps	%xmm0, %xmm0
	movl	%r14d, %edi
	movl	%ebx, %esi
	callq	_cq_template_fcmp_ogt_f64_hl_unc
	movl	%ebp, %edi
	movl	%ebx, %esi
	movsd	LCPI2_0(%rip), %xmm0            ## xmm0 = [1.0E+0,0.0E+0]
	callq	_cq_template_fadd_f64_hl_unc
	movl	%ebp, %edi
	callq	_cqrt_free
	movl	%r14d, %edi
	callq	_cqrt_free
	movl	%r15d, %edi
	callq	_cqrt_free
	movl	%r12d, %edi
	callq	_cqrt_free
	movl	%r13d, %edi
	callq	_cqrt_free
	movl	16(%rsp), %eax                  ## 4-byte Reload
	addq	$24, %rsp
	popq	%rbx
	popq	%r12
	popq	%r13
	popq	%r14
	popq	%r15
	popq	%rbp
	retq
	.cfi_endproc
                                        ## -- End function
.subsections_via_symbols
