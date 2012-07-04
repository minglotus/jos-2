
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in mem_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 ac 79 11 f0       	mov    $0xf01179ac,%eax
f010004b:	2d 04 73 11 f0       	sub    $0xf0117304,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 04 73 11 f0 	movl   $0xf0117304,(%esp)
f0100063:	e8 ae 37 00 00       	call   f0103816 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8e 04 00 00       	call   f01004fb <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 20 3d 10 f0 	movl   $0xf0103d20,(%esp)
f010007c:	e8 95 2b 00 00       	call   f0102c16 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 38 11 00 00       	call   f01011be <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 b3 07 00 00       	call   f0100845 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 20 73 11 f0 00 	cmpl   $0x0,0xf0117320
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 20 73 11 f0    	mov    %esi,0xf0117320

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 3b 3d 10 f0 	movl   $0xf0103d3b,(%esp)
f01000c8:	e8 49 2b 00 00       	call   f0102c16 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 0a 2b 00 00       	call   f0102be3 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 9c 4b 10 f0 	movl   $0xf0104b9c,(%esp)
f01000e0:	e8 31 2b 00 00       	call   f0102c16 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 54 07 00 00       	call   f0100845 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 53 3d 10 f0 	movl   $0xf0103d53,(%esp)
f0100112:	e8 ff 2a 00 00       	call   f0102c16 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 bd 2a 00 00       	call   f0102be3 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 9c 4b 10 f0 	movl   $0xf0104b9c,(%esp)
f010012d:	e8 e4 2a 00 00       	call   f0102c16 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
	...

f0100140 <delay>:
extern int char_color;

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100157:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 06                	je     f0100166 <serial_proc_data+0x18>
f0100160:	b2 f8                	mov    $0xf8,%dl
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c8             	movzbl %al,%ecx
}
f0100166:	89 c8                	mov    %ecx,%eax
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 25                	jmp    f010019a <cons_intr+0x30>
		if (c == 0)
f0100175:	85 c0                	test   %eax,%eax
f0100177:	74 21                	je     f010019a <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	8b 15 64 75 11 f0    	mov    0xf0117564,%edx
f010017f:	88 82 60 73 11 f0    	mov    %al,-0xfee8ca0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 64 75 11 f0       	mov    %eax,0xf0117564
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019a:	ff d3                	call   *%ebx
f010019c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019f:	75 d4                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a1:	83 c4 04             	add    $0x4,%esp
f01001a4:	5b                   	pop    %ebx
f01001a5:	5d                   	pop    %ebp
f01001a6:	c3                   	ret    

f01001a7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	57                   	push   %edi
f01001ab:	56                   	push   %esi
f01001ac:	53                   	push   %ebx
f01001ad:	83 ec 2c             	sub    $0x2c,%esp
f01001b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01001b3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b8:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001b9:	a8 20                	test   $0x20,%al
f01001bb:	75 1b                	jne    f01001d8 <cons_putc+0x31>
f01001bd:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c2:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c7:	e8 74 ff ff ff       	call   f0100140 <delay>
f01001cc:	89 f2                	mov    %esi,%edx
f01001ce:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001cf:	a8 20                	test   $0x20,%al
f01001d1:	75 05                	jne    f01001d8 <cons_putc+0x31>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d3:	83 eb 01             	sub    $0x1,%ebx
f01001d6:	75 ef                	jne    f01001c7 <cons_putc+0x20>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01001d8:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001dc:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e1:	89 f8                	mov    %edi,%eax
f01001e3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e4:	b2 79                	mov    $0x79,%dl
f01001e6:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001e7:	84 c0                	test   %al,%al
f01001e9:	78 1b                	js     f0100206 <cons_putc+0x5f>
f01001eb:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f0:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01001f5:	e8 46 ff ff ff       	call   f0100140 <delay>
f01001fa:	89 f2                	mov    %esi,%edx
f01001fc:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001fd:	84 c0                	test   %al,%al
f01001ff:	78 05                	js     f0100206 <cons_putc+0x5f>
f0100201:	83 eb 01             	sub    $0x1,%ebx
f0100204:	75 ef                	jne    f01001f5 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100206:	ba 78 03 00 00       	mov    $0x378,%edx
f010020b:	89 f8                	mov    %edi,%eax
f010020d:	ee                   	out    %al,(%dx)
f010020e:	b2 7a                	mov    $0x7a,%dl
f0100210:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100215:	ee                   	out    %al,(%dx)
f0100216:	b8 08 00 00 00       	mov    $0x8,%eax
f010021b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c = c | (char_color<<8);
f010021c:	a1 00 73 11 f0       	mov    0xf0117300,%eax
f0100221:	c1 e0 08             	shl    $0x8,%eax
f0100224:	0b 45 e4             	or     -0x1c(%ebp),%eax
	
	if (!(c & ~0xFF)){
f0100227:	89 c1                	mov    %eax,%ecx
f0100229:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f010022f:	89 c2                	mov    %eax,%edx
f0100231:	80 ce 07             	or     $0x7,%dh
f0100234:	85 c9                	test   %ecx,%ecx
f0100236:	0f 44 c2             	cmove  %edx,%eax
		}

	switch (c & 0xff) {
f0100239:	0f b6 d0             	movzbl %al,%edx
f010023c:	83 fa 09             	cmp    $0x9,%edx
f010023f:	74 75                	je     f01002b6 <cons_putc+0x10f>
f0100241:	83 fa 09             	cmp    $0x9,%edx
f0100244:	7f 0c                	jg     f0100252 <cons_putc+0xab>
f0100246:	83 fa 08             	cmp    $0x8,%edx
f0100249:	0f 85 9b 00 00 00    	jne    f01002ea <cons_putc+0x143>
f010024f:	90                   	nop
f0100250:	eb 10                	jmp    f0100262 <cons_putc+0xbb>
f0100252:	83 fa 0a             	cmp    $0xa,%edx
f0100255:	74 39                	je     f0100290 <cons_putc+0xe9>
f0100257:	83 fa 0d             	cmp    $0xd,%edx
f010025a:	0f 85 8a 00 00 00    	jne    f01002ea <cons_putc+0x143>
f0100260:	eb 36                	jmp    f0100298 <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f0100262:	0f b7 15 74 75 11 f0 	movzwl 0xf0117574,%edx
f0100269:	66 85 d2             	test   %dx,%dx
f010026c:	0f 84 e3 00 00 00    	je     f0100355 <cons_putc+0x1ae>
			crt_pos--;
f0100272:	83 ea 01             	sub    $0x1,%edx
f0100275:	66 89 15 74 75 11 f0 	mov    %dx,0xf0117574
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027c:	0f b7 d2             	movzwl %dx,%edx
f010027f:	b0 00                	mov    $0x0,%al
f0100281:	83 c8 20             	or     $0x20,%eax
f0100284:	8b 0d 70 75 11 f0    	mov    0xf0117570,%ecx
f010028a:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f010028e:	eb 78                	jmp    f0100308 <cons_putc+0x161>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100290:	66 83 05 74 75 11 f0 	addw   $0x50,0xf0117574
f0100297:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100298:	0f b7 05 74 75 11 f0 	movzwl 0xf0117574,%eax
f010029f:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a5:	c1 e8 16             	shr    $0x16,%eax
f01002a8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ab:	c1 e0 04             	shl    $0x4,%eax
f01002ae:	66 a3 74 75 11 f0    	mov    %ax,0xf0117574
f01002b4:	eb 52                	jmp    f0100308 <cons_putc+0x161>
		break;
	case '\t':
		cons_putc(' ');
f01002b6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002bb:	e8 e7 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002c0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c5:	e8 dd fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002ca:	b8 20 00 00 00       	mov    $0x20,%eax
f01002cf:	e8 d3 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002d4:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d9:	e8 c9 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002de:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e3:	e8 bf fe ff ff       	call   f01001a7 <cons_putc>
f01002e8:	eb 1e                	jmp    f0100308 <cons_putc+0x161>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002ea:	0f b7 15 74 75 11 f0 	movzwl 0xf0117574,%edx
f01002f1:	0f b7 da             	movzwl %dx,%ebx
f01002f4:	8b 0d 70 75 11 f0    	mov    0xf0117570,%ecx
f01002fa:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f01002fe:	83 c2 01             	add    $0x1,%edx
f0100301:	66 89 15 74 75 11 f0 	mov    %dx,0xf0117574
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100308:	66 81 3d 74 75 11 f0 	cmpw   $0x7cf,0xf0117574
f010030f:	cf 07 
f0100311:	76 42                	jbe    f0100355 <cons_putc+0x1ae>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100313:	a1 70 75 11 f0       	mov    0xf0117570,%eax
f0100318:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010031f:	00 
f0100320:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100326:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032a:	89 04 24             	mov    %eax,(%esp)
f010032d:	e8 3f 35 00 00       	call   f0103871 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100332:	8b 15 70 75 11 f0    	mov    0xf0117570,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100338:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010033d:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100343:	83 c0 01             	add    $0x1,%eax
f0100346:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010034b:	75 f0                	jne    f010033d <cons_putc+0x196>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010034d:	66 83 2d 74 75 11 f0 	subw   $0x50,0xf0117574
f0100354:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100355:	8b 0d 6c 75 11 f0    	mov    0xf011756c,%ecx
f010035b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100360:	89 ca                	mov    %ecx,%edx
f0100362:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100363:	0f b7 35 74 75 11 f0 	movzwl 0xf0117574,%esi
f010036a:	8d 59 01             	lea    0x1(%ecx),%ebx
f010036d:	89 f0                	mov    %esi,%eax
f010036f:	66 c1 e8 08          	shr    $0x8,%ax
f0100373:	89 da                	mov    %ebx,%edx
f0100375:	ee                   	out    %al,(%dx)
f0100376:	b8 0f 00 00 00       	mov    $0xf,%eax
f010037b:	89 ca                	mov    %ecx,%edx
f010037d:	ee                   	out    %al,(%dx)
f010037e:	89 f0                	mov    %esi,%eax
f0100380:	89 da                	mov    %ebx,%edx
f0100382:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100383:	83 c4 2c             	add    $0x2c,%esp
f0100386:	5b                   	pop    %ebx
f0100387:	5e                   	pop    %esi
f0100388:	5f                   	pop    %edi
f0100389:	5d                   	pop    %ebp
f010038a:	c3                   	ret    

f010038b <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010038b:	55                   	push   %ebp
f010038c:	89 e5                	mov    %esp,%ebp
f010038e:	53                   	push   %ebx
f010038f:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100392:	ba 64 00 00 00       	mov    $0x64,%edx
f0100397:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100398:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010039d:	a8 01                	test   $0x1,%al
f010039f:	0f 84 de 00 00 00    	je     f0100483 <kbd_proc_data+0xf8>
f01003a5:	b2 60                	mov    $0x60,%dl
f01003a7:	ec                   	in     (%dx),%al
f01003a8:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003aa:	3c e0                	cmp    $0xe0,%al
f01003ac:	75 11                	jne    f01003bf <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003ae:	83 0d 68 75 11 f0 40 	orl    $0x40,0xf0117568
		return 0;
f01003b5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003ba:	e9 c4 00 00 00       	jmp    f0100483 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003bf:	84 c0                	test   %al,%al
f01003c1:	79 37                	jns    f01003fa <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c3:	8b 0d 68 75 11 f0    	mov    0xf0117568,%ecx
f01003c9:	89 cb                	mov    %ecx,%ebx
f01003cb:	83 e3 40             	and    $0x40,%ebx
f01003ce:	83 e0 7f             	and    $0x7f,%eax
f01003d1:	85 db                	test   %ebx,%ebx
f01003d3:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d6:	0f b6 d2             	movzbl %dl,%edx
f01003d9:	0f b6 82 a0 3d 10 f0 	movzbl -0xfefc260(%edx),%eax
f01003e0:	83 c8 40             	or     $0x40,%eax
f01003e3:	0f b6 c0             	movzbl %al,%eax
f01003e6:	f7 d0                	not    %eax
f01003e8:	21 c1                	and    %eax,%ecx
f01003ea:	89 0d 68 75 11 f0    	mov    %ecx,0xf0117568
		return 0;
f01003f0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f5:	e9 89 00 00 00       	jmp    f0100483 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003fa:	8b 0d 68 75 11 f0    	mov    0xf0117568,%ecx
f0100400:	f6 c1 40             	test   $0x40,%cl
f0100403:	74 0e                	je     f0100413 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100405:	89 c2                	mov    %eax,%edx
f0100407:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040a:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040d:	89 0d 68 75 11 f0    	mov    %ecx,0xf0117568
	}

	shift |= shiftcode[data];
f0100413:	0f b6 d2             	movzbl %dl,%edx
f0100416:	0f b6 82 a0 3d 10 f0 	movzbl -0xfefc260(%edx),%eax
f010041d:	0b 05 68 75 11 f0    	or     0xf0117568,%eax
	shift ^= togglecode[data];
f0100423:	0f b6 8a a0 3e 10 f0 	movzbl -0xfefc160(%edx),%ecx
f010042a:	31 c8                	xor    %ecx,%eax
f010042c:	a3 68 75 11 f0       	mov    %eax,0xf0117568

	c = charcode[shift & (CTL | SHIFT)][data];
f0100431:	89 c1                	mov    %eax,%ecx
f0100433:	83 e1 03             	and    $0x3,%ecx
f0100436:	8b 0c 8d a0 3f 10 f0 	mov    -0xfefc060(,%ecx,4),%ecx
f010043d:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100441:	a8 08                	test   $0x8,%al
f0100443:	74 19                	je     f010045e <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100445:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100448:	83 fa 19             	cmp    $0x19,%edx
f010044b:	77 05                	ja     f0100452 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010044d:	83 eb 20             	sub    $0x20,%ebx
f0100450:	eb 0c                	jmp    f010045e <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100452:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100455:	8d 53 20             	lea    0x20(%ebx),%edx
f0100458:	83 f9 19             	cmp    $0x19,%ecx
f010045b:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010045e:	f7 d0                	not    %eax
f0100460:	a8 06                	test   $0x6,%al
f0100462:	75 1f                	jne    f0100483 <kbd_proc_data+0xf8>
f0100464:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010046a:	75 17                	jne    f0100483 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010046c:	c7 04 24 6d 3d 10 f0 	movl   $0xf0103d6d,(%esp)
f0100473:	e8 9e 27 00 00       	call   f0102c16 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100478:	ba 92 00 00 00       	mov    $0x92,%edx
f010047d:	b8 03 00 00 00       	mov    $0x3,%eax
f0100482:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100483:	89 d8                	mov    %ebx,%eax
f0100485:	83 c4 14             	add    $0x14,%esp
f0100488:	5b                   	pop    %ebx
f0100489:	5d                   	pop    %ebp
f010048a:	c3                   	ret    

f010048b <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010048b:	55                   	push   %ebp
f010048c:	89 e5                	mov    %esp,%ebp
f010048e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100491:	83 3d 40 73 11 f0 00 	cmpl   $0x0,0xf0117340
f0100498:	74 0a                	je     f01004a4 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010049a:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f010049f:	e8 c6 fc ff ff       	call   f010016a <cons_intr>
}
f01004a4:	c9                   	leave  
f01004a5:	c3                   	ret    

f01004a6 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a6:	55                   	push   %ebp
f01004a7:	89 e5                	mov    %esp,%ebp
f01004a9:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ac:	b8 8b 03 10 f0       	mov    $0xf010038b,%eax
f01004b1:	e8 b4 fc ff ff       	call   f010016a <cons_intr>
}
f01004b6:	c9                   	leave  
f01004b7:	c3                   	ret    

f01004b8 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b8:	55                   	push   %ebp
f01004b9:	89 e5                	mov    %esp,%ebp
f01004bb:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004be:	e8 c8 ff ff ff       	call   f010048b <serial_intr>
	kbd_intr();
f01004c3:	e8 de ff ff ff       	call   f01004a6 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c8:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004ce:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d3:	3b 15 64 75 11 f0    	cmp    0xf0117564,%edx
f01004d9:	74 1e                	je     f01004f9 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004db:	0f b6 82 60 73 11 f0 	movzbl -0xfee8ca0(%edx),%eax
f01004e2:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e5:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004eb:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f0:	0f 44 d1             	cmove  %ecx,%edx
f01004f3:	89 15 60 75 11 f0    	mov    %edx,0xf0117560
		return c;
	}
	return 0;
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	57                   	push   %edi
f01004ff:	56                   	push   %esi
f0100500:	53                   	push   %ebx
f0100501:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100504:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050b:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100512:	5a a5 
	if (*cp != 0xA55A) {
f0100514:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051b:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051f:	74 11                	je     f0100532 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100521:	c7 05 6c 75 11 f0 b4 	movl   $0x3b4,0xf011756c
f0100528:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052b:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100530:	eb 16                	jmp    f0100548 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100532:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100539:	c7 05 6c 75 11 f0 d4 	movl   $0x3d4,0xf011756c
f0100540:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100543:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100548:	8b 0d 6c 75 11 f0    	mov    0xf011756c,%ecx
f010054e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100553:	89 ca                	mov    %ecx,%edx
f0100555:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100556:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100559:	89 da                	mov    %ebx,%edx
f010055b:	ec                   	in     (%dx),%al
f010055c:	0f b6 f8             	movzbl %al,%edi
f010055f:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100562:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100567:	89 ca                	mov    %ecx,%edx
f0100569:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056a:	89 da                	mov    %ebx,%edx
f010056c:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056d:	89 35 70 75 11 f0    	mov    %esi,0xf0117570
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100573:	0f b6 d8             	movzbl %al,%ebx
f0100576:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100578:	66 89 3d 74 75 11 f0 	mov    %di,0xf0117574
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057f:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100584:	b8 00 00 00 00       	mov    $0x0,%eax
f0100589:	89 da                	mov    %ebx,%edx
f010058b:	ee                   	out    %al,(%dx)
f010058c:	b2 fb                	mov    $0xfb,%dl
f010058e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100593:	ee                   	out    %al,(%dx)
f0100594:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100599:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059e:	89 ca                	mov    %ecx,%edx
f01005a0:	ee                   	out    %al,(%dx)
f01005a1:	b2 f9                	mov    $0xf9,%dl
f01005a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a8:	ee                   	out    %al,(%dx)
f01005a9:	b2 fb                	mov    $0xfb,%dl
f01005ab:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b0:	ee                   	out    %al,(%dx)
f01005b1:	b2 fc                	mov    $0xfc,%dl
f01005b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b8:	ee                   	out    %al,(%dx)
f01005b9:	b2 f9                	mov    $0xf9,%dl
f01005bb:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c0:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c1:	b2 fd                	mov    $0xfd,%dl
f01005c3:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c4:	3c ff                	cmp    $0xff,%al
f01005c6:	0f 95 c0             	setne  %al
f01005c9:	0f b6 c0             	movzbl %al,%eax
f01005cc:	89 c6                	mov    %eax,%esi
f01005ce:	a3 40 73 11 f0       	mov    %eax,0xf0117340
f01005d3:	89 da                	mov    %ebx,%edx
f01005d5:	ec                   	in     (%dx),%al
f01005d6:	89 ca                	mov    %ecx,%edx
f01005d8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005d9:	85 f6                	test   %esi,%esi
f01005db:	75 0c                	jne    f01005e9 <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f01005dd:	c7 04 24 79 3d 10 f0 	movl   $0xf0103d79,(%esp)
f01005e4:	e8 2d 26 00 00       	call   f0102c16 <cprintf>
}
f01005e9:	83 c4 1c             	add    $0x1c,%esp
f01005ec:	5b                   	pop    %ebx
f01005ed:	5e                   	pop    %esi
f01005ee:	5f                   	pop    %edi
f01005ef:	5d                   	pop    %ebp
f01005f0:	c3                   	ret    

f01005f1 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f1:	55                   	push   %ebp
f01005f2:	89 e5                	mov    %esp,%ebp
f01005f4:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f7:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fa:	e8 a8 fb ff ff       	call   f01001a7 <cons_putc>
}
f01005ff:	c9                   	leave  
f0100600:	c3                   	ret    

f0100601 <getchar>:

int
getchar(void)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100607:	e8 ac fe ff ff       	call   f01004b8 <cons_getc>
f010060c:	85 c0                	test   %eax,%eax
f010060e:	74 f7                	je     f0100607 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100610:	c9                   	leave  
f0100611:	c3                   	ret    

f0100612 <iscons>:

