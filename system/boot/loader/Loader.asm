

include '..\..\Ampere.inc'

ORG 0x8200
$Entry Loader.main

public class Loader:
{
	
	public Loader_16 oldInfo = 0
	public int idt.length    = 0
	public long idt          = 0
	public int tss.length    = 0
	public long tss          = 0
	
	public void Loader()
	\{
		Prologue
		
		Set    oldInfo, rdi
		
		mov    rsi, [rdi+Loader_16.memorySize]
		lea    rdi, [rdi+Loader_16.acpiMemoryMap.length]
		Call Memory.setBitmap
		
		Call setIdt
		
		Call setTss
		
		Call disablePic
		
		return
	\}
	
	public static void main()
	\{
		USE16
		Call Loader_16.setGateA20 ; /* Stack Unsafe Method */
		
;   /**
;    * The top 4B contains garbage.
;    * Override the top 4B for stack consistency. 
;    */
		xor    eax, eax
		mov    [bp- 4], eax ; /* Critical instruction. */
		
		mov    ss, ax
		add    esp, 0x00090000
		add    ebp, esp
		
		sub    esp, 8
		
		mov    eax, dword[@DynamicSize]
;   /**
;    * The top 4B contains the value specified in the
;    * critical instruction (ZERO).
;    */
		mov    [ebp- 8], eax
		mov    ebx, eax
		add    eax, 7 * 8
		mov    dword[@DynamicSize], eax
		
		jmp Loader_16.Loader_16
	.x64Mode:
		USE64
		Loader loader
		Prologue
		
		mov    rdi, rbx
		
		mov    rax, [@DynamicSize]
		mov    rbx, rax
		Set    loader, rax
		add    rax, sizeof.Loader * 8
		mov    [@DynamicSize], rax
		Call Loader
		sti
		hlt
		
		mov    edi, 0xFEE00000
		lea    rsi, [rdi+ 3]
		Call Memory.setPageTable
		
		Mkstr hello = 'Hello!', 10, \
		              'We are preparing everthing to you.'
		mov    rdi, hello
		Call Screen.println
		Halt
	\}
	
	public void disablePic()
	\{
		Prologue
		
		mov    al, 0x11
		out    0x20, al
		out    0xA0, al
		
		mov    al, 0x20
		out    0x21, al
		mov    al, 0x28
		out    0xA1, al
		
		mov    al, 4
		out    0x21, al
		mov    al, 2
		out    0xA1, al
		
		mov    al, 1
		out    0x21, al
		out    0xA1, al
		
		mov    al, 0xFF
		out    0x21, al
		out    0xA1, al
		
		return
	\}
	
	public void setTss()
	\{
		long a, b
		Prologue
		
		mov    rax, [@DynamicSize]
		mov    rsi, 0x1000
		xor    rdx, rdx
		div    rsi
		
		and    rdx, rdx
		jz     .J0
		inc    rax
	.J0:
		mul    rsi
		mov    rcx, rax
		add    rax, 0x2068
		mov    [@DynamicSize], rax
		
		Set    tss.length, 0x2068, qword
		Set    tss, rcx
		
		mov    dword[rdi+  4], 0x00080000
		mov     word[rdi+104], 0x0068
		
		Get    eax, tss.length
		and    eax, 0xFFFF
		
		mov    rdx, rcx
		and    edx, 0xFFFF
		shl    edx, 16
		
		or     eax, edx
		
		mov    rdx, rcx
		shr    edx, 16
		and    edx, 0x00FF
		shl    rdx, 32
		
		or     rax, rdx
		
		mov    rdx, rcx
		shr    edx, 16
		and    edx, 0xFF00
		shl    rdx, 48
		
		or     rax, rdx
		
		mov    edx, 0x8900
		shl    rdx, 32
		
		or     rax, rdx
		
		Get    rdi, oldInfo
		mov    edx, [rdi+Loader_16.globalDescriptorsTable.length]
		mov    rdi, [rdi+Loader_16.globalDescriptorsTable]
		mov    [rdi+32], rax
		
		shr    rcx, 32
		mov    [rdi+40], rcx
		
		dec    edx
		mov    [rbp-16], dx
		mov    [rbp-14], rdi
		
		lgdt   tbyte[rbp-16]
		
		mov    ax, 32
		ltr    ax
		
		return
	\}
	
