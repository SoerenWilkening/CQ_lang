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
	movsd	%xmm0, -16(%rsp)                ## 8-byte Spill
	movb	%sil, %cl
	movb	%dil, %dl
	xorps	%xmm1, %xmm1
	ucomisd	%xmm1, %xmm0
	seta	%al
	andb	%dl, %al
	orb	%cl, %al
	movsd	LCPI0_0(%rip), %xmm1            ## xmm1 = [1.0E+0,0.0E+0]
	addsd	%xmm1, %xmm0
	testb	$1, %al
	movsd	%xmm0, -8(%rsp)                 ## 8-byte Spill
	jne	LBB0_2
## %bb.1:                               ## %entry
	movsd	-16(%rsp), %xmm0                ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
	movsd	%xmm0, -8(%rsp)                 ## 8-byte Spill
LBB0_2:                                 ## %entry
	movsd	-8(%rsp), %xmm0                 ## 8-byte Reload
                                        ## xmm0 = mem[0],zero
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
	pushq	%rax
	.cfi_def_cfa_offset 16
	movb	%sil, %al
	movb	%al, 3(%rsp)                    ## 1-byte Spill
	movb	%dil, %al
	movb	%al, 2(%rsp)                    ## 1-byte Spill
	callq	_cqrt_alloc_f64
	movl	%eax, %edi
	movl	%edi, 4(%rsp)                   ## 4-byte Spill
	movsd	LCPI1_0(%rip), %xmm0            ## xmm0 = [2.5E-1,0.0E+0]
	callq	_cqrt_ry_f64
	movb	2(%rsp), %cl                    ## 1-byte Reload
	movb	3(%rsp), %al                    ## 1-byte Reload
	movl	4(%rsp), %edi                   ## 4-byte Reload
	movzbl	%cl, %esi
	andl	$1, %esi
	movzbl	%al, %edx
	andl	$1, %edx
	callq	___cq_q_bool_mix_001
	movl	%eax, %edi
	callq	_cqrt_measure_f64
	xorl	%eax, %eax
	popq	%rcx
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
	subq	$40, %rsp
	.cfi_def_cfa_offset 48
	movl	%edi, 12(%rsp)                  ## 4-byte Spill
	movb	%dl, %al
	movb	%al, 10(%rsp)                   ## 1-byte Spill
	movb	%sil, %al
	movb	%al, 11(%rsp)                   ## 1-byte Spill
	movsd	LCPI2_0(%rip), %xmm0            ## xmm0 = [1.0E+0,0.0E+0]
	callq	_cq_template_fadd_f64_hl
	movl	12(%rsp), %edi                  ## 4-byte Reload
	movl	%eax, 16(%rsp)                  ## 4-byte Spill
	xorps	%xmm0, %xmm0
	callq	_cq_template_fcmp_ogt_f64_hl
	movl	%eax, %edi
	movb	11(%rsp), %al                   ## 1-byte Reload
	movl	%edi, 20(%rsp)                  ## 4-byte Spill
	movzbl	%al, %esi
	andl	$1, %esi
	callq	_cq_template_and_i1_hl
	movl	%eax, %edi
	movb	10(%rsp), %al                   ## 1-byte Reload
	movl	%edi, 24(%rsp)                  ## 4-byte Spill
	movzbl	%al, %esi
	andl	$1, %esi
	callq	_cq_template_or_i1_hl
	movl	%eax, 28(%rsp)                  ## 4-byte Spill
	xorps	%xmm0, %xmm0
	callq	_cqrt_alloc_f64
	movl	16(%rsp), %esi                  ## 4-byte Reload
	movl	28(%rsp), %edi                  ## 4-byte Reload
	movl	%eax, %edx
	movl	%edx, 32(%rsp)                  ## 4-byte Spill
	callq	_cqrt_copy_f64_controlled
	movl	28(%rsp), %edi                  ## 4-byte Reload
	callq	_cqrt_x
	movl	12(%rsp), %esi                  ## 4-byte Reload
	movl	28(%rsp), %edi                  ## 4-byte Reload
	movl	32(%rsp), %edx                  ## 4-byte Reload
	callq	_cqrt_copy_f64_controlled
	xorps	%xmm0, %xmm0
	callq	_cqrt_alloc_f64
	movl	32(%rsp), %edi                  ## 4-byte Reload
	movl	%eax, %esi
	movl	%esi, 36(%rsp)                  ## 4-byte Spill
	callq	_cqrt_copy_f64
	movl	12(%rsp), %esi                  ## 4-byte Reload
	movl	28(%rsp), %edi                  ## 4-byte Reload
	movl	32(%rsp), %edx                  ## 4-byte Reload
	callq	_cqrt_copy_f64_controlled
	movl	28(%rsp), %edi                  ## 4-byte Reload
	callq	_cqrt_x
	movl	16(%rsp), %esi                  ## 4-byte Reload
	movl	28(%rsp), %edi                  ## 4-byte Reload
	movl	32(%rsp), %edx                  ## 4-byte Reload
	callq	_cqrt_copy_f64_controlled
	movb	10(%rsp), %al                   ## 1-byte Reload
	movl	24(%rsp), %esi                  ## 4-byte Reload
	movl	28(%rsp), %edi                  ## 4-byte Reload
	movzbl	%al, %edx
	andl	$1, %edx
	callq	_cq_template_or_i1_hl_unc
	movb	11(%rsp), %al                   ## 1-byte Reload
	movl	20(%rsp), %esi                  ## 4-byte Reload
	movl	24(%rsp), %edi                  ## 4-byte Reload
	movzbl	%al, %edx
	andl	$1, %edx
	callq	_cq_template_and_i1_hl_unc
	movl	12(%rsp), %esi                  ## 4-byte Reload
	movl	20(%rsp), %edi                  ## 4-byte Reload
	xorps	%xmm0, %xmm0
	callq	_cq_template_fcmp_ogt_f64_hl_unc
	movl	12(%rsp), %esi                  ## 4-byte Reload
	movl	16(%rsp), %edi                  ## 4-byte Reload
	movsd	LCPI2_0(%rip), %xmm0            ## xmm0 = [1.0E+0,0.0E+0]
	callq	_cq_template_fadd_f64_hl_unc
	movl	16(%rsp), %edi                  ## 4-byte Reload
	callq	_cqrt_free
	movl	20(%rsp), %edi                  ## 4-byte Reload
	callq	_cqrt_free
	movl	24(%rsp), %edi                  ## 4-byte Reload
	callq	_cqrt_free
	movl	28(%rsp), %edi                  ## 4-byte Reload
	callq	_cqrt_free
	movl	32(%rsp), %edi                  ## 4-byte Reload
	callq	_cqrt_free
	movl	36(%rsp), %eax                  ## 4-byte Reload
	addq	$40, %rsp
	retq
	.cfi_endproc
                                        ## -- End function
.subsections_via_symbols