int
iscons(int fdnum)
{
f0100612:	55                   	push   %ebp
f0100613:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100615:	b8 01 00 00 00       	mov    $0x1,%eax
f010061a:	5d                   	pop    %ebp
f010061b:	c3                   	ret    
f010061c:	00 00                	add    %al,(%eax)
	...

f0100620 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100626:	c7 04 24 b0 3f 10 f0 	movl   $0xf0103fb0,(%esp)
f010062d:	e8 e4 25 00 00       	call   f0102c16 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 74 40 10 f0 	movl   $0xf0104074,(%esp)
f0100649:	e8 c8 25 00 00       	call   f0102c16 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 15 3d 10 	movl   $0x103d15,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 15 3d 10 	movl   $0xf0103d15,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 98 40 10 f0 	movl   $0xf0104098,(%esp)
f0100665:	e8 ac 25 00 00       	call   f0102c16 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 04 73 11 	movl   $0x117304,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 04 73 11 	movl   $0xf0117304,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 bc 40 10 f0 	movl   $0xf01040bc,(%esp)
f0100681:	e8 90 25 00 00       	call   f0102c16 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 ac 79 11 	movl   $0x1179ac,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 ac 79 11 	movl   $0xf01179ac,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 e0 40 10 f0 	movl   $0xf01040e0,(%esp)
f010069d:	e8 74 25 00 00       	call   f0102c16 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006a2:	b8 ab 7d 11 f0       	mov    $0xf0117dab,%eax
f01006a7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ac:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006b2:	85 c0                	test   %eax,%eax
f01006b4:	0f 48 c2             	cmovs  %edx,%eax
f01006b7:	c1 f8 0a             	sar    $0xa,%eax
f01006ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006be:	c7 04 24 04 41 10 f0 	movl   $0xf0104104,(%esp)
f01006c5:	e8 4c 25 00 00       	call   f0102c16 <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01006ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01006cf:	c9                   	leave  
f01006d0:	c3                   	ret    

f01006d1 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006d1:	55                   	push   %ebp
f01006d2:	89 e5                	mov    %esp,%ebp
f01006d4:	53                   	push   %ebx
f01006d5:	83 ec 14             	sub    $0x14,%esp
f01006d8:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006dd:	8b 83 04 42 10 f0    	mov    -0xfefbdfc(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 00 42 10 f0    	mov    -0xfefbe00(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 c9 3f 10 f0 	movl   $0xf0103fc9,(%esp)
f01006f8:	e8 19 25 00 00       	call   f0102c16 <cprintf>
f01006fd:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100700:	83 fb 24             	cmp    $0x24,%ebx
f0100703:	75 d8                	jne    f01006dd <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100705:	b8 00 00 00 00       	mov    $0x0,%eax
f010070a:	83 c4 14             	add    $0x14,%esp
f010070d:	5b                   	pop    %ebx
f010070e:	5d                   	pop    %ebp
f010070f:	c3                   	ret    

f0100710 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100710:	55                   	push   %ebp
f0100711:	89 e5                	mov    %esp,%ebp
f0100713:	57                   	push   %edi
f0100714:	56                   	push   %esi
f0100715:	53                   	push   %ebx
f0100716:	81 ec 8c 00 00 00    	sub    $0x8c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010071c:	89 eb                	mov    %ebp,%ebx
f010071e:	89 de                	mov    %ebx,%esi
	// Your code here.
	uint32_t ebp,eip,arg[5];
	ebp = read_ebp();
	eip = *((uint32_t*)ebp+1);
f0100720:	8b 7b 04             	mov    0x4(%ebx),%edi
	arg[0] = *((uint32_t*)ebp+2);
f0100723:	8b 43 08             	mov    0x8(%ebx),%eax
f0100726:	89 45 a4             	mov    %eax,-0x5c(%ebp)
	arg[1] = *((uint32_t*)ebp+3);
f0100729:	8b 43 0c             	mov    0xc(%ebx),%eax
f010072c:	89 45 a0             	mov    %eax,-0x60(%ebp)
	arg[2] = *((uint32_t*)ebp+4);
f010072f:	8b 43 10             	mov    0x10(%ebx),%eax
f0100732:	89 45 9c             	mov    %eax,-0x64(%ebp)
	arg[3] = *((uint32_t*)ebp+5);
f0100735:	8b 43 14             	mov    0x14(%ebx),%eax
f0100738:	89 45 98             	mov    %eax,-0x68(%ebp)
	arg[4] = *((uint32_t*)ebp+6);
f010073b:	8b 43 18             	mov    0x18(%ebx),%eax
f010073e:	89 45 94             	mov    %eax,-0x6c(%ebp)

	cprintf("Stack backtrace:\n");
f0100741:	c7 04 24 d2 3f 10 f0 	movl   $0xf0103fd2,(%esp)
f0100748:	e8 c9 24 00 00       	call   f0102c16 <cprintf>
	
	while(ebp != 0x00)
f010074d:	85 db                	test   %ebx,%ebx
f010074f:	0f 84 e0 00 00 00    	je     f0100835 <mon_backtrace+0x125>
			info.eip_fn_name = "<unknown>";
			info.eip_fn_namelen = 9;
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f0100755:	8d 5d d0             	lea    -0x30(%ebp),%ebx
f0100758:	8b 45 9c             	mov    -0x64(%ebp),%eax
f010075b:	8b 55 98             	mov    -0x68(%ebp),%edx
f010075e:	8b 4d 94             	mov    -0x6c(%ebp),%ecx
	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
		{
			
			cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp,eip,arg[0],arg[1],arg[2],arg[3],arg[4]);
f0100761:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0100765:	89 54 24 18          	mov    %edx,0x18(%esp)
f0100769:	89 44 24 14          	mov    %eax,0x14(%esp)
f010076d:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100770:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100774:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100777:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010077b:	89 7c 24 08          	mov    %edi,0x8(%esp)
f010077f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100783:	c7 04 24 30 41 10 f0 	movl   $0xf0104130,(%esp)
f010078a:	e8 87 24 00 00       	call   f0102c16 <cprintf>
			struct Eipdebuginfo info;
			info.eip_file = "<unknown>";
f010078f:	c7 45 d0 e4 3f 10 f0 	movl   $0xf0103fe4,-0x30(%ebp)
			info.eip_line = 0;
f0100796:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
			info.eip_fn_name = "<unknown>";
f010079d:	c7 45 d8 e4 3f 10 f0 	movl   $0xf0103fe4,-0x28(%ebp)
			info.eip_fn_namelen = 9;
f01007a4:	c7 45 dc 09 00 00 00 	movl   $0x9,-0x24(%ebp)
			info.eip_fn_addr = eip;
f01007ab:	89 7d e0             	mov    %edi,-0x20(%ebp)
			info.eip_fn_narg = 0;
f01007ae:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
f01007b5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007b9:	89 3c 24             	mov    %edi,(%esp)
f01007bc:	e8 4f 25 00 00       	call   f0102d10 <debuginfo_eip>
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f01007c1:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f01007c4:	0f b6 11             	movzbl (%ecx),%edx
f01007c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007cc:	80 fa 3a             	cmp    $0x3a,%dl
f01007cf:	74 15                	je     f01007e6 <mon_backtrace+0xd6>
				display_eip_fn_name[i]=info.eip_fn_name[i];
f01007d1:	88 54 05 b2          	mov    %dl,-0x4e(%ebp,%eax,1)
			info.eip_fn_addr = eip;
			info.eip_fn_narg = 0;
			char display_eip_fn_name[30];
			debuginfo_eip(eip,&info);
			int i;
			for ( i=0;(info.eip_fn_name[i]!=':')&&( i<30); i++)
f01007d5:	83 c0 01             	add    $0x1,%eax
f01007d8:	0f b6 14 01          	movzbl (%ecx,%eax,1),%edx
f01007dc:	80 fa 3a             	cmp    $0x3a,%dl
f01007df:	74 05                	je     f01007e6 <mon_backtrace+0xd6>
f01007e1:	83 f8 1d             	cmp    $0x1d,%eax
f01007e4:	7e eb                	jle    f01007d1 <mon_backtrace+0xc1>
				display_eip_fn_name[i]=info.eip_fn_name[i];
			display_eip_fn_name[i]='\0';
f01007e6:	c6 44 05 b2 00       	movb   $0x0,-0x4e(%ebp,%eax,1)
			cprintf("    %s:%d: %s+%d\n",info.eip_file,info.eip_line,display_eip_fn_name,(eip-info.eip_fn_addr));
f01007eb:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007ee:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01007f2:	8d 45 b2             	lea    -0x4e(%ebp),%eax
f01007f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007fc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100800:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100803:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100807:	c7 04 24 ee 3f 10 f0 	movl   $0xf0103fee,(%esp)
f010080e:	e8 03 24 00 00       	call   f0102c16 <cprintf>
			ebp = *(uint32_t *)ebp;
f0100813:	8b 36                	mov    (%esi),%esi
			eip = *((uint32_t*)ebp+1);
f0100815:	8b 7e 04             	mov    0x4(%esi),%edi
			arg[0] = *((uint32_t*)ebp+2);
f0100818:	8b 46 08             	mov    0x8(%esi),%eax
f010081b:	89 45 a4             	mov    %eax,-0x5c(%ebp)
			arg[1] = *((uint32_t*)ebp+3);
f010081e:	8b 46 0c             	mov    0xc(%esi),%eax
f0100821:	89 45 a0             	mov    %eax,-0x60(%ebp)
			arg[2] = *((uint32_t*)ebp+4);
f0100824:	8b 46 10             	mov    0x10(%esi),%eax
			arg[3] = *((uint32_t*)ebp+5);
f0100827:	8b 56 14             	mov    0x14(%esi),%edx
			arg[4] = *((uint32_t*)ebp+6);
f010082a:	8b 4e 18             	mov    0x18(%esi),%ecx
	arg[3] = *((uint32_t*)ebp+5);
	arg[4] = *((uint32_t*)ebp+6);

	cprintf("Stack backtrace:\n");
	
	while(ebp != 0x00)
f010082d:	85 f6                	test   %esi,%esi
f010082f:	0f 85 2c ff ff ff    	jne    f0100761 <mon_backtrace+0x51>
			arg[3] = *((uint32_t*)ebp+5);
			arg[4] = *((uint32_t*)ebp+6);
			
		}
	return 0;
}
f0100835:	b8 00 00 00 00       	mov    $0x0,%eax
f010083a:	81 c4 8c 00 00 00    	add    $0x8c,%esp
f0100840:	5b                   	pop    %ebx
f0100841:	5e                   	pop    %esi
f0100842:	5f                   	pop    %edi
f0100843:	5d                   	pop    %ebp
f0100844:	c3                   	ret    

f0100845 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100845:	55                   	push   %ebp
f0100846:	89 e5                	mov    %esp,%ebp
f0100848:	57                   	push   %edi
f0100849:	56                   	push   %esi
f010084a:	53                   	push   %ebx
f010084b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010084e:	c7 04 24 64 41 10 f0 	movl   $0xf0104164,(%esp)
f0100855:	e8 bc 23 00 00       	call   f0102c16 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010085a:	c7 04 24 88 41 10 f0 	movl   $0xf0104188,(%esp)
f0100861:	e8 b0 23 00 00       	call   f0102c16 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100866:	c7 04 24 00 40 10 f0 	movl   $0xf0104000,(%esp)
f010086d:	e8 1e 2d 00 00       	call   f0103590 <readline>
f0100872:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100874:	85 c0                	test   %eax,%eax
f0100876:	74 ee                	je     f0100866 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100878:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010087f:	be 00 00 00 00       	mov    $0x0,%esi
f0100884:	eb 06                	jmp    f010088c <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100886:	c6 03 00             	movb   $0x0,(%ebx)
f0100889:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010088c:	0f b6 03             	movzbl (%ebx),%eax
f010088f:	84 c0                	test   %al,%al
f0100891:	74 6a                	je     f01008fd <monitor+0xb8>
f0100893:	0f be c0             	movsbl %al,%eax
f0100896:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089a:	c7 04 24 04 40 10 f0 	movl   $0xf0104004,(%esp)
f01008a1:	e8 15 2f 00 00       	call   f01037bb <strchr>
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	75 dc                	jne    f0100886 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008aa:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008ad:	74 4e                	je     f01008fd <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008af:	83 fe 0f             	cmp    $0xf,%esi
f01008b2:	75 16                	jne    f01008ca <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008b4:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008bb:	00 
f01008bc:	c7 04 24 09 40 10 f0 	movl   $0xf0104009,(%esp)
f01008c3:	e8 4e 23 00 00       	call   f0102c16 <cprintf>
f01008c8:	eb 9c                	jmp    f0100866 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008ca:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008ce:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d1:	0f b6 03             	movzbl (%ebx),%eax
f01008d4:	84 c0                	test   %al,%al
f01008d6:	75 0c                	jne    f01008e4 <monitor+0x9f>
f01008d8:	eb b2                	jmp    f010088c <monitor+0x47>
			buf++;
f01008da:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008dd:	0f b6 03             	movzbl (%ebx),%eax
f01008e0:	84 c0                	test   %al,%al
f01008e2:	74 a8                	je     f010088c <monitor+0x47>
f01008e4:	0f be c0             	movsbl %al,%eax
f01008e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008eb:	c7 04 24 04 40 10 f0 	movl   $0xf0104004,(%esp)
f01008f2:	e8 c4 2e 00 00       	call   f01037bb <strchr>
f01008f7:	85 c0                	test   %eax,%eax
f01008f9:	74 df                	je     f01008da <monitor+0x95>
f01008fb:	eb 8f                	jmp    f010088c <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f01008fd:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100904:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100905:	85 f6                	test   %esi,%esi
f0100907:	0f 84 59 ff ff ff    	je     f0100866 <monitor+0x21>
f010090d:	bb 00 42 10 f0       	mov    $0xf0104200,%ebx
f0100912:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100917:	8b 03                	mov    (%ebx),%eax
f0100919:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091d:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100920:	89 04 24             	mov    %eax,(%esp)
f0100923:	e8 18 2e 00 00       	call   f0103740 <strcmp>
f0100928:	85 c0                	test   %eax,%eax
f010092a:	75 24                	jne    f0100950 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010092c:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f010092f:	8b 55 08             	mov    0x8(%ebp),%edx
f0100932:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100936:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100939:	89 54 24 04          	mov    %edx,0x4(%esp)
f010093d:	89 34 24             	mov    %esi,(%esp)
f0100940:	ff 14 85 08 42 10 f0 	call   *-0xfefbdf8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100947:	85 c0                	test   %eax,%eax
f0100949:	78 28                	js     f0100973 <monitor+0x12e>
f010094b:	e9 16 ff ff ff       	jmp    f0100866 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100950:	83 c7 01             	add    $0x1,%edi
f0100953:	83 c3 0c             	add    $0xc,%ebx
f0100956:	83 ff 03             	cmp    $0x3,%edi
f0100959:	75 bc                	jne    f0100917 <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010095b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010095e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100962:	c7 04 24 26 40 10 f0 	movl   $0xf0104026,(%esp)
f0100969:	e8 a8 22 00 00       	call   f0102c16 <cprintf>
f010096e:	e9 f3 fe ff ff       	jmp    f0100866 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100973:	83 c4 5c             	add    $0x5c,%esp
f0100976:	5b                   	pop    %ebx
f0100977:	5e                   	pop    %esi
f0100978:	5f                   	pop    %edi
f0100979:	5d                   	pop    %ebp
f010097a:	c3                   	ret    

f010097b <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010097b:	55                   	push   %ebp
f010097c:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f010097e:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100981:	5d                   	pop    %ebp
f0100982:	c3                   	ret    
	...

f0100984 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100984:	55                   	push   %ebp
f0100985:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100987:	83 3d 7c 75 11 f0 00 	cmpl   $0x0,0xf011757c
f010098e:	75 11                	jne    f01009a1 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100990:	ba ab 89 11 f0       	mov    $0xf01189ab,%edx
f0100995:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010099b:	89 15 7c 75 11 f0    	mov    %edx,0xf011757c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = ROUNDUP(nextfree, PGSIZE);
f01009a1:	8b 15 7c 75 11 f0    	mov    0xf011757c,%edx
f01009a7:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f01009ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	nextfree = result + n;
f01009b3:	01 d0                	add    %edx,%eax
f01009b5:	a3 7c 75 11 f0       	mov    %eax,0xf011757c
	//cprintf("\nnextfree:0x%08x",nextfree);
	return result;
}
f01009ba:	89 d0                	mov    %edx,%eax
f01009bc:	5d                   	pop    %ebp
f01009bd:	c3                   	ret    

f01009be <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01009be:	55                   	push   %ebp
f01009bf:	89 e5                	mov    %esp,%ebp
f01009c1:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01009c4:	89 d1                	mov    %edx,%ecx
f01009c6:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f01009c9:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f01009cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f01009d1:	f6 c1 01             	test   $0x1,%cl
f01009d4:	74 57                	je     f0100a2d <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f01009d6:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009dc:	89 c8                	mov    %ecx,%eax
f01009de:	c1 e8 0c             	shr    $0xc,%eax
f01009e1:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f01009e7:	72 20                	jb     f0100a09 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009e9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01009ed:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f01009f4:	f0 
f01009f5:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f01009fc:	00 
f01009fd:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100a04:	e8 8b f6 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100a09:	c1 ea 0c             	shr    $0xc,%edx
f0100a0c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a12:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0100a19:	89 c2                	mov    %eax,%edx
f0100a1b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a1e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a23:	85 d2                	test   %edx,%edx
f0100a25:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a2a:	0f 44 c2             	cmove  %edx,%eax
}
f0100a2d:	c9                   	leave  
f0100a2e:	c3                   	ret    

f0100a2f <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a2f:	55                   	push   %ebp
f0100a30:	89 e5                	mov    %esp,%ebp
f0100a32:	83 ec 18             	sub    $0x18,%esp
f0100a35:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a38:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a3b:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a3d:	89 04 24             	mov    %eax,(%esp)
f0100a40:	e8 63 21 00 00       	call   f0102ba8 <mc146818_read>
f0100a45:	89 c6                	mov    %eax,%esi
f0100a47:	83 c3 01             	add    $0x1,%ebx
f0100a4a:	89 1c 24             	mov    %ebx,(%esp)
f0100a4d:	e8 56 21 00 00       	call   f0102ba8 <mc146818_read>
f0100a52:	c1 e0 08             	shl    $0x8,%eax
f0100a55:	09 f0                	or     %esi,%eax
}
f0100a57:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a5a:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a5d:	89 ec                	mov    %ebp,%esp
f0100a5f:	5d                   	pop    %ebp
f0100a60:	c3                   	ret    

f0100a61 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a61:	55                   	push   %ebp
f0100a62:	89 e5                	mov    %esp,%ebp
f0100a64:	57                   	push   %edi
f0100a65:	56                   	push   %esi
f0100a66:	53                   	push   %ebx
f0100a67:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a6a:	83 f8 01             	cmp    $0x1,%eax
f0100a6d:	19 f6                	sbb    %esi,%esi
f0100a6f:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100a75:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100a78:	8b 1d 80 75 11 f0    	mov    0xf0117580,%ebx
f0100a7e:	85 db                	test   %ebx,%ebx
f0100a80:	75 1c                	jne    f0100a9e <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100a82:	c7 44 24 08 48 42 10 	movl   $0xf0104248,0x8(%esp)
f0100a89:	f0 
f0100a8a:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
f0100a91:	00 
f0100a92:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100a99:	e8 f6 f5 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100a9e:	85 c0                	test   %eax,%eax
f0100aa0:	74 50                	je     f0100af2 <check_page_free_list+0x91>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100aa2:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100aa5:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100aa8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100aab:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aae:	89 d8                	mov    %ebx,%eax
f0100ab0:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0100ab6:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ab9:	c1 e8 16             	shr    $0x16,%eax
f0100abc:	39 f0                	cmp    %esi,%eax
f0100abe:	0f 93 c0             	setae  %al
f0100ac1:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100ac4:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100ac8:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100aca:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ace:	8b 1b                	mov    (%ebx),%ebx
f0100ad0:	85 db                	test   %ebx,%ebx
f0100ad2:	75 da                	jne    f0100aae <check_page_free_list+0x4d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ad4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ad7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100add:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ae0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ae3:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ae5:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ae8:	89 1d 80 75 11 f0    	mov    %ebx,0xf0117580
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aee:	85 db                	test   %ebx,%ebx
f0100af0:	74 67                	je     f0100b59 <check_page_free_list+0xf8>
f0100af2:	89 d8                	mov    %ebx,%eax
f0100af4:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0100afa:	c1 f8 03             	sar    $0x3,%eax
f0100afd:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b00:	89 c2                	mov    %eax,%edx
f0100b02:	c1 ea 16             	shr    $0x16,%edx
f0100b05:	39 f2                	cmp    %esi,%edx
f0100b07:	73 4a                	jae    f0100b53 <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b09:	89 c2                	mov    %eax,%edx
f0100b0b:	c1 ea 0c             	shr    $0xc,%edx
f0100b0e:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0100b14:	72 20                	jb     f0100b36 <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b16:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b1a:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0100b21:	f0 
f0100b22:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b29:	00 
f0100b2a:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f0100b31:	e8 5e f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b36:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b3d:	00 
f0100b3e:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b45:	00 
	return (void *)(pa + KERNBASE);
f0100b46:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b4b:	89 04 24             	mov    %eax,(%esp)
f0100b4e:	e8 c3 2c 00 00       	call   f0103816 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b53:	8b 1b                	mov    (%ebx),%ebx
f0100b55:	85 db                	test   %ebx,%ebx
f0100b57:	75 99                	jne    f0100af2 <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b59:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b5e:	e8 21 fe ff ff       	call   f0100984 <boot_alloc>
f0100b63:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b66:	8b 15 80 75 11 f0    	mov    0xf0117580,%edx
f0100b6c:	85 d2                	test   %edx,%edx
f0100b6e:	0f 84 f6 01 00 00    	je     f0100d6a <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b74:	8b 1d a8 79 11 f0    	mov    0xf01179a8,%ebx
f0100b7a:	39 da                	cmp    %ebx,%edx
f0100b7c:	72 4d                	jb     f0100bcb <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f0100b7e:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f0100b83:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b86:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b89:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b8c:	39 c2                	cmp    %eax,%edx
f0100b8e:	73 64                	jae    f0100bf4 <check_page_free_list+0x193>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b90:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b93:	89 d0                	mov    %edx,%eax
f0100b95:	29 d8                	sub    %ebx,%eax
f0100b97:	a8 07                	test   $0x7,%al
f0100b99:	0f 85 82 00 00 00    	jne    f0100c21 <check_page_free_list+0x1c0>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b9f:	c1 f8 03             	sar    $0x3,%eax
f0100ba2:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ba5:	85 c0                	test   %eax,%eax
f0100ba7:	0f 84 a2 00 00 00    	je     f0100c4f <check_page_free_list+0x1ee>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bad:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bb2:	0f 84 c2 00 00 00    	je     f0100c7a <check_page_free_list+0x219>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bb8:	be 00 00 00 00       	mov    $0x0,%esi
f0100bbd:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bc2:	e9 d7 00 00 00       	jmp    f0100c9e <check_page_free_list+0x23d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bc7:	39 da                	cmp    %ebx,%edx
f0100bc9:	73 24                	jae    f0100bef <check_page_free_list+0x18e>
f0100bcb:	c7 44 24 0c 26 49 10 	movl   $0xf0104926,0xc(%esp)
f0100bd2:	f0 
f0100bd3:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100bda:	f0 
f0100bdb:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100be2:	00 
f0100be3:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100bea:	e8 a5 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bef:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bf2:	72 24                	jb     f0100c18 <check_page_free_list+0x1b7>
f0100bf4:	c7 44 24 0c 47 49 10 	movl   $0xf0104947,0xc(%esp)
f0100bfb:	f0 
f0100bfc:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100c03:	f0 
f0100c04:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0100c0b:	00 
f0100c0c:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100c13:	e8 7c f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c18:	89 d0                	mov    %edx,%eax
f0100c1a:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c1d:	a8 07                	test   $0x7,%al
f0100c1f:	74 24                	je     f0100c45 <check_page_free_list+0x1e4>
f0100c21:	c7 44 24 0c 6c 42 10 	movl   $0xf010426c,0xc(%esp)
f0100c28:	f0 
f0100c29:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100c30:	f0 
f0100c31:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f0100c38:	00 
f0100c39:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100c40:	e8 4f f4 ff ff       	call   f0100094 <_panic>
f0100c45:	c1 f8 03             	sar    $0x3,%eax
f0100c48:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c4b:	85 c0                	test   %eax,%eax
f0100c4d:	75 24                	jne    f0100c73 <check_page_free_list+0x212>
f0100c4f:	c7 44 24 0c 5b 49 10 	movl   $0xf010495b,0xc(%esp)
f0100c56:	f0 
f0100c57:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100c5e:	f0 
f0100c5f:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
f0100c66:	00 
f0100c67:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100c6e:	e8 21 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c73:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c78:	75 24                	jne    f0100c9e <check_page_free_list+0x23d>
f0100c7a:	c7 44 24 0c 6c 49 10 	movl   $0xf010496c,0xc(%esp)
f0100c81:	f0 
f0100c82:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100c89:	f0 
f0100c8a:	c7 44 24 04 3e 02 00 	movl   $0x23e,0x4(%esp)
f0100c91:	00 
f0100c92:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100c99:	e8 f6 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c9e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ca3:	75 24                	jne    f0100cc9 <check_page_free_list+0x268>
f0100ca5:	c7 44 24 0c a0 42 10 	movl   $0xf01042a0,0xc(%esp)
f0100cac:	f0 
f0100cad:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100cb4:	f0 
f0100cb5:	c7 44 24 04 3f 02 00 	movl   $0x23f,0x4(%esp)
f0100cbc:	00 
f0100cbd:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100cc4:	e8 cb f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cc9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cce:	75 24                	jne    f0100cf4 <check_page_free_list+0x293>
f0100cd0:	c7 44 24 0c 85 49 10 	movl   $0xf0104985,0xc(%esp)
f0100cd7:	f0 
f0100cd8:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100cdf:	f0 
f0100ce0:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
f0100ce7:	00 
f0100ce8:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100cef:	e8 a0 f3 ff ff       	call   f0100094 <_panic>
f0100cf4:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cf6:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cfb:	76 57                	jbe    f0100d54 <check_page_free_list+0x2f3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cfd:	c1 e8 0c             	shr    $0xc,%eax
f0100d00:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d03:	77 20                	ja     f0100d25 <check_page_free_list+0x2c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d05:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d09:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0100d10:	f0 
f0100d11:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d18:	00 
f0100d19:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f0100d20:	e8 6f f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d25:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d2b:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100d2e:	76 29                	jbe    f0100d59 <check_page_free_list+0x2f8>
f0100d30:	c7 44 24 0c c4 42 10 	movl   $0xf01042c4,0xc(%esp)
f0100d37:	f0 
f0100d38:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100d3f:	f0 
f0100d40:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
f0100d47:	00 
f0100d48:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100d4f:	e8 40 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d54:	83 c7 01             	add    $0x1,%edi
f0100d57:	eb 03                	jmp    f0100d5c <check_page_free_list+0x2fb>
		else
			++nfree_extmem;
f0100d59:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d5c:	8b 12                	mov    (%edx),%edx
f0100d5e:	85 d2                	test   %edx,%edx
f0100d60:	0f 85 61 fe ff ff    	jne    f0100bc7 <check_page_free_list+0x166>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d66:	85 ff                	test   %edi,%edi
f0100d68:	7f 24                	jg     f0100d8e <check_page_free_list+0x32d>
f0100d6a:	c7 44 24 0c 9f 49 10 	movl   $0xf010499f,0xc(%esp)
f0100d71:	f0 
f0100d72:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100d79:	f0 
f0100d7a:	c7 44 24 04 49 02 00 	movl   $0x249,0x4(%esp)
f0100d81:	00 
f0100d82:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100d89:	e8 06 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d8e:	85 f6                	test   %esi,%esi
f0100d90:	7f 24                	jg     f0100db6 <check_page_free_list+0x355>
f0100d92:	c7 44 24 0c b1 49 10 	movl   $0xf01049b1,0xc(%esp)
f0100d99:	f0 
f0100d9a:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0100da1:	f0 
f0100da2:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
f0100da9:	00 
f0100daa:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100db1:	e8 de f2 ff ff       	call   f0100094 <_panic>
}
f0100db6:	83 c4 3c             	add    $0x3c,%esp
f0100db9:	5b                   	pop    %ebx
f0100dba:	5e                   	pop    %esi
f0100dbb:	5f                   	pop    %edi
f0100dbc:	5d                   	pop    %ebp
f0100dbd:	c3                   	ret    

f0100dbe <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dbe:	55                   	push   %ebp
f0100dbf:	89 e5                	mov    %esp,%ebp
f0100dc1:	56                   	push   %esi
f0100dc2:	53                   	push   %ebx
f0100dc3:	83 ec 10             	sub    $0x10,%esp
	// free pages!
	size_t i;
	//size_t a=0;
	//size_t b=0;
	//size_t c=0;
	page_free_list = NULL;
f0100dc6:	c7 05 80 75 11 f0 00 	movl   $0x0,0xf0117580
f0100dcd:	00 00 00 
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
f0100dd0:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f0100dd5:	89 c6                	mov    %eax,%esi
f0100dd7:	c1 e6 06             	shl    $0x6,%esi
f0100dda:	03 35 a8 79 11 f0    	add    0xf01179a8,%esi
f0100de0:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f0100de6:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100dec:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0100df2:	77 20                	ja     f0100e14 <page_init+0x56>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100df4:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100df8:	c7 44 24 08 0c 43 10 	movl   $0xf010430c,0x8(%esp)
f0100dff:	f0 
f0100e00:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
f0100e07:	00 
f0100e08:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100e0f:	e8 80 f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e14:	81 c6 00 00 00 10    	add    $0x10000000,%esi
f0100e1a:	c1 ee 0c             	shr    $0xc,%esi
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f0100e1d:	83 f8 01             	cmp    $0x1,%eax
f0100e20:	76 6f                	jbe    f0100e91 <page_init+0xd3>
f0100e22:	ba 08 00 00 00       	mov    $0x8,%edx
f0100e27:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e2c:	b8 01 00 00 00       	mov    $0x1,%eax
	{
		
		
		if(i<pgnum_IOPHYSMEM)
f0100e31:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f0100e36:	77 1a                	ja     f0100e52 <page_init+0x94>
		{
			pages[i].pp_ref = 0;
f0100e38:	89 d3                	mov    %edx,%ebx
f0100e3a:	03 1d a8 79 11 f0    	add    0xf01179a8,%ebx
f0100e40:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
			pages[i].pp_link = page_free_list;
f0100e46:	89 0b                	mov    %ecx,(%ebx)
			page_free_list = &pages[i];
f0100e48:	89 d1                	mov    %edx,%ecx
f0100e4a:	03 0d a8 79 11 f0    	add    0xf01179a8,%ecx
f0100e50:	eb 2b                	jmp    f0100e7d <page_init+0xbf>
			//a++;
		}
		else if( i>pgnum_EXTPHYSMEM)
f0100e52:	39 c6                	cmp    %eax,%esi
f0100e54:	73 1a                	jae    f0100e70 <page_init+0xb2>
		{
			pages[i].pp_ref = 0;
f0100e56:	8b 1d a8 79 11 f0    	mov    0xf01179a8,%ebx
f0100e5c:	66 c7 44 13 04 00 00 	movw   $0x0,0x4(%ebx,%edx,1)
			pages[i].pp_link = page_free_list;
f0100e63:	89 0c 13             	mov    %ecx,(%ebx,%edx,1)
			page_free_list = &pages[i];
f0100e66:	89 d1                	mov    %edx,%ecx
f0100e68:	03 0d a8 79 11 f0    	add    0xf01179a8,%ecx
f0100e6e:	eb 0d                	jmp    f0100e7d <page_init+0xbf>
			//b++;
		}
		else
		{
			pages[i].pp_ref = 1;
f0100e70:	8b 1d a8 79 11 f0    	mov    0xf01179a8,%ebx
f0100e76:	66 c7 44 13 04 01 00 	movw   $0x1,0x4(%ebx,%edx,1)
	//size_t c=0;
	page_free_list = NULL;
	physaddr_t pgnum_IOPHYSMEM = PGNUM (IOPHYSMEM);
	physaddr_t pgnum_EXTPHYSMEM =PGNUM ( PADDR (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE)));
	//PGNUM (ROUNDUP(pages+npages* sizeof (struct Page),PGSIZE))-PGNUM(kern_pgdir)+PGNUM(EXTPHYSMEM);
	for (i = 1; i < npages; i++) 
f0100e7d:	83 c0 01             	add    $0x1,%eax
f0100e80:	83 c2 08             	add    $0x8,%edx
f0100e83:	39 05 a0 79 11 f0    	cmp    %eax,0xf01179a0
f0100e89:	77 a6                	ja     f0100e31 <page_init+0x73>
f0100e8b:	89 0d 80 75 11 f0    	mov    %ecx,0xf0117580
			pages[i].pp_ref = 1;
			//c++;
		}
	}
	//cprintf("\n a:%d,b:%d c:%d  ",a,b,c);
}
f0100e91:	83 c4 10             	add    $0x10,%esp
f0100e94:	5b                   	pop    %ebx
f0100e95:	5e                   	pop    %esi
f0100e96:	5d                   	pop    %ebp
f0100e97:	c3                   	ret    

