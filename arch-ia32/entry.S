#include <arch/multiboot.h>
#include <arch/gdt.h>
#include <arch/page.h>
.section .text.init
.text

.globl	_start
_start:
	jmp	multiboot_entry

.align	4
multiboot_header:
	.long	MULTIBOOT_HEADER_MAGIC
	.long	MULTIBOOT_HEADER_FLAGS
	.long	-(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

multiboot_entry:
	movl $__init_stack_top_pa, %esp

	/* Reset EFLAGS */
	pushl	$0
	popf

	/* Parameters for multiboot_check */
	pushl	%ebx	/* mbi structure */
	pushl	%eax	/* magic */

	/* Check multiboot structures */
	call	multiboot_check
	test	$0x0, %eax
	jne	2f

	/* Our pagetables are now fixed up so we can use linked addresses
	 * within the first 4MB (assumes the whole kernel loads
	 * within 4MB - should be OK for some time...)
	 */

	/* Enable paging */
	movl	%cr0,%edx
	orl	$0x80010000,%edx
	movl	%edx,%cr0

	/* Fixup stack pointer */
	addl	$PAGE_OFFSET,%esp

	/* Load in the GDT */
	lgdt	loadgdt

	/* Reload EIP */
	ljmp	$__KERNEL_CS, $1f

	/* Reload segment selectors */
1:
	movl	$__KERNEL_DS, %eax
	movl	%eax, %ds
	movl	%eax, %es
	movl	%eax, %fs
	movl	%eax, %gs
	movl	%eax, %ss

	/* Main part of kernel */
	popl	%eax
	popl	%ebx
	addl	$PAGE_OFFSET,%ebx
	pushl	%ebx
	call	setup

2:
	hlt
	jmp	2b