	public void setIdt()
	\{
		define iGate 0x0E00
		define tGate 0x0F00
		macro setIdtEntry number, type, code, name \\{
			mov    dword[rdi+(number*16)     ], ((code and 0xFFFF) shl 16) or (Loader.\\#name and 0xFFFF)
			mov    dword[rdi+(number*16) +  4], (Loader.\\#name and 0xFFFF0000) or ((type and 0x0F00) or 0x8000)
;        /* mov    dword[rdi+(number*16) +  8], (Loader.\\#name and 0xFFFFFFFF00000000) shr 32
;           mov    dword[rdi+(number*16) + 12], 0x00000000 */
		\\}
		long a, b
		Prologue
		
		mov    rax, [@DynamicSize]
		mov    rsi, 0x1000
		xor    rdx, rdx
		div    rsi
		
		and    rdx, rdx
		jz     .J0
		inc    rax
	.J0:
		mul    rsi
		
		mov    rdi, rax
		add    rax, rsi
		mov    [@DynamicSize], rax
		
		mov    edx, esi
		shr    esi, 4
		
		Set    idt.length, esi, dword
		Set    idt, rdi
		
		dec    edx
		mov    [rbp-16], dx
		mov    [rbp-14], rdi
		
		setIdtEntry 0, iGate, 24, divideByZeroErrorException
		setIdtEntry 1, iGate, 24, debugException
		setIdtEntry 2, iGate, 24, nonMaskableInterruptException
		setIdtEntry 3, iGate, 24, breakpointException
		setIdtEntry 4, iGate, 24, overflowException
		setIdtEntry 5, iGate, 24, boundRangeException
		setIdtEntry 6, iGate, 24, invalidOpcodeException
		setIdtEntry 7, iGate, 24, deviceNotAvaliableException
		setIdtEntry 8, iGate, 24, doubleFaultException
		setIdtEntry 10, iGate, 24, invalidTSSException
		setIdtEntry 11, iGate, 24, segmentNotPresentException
		setIdtEntry 12, iGate, 24, stackException
		setIdtEntry 13, iGate, 24, generalProtectionException
		setIdtEntry 14, iGate, 24, pageFaultException
		setIdtEntry 16, iGate, 24, x87FloatingPointExceptionPending
		setIdtEntry 17, iGate, 24, alignmentCheckException
		setIdtEntry 18, iGate, 24, machineCheckException
		setIdtEntry 19, iGate, 24, simdFloatingPointException
		setIdtEntry 29, iGate, 24, vmmCommunicationException
		setIdtEntry 30, iGate, 24, securityException
		
		lidt   tbyte[rbp-16]
		
		return
	\}
	
	void divideByZeroErrorException()
	\{
		Mkstr divideByZeroError = 'Oh, no!', 10, \
		                          'We cannot divide by zero.', 10, \
		                          'Contact the developer to solve this unpredictable division.'
		mov    rdi, divideByZeroError
		Call Screen.println
		Halt
	\}
	
	void debugException()
	\{
		Mkstr notImplemented = 'Sorry! Resource not implemented yet.'
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void nonMaskableInterruptException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void breakpointException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void overflowException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void boundRangeException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void invalidOpcodeException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void deviceNotAvaliableException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void doubleFaultException()
	\{
		Mkstr doubleFault = 'Forgiveness!', 10, \
		                    'Somenthing wrong happen and the system failed to carry out his function.'
		mov    rdi, doubleFault
		Call Screen.println
		Halt
	\}
	
	void invalidTSSException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void segmentNotPresentException()
	\{
		Mkstr segmentNotPresent = 'The current program attempt to access a not present segment.'
		mov    rdi, segmentNotPresent
		Call Screen.println
		Halt
	\}
	
	void stackException()
	\{
		mov    rdi, segmentNotPresent
		Call Screen.println
		Halt
	\}
	
	void generalProtectionException()
	\{
		Prologue
		Mkstr generalProtection = 'Oh no!', 10, \
		                          'The current program is wicked.', 10, \
		                          'He attempt to violate the protection.'
		mov    rdi, generalProtection
		Call Screen.println
		mov    rdi, [rbp+ 8]
		mov    esi, 8
		Call Screen.printlnHex
		Halt
	\}
	
	void pageFaultException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void x87FloatingPointExceptionPending()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void alignmentCheckException()
	\{
		Mkstr alignmentError = 'The current program failed to pass on the alignment check.'
		mov    rdi, alignmentError
		Call Screen.println
		Halt
	\}
	
	void machineCheckException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void simdFloatingPointException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void vmmCommunicationException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
	void securityException()
	\{
		mov    rdi, notImplemented
		Call Screen.println
		Halt
	\}
	
}

private class Memory:
{
	
	private static long freeBlocks    = 0
	private static long bitmap.length = 0
	private static long bitmap        = 0
	private static long length        = 0
	
	public static void setBitmap()
	\{
		long r12Save, r13Save, r14Save, r15Save
		Prologue
		
		shr    rsi, 12
		Set    bitmap.length, rsi
		shr    rsi, 6
		
		mov    rax, [@DynamicSize]
		Set    bitmap, rax
		add    rax, rsi
		mov    [@DynamicSize], rax
		
		mov    [rbp+.r12Save], r12
		mov    [rbp+.r13Save], r13
		mov    [rbp+.r14Save], r14
		mov    [rbp+.r15Save], r15
		
		mov    r12, [rdi   ]
		mov    r13, [rdi+ 8]
	.getNextEntry:
		cmp    dword[r13+20], 1
		jne    .ignoreEntry
		cmp    dword[r13+16], 1
		jne    .ignoreEntry
		cmp    qword[r13+ 8], 0x1000
		jb     .ignoreEntry
		
		mov    r15, [r13+ 8]
		mov    r14, [r13   ]
		shr    r15, 12
	.getNextPage:
		cmp    r14, 0x00100000
		jb     .ignorePage
		
		mov    rdi, r14
		Call setPageFree
	.ignorePage:
		add    r14, 0x1000
		dec    r15
		jnz    .getNextPage
	.ignoreEntry:
		add    r13, 24
		dec    r12
		jnz    .getNextEntry
		
		mov    r15, [rbp+.r15Save]
		mov    r14, [rbp+.r14Save]
		mov    r13, [rbp+.r13Save]
		mov    r12, [rbp+.r12Save]
		return
	\}
	
	public static void setPageTableDynamic()
	\{
		long vAddress
		Prologue
		mov    [rbp+.vAddress], rdi
		
		Call getPageFree
		mov    rdi, [rbp+.vAddress]
		or     rax, 3
		mov    rsi, rax
		Call setPageTable
		
		return
	\}
	
	public static void setPageTable()
	\{
		long vAddress, pageInfo
		Prologue
		mov    [rbp+.vAddress], rdi
		mov    [rbp+.pageInfo], rsi
		
		mov    rdx, 0x0000FFFFFFFFF000
		mov    rsi, cr3
		and    rsi, rdx
		
		shr    rdi, 39
		and    edi, 0x01FF
		Call getPageAddress
		
		mov    rdi, [rbp+.vAddress]
		mov    rsi, rax
		shr    rdi, 30
		and    edi, 0x01FF
		Call getPageAddress
		
		mov    rdi, [rbp+.vAddress]
		mov    rsi, rax
		shr    rdi, 21
		and    edi, 0x01FF
		Call getPageAddress
		
		mov    rdi, [rbp+.vAddress]
		mov    rsi, rax
		shr    rdi, 12
		and    edi, 0x01FF
		
		lea    rdi, [rsi+rdi*8]
		bt     qword[rdi   ], 0
		jc     .pagePresent
		
		mov    rax, [rbp+.pageInfo]
		mov    [rdi   ], rax
	.pagePresent:
	    return
	\}
	
	public static long getPageAddress()
	\{
		long pageAddress
		Prologue
		
		lea    rdi, [rsi+rdi*8]
		
		mov    rax, [rdi   ]
		bt     rax, 0
		jc     .pagePresent
		
		mov    [rbp+.pageAddress], rdi
		
		Call getPageFree
		mov    rdi, [rbp+.pageAddress]
		or     rax, 3
		mov    [rdi   ], rax
	.pagePresent:
	    mov    rdx, 0x0000FFFFFFFFF000
		and    rax, rdx
		
		return
	\}
	
	public static void getPageFree()
	\{
		Prologue
		
		cmp    qword[Memory.freeBlocks], 0
		je     .outOfMemory
		
		mov    rsi, [Memory.bitmap]
	.getNextQuad:
		lodsq
		and    rax, rax
		jz     .getNextQuad
		
		bsf    rdx, rax
		btr    [rsi- 8], rdx
		sub    rsi, [Memory.bitmap]
		dec    qword[Memory.freeBlocks]
		lea    rax, [rsi*8-64]
		shl    rax, 12
		
		return
	.outOfMemory:
		Mkstr outOfMemoryException = 'Out of memory exception.'
		mov    rdi, outOfMemoryException
		Call Screen.println
		Halt
	\}
	
	public static void setPageFree()
	\{
		Prologue
		
		shr    rdi, 12
		cmp    rdi, [Memory.bitmap.length]
		ja     .outOfBounds
		
		mov    rax, rdi
		
		mov    rsi, 64
		xor    rdx, rdx
		div    rsi
		
		mov    rsi, [Memory.bitmap]
		
		bts    [rsi+rax*8], rdx
		inc    qword[Memory.freeBlocks]
	.outOfBounds:
		return
	\}
	
}

private class Screen:
{
	
	public static short color = 0x0F00
	public static long buffer = 0x000B8000
	public static int width   = 80
	public static int height  = 25
	public static int x       = 0
	public static int y       = 0
	
	public static void printlnHex()
	\{
		Prologue
		
		Call printHex
		mov    edi, 10
		Call print@C
		
		return
	\}
	
	public static void printHex()
	\{
		long number
		Prologue
		
		cmp    esi, 1
		jb     .noPrint
		
		Set    number, rdi
		
		lea    ecx, [esi* 8]
	.getNextNibble:
		sub    ecx, 4
		
		shr    rdi, cl
		and    edi, 0xF 
		add    edi, '0'
		cmp    edi, '9'
		jna    .J0
		add    edi, 'A' - '9' - 1
	.J0:
		Call print@C
		Get    rdi, number
		and    ecx, ecx
		jnz    .getNextNibble
	.noPrint:
		return
	\}
	
	public static void println()
	\{
		Prologue
		
		Call print
		mov    edi, 10
		Call print@C
		
		return
	\}
	
	public static void print()
	\{
		long rsuSave
		Prologue
		mov    [rbp- 8], rbx
		
		and    rdi, rdi
		jz     .nullReference
		
		mov    rbx, rdi
	.getNextChar:
		movzx  edi, byte[rbx   ]
		and    edi, edi
		jz     .endOfString
		
		Call print@C
		inc    rbx
		jmp    .getNextChar
	.endOfString:
		mov    rbx, [rbp- 8]
	.nullReference:
		return
	\}
	
	public static void print@C()
	\{
		Prologue
		
		cmp    edi, 10
		je     .newLine
		
		Get    eax, y, dword
		
		or     edi, dword[Screen.color]
		
		mul    dword[Screen.width]
		add    eax, dword[Screen.x]
		shl    eax, 1
		add    rax, [Screen.buffer]
		
		xchg   rax, rdi
		
		stosw
		
		Get    edi, x, dword
		inc    edi
	.setX:
		Call setX
		
		return
	.newLine:
		Get    edi, y, dword
		inc    edi
		Call setY
		
		xor    edi, edi
		jmp    .setX
	\}
	
	public static void setX()
	\{
		Prologue
		
		mov    eax, edi
		xor    edx, edx
		div    dword[Screen.width]
		
		Set    x, edx, dword
		
		and    eax, eax
		jz     .noNewLine
		
		mov    edi, eax
		Call   setY
	.noNewLine:
		return
	\}
	
	public static void setY()
	\{
		Prologue
		
		mov    eax, edi
		xor    edx, edx
		div    dword[Screen.height]
		
		Set    y, edx, dword
		
		and    eax, eax
		jz     .noScreenOverflow
		
		cmp    eax, 2 ; /* Uses the JNB below. */
		
		Get    eax, height, dword
		Get    esi, width, dword
		Get    rdi, buffer
		
		jnb    .clearAllScreen ; /* Uses the CMP above. */
		
		mov    ecx, eax
		sub    ecx, edx
		dec    ecx
		Set    y, ecx, dword
		
		mov    ecx, edx
		
		mul    esi
		
		xchg   ecx, eax
		
		mul    esi
		
		lea    rsi, [rdi+rax*2]
		
		sub    ecx, eax
		shr    ecx, 2
		
		rep    movsq
	.clearScreen:
		mov    ecx, eax
		shr    ecx, 2
		
		xor    eax, eax
		
		rep    stosq
	.noScreenOverflow:
		return
	.clearAllScreen:
		mul    esi
		jmp    .clearScreen
	\}
	
}

define MINIMUM_MEMORY_AMOUNT 0x0037FC00

private class Loader_16:
{
	
	public long memorySize                   = 0
	public int acpiMemoryMap.length          = 0
	public long acpiMemoryMap                = 0
	public int pageMapLevel4.length          = 0
	public long pageMapLevel4                = 0
	public int globalDescriptorsTable.length = 0
	public long globalDescriptorsTable       = 0
	
	public void Loader_16()
	\{
		USE16
		Call setMemorySize
		
		Call setPageMapLevel4
		
		Call setGlobalDescriptorsTable
		
		cli
		mov    eax, cr0
		bts    eax, 0
		mov    cr0, eax
		jmp    8:.protectedMode
	.protectedMode:
		USE32
		mov    ax, 16
		mov    ss, ax
		
		mov    eax, cr4
		bts    eax, 5
		mov    cr4, eax
		
		mov    ecx, 0xC0000080
		rdmsr
		bts    eax, 8
		wrmsr
		
		mov    eax, cr0
		bts    eax, 31
		mov    cr0, eax
		jmp    24:Loader.main.x64Mode
	\}
	
	private long setGlobalDescriptorsTable()
	\{
		USE16
		push   ebp
		mov    ebp, esp
		sub    esp, 16
		
		mov    eax, 6 * 8
		mov    [ebx+Loader_16.globalDescriptorsTable.length], eax
		dec    eax
		mov    word[ebp-16], ax
		
		mov    esi, 0x1000
		mov    eax, dword[@DynamicSize]
		xor    edx, edx
		
		div    esi
		and    edx, edx
		jz     .J0
		inc    eax
	.J0:
		mul    esi
		mov    edi, eax
		mov    [ebp-14], eax
		mov    [ebx+Loader_16.globalDescriptorsTable], eax
		add    eax, esi
		mov    dword[@DynamicSize], eax
		
;    /* mov    dword[edi   ]
;       mov    dword[edi+ 4] */
		mov    dword[edi+ 8], 0x0000FFFF
		mov    dword[edi+12], 0x00CF9800
		mov    dword[edi+16], 0x0000FFFF
		mov    dword[edi+20], 0x00CF9200
		mov    dword[edi+24], 0x00000000
		mov    dword[edi+28], 0x00209800
;    /* mov    dword[edi+32]
;       mov    dword[edi+36]
;       mov    dword[edi+40]
;       mov    dword[edi+44] */
		
		lgdt   fword[ebp-16]
		
		mov    esp, ebp
		pop    ebp
		ret
	\}
	
	private void setPageMapLevel4()
	\{
		USE16
		push   ebp
		mov    ebp, esp
		
		mov    esi, 0x1000
		mov    eax, dword[@DynamicSize]
		xor    edx, edx
		
		mov    dword[ebx+Loader_16.pageMapLevel4.length], 512
		
		div    esi
		and    edx, edx
		jz     .J0
		inc    eax
	.J0:
		mul    esi
		mov    cr3, eax
		mov    [ebx+Loader_16.pageMapLevel4], eax ; /* PML4 Address */
		
		mov    edi, eax
		add    eax, esi
		or     eax, 3
		
		mov    [edi   ], eax ; /* PML4E0 Address */
		
		add    edi, esi
		add    eax, esi
		
		mov    [edi   ], eax ; /* PDPTE0 Address */
		
		add    edi, esi
		add    eax, esi
		
		mov    [edi   ], eax ; /* PDE0 Address */
		
		add    edi, esi
		add    eax, esi
		and    eax, not 0x0FFF
		mov    dword[@DynamicSize], eax
		
		mov    dword[edi   ], 0x1B ; /* PTE0 Address */
		add    edi, 8
		
		mov    edx, 0x009D
		mov    eax, 0x1003
	.setNextPage0:
		mov    [edi   ], eax
		add    edi, 8
		add    eax, esi
		dec    edx
		jnz    .setNextPage0
		
		mov    edx, 0x0062
		or     eax, 0x001B
	.setNextPage1:
		mov    [edi   ], eax
		add    edi, 8
		add    eax, esi
		dec    edx
		jnz    .setNextPage1
		
		mov    edx, 0x0100
		xor    eax, 0x0018
	.setNextPage2:
		mov    [edi   ], eax
		add    edi, 8
		add    eax, esi
		dec    edx
		jnz    .setNextPage2
		
		pop    ebp
		ret
	\}
	
	private long setMemorySize()
	\{
		USE16
		push   ebp
		mov    ebp, esp
		
		Call setAcpiMemoryMap
		
		cmp    dword[ebx+Loader_16.acpiMemoryMap.length], 0
		je     .acpiMemoryMapEmpty
		
		mov    esi, [ebx+Loader_16.acpiMemoryMap.length]
		mov    edi, [ebx+Loader_16.acpiMemoryMap]
		xor    eax, eax
		xor    edx, edx
	.getNextAcpiEntry:
		cmp    dword[edi+16], 1
		jne    .nextAcpiEntry
		
		add    eax, [edi+ 8]
		adc    edx, [edi+12]
	.nextAcpiEntry:
		add    edi, 24
		dec    esi
		jnz    .getNextAcpiEntry
		
		cmp    eax, MINIMUM_MEMORY_AMOUNT
		jb     .insuficientMemory
	.suficientMemory:
		mov    [ebx+Loader_16.memorySize], eax
		mov    [ebx+Loader_16.memorySize+4], edx
		
		pop    ebp
		ret
	.insuficientMemory:
		and    edx, edx
		jnz    .suficientMemory
		
		Mkstr insuficientMemoryError = 'Memory size is lowest than 4MB.', 10, 13
		mov    esi, insuficientMemoryError
		Call printFatal
	.acpiMemoryMapEmpty:
		mov    ax, 0x0E00+'h'
		Int    0x10
		Halt
	\}
	
	private void setAcpiMemoryMap()
	\{
		USE16
		push   ebp
		mov    ebp, esp
		sub    esp, 24
		
		mov    edi, dword[@DynamicSize]
		mov    [ebx+Loader_16.acpiMemoryMap], edi
		
		mov    [ebp- 8], ebx
		xor    ebx, ebx
		mov    [ebp-24], ebx
	.getNextEntry:
		mov    dword[edi+20], 1
		mov    eax, 0xE820
		mov    ecx, 24
		mov    edx, 'PAMS'
		Int    0x15
		jc     .endOfMap
		
		cmp    eax, 'PAMS'
		jne    .endOfMap
		
		cmp    ecx, 20
		jb     .endOfMap
		
		cmp    ecx, 24
		ja     .endOfMap
		
		and    ebx, ebx
		jz     .endOfMap
		
		cmp    dword[edi+ 8], 0
		je     .invalidSize
	.validSize:
		inc    dword[ebp-24]
		add    edi, 24
		jmp    .getNextEntry
	.invalidSize:
		cmp    dword[edi+12], 0
		jne    .validSize
		jmp    .getNextEntry
	.endOfMap:
		mov    dword[@DynamicSize], edi
		
		mov    ebx, [ebp- 8]
		mov    eax, [ebp-24]
		
		mov    [ebx+Loader_16.acpiMemoryMap.length], eax
		
		mov    esp, ebp
		pop    ebp
		ret
	\}
	
;   /**
;    * @StackUnsafe
;    */
	public static void setGateA20()
	\{
		USE16
		push   bp
		mov    bp, sp
		
;   /** !!! WARNING !!!
;    * 
;    * Stack space used by this method must be overrided.
;    * 
;    * Uses (Bytes):
;    *     BP Save < 2
;    *     FLAGS   < 2
;    *     DS Save < 2
;    *     DS New  < 2
;    * 
;    * For subsequent 4B pushes, aligned to 8B, at least
;    * the top 4B needs to be overrided.
;    */
		
		pushf
		or     byte[bp- 1], 0x40
		popf
		pushf
		and    byte[bp- 1], 0x40
		jz     .a20Error
		
		push   ds
		push   word 0xFFFF
		pop    ds
		cmp    word[0x7E0E], 0xAA55
		pop    ds
		je     .setA20
		
		mov    sp, bp
		pop    bp
		ret
	.setA20:
	.a20Error:
		Mkstr gateA20Error = 'This processor do not support Gate A20.', 10, 13
		mov    si, gateA20Error
		Call printFatal
	\}
	
	private static void printFatal()
	\{
		USE16
		Mkstr fatalPrefix = 'FATAL: '
		push   bp
		mov    bp, sp
		sub    sp, 2
		
		mov    [bp-2], si
		mov    si, fatalPrefix
		Call print
		mov    si, [bp-2]
		Call print
		Halt
	\}
	
	private static void print()
	\{
		USE16
		push   bp
		mov    bp, sp
		
		and    si, si
		jz     .nullReference
		
		mov    ax, 0x0E00
	.getNextChar:
		lodsb
		and    al, al
		jz     .endOfString
		
		Int    0x10
		jmp    .getNextChar
	.endOfString:
	.nullReference:
		pop    bp
		ret
	\}
	
}

















