f0100e98 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100e98:	55                   	push   %ebp
f0100e99:	89 e5                	mov    %esp,%ebp
f0100e9b:	53                   	push   %ebx
f0100e9c:	83 ec 14             	sub    $0x14,%esp
f0100e9f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	if ((alloc_flags==0 ||alloc_flags==ALLOC_ZERO)&& page_free_list!=NULL)
f0100ea2:	83 f8 01             	cmp    $0x1,%eax
f0100ea5:	77 71                	ja     f0100f18 <page_alloc+0x80>
f0100ea7:	8b 1d 80 75 11 f0    	mov    0xf0117580,%ebx
f0100ead:	85 db                	test   %ebx,%ebx
f0100eaf:	74 6c                	je     f0100f1d <page_alloc+0x85>
	{
		struct Page * temp_alloc_page = page_free_list;
		if(page_free_list->pp_link!=NULL)
f0100eb1:	8b 13                	mov    (%ebx),%edx
			page_free_list=page_free_list->pp_link;
f0100eb3:	89 15 80 75 11 f0    	mov    %edx,0xf0117580
		else 
			page_free_list=NULL;
		if(alloc_flags==ALLOC_ZERO)
f0100eb9:	83 f8 01             	cmp    $0x1,%eax
f0100ebc:	75 5f                	jne    f0100f1d <page_alloc+0x85>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ebe:	89 d8                	mov    %ebx,%eax
f0100ec0:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0100ec6:	c1 f8 03             	sar    $0x3,%eax
f0100ec9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ecc:	89 c2                	mov    %eax,%edx
f0100ece:	c1 ea 0c             	shr    $0xc,%edx
f0100ed1:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0100ed7:	72 20                	jb     f0100ef9 <page_alloc+0x61>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ed9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100edd:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0100ee4:	f0 
f0100ee5:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100eec:	00 
f0100eed:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f0100ef4:	e8 9b f1 ff ff       	call   f0100094 <_panic>
			memset(page2kva(temp_alloc_page), 0, PGSIZE);
f0100ef9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f00:	00 
f0100f01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f08:	00 
	return (void *)(pa + KERNBASE);
f0100f09:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f0e:	89 04 24             	mov    %eax,(%esp)
f0100f11:	e8 00 29 00 00       	call   f0103816 <memset>
f0100f16:	eb 05                	jmp    f0100f1d <page_alloc+0x85>
		return temp_alloc_page;
	}
	else
		return NULL;
f0100f18:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0100f1d:	89 d8                	mov    %ebx,%eax
f0100f1f:	83 c4 14             	add    $0x14,%esp
f0100f22:	5b                   	pop    %ebx
f0100f23:	5d                   	pop    %ebp
f0100f24:	c3                   	ret    

f0100f25 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f25:	55                   	push   %ebp
f0100f26:	89 e5                	mov    %esp,%ebp
f0100f28:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
//	pp->pp_ref = 0;
	pp->pp_link = page_free_list;
f0100f2b:	8b 15 80 75 11 f0    	mov    0xf0117580,%edx
f0100f31:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f33:	a3 80 75 11 f0       	mov    %eax,0xf0117580
}
f0100f38:	5d                   	pop    %ebp
f0100f39:	c3                   	ret    

f0100f3a <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f3a:	55                   	push   %ebp
f0100f3b:	89 e5                	mov    %esp,%ebp
f0100f3d:	83 ec 04             	sub    $0x4,%esp
f0100f40:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f43:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f47:	83 ea 01             	sub    $0x1,%edx
f0100f4a:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f4e:	66 85 d2             	test   %dx,%dx
f0100f51:	75 08                	jne    f0100f5b <page_decref+0x21>
		page_free(pp);
f0100f53:	89 04 24             	mov    %eax,(%esp)
f0100f56:	e8 ca ff ff ff       	call   f0100f25 <page_free>
}
f0100f5b:	c9                   	leave  
f0100f5c:	c3                   	ret    

f0100f5d <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f5d:	55                   	push   %ebp
f0100f5e:	89 e5                	mov    %esp,%ebp
f0100f60:	56                   	push   %esi
f0100f61:	53                   	push   %ebx
f0100f62:	83 ec 10             	sub    $0x10,%esp
f0100f65:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t *pde;//page directory entry,
	pte_t *pte;//page table entry
	pde=(pde_t *)pgdir+PDX(va);//get the entry of pde
f0100f68:	89 f3                	mov    %esi,%ebx
f0100f6a:	c1 eb 16             	shr    $0x16,%ebx
f0100f6d:	c1 e3 02             	shl    $0x2,%ebx
f0100f70:	03 5d 08             	add    0x8(%ebp),%ebx

	if (*pde & PTE_P)//the address exists
f0100f73:	8b 03                	mov    (%ebx),%eax
f0100f75:	a8 01                	test   $0x1,%al
f0100f77:	74 44                	je     f0100fbd <pgdir_walk+0x60>
	{
		pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f0100f79:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f7e:	89 c2                	mov    %eax,%edx
f0100f80:	c1 ea 0c             	shr    $0xc,%edx
f0100f83:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0100f89:	72 20                	jb     f0100fab <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f8f:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0100f96:	f0 
f0100f97:	c7 44 24 04 72 01 00 	movl   $0x172,0x4(%esp)
f0100f9e:	00 
f0100f9f:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0100fa6:	e8 e9 f0 ff ff       	call   f0100094 <_panic>
f0100fab:	c1 ee 0a             	shr    $0xa,%esi
f0100fae:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100fb4:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
		return pte;
f0100fbb:	eb 7d                	jmp    f010103a <pgdir_walk+0xdd>
	}
	//the page does not exist
	if (create )//create a new page table 
f0100fbd:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fc1:	74 6b                	je     f010102e <pgdir_walk+0xd1>
	{	
		struct Page *pp;
		pp=page_alloc(ALLOC_ZERO);
f0100fc3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fca:	e8 c9 fe ff ff       	call   f0100e98 <page_alloc>
		if (pp!=NULL)
f0100fcf:	85 c0                	test   %eax,%eax
f0100fd1:	74 62                	je     f0101035 <pgdir_walk+0xd8>
		{
			pp->pp_ref=1;
f0100fd3:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fd9:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0100fdf:	c1 f8 03             	sar    $0x3,%eax
f0100fe2:	c1 e0 0c             	shl    $0xc,%eax
			*pde = page2pa(pp)|PTE_U|PTE_W|PTE_P ;
f0100fe5:	83 c8 07             	or     $0x7,%eax
f0100fe8:	89 03                	mov    %eax,(%ebx)
			pte=(pte_t *)KADDR(PTE_ADDR(*pde))+PTX(va);
f0100fea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fef:	89 c2                	mov    %eax,%edx
f0100ff1:	c1 ea 0c             	shr    $0xc,%edx
f0100ff4:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0100ffa:	72 20                	jb     f010101c <pgdir_walk+0xbf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ffc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101000:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0101007:	f0 
f0101008:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f010100f:	00 
f0101010:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101017:	e8 78 f0 ff ff       	call   f0100094 <_panic>
f010101c:	c1 ee 0a             	shr    $0xa,%esi
f010101f:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101025:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
			return pte;
f010102c:	eb 0c                	jmp    f010103a <pgdir_walk+0xdd>
		}
	}
	
	
	
	return NULL;
f010102e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101033:	eb 05                	jmp    f010103a <pgdir_walk+0xdd>
f0101035:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010103a:	83 c4 10             	add    $0x10,%esp
f010103d:	5b                   	pop    %ebx
f010103e:	5e                   	pop    %esi
f010103f:	5d                   	pop    %ebp
f0101040:	c3                   	ret    

f0101041 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101041:	55                   	push   %ebp
f0101042:	89 e5                	mov    %esp,%ebp
f0101044:	53                   	push   %ebx
f0101045:	83 ec 14             	sub    $0x14,%esp
f0101048:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk (pgdir, va, 0);
f010104b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101052:	00 
f0101053:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101056:	89 44 24 04          	mov    %eax,0x4(%esp)
f010105a:	8b 45 08             	mov    0x8(%ebp),%eax
f010105d:	89 04 24             	mov    %eax,(%esp)
f0101060:	e8 f8 fe ff ff       	call   f0100f5d <pgdir_walk>
	if (pte_store != 0) {
f0101065:	85 db                	test   %ebx,%ebx
f0101067:	74 02                	je     f010106b <page_lookup+0x2a>
		*pte_store = pte;
f0101069:	89 03                	mov    %eax,(%ebx)
		}
	if (pte != NULL && (*pte & PTE_P)) {
f010106b:	85 c0                	test   %eax,%eax
f010106d:	74 38                	je     f01010a7 <page_lookup+0x66>
f010106f:	8b 00                	mov    (%eax),%eax
f0101071:	a8 01                	test   $0x1,%al
f0101073:	74 39                	je     f01010ae <page_lookup+0x6d>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101075:	c1 e8 0c             	shr    $0xc,%eax
f0101078:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f010107e:	72 1c                	jb     f010109c <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f0101080:	c7 44 24 08 30 43 10 	movl   $0xf0104330,0x8(%esp)
f0101087:	f0 
f0101088:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f010108f:	00 
f0101090:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f0101097:	e8 f8 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010109c:	c1 e0 03             	shl    $0x3,%eax
f010109f:	03 05 a8 79 11 f0    	add    0xf01179a8,%eax
		return pa2page (PTE_ADDR (*pte));
f01010a5:	eb 0c                	jmp    f01010b3 <page_lookup+0x72>
	}
	return NULL;
f01010a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ac:	eb 05                	jmp    f01010b3 <page_lookup+0x72>
f01010ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01010b3:	83 c4 14             	add    $0x14,%esp
f01010b6:	5b                   	pop    %ebx
f01010b7:	5d                   	pop    %ebp
f01010b8:	c3                   	ret    

f01010b9 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01010b9:	55                   	push   %ebp
f01010ba:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01010bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010bf:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01010c2:	5d                   	pop    %ebp
f01010c3:	c3                   	ret    

f01010c4 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010c4:	55                   	push   %ebp
f01010c5:	89 e5                	mov    %esp,%ebp
f01010c7:	83 ec 28             	sub    $0x28,%esp
f01010ca:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01010cd:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01010d0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010d3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct Page *physpage = page_lookup (pgdir, va, &pte);
f01010d6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010d9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010dd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010e1:	89 34 24             	mov    %esi,(%esp)
f01010e4:	e8 58 ff ff ff       	call   f0101041 <page_lookup>
	if (physpage != NULL) {
f01010e9:	85 c0                	test   %eax,%eax
f01010eb:	74 1d                	je     f010110a <page_remove+0x46>
		page_decref (physpage);
f01010ed:	89 04 24             	mov    %eax,(%esp)
f01010f0:	e8 45 fe ff ff       	call   f0100f3a <page_decref>
		*pte = 0;
f01010f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01010f8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate (pgdir, va);
f01010fe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101102:	89 34 24             	mov    %esi,(%esp)
f0101105:	e8 af ff ff ff       	call   f01010b9 <tlb_invalidate>
}
}
f010110a:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f010110d:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101110:	89 ec                	mov    %ebp,%esp
f0101112:	5d                   	pop    %ebp
f0101113:	c3                   	ret    

f0101114 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101114:	55                   	push   %ebp
f0101115:	89 e5                	mov    %esp,%ebp
f0101117:	83 ec 28             	sub    $0x28,%esp
f010111a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010111d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101120:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101123:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101126:	8b 7d 10             	mov    0x10(%ebp),%edi

	pte_t * pte = pgdir_walk(pgdir, va, 1) ;
f0101129:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101130:	00 
f0101131:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101135:	8b 45 08             	mov    0x8(%ebp),%eax
f0101138:	89 04 24             	mov    %eax,(%esp)
f010113b:	e8 1d fe ff ff       	call   f0100f5d <pgdir_walk>
f0101140:	89 c3                	mov    %eax,%ebx
	if (!pte)
f0101142:	85 c0                	test   %eax,%eax
f0101144:	74 66                	je     f01011ac <page_insert+0x98>
		return -E_NO_MEM;
	if (*pte & PTE_P) {
f0101146:	8b 00                	mov    (%eax),%eax
f0101148:	a8 01                	test   $0x1,%al
f010114a:	74 3c                	je     f0101188 <page_insert+0x74>
		if (PTE_ADDR(*pte) == page2pa (pp)) {
f010114c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101151:	89 f2                	mov    %esi,%edx
f0101153:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101159:	c1 fa 03             	sar    $0x3,%edx
f010115c:	c1 e2 0c             	shl    $0xc,%edx
f010115f:	39 d0                	cmp    %edx,%eax
f0101161:	75 16                	jne    f0101179 <page_insert+0x65>
			tlb_invalidate (pgdir, va);
f0101163:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101167:	8b 45 08             	mov    0x8(%ebp),%eax
f010116a:	89 04 24             	mov    %eax,(%esp)
f010116d:	e8 47 ff ff ff       	call   f01010b9 <tlb_invalidate>
			pp -> pp_ref --;
f0101172:	66 83 6e 04 01       	subw   $0x1,0x4(%esi)
f0101177:	eb 0f                	jmp    f0101188 <page_insert+0x74>
			} else {
		page_remove (pgdir, va);
f0101179:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010117d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101180:	89 04 24             	mov    %eax,(%esp)
f0101183:	e8 3c ff ff ff       	call   f01010c4 <page_remove>
		}
	}

	*pte = page2pa (pp)|perm|PTE_P;
f0101188:	8b 45 14             	mov    0x14(%ebp),%eax
f010118b:	83 c8 01             	or     $0x1,%eax
f010118e:	89 f2                	mov    %esi,%edx
f0101190:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101196:	c1 fa 03             	sar    $0x3,%edx
f0101199:	c1 e2 0c             	shl    $0xc,%edx
f010119c:	09 d0                	or     %edx,%eax
f010119e:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f01011a0:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f01011a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01011aa:	eb 05                	jmp    f01011b1 <page_insert+0x9d>
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{

	pte_t * pte = pgdir_walk(pgdir, va, 1) ;
	if (!pte)
		return -E_NO_MEM;
f01011ac:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}

	*pte = page2pa (pp)|perm|PTE_P;
	pp->pp_ref++;
	return 0;
}
f01011b1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01011b4:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01011b7:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01011ba:	89 ec                	mov    %ebp,%esp
f01011bc:	5d                   	pop    %ebp
f01011bd:	c3                   	ret    

f01011be <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011be:	55                   	push   %ebp
f01011bf:	89 e5                	mov    %esp,%ebp
f01011c1:	57                   	push   %edi
f01011c2:	56                   	push   %esi
f01011c3:	53                   	push   %ebx
f01011c4:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01011c7:	b8 15 00 00 00       	mov    $0x15,%eax
f01011cc:	e8 5e f8 ff ff       	call   f0100a2f <nvram_read>
f01011d1:	c1 e0 0a             	shl    $0xa,%eax
f01011d4:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011da:	85 c0                	test   %eax,%eax
f01011dc:	0f 48 c2             	cmovs  %edx,%eax
f01011df:	c1 f8 0c             	sar    $0xc,%eax
f01011e2:	a3 78 75 11 f0       	mov    %eax,0xf0117578
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01011e7:	b8 17 00 00 00       	mov    $0x17,%eax
f01011ec:	e8 3e f8 ff ff       	call   f0100a2f <nvram_read>
f01011f1:	c1 e0 0a             	shl    $0xa,%eax
f01011f4:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011fa:	85 c0                	test   %eax,%eax
f01011fc:	0f 48 c2             	cmovs  %edx,%eax
f01011ff:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101202:	85 c0                	test   %eax,%eax
f0101204:	74 0e                	je     f0101214 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101206:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010120c:	89 15 a0 79 11 f0    	mov    %edx,0xf01179a0
f0101212:	eb 0c                	jmp    f0101220 <mem_init+0x62>
	else
		npages = npages_basemem;
f0101214:	8b 15 78 75 11 f0    	mov    0xf0117578,%edx
f010121a:	89 15 a0 79 11 f0    	mov    %edx,0xf01179a0

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101220:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101223:	c1 e8 0a             	shr    $0xa,%eax
f0101226:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010122a:	a1 78 75 11 f0       	mov    0xf0117578,%eax
f010122f:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101232:	c1 e8 0a             	shr    $0xa,%eax
f0101235:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101239:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f010123e:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101241:	c1 e8 0a             	shr    $0xa,%eax
f0101244:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101248:	c7 04 24 50 43 10 f0 	movl   $0xf0104350,(%esp)
f010124f:	e8 c2 19 00 00       	call   f0102c16 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101254:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101259:	e8 26 f7 ff ff       	call   f0100984 <boot_alloc>
f010125e:	a3 a4 79 11 f0       	mov    %eax,0xf01179a4
	memset(kern_pgdir, 0, PGSIZE);
f0101263:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010126a:	00 
f010126b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101272:	00 
f0101273:	89 04 24             	mov    %eax,(%esp)
f0101276:	e8 9b 25 00 00       	call   f0103816 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010127b:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101280:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101285:	77 20                	ja     f01012a7 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101287:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010128b:	c7 44 24 08 0c 43 10 	movl   $0xf010430c,0x8(%esp)
f0101292:	f0 
f0101293:	c7 44 24 04 8b 00 00 	movl   $0x8b,0x4(%esp)
f010129a:	00 
f010129b:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01012a2:	e8 ed ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01012a7:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012ad:	83 ca 05             	or     $0x5,%edx
f01012b0:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:

	pages =(struct Page *) boot_alloc(npages* sizeof (struct Page));
f01012b6:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f01012bb:	c1 e0 03             	shl    $0x3,%eax
f01012be:	e8 c1 f6 ff ff       	call   f0100984 <boot_alloc>
f01012c3:	a3 a8 79 11 f0       	mov    %eax,0xf01179a8
	memset(pages, 0, npages* sizeof (struct Page));
f01012c8:	8b 15 a0 79 11 f0    	mov    0xf01179a0,%edx
f01012ce:	c1 e2 03             	shl    $0x3,%edx
f01012d1:	89 54 24 08          	mov    %edx,0x8(%esp)
f01012d5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012dc:	00 
f01012dd:	89 04 24             	mov    %eax,(%esp)
f01012e0:	e8 31 25 00 00       	call   f0103816 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012e5:	e8 d4 fa ff ff       	call   f0100dbe <page_init>
	check_page_free_list(1);
f01012ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01012ef:	e8 6d f7 ff ff       	call   f0100a61 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01012f4:	83 3d a8 79 11 f0 00 	cmpl   $0x0,0xf01179a8
f01012fb:	75 1c                	jne    f0101319 <mem_init+0x15b>
		panic("'pages' is a null pointer!");
f01012fd:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101304:	f0 
f0101305:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f010130c:	00 
f010130d:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101314:	e8 7b ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101319:	a1 80 75 11 f0       	mov    0xf0117580,%eax
f010131e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101323:	85 c0                	test   %eax,%eax
f0101325:	74 09                	je     f0101330 <mem_init+0x172>
		++nfree;
f0101327:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010132a:	8b 00                	mov    (%eax),%eax
f010132c:	85 c0                	test   %eax,%eax
f010132e:	75 f7                	jne    f0101327 <mem_init+0x169>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101330:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101337:	e8 5c fb ff ff       	call   f0100e98 <page_alloc>
f010133c:	89 c6                	mov    %eax,%esi
f010133e:	85 c0                	test   %eax,%eax
f0101340:	75 24                	jne    f0101366 <mem_init+0x1a8>
f0101342:	c7 44 24 0c dd 49 10 	movl   $0xf01049dd,0xc(%esp)
f0101349:	f0 
f010134a:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101351:	f0 
f0101352:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f0101359:	00 
f010135a:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101361:	e8 2e ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101366:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010136d:	e8 26 fb ff ff       	call   f0100e98 <page_alloc>
f0101372:	89 c7                	mov    %eax,%edi
f0101374:	85 c0                	test   %eax,%eax
f0101376:	75 24                	jne    f010139c <mem_init+0x1de>
f0101378:	c7 44 24 0c f3 49 10 	movl   $0xf01049f3,0xc(%esp)
f010137f:	f0 
f0101380:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101387:	f0 
f0101388:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f010138f:	00 
f0101390:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101397:	e8 f8 ec ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010139c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013a3:	e8 f0 fa ff ff       	call   f0100e98 <page_alloc>
f01013a8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01013ab:	85 c0                	test   %eax,%eax
f01013ad:	75 24                	jne    f01013d3 <mem_init+0x215>
f01013af:	c7 44 24 0c 09 4a 10 	movl   $0xf0104a09,0xc(%esp)
f01013b6:	f0 
f01013b7:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01013be:	f0 
f01013bf:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f01013c6:	00 
f01013c7:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01013ce:	e8 c1 ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013d3:	39 fe                	cmp    %edi,%esi
f01013d5:	75 24                	jne    f01013fb <mem_init+0x23d>
f01013d7:	c7 44 24 0c 1f 4a 10 	movl   $0xf0104a1f,0xc(%esp)
f01013de:	f0 
f01013df:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01013e6:	f0 
f01013e7:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f01013ee:	00 
f01013ef:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01013f6:	e8 99 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013fb:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01013fe:	74 05                	je     f0101405 <mem_init+0x247>
f0101400:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101403:	75 24                	jne    f0101429 <mem_init+0x26b>
f0101405:	c7 44 24 0c 8c 43 10 	movl   $0xf010438c,0xc(%esp)
f010140c:	f0 
f010140d:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101414:	f0 
f0101415:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f010141c:	00 
f010141d:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101424:	e8 6b ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101429:	8b 15 a8 79 11 f0    	mov    0xf01179a8,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010142f:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f0101434:	c1 e0 0c             	shl    $0xc,%eax
f0101437:	89 f1                	mov    %esi,%ecx
f0101439:	29 d1                	sub    %edx,%ecx
f010143b:	c1 f9 03             	sar    $0x3,%ecx
f010143e:	c1 e1 0c             	shl    $0xc,%ecx
f0101441:	39 c1                	cmp    %eax,%ecx
f0101443:	72 24                	jb     f0101469 <mem_init+0x2ab>
f0101445:	c7 44 24 0c 31 4a 10 	movl   $0xf0104a31,0xc(%esp)
f010144c:	f0 
f010144d:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101454:	f0 
f0101455:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f010145c:	00 
f010145d:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101464:	e8 2b ec ff ff       	call   f0100094 <_panic>
f0101469:	89 f9                	mov    %edi,%ecx
f010146b:	29 d1                	sub    %edx,%ecx
f010146d:	c1 f9 03             	sar    $0x3,%ecx
f0101470:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101473:	39 c8                	cmp    %ecx,%eax
f0101475:	77 24                	ja     f010149b <mem_init+0x2dd>
f0101477:	c7 44 24 0c 4e 4a 10 	movl   $0xf0104a4e,0xc(%esp)
f010147e:	f0 
f010147f:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101486:	f0 
f0101487:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f010148e:	00 
f010148f:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101496:	e8 f9 eb ff ff       	call   f0100094 <_panic>
f010149b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010149e:	29 d1                	sub    %edx,%ecx
f01014a0:	89 ca                	mov    %ecx,%edx
f01014a2:	c1 fa 03             	sar    $0x3,%edx
f01014a5:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01014a8:	39 d0                	cmp    %edx,%eax
f01014aa:	77 24                	ja     f01014d0 <mem_init+0x312>
f01014ac:	c7 44 24 0c 6b 4a 10 	movl   $0xf0104a6b,0xc(%esp)
f01014b3:	f0 
f01014b4:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01014bb:	f0 
f01014bc:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f01014c3:	00 
f01014c4:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01014cb:	e8 c4 eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014d0:	a1 80 75 11 f0       	mov    0xf0117580,%eax
f01014d5:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014d8:	c7 05 80 75 11 f0 00 	movl   $0x0,0xf0117580
f01014df:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014e2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014e9:	e8 aa f9 ff ff       	call   f0100e98 <page_alloc>
f01014ee:	85 c0                	test   %eax,%eax
f01014f0:	74 24                	je     f0101516 <mem_init+0x358>
f01014f2:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f01014f9:	f0 
f01014fa:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101501:	f0 
f0101502:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f0101509:	00 
f010150a:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101511:	e8 7e eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101516:	89 34 24             	mov    %esi,(%esp)
f0101519:	e8 07 fa ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f010151e:	89 3c 24             	mov    %edi,(%esp)
f0101521:	e8 ff f9 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f0101526:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101529:	89 04 24             	mov    %eax,(%esp)
f010152c:	e8 f4 f9 ff ff       	call   f0100f25 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101531:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101538:	e8 5b f9 ff ff       	call   f0100e98 <page_alloc>
f010153d:	89 c6                	mov    %eax,%esi
f010153f:	85 c0                	test   %eax,%eax
f0101541:	75 24                	jne    f0101567 <mem_init+0x3a9>
f0101543:	c7 44 24 0c dd 49 10 	movl   $0xf01049dd,0xc(%esp)
f010154a:	f0 
f010154b:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101552:	f0 
f0101553:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f010155a:	00 
f010155b:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101562:	e8 2d eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101567:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010156e:	e8 25 f9 ff ff       	call   f0100e98 <page_alloc>
f0101573:	89 c7                	mov    %eax,%edi
f0101575:	85 c0                	test   %eax,%eax
f0101577:	75 24                	jne    f010159d <mem_init+0x3df>
f0101579:	c7 44 24 0c f3 49 10 	movl   $0xf01049f3,0xc(%esp)
f0101580:	f0 
f0101581:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101588:	f0 
f0101589:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0101590:	00 
f0101591:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101598:	e8 f7 ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010159d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a4:	e8 ef f8 ff ff       	call   f0100e98 <page_alloc>
f01015a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015ac:	85 c0                	test   %eax,%eax
f01015ae:	75 24                	jne    f01015d4 <mem_init+0x416>
f01015b0:	c7 44 24 0c 09 4a 10 	movl   $0xf0104a09,0xc(%esp)
f01015b7:	f0 
f01015b8:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01015bf:	f0 
f01015c0:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f01015c7:	00 
f01015c8:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01015cf:	e8 c0 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015d4:	39 fe                	cmp    %edi,%esi
f01015d6:	75 24                	jne    f01015fc <mem_init+0x43e>
f01015d8:	c7 44 24 0c 1f 4a 10 	movl   $0xf0104a1f,0xc(%esp)
f01015df:	f0 
f01015e0:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01015e7:	f0 
f01015e8:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f01015ef:	00 
f01015f0:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01015f7:	e8 98 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015fc:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01015ff:	74 05                	je     f0101606 <mem_init+0x448>
f0101601:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101604:	75 24                	jne    f010162a <mem_init+0x46c>
f0101606:	c7 44 24 0c 8c 43 10 	movl   $0xf010438c,0xc(%esp)
f010160d:	f0 
f010160e:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101615:	f0 
f0101616:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f010161d:	00 
f010161e:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101625:	e8 6a ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f010162a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101631:	e8 62 f8 ff ff       	call   f0100e98 <page_alloc>
f0101636:	85 c0                	test   %eax,%eax
f0101638:	74 24                	je     f010165e <mem_init+0x4a0>
f010163a:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f0101641:	f0 
f0101642:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101649:	f0 
f010164a:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101651:	00 
f0101652:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101659:	e8 36 ea ff ff       	call   f0100094 <_panic>
f010165e:	89 f0                	mov    %esi,%eax
f0101660:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0101666:	c1 f8 03             	sar    $0x3,%eax
f0101669:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010166c:	89 c2                	mov    %eax,%edx
f010166e:	c1 ea 0c             	shr    $0xc,%edx
f0101671:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0101677:	72 20                	jb     f0101699 <mem_init+0x4db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101679:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010167d:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0101684:	f0 
f0101685:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010168c:	00 
f010168d:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f0101694:	e8 fb e9 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101699:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016a0:	00 
f01016a1:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01016a8:	00 
	return (void *)(pa + KERNBASE);
f01016a9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016ae:	89 04 24             	mov    %eax,(%esp)
f01016b1:	e8 60 21 00 00       	call   f0103816 <memset>
	page_free(pp0);
f01016b6:	89 34 24             	mov    %esi,(%esp)
f01016b9:	e8 67 f8 ff ff       	call   f0100f25 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016be:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016c5:	e8 ce f7 ff ff       	call   f0100e98 <page_alloc>
f01016ca:	85 c0                	test   %eax,%eax
f01016cc:	75 24                	jne    f01016f2 <mem_init+0x534>
f01016ce:	c7 44 24 0c 97 4a 10 	movl   $0xf0104a97,0xc(%esp)
f01016d5:	f0 
f01016d6:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01016dd:	f0 
f01016de:	c7 44 24 04 85 02 00 	movl   $0x285,0x4(%esp)
f01016e5:	00 
f01016e6:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01016ed:	e8 a2 e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01016f2:	39 c6                	cmp    %eax,%esi
f01016f4:	74 24                	je     f010171a <mem_init+0x55c>
f01016f6:	c7 44 24 0c b5 4a 10 	movl   $0xf0104ab5,0xc(%esp)
f01016fd:	f0 
f01016fe:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101705:	f0 
f0101706:	c7 44 24 04 86 02 00 	movl   $0x286,0x4(%esp)
f010170d:	00 
f010170e:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101715:	e8 7a e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010171a:	89 f2                	mov    %esi,%edx
f010171c:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101722:	c1 fa 03             	sar    $0x3,%edx
f0101725:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101728:	89 d0                	mov    %edx,%eax
f010172a:	c1 e8 0c             	shr    $0xc,%eax
f010172d:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f0101733:	72 20                	jb     f0101755 <mem_init+0x597>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101735:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101739:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0101740:	f0 
f0101741:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101748:	00 
f0101749:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f0101750:	e8 3f e9 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101755:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f010175c:	75 11                	jne    f010176f <mem_init+0x5b1>
f010175e:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101764:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010176a:	80 38 00             	cmpb   $0x0,(%eax)
f010176d:	74 24                	je     f0101793 <mem_init+0x5d5>
f010176f:	c7 44 24 0c c5 4a 10 	movl   $0xf0104ac5,0xc(%esp)
f0101776:	f0 
f0101777:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010177e:	f0 
f010177f:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f0101786:	00 
f0101787:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010178e:	e8 01 e9 ff ff       	call   f0100094 <_panic>
f0101793:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101796:	39 d0                	cmp    %edx,%eax
f0101798:	75 d0                	jne    f010176a <mem_init+0x5ac>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f010179a:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010179d:	89 15 80 75 11 f0    	mov    %edx,0xf0117580

	// free the pages we took
	page_free(pp0);
f01017a3:	89 34 24             	mov    %esi,(%esp)
f01017a6:	e8 7a f7 ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f01017ab:	89 3c 24             	mov    %edi,(%esp)
f01017ae:	e8 72 f7 ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f01017b3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017b6:	89 04 24             	mov    %eax,(%esp)
f01017b9:	e8 67 f7 ff ff       	call   f0100f25 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017be:	a1 80 75 11 f0       	mov    0xf0117580,%eax
f01017c3:	85 c0                	test   %eax,%eax
f01017c5:	74 09                	je     f01017d0 <mem_init+0x612>
		--nfree;
f01017c7:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017ca:	8b 00                	mov    (%eax),%eax
f01017cc:	85 c0                	test   %eax,%eax
f01017ce:	75 f7                	jne    f01017c7 <mem_init+0x609>
		--nfree;
	assert(nfree == 0);
f01017d0:	85 db                	test   %ebx,%ebx
f01017d2:	74 24                	je     f01017f8 <mem_init+0x63a>
f01017d4:	c7 44 24 0c cf 4a 10 	movl   $0xf0104acf,0xc(%esp)
f01017db:	f0 
f01017dc:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01017e3:	f0 
f01017e4:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f01017eb:	00 
f01017ec:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01017f3:	e8 9c e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017f8:	c7 04 24 ac 43 10 f0 	movl   $0xf01043ac,(%esp)
f01017ff:	e8 12 14 00 00       	call   f0102c16 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101804:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010180b:	e8 88 f6 ff ff       	call   f0100e98 <page_alloc>
f0101810:	89 c3                	mov    %eax,%ebx
f0101812:	85 c0                	test   %eax,%eax
f0101814:	75 24                	jne    f010183a <mem_init+0x67c>
f0101816:	c7 44 24 0c dd 49 10 	movl   $0xf01049dd,0xc(%esp)
f010181d:	f0 
f010181e:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101825:	f0 
f0101826:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f010182d:	00 
f010182e:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101835:	e8 5a e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010183a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101841:	e8 52 f6 ff ff       	call   f0100e98 <page_alloc>
f0101846:	89 c7                	mov    %eax,%edi
f0101848:	85 c0                	test   %eax,%eax
f010184a:	75 24                	jne    f0101870 <mem_init+0x6b2>
f010184c:	c7 44 24 0c f3 49 10 	movl   $0xf01049f3,0xc(%esp)
f0101853:	f0 
f0101854:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010185b:	f0 
f010185c:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101863:	00 
f0101864:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010186b:	e8 24 e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101870:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101877:	e8 1c f6 ff ff       	call   f0100e98 <page_alloc>
f010187c:	89 c6                	mov    %eax,%esi
f010187e:	85 c0                	test   %eax,%eax
f0101880:	75 24                	jne    f01018a6 <mem_init+0x6e8>
f0101882:	c7 44 24 0c 09 4a 10 	movl   $0xf0104a09,0xc(%esp)
f0101889:	f0 
f010188a:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101891:	f0 
f0101892:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0101899:	00 
f010189a:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01018a1:	e8 ee e7 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018a6:	39 fb                	cmp    %edi,%ebx
f01018a8:	75 24                	jne    f01018ce <mem_init+0x710>
f01018aa:	c7 44 24 0c 1f 4a 10 	movl   $0xf0104a1f,0xc(%esp)
f01018b1:	f0 
f01018b2:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01018b9:	f0 
f01018ba:	c7 44 24 04 f4 02 00 	movl   $0x2f4,0x4(%esp)
f01018c1:	00 
f01018c2:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01018c9:	e8 c6 e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018ce:	39 c7                	cmp    %eax,%edi
f01018d0:	74 04                	je     f01018d6 <mem_init+0x718>
f01018d2:	39 c3                	cmp    %eax,%ebx
f01018d4:	75 24                	jne    f01018fa <mem_init+0x73c>
f01018d6:	c7 44 24 0c 8c 43 10 	movl   $0xf010438c,0xc(%esp)
f01018dd:	f0 
f01018de:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01018e5:	f0 
f01018e6:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f01018ed:	00 
f01018ee:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01018f5:	e8 9a e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018fa:	8b 15 80 75 11 f0    	mov    0xf0117580,%edx
f0101900:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101903:	c7 05 80 75 11 f0 00 	movl   $0x0,0xf0117580
f010190a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010190d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101914:	e8 7f f5 ff ff       	call   f0100e98 <page_alloc>
f0101919:	85 c0                	test   %eax,%eax
f010191b:	74 24                	je     f0101941 <mem_init+0x783>
f010191d:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f0101924:	f0 
f0101925:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010192c:	f0 
f010192d:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f0101934:	00 
f0101935:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010193c:	e8 53 e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101941:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101944:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101948:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010194f:	00 
f0101950:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101955:	89 04 24             	mov    %eax,(%esp)
f0101958:	e8 e4 f6 ff ff       	call   f0101041 <page_lookup>
f010195d:	85 c0                	test   %eax,%eax
f010195f:	74 24                	je     f0101985 <mem_init+0x7c7>
f0101961:	c7 44 24 0c cc 43 10 	movl   $0xf01043cc,0xc(%esp)
f0101968:	f0 
f0101969:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101970:	f0 
f0101971:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0101978:	00 
f0101979:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101980:	e8 0f e7 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101985:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010198c:	00 
f010198d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101994:	00 
f0101995:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101999:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f010199e:	89 04 24             	mov    %eax,(%esp)
f01019a1:	e8 6e f7 ff ff       	call   f0101114 <page_insert>
f01019a6:	85 c0                	test   %eax,%eax
f01019a8:	78 24                	js     f01019ce <mem_init+0x810>
f01019aa:	c7 44 24 0c 04 44 10 	movl   $0xf0104404,0xc(%esp)
f01019b1:	f0 
f01019b2:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01019b9:	f0 
f01019ba:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f01019c1:	00 
f01019c2:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01019c9:	e8 c6 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019ce:	89 1c 24             	mov    %ebx,(%esp)
f01019d1:	e8 4f f5 ff ff       	call   f0100f25 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019d6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019dd:	00 
f01019de:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019e5:	00 
f01019e6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01019ea:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01019ef:	89 04 24             	mov    %eax,(%esp)
f01019f2:	e8 1d f7 ff ff       	call   f0101114 <page_insert>
f01019f7:	85 c0                	test   %eax,%eax
f01019f9:	74 24                	je     f0101a1f <mem_init+0x861>
f01019fb:	c7 44 24 0c 34 44 10 	movl   $0xf0104434,0xc(%esp)
f0101a02:	f0 
f0101a03:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101a0a:	f0 
f0101a0b:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101a12:	00 
f0101a13:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101a1a:	e8 75 e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a1f:	8b 0d a4 79 11 f0    	mov    0xf01179a4,%ecx
f0101a25:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a28:	a1 a8 79 11 f0       	mov    0xf01179a8,%eax
f0101a2d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a30:	8b 11                	mov    (%ecx),%edx
f0101a32:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a38:	89 d8                	mov    %ebx,%eax
f0101a3a:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101a3d:	c1 f8 03             	sar    $0x3,%eax
f0101a40:	c1 e0 0c             	shl    $0xc,%eax
f0101a43:	39 c2                	cmp    %eax,%edx
f0101a45:	74 24                	je     f0101a6b <mem_init+0x8ad>
f0101a47:	c7 44 24 0c 64 44 10 	movl   $0xf0104464,0xc(%esp)
f0101a4e:	f0 
f0101a4f:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101a56:	f0 
f0101a57:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0101a5e:	00 
f0101a5f:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101a66:	e8 29 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a6b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a70:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a73:	e8 46 ef ff ff       	call   f01009be <check_va2pa>
f0101a78:	89 fa                	mov    %edi,%edx
f0101a7a:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101a7d:	c1 fa 03             	sar    $0x3,%edx
f0101a80:	c1 e2 0c             	shl    $0xc,%edx
f0101a83:	39 d0                	cmp    %edx,%eax
f0101a85:	74 24                	je     f0101aab <mem_init+0x8ed>
f0101a87:	c7 44 24 0c 8c 44 10 	movl   $0xf010448c,0xc(%esp)
f0101a8e:	f0 
f0101a8f:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101a96:	f0 
f0101a97:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101a9e:	00 
f0101a9f:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101aa6:	e8 e9 e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101aab:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101ab0:	74 24                	je     f0101ad6 <mem_init+0x918>
f0101ab2:	c7 44 24 0c da 4a 10 	movl   $0xf0104ada,0xc(%esp)
f0101ab9:	f0 
f0101aba:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101ac1:	f0 
f0101ac2:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101ac9:	00 
f0101aca:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101ad1:	e8 be e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101ad6:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101adb:	74 24                	je     f0101b01 <mem_init+0x943>
f0101add:	c7 44 24 0c eb 4a 10 	movl   $0xf0104aeb,0xc(%esp)
f0101ae4:	f0 
f0101ae5:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101aec:	f0 
f0101aed:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101af4:	00 
f0101af5:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101afc:	e8 93 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b01:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b08:	00 
f0101b09:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b10:	00 
f0101b11:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b15:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101b18:	89 14 24             	mov    %edx,(%esp)
f0101b1b:	e8 f4 f5 ff ff       	call   f0101114 <page_insert>
f0101b20:	85 c0                	test   %eax,%eax
f0101b22:	74 24                	je     f0101b48 <mem_init+0x98a>
f0101b24:	c7 44 24 0c bc 44 10 	movl   $0xf01044bc,0xc(%esp)
f0101b2b:	f0 
f0101b2c:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101b33:	f0 
f0101b34:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101b3b:	00 
f0101b3c:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101b43:	e8 4c e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b48:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b4d:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101b52:	e8 67 ee ff ff       	call   f01009be <check_va2pa>
f0101b57:	89 f2                	mov    %esi,%edx
f0101b59:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101b5f:	c1 fa 03             	sar    $0x3,%edx
f0101b62:	c1 e2 0c             	shl    $0xc,%edx
f0101b65:	39 d0                	cmp    %edx,%eax
f0101b67:	74 24                	je     f0101b8d <mem_init+0x9cf>
f0101b69:	c7 44 24 0c f8 44 10 	movl   $0xf01044f8,0xc(%esp)
f0101b70:	f0 
f0101b71:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101b78:	f0 
f0101b79:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101b80:	00 
f0101b81:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101b88:	e8 07 e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b8d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101b92:	74 24                	je     f0101bb8 <mem_init+0x9fa>
f0101b94:	c7 44 24 0c fc 4a 10 	movl   $0xf0104afc,0xc(%esp)
f0101b9b:	f0 
f0101b9c:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101ba3:	f0 
f0101ba4:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101bab:	00 
f0101bac:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101bb3:	e8 dc e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101bb8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bbf:	e8 d4 f2 ff ff       	call   f0100e98 <page_alloc>
f0101bc4:	85 c0                	test   %eax,%eax
f0101bc6:	74 24                	je     f0101bec <mem_init+0xa2e>
f0101bc8:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f0101bcf:	f0 
f0101bd0:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101bd7:	f0 
f0101bd8:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101bdf:	00 
f0101be0:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101be7:	e8 a8 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bec:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bf3:	00 
f0101bf4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bfb:	00 
f0101bfc:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c00:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101c05:	89 04 24             	mov    %eax,(%esp)
f0101c08:	e8 07 f5 ff ff       	call   f0101114 <page_insert>
f0101c0d:	85 c0                	test   %eax,%eax
f0101c0f:	74 24                	je     f0101c35 <mem_init+0xa77>
f0101c11:	c7 44 24 0c bc 44 10 	movl   $0xf01044bc,0xc(%esp)
f0101c18:	f0 
f0101c19:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101c20:	f0 
f0101c21:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f0101c28:	00 
f0101c29:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101c30:	e8 5f e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c35:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c3a:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101c3f:	e8 7a ed ff ff       	call   f01009be <check_va2pa>
f0101c44:	89 f2                	mov    %esi,%edx
f0101c46:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101c4c:	c1 fa 03             	sar    $0x3,%edx
f0101c4f:	c1 e2 0c             	shl    $0xc,%edx
f0101c52:	39 d0                	cmp    %edx,%eax
f0101c54:	74 24                	je     f0101c7a <mem_init+0xabc>
f0101c56:	c7 44 24 0c f8 44 10 	movl   $0xf01044f8,0xc(%esp)
f0101c5d:	f0 
f0101c5e:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101c65:	f0 
f0101c66:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101c6d:	00 
f0101c6e:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101c75:	e8 1a e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c7a:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c7f:	74 24                	je     f0101ca5 <mem_init+0xae7>
f0101c81:	c7 44 24 0c fc 4a 10 	movl   $0xf0104afc,0xc(%esp)
f0101c88:	f0 
f0101c89:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101c90:	f0 
f0101c91:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101c98:	00 
f0101c99:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101ca0:	e8 ef e3 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ca5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cac:	e8 e7 f1 ff ff       	call   f0100e98 <page_alloc>
f0101cb1:	85 c0                	test   %eax,%eax
f0101cb3:	74 24                	je     f0101cd9 <mem_init+0xb1b>
f0101cb5:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f0101cbc:	f0 
f0101cbd:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101cc4:	f0 
f0101cc5:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101ccc:	00 
f0101ccd:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101cd4:	e8 bb e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cd9:	8b 15 a4 79 11 f0    	mov    0xf01179a4,%edx
f0101cdf:	8b 02                	mov    (%edx),%eax
f0101ce1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ce6:	89 c1                	mov    %eax,%ecx
f0101ce8:	c1 e9 0c             	shr    $0xc,%ecx
f0101ceb:	3b 0d a0 79 11 f0    	cmp    0xf01179a0,%ecx
f0101cf1:	72 20                	jb     f0101d13 <mem_init+0xb55>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cf3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101cf7:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0101cfe:	f0 
f0101cff:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101d06:	00 
f0101d07:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101d0e:	e8 81 e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101d13:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d18:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d1b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d22:	00 
f0101d23:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d2a:	00 
f0101d2b:	89 14 24             	mov    %edx,(%esp)
f0101d2e:	e8 2a f2 ff ff       	call   f0100f5d <pgdir_walk>
f0101d33:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101d36:	83 c2 04             	add    $0x4,%edx
f0101d39:	39 d0                	cmp    %edx,%eax
f0101d3b:	74 24                	je     f0101d61 <mem_init+0xba3>
f0101d3d:	c7 44 24 0c 28 45 10 	movl   $0xf0104528,0xc(%esp)
f0101d44:	f0 
f0101d45:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101d4c:	f0 
f0101d4d:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101d54:	00 
f0101d55:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101d5c:	e8 33 e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d61:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d68:	00 
f0101d69:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d70:	00 
f0101d71:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d75:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101d7a:	89 04 24             	mov    %eax,(%esp)
f0101d7d:	e8 92 f3 ff ff       	call   f0101114 <page_insert>
f0101d82:	85 c0                	test   %eax,%eax
f0101d84:	74 24                	je     f0101daa <mem_init+0xbec>
f0101d86:	c7 44 24 0c 68 45 10 	movl   $0xf0104568,0xc(%esp)
f0101d8d:	f0 
f0101d8e:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101d95:	f0 
f0101d96:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101d9d:	00 
f0101d9e:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101da5:	e8 ea e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101daa:	8b 0d a4 79 11 f0    	mov    0xf01179a4,%ecx
f0101db0:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101db3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101db8:	89 c8                	mov    %ecx,%eax
f0101dba:	e8 ff eb ff ff       	call   f01009be <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101dbf:	89 f2                	mov    %esi,%edx
f0101dc1:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0101dc7:	c1 fa 03             	sar    $0x3,%edx
f0101dca:	c1 e2 0c             	shl    $0xc,%edx
f0101dcd:	39 d0                	cmp    %edx,%eax
f0101dcf:	74 24                	je     f0101df5 <mem_init+0xc37>
f0101dd1:	c7 44 24 0c f8 44 10 	movl   $0xf01044f8,0xc(%esp)
f0101dd8:	f0 
f0101dd9:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101de0:	f0 
f0101de1:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0101de8:	00 
f0101de9:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101df0:	e8 9f e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101df5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101dfa:	74 24                	je     f0101e20 <mem_init+0xc62>
f0101dfc:	c7 44 24 0c fc 4a 10 	movl   $0xf0104afc,0xc(%esp)
f0101e03:	f0 
f0101e04:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101e0b:	f0 
f0101e0c:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101e13:	00 
f0101e14:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101e1b:	e8 74 e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e20:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e27:	00 
f0101e28:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e2f:	00 
f0101e30:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e33:	89 04 24             	mov    %eax,(%esp)
f0101e36:	e8 22 f1 ff ff       	call   f0100f5d <pgdir_walk>
f0101e3b:	f6 00 04             	testb  $0x4,(%eax)
f0101e3e:	75 24                	jne    f0101e64 <mem_init+0xca6>
f0101e40:	c7 44 24 0c a8 45 10 	movl   $0xf01045a8,0xc(%esp)
f0101e47:	f0 
f0101e48:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101e4f:	f0 
f0101e50:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101e57:	00 
f0101e58:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101e5f:	e8 30 e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e64:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101e69:	f6 00 04             	testb  $0x4,(%eax)
f0101e6c:	75 24                	jne    f0101e92 <mem_init+0xcd4>
f0101e6e:	c7 44 24 0c 0d 4b 10 	movl   $0xf0104b0d,0xc(%esp)
f0101e75:	f0 
f0101e76:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101e7d:	f0 
f0101e7e:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101e85:	00 
f0101e86:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101e8d:	e8 02 e2 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e92:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e99:	00 
f0101e9a:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101ea1:	00 
f0101ea2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ea6:	89 04 24             	mov    %eax,(%esp)
f0101ea9:	e8 66 f2 ff ff       	call   f0101114 <page_insert>
f0101eae:	85 c0                	test   %eax,%eax
f0101eb0:	78 24                	js     f0101ed6 <mem_init+0xd18>
f0101eb2:	c7 44 24 0c dc 45 10 	movl   $0xf01045dc,0xc(%esp)
f0101eb9:	f0 
f0101eba:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101ec1:	f0 
f0101ec2:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101ec9:	00 
f0101eca:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101ed1:	e8 be e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ed6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101edd:	00 
f0101ede:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ee5:	00 
f0101ee6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101eea:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101eef:	89 04 24             	mov    %eax,(%esp)
f0101ef2:	e8 1d f2 ff ff       	call   f0101114 <page_insert>
f0101ef7:	85 c0                	test   %eax,%eax
f0101ef9:	74 24                	je     f0101f1f <mem_init+0xd61>
f0101efb:	c7 44 24 0c 14 46 10 	movl   $0xf0104614,0xc(%esp)
f0101f02:	f0 
f0101f03:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101f0a:	f0 
f0101f0b:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0101f12:	00 
f0101f13:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101f1a:	e8 75 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f1f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f26:	00 
f0101f27:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f2e:	00 
f0101f2f:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101f34:	89 04 24             	mov    %eax,(%esp)
f0101f37:	e8 21 f0 ff ff       	call   f0100f5d <pgdir_walk>
f0101f3c:	f6 00 04             	testb  $0x4,(%eax)
f0101f3f:	74 24                	je     f0101f65 <mem_init+0xda7>
f0101f41:	c7 44 24 0c 50 46 10 	movl   $0xf0104650,0xc(%esp)
f0101f48:	f0 
f0101f49:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101f50:	f0 
f0101f51:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0101f58:	00 
f0101f59:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101f60:	e8 2f e1 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101f65:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0101f6a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101f6d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f72:	e8 47 ea ff ff       	call   f01009be <check_va2pa>
f0101f77:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101f7a:	89 f8                	mov    %edi,%eax
f0101f7c:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0101f82:	c1 f8 03             	sar    $0x3,%eax
f0101f85:	c1 e0 0c             	shl    $0xc,%eax
f0101f88:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101f8b:	74 24                	je     f0101fb1 <mem_init+0xdf3>
f0101f8d:	c7 44 24 0c 88 46 10 	movl   $0xf0104688,0xc(%esp)
f0101f94:	f0 
f0101f95:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101f9c:	f0 
f0101f9d:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101fa4:	00 
f0101fa5:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101fac:	e8 e3 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fb1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fb6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fb9:	e8 00 ea ff ff       	call   f01009be <check_va2pa>
f0101fbe:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101fc1:	74 24                	je     f0101fe7 <mem_init+0xe29>
f0101fc3:	c7 44 24 0c b4 46 10 	movl   $0xf01046b4,0xc(%esp)
f0101fca:	f0 
f0101fcb:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101fd2:	f0 
f0101fd3:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101fda:	00 
f0101fdb:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0101fe2:	e8 ad e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101fe7:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101fec:	74 24                	je     f0102012 <mem_init+0xe54>
f0101fee:	c7 44 24 0c 23 4b 10 	movl   $0xf0104b23,0xc(%esp)
f0101ff5:	f0 
f0101ff6:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0101ffd:	f0 
f0101ffe:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0102005:	00 
f0102006:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010200d:	e8 82 e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102012:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102017:	74 24                	je     f010203d <mem_init+0xe7f>
f0102019:	c7 44 24 0c 34 4b 10 	movl   $0xf0104b34,0xc(%esp)
f0102020:	f0 
f0102021:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102028:	f0 
f0102029:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0102030:	00 
f0102031:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102038:	e8 57 e0 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010203d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102044:	e8 4f ee ff ff       	call   f0100e98 <page_alloc>
f0102049:	85 c0                	test   %eax,%eax
f010204b:	74 04                	je     f0102051 <mem_init+0xe93>
f010204d:	39 c6                	cmp    %eax,%esi
f010204f:	74 24                	je     f0102075 <mem_init+0xeb7>
f0102051:	c7 44 24 0c e4 46 10 	movl   $0xf01046e4,0xc(%esp)
f0102058:	f0 
f0102059:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102060:	f0 
f0102061:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0102068:	00 
f0102069:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102070:	e8 1f e0 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102075:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010207c:	00 
f010207d:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102082:	89 04 24             	mov    %eax,(%esp)
f0102085:	e8 3a f0 ff ff       	call   f01010c4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010208a:	8b 15 a4 79 11 f0    	mov    0xf01179a4,%edx
f0102090:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102093:	ba 00 00 00 00       	mov    $0x0,%edx
f0102098:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010209b:	e8 1e e9 ff ff       	call   f01009be <check_va2pa>
f01020a0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020a3:	74 24                	je     f01020c9 <mem_init+0xf0b>
f01020a5:	c7 44 24 0c 08 47 10 	movl   $0xf0104708,0xc(%esp)
f01020ac:	f0 
f01020ad:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01020b4:	f0 
f01020b5:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f01020bc:	00 
f01020bd:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01020c4:	e8 cb df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020c9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020d1:	e8 e8 e8 ff ff       	call   f01009be <check_va2pa>
f01020d6:	89 fa                	mov    %edi,%edx
f01020d8:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f01020de:	c1 fa 03             	sar    $0x3,%edx
f01020e1:	c1 e2 0c             	shl    $0xc,%edx
f01020e4:	39 d0                	cmp    %edx,%eax
f01020e6:	74 24                	je     f010210c <mem_init+0xf4e>
f01020e8:	c7 44 24 0c b4 46 10 	movl   $0xf01046b4,0xc(%esp)
f01020ef:	f0 
f01020f0:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01020f7:	f0 
f01020f8:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f01020ff:	00 
f0102100:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102107:	e8 88 df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f010210c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102111:	74 24                	je     f0102137 <mem_init+0xf79>
f0102113:	c7 44 24 0c da 4a 10 	movl   $0xf0104ada,0xc(%esp)
f010211a:	f0 
f010211b:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102122:	f0 
f0102123:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f010212a:	00 
f010212b:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102132:	e8 5d df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102137:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010213c:	74 24                	je     f0102162 <mem_init+0xfa4>
f010213e:	c7 44 24 0c 34 4b 10 	movl   $0xf0104b34,0xc(%esp)
f0102145:	f0 
f0102146:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010214d:	f0 
f010214e:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0102155:	00 
f0102156:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010215d:	e8 32 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102162:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102169:	00 
f010216a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010216d:	89 0c 24             	mov    %ecx,(%esp)
f0102170:	e8 4f ef ff ff       	call   f01010c4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102175:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f010217a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010217d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102182:	e8 37 e8 ff ff       	call   f01009be <check_va2pa>
f0102187:	83 f8 ff             	cmp    $0xffffffff,%eax
f010218a:	74 24                	je     f01021b0 <mem_init+0xff2>
f010218c:	c7 44 24 0c 08 47 10 	movl   $0xf0104708,0xc(%esp)
f0102193:	f0 
f0102194:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010219b:	f0 
f010219c:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f01021a3:	00 
f01021a4:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01021ab:	e8 e4 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01021b0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021b8:	e8 01 e8 ff ff       	call   f01009be <check_va2pa>
f01021bd:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021c0:	74 24                	je     f01021e6 <mem_init+0x1028>
f01021c2:	c7 44 24 0c 2c 47 10 	movl   $0xf010472c,0xc(%esp)
f01021c9:	f0 
f01021ca:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01021d1:	f0 
f01021d2:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f01021d9:	00 
f01021da:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01021e1:	e8 ae de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01021e6:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01021eb:	74 24                	je     f0102211 <mem_init+0x1053>
f01021ed:	c7 44 24 0c 45 4b 10 	movl   $0xf0104b45,0xc(%esp)
f01021f4:	f0 
f01021f5:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01021fc:	f0 
f01021fd:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0102204:	00 
f0102205:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010220c:	e8 83 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102211:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102216:	74 24                	je     f010223c <mem_init+0x107e>
f0102218:	c7 44 24 0c 34 4b 10 	movl   $0xf0104b34,0xc(%esp)
f010221f:	f0 
f0102220:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102227:	f0 
f0102228:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f010222f:	00 
f0102230:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102237:	e8 58 de ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010223c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102243:	e8 50 ec ff ff       	call   f0100e98 <page_alloc>
f0102248:	85 c0                	test   %eax,%eax
f010224a:	74 04                	je     f0102250 <mem_init+0x1092>
f010224c:	39 c7                	cmp    %eax,%edi
f010224e:	74 24                	je     f0102274 <mem_init+0x10b6>
f0102250:	c7 44 24 0c 54 47 10 	movl   $0xf0104754,0xc(%esp)
f0102257:	f0 
f0102258:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010225f:	f0 
f0102260:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102267:	00 
f0102268:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010226f:	e8 20 de ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102274:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010227b:	e8 18 ec ff ff       	call   f0100e98 <page_alloc>
f0102280:	85 c0                	test   %eax,%eax
f0102282:	74 24                	je     f01022a8 <mem_init+0x10ea>
f0102284:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f010228b:	f0 
f010228c:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102293:	f0 
f0102294:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f010229b:	00 
f010229c:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01022a3:	e8 ec dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022a8:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01022ad:	8b 08                	mov    (%eax),%ecx
f01022af:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01022b5:	89 da                	mov    %ebx,%edx
f01022b7:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f01022bd:	c1 fa 03             	sar    $0x3,%edx
f01022c0:	c1 e2 0c             	shl    $0xc,%edx
f01022c3:	39 d1                	cmp    %edx,%ecx
f01022c5:	74 24                	je     f01022eb <mem_init+0x112d>
f01022c7:	c7 44 24 0c 64 44 10 	movl   $0xf0104464,0xc(%esp)
f01022ce:	f0 
f01022cf:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01022d6:	f0 
f01022d7:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f01022de:	00 
f01022df:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01022e6:	e8 a9 dd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01022eb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01022f1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01022f6:	74 24                	je     f010231c <mem_init+0x115e>
f01022f8:	c7 44 24 0c eb 4a 10 	movl   $0xf0104aeb,0xc(%esp)
f01022ff:	f0 
f0102300:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102307:	f0 
f0102308:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f010230f:	00 
f0102310:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102317:	e8 78 dd ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f010231c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102322:	89 1c 24             	mov    %ebx,(%esp)
f0102325:	e8 fb eb ff ff       	call   f0100f25 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010232a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102331:	00 
f0102332:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102339:	00 
f010233a:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f010233f:	89 04 24             	mov    %eax,(%esp)
f0102342:	e8 16 ec ff ff       	call   f0100f5d <pgdir_walk>
f0102347:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010234a:	8b 0d a4 79 11 f0    	mov    0xf01179a4,%ecx
f0102350:	8b 51 04             	mov    0x4(%ecx),%edx
f0102353:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102359:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010235c:	8b 15 a0 79 11 f0    	mov    0xf01179a0,%edx
f0102362:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102365:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102368:	c1 ea 0c             	shr    $0xc,%edx
f010236b:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010236e:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102371:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102374:	72 23                	jb     f0102399 <mem_init+0x11db>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102376:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102379:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010237d:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0102384:	f0 
f0102385:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f010238c:	00 
f010238d:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102394:	e8 fb dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102399:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010239c:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01023a2:	39 d0                	cmp    %edx,%eax
f01023a4:	74 24                	je     f01023ca <mem_init+0x120c>
f01023a6:	c7 44 24 0c 56 4b 10 	movl   $0xf0104b56,0xc(%esp)
f01023ad:	f0 
f01023ae:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01023b5:	f0 
f01023b6:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f01023bd:	00 
f01023be:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01023c5:	e8 ca dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01023ca:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01023d1:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01023d7:	89 d8                	mov    %ebx,%eax
f01023d9:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f01023df:	c1 f8 03             	sar    $0x3,%eax
f01023e2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023e5:	89 c1                	mov    %eax,%ecx
f01023e7:	c1 e9 0c             	shr    $0xc,%ecx
f01023ea:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f01023ed:	77 20                	ja     f010240f <mem_init+0x1251>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01023f3:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f01023fa:	f0 
f01023fb:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102402:	00 
f0102403:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f010240a:	e8 85 dc ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010240f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102416:	00 
f0102417:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010241e:	00 
	return (void *)(pa + KERNBASE);
f010241f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102424:	89 04 24             	mov    %eax,(%esp)
f0102427:	e8 ea 13 00 00       	call   f0103816 <memset>
	page_free(pp0);
f010242c:	89 1c 24             	mov    %ebx,(%esp)
f010242f:	e8 f1 ea ff ff       	call   f0100f25 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102434:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010243b:	00 
f010243c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102443:	00 
f0102444:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102449:	89 04 24             	mov    %eax,(%esp)
f010244c:	e8 0c eb ff ff       	call   f0100f5d <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102451:	89 da                	mov    %ebx,%edx
f0102453:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0102459:	c1 fa 03             	sar    $0x3,%edx
f010245c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010245f:	89 d0                	mov    %edx,%eax
f0102461:	c1 e8 0c             	shr    $0xc,%eax
f0102464:	3b 05 a0 79 11 f0    	cmp    0xf01179a0,%eax
f010246a:	72 20                	jb     f010248c <mem_init+0x12ce>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010246c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102470:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0102477:	f0 
f0102478:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010247f:	00 
f0102480:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f0102487:	e8 08 dc ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010248c:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102492:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102495:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f010249c:	75 11                	jne    f01024af <mem_init+0x12f1>
f010249e:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01024a4:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01024aa:	f6 00 01             	testb  $0x1,(%eax)
f01024ad:	74 24                	je     f01024d3 <mem_init+0x1315>
f01024af:	c7 44 24 0c 6e 4b 10 	movl   $0xf0104b6e,0xc(%esp)
f01024b6:	f0 
f01024b7:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01024be:	f0 
f01024bf:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01024c6:	00 
f01024c7:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01024ce:	e8 c1 db ff ff       	call   f0100094 <_panic>
f01024d3:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01024d6:	39 d0                	cmp    %edx,%eax
f01024d8:	75 d0                	jne    f01024aa <mem_init+0x12ec>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01024da:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01024df:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01024e5:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f01024eb:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01024ee:	89 0d 80 75 11 f0    	mov    %ecx,0xf0117580

	// free the pages we took
	page_free(pp0);
f01024f4:	89 1c 24             	mov    %ebx,(%esp)
f01024f7:	e8 29 ea ff ff       	call   f0100f25 <page_free>
	page_free(pp1);
f01024fc:	89 3c 24             	mov    %edi,(%esp)
f01024ff:	e8 21 ea ff ff       	call   f0100f25 <page_free>
	page_free(pp2);
f0102504:	89 34 24             	mov    %esi,(%esp)
f0102507:	e8 19 ea ff ff       	call   f0100f25 <page_free>

	cprintf("check_page() succeeded!\n");
f010250c:	c7 04 24 85 4b 10 f0 	movl   $0xf0104b85,(%esp)
f0102513:	e8 fe 06 00 00       	call   f0102c16 <cprintf>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102518:	8b 1d a4 79 11 f0    	mov    0xf01179a4,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f010251e:	a1 a0 79 11 f0       	mov    0xf01179a0,%eax
f0102523:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102526:	8d 3c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f010252d:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102533:	74 79                	je     f01025ae <mem_init+0x13f0>
f0102535:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010253a:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102540:	89 d8                	mov    %ebx,%eax
f0102542:	e8 77 e4 ff ff       	call   f01009be <check_va2pa>
f0102547:	8b 15 a8 79 11 f0    	mov    0xf01179a8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010254d:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102553:	77 20                	ja     f0102575 <mem_init+0x13b7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102555:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102559:	c7 44 24 08 0c 43 10 	movl   $0xf010430c,0x8(%esp)
f0102560:	f0 
f0102561:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102568:	00 
f0102569:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102570:	e8 1f db ff ff       	call   f0100094 <_panic>
f0102575:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f010257c:	39 d0                	cmp    %edx,%eax
f010257e:	74 24                	je     f01025a4 <mem_init+0x13e6>
f0102580:	c7 44 24 0c 78 47 10 	movl   $0xf0104778,0xc(%esp)
f0102587:	f0 
f0102588:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010258f:	f0 
f0102590:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102597:	00 
f0102598:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010259f:	e8 f0 da ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01025a4:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01025aa:	39 f7                	cmp    %esi,%edi
f01025ac:	77 8c                	ja     f010253a <mem_init+0x137c>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01025ae:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01025b1:	c1 e7 0c             	shl    $0xc,%edi
f01025b4:	85 ff                	test   %edi,%edi
f01025b6:	74 4b                	je     f0102603 <mem_init+0x1445>
f01025b8:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01025bd:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01025c3:	89 d8                	mov    %ebx,%eax
f01025c5:	e8 f4 e3 ff ff       	call   f01009be <check_va2pa>
f01025ca:	39 c6                	cmp    %eax,%esi
f01025cc:	74 24                	je     f01025f2 <mem_init+0x1434>
f01025ce:	c7 44 24 0c ac 47 10 	movl   $0xf01047ac,0xc(%esp)
f01025d5:	f0 
f01025d6:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01025dd:	f0 
f01025de:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f01025e5:	00 
f01025e6:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01025ed:	e8 a2 da ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01025f2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01025f8:	39 fe                	cmp    %edi,%esi
f01025fa:	72 c1                	jb     f01025bd <mem_init+0x13ff>
f01025fc:	be 00 80 bf ef       	mov    $0xefbf8000,%esi
f0102601:	eb 05                	jmp    f0102608 <mem_init+0x144a>
f0102603:	be 00 80 bf ef       	mov    $0xefbf8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102608:	bf 00 d0 10 f0       	mov    $0xf010d000,%edi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010260d:	89 f2                	mov    %esi,%edx
f010260f:	89 d8                	mov    %ebx,%eax
f0102611:	e8 a8 e3 ff ff       	call   f01009be <check_va2pa>
f0102616:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f010261c:	77 24                	ja     f0102642 <mem_init+0x1484>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010261e:	c7 44 24 0c 00 d0 10 	movl   $0xf010d000,0xc(%esp)
f0102625:	f0 
f0102626:	c7 44 24 08 0c 43 10 	movl   $0xf010430c,0x8(%esp)
f010262d:	f0 
f010262e:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f0102635:	00 
f0102636:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010263d:	e8 52 da ff ff       	call   f0100094 <_panic>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102642:	8d 96 00 50 51 10    	lea    0x10515000(%esi),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102648:	39 d0                	cmp    %edx,%eax
f010264a:	74 24                	je     f0102670 <mem_init+0x14b2>
f010264c:	c7 44 24 0c d4 47 10 	movl   $0xf01047d4,0xc(%esp)
f0102653:	f0 
f0102654:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010265b:	f0 
f010265c:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f0102663:	00 
f0102664:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010266b:	e8 24 da ff ff       	call   f0100094 <_panic>
f0102670:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102676:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f010267c:	75 8f                	jne    f010260d <mem_init+0x144f>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010267e:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102683:	89 d8                	mov    %ebx,%eax
f0102685:	e8 34 e3 ff ff       	call   f01009be <check_va2pa>
f010268a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010268d:	74 24                	je     f01026b3 <mem_init+0x14f5>
f010268f:	c7 44 24 0c 1c 48 10 	movl   $0xf010481c,0xc(%esp)
f0102696:	f0 
f0102697:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010269e:	f0 
f010269f:	c7 44 24 04 b8 02 00 	movl   $0x2b8,0x4(%esp)
f01026a6:	00 
f01026a7:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01026ae:	e8 e1 d9 ff ff       	call   f0100094 <_panic>
f01026b3:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01026b8:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01026be:	83 fa 02             	cmp    $0x2,%edx
f01026c1:	77 2e                	ja     f01026f1 <mem_init+0x1533>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01026c3:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01026c7:	0f 85 aa 00 00 00    	jne    f0102777 <mem_init+0x15b9>
f01026cd:	c7 44 24 0c 9e 4b 10 	movl   $0xf0104b9e,0xc(%esp)
f01026d4:	f0 
f01026d5:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01026dc:	f0 
f01026dd:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f01026e4:	00 
f01026e5:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01026ec:	e8 a3 d9 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01026f1:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01026f6:	76 55                	jbe    f010274d <mem_init+0x158f>
				assert(pgdir[i] & PTE_P);
f01026f8:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01026fb:	f6 c2 01             	test   $0x1,%dl
f01026fe:	75 24                	jne    f0102724 <mem_init+0x1566>
f0102700:	c7 44 24 0c 9e 4b 10 	movl   $0xf0104b9e,0xc(%esp)
f0102707:	f0 
f0102708:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010270f:	f0 
f0102710:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f0102717:	00 
f0102718:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010271f:	e8 70 d9 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102724:	f6 c2 02             	test   $0x2,%dl
f0102727:	75 4e                	jne    f0102777 <mem_init+0x15b9>
f0102729:	c7 44 24 0c af 4b 10 	movl   $0xf0104baf,0xc(%esp)
f0102730:	f0 
f0102731:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102738:	f0 
f0102739:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0102740:	00 
f0102741:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102748:	e8 47 d9 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f010274d:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102751:	74 24                	je     f0102777 <mem_init+0x15b9>
f0102753:	c7 44 24 0c c0 4b 10 	movl   $0xf0104bc0,0xc(%esp)
f010275a:	f0 
f010275b:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102762:	f0 
f0102763:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f010276a:	00 
f010276b:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102772:	e8 1d d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102777:	83 c0 01             	add    $0x1,%eax
f010277a:	3d 00 04 00 00       	cmp    $0x400,%eax
f010277f:	0f 85 33 ff ff ff    	jne    f01026b8 <mem_init+0x14fa>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102785:	c7 04 24 4c 48 10 f0 	movl   $0xf010484c,(%esp)
f010278c:	e8 85 04 00 00       	call   f0102c16 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102791:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102796:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010279b:	77 20                	ja     f01027bd <mem_init+0x15ff>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010279d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01027a1:	c7 44 24 08 0c 43 10 	movl   $0xf010430c,0x8(%esp)
f01027a8:	f0 
f01027a9:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
f01027b0:	00 
f01027b1:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01027b8:	e8 d7 d8 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01027bd:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01027c2:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01027c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01027ca:	e8 92 e2 ff ff       	call   f0100a61 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01027cf:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f01027d2:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f01027d7:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01027da:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01027dd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027e4:	e8 af e6 ff ff       	call   f0100e98 <page_alloc>
f01027e9:	89 c6                	mov    %eax,%esi
f01027eb:	85 c0                	test   %eax,%eax
f01027ed:	75 24                	jne    f0102813 <mem_init+0x1655>
f01027ef:	c7 44 24 0c dd 49 10 	movl   $0xf01049dd,0xc(%esp)
f01027f6:	f0 
f01027f7:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01027fe:	f0 
f01027ff:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0102806:	00 
f0102807:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010280e:	e8 81 d8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102813:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010281a:	e8 79 e6 ff ff       	call   f0100e98 <page_alloc>
f010281f:	89 c7                	mov    %eax,%edi
f0102821:	85 c0                	test   %eax,%eax
f0102823:	75 24                	jne    f0102849 <mem_init+0x168b>
f0102825:	c7 44 24 0c f3 49 10 	movl   $0xf01049f3,0xc(%esp)
f010282c:	f0 
f010282d:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102834:	f0 
f0102835:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f010283c:	00 
f010283d:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102844:	e8 4b d8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102849:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102850:	e8 43 e6 ff ff       	call   f0100e98 <page_alloc>
f0102855:	89 c3                	mov    %eax,%ebx
f0102857:	85 c0                	test   %eax,%eax
f0102859:	75 24                	jne    f010287f <mem_init+0x16c1>
f010285b:	c7 44 24 0c 09 4a 10 	movl   $0xf0104a09,0xc(%esp)
f0102862:	f0 
f0102863:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010286a:	f0 
f010286b:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0102872:	00 
f0102873:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010287a:	e8 15 d8 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f010287f:	89 34 24             	mov    %esi,(%esp)
f0102882:	e8 9e e6 ff ff       	call   f0100f25 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102887:	89 f8                	mov    %edi,%eax
f0102889:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f010288f:	c1 f8 03             	sar    $0x3,%eax
f0102892:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102895:	89 c2                	mov    %eax,%edx
f0102897:	c1 ea 0c             	shr    $0xc,%edx
f010289a:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f01028a0:	72 20                	jb     f01028c2 <mem_init+0x1704>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028a2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028a6:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f01028ad:	f0 
f01028ae:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01028b5:	00 
f01028b6:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f01028bd:	e8 d2 d7 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01028c2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01028c9:	00 
f01028ca:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01028d1:	00 
	return (void *)(pa + KERNBASE);
f01028d2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01028d7:	89 04 24             	mov    %eax,(%esp)
f01028da:	e8 37 0f 00 00       	call   f0103816 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01028df:	89 d8                	mov    %ebx,%eax
f01028e1:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f01028e7:	c1 f8 03             	sar    $0x3,%eax
f01028ea:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028ed:	89 c2                	mov    %eax,%edx
f01028ef:	c1 ea 0c             	shr    $0xc,%edx
f01028f2:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f01028f8:	72 20                	jb     f010291a <mem_init+0x175c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028fe:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0102905:	f0 
f0102906:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010290d:	00 
f010290e:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f0102915:	e8 7a d7 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010291a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102921:	00 
f0102922:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102929:	00 
	return (void *)(pa + KERNBASE);
f010292a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010292f:	89 04 24             	mov    %eax,(%esp)
f0102932:	e8 df 0e 00 00       	call   f0103816 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102937:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010293e:	00 
f010293f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102946:	00 
f0102947:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010294b:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102950:	89 04 24             	mov    %eax,(%esp)
f0102953:	e8 bc e7 ff ff       	call   f0101114 <page_insert>
	assert(pp1->pp_ref == 1);
f0102958:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010295d:	74 24                	je     f0102983 <mem_init+0x17c5>
f010295f:	c7 44 24 0c da 4a 10 	movl   $0xf0104ada,0xc(%esp)
f0102966:	f0 
f0102967:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010296e:	f0 
f010296f:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102976:	00 
f0102977:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f010297e:	e8 11 d7 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102983:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010298a:	01 01 01 
f010298d:	74 24                	je     f01029b3 <mem_init+0x17f5>
f010298f:	c7 44 24 0c 6c 48 10 	movl   $0xf010486c,0xc(%esp)
f0102996:	f0 
f0102997:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f010299e:	f0 
f010299f:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f01029a6:	00 
f01029a7:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01029ae:	e8 e1 d6 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01029b3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01029ba:	00 
f01029bb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029c2:	00 
f01029c3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01029c7:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f01029cc:	89 04 24             	mov    %eax,(%esp)
f01029cf:	e8 40 e7 ff ff       	call   f0101114 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01029d4:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01029db:	02 02 02 
f01029de:	74 24                	je     f0102a04 <mem_init+0x1846>
f01029e0:	c7 44 24 0c 90 48 10 	movl   $0xf0104890,0xc(%esp)
f01029e7:	f0 
f01029e8:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f01029ef:	f0 
f01029f0:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01029f7:	00 
f01029f8:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f01029ff:	e8 90 d6 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102a04:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102a09:	74 24                	je     f0102a2f <mem_init+0x1871>
f0102a0b:	c7 44 24 0c fc 4a 10 	movl   $0xf0104afc,0xc(%esp)
f0102a12:	f0 
f0102a13:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102a1a:	f0 
f0102a1b:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102a22:	00 
f0102a23:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102a2a:	e8 65 d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102a2f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102a34:	74 24                	je     f0102a5a <mem_init+0x189c>
f0102a36:	c7 44 24 0c 45 4b 10 	movl   $0xf0104b45,0xc(%esp)
f0102a3d:	f0 
f0102a3e:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102a45:	f0 
f0102a46:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102a4d:	00 
f0102a4e:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102a55:	e8 3a d6 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102a5a:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102a61:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a64:	89 d8                	mov    %ebx,%eax
f0102a66:	2b 05 a8 79 11 f0    	sub    0xf01179a8,%eax
f0102a6c:	c1 f8 03             	sar    $0x3,%eax
f0102a6f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a72:	89 c2                	mov    %eax,%edx
f0102a74:	c1 ea 0c             	shr    $0xc,%edx
f0102a77:	3b 15 a0 79 11 f0    	cmp    0xf01179a0,%edx
f0102a7d:	72 20                	jb     f0102a9f <mem_init+0x18e1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a7f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a83:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0102a8a:	f0 
f0102a8b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a92:	00 
f0102a93:	c7 04 24 18 49 10 f0 	movl   $0xf0104918,(%esp)
f0102a9a:	e8 f5 d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102a9f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102aa6:	03 03 03 
f0102aa9:	74 24                	je     f0102acf <mem_init+0x1911>
f0102aab:	c7 44 24 0c b4 48 10 	movl   $0xf01048b4,0xc(%esp)
f0102ab2:	f0 
f0102ab3:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102aba:	f0 
f0102abb:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0102ac2:	00 
f0102ac3:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102aca:	e8 c5 d5 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102acf:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102ad6:	00 
f0102ad7:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102adc:	89 04 24             	mov    %eax,(%esp)
f0102adf:	e8 e0 e5 ff ff       	call   f01010c4 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ae4:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102ae9:	74 24                	je     f0102b0f <mem_init+0x1951>
f0102aeb:	c7 44 24 0c 34 4b 10 	movl   $0xf0104b34,0xc(%esp)
f0102af2:	f0 
f0102af3:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102afa:	f0 
f0102afb:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0102b02:	00 
f0102b03:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102b0a:	e8 85 d5 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b0f:	a1 a4 79 11 f0       	mov    0xf01179a4,%eax
f0102b14:	8b 08                	mov    (%eax),%ecx
f0102b16:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b1c:	89 f2                	mov    %esi,%edx
f0102b1e:	2b 15 a8 79 11 f0    	sub    0xf01179a8,%edx
f0102b24:	c1 fa 03             	sar    $0x3,%edx
f0102b27:	c1 e2 0c             	shl    $0xc,%edx
f0102b2a:	39 d1                	cmp    %edx,%ecx
f0102b2c:	74 24                	je     f0102b52 <mem_init+0x1994>
f0102b2e:	c7 44 24 0c 64 44 10 	movl   $0xf0104464,0xc(%esp)
f0102b35:	f0 
f0102b36:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102b3d:	f0 
f0102b3e:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f0102b45:	00 
f0102b46:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102b4d:	e8 42 d5 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102b52:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102b58:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b5d:	74 24                	je     f0102b83 <mem_init+0x19c5>
f0102b5f:	c7 44 24 0c eb 4a 10 	movl   $0xf0104aeb,0xc(%esp)
f0102b66:	f0 
f0102b67:	c7 44 24 08 32 49 10 	movl   $0xf0104932,0x8(%esp)
f0102b6e:	f0 
f0102b6f:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102b76:	00 
f0102b77:	c7 04 24 0c 49 10 f0 	movl   $0xf010490c,(%esp)
f0102b7e:	e8 11 d5 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102b83:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102b89:	89 34 24             	mov    %esi,(%esp)
f0102b8c:	e8 94 e3 ff ff       	call   f0100f25 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102b91:	c7 04 24 e0 48 10 f0 	movl   $0xf01048e0,(%esp)
f0102b98:	e8 79 00 00 00       	call   f0102c16 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102b9d:	83 c4 3c             	add    $0x3c,%esp
f0102ba0:	5b                   	pop    %ebx
f0102ba1:	5e                   	pop    %esi
f0102ba2:	5f                   	pop    %edi
f0102ba3:	5d                   	pop    %ebp
f0102ba4:	c3                   	ret    
f0102ba5:	00 00                	add    %al,(%eax)
	...

f0102ba8 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102ba8:	55                   	push   %ebp
f0102ba9:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102bab:	ba 70 00 00 00       	mov    $0x70,%edx
f0102bb0:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bb3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102bb4:	b2 71                	mov    $0x71,%dl
f0102bb6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102bb7:	0f b6 c0             	movzbl %al,%eax
}
f0102bba:	5d                   	pop    %ebp
f0102bbb:	c3                   	ret    

f0102bbc <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102bbc:	55                   	push   %ebp
f0102bbd:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102bbf:	ba 70 00 00 00       	mov    $0x70,%edx
f0102bc4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bc7:	ee                   	out    %al,(%dx)
f0102bc8:	b2 71                	mov    $0x71,%dl
f0102bca:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bcd:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102bce:	5d                   	pop    %ebp
f0102bcf:	c3                   	ret    

f0102bd0 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102bd0:	55                   	push   %ebp
f0102bd1:	89 e5                	mov    %esp,%ebp
f0102bd3:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102bd6:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bd9:	89 04 24             	mov    %eax,(%esp)
f0102bdc:	e8 10 da ff ff       	call   f01005f1 <cputchar>
	*cnt++;
}
f0102be1:	c9                   	leave  
f0102be2:	c3                   	ret    

f0102be3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102be3:	55                   	push   %ebp
f0102be4:	89 e5                	mov    %esp,%ebp
f0102be6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102be9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102bf0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bf3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bf7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bfa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102bfe:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102c01:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c05:	c7 04 24 d0 2b 10 f0 	movl   $0xf0102bd0,(%esp)
f0102c0c:	e8 69 04 00 00       	call   f010307a <vprintfmt>
	return cnt;
}
f0102c11:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102c14:	c9                   	leave  
f0102c15:	c3                   	ret    

f0102c16 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102c16:	55                   	push   %ebp
f0102c17:	89 e5                	mov    %esp,%ebp
f0102c19:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102c1c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102c1f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c23:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c26:	89 04 24             	mov    %eax,(%esp)
f0102c29:	e8 b5 ff ff ff       	call   f0102be3 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102c2e:	c9                   	leave  
f0102c2f:	c3                   	ret    

f0102c30 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102c30:	55                   	push   %ebp
f0102c31:	89 e5                	mov    %esp,%ebp
f0102c33:	57                   	push   %edi
f0102c34:	56                   	push   %esi
f0102c35:	53                   	push   %ebx
f0102c36:	83 ec 10             	sub    $0x10,%esp
f0102c39:	89 c3                	mov    %eax,%ebx
f0102c3b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102c3e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102c41:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102c44:	8b 0a                	mov    (%edx),%ecx
f0102c46:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102c49:	8b 00                	mov    (%eax),%eax
f0102c4b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102c4e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102c55:	eb 77                	jmp    f0102cce <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102c57:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102c5a:	01 c8                	add    %ecx,%eax
f0102c5c:	bf 02 00 00 00       	mov    $0x2,%edi
f0102c61:	99                   	cltd   
f0102c62:	f7 ff                	idiv   %edi
f0102c64:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102c66:	eb 01                	jmp    f0102c69 <stab_binsearch+0x39>
			m--;
f0102c68:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102c69:	39 ca                	cmp    %ecx,%edx
f0102c6b:	7c 1d                	jl     f0102c8a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102c6d:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102c70:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102c75:	39 f7                	cmp    %esi,%edi
f0102c77:	75 ef                	jne    f0102c68 <stab_binsearch+0x38>
f0102c79:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102c7c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102c7f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102c83:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102c86:	73 18                	jae    f0102ca0 <stab_binsearch+0x70>
f0102c88:	eb 05                	jmp    f0102c8f <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102c8a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102c8d:	eb 3f                	jmp    f0102cce <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102c8f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102c92:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102c94:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102c97:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102c9e:	eb 2e                	jmp    f0102cce <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102ca0:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102ca3:	76 15                	jbe    f0102cba <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102ca5:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102ca8:	4f                   	dec    %edi
f0102ca9:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102cac:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102caf:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102cb1:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102cb8:	eb 14                	jmp    f0102cce <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102cba:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102cbd:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102cc0:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102cc2:	ff 45 0c             	incl   0xc(%ebp)
f0102cc5:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102cc7:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102cce:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102cd1:	7e 84                	jle    f0102c57 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102cd3:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102cd7:	75 0d                	jne    f0102ce6 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102cd9:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102cdc:	8b 02                	mov    (%edx),%eax
f0102cde:	48                   	dec    %eax
f0102cdf:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102ce2:	89 01                	mov    %eax,(%ecx)
f0102ce4:	eb 22                	jmp    f0102d08 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ce6:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102ce9:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102ceb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102cee:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102cf0:	eb 01                	jmp    f0102cf3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102cf2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102cf3:	39 c1                	cmp    %eax,%ecx
f0102cf5:	7d 0c                	jge    f0102d03 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102cf7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102cfa:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102cff:	39 f2                	cmp    %esi,%edx
f0102d01:	75 ef                	jne    f0102cf2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102d03:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102d06:	89 02                	mov    %eax,(%edx)
	}
}
f0102d08:	83 c4 10             	add    $0x10,%esp
f0102d0b:	5b                   	pop    %ebx
f0102d0c:	5e                   	pop    %esi
f0102d0d:	5f                   	pop    %edi
f0102d0e:	5d                   	pop    %ebp
f0102d0f:	c3                   	ret    

f0102d10 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102d10:	55                   	push   %ebp
f0102d11:	89 e5                	mov    %esp,%ebp
f0102d13:	83 ec 38             	sub    $0x38,%esp
f0102d16:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102d19:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102d1c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102d1f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102d22:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102d25:	c7 03 e4 3f 10 f0    	movl   $0xf0103fe4,(%ebx)
	info->eip_line = 0;
f0102d2b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102d32:	c7 43 08 e4 3f 10 f0 	movl   $0xf0103fe4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102d39:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102d40:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102d43:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102d4a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102d50:	76 12                	jbe    f0102d64 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102d52:	b8 b6 cc 10 f0       	mov    $0xf010ccb6,%eax
f0102d57:	3d 95 ae 10 f0       	cmp    $0xf010ae95,%eax
f0102d5c:	0f 86 9b 01 00 00    	jbe    f0102efd <debuginfo_eip+0x1ed>
f0102d62:	eb 1c                	jmp    f0102d80 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102d64:	c7 44 24 08 ce 4b 10 	movl   $0xf0104bce,0x8(%esp)
f0102d6b:	f0 
f0102d6c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102d73:	00 
f0102d74:	c7 04 24 db 4b 10 f0 	movl   $0xf0104bdb,(%esp)
f0102d7b:	e8 14 d3 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102d80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102d85:	80 3d b5 cc 10 f0 00 	cmpb   $0x0,0xf010ccb5
f0102d8c:	0f 85 77 01 00 00    	jne    f0102f09 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102d92:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102d99:	b8 94 ae 10 f0       	mov    $0xf010ae94,%eax
f0102d9e:	2d f8 4d 10 f0       	sub    $0xf0104df8,%eax
f0102da3:	c1 f8 02             	sar    $0x2,%eax
f0102da6:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102dac:	83 e8 01             	sub    $0x1,%eax
f0102daf:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102db2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102db6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102dbd:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102dc0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102dc3:	b8 f8 4d 10 f0       	mov    $0xf0104df8,%eax
f0102dc8:	e8 63 fe ff ff       	call   f0102c30 <stab_binsearch>
	if (lfile == 0)
f0102dcd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102dd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102dd5:	85 d2                	test   %edx,%edx
f0102dd7:	0f 84 2c 01 00 00    	je     f0102f09 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102ddd:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102de0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102de3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102de6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102dea:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102df1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102df4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102df7:	b8 f8 4d 10 f0       	mov    $0xf0104df8,%eax
f0102dfc:	e8 2f fe ff ff       	call   f0102c30 <stab_binsearch>

	if (lfun <= rfun) {
f0102e01:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102e04:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102e07:	7f 2e                	jg     f0102e37 <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102e09:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102e0c:	8d 90 f8 4d 10 f0    	lea    -0xfefb208(%eax),%edx
f0102e12:	8b 80 f8 4d 10 f0    	mov    -0xfefb208(%eax),%eax
f0102e18:	b9 b6 cc 10 f0       	mov    $0xf010ccb6,%ecx
f0102e1d:	81 e9 95 ae 10 f0    	sub    $0xf010ae95,%ecx
f0102e23:	39 c8                	cmp    %ecx,%eax
f0102e25:	73 08                	jae    f0102e2f <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102e27:	05 95 ae 10 f0       	add    $0xf010ae95,%eax
f0102e2c:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102e2f:	8b 42 08             	mov    0x8(%edx),%eax
f0102e32:	89 43 10             	mov    %eax,0x10(%ebx)
f0102e35:	eb 06                	jmp    f0102e3d <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102e37:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102e3a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102e3d:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102e44:	00 
f0102e45:	8b 43 08             	mov    0x8(%ebx),%eax
f0102e48:	89 04 24             	mov    %eax,(%esp)
f0102e4b:	e8 9f 09 00 00       	call   f01037ef <strfind>
f0102e50:	2b 43 08             	sub    0x8(%ebx),%eax
f0102e53:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102e56:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102e59:	39 d7                	cmp    %edx,%edi
f0102e5b:	7c 5f                	jl     f0102ebc <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102e5d:	89 f8                	mov    %edi,%eax
f0102e5f:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0102e62:	80 b9 fc 4d 10 f0 84 	cmpb   $0x84,-0xfefb204(%ecx)
f0102e69:	75 18                	jne    f0102e83 <debuginfo_eip+0x173>
f0102e6b:	eb 30                	jmp    f0102e9d <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102e6d:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102e70:	39 fa                	cmp    %edi,%edx
f0102e72:	7f 48                	jg     f0102ebc <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0102e74:	89 f8                	mov    %edi,%eax
f0102e76:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0102e79:	80 3c 8d fc 4d 10 f0 	cmpb   $0x84,-0xfefb204(,%ecx,4)
f0102e80:	84 
f0102e81:	74 1a                	je     f0102e9d <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102e83:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0102e86:	8d 04 85 f8 4d 10 f0 	lea    -0xfefb208(,%eax,4),%eax
f0102e8d:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0102e91:	75 da                	jne    f0102e6d <debuginfo_eip+0x15d>
f0102e93:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0102e97:	74 d4                	je     f0102e6d <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102e99:	39 fa                	cmp    %edi,%edx
f0102e9b:	7f 1f                	jg     f0102ebc <debuginfo_eip+0x1ac>
f0102e9d:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102ea0:	8b 87 f8 4d 10 f0    	mov    -0xfefb208(%edi),%eax
f0102ea6:	ba b6 cc 10 f0       	mov    $0xf010ccb6,%edx
f0102eab:	81 ea 95 ae 10 f0    	sub    $0xf010ae95,%edx
f0102eb1:	39 d0                	cmp    %edx,%eax
f0102eb3:	73 07                	jae    f0102ebc <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102eb5:	05 95 ae 10 f0       	add    $0xf010ae95,%eax
f0102eba:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102ebc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102ebf:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102ec2:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102ec7:	39 ca                	cmp    %ecx,%edx
f0102ec9:	7d 3e                	jge    f0102f09 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0102ecb:	83 c2 01             	add    $0x1,%edx
f0102ece:	39 d1                	cmp    %edx,%ecx
f0102ed0:	7e 37                	jle    f0102f09 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102ed2:	6b f2 0c             	imul   $0xc,%edx,%esi
f0102ed5:	80 be fc 4d 10 f0 a0 	cmpb   $0xa0,-0xfefb204(%esi)
f0102edc:	75 2b                	jne    f0102f09 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0102ede:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102ee2:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102ee5:	39 d1                	cmp    %edx,%ecx
f0102ee7:	7e 1b                	jle    f0102f04 <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102ee9:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0102eec:	80 3c 85 fc 4d 10 f0 	cmpb   $0xa0,-0xfefb204(,%eax,4)
f0102ef3:	a0 
f0102ef4:	74 e8                	je     f0102ede <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102ef6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102efb:	eb 0c                	jmp    f0102f09 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102efd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102f02:	eb 05                	jmp    f0102f09 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0102f04:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102f09:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0102f0c:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0102f0f:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0102f12:	89 ec                	mov    %ebp,%esp
f0102f14:	5d                   	pop    %ebp
f0102f15:	c3                   	ret    
	...

f0102f20 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0102f20:	55                   	push   %ebp
f0102f21:	89 e5                	mov    %esp,%ebp
f0102f23:	57                   	push   %edi
f0102f24:	56                   	push   %esi
f0102f25:	53                   	push   %ebx
f0102f26:	83 ec 3c             	sub    $0x3c,%esp
f0102f29:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102f2c:	89 d7                	mov    %edx,%edi
f0102f2e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f31:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0102f34:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f37:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102f3a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0102f3d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0102f40:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f45:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0102f48:	72 11                	jb     f0102f5b <printnum+0x3b>
f0102f4a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102f4d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0102f50:	76 09                	jbe    f0102f5b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102f52:	83 eb 01             	sub    $0x1,%ebx
f0102f55:	85 db                	test   %ebx,%ebx
f0102f57:	7f 51                	jg     f0102faa <printnum+0x8a>
f0102f59:	eb 5e                	jmp    f0102fb9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0102f5b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0102f5f:	83 eb 01             	sub    $0x1,%ebx
f0102f62:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102f66:	8b 45 10             	mov    0x10(%ebp),%eax
f0102f69:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f6d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0102f71:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0102f75:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102f7c:	00 
f0102f7d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102f80:	89 04 24             	mov    %eax,(%esp)
f0102f83:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f86:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f8a:	e8 e1 0a 00 00       	call   f0103a70 <__udivdi3>
f0102f8f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102f93:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102f97:	89 04 24             	mov    %eax,(%esp)
f0102f9a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102f9e:	89 fa                	mov    %edi,%edx
f0102fa0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fa3:	e8 78 ff ff ff       	call   f0102f20 <printnum>
f0102fa8:	eb 0f                	jmp    f0102fb9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102faa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102fae:	89 34 24             	mov    %esi,(%esp)
f0102fb1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102fb4:	83 eb 01             	sub    $0x1,%ebx
f0102fb7:	75 f1                	jne    f0102faa <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102fb9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102fbd:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0102fc1:	8b 45 10             	mov    0x10(%ebp),%eax
f0102fc4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102fc8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102fcf:	00 
f0102fd0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102fd3:	89 04 24             	mov    %eax,(%esp)
f0102fd6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fd9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fdd:	e8 be 0b 00 00       	call   f0103ba0 <__umoddi3>
f0102fe2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102fe6:	0f be 80 e9 4b 10 f0 	movsbl -0xfefb417(%eax),%eax
f0102fed:	89 04 24             	mov    %eax,(%esp)
f0102ff0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0102ff3:	83 c4 3c             	add    $0x3c,%esp
f0102ff6:	5b                   	pop    %ebx
f0102ff7:	5e                   	pop    %esi
f0102ff8:	5f                   	pop    %edi
f0102ff9:	5d                   	pop    %ebp
f0102ffa:	c3                   	ret    

f0102ffb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0102ffb:	55                   	push   %ebp
f0102ffc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0102ffe:	83 fa 01             	cmp    $0x1,%edx
f0103001:	7e 0e                	jle    f0103011 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103003:	8b 10                	mov    (%eax),%edx
f0103005:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103008:	89 08                	mov    %ecx,(%eax)
f010300a:	8b 02                	mov    (%edx),%eax
f010300c:	8b 52 04             	mov    0x4(%edx),%edx
f010300f:	eb 22                	jmp    f0103033 <getuint+0x38>
	else if (lflag)
f0103011:	85 d2                	test   %edx,%edx
f0103013:	74 10                	je     f0103025 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103015:	8b 10                	mov    (%eax),%edx
f0103017:	8d 4a 04             	lea    0x4(%edx),%ecx
f010301a:	89 08                	mov    %ecx,(%eax)
f010301c:	8b 02                	mov    (%edx),%eax
f010301e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103023:	eb 0e                	jmp    f0103033 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103025:	8b 10                	mov    (%eax),%edx
f0103027:	8d 4a 04             	lea    0x4(%edx),%ecx
f010302a:	89 08                	mov    %ecx,(%eax)
f010302c:	8b 02                	mov    (%edx),%eax
f010302e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103033:	5d                   	pop    %ebp
f0103034:	c3                   	ret    

f0103035 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103035:	55                   	push   %ebp
f0103036:	89 e5                	mov    %esp,%ebp
f0103038:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010303b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010303f:	8b 10                	mov    (%eax),%edx
f0103041:	3b 50 04             	cmp    0x4(%eax),%edx
f0103044:	73 0a                	jae    f0103050 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103046:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103049:	88 0a                	mov    %cl,(%edx)
f010304b:	83 c2 01             	add    $0x1,%edx
f010304e:	89 10                	mov    %edx,(%eax)
}
f0103050:	5d                   	pop    %ebp
f0103051:	c3                   	ret    

f0103052 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103052:	55                   	push   %ebp
f0103053:	89 e5                	mov    %esp,%ebp
f0103055:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103058:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010305b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010305f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103062:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103066:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103069:	89 44 24 04          	mov    %eax,0x4(%esp)
f010306d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103070:	89 04 24             	mov    %eax,(%esp)
f0103073:	e8 02 00 00 00       	call   f010307a <vprintfmt>
	va_end(ap);
}
f0103078:	c9                   	leave  
f0103079:	c3                   	ret    

f010307a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010307a:	55                   	push   %ebp
f010307b:	89 e5                	mov    %esp,%ebp
f010307d:	57                   	push   %edi
f010307e:	56                   	push   %esi
f010307f:	53                   	push   %ebx
f0103080:	83 ec 3c             	sub    $0x3c,%esp
f0103083:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0103086:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0103089:	e9 bb 00 00 00       	jmp    f0103149 <vprintfmt+0xcf>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010308e:	85 c0                	test   %eax,%eax
f0103090:	0f 84 63 04 00 00    	je     f01034f9 <vprintfmt+0x47f>
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
f0103096:	83 f8 1b             	cmp    $0x1b,%eax
f0103099:	0f 85 9a 00 00 00    	jne    f0103139 <vprintfmt+0xbf>
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
f010309f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01030a2:	83 c3 02             	add    $0x2,%ebx
				while (ch != 'm') 
f01030a5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030a8:	80 78 01 6d          	cmpb   $0x6d,0x1(%eax)
f01030ac:	0f 84 81 00 00 00    	je     f0103133 <vprintfmt+0xb9>
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
f01030b2:	ba 00 00 00 00       	mov    $0x0,%edx
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
				{
					ch = *(unsigned char *) fmt++;
f01030b7:	0f b6 03             	movzbl (%ebx),%eax
f01030ba:	83 c3 01             	add    $0x1,%ebx
					if ( ch !=';' && ch!='m')
f01030bd:	83 f8 6d             	cmp    $0x6d,%eax
f01030c0:	0f 95 c1             	setne  %cl
f01030c3:	83 f8 3b             	cmp    $0x3b,%eax
f01030c6:	74 0d                	je     f01030d5 <vprintfmt+0x5b>
f01030c8:	84 c9                	test   %cl,%cl
f01030ca:	74 09                	je     f01030d5 <vprintfmt+0x5b>
						temp_color_no=temp_color_no*10+ch-'0';
f01030cc:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01030cf:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
f01030d3:	eb 55                	jmp    f010312a <vprintfmt+0xb0>
					else if ( ch==';' || ch=='m'){
f01030d5:	83 f8 3b             	cmp    $0x3b,%eax
f01030d8:	74 05                	je     f01030df <vprintfmt+0x65>
f01030da:	83 f8 6d             	cmp    $0x6d,%eax
f01030dd:	75 4b                	jne    f010312a <vprintfmt+0xb0>
						if ( temp_color_no >=30 && temp_color_no<40){// Foreground colors
f01030df:	89 d6                	mov    %edx,%esi
f01030e1:	8d 7a e2             	lea    -0x1e(%edx),%edi
f01030e4:	83 ff 09             	cmp    $0x9,%edi
f01030e7:	77 16                	ja     f01030ff <vprintfmt+0x85>
							char_color = (char_color&0xf0) + (temp_color_no-30);						
f01030e9:	8b 3d 00 73 11 f0    	mov    0xf0117300,%edi
f01030ef:	81 e7 f0 00 00 00    	and    $0xf0,%edi
f01030f5:	8d 7c 3a e2          	lea    -0x1e(%edx,%edi,1),%edi
f01030f9:	89 3d 00 73 11 f0    	mov    %edi,0xf0117300
							}
						if ( temp_color_no >=40 && temp_color_no<50){// Background colors
f01030ff:	83 ee 28             	sub    $0x28,%esi
f0103102:	83 fe 09             	cmp    $0x9,%esi
f0103105:	77 1e                	ja     f0103125 <vprintfmt+0xab>
							char_color = (char_color&0x0f) + ((temp_color_no-40)<<4);
f0103107:	8b 35 00 73 11 f0    	mov    0xf0117300,%esi
f010310d:	83 e6 0f             	and    $0xf,%esi
f0103110:	83 ea 28             	sub    $0x28,%edx
f0103113:	c1 e2 04             	shl    $0x4,%edx
f0103116:	01 f2                	add    %esi,%edx
f0103118:	89 15 00 73 11 f0    	mov    %edx,0xf0117300
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
f010311e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103123:	eb 05                	jmp    f010312a <vprintfmt+0xb0>
f0103125:	ba 00 00 00 00       	mov    $0x0,%edx
			if (ch == '\0')
				return;
			if (ch =='\033'){//if this is Escape character  and this if is char color set.
				int temp_color_no=0;
				ch = *(unsigned char *) fmt++;
				while (ch != 'm') 
f010312a:	84 c9                	test   %cl,%cl
f010312c:	75 89                	jne    f01030b7 <vprintfmt+0x3d>
						}
						//cprintf("0x%o ,",char_color);
						temp_color_no=0;
					}
				}
				if (ch == 'm')
f010312e:	83 f8 6d             	cmp    $0x6d,%eax
f0103131:	75 06                	jne    f0103139 <vprintfmt+0xbf>
					ch = *(unsigned char *) fmt++;
f0103133:	0f b6 03             	movzbl (%ebx),%eax
f0103136:	83 c3 01             	add    $0x1,%ebx
				
			}
			putch(ch, putdat);
f0103139:	8b 55 0c             	mov    0xc(%ebp),%edx
f010313c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103140:	89 04 24             	mov    %eax,(%esp)
f0103143:	ff 55 08             	call   *0x8(%ebp)
f0103146:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103149:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010314c:	0f b6 03             	movzbl (%ebx),%eax
f010314f:	83 c3 01             	add    $0x1,%ebx
f0103152:	83 f8 25             	cmp    $0x25,%eax
f0103155:	0f 85 33 ff ff ff    	jne    f010308e <vprintfmt+0x14>
f010315b:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f010315f:	bf 00 00 00 00       	mov    $0x0,%edi
f0103164:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0103169:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103170:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103175:	eb 23                	jmp    f010319a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103177:	89 c3                	mov    %eax,%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0103179:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f010317d:	eb 1b                	jmp    f010319a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010317f:	89 c3                	mov    %eax,%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103181:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0103185:	eb 13                	jmp    f010319a <vprintfmt+0x120>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103187:	89 c3                	mov    %eax,%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103189:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103190:	eb 08                	jmp    f010319a <vprintfmt+0x120>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103192:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0103195:	be ff ff ff ff       	mov    $0xffffffff,%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010319a:	0f b6 13             	movzbl (%ebx),%edx
f010319d:	0f b6 c2             	movzbl %dl,%eax
f01031a0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01031a3:	8d 43 01             	lea    0x1(%ebx),%eax
f01031a6:	83 ea 23             	sub    $0x23,%edx
f01031a9:	80 fa 55             	cmp    $0x55,%dl
f01031ac:	0f 87 18 03 00 00    	ja     f01034ca <vprintfmt+0x450>
f01031b2:	0f b6 d2             	movzbl %dl,%edx
f01031b5:	ff 24 95 74 4c 10 f0 	jmp    *-0xfefb38c(,%edx,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01031bc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031bf:	83 ee 30             	sub    $0x30,%esi
				ch = *fmt;
f01031c2:	0f be 53 01          	movsbl 0x1(%ebx),%edx
				if (ch < '0' || ch > '9')
f01031c6:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01031c9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031cc:	89 c3                	mov    %eax,%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01031ce:	83 7d e4 09          	cmpl   $0x9,-0x1c(%ebp)
f01031d2:	77 3b                	ja     f010320f <vprintfmt+0x195>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01031d4:	83 c0 01             	add    $0x1,%eax
				precision = precision * 10 + ch - '0';
f01031d7:	8d 1c b6             	lea    (%esi,%esi,4),%ebx
f01031da:	8d 74 5a d0          	lea    -0x30(%edx,%ebx,2),%esi
				ch = *fmt;
f01031de:	0f be 10             	movsbl (%eax),%edx
				if (ch < '0' || ch > '9')
f01031e1:	8d 5a d0             	lea    -0x30(%edx),%ebx
f01031e4:	83 fb 09             	cmp    $0x9,%ebx
f01031e7:	76 eb                	jbe    f01031d4 <vprintfmt+0x15a>
f01031e9:	eb 22                	jmp    f010320d <vprintfmt+0x193>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01031eb:	8b 55 14             	mov    0x14(%ebp),%edx
f01031ee:	8d 5a 04             	lea    0x4(%edx),%ebx
f01031f1:	89 5d 14             	mov    %ebx,0x14(%ebp)
f01031f4:	8b 32                	mov    (%edx),%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031f6:	89 c3                	mov    %eax,%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01031f8:	eb 15                	jmp    f010320f <vprintfmt+0x195>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031fa:	89 c3                	mov    %eax,%ebx
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f01031fc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103200:	79 98                	jns    f010319a <vprintfmt+0x120>
f0103202:	eb 83                	jmp    f0103187 <vprintfmt+0x10d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103204:	89 c3                	mov    %eax,%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103206:	bf 01 00 00 00       	mov    $0x1,%edi
			goto reswitch;
f010320b:	eb 8d                	jmp    f010319a <vprintfmt+0x120>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010320d:	89 c3                	mov    %eax,%ebx
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010320f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103213:	79 85                	jns    f010319a <vprintfmt+0x120>
f0103215:	e9 78 ff ff ff       	jmp    f0103192 <vprintfmt+0x118>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f010321a:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010321d:	89 c3                	mov    %eax,%ebx
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010321f:	e9 76 ff ff ff       	jmp    f010319a <vprintfmt+0x120>
f0103224:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103227:	8b 45 14             	mov    0x14(%ebp),%eax
f010322a:	8d 50 04             	lea    0x4(%eax),%edx
f010322d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103230:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103233:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103237:	8b 00                	mov    (%eax),%eax
f0103239:	89 04 24             	mov    %eax,(%esp)
f010323c:	ff 55 08             	call   *0x8(%ebp)
			break;
f010323f:	e9 05 ff ff ff       	jmp    f0103149 <vprintfmt+0xcf>
f0103244:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103247:	8b 45 14             	mov    0x14(%ebp),%eax
f010324a:	8d 50 04             	lea    0x4(%eax),%edx
f010324d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103250:	8b 00                	mov    (%eax),%eax
f0103252:	89 c2                	mov    %eax,%edx
f0103254:	c1 fa 1f             	sar    $0x1f,%edx
f0103257:	31 d0                	xor    %edx,%eax
f0103259:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010325b:	83 f8 06             	cmp    $0x6,%eax
f010325e:	7f 0b                	jg     f010326b <vprintfmt+0x1f1>
f0103260:	8b 14 85 cc 4d 10 f0 	mov    -0xfefb234(,%eax,4),%edx
f0103267:	85 d2                	test   %edx,%edx
f0103269:	75 23                	jne    f010328e <vprintfmt+0x214>
				printfmt(putch, putdat, "error %d", err);
f010326b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010326f:	c7 44 24 08 01 4c 10 	movl   $0xf0104c01,0x8(%esp)
f0103276:	f0 
f0103277:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010327a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010327e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103281:	89 1c 24             	mov    %ebx,(%esp)
f0103284:	e8 c9 fd ff ff       	call   f0103052 <printfmt>
f0103289:	e9 bb fe ff ff       	jmp    f0103149 <vprintfmt+0xcf>
			else
				printfmt(putch, putdat, "%s", p);
f010328e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103292:	c7 44 24 08 44 49 10 	movl   $0xf0104944,0x8(%esp)
f0103299:	f0 
f010329a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010329d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01032a1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01032a4:	89 1c 24             	mov    %ebx,(%esp)
f01032a7:	e8 a6 fd ff ff       	call   f0103052 <printfmt>
f01032ac:	e9 98 fe ff ff       	jmp    f0103149 <vprintfmt+0xcf>
f01032b1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032b4:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01032b7:	89 5d d8             	mov    %ebx,-0x28(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01032ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01032bd:	8d 50 04             	lea    0x4(%eax),%edx
f01032c0:	89 55 14             	mov    %edx,0x14(%ebp)
f01032c3:	8b 18                	mov    (%eax),%ebx
				p = "(null)";
f01032c5:	85 db                	test   %ebx,%ebx
f01032c7:	b8 fa 4b 10 f0       	mov    $0xf0104bfa,%eax
f01032cc:	0f 44 d8             	cmove  %eax,%ebx
			if (width > 0 && padc != '-')
f01032cf:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01032d3:	7e 06                	jle    f01032db <vprintfmt+0x261>
f01032d5:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f01032d9:	75 10                	jne    f01032eb <vprintfmt+0x271>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01032db:	0f be 03             	movsbl (%ebx),%eax
f01032de:	83 c3 01             	add    $0x1,%ebx
f01032e1:	85 c0                	test   %eax,%eax
f01032e3:	0f 85 82 00 00 00    	jne    f010336b <vprintfmt+0x2f1>
f01032e9:	eb 75                	jmp    f0103360 <vprintfmt+0x2e6>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01032eb:	89 74 24 04          	mov    %esi,0x4(%esp)
f01032ef:	89 1c 24             	mov    %ebx,(%esp)
f01032f2:	e8 84 03 00 00       	call   f010367b <strnlen>
f01032f7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01032fa:	29 c2                	sub    %eax,%edx
f01032fc:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01032ff:	85 d2                	test   %edx,%edx
f0103301:	7e d8                	jle    f01032db <vprintfmt+0x261>
					putch(padc, putdat);
f0103303:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0103307:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010330a:	8b 55 0c             	mov    0xc(%ebp),%edx
f010330d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103311:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103314:	89 04 24             	mov    %eax,(%esp)
f0103317:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010331a:	83 6d dc 01          	subl   $0x1,-0x24(%ebp)
f010331e:	75 ea                	jne    f010330a <vprintfmt+0x290>
f0103320:	eb b9                	jmp    f01032db <vprintfmt+0x261>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103322:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0103326:	74 1b                	je     f0103343 <vprintfmt+0x2c9>
f0103328:	8d 50 e0             	lea    -0x20(%eax),%edx
f010332b:	83 fa 5e             	cmp    $0x5e,%edx
f010332e:	76 13                	jbe    f0103343 <vprintfmt+0x2c9>
					putch('?', putdat);
f0103330:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103333:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103337:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010333e:	ff 55 08             	call   *0x8(%ebp)
f0103341:	eb 0d                	jmp    f0103350 <vprintfmt+0x2d6>
				else
					putch(ch, putdat);
f0103343:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103346:	89 54 24 04          	mov    %edx,0x4(%esp)
f010334a:	89 04 24             	mov    %eax,(%esp)
f010334d:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103350:	83 ef 01             	sub    $0x1,%edi
f0103353:	0f be 03             	movsbl (%ebx),%eax
f0103356:	83 c3 01             	add    $0x1,%ebx
f0103359:	85 c0                	test   %eax,%eax
f010335b:	75 14                	jne    f0103371 <vprintfmt+0x2f7>
f010335d:	89 7d dc             	mov    %edi,-0x24(%ebp)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103360:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103364:	7f 19                	jg     f010337f <vprintfmt+0x305>
f0103366:	e9 de fd ff ff       	jmp    f0103149 <vprintfmt+0xcf>
f010336b:	89 7d e0             	mov    %edi,-0x20(%ebp)
f010336e:	8b 7d dc             	mov    -0x24(%ebp),%edi
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103371:	85 f6                	test   %esi,%esi
f0103373:	78 ad                	js     f0103322 <vprintfmt+0x2a8>
f0103375:	83 ee 01             	sub    $0x1,%esi
f0103378:	79 a8                	jns    f0103322 <vprintfmt+0x2a8>
f010337a:	89 7d dc             	mov    %edi,-0x24(%ebp)
f010337d:	eb e1                	jmp    f0103360 <vprintfmt+0x2e6>
f010337f:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103382:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103385:	8b 75 0c             	mov    0xc(%ebp),%esi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103388:	89 74 24 04          	mov    %esi,0x4(%esp)
f010338c:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103393:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103395:	83 eb 01             	sub    $0x1,%ebx
f0103398:	75 ee                	jne    f0103388 <vprintfmt+0x30e>
f010339a:	e9 aa fd ff ff       	jmp    f0103149 <vprintfmt+0xcf>
f010339f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01033a2:	83 f9 01             	cmp    $0x1,%ecx
f01033a5:	7e 10                	jle    f01033b7 <vprintfmt+0x33d>
		return va_arg(*ap, long long);
f01033a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01033aa:	8d 50 08             	lea    0x8(%eax),%edx
f01033ad:	89 55 14             	mov    %edx,0x14(%ebp)
f01033b0:	8b 30                	mov    (%eax),%esi
f01033b2:	8b 78 04             	mov    0x4(%eax),%edi
f01033b5:	eb 26                	jmp    f01033dd <vprintfmt+0x363>
	else if (lflag)
f01033b7:	85 c9                	test   %ecx,%ecx
f01033b9:	74 12                	je     f01033cd <vprintfmt+0x353>
		return va_arg(*ap, long);
f01033bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01033be:	8d 50 04             	lea    0x4(%eax),%edx
f01033c1:	89 55 14             	mov    %edx,0x14(%ebp)
f01033c4:	8b 30                	mov    (%eax),%esi
f01033c6:	89 f7                	mov    %esi,%edi
f01033c8:	c1 ff 1f             	sar    $0x1f,%edi
f01033cb:	eb 10                	jmp    f01033dd <vprintfmt+0x363>
	else
		return va_arg(*ap, int);
f01033cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01033d0:	8d 50 04             	lea    0x4(%eax),%edx
f01033d3:	89 55 14             	mov    %edx,0x14(%ebp)
f01033d6:	8b 30                	mov    (%eax),%esi
f01033d8:	89 f7                	mov    %esi,%edi
f01033da:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01033dd:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01033e2:	85 ff                	test   %edi,%edi
f01033e4:	0f 89 9e 00 00 00    	jns    f0103488 <vprintfmt+0x40e>
				putch('-', putdat);
f01033ea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033ed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033f1:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01033f8:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01033fb:	f7 de                	neg    %esi
f01033fd:	83 d7 00             	adc    $0x0,%edi
f0103400:	f7 df                	neg    %edi
			}
			base = 10;
f0103402:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103407:	eb 7f                	jmp    f0103488 <vprintfmt+0x40e>
f0103409:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010340c:	89 ca                	mov    %ecx,%edx
f010340e:	8d 45 14             	lea    0x14(%ebp),%eax
f0103411:	e8 e5 fb ff ff       	call   f0102ffb <getuint>
f0103416:	89 c6                	mov    %eax,%esi
f0103418:	89 d7                	mov    %edx,%edi
			base = 10;
f010341a:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010341f:	eb 67                	jmp    f0103488 <vprintfmt+0x40e>
f0103421:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0103424:	89 ca                	mov    %ecx,%edx
f0103426:	8d 45 14             	lea    0x14(%ebp),%eax
f0103429:	e8 cd fb ff ff       	call   f0102ffb <getuint>
f010342e:	89 c6                	mov    %eax,%esi
f0103430:	89 d7                	mov    %edx,%edi
			base = 8;
f0103432:	b8 08 00 00 00       	mov    $0x8,%eax

			goto number;
f0103437:	eb 4f                	jmp    f0103488 <vprintfmt+0x40e>
f0103439:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// pointer
		case 'p':
			putch('0', putdat);
f010343c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010343f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103443:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010344a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010344d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103451:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103458:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010345b:	8b 45 14             	mov    0x14(%ebp),%eax
f010345e:	8d 50 04             	lea    0x4(%eax),%edx
f0103461:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103464:	8b 30                	mov    (%eax),%esi
f0103466:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010346b:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103470:	eb 16                	jmp    f0103488 <vprintfmt+0x40e>
f0103472:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103475:	89 ca                	mov    %ecx,%edx
f0103477:	8d 45 14             	lea    0x14(%ebp),%eax
f010347a:	e8 7c fb ff ff       	call   f0102ffb <getuint>
f010347f:	89 c6                	mov    %eax,%esi
f0103481:	89 d7                	mov    %edx,%edi
			base = 16;
f0103483:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103488:	0f be 55 e0          	movsbl -0x20(%ebp),%edx
f010348c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103490:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103493:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103497:	89 44 24 08          	mov    %eax,0x8(%esp)
f010349b:	89 34 24             	mov    %esi,(%esp)
f010349e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034a2:	8b 55 0c             	mov    0xc(%ebp),%edx
f01034a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01034a8:	e8 73 fa ff ff       	call   f0102f20 <printnum>
			break;
f01034ad:	e9 97 fc ff ff       	jmp    f0103149 <vprintfmt+0xcf>
f01034b2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01034b5:	89 45 e4             	mov    %eax,-0x1c(%ebp)

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01034b8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034bb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034bf:	89 14 24             	mov    %edx,(%esp)
f01034c2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01034c5:	e9 7f fc ff ff       	jmp    f0103149 <vprintfmt+0xcf>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01034ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034d1:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01034d8:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01034db:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01034de:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01034e2:	0f 84 61 fc ff ff    	je     f0103149 <vprintfmt+0xcf>
f01034e8:	83 eb 01             	sub    $0x1,%ebx
f01034eb:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01034ef:	75 f7                	jne    f01034e8 <vprintfmt+0x46e>
f01034f1:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f01034f4:	e9 50 fc ff ff       	jmp    f0103149 <vprintfmt+0xcf>
				/* do nothing */;
			break;
		}
	}
}
f01034f9:	83 c4 3c             	add    $0x3c,%esp
f01034fc:	5b                   	pop    %ebx
f01034fd:	5e                   	pop    %esi
f01034fe:	5f                   	pop    %edi
f01034ff:	5d                   	pop    %ebp
f0103500:	c3                   	ret    

f0103501 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103501:	55                   	push   %ebp
f0103502:	89 e5                	mov    %esp,%ebp
f0103504:	83 ec 28             	sub    $0x28,%esp
f0103507:	8b 45 08             	mov    0x8(%ebp),%eax
f010350a:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010350d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103510:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103514:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103517:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010351e:	85 c0                	test   %eax,%eax
f0103520:	74 30                	je     f0103552 <vsnprintf+0x51>
f0103522:	85 d2                	test   %edx,%edx
f0103524:	7e 2c                	jle    f0103552 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103526:	8b 45 14             	mov    0x14(%ebp),%eax
f0103529:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010352d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103530:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103534:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103537:	89 44 24 04          	mov    %eax,0x4(%esp)
f010353b:	c7 04 24 35 30 10 f0 	movl   $0xf0103035,(%esp)
f0103542:	e8 33 fb ff ff       	call   f010307a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103547:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010354a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010354d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103550:	eb 05                	jmp    f0103557 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103552:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103557:	c9                   	leave  
f0103558:	c3                   	ret    

f0103559 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103559:	55                   	push   %ebp
f010355a:	89 e5                	mov    %esp,%ebp
f010355c:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f010355f:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103562:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103566:	8b 45 10             	mov    0x10(%ebp),%eax
f0103569:	89 44 24 08          	mov    %eax,0x8(%esp)
f010356d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103570:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103574:	8b 45 08             	mov    0x8(%ebp),%eax
f0103577:	89 04 24             	mov    %eax,(%esp)
f010357a:	e8 82 ff ff ff       	call   f0103501 <vsnprintf>
	va_end(ap);

	return rc;
}
f010357f:	c9                   	leave  
f0103580:	c3                   	ret    
	...

f0103590 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103590:	55                   	push   %ebp
f0103591:	89 e5                	mov    %esp,%ebp
f0103593:	57                   	push   %edi
f0103594:	56                   	push   %esi
f0103595:	53                   	push   %ebx
f0103596:	83 ec 1c             	sub    $0x1c,%esp
f0103599:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010359c:	85 c0                	test   %eax,%eax
f010359e:	74 10                	je     f01035b0 <readline+0x20>
		cprintf("%s", prompt);
f01035a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035a4:	c7 04 24 44 49 10 f0 	movl   $0xf0104944,(%esp)
f01035ab:	e8 66 f6 ff ff       	call   f0102c16 <cprintf>

	i = 0;
	echoing = iscons(0);
f01035b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01035b7:	e8 56 d0 ff ff       	call   f0100612 <iscons>
f01035bc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01035be:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01035c3:	e8 39 d0 ff ff       	call   f0100601 <getchar>
f01035c8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01035ca:	85 c0                	test   %eax,%eax
f01035cc:	79 17                	jns    f01035e5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01035ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035d2:	c7 04 24 e8 4d 10 f0 	movl   $0xf0104de8,(%esp)
f01035d9:	e8 38 f6 ff ff       	call   f0102c16 <cprintf>
			return NULL;
f01035de:	b8 00 00 00 00       	mov    $0x0,%eax
f01035e3:	eb 6d                	jmp    f0103652 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01035e5:	83 f8 08             	cmp    $0x8,%eax
f01035e8:	74 05                	je     f01035ef <readline+0x5f>
f01035ea:	83 f8 7f             	cmp    $0x7f,%eax
f01035ed:	75 19                	jne    f0103608 <readline+0x78>
f01035ef:	85 f6                	test   %esi,%esi
f01035f1:	7e 15                	jle    f0103608 <readline+0x78>
			if (echoing)
f01035f3:	85 ff                	test   %edi,%edi
f01035f5:	74 0c                	je     f0103603 <readline+0x73>
				cputchar('\b');
f01035f7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01035fe:	e8 ee cf ff ff       	call   f01005f1 <cputchar>
			i--;
f0103603:	83 ee 01             	sub    $0x1,%esi
f0103606:	eb bb                	jmp    f01035c3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103608:	83 fb 1f             	cmp    $0x1f,%ebx
f010360b:	7e 1f                	jle    f010362c <readline+0x9c>
f010360d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103613:	7f 17                	jg     f010362c <readline+0x9c>
			if (echoing)
f0103615:	85 ff                	test   %edi,%edi
f0103617:	74 08                	je     f0103621 <readline+0x91>
				cputchar(c);
f0103619:	89 1c 24             	mov    %ebx,(%esp)
f010361c:	e8 d0 cf ff ff       	call   f01005f1 <cputchar>
			buf[i++] = c;
f0103621:	88 9e a0 75 11 f0    	mov    %bl,-0xfee8a60(%esi)
f0103627:	83 c6 01             	add    $0x1,%esi
f010362a:	eb 97                	jmp    f01035c3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010362c:	83 fb 0a             	cmp    $0xa,%ebx
f010362f:	74 05                	je     f0103636 <readline+0xa6>
f0103631:	83 fb 0d             	cmp    $0xd,%ebx
f0103634:	75 8d                	jne    f01035c3 <readline+0x33>
			if (echoing)
f0103636:	85 ff                	test   %edi,%edi
f0103638:	74 0c                	je     f0103646 <readline+0xb6>
				cputchar('\n');
f010363a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103641:	e8 ab cf ff ff       	call   f01005f1 <cputchar>
			buf[i] = 0;
f0103646:	c6 86 a0 75 11 f0 00 	movb   $0x0,-0xfee8a60(%esi)
			return buf;
f010364d:	b8 a0 75 11 f0       	mov    $0xf01175a0,%eax
		}
	}
}
f0103652:	83 c4 1c             	add    $0x1c,%esp
f0103655:	5b                   	pop    %ebx
f0103656:	5e                   	pop    %esi
f0103657:	5f                   	pop    %edi
f0103658:	5d                   	pop    %ebp
f0103659:	c3                   	ret    
f010365a:	00 00                	add    %al,(%eax)
f010365c:	00 00                	add    %al,(%eax)
	...

f0103660 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103660:	55                   	push   %ebp
f0103661:	89 e5                	mov    %esp,%ebp
f0103663:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103666:	b8 00 00 00 00       	mov    $0x0,%eax
f010366b:	80 3a 00             	cmpb   $0x0,(%edx)
f010366e:	74 09                	je     f0103679 <strlen+0x19>
		n++;
f0103670:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103673:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103677:	75 f7                	jne    f0103670 <strlen+0x10>
		n++;
	return n;
}
f0103679:	5d                   	pop    %ebp
f010367a:	c3                   	ret    

f010367b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010367b:	55                   	push   %ebp
f010367c:	89 e5                	mov    %esp,%ebp
f010367e:	53                   	push   %ebx
f010367f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103682:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103685:	b8 00 00 00 00       	mov    $0x0,%eax
f010368a:	85 c9                	test   %ecx,%ecx
f010368c:	74 1a                	je     f01036a8 <strnlen+0x2d>
f010368e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103691:	74 15                	je     f01036a8 <strnlen+0x2d>
f0103693:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103698:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010369a:	39 ca                	cmp    %ecx,%edx
f010369c:	74 0a                	je     f01036a8 <strnlen+0x2d>
f010369e:	83 c2 01             	add    $0x1,%edx
f01036a1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01036a6:	75 f0                	jne    f0103698 <strnlen+0x1d>
		n++;
	return n;
}
f01036a8:	5b                   	pop    %ebx
f01036a9:	5d                   	pop    %ebp
f01036aa:	c3                   	ret    

f01036ab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01036ab:	55                   	push   %ebp
f01036ac:	89 e5                	mov    %esp,%ebp
f01036ae:	53                   	push   %ebx
f01036af:	8b 45 08             	mov    0x8(%ebp),%eax
f01036b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01036b5:	ba 00 00 00 00       	mov    $0x0,%edx
f01036ba:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01036be:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01036c1:	83 c2 01             	add    $0x1,%edx
f01036c4:	84 c9                	test   %cl,%cl
f01036c6:	75 f2                	jne    f01036ba <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01036c8:	5b                   	pop    %ebx
f01036c9:	5d                   	pop    %ebp
f01036ca:	c3                   	ret    

f01036cb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01036cb:	55                   	push   %ebp
f01036cc:	89 e5                	mov    %esp,%ebp
f01036ce:	56                   	push   %esi
f01036cf:	53                   	push   %ebx
f01036d0:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036d6:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036d9:	85 f6                	test   %esi,%esi
f01036db:	74 18                	je     f01036f5 <strncpy+0x2a>
f01036dd:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01036e2:	0f b6 1a             	movzbl (%edx),%ebx
f01036e5:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01036e8:	80 3a 01             	cmpb   $0x1,(%edx)
f01036eb:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036ee:	83 c1 01             	add    $0x1,%ecx
f01036f1:	39 f1                	cmp    %esi,%ecx
f01036f3:	75 ed                	jne    f01036e2 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01036f5:	5b                   	pop    %ebx
f01036f6:	5e                   	pop    %esi
f01036f7:	5d                   	pop    %ebp
f01036f8:	c3                   	ret    

f01036f9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01036f9:	55                   	push   %ebp
f01036fa:	89 e5                	mov    %esp,%ebp
f01036fc:	57                   	push   %edi
f01036fd:	56                   	push   %esi
f01036fe:	53                   	push   %ebx
f01036ff:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103702:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103705:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103708:	89 f8                	mov    %edi,%eax
f010370a:	85 f6                	test   %esi,%esi
f010370c:	74 2b                	je     f0103739 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010370e:	83 fe 01             	cmp    $0x1,%esi
f0103711:	74 23                	je     f0103736 <strlcpy+0x3d>
f0103713:	0f b6 0b             	movzbl (%ebx),%ecx
f0103716:	84 c9                	test   %cl,%cl
f0103718:	74 1c                	je     f0103736 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010371a:	83 ee 02             	sub    $0x2,%esi
f010371d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103722:	88 08                	mov    %cl,(%eax)
f0103724:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103727:	39 f2                	cmp    %esi,%edx
f0103729:	74 0b                	je     f0103736 <strlcpy+0x3d>
f010372b:	83 c2 01             	add    $0x1,%edx
f010372e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103732:	84 c9                	test   %cl,%cl
f0103734:	75 ec                	jne    f0103722 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103736:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103739:	29 f8                	sub    %edi,%eax
}
f010373b:	5b                   	pop    %ebx
f010373c:	5e                   	pop    %esi
f010373d:	5f                   	pop    %edi
f010373e:	5d                   	pop    %ebp
f010373f:	c3                   	ret    

f0103740 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103740:	55                   	push   %ebp
f0103741:	89 e5                	mov    %esp,%ebp
f0103743:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103746:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103749:	0f b6 01             	movzbl (%ecx),%eax
f010374c:	84 c0                	test   %al,%al
f010374e:	74 16                	je     f0103766 <strcmp+0x26>
f0103750:	3a 02                	cmp    (%edx),%al
f0103752:	75 12                	jne    f0103766 <strcmp+0x26>
		p++, q++;
f0103754:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103757:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f010375b:	84 c0                	test   %al,%al
f010375d:	74 07                	je     f0103766 <strcmp+0x26>
f010375f:	83 c1 01             	add    $0x1,%ecx
f0103762:	3a 02                	cmp    (%edx),%al
f0103764:	74 ee                	je     f0103754 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103766:	0f b6 c0             	movzbl %al,%eax
f0103769:	0f b6 12             	movzbl (%edx),%edx
f010376c:	29 d0                	sub    %edx,%eax
}
f010376e:	5d                   	pop    %ebp
f010376f:	c3                   	ret    

f0103770 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103770:	55                   	push   %ebp
f0103771:	89 e5                	mov    %esp,%ebp
f0103773:	53                   	push   %ebx
f0103774:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103777:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010377a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010377d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103782:	85 d2                	test   %edx,%edx
f0103784:	74 28                	je     f01037ae <strncmp+0x3e>
f0103786:	0f b6 01             	movzbl (%ecx),%eax
f0103789:	84 c0                	test   %al,%al
f010378b:	74 24                	je     f01037b1 <strncmp+0x41>
f010378d:	3a 03                	cmp    (%ebx),%al
f010378f:	75 20                	jne    f01037b1 <strncmp+0x41>
f0103791:	83 ea 01             	sub    $0x1,%edx
f0103794:	74 13                	je     f01037a9 <strncmp+0x39>
		n--, p++, q++;
f0103796:	83 c1 01             	add    $0x1,%ecx
f0103799:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010379c:	0f b6 01             	movzbl (%ecx),%eax
f010379f:	84 c0                	test   %al,%al
f01037a1:	74 0e                	je     f01037b1 <strncmp+0x41>
f01037a3:	3a 03                	cmp    (%ebx),%al
f01037a5:	74 ea                	je     f0103791 <strncmp+0x21>
f01037a7:	eb 08                	jmp    f01037b1 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01037a9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01037ae:	5b                   	pop    %ebx
f01037af:	5d                   	pop    %ebp
f01037b0:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01037b1:	0f b6 01             	movzbl (%ecx),%eax
f01037b4:	0f b6 13             	movzbl (%ebx),%edx
f01037b7:	29 d0                	sub    %edx,%eax
f01037b9:	eb f3                	jmp    f01037ae <strncmp+0x3e>

f01037bb <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01037bb:	55                   	push   %ebp
f01037bc:	89 e5                	mov    %esp,%ebp
f01037be:	8b 45 08             	mov    0x8(%ebp),%eax
f01037c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01037c5:	0f b6 10             	movzbl (%eax),%edx
f01037c8:	84 d2                	test   %dl,%dl
f01037ca:	74 1c                	je     f01037e8 <strchr+0x2d>
		if (*s == c)
f01037cc:	38 ca                	cmp    %cl,%dl
f01037ce:	75 09                	jne    f01037d9 <strchr+0x1e>
f01037d0:	eb 1b                	jmp    f01037ed <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01037d2:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01037d5:	38 ca                	cmp    %cl,%dl
f01037d7:	74 14                	je     f01037ed <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01037d9:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01037dd:	84 d2                	test   %dl,%dl
f01037df:	75 f1                	jne    f01037d2 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01037e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01037e6:	eb 05                	jmp    f01037ed <strchr+0x32>
f01037e8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01037ed:	5d                   	pop    %ebp
f01037ee:	c3                   	ret    

f01037ef <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01037ef:	55                   	push   %ebp
f01037f0:	89 e5                	mov    %esp,%ebp
f01037f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01037f5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01037f9:	0f b6 10             	movzbl (%eax),%edx
f01037fc:	84 d2                	test   %dl,%dl
f01037fe:	74 14                	je     f0103814 <strfind+0x25>
		if (*s == c)
f0103800:	38 ca                	cmp    %cl,%dl
f0103802:	75 06                	jne    f010380a <strfind+0x1b>
f0103804:	eb 0e                	jmp    f0103814 <strfind+0x25>
f0103806:	38 ca                	cmp    %cl,%dl
f0103808:	74 0a                	je     f0103814 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010380a:	83 c0 01             	add    $0x1,%eax
f010380d:	0f b6 10             	movzbl (%eax),%edx
f0103810:	84 d2                	test   %dl,%dl
f0103812:	75 f2                	jne    f0103806 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103814:	5d                   	pop    %ebp
f0103815:	c3                   	ret    

f0103816 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103816:	55                   	push   %ebp
f0103817:	89 e5                	mov    %esp,%ebp
f0103819:	83 ec 0c             	sub    $0xc,%esp
f010381c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010381f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103822:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103825:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103828:	8b 45 0c             	mov    0xc(%ebp),%eax
f010382b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010382e:	85 c9                	test   %ecx,%ecx
f0103830:	74 30                	je     f0103862 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103832:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103838:	75 25                	jne    f010385f <memset+0x49>
f010383a:	f6 c1 03             	test   $0x3,%cl
f010383d:	75 20                	jne    f010385f <memset+0x49>
		c &= 0xFF;
f010383f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103842:	89 d3                	mov    %edx,%ebx
f0103844:	c1 e3 08             	shl    $0x8,%ebx
f0103847:	89 d6                	mov    %edx,%esi
f0103849:	c1 e6 18             	shl    $0x18,%esi
f010384c:	89 d0                	mov    %edx,%eax
f010384e:	c1 e0 10             	shl    $0x10,%eax
f0103851:	09 f0                	or     %esi,%eax
f0103853:	09 d0                	or     %edx,%eax
f0103855:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103857:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010385a:	fc                   	cld    
f010385b:	f3 ab                	rep stos %eax,%es:(%edi)
f010385d:	eb 03                	jmp    f0103862 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010385f:	fc                   	cld    
f0103860:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103862:	89 f8                	mov    %edi,%eax
f0103864:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103867:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010386a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010386d:	89 ec                	mov    %ebp,%esp
f010386f:	5d                   	pop    %ebp
f0103870:	c3                   	ret    

f0103871 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103871:	55                   	push   %ebp
f0103872:	89 e5                	mov    %esp,%ebp
f0103874:	83 ec 08             	sub    $0x8,%esp
f0103877:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010387a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010387d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103880:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103883:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103886:	39 c6                	cmp    %eax,%esi
f0103888:	73 36                	jae    f01038c0 <memmove+0x4f>
f010388a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010388d:	39 d0                	cmp    %edx,%eax
f010388f:	73 2f                	jae    f01038c0 <memmove+0x4f>
		s += n;
		d += n;
f0103891:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103894:	f6 c2 03             	test   $0x3,%dl
f0103897:	75 1b                	jne    f01038b4 <memmove+0x43>
f0103899:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010389f:	75 13                	jne    f01038b4 <memmove+0x43>
f01038a1:	f6 c1 03             	test   $0x3,%cl
f01038a4:	75 0e                	jne    f01038b4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01038a6:	83 ef 04             	sub    $0x4,%edi
f01038a9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01038ac:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01038af:	fd                   	std    
f01038b0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01038b2:	eb 09                	jmp    f01038bd <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01038b4:	83 ef 01             	sub    $0x1,%edi
f01038b7:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01038ba:	fd                   	std    
f01038bb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01038bd:	fc                   	cld    
f01038be:	eb 20                	jmp    f01038e0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01038c0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01038c6:	75 13                	jne    f01038db <memmove+0x6a>
f01038c8:	a8 03                	test   $0x3,%al
f01038ca:	75 0f                	jne    f01038db <memmove+0x6a>
f01038cc:	f6 c1 03             	test   $0x3,%cl
f01038cf:	75 0a                	jne    f01038db <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01038d1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01038d4:	89 c7                	mov    %eax,%edi
f01038d6:	fc                   	cld    
f01038d7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01038d9:	eb 05                	jmp    f01038e0 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01038db:	89 c7                	mov    %eax,%edi
f01038dd:	fc                   	cld    
f01038de:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01038e0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01038e3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01038e6:	89 ec                	mov    %ebp,%esp
f01038e8:	5d                   	pop    %ebp
f01038e9:	c3                   	ret    

f01038ea <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01038ea:	55                   	push   %ebp
f01038eb:	89 e5                	mov    %esp,%ebp
f01038ed:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01038f0:	8b 45 10             	mov    0x10(%ebp),%eax
f01038f3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038f7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103901:	89 04 24             	mov    %eax,(%esp)
f0103904:	e8 68 ff ff ff       	call   f0103871 <memmove>
}
f0103909:	c9                   	leave  
f010390a:	c3                   	ret    

f010390b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010390b:	55                   	push   %ebp
f010390c:	89 e5                	mov    %esp,%ebp
f010390e:	57                   	push   %edi
f010390f:	56                   	push   %esi
f0103910:	53                   	push   %ebx
f0103911:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103914:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103917:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010391a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010391f:	85 ff                	test   %edi,%edi
f0103921:	74 37                	je     f010395a <memcmp+0x4f>
		if (*s1 != *s2)
f0103923:	0f b6 03             	movzbl (%ebx),%eax
f0103926:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103929:	83 ef 01             	sub    $0x1,%edi
f010392c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103931:	38 c8                	cmp    %cl,%al
f0103933:	74 1c                	je     f0103951 <memcmp+0x46>
f0103935:	eb 10                	jmp    f0103947 <memcmp+0x3c>
f0103937:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010393c:	83 c2 01             	add    $0x1,%edx
f010393f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103943:	38 c8                	cmp    %cl,%al
f0103945:	74 0a                	je     f0103951 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103947:	0f b6 c0             	movzbl %al,%eax
f010394a:	0f b6 c9             	movzbl %cl,%ecx
f010394d:	29 c8                	sub    %ecx,%eax
f010394f:	eb 09                	jmp    f010395a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103951:	39 fa                	cmp    %edi,%edx
f0103953:	75 e2                	jne    f0103937 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103955:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010395a:	5b                   	pop    %ebx
f010395b:	5e                   	pop    %esi
f010395c:	5f                   	pop    %edi
f010395d:	5d                   	pop    %ebp
f010395e:	c3                   	ret    

f010395f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010395f:	55                   	push   %ebp
f0103960:	89 e5                	mov    %esp,%ebp
f0103962:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103965:	89 c2                	mov    %eax,%edx
f0103967:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010396a:	39 d0                	cmp    %edx,%eax
f010396c:	73 15                	jae    f0103983 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f010396e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103972:	38 08                	cmp    %cl,(%eax)
f0103974:	75 06                	jne    f010397c <memfind+0x1d>
f0103976:	eb 0b                	jmp    f0103983 <memfind+0x24>
f0103978:	38 08                	cmp    %cl,(%eax)
f010397a:	74 07                	je     f0103983 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010397c:	83 c0 01             	add    $0x1,%eax
f010397f:	39 d0                	cmp    %edx,%eax
f0103981:	75 f5                	jne    f0103978 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103983:	5d                   	pop    %ebp
f0103984:	c3                   	ret    

f0103985 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103985:	55                   	push   %ebp
f0103986:	89 e5                	mov    %esp,%ebp
f0103988:	57                   	push   %edi
f0103989:	56                   	push   %esi
f010398a:	53                   	push   %ebx
f010398b:	8b 55 08             	mov    0x8(%ebp),%edx
f010398e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103991:	0f b6 02             	movzbl (%edx),%eax
f0103994:	3c 20                	cmp    $0x20,%al
f0103996:	74 04                	je     f010399c <strtol+0x17>
f0103998:	3c 09                	cmp    $0x9,%al
f010399a:	75 0e                	jne    f01039aa <strtol+0x25>
		s++;
f010399c:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010399f:	0f b6 02             	movzbl (%edx),%eax
f01039a2:	3c 20                	cmp    $0x20,%al
f01039a4:	74 f6                	je     f010399c <strtol+0x17>
f01039a6:	3c 09                	cmp    $0x9,%al
f01039a8:	74 f2                	je     f010399c <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01039aa:	3c 2b                	cmp    $0x2b,%al
f01039ac:	75 0a                	jne    f01039b8 <strtol+0x33>
		s++;
f01039ae:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01039b1:	bf 00 00 00 00       	mov    $0x0,%edi
f01039b6:	eb 10                	jmp    f01039c8 <strtol+0x43>
f01039b8:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01039bd:	3c 2d                	cmp    $0x2d,%al
f01039bf:	75 07                	jne    f01039c8 <strtol+0x43>
		s++, neg = 1;
f01039c1:	83 c2 01             	add    $0x1,%edx
f01039c4:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01039c8:	85 db                	test   %ebx,%ebx
f01039ca:	0f 94 c0             	sete   %al
f01039cd:	74 05                	je     f01039d4 <strtol+0x4f>
f01039cf:	83 fb 10             	cmp    $0x10,%ebx
f01039d2:	75 15                	jne    f01039e9 <strtol+0x64>
f01039d4:	80 3a 30             	cmpb   $0x30,(%edx)
f01039d7:	75 10                	jne    f01039e9 <strtol+0x64>
f01039d9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01039dd:	75 0a                	jne    f01039e9 <strtol+0x64>
		s += 2, base = 16;
f01039df:	83 c2 02             	add    $0x2,%edx
f01039e2:	bb 10 00 00 00       	mov    $0x10,%ebx
f01039e7:	eb 13                	jmp    f01039fc <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f01039e9:	84 c0                	test   %al,%al
f01039eb:	74 0f                	je     f01039fc <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01039ed:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01039f2:	80 3a 30             	cmpb   $0x30,(%edx)
f01039f5:	75 05                	jne    f01039fc <strtol+0x77>
		s++, base = 8;
f01039f7:	83 c2 01             	add    $0x1,%edx
f01039fa:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01039fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a01:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103a03:	0f b6 0a             	movzbl (%edx),%ecx
f0103a06:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103a09:	80 fb 09             	cmp    $0x9,%bl
f0103a0c:	77 08                	ja     f0103a16 <strtol+0x91>
			dig = *s - '0';
f0103a0e:	0f be c9             	movsbl %cl,%ecx
f0103a11:	83 e9 30             	sub    $0x30,%ecx
f0103a14:	eb 1e                	jmp    f0103a34 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103a16:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103a19:	80 fb 19             	cmp    $0x19,%bl
f0103a1c:	77 08                	ja     f0103a26 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103a1e:	0f be c9             	movsbl %cl,%ecx
f0103a21:	83 e9 57             	sub    $0x57,%ecx
f0103a24:	eb 0e                	jmp    f0103a34 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103a26:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103a29:	80 fb 19             	cmp    $0x19,%bl
f0103a2c:	77 14                	ja     f0103a42 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103a2e:	0f be c9             	movsbl %cl,%ecx
f0103a31:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103a34:	39 f1                	cmp    %esi,%ecx
f0103a36:	7d 0e                	jge    f0103a46 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103a38:	83 c2 01             	add    $0x1,%edx
f0103a3b:	0f af c6             	imul   %esi,%eax
f0103a3e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103a40:	eb c1                	jmp    f0103a03 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103a42:	89 c1                	mov    %eax,%ecx
f0103a44:	eb 02                	jmp    f0103a48 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103a46:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103a48:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103a4c:	74 05                	je     f0103a53 <strtol+0xce>
		*endptr = (char *) s;
f0103a4e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a51:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103a53:	89 ca                	mov    %ecx,%edx
f0103a55:	f7 da                	neg    %edx
f0103a57:	85 ff                	test   %edi,%edi
f0103a59:	0f 45 c2             	cmovne %edx,%eax
}
f0103a5c:	5b                   	pop    %ebx
f0103a5d:	5e                   	pop    %esi
f0103a5e:	5f                   	pop    %edi
f0103a5f:	5d                   	pop    %ebp
f0103a60:	c3                   	ret    
	...

f0103a70 <__udivdi3>:
f0103a70:	83 ec 1c             	sub    $0x1c,%esp
f0103a73:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103a77:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103a7b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103a7f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103a83:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103a87:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103a8b:	85 ff                	test   %edi,%edi
f0103a8d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103a91:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a95:	89 cd                	mov    %ecx,%ebp
f0103a97:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a9b:	75 33                	jne    f0103ad0 <__udivdi3+0x60>
f0103a9d:	39 f1                	cmp    %esi,%ecx
f0103a9f:	77 57                	ja     f0103af8 <__udivdi3+0x88>
f0103aa1:	85 c9                	test   %ecx,%ecx
f0103aa3:	75 0b                	jne    f0103ab0 <__udivdi3+0x40>
f0103aa5:	b8 01 00 00 00       	mov    $0x1,%eax
f0103aaa:	31 d2                	xor    %edx,%edx
f0103aac:	f7 f1                	div    %ecx
f0103aae:	89 c1                	mov    %eax,%ecx
f0103ab0:	89 f0                	mov    %esi,%eax
f0103ab2:	31 d2                	xor    %edx,%edx
f0103ab4:	f7 f1                	div    %ecx
f0103ab6:	89 c6                	mov    %eax,%esi
f0103ab8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103abc:	f7 f1                	div    %ecx
f0103abe:	89 f2                	mov    %esi,%edx
f0103ac0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ac4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ac8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103acc:	83 c4 1c             	add    $0x1c,%esp
f0103acf:	c3                   	ret    
f0103ad0:	31 d2                	xor    %edx,%edx
f0103ad2:	31 c0                	xor    %eax,%eax
f0103ad4:	39 f7                	cmp    %esi,%edi
f0103ad6:	77 e8                	ja     f0103ac0 <__udivdi3+0x50>
f0103ad8:	0f bd cf             	bsr    %edi,%ecx
f0103adb:	83 f1 1f             	xor    $0x1f,%ecx
f0103ade:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103ae2:	75 2c                	jne    f0103b10 <__udivdi3+0xa0>
f0103ae4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103ae8:	76 04                	jbe    f0103aee <__udivdi3+0x7e>
f0103aea:	39 f7                	cmp    %esi,%edi
f0103aec:	73 d2                	jae    f0103ac0 <__udivdi3+0x50>
f0103aee:	31 d2                	xor    %edx,%edx
f0103af0:	b8 01 00 00 00       	mov    $0x1,%eax
f0103af5:	eb c9                	jmp    f0103ac0 <__udivdi3+0x50>
f0103af7:	90                   	nop
f0103af8:	89 f2                	mov    %esi,%edx
f0103afa:	f7 f1                	div    %ecx
f0103afc:	31 d2                	xor    %edx,%edx
f0103afe:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b02:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b06:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b0a:	83 c4 1c             	add    $0x1c,%esp
f0103b0d:	c3                   	ret    
f0103b0e:	66 90                	xchg   %ax,%ax
f0103b10:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b15:	b8 20 00 00 00       	mov    $0x20,%eax
f0103b1a:	89 ea                	mov    %ebp,%edx
f0103b1c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103b20:	d3 e7                	shl    %cl,%edi
f0103b22:	89 c1                	mov    %eax,%ecx
f0103b24:	d3 ea                	shr    %cl,%edx
f0103b26:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b2b:	09 fa                	or     %edi,%edx
f0103b2d:	89 f7                	mov    %esi,%edi
f0103b2f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b33:	89 f2                	mov    %esi,%edx
f0103b35:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103b39:	d3 e5                	shl    %cl,%ebp
f0103b3b:	89 c1                	mov    %eax,%ecx
f0103b3d:	d3 ef                	shr    %cl,%edi
f0103b3f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b44:	d3 e2                	shl    %cl,%edx
f0103b46:	89 c1                	mov    %eax,%ecx
f0103b48:	d3 ee                	shr    %cl,%esi
f0103b4a:	09 d6                	or     %edx,%esi
f0103b4c:	89 fa                	mov    %edi,%edx
f0103b4e:	89 f0                	mov    %esi,%eax
f0103b50:	f7 74 24 0c          	divl   0xc(%esp)
f0103b54:	89 d7                	mov    %edx,%edi
f0103b56:	89 c6                	mov    %eax,%esi
f0103b58:	f7 e5                	mul    %ebp
f0103b5a:	39 d7                	cmp    %edx,%edi
f0103b5c:	72 22                	jb     f0103b80 <__udivdi3+0x110>
f0103b5e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103b62:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103b67:	d3 e5                	shl    %cl,%ebp
f0103b69:	39 c5                	cmp    %eax,%ebp
f0103b6b:	73 04                	jae    f0103b71 <__udivdi3+0x101>
f0103b6d:	39 d7                	cmp    %edx,%edi
f0103b6f:	74 0f                	je     f0103b80 <__udivdi3+0x110>
f0103b71:	89 f0                	mov    %esi,%eax
f0103b73:	31 d2                	xor    %edx,%edx
f0103b75:	e9 46 ff ff ff       	jmp    f0103ac0 <__udivdi3+0x50>
f0103b7a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103b80:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103b83:	31 d2                	xor    %edx,%edx
f0103b85:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103b89:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103b8d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103b91:	83 c4 1c             	add    $0x1c,%esp
f0103b94:	c3                   	ret    
	...

f0103ba0 <__umoddi3>:
f0103ba0:	83 ec 1c             	sub    $0x1c,%esp
f0103ba3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103ba7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103bab:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103baf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103bb3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103bb7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103bbb:	85 ed                	test   %ebp,%ebp
f0103bbd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103bc1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103bc5:	89 cf                	mov    %ecx,%edi
f0103bc7:	89 04 24             	mov    %eax,(%esp)
f0103bca:	89 f2                	mov    %esi,%edx
f0103bcc:	75 1a                	jne    f0103be8 <__umoddi3+0x48>
f0103bce:	39 f1                	cmp    %esi,%ecx
f0103bd0:	76 4e                	jbe    f0103c20 <__umoddi3+0x80>
f0103bd2:	f7 f1                	div    %ecx
f0103bd4:	89 d0                	mov    %edx,%eax
f0103bd6:	31 d2                	xor    %edx,%edx
f0103bd8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103bdc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103be0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103be4:	83 c4 1c             	add    $0x1c,%esp
f0103be7:	c3                   	ret    
f0103be8:	39 f5                	cmp    %esi,%ebp
f0103bea:	77 54                	ja     f0103c40 <__umoddi3+0xa0>
f0103bec:	0f bd c5             	bsr    %ebp,%eax
f0103bef:	83 f0 1f             	xor    $0x1f,%eax
f0103bf2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bf6:	75 60                	jne    f0103c58 <__umoddi3+0xb8>
f0103bf8:	3b 0c 24             	cmp    (%esp),%ecx
f0103bfb:	0f 87 07 01 00 00    	ja     f0103d08 <__umoddi3+0x168>
f0103c01:	89 f2                	mov    %esi,%edx
f0103c03:	8b 34 24             	mov    (%esp),%esi
f0103c06:	29 ce                	sub    %ecx,%esi
f0103c08:	19 ea                	sbb    %ebp,%edx
f0103c0a:	89 34 24             	mov    %esi,(%esp)
f0103c0d:	8b 04 24             	mov    (%esp),%eax
f0103c10:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c14:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c18:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c1c:	83 c4 1c             	add    $0x1c,%esp
f0103c1f:	c3                   	ret    
f0103c20:	85 c9                	test   %ecx,%ecx
f0103c22:	75 0b                	jne    f0103c2f <__umoddi3+0x8f>
f0103c24:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c29:	31 d2                	xor    %edx,%edx
f0103c2b:	f7 f1                	div    %ecx
f0103c2d:	89 c1                	mov    %eax,%ecx
f0103c2f:	89 f0                	mov    %esi,%eax
f0103c31:	31 d2                	xor    %edx,%edx
f0103c33:	f7 f1                	div    %ecx
f0103c35:	8b 04 24             	mov    (%esp),%eax
f0103c38:	f7 f1                	div    %ecx
f0103c3a:	eb 98                	jmp    f0103bd4 <__umoddi3+0x34>
f0103c3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c40:	89 f2                	mov    %esi,%edx
f0103c42:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c46:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c4a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c4e:	83 c4 1c             	add    $0x1c,%esp
f0103c51:	c3                   	ret    
f0103c52:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c58:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c5d:	89 e8                	mov    %ebp,%eax
f0103c5f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103c64:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103c68:	89 fa                	mov    %edi,%edx
f0103c6a:	d3 e0                	shl    %cl,%eax
f0103c6c:	89 e9                	mov    %ebp,%ecx
f0103c6e:	d3 ea                	shr    %cl,%edx
f0103c70:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c75:	09 c2                	or     %eax,%edx
f0103c77:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103c7b:	89 14 24             	mov    %edx,(%esp)
f0103c7e:	89 f2                	mov    %esi,%edx
f0103c80:	d3 e7                	shl    %cl,%edi
f0103c82:	89 e9                	mov    %ebp,%ecx
f0103c84:	d3 ea                	shr    %cl,%edx
f0103c86:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c8b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c8f:	d3 e6                	shl    %cl,%esi
f0103c91:	89 e9                	mov    %ebp,%ecx
f0103c93:	d3 e8                	shr    %cl,%eax
f0103c95:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c9a:	09 f0                	or     %esi,%eax
f0103c9c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103ca0:	f7 34 24             	divl   (%esp)
f0103ca3:	d3 e6                	shl    %cl,%esi
f0103ca5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103ca9:	89 d6                	mov    %edx,%esi
f0103cab:	f7 e7                	mul    %edi
f0103cad:	39 d6                	cmp    %edx,%esi
f0103caf:	89 c1                	mov    %eax,%ecx
f0103cb1:	89 d7                	mov    %edx,%edi
f0103cb3:	72 3f                	jb     f0103cf4 <__umoddi3+0x154>
f0103cb5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103cb9:	72 35                	jb     f0103cf0 <__umoddi3+0x150>
f0103cbb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103cbf:	29 c8                	sub    %ecx,%eax
f0103cc1:	19 fe                	sbb    %edi,%esi
f0103cc3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103cc8:	89 f2                	mov    %esi,%edx
f0103cca:	d3 e8                	shr    %cl,%eax
f0103ccc:	89 e9                	mov    %ebp,%ecx
f0103cce:	d3 e2                	shl    %cl,%edx
f0103cd0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103cd5:	09 d0                	or     %edx,%eax
f0103cd7:	89 f2                	mov    %esi,%edx
f0103cd9:	d3 ea                	shr    %cl,%edx
f0103cdb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cdf:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ce3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ce7:	83 c4 1c             	add    $0x1c,%esp
f0103cea:	c3                   	ret    
f0103ceb:	90                   	nop
f0103cec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cf0:	39 d6                	cmp    %edx,%esi
f0103cf2:	75 c7                	jne    f0103cbb <__umoddi3+0x11b>
f0103cf4:	89 d7                	mov    %edx,%edi
f0103cf6:	89 c1                	mov    %eax,%ecx
f0103cf8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0103cfc:	1b 3c 24             	sbb    (%esp),%edi
f0103cff:	eb ba                	jmp    f0103cbb <__umoddi3+0x11b>
f0103d01:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103d08:	39 f5                	cmp    %esi,%ebp
f0103d0a:	0f 82 f1 fe ff ff    	jb     f0103c01 <__umoddi3+0x61>
f0103d10:	e9 f8 fe ff ff       	jmp    f0103c0d <__umoddi3+0x6d>
