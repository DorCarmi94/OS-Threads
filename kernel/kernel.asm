
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	18010113          	addi	sp,sp,384 # 8000a180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	fee70713          	addi	a4,a4,-18 # 8000a040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	03c78793          	addi	a5,a5,60 # 800070a0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffaa7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	e4a78793          	addi	a5,a5,-438 # 80000ef8 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00003097          	auipc	ra,0x3
    80000122:	0a6080e7          	jalr	166(ra) # 800031c4 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00012517          	auipc	a0,0x12
    80000180:	00450513          	addi	a0,a0,4 # 80012180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	aae080e7          	jalr	-1362(ra) # 80000c32 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00012497          	auipc	s1,0x12
    80000190:	ff448493          	addi	s1,s1,-12 # 80012180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00012917          	auipc	s2,0x12
    80000198:	08490913          	addi	s2,s2,132 # 80012218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	994080e7          	jalr	-1644(ra) # 80001b46 <myproc>
    800001ba:	4d5c                	lw	a5,28(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	6e0080e7          	jalr	1760(ra) # 800028a2 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00003097          	auipc	ra,0x3
    80000202:	f70080e7          	jalr	-144(ra) # 8000316e <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00012517          	auipc	a0,0x12
    80000216:	f6e50513          	addi	a0,a0,-146 # 80012180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	acc080e7          	jalr	-1332(ra) # 80000ce6 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00012517          	auipc	a0,0x12
    8000022c:	f5850513          	addi	a0,a0,-168 # 80012180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	ab6080e7          	jalr	-1354(ra) # 80000ce6 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00012717          	auipc	a4,0x12
    80000262:	faf72d23          	sw	a5,-70(a4) # 80012218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00012517          	auipc	a0,0x12
    800002bc:	ec850513          	addi	a0,a0,-312 # 80012180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	972080e7          	jalr	-1678(ra) # 80000c32 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00003097          	auipc	ra,0x3
    800002e2:	f3c080e7          	jalr	-196(ra) # 8000321a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00012517          	auipc	a0,0x12
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80012180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	9f8080e7          	jalr	-1544(ra) # 80000ce6 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00012717          	auipc	a4,0x12
    8000030e:	e7670713          	addi	a4,a4,-394 # 80012180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00012797          	auipc	a5,0x12
    80000338:	e4c78793          	addi	a5,a5,-436 # 80012180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00012797          	auipc	a5,0x12
    80000366:	eb67a783          	lw	a5,-330(a5) # 80012218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00012717          	auipc	a4,0x12
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80012180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00012497          	auipc	s1,0x12
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80012180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00012717          	auipc	a4,0x12
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80012180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00012717          	auipc	a4,0x12
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80012220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00012797          	auipc	a5,0x12
    80000402:	d8278793          	addi	a5,a5,-638 # 80012180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00012797          	auipc	a5,0x12
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001221c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00012517          	auipc	a0,0x12
    8000042e:	dee50513          	addi	a0,a0,-530 # 80012218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	606080e7          	jalr	1542(ra) # 80002a38 <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00009597          	auipc	a1,0x9
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80009010 <etext+0x10>
    8000044c:	00012517          	auipc	a0,0x12
    80000450:	d3450513          	addi	a0,a0,-716 # 80012180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6fe080e7          	jalr	1790(ra) # 80000b52 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00050797          	auipc	a5,0x50
    80000468:	90c78793          	addi	a5,a5,-1780 # 8004fd70 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00009617          	auipc	a2,0x9
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80009040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00012797          	auipc	a5,0x12
    8000053a:	d007a523          	sw	zero,-758(a5) # 80012240 <pr+0x18>
  printf("panic: ");
    8000053e:	00009517          	auipc	a0,0x9
    80000542:	ada50513          	addi	a0,a0,-1318 # 80009018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00009517          	auipc	a0,0x9
    8000055c:	bb850513          	addi	a0,a0,-1096 # 80009110 <digits+0xd0>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	0000a717          	auipc	a4,0xa
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 8000a000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00012d97          	auipc	s11,0x12
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80012240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00009b17          	auipc	s6,0x9
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80009040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00012517          	auipc	a0,0x12
    800005e8:	c4450513          	addi	a0,a0,-956 # 80012228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	646080e7          	jalr	1606(ra) # 80000c32 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00009517          	auipc	a0,0x9
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80009028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00009497          	auipc	s1,0x9
    800006f4:	93048493          	addi	s1,s1,-1744 # 80009020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00012517          	auipc	a0,0x12
    80000746:	ae650513          	addi	a0,a0,-1306 # 80012228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	59c080e7          	jalr	1436(ra) # 80000ce6 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00012497          	auipc	s1,0x12
    80000762:	aca48493          	addi	s1,s1,-1334 # 80012228 <pr>
    80000766:	00009597          	auipc	a1,0x9
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80009038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3e2080e7          	jalr	994(ra) # 80000b52 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00009597          	auipc	a1,0x9
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80009058 <digits+0x18>
    800007be:	00012517          	auipc	a0,0x12
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80012248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	38c080e7          	jalr	908(ra) # 80000b52 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	3fc080e7          	jalr	1020(ra) # 80000bde <push_off>

  if(panicked){
    800007ea:	0000a797          	auipc	a5,0xa
    800007ee:	8167a783          	lw	a5,-2026(a5) # 8000a000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	470080e7          	jalr	1136(ra) # 80000c80 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00009797          	auipc	a5,0x9
    80000826:	7e67b783          	ld	a5,2022(a5) # 8000a008 <uart_tx_r>
    8000082a:	00009717          	auipc	a4,0x9
    8000082e:	7e673703          	ld	a4,2022(a4) # 8000a010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00012a17          	auipc	s4,0x12
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80012248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00009497          	auipc	s1,0x9
    80000858:	7b448493          	addi	s1,s1,1972 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00009997          	auipc	s3,0x9
    80000860:	7b498993          	addi	s3,s3,1972 # 8000a010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	1ba080e7          	jalr	442(ra) # 80002a38 <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00012517          	auipc	a0,0x12
    800008be:	98e50513          	addi	a0,a0,-1650 # 80012248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	370080e7          	jalr	880(ra) # 80000c32 <acquire>
  if(panicked){
    800008ca:	00009797          	auipc	a5,0x9
    800008ce:	7367a783          	lw	a5,1846(a5) # 8000a000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00009717          	auipc	a4,0x9
    800008da:	73a73703          	ld	a4,1850(a4) # 8000a010 <uart_tx_w>
    800008de:	00009797          	auipc	a5,0x9
    800008e2:	72a7b783          	ld	a5,1834(a5) # 8000a008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00012997          	auipc	s3,0x12
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80012248 <uart_tx_lock>
    800008f6:	00009497          	auipc	s1,0x9
    800008fa:	71248493          	addi	s1,s1,1810 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00009917          	auipc	s2,0x9
    80000902:	71290913          	addi	s2,s2,1810 # 8000a010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	f98080e7          	jalr	-104(ra) # 800028a2 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00012497          	auipc	s1,0x12
    80000924:	92848493          	addi	s1,s1,-1752 # 80012248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00009797          	auipc	a5,0x9
    80000938:	6ce7be23          	sd	a4,1756(a5) # 8000a010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	3a0080e7          	jalr	928(ra) # 80000ce6 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00012497          	auipc	s1,0x12
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80012248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	280080e7          	jalr	640(ra) # 80000c32 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	322080e7          	jalr	802(ra) # 80000ce6 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    panic("kfree1");

  if((char*)pa < end )
    800009ea:	00053797          	auipc	a5,0x53
    800009ee:	61678793          	addi	a5,a5,1558 # 80054000 <end>
    800009f2:	04f56d63          	bltu	a0,a5,80000a4c <kfree+0x76>
    panic("kfree2");

  if((uint64)pa >= PHYSTOP)
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	06f57163          	bgeu	a0,a5,80000a5c <kfree+0x86>
    panic("kfree3");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	348080e7          	jalr	840(ra) # 80000d4a <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00012917          	auipc	s2,0x12
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80012280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	21e080e7          	jalr	542(ra) # 80000c32 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	2be080e7          	jalr	702(ra) # 80000ce6 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree1");
    80000a3c:	00008517          	auipc	a0,0x8
    80000a40:	62450513          	addi	a0,a0,1572 # 80009060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>
    panic("kfree2");
    80000a4c:	00008517          	auipc	a0,0x8
    80000a50:	61c50513          	addi	a0,a0,1564 # 80009068 <digits+0x28>
    80000a54:	00000097          	auipc	ra,0x0
    80000a58:	ad6080e7          	jalr	-1322(ra) # 8000052a <panic>
    panic("kfree3");
    80000a5c:	00008517          	auipc	a0,0x8
    80000a60:	61450513          	addi	a0,a0,1556 # 80009070 <digits+0x30>
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	ac6080e7          	jalr	-1338(ra) # 8000052a <panic>

0000000080000a6c <freerange>:
{
    80000a6c:	7179                	addi	sp,sp,-48
    80000a6e:	f406                	sd	ra,40(sp)
    80000a70:	f022                	sd	s0,32(sp)
    80000a72:	ec26                	sd	s1,24(sp)
    80000a74:	e84a                	sd	s2,16(sp)
    80000a76:	e44e                	sd	s3,8(sp)
    80000a78:	e052                	sd	s4,0(sp)
    80000a7a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7c:	6785                	lui	a5,0x1
    80000a7e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a82:	94aa                	add	s1,s1,a0
    80000a84:	757d                	lui	a0,0xfffff
    80000a86:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a88:	94be                	add	s1,s1,a5
    80000a8a:	0095ee63          	bltu	a1,s1,80000aa6 <freerange+0x3a>
    80000a8e:	892e                	mv	s2,a1
    kfree(p);
    80000a90:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a92:	6985                	lui	s3,0x1
    kfree(p);
    80000a94:	01448533          	add	a0,s1,s4
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	f3e080e7          	jalr	-194(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa0:	94ce                	add	s1,s1,s3
    80000aa2:	fe9979e3          	bgeu	s2,s1,80000a94 <freerange+0x28>
}
    80000aa6:	70a2                	ld	ra,40(sp)
    80000aa8:	7402                	ld	s0,32(sp)
    80000aaa:	64e2                	ld	s1,24(sp)
    80000aac:	6942                	ld	s2,16(sp)
    80000aae:	69a2                	ld	s3,8(sp)
    80000ab0:	6a02                	ld	s4,0(sp)
    80000ab2:	6145                	addi	sp,sp,48
    80000ab4:	8082                	ret

0000000080000ab6 <kinit>:
{
    80000ab6:	1141                	addi	sp,sp,-16
    80000ab8:	e406                	sd	ra,8(sp)
    80000aba:	e022                	sd	s0,0(sp)
    80000abc:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000abe:	00008597          	auipc	a1,0x8
    80000ac2:	5ba58593          	addi	a1,a1,1466 # 80009078 <digits+0x38>
    80000ac6:	00011517          	auipc	a0,0x11
    80000aca:	7ba50513          	addi	a0,a0,1978 # 80012280 <kmem>
    80000ace:	00000097          	auipc	ra,0x0
    80000ad2:	084080e7          	jalr	132(ra) # 80000b52 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad6:	45c5                	li	a1,17
    80000ad8:	05ee                	slli	a1,a1,0x1b
    80000ada:	00053517          	auipc	a0,0x53
    80000ade:	52650513          	addi	a0,a0,1318 # 80054000 <end>
    80000ae2:	00000097          	auipc	ra,0x0
    80000ae6:	f8a080e7          	jalr	-118(ra) # 80000a6c <freerange>
}
    80000aea:	60a2                	ld	ra,8(sp)
    80000aec:	6402                	ld	s0,0(sp)
    80000aee:	0141                	addi	sp,sp,16
    80000af0:	8082                	ret

0000000080000af2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af2:	1101                	addi	sp,sp,-32
    80000af4:	ec06                	sd	ra,24(sp)
    80000af6:	e822                	sd	s0,16(sp)
    80000af8:	e426                	sd	s1,8(sp)
    80000afa:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afc:	00011497          	auipc	s1,0x11
    80000b00:	78448493          	addi	s1,s1,1924 # 80012280 <kmem>
    80000b04:	8526                	mv	a0,s1
    80000b06:	00000097          	auipc	ra,0x0
    80000b0a:	12c080e7          	jalr	300(ra) # 80000c32 <acquire>
  r = kmem.freelist;
    80000b0e:	6c84                	ld	s1,24(s1)
  if(r)
    80000b10:	c885                	beqz	s1,80000b40 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b12:	609c                	ld	a5,0(s1)
    80000b14:	00011517          	auipc	a0,0x11
    80000b18:	76c50513          	addi	a0,a0,1900 # 80012280 <kmem>
    80000b1c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b1e:	00000097          	auipc	ra,0x0
    80000b22:	1c8080e7          	jalr	456(ra) # 80000ce6 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b26:	6605                	lui	a2,0x1
    80000b28:	4595                	li	a1,5
    80000b2a:	8526                	mv	a0,s1
    80000b2c:	00000097          	auipc	ra,0x0
    80000b30:	21e080e7          	jalr	542(ra) # 80000d4a <memset>
  return (void*)r;
}
    80000b34:	8526                	mv	a0,s1
    80000b36:	60e2                	ld	ra,24(sp)
    80000b38:	6442                	ld	s0,16(sp)
    80000b3a:	64a2                	ld	s1,8(sp)
    80000b3c:	6105                	addi	sp,sp,32
    80000b3e:	8082                	ret
  release(&kmem.lock);
    80000b40:	00011517          	auipc	a0,0x11
    80000b44:	74050513          	addi	a0,a0,1856 # 80012280 <kmem>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	19e080e7          	jalr	414(ra) # 80000ce6 <release>
  if(r)
    80000b50:	b7d5                	j	80000b34 <kalloc+0x42>

0000000080000b52 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b52:	1141                	addi	sp,sp,-16
    80000b54:	e422                	sd	s0,8(sp)
    80000b56:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b58:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b5e:	00053823          	sd	zero,16(a0)
}
    80000b62:	6422                	ld	s0,8(sp)
    80000b64:	0141                	addi	sp,sp,16
    80000b66:	8082                	ret

0000000080000b68 <myAcquirePanic>:

void myAcquirePanic(struct spinlock *lk)
{
    80000b68:	1101                	addi	sp,sp,-32
    80000b6a:	ec06                	sd	ra,24(sp)
    80000b6c:	e822                	sd	s0,16(sp)
    80000b6e:	e426                	sd	s1,8(sp)
    80000b70:	e04a                	sd	s2,0(sp)
    80000b72:	1000                	addi	s0,sp,32
    80000b74:	84aa                	mv	s1,a0
    printf("pid: %d, tid: %d, lock: %s\n",myproc()->pid,mythread()->tid,lk->name);
    80000b76:	00001097          	auipc	ra,0x1
    80000b7a:	fd0080e7          	jalr	-48(ra) # 80001b46 <myproc>
    80000b7e:	02452903          	lw	s2,36(a0)
    80000b82:	00001097          	auipc	ra,0x1
    80000b86:	f3a080e7          	jalr	-198(ra) # 80001abc <mythread>
    80000b8a:	6494                	ld	a3,8(s1)
    80000b8c:	4110                	lw	a2,0(a0)
    80000b8e:	85ca                	mv	a1,s2
    80000b90:	00008517          	auipc	a0,0x8
    80000b94:	4f050513          	addi	a0,a0,1264 # 80009080 <digits+0x40>
    80000b98:	00000097          	auipc	ra,0x0
    80000b9c:	9dc080e7          	jalr	-1572(ra) # 80000574 <printf>
    panic("acquire");
    80000ba0:	00008517          	auipc	a0,0x8
    80000ba4:	50050513          	addi	a0,a0,1280 # 800090a0 <digits+0x60>
    80000ba8:	00000097          	auipc	ra,0x0
    80000bac:	982080e7          	jalr	-1662(ra) # 8000052a <panic>

0000000080000bb0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bb0:	411c                	lw	a5,0(a0)
    80000bb2:	e399                	bnez	a5,80000bb8 <holding+0x8>
    80000bb4:	4501                	li	a0,0
  return r;
}
    80000bb6:	8082                	ret
{
    80000bb8:	1101                	addi	sp,sp,-32
    80000bba:	ec06                	sd	ra,24(sp)
    80000bbc:	e822                	sd	s0,16(sp)
    80000bbe:	e426                	sd	s1,8(sp)
    80000bc0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bc2:	6904                	ld	s1,16(a0)
    80000bc4:	00001097          	auipc	ra,0x1
    80000bc8:	ed4080e7          	jalr	-300(ra) # 80001a98 <mycpu>
    80000bcc:	40a48533          	sub	a0,s1,a0
    80000bd0:	00153513          	seqz	a0,a0
}
    80000bd4:	60e2                	ld	ra,24(sp)
    80000bd6:	6442                	ld	s0,16(sp)
    80000bd8:	64a2                	ld	s1,8(sp)
    80000bda:	6105                	addi	sp,sp,32
    80000bdc:	8082                	ret

0000000080000bde <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bde:	1101                	addi	sp,sp,-32
    80000be0:	ec06                	sd	ra,24(sp)
    80000be2:	e822                	sd	s0,16(sp)
    80000be4:	e426                	sd	s1,8(sp)
    80000be6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000be8:	100024f3          	csrr	s1,sstatus
    80000bec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bf0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bf2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bf6:	00001097          	auipc	ra,0x1
    80000bfa:	ea2080e7          	jalr	-350(ra) # 80001a98 <mycpu>
    80000bfe:	08052783          	lw	a5,128(a0)
    80000c02:	cf99                	beqz	a5,80000c20 <push_off+0x42>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c04:	00001097          	auipc	ra,0x1
    80000c08:	e94080e7          	jalr	-364(ra) # 80001a98 <mycpu>
    80000c0c:	08052783          	lw	a5,128(a0)
    80000c10:	2785                	addiw	a5,a5,1
    80000c12:	08f52023          	sw	a5,128(a0)
}
    80000c16:	60e2                	ld	ra,24(sp)
    80000c18:	6442                	ld	s0,16(sp)
    80000c1a:	64a2                	ld	s1,8(sp)
    80000c1c:	6105                	addi	sp,sp,32
    80000c1e:	8082                	ret
    mycpu()->intena = old;
    80000c20:	00001097          	auipc	ra,0x1
    80000c24:	e78080e7          	jalr	-392(ra) # 80001a98 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c28:	8085                	srli	s1,s1,0x1
    80000c2a:	8885                	andi	s1,s1,1
    80000c2c:	08952223          	sw	s1,132(a0)
    80000c30:	bfd1                	j	80000c04 <push_off+0x26>

0000000080000c32 <acquire>:
{
    80000c32:	1101                	addi	sp,sp,-32
    80000c34:	ec06                	sd	ra,24(sp)
    80000c36:	e822                	sd	s0,16(sp)
    80000c38:	e426                	sd	s1,8(sp)
    80000c3a:	1000                	addi	s0,sp,32
    80000c3c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	fa0080e7          	jalr	-96(ra) # 80000bde <push_off>
  if(holding(lk))
    80000c46:	8526                	mv	a0,s1
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	f68080e7          	jalr	-152(ra) # 80000bb0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c50:	4705                	li	a4,1
  if(holding(lk))
    80000c52:	e115                	bnez	a0,80000c76 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c54:	87ba                	mv	a5,a4
    80000c56:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c5a:	2781                	sext.w	a5,a5
    80000c5c:	ffe5                	bnez	a5,80000c54 <acquire+0x22>
  __sync_synchronize();
    80000c5e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c62:	00001097          	auipc	ra,0x1
    80000c66:	e36080e7          	jalr	-458(ra) # 80001a98 <mycpu>
    80000c6a:	e888                	sd	a0,16(s1)
}
    80000c6c:	60e2                	ld	ra,24(sp)
    80000c6e:	6442                	ld	s0,16(sp)
    80000c70:	64a2                	ld	s1,8(sp)
    80000c72:	6105                	addi	sp,sp,32
    80000c74:	8082                	ret
    myAcquirePanic(lk);
    80000c76:	8526                	mv	a0,s1
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	ef0080e7          	jalr	-272(ra) # 80000b68 <myAcquirePanic>

0000000080000c80 <pop_off>:

void
pop_off(void)
{
    80000c80:	1141                	addi	sp,sp,-16
    80000c82:	e406                	sd	ra,8(sp)
    80000c84:	e022                	sd	s0,0(sp)
    80000c86:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c88:	00001097          	auipc	ra,0x1
    80000c8c:	e10080e7          	jalr	-496(ra) # 80001a98 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c94:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c96:	eb85                	bnez	a5,80000cc6 <pop_off+0x46>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c98:	08052783          	lw	a5,128(a0)
    80000c9c:	02f05d63          	blez	a5,80000cd6 <pop_off+0x56>
    panic("pop_off");
  c->noff -= 1;
    80000ca0:	37fd                	addiw	a5,a5,-1
    80000ca2:	0007871b          	sext.w	a4,a5
    80000ca6:	08f52023          	sw	a5,128(a0)
  if(c->noff == 0 && c->intena)
    80000caa:	eb11                	bnez	a4,80000cbe <pop_off+0x3e>
    80000cac:	08452783          	lw	a5,132(a0)
    80000cb0:	c799                	beqz	a5,80000cbe <pop_off+0x3e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cb6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cba:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cbe:	60a2                	ld	ra,8(sp)
    80000cc0:	6402                	ld	s0,0(sp)
    80000cc2:	0141                	addi	sp,sp,16
    80000cc4:	8082                	ret
    panic("pop_off - interruptible");
    80000cc6:	00008517          	auipc	a0,0x8
    80000cca:	3e250513          	addi	a0,a0,994 # 800090a8 <digits+0x68>
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	85c080e7          	jalr	-1956(ra) # 8000052a <panic>
    panic("pop_off");
    80000cd6:	00008517          	auipc	a0,0x8
    80000cda:	3ea50513          	addi	a0,a0,1002 # 800090c0 <digits+0x80>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	84c080e7          	jalr	-1972(ra) # 8000052a <panic>

0000000080000ce6 <release>:
{
    80000ce6:	1101                	addi	sp,sp,-32
    80000ce8:	ec06                	sd	ra,24(sp)
    80000cea:	e822                	sd	s0,16(sp)
    80000cec:	e426                	sd	s1,8(sp)
    80000cee:	1000                	addi	s0,sp,32
    80000cf0:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	ebe080e7          	jalr	-322(ra) # 80000bb0 <holding>
    80000cfa:	c115                	beqz	a0,80000d1e <release+0x38>
  lk->cpu = 0;
    80000cfc:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d00:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d04:	0f50000f          	fence	iorw,ow
    80000d08:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d0c:	00000097          	auipc	ra,0x0
    80000d10:	f74080e7          	jalr	-140(ra) # 80000c80 <pop_off>
}
    80000d14:	60e2                	ld	ra,24(sp)
    80000d16:	6442                	ld	s0,16(sp)
    80000d18:	64a2                	ld	s1,8(sp)
    80000d1a:	6105                	addi	sp,sp,32
    80000d1c:	8082                	ret
    printf("pid: %d, lock: %s\n",myproc()->pid,lk->name);
    80000d1e:	00001097          	auipc	ra,0x1
    80000d22:	e28080e7          	jalr	-472(ra) # 80001b46 <myproc>
    80000d26:	6490                	ld	a2,8(s1)
    80000d28:	514c                	lw	a1,36(a0)
    80000d2a:	00008517          	auipc	a0,0x8
    80000d2e:	39e50513          	addi	a0,a0,926 # 800090c8 <digits+0x88>
    80000d32:	00000097          	auipc	ra,0x0
    80000d36:	842080e7          	jalr	-1982(ra) # 80000574 <printf>
    panic("release");
    80000d3a:	00008517          	auipc	a0,0x8
    80000d3e:	3a650513          	addi	a0,a0,934 # 800090e0 <digits+0xa0>
    80000d42:	fffff097          	auipc	ra,0xfffff
    80000d46:	7e8080e7          	jalr	2024(ra) # 8000052a <panic>

0000000080000d4a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d4a:	1141                	addi	sp,sp,-16
    80000d4c:	e422                	sd	s0,8(sp)
    80000d4e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d50:	ca19                	beqz	a2,80000d66 <memset+0x1c>
    80000d52:	87aa                	mv	a5,a0
    80000d54:	1602                	slli	a2,a2,0x20
    80000d56:	9201                	srli	a2,a2,0x20
    80000d58:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d5c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d60:	0785                	addi	a5,a5,1
    80000d62:	fee79de3          	bne	a5,a4,80000d5c <memset+0x12>
  }
  return dst;
}
    80000d66:	6422                	ld	s0,8(sp)
    80000d68:	0141                	addi	sp,sp,16
    80000d6a:	8082                	ret

0000000080000d6c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d72:	ca05                	beqz	a2,80000da2 <memcmp+0x36>
    80000d74:	fff6069b          	addiw	a3,a2,-1
    80000d78:	1682                	slli	a3,a3,0x20
    80000d7a:	9281                	srli	a3,a3,0x20
    80000d7c:	0685                	addi	a3,a3,1
    80000d7e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d80:	00054783          	lbu	a5,0(a0)
    80000d84:	0005c703          	lbu	a4,0(a1)
    80000d88:	00e79863          	bne	a5,a4,80000d98 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d8c:	0505                	addi	a0,a0,1
    80000d8e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d90:	fed518e3          	bne	a0,a3,80000d80 <memcmp+0x14>
  }

  return 0;
    80000d94:	4501                	li	a0,0
    80000d96:	a019                	j	80000d9c <memcmp+0x30>
      return *s1 - *s2;
    80000d98:	40e7853b          	subw	a0,a5,a4
}
    80000d9c:	6422                	ld	s0,8(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret
  return 0;
    80000da2:	4501                	li	a0,0
    80000da4:	bfe5                	j	80000d9c <memcmp+0x30>

0000000080000da6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e422                	sd	s0,8(sp)
    80000daa:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dac:	02a5e563          	bltu	a1,a0,80000dd6 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000db0:	fff6069b          	addiw	a3,a2,-1
    80000db4:	ce11                	beqz	a2,80000dd0 <memmove+0x2a>
    80000db6:	1682                	slli	a3,a3,0x20
    80000db8:	9281                	srli	a3,a3,0x20
    80000dba:	0685                	addi	a3,a3,1
    80000dbc:	96ae                	add	a3,a3,a1
    80000dbe:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dc0:	0585                	addi	a1,a1,1
    80000dc2:	0785                	addi	a5,a5,1
    80000dc4:	fff5c703          	lbu	a4,-1(a1)
    80000dc8:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dcc:	fed59ae3          	bne	a1,a3,80000dc0 <memmove+0x1a>

  return dst;
}
    80000dd0:	6422                	ld	s0,8(sp)
    80000dd2:	0141                	addi	sp,sp,16
    80000dd4:	8082                	ret
  if(s < d && s + n > d){
    80000dd6:	02061713          	slli	a4,a2,0x20
    80000dda:	9301                	srli	a4,a4,0x20
    80000ddc:	00e587b3          	add	a5,a1,a4
    80000de0:	fcf578e3          	bgeu	a0,a5,80000db0 <memmove+0xa>
    d += n;
    80000de4:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000de6:	fff6069b          	addiw	a3,a2,-1
    80000dea:	d27d                	beqz	a2,80000dd0 <memmove+0x2a>
    80000dec:	02069613          	slli	a2,a3,0x20
    80000df0:	9201                	srli	a2,a2,0x20
    80000df2:	fff64613          	not	a2,a2
    80000df6:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000df8:	17fd                	addi	a5,a5,-1
    80000dfa:	177d                	addi	a4,a4,-1
    80000dfc:	0007c683          	lbu	a3,0(a5)
    80000e00:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e04:	fef61ae3          	bne	a2,a5,80000df8 <memmove+0x52>
    80000e08:	b7e1                	j	80000dd0 <memmove+0x2a>

0000000080000e0a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e0a:	1141                	addi	sp,sp,-16
    80000e0c:	e406                	sd	ra,8(sp)
    80000e0e:	e022                	sd	s0,0(sp)
    80000e10:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e12:	00000097          	auipc	ra,0x0
    80000e16:	f94080e7          	jalr	-108(ra) # 80000da6 <memmove>
}
    80000e1a:	60a2                	ld	ra,8(sp)
    80000e1c:	6402                	ld	s0,0(sp)
    80000e1e:	0141                	addi	sp,sp,16
    80000e20:	8082                	ret

0000000080000e22 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e22:	1141                	addi	sp,sp,-16
    80000e24:	e422                	sd	s0,8(sp)
    80000e26:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e28:	ce11                	beqz	a2,80000e44 <strncmp+0x22>
    80000e2a:	00054783          	lbu	a5,0(a0)
    80000e2e:	cf89                	beqz	a5,80000e48 <strncmp+0x26>
    80000e30:	0005c703          	lbu	a4,0(a1)
    80000e34:	00f71a63          	bne	a4,a5,80000e48 <strncmp+0x26>
    n--, p++, q++;
    80000e38:	367d                	addiw	a2,a2,-1
    80000e3a:	0505                	addi	a0,a0,1
    80000e3c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e3e:	f675                	bnez	a2,80000e2a <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e40:	4501                	li	a0,0
    80000e42:	a809                	j	80000e54 <strncmp+0x32>
    80000e44:	4501                	li	a0,0
    80000e46:	a039                	j	80000e54 <strncmp+0x32>
  if(n == 0)
    80000e48:	ca09                	beqz	a2,80000e5a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e4a:	00054503          	lbu	a0,0(a0)
    80000e4e:	0005c783          	lbu	a5,0(a1)
    80000e52:	9d1d                	subw	a0,a0,a5
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret
    return 0;
    80000e5a:	4501                	li	a0,0
    80000e5c:	bfe5                	j	80000e54 <strncmp+0x32>

0000000080000e5e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e5e:	1141                	addi	sp,sp,-16
    80000e60:	e422                	sd	s0,8(sp)
    80000e62:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e64:	872a                	mv	a4,a0
    80000e66:	8832                	mv	a6,a2
    80000e68:	367d                	addiw	a2,a2,-1
    80000e6a:	01005963          	blez	a6,80000e7c <strncpy+0x1e>
    80000e6e:	0705                	addi	a4,a4,1
    80000e70:	0005c783          	lbu	a5,0(a1)
    80000e74:	fef70fa3          	sb	a5,-1(a4)
    80000e78:	0585                	addi	a1,a1,1
    80000e7a:	f7f5                	bnez	a5,80000e66 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e7c:	86ba                	mv	a3,a4
    80000e7e:	00c05c63          	blez	a2,80000e96 <strncpy+0x38>
    *s++ = 0;
    80000e82:	0685                	addi	a3,a3,1
    80000e84:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e88:	fff6c793          	not	a5,a3
    80000e8c:	9fb9                	addw	a5,a5,a4
    80000e8e:	010787bb          	addw	a5,a5,a6
    80000e92:	fef048e3          	bgtz	a5,80000e82 <strncpy+0x24>
  return os;
}
    80000e96:	6422                	ld	s0,8(sp)
    80000e98:	0141                	addi	sp,sp,16
    80000e9a:	8082                	ret

0000000080000e9c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e9c:	1141                	addi	sp,sp,-16
    80000e9e:	e422                	sd	s0,8(sp)
    80000ea0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ea2:	02c05363          	blez	a2,80000ec8 <safestrcpy+0x2c>
    80000ea6:	fff6069b          	addiw	a3,a2,-1
    80000eaa:	1682                	slli	a3,a3,0x20
    80000eac:	9281                	srli	a3,a3,0x20
    80000eae:	96ae                	add	a3,a3,a1
    80000eb0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000eb2:	00d58963          	beq	a1,a3,80000ec4 <safestrcpy+0x28>
    80000eb6:	0585                	addi	a1,a1,1
    80000eb8:	0785                	addi	a5,a5,1
    80000eba:	fff5c703          	lbu	a4,-1(a1)
    80000ebe:	fee78fa3          	sb	a4,-1(a5)
    80000ec2:	fb65                	bnez	a4,80000eb2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ec4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	addi	sp,sp,16
    80000ecc:	8082                	ret

0000000080000ece <strlen>:

int
strlen(const char *s)
{
    80000ece:	1141                	addi	sp,sp,-16
    80000ed0:	e422                	sd	s0,8(sp)
    80000ed2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ed4:	00054783          	lbu	a5,0(a0)
    80000ed8:	cf91                	beqz	a5,80000ef4 <strlen+0x26>
    80000eda:	0505                	addi	a0,a0,1
    80000edc:	87aa                	mv	a5,a0
    80000ede:	4685                	li	a3,1
    80000ee0:	9e89                	subw	a3,a3,a0
    80000ee2:	00f6853b          	addw	a0,a3,a5
    80000ee6:	0785                	addi	a5,a5,1
    80000ee8:	fff7c703          	lbu	a4,-1(a5)
    80000eec:	fb7d                	bnez	a4,80000ee2 <strlen+0x14>
    ;
  return n;
}
    80000eee:	6422                	ld	s0,8(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ef4:	4501                	li	a0,0
    80000ef6:	bfe5                	j	80000eee <strlen+0x20>

0000000080000ef8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ef8:	1141                	addi	sp,sp,-16
    80000efa:	e406                	sd	ra,8(sp)
    80000efc:	e022                	sd	s0,0(sp)
    80000efe:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f00:	00001097          	auipc	ra,0x1
    80000f04:	b88080e7          	jalr	-1144(ra) # 80001a88 <cpuid>
    userinit();      // first user process
    
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f08:	00009717          	auipc	a4,0x9
    80000f0c:	11070713          	addi	a4,a4,272 # 8000a018 <started>
  if(cpuid() == 0){
    80000f10:	c139                	beqz	a0,80000f56 <main+0x5e>
    while(started == 0)
    80000f12:	431c                	lw	a5,0(a4)
    80000f14:	2781                	sext.w	a5,a5
    80000f16:	dff5                	beqz	a5,80000f12 <main+0x1a>
      ;
    __sync_synchronize();
    80000f18:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f1c:	00001097          	auipc	ra,0x1
    80000f20:	b6c080e7          	jalr	-1172(ra) # 80001a88 <cpuid>
    80000f24:	85aa                	mv	a1,a0
    80000f26:	00008517          	auipc	a0,0x8
    80000f2a:	1da50513          	addi	a0,a0,474 # 80009100 <digits+0xc0>
    80000f2e:	fffff097          	auipc	ra,0xfffff
    80000f32:	646080e7          	jalr	1606(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000f36:	00000097          	auipc	ra,0x0
    80000f3a:	0d8080e7          	jalr	216(ra) # 8000100e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f3e:	00003097          	auipc	ra,0x3
    80000f42:	92c080e7          	jalr	-1748(ra) # 8000386a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f46:	00006097          	auipc	ra,0x6
    80000f4a:	19a080e7          	jalr	410(ra) # 800070e0 <plicinithart>
  }
  //printf("After user init\n");
  scheduler();        
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	62e080e7          	jalr	1582(ra) # 8000257c <scheduler>
    consoleinit();
    80000f56:	fffff097          	auipc	ra,0xfffff
    80000f5a:	4e6080e7          	jalr	1254(ra) # 8000043c <consoleinit>
    printfinit();
    80000f5e:	fffff097          	auipc	ra,0xfffff
    80000f62:	7f6080e7          	jalr	2038(ra) # 80000754 <printfinit>
    printf("\n");
    80000f66:	00008517          	auipc	a0,0x8
    80000f6a:	1aa50513          	addi	a0,a0,426 # 80009110 <digits+0xd0>
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	606080e7          	jalr	1542(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000f76:	00008517          	auipc	a0,0x8
    80000f7a:	17250513          	addi	a0,a0,370 # 800090e8 <digits+0xa8>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	5f6080e7          	jalr	1526(ra) # 80000574 <printf>
    printf("\n");
    80000f86:	00008517          	auipc	a0,0x8
    80000f8a:	18a50513          	addi	a0,a0,394 # 80009110 <digits+0xd0>
    80000f8e:	fffff097          	auipc	ra,0xfffff
    80000f92:	5e6080e7          	jalr	1510(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	b20080e7          	jalr	-1248(ra) # 80000ab6 <kinit>
    kvminit();       // create kernel page table
    80000f9e:	00000097          	auipc	ra,0x0
    80000fa2:	310080e7          	jalr	784(ra) # 800012ae <kvminit>
    kvminithart();   // turn on paging
    80000fa6:	00000097          	auipc	ra,0x0
    80000faa:	068080e7          	jalr	104(ra) # 8000100e <kvminithart>
    procinit();      // process table
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	9a8080e7          	jalr	-1624(ra) # 80001956 <procinit>
    trapinit();      // trap vectors
    80000fb6:	00003097          	auipc	ra,0x3
    80000fba:	88c080e7          	jalr	-1908(ra) # 80003842 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fbe:	00003097          	auipc	ra,0x3
    80000fc2:	8ac080e7          	jalr	-1876(ra) # 8000386a <trapinithart>
    plicinit();      // set up interrupt controller
    80000fc6:	00006097          	auipc	ra,0x6
    80000fca:	104080e7          	jalr	260(ra) # 800070ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fce:	00006097          	auipc	ra,0x6
    80000fd2:	112080e7          	jalr	274(ra) # 800070e0 <plicinithart>
    binit();         // buffer cache
    80000fd6:	00003097          	auipc	ra,0x3
    80000fda:	290080e7          	jalr	656(ra) # 80004266 <binit>
    iinit();         // inode cache
    80000fde:	00004097          	auipc	ra,0x4
    80000fe2:	922080e7          	jalr	-1758(ra) # 80004900 <iinit>
    fileinit();      // file table
    80000fe6:	00005097          	auipc	ra,0x5
    80000fea:	8ce080e7          	jalr	-1842(ra) # 800058b4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fee:	00006097          	auipc	ra,0x6
    80000ff2:	214080e7          	jalr	532(ra) # 80007202 <virtio_disk_init>
    userinit();      // first user process
    80000ff6:	00001097          	auipc	ra,0x1
    80000ffa:	fae080e7          	jalr	-82(ra) # 80001fa4 <userinit>
    __sync_synchronize();
    80000ffe:	0ff0000f          	fence
    started = 1;
    80001002:	4785                	li	a5,1
    80001004:	00009717          	auipc	a4,0x9
    80001008:	00f72a23          	sw	a5,20(a4) # 8000a018 <started>
    8000100c:	b789                	j	80000f4e <main+0x56>

000000008000100e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000100e:	1141                	addi	sp,sp,-16
    80001010:	e422                	sd	s0,8(sp)
    80001012:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001014:	00009797          	auipc	a5,0x9
    80001018:	00c7b783          	ld	a5,12(a5) # 8000a020 <kernel_pagetable>
    8000101c:	83b1                	srli	a5,a5,0xc
    8000101e:	577d                	li	a4,-1
    80001020:	177e                	slli	a4,a4,0x3f
    80001022:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001024:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001028:	12000073          	sfence.vma
  sfence_vma();
}
    8000102c:	6422                	ld	s0,8(sp)
    8000102e:	0141                	addi	sp,sp,16
    80001030:	8082                	ret

0000000080001032 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001032:	7139                	addi	sp,sp,-64
    80001034:	fc06                	sd	ra,56(sp)
    80001036:	f822                	sd	s0,48(sp)
    80001038:	f426                	sd	s1,40(sp)
    8000103a:	f04a                	sd	s2,32(sp)
    8000103c:	ec4e                	sd	s3,24(sp)
    8000103e:	e852                	sd	s4,16(sp)
    80001040:	e456                	sd	s5,8(sp)
    80001042:	e05a                	sd	s6,0(sp)
    80001044:	0080                	addi	s0,sp,64
    80001046:	84aa                	mv	s1,a0
    80001048:	89ae                	mv	s3,a1
    8000104a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001052:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001054:	04b7f263          	bgeu	a5,a1,80001098 <walk+0x66>
    panic("walk");
    80001058:	00008517          	auipc	a0,0x8
    8000105c:	0c050513          	addi	a0,a0,192 # 80009118 <digits+0xd8>
    80001060:	fffff097          	auipc	ra,0xfffff
    80001064:	4ca080e7          	jalr	1226(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001068:	060a8663          	beqz	s5,800010d4 <walk+0xa2>
    8000106c:	00000097          	auipc	ra,0x0
    80001070:	a86080e7          	jalr	-1402(ra) # 80000af2 <kalloc>
    80001074:	84aa                	mv	s1,a0
    80001076:	c529                	beqz	a0,800010c0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001078:	6605                	lui	a2,0x1
    8000107a:	4581                	li	a1,0
    8000107c:	00000097          	auipc	ra,0x0
    80001080:	cce080e7          	jalr	-818(ra) # 80000d4a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001084:	00c4d793          	srli	a5,s1,0xc
    80001088:	07aa                	slli	a5,a5,0xa
    8000108a:	0017e793          	ori	a5,a5,1
    8000108e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001092:	3a5d                	addiw	s4,s4,-9
    80001094:	036a0063          	beq	s4,s6,800010b4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001098:	0149d933          	srl	s2,s3,s4
    8000109c:	1ff97913          	andi	s2,s2,511
    800010a0:	090e                	slli	s2,s2,0x3
    800010a2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a4:	00093483          	ld	s1,0(s2)
    800010a8:	0014f793          	andi	a5,s1,1
    800010ac:	dfd5                	beqz	a5,80001068 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010ae:	80a9                	srli	s1,s1,0xa
    800010b0:	04b2                	slli	s1,s1,0xc
    800010b2:	b7c5                	j	80001092 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b4:	00c9d513          	srli	a0,s3,0xc
    800010b8:	1ff57513          	andi	a0,a0,511
    800010bc:	050e                	slli	a0,a0,0x3
    800010be:	9526                	add	a0,a0,s1
}
    800010c0:	70e2                	ld	ra,56(sp)
    800010c2:	7442                	ld	s0,48(sp)
    800010c4:	74a2                	ld	s1,40(sp)
    800010c6:	7902                	ld	s2,32(sp)
    800010c8:	69e2                	ld	s3,24(sp)
    800010ca:	6a42                	ld	s4,16(sp)
    800010cc:	6aa2                	ld	s5,8(sp)
    800010ce:	6b02                	ld	s6,0(sp)
    800010d0:	6121                	addi	sp,sp,64
    800010d2:	8082                	ret
        return 0;
    800010d4:	4501                	li	a0,0
    800010d6:	b7ed                	j	800010c0 <walk+0x8e>

00000000800010d8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d8:	57fd                	li	a5,-1
    800010da:	83e9                	srli	a5,a5,0x1a
    800010dc:	00b7f463          	bgeu	a5,a1,800010e4 <walkaddr+0xc>
    return 0;
    800010e0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010e2:	8082                	ret
{
    800010e4:	1141                	addi	sp,sp,-16
    800010e6:	e406                	sd	ra,8(sp)
    800010e8:	e022                	sd	s0,0(sp)
    800010ea:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ec:	4601                	li	a2,0
    800010ee:	00000097          	auipc	ra,0x0
    800010f2:	f44080e7          	jalr	-188(ra) # 80001032 <walk>
  if(pte == 0)
    800010f6:	c105                	beqz	a0,80001116 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010fa:	0117f693          	andi	a3,a5,17
    800010fe:	4745                	li	a4,17
    return 0;
    80001100:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001102:	00e68663          	beq	a3,a4,8000110e <walkaddr+0x36>
}
    80001106:	60a2                	ld	ra,8(sp)
    80001108:	6402                	ld	s0,0(sp)
    8000110a:	0141                	addi	sp,sp,16
    8000110c:	8082                	ret
  pa = PTE2PA(*pte);
    8000110e:	00a7d513          	srli	a0,a5,0xa
    80001112:	0532                	slli	a0,a0,0xc
  return pa;
    80001114:	bfcd                	j	80001106 <walkaddr+0x2e>
    return 0;
    80001116:	4501                	li	a0,0
    80001118:	b7fd                	j	80001106 <walkaddr+0x2e>

000000008000111a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000111a:	715d                	addi	sp,sp,-80
    8000111c:	e486                	sd	ra,72(sp)
    8000111e:	e0a2                	sd	s0,64(sp)
    80001120:	fc26                	sd	s1,56(sp)
    80001122:	f84a                	sd	s2,48(sp)
    80001124:	f44e                	sd	s3,40(sp)
    80001126:	f052                	sd	s4,32(sp)
    80001128:	ec56                	sd	s5,24(sp)
    8000112a:	e85a                	sd	s6,16(sp)
    8000112c:	e45e                	sd	s7,8(sp)
    8000112e:	0880                	addi	s0,sp,80
    80001130:	8aaa                	mv	s5,a0
    80001132:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001134:	777d                	lui	a4,0xfffff
    80001136:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000113a:	167d                	addi	a2,a2,-1
    8000113c:	00b609b3          	add	s3,a2,a1
    80001140:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001144:	893e                	mv	s2,a5
    80001146:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000114a:	6b85                	lui	s7,0x1
    8000114c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001150:	4605                	li	a2,1
    80001152:	85ca                	mv	a1,s2
    80001154:	8556                	mv	a0,s5
    80001156:	00000097          	auipc	ra,0x0
    8000115a:	edc080e7          	jalr	-292(ra) # 80001032 <walk>
    8000115e:	c51d                	beqz	a0,8000118c <mappages+0x72>
    if(*pte & PTE_V)
    80001160:	611c                	ld	a5,0(a0)
    80001162:	8b85                	andi	a5,a5,1
    80001164:	ef81                	bnez	a5,8000117c <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001166:	80b1                	srli	s1,s1,0xc
    80001168:	04aa                	slli	s1,s1,0xa
    8000116a:	0164e4b3          	or	s1,s1,s6
    8000116e:	0014e493          	ori	s1,s1,1
    80001172:	e104                	sd	s1,0(a0)
    if(a == last)
    80001174:	03390863          	beq	s2,s3,800011a4 <mappages+0x8a>
    a += PGSIZE;
    80001178:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000117a:	bfc9                	j	8000114c <mappages+0x32>
      panic("remap");
    8000117c:	00008517          	auipc	a0,0x8
    80001180:	fa450513          	addi	a0,a0,-92 # 80009120 <digits+0xe0>
    80001184:	fffff097          	auipc	ra,0xfffff
    80001188:	3a6080e7          	jalr	934(ra) # 8000052a <panic>
      return -1;
    8000118c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000118e:	60a6                	ld	ra,72(sp)
    80001190:	6406                	ld	s0,64(sp)
    80001192:	74e2                	ld	s1,56(sp)
    80001194:	7942                	ld	s2,48(sp)
    80001196:	79a2                	ld	s3,40(sp)
    80001198:	7a02                	ld	s4,32(sp)
    8000119a:	6ae2                	ld	s5,24(sp)
    8000119c:	6b42                	ld	s6,16(sp)
    8000119e:	6ba2                	ld	s7,8(sp)
    800011a0:	6161                	addi	sp,sp,80
    800011a2:	8082                	ret
  return 0;
    800011a4:	4501                	li	a0,0
    800011a6:	b7e5                	j	8000118e <mappages+0x74>

00000000800011a8 <kvmmap>:
{
    800011a8:	1141                	addi	sp,sp,-16
    800011aa:	e406                	sd	ra,8(sp)
    800011ac:	e022                	sd	s0,0(sp)
    800011ae:	0800                	addi	s0,sp,16
    800011b0:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011b2:	86b2                	mv	a3,a2
    800011b4:	863e                	mv	a2,a5
    800011b6:	00000097          	auipc	ra,0x0
    800011ba:	f64080e7          	jalr	-156(ra) # 8000111a <mappages>
    800011be:	e509                	bnez	a0,800011c8 <kvmmap+0x20>
}
    800011c0:	60a2                	ld	ra,8(sp)
    800011c2:	6402                	ld	s0,0(sp)
    800011c4:	0141                	addi	sp,sp,16
    800011c6:	8082                	ret
    panic("kvmmap");
    800011c8:	00008517          	auipc	a0,0x8
    800011cc:	f6050513          	addi	a0,a0,-160 # 80009128 <digits+0xe8>
    800011d0:	fffff097          	auipc	ra,0xfffff
    800011d4:	35a080e7          	jalr	858(ra) # 8000052a <panic>

00000000800011d8 <kvmmake>:
{
    800011d8:	1101                	addi	sp,sp,-32
    800011da:	ec06                	sd	ra,24(sp)
    800011dc:	e822                	sd	s0,16(sp)
    800011de:	e426                	sd	s1,8(sp)
    800011e0:	e04a                	sd	s2,0(sp)
    800011e2:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	90e080e7          	jalr	-1778(ra) # 80000af2 <kalloc>
    800011ec:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011ee:	6605                	lui	a2,0x1
    800011f0:	4581                	li	a1,0
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	b58080e7          	jalr	-1192(ra) # 80000d4a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011fa:	4719                	li	a4,6
    800011fc:	6685                	lui	a3,0x1
    800011fe:	10000637          	lui	a2,0x10000
    80001202:	100005b7          	lui	a1,0x10000
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	fa0080e7          	jalr	-96(ra) # 800011a8 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	6685                	lui	a3,0x1
    80001214:	10001637          	lui	a2,0x10001
    80001218:	100015b7          	lui	a1,0x10001
    8000121c:	8526                	mv	a0,s1
    8000121e:	00000097          	auipc	ra,0x0
    80001222:	f8a080e7          	jalr	-118(ra) # 800011a8 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001226:	4719                	li	a4,6
    80001228:	004006b7          	lui	a3,0x400
    8000122c:	0c000637          	lui	a2,0xc000
    80001230:	0c0005b7          	lui	a1,0xc000
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f72080e7          	jalr	-142(ra) # 800011a8 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000123e:	00008917          	auipc	s2,0x8
    80001242:	dc290913          	addi	s2,s2,-574 # 80009000 <etext>
    80001246:	4729                	li	a4,10
    80001248:	80008697          	auipc	a3,0x80008
    8000124c:	db868693          	addi	a3,a3,-584 # 9000 <_entry-0x7fff7000>
    80001250:	4605                	li	a2,1
    80001252:	067e                	slli	a2,a2,0x1f
    80001254:	85b2                	mv	a1,a2
    80001256:	8526                	mv	a0,s1
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	f50080e7          	jalr	-176(ra) # 800011a8 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001260:	4719                	li	a4,6
    80001262:	46c5                	li	a3,17
    80001264:	06ee                	slli	a3,a3,0x1b
    80001266:	412686b3          	sub	a3,a3,s2
    8000126a:	864a                	mv	a2,s2
    8000126c:	85ca                	mv	a1,s2
    8000126e:	8526                	mv	a0,s1
    80001270:	00000097          	auipc	ra,0x0
    80001274:	f38080e7          	jalr	-200(ra) # 800011a8 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001278:	4729                	li	a4,10
    8000127a:	6685                	lui	a3,0x1
    8000127c:	00007617          	auipc	a2,0x7
    80001280:	d8460613          	addi	a2,a2,-636 # 80008000 <_trampoline>
    80001284:	040005b7          	lui	a1,0x4000
    80001288:	15fd                	addi	a1,a1,-1
    8000128a:	05b2                	slli	a1,a1,0xc
    8000128c:	8526                	mv	a0,s1
    8000128e:	00000097          	auipc	ra,0x0
    80001292:	f1a080e7          	jalr	-230(ra) # 800011a8 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001296:	8526                	mv	a0,s1
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	600080e7          	jalr	1536(ra) # 80001898 <proc_mapstacks>
}
    800012a0:	8526                	mv	a0,s1
    800012a2:	60e2                	ld	ra,24(sp)
    800012a4:	6442                	ld	s0,16(sp)
    800012a6:	64a2                	ld	s1,8(sp)
    800012a8:	6902                	ld	s2,0(sp)
    800012aa:	6105                	addi	sp,sp,32
    800012ac:	8082                	ret

00000000800012ae <kvminit>:
{
    800012ae:	1141                	addi	sp,sp,-16
    800012b0:	e406                	sd	ra,8(sp)
    800012b2:	e022                	sd	s0,0(sp)
    800012b4:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f22080e7          	jalr	-222(ra) # 800011d8 <kvmmake>
    800012be:	00009797          	auipc	a5,0x9
    800012c2:	d6a7b123          	sd	a0,-670(a5) # 8000a020 <kernel_pagetable>
}
    800012c6:	60a2                	ld	ra,8(sp)
    800012c8:	6402                	ld	s0,0(sp)
    800012ca:	0141                	addi	sp,sp,16
    800012cc:	8082                	ret

00000000800012ce <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ce:	715d                	addi	sp,sp,-80
    800012d0:	e486                	sd	ra,72(sp)
    800012d2:	e0a2                	sd	s0,64(sp)
    800012d4:	fc26                	sd	s1,56(sp)
    800012d6:	f84a                	sd	s2,48(sp)
    800012d8:	f44e                	sd	s3,40(sp)
    800012da:	f052                	sd	s4,32(sp)
    800012dc:	ec56                	sd	s5,24(sp)
    800012de:	e85a                	sd	s6,16(sp)
    800012e0:	e45e                	sd	s7,8(sp)
    800012e2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012e4:	03459793          	slli	a5,a1,0x34
    800012e8:	e795                	bnez	a5,80001314 <uvmunmap+0x46>
    800012ea:	8a2a                	mv	s4,a0
    800012ec:	892e                	mv	s2,a1
    800012ee:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f0:	0632                	slli	a2,a2,0xc
    800012f2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f8:	6b05                	lui	s6,0x1
    800012fa:	0735e263          	bltu	a1,s3,8000135e <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012fe:	60a6                	ld	ra,72(sp)
    80001300:	6406                	ld	s0,64(sp)
    80001302:	74e2                	ld	s1,56(sp)
    80001304:	7942                	ld	s2,48(sp)
    80001306:	79a2                	ld	s3,40(sp)
    80001308:	7a02                	ld	s4,32(sp)
    8000130a:	6ae2                	ld	s5,24(sp)
    8000130c:	6b42                	ld	s6,16(sp)
    8000130e:	6ba2                	ld	s7,8(sp)
    80001310:	6161                	addi	sp,sp,80
    80001312:	8082                	ret
    panic("uvmunmap: not aligned");
    80001314:	00008517          	auipc	a0,0x8
    80001318:	e1c50513          	addi	a0,a0,-484 # 80009130 <digits+0xf0>
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	20e080e7          	jalr	526(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001324:	00008517          	auipc	a0,0x8
    80001328:	e2450513          	addi	a0,a0,-476 # 80009148 <digits+0x108>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	1fe080e7          	jalr	510(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    80001334:	00008517          	auipc	a0,0x8
    80001338:	e2450513          	addi	a0,a0,-476 # 80009158 <digits+0x118>
    8000133c:	fffff097          	auipc	ra,0xfffff
    80001340:	1ee080e7          	jalr	494(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    80001344:	00008517          	auipc	a0,0x8
    80001348:	e2c50513          	addi	a0,a0,-468 # 80009170 <digits+0x130>
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	1de080e7          	jalr	478(ra) # 8000052a <panic>
    *pte = 0;
    80001354:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001358:	995a                	add	s2,s2,s6
    8000135a:	fb3972e3          	bgeu	s2,s3,800012fe <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000135e:	4601                	li	a2,0
    80001360:	85ca                	mv	a1,s2
    80001362:	8552                	mv	a0,s4
    80001364:	00000097          	auipc	ra,0x0
    80001368:	cce080e7          	jalr	-818(ra) # 80001032 <walk>
    8000136c:	84aa                	mv	s1,a0
    8000136e:	d95d                	beqz	a0,80001324 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001370:	6108                	ld	a0,0(a0)
    80001372:	00157793          	andi	a5,a0,1
    80001376:	dfdd                	beqz	a5,80001334 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001378:	3ff57793          	andi	a5,a0,1023
    8000137c:	fd7784e3          	beq	a5,s7,80001344 <uvmunmap+0x76>
    if(do_free){
    80001380:	fc0a8ae3          	beqz	s5,80001354 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001384:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001386:	0532                	slli	a0,a0,0xc
    80001388:	fffff097          	auipc	ra,0xfffff
    8000138c:	64e080e7          	jalr	1614(ra) # 800009d6 <kfree>
    80001390:	b7d1                	j	80001354 <uvmunmap+0x86>

0000000080001392 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001392:	1101                	addi	sp,sp,-32
    80001394:	ec06                	sd	ra,24(sp)
    80001396:	e822                	sd	s0,16(sp)
    80001398:	e426                	sd	s1,8(sp)
    8000139a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000139c:	fffff097          	auipc	ra,0xfffff
    800013a0:	756080e7          	jalr	1878(ra) # 80000af2 <kalloc>
    800013a4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013a6:	c519                	beqz	a0,800013b4 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	99e080e7          	jalr	-1634(ra) # 80000d4a <memset>
  return pagetable;
}
    800013b4:	8526                	mv	a0,s1
    800013b6:	60e2                	ld	ra,24(sp)
    800013b8:	6442                	ld	s0,16(sp)
    800013ba:	64a2                	ld	s1,8(sp)
    800013bc:	6105                	addi	sp,sp,32
    800013be:	8082                	ret

00000000800013c0 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c0:	7179                	addi	sp,sp,-48
    800013c2:	f406                	sd	ra,40(sp)
    800013c4:	f022                	sd	s0,32(sp)
    800013c6:	ec26                	sd	s1,24(sp)
    800013c8:	e84a                	sd	s2,16(sp)
    800013ca:	e44e                	sd	s3,8(sp)
    800013cc:	e052                	sd	s4,0(sp)
    800013ce:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d0:	6785                	lui	a5,0x1
    800013d2:	04f67863          	bgeu	a2,a5,80001422 <uvminit+0x62>
    800013d6:	8a2a                	mv	s4,a0
    800013d8:	89ae                	mv	s3,a1
    800013da:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	716080e7          	jalr	1814(ra) # 80000af2 <kalloc>
    800013e4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013e6:	6605                	lui	a2,0x1
    800013e8:	4581                	li	a1,0
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	960080e7          	jalr	-1696(ra) # 80000d4a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013f2:	4779                	li	a4,30
    800013f4:	86ca                	mv	a3,s2
    800013f6:	6605                	lui	a2,0x1
    800013f8:	4581                	li	a1,0
    800013fa:	8552                	mv	a0,s4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	d1e080e7          	jalr	-738(ra) # 8000111a <mappages>
  memmove(mem, src, sz);
    80001404:	8626                	mv	a2,s1
    80001406:	85ce                	mv	a1,s3
    80001408:	854a                	mv	a0,s2
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	99c080e7          	jalr	-1636(ra) # 80000da6 <memmove>
}
    80001412:	70a2                	ld	ra,40(sp)
    80001414:	7402                	ld	s0,32(sp)
    80001416:	64e2                	ld	s1,24(sp)
    80001418:	6942                	ld	s2,16(sp)
    8000141a:	69a2                	ld	s3,8(sp)
    8000141c:	6a02                	ld	s4,0(sp)
    8000141e:	6145                	addi	sp,sp,48
    80001420:	8082                	ret
    panic("inituvm: more than a page");
    80001422:	00008517          	auipc	a0,0x8
    80001426:	d6650513          	addi	a0,a0,-666 # 80009188 <digits+0x148>
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	100080e7          	jalr	256(ra) # 8000052a <panic>

0000000080001432 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001432:	1101                	addi	sp,sp,-32
    80001434:	ec06                	sd	ra,24(sp)
    80001436:	e822                	sd	s0,16(sp)
    80001438:	e426                	sd	s1,8(sp)
    8000143a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000143c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000143e:	00b67d63          	bgeu	a2,a1,80001458 <uvmdealloc+0x26>
    80001442:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001444:	6785                	lui	a5,0x1
    80001446:	17fd                	addi	a5,a5,-1
    80001448:	00f60733          	add	a4,a2,a5
    8000144c:	767d                	lui	a2,0xfffff
    8000144e:	8f71                	and	a4,a4,a2
    80001450:	97ae                	add	a5,a5,a1
    80001452:	8ff1                	and	a5,a5,a2
    80001454:	00f76863          	bltu	a4,a5,80001464 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001458:	8526                	mv	a0,s1
    8000145a:	60e2                	ld	ra,24(sp)
    8000145c:	6442                	ld	s0,16(sp)
    8000145e:	64a2                	ld	s1,8(sp)
    80001460:	6105                	addi	sp,sp,32
    80001462:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001464:	8f99                	sub	a5,a5,a4
    80001466:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001468:	4685                	li	a3,1
    8000146a:	0007861b          	sext.w	a2,a5
    8000146e:	85ba                	mv	a1,a4
    80001470:	00000097          	auipc	ra,0x0
    80001474:	e5e080e7          	jalr	-418(ra) # 800012ce <uvmunmap>
    80001478:	b7c5                	j	80001458 <uvmdealloc+0x26>

000000008000147a <uvmalloc>:
  if(newsz < oldsz)
    8000147a:	0ab66163          	bltu	a2,a1,8000151c <uvmalloc+0xa2>
{
    8000147e:	7139                	addi	sp,sp,-64
    80001480:	fc06                	sd	ra,56(sp)
    80001482:	f822                	sd	s0,48(sp)
    80001484:	f426                	sd	s1,40(sp)
    80001486:	f04a                	sd	s2,32(sp)
    80001488:	ec4e                	sd	s3,24(sp)
    8000148a:	e852                	sd	s4,16(sp)
    8000148c:	e456                	sd	s5,8(sp)
    8000148e:	0080                	addi	s0,sp,64
    80001490:	8aaa                	mv	s5,a0
    80001492:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001494:	6985                	lui	s3,0x1
    80001496:	19fd                	addi	s3,s3,-1
    80001498:	95ce                	add	a1,a1,s3
    8000149a:	79fd                	lui	s3,0xfffff
    8000149c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a0:	08c9f063          	bgeu	s3,a2,80001520 <uvmalloc+0xa6>
    800014a4:	894e                	mv	s2,s3
    mem = kalloc();
    800014a6:	fffff097          	auipc	ra,0xfffff
    800014aa:	64c080e7          	jalr	1612(ra) # 80000af2 <kalloc>
    800014ae:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b0:	c51d                	beqz	a0,800014de <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014b2:	6605                	lui	a2,0x1
    800014b4:	4581                	li	a1,0
    800014b6:	00000097          	auipc	ra,0x0
    800014ba:	894080e7          	jalr	-1900(ra) # 80000d4a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014be:	4779                	li	a4,30
    800014c0:	86a6                	mv	a3,s1
    800014c2:	6605                	lui	a2,0x1
    800014c4:	85ca                	mv	a1,s2
    800014c6:	8556                	mv	a0,s5
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	c52080e7          	jalr	-942(ra) # 8000111a <mappages>
    800014d0:	e905                	bnez	a0,80001500 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014d2:	6785                	lui	a5,0x1
    800014d4:	993e                	add	s2,s2,a5
    800014d6:	fd4968e3          	bltu	s2,s4,800014a6 <uvmalloc+0x2c>
  return newsz;
    800014da:	8552                	mv	a0,s4
    800014dc:	a809                	j	800014ee <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014de:	864e                	mv	a2,s3
    800014e0:	85ca                	mv	a1,s2
    800014e2:	8556                	mv	a0,s5
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	f4e080e7          	jalr	-178(ra) # 80001432 <uvmdealloc>
      return 0;
    800014ec:	4501                	li	a0,0
}
    800014ee:	70e2                	ld	ra,56(sp)
    800014f0:	7442                	ld	s0,48(sp)
    800014f2:	74a2                	ld	s1,40(sp)
    800014f4:	7902                	ld	s2,32(sp)
    800014f6:	69e2                	ld	s3,24(sp)
    800014f8:	6a42                	ld	s4,16(sp)
    800014fa:	6aa2                	ld	s5,8(sp)
    800014fc:	6121                	addi	sp,sp,64
    800014fe:	8082                	ret
      kfree(mem);
    80001500:	8526                	mv	a0,s1
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	4d4080e7          	jalr	1236(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000150a:	864e                	mv	a2,s3
    8000150c:	85ca                	mv	a1,s2
    8000150e:	8556                	mv	a0,s5
    80001510:	00000097          	auipc	ra,0x0
    80001514:	f22080e7          	jalr	-222(ra) # 80001432 <uvmdealloc>
      return 0;
    80001518:	4501                	li	a0,0
    8000151a:	bfd1                	j	800014ee <uvmalloc+0x74>
    return oldsz;
    8000151c:	852e                	mv	a0,a1
}
    8000151e:	8082                	ret
  return newsz;
    80001520:	8532                	mv	a0,a2
    80001522:	b7f1                	j	800014ee <uvmalloc+0x74>

0000000080001524 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001524:	7179                	addi	sp,sp,-48
    80001526:	f406                	sd	ra,40(sp)
    80001528:	f022                	sd	s0,32(sp)
    8000152a:	ec26                	sd	s1,24(sp)
    8000152c:	e84a                	sd	s2,16(sp)
    8000152e:	e44e                	sd	s3,8(sp)
    80001530:	e052                	sd	s4,0(sp)
    80001532:	1800                	addi	s0,sp,48
    80001534:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001536:	84aa                	mv	s1,a0
    80001538:	6905                	lui	s2,0x1
    8000153a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000153c:	4985                	li	s3,1
    8000153e:	a821                	j	80001556 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001540:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001542:	0532                	slli	a0,a0,0xc
    80001544:	00000097          	auipc	ra,0x0
    80001548:	fe0080e7          	jalr	-32(ra) # 80001524 <freewalk>
      pagetable[i] = 0;
    8000154c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001550:	04a1                	addi	s1,s1,8
    80001552:	03248163          	beq	s1,s2,80001574 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001556:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001558:	00f57793          	andi	a5,a0,15
    8000155c:	ff3782e3          	beq	a5,s3,80001540 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001560:	8905                	andi	a0,a0,1
    80001562:	d57d                	beqz	a0,80001550 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001564:	00008517          	auipc	a0,0x8
    80001568:	c4450513          	addi	a0,a0,-956 # 800091a8 <digits+0x168>
    8000156c:	fffff097          	auipc	ra,0xfffff
    80001570:	fbe080e7          	jalr	-66(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    80001574:	8552                	mv	a0,s4
    80001576:	fffff097          	auipc	ra,0xfffff
    8000157a:	460080e7          	jalr	1120(ra) # 800009d6 <kfree>
}
    8000157e:	70a2                	ld	ra,40(sp)
    80001580:	7402                	ld	s0,32(sp)
    80001582:	64e2                	ld	s1,24(sp)
    80001584:	6942                	ld	s2,16(sp)
    80001586:	69a2                	ld	s3,8(sp)
    80001588:	6a02                	ld	s4,0(sp)
    8000158a:	6145                	addi	sp,sp,48
    8000158c:	8082                	ret

000000008000158e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000158e:	1101                	addi	sp,sp,-32
    80001590:	ec06                	sd	ra,24(sp)
    80001592:	e822                	sd	s0,16(sp)
    80001594:	e426                	sd	s1,8(sp)
    80001596:	1000                	addi	s0,sp,32
    80001598:	84aa                	mv	s1,a0
  if(sz > 0)
    8000159a:	e999                	bnez	a1,800015b0 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000159c:	8526                	mv	a0,s1
    8000159e:	00000097          	auipc	ra,0x0
    800015a2:	f86080e7          	jalr	-122(ra) # 80001524 <freewalk>
}
    800015a6:	60e2                	ld	ra,24(sp)
    800015a8:	6442                	ld	s0,16(sp)
    800015aa:	64a2                	ld	s1,8(sp)
    800015ac:	6105                	addi	sp,sp,32
    800015ae:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015b0:	6605                	lui	a2,0x1
    800015b2:	167d                	addi	a2,a2,-1
    800015b4:	962e                	add	a2,a2,a1
    800015b6:	4685                	li	a3,1
    800015b8:	8231                	srli	a2,a2,0xc
    800015ba:	4581                	li	a1,0
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	d12080e7          	jalr	-750(ra) # 800012ce <uvmunmap>
    800015c4:	bfe1                	j	8000159c <uvmfree+0xe>

00000000800015c6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	c679                	beqz	a2,80001694 <uvmcopy+0xce>
{
    800015c8:	715d                	addi	sp,sp,-80
    800015ca:	e486                	sd	ra,72(sp)
    800015cc:	e0a2                	sd	s0,64(sp)
    800015ce:	fc26                	sd	s1,56(sp)
    800015d0:	f84a                	sd	s2,48(sp)
    800015d2:	f44e                	sd	s3,40(sp)
    800015d4:	f052                	sd	s4,32(sp)
    800015d6:	ec56                	sd	s5,24(sp)
    800015d8:	e85a                	sd	s6,16(sp)
    800015da:	e45e                	sd	s7,8(sp)
    800015dc:	0880                	addi	s0,sp,80
    800015de:	8b2a                	mv	s6,a0
    800015e0:	8aae                	mv	s5,a1
    800015e2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015e4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015e6:	4601                	li	a2,0
    800015e8:	85ce                	mv	a1,s3
    800015ea:	855a                	mv	a0,s6
    800015ec:	00000097          	auipc	ra,0x0
    800015f0:	a46080e7          	jalr	-1466(ra) # 80001032 <walk>
    800015f4:	c531                	beqz	a0,80001640 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015f6:	6118                	ld	a4,0(a0)
    800015f8:	00177793          	andi	a5,a4,1
    800015fc:	cbb1                	beqz	a5,80001650 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015fe:	00a75593          	srli	a1,a4,0xa
    80001602:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001606:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	4e8080e7          	jalr	1256(ra) # 80000af2 <kalloc>
    80001612:	892a                	mv	s2,a0
    80001614:	c939                	beqz	a0,8000166a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001616:	6605                	lui	a2,0x1
    80001618:	85de                	mv	a1,s7
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	78c080e7          	jalr	1932(ra) # 80000da6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001622:	8726                	mv	a4,s1
    80001624:	86ca                	mv	a3,s2
    80001626:	6605                	lui	a2,0x1
    80001628:	85ce                	mv	a1,s3
    8000162a:	8556                	mv	a0,s5
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	aee080e7          	jalr	-1298(ra) # 8000111a <mappages>
    80001634:	e515                	bnez	a0,80001660 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001636:	6785                	lui	a5,0x1
    80001638:	99be                	add	s3,s3,a5
    8000163a:	fb49e6e3          	bltu	s3,s4,800015e6 <uvmcopy+0x20>
    8000163e:	a081                	j	8000167e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001640:	00008517          	auipc	a0,0x8
    80001644:	b7850513          	addi	a0,a0,-1160 # 800091b8 <digits+0x178>
    80001648:	fffff097          	auipc	ra,0xfffff
    8000164c:	ee2080e7          	jalr	-286(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    80001650:	00008517          	auipc	a0,0x8
    80001654:	b8850513          	addi	a0,a0,-1144 # 800091d8 <digits+0x198>
    80001658:	fffff097          	auipc	ra,0xfffff
    8000165c:	ed2080e7          	jalr	-302(ra) # 8000052a <panic>
      kfree(mem);
    80001660:	854a                	mv	a0,s2
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	374080e7          	jalr	884(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000166a:	4685                	li	a3,1
    8000166c:	00c9d613          	srli	a2,s3,0xc
    80001670:	4581                	li	a1,0
    80001672:	8556                	mv	a0,s5
    80001674:	00000097          	auipc	ra,0x0
    80001678:	c5a080e7          	jalr	-934(ra) # 800012ce <uvmunmap>
  return -1;
    8000167c:	557d                	li	a0,-1
}
    8000167e:	60a6                	ld	ra,72(sp)
    80001680:	6406                	ld	s0,64(sp)
    80001682:	74e2                	ld	s1,56(sp)
    80001684:	7942                	ld	s2,48(sp)
    80001686:	79a2                	ld	s3,40(sp)
    80001688:	7a02                	ld	s4,32(sp)
    8000168a:	6ae2                	ld	s5,24(sp)
    8000168c:	6b42                	ld	s6,16(sp)
    8000168e:	6ba2                	ld	s7,8(sp)
    80001690:	6161                	addi	sp,sp,80
    80001692:	8082                	ret
  return 0;
    80001694:	4501                	li	a0,0
}
    80001696:	8082                	ret

0000000080001698 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001698:	1141                	addi	sp,sp,-16
    8000169a:	e406                	sd	ra,8(sp)
    8000169c:	e022                	sd	s0,0(sp)
    8000169e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016a0:	4601                	li	a2,0
    800016a2:	00000097          	auipc	ra,0x0
    800016a6:	990080e7          	jalr	-1648(ra) # 80001032 <walk>
  if(pte == 0)
    800016aa:	c901                	beqz	a0,800016ba <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016ac:	611c                	ld	a5,0(a0)
    800016ae:	9bbd                	andi	a5,a5,-17
    800016b0:	e11c                	sd	a5,0(a0)
}
    800016b2:	60a2                	ld	ra,8(sp)
    800016b4:	6402                	ld	s0,0(sp)
    800016b6:	0141                	addi	sp,sp,16
    800016b8:	8082                	ret
    panic("uvmclear");
    800016ba:	00008517          	auipc	a0,0x8
    800016be:	b3e50513          	addi	a0,a0,-1218 # 800091f8 <digits+0x1b8>
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	e68080e7          	jalr	-408(ra) # 8000052a <panic>

00000000800016ca <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ca:	c6bd                	beqz	a3,80001738 <copyout+0x6e>
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	e062                	sd	s8,0(sp)
    800016e2:	0880                	addi	s0,sp,80
    800016e4:	8b2a                	mv	s6,a0
    800016e6:	8c2e                	mv	s8,a1
    800016e8:	8a32                	mv	s4,a2
    800016ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ee:	6a85                	lui	s5,0x1
    800016f0:	a015                	j	80001714 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016f2:	9562                	add	a0,a0,s8
    800016f4:	0004861b          	sext.w	a2,s1
    800016f8:	85d2                	mv	a1,s4
    800016fa:	41250533          	sub	a0,a0,s2
    800016fe:	fffff097          	auipc	ra,0xfffff
    80001702:	6a8080e7          	jalr	1704(ra) # 80000da6 <memmove>

    len -= n;
    80001706:	409989b3          	sub	s3,s3,s1
    src += n;
    8000170a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000170c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001710:	02098263          	beqz	s3,80001734 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001714:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001718:	85ca                	mv	a1,s2
    8000171a:	855a                	mv	a0,s6
    8000171c:	00000097          	auipc	ra,0x0
    80001720:	9bc080e7          	jalr	-1604(ra) # 800010d8 <walkaddr>
    if(pa0 == 0)
    80001724:	cd01                	beqz	a0,8000173c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001726:	418904b3          	sub	s1,s2,s8
    8000172a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172c:	fc99f3e3          	bgeu	s3,s1,800016f2 <copyout+0x28>
    80001730:	84ce                	mv	s1,s3
    80001732:	b7c1                	j	800016f2 <copyout+0x28>
  }
  return 0;
    80001734:	4501                	li	a0,0
    80001736:	a021                	j	8000173e <copyout+0x74>
    80001738:	4501                	li	a0,0
}
    8000173a:	8082                	ret
      return -1;
    8000173c:	557d                	li	a0,-1
}
    8000173e:	60a6                	ld	ra,72(sp)
    80001740:	6406                	ld	s0,64(sp)
    80001742:	74e2                	ld	s1,56(sp)
    80001744:	7942                	ld	s2,48(sp)
    80001746:	79a2                	ld	s3,40(sp)
    80001748:	7a02                	ld	s4,32(sp)
    8000174a:	6ae2                	ld	s5,24(sp)
    8000174c:	6b42                	ld	s6,16(sp)
    8000174e:	6ba2                	ld	s7,8(sp)
    80001750:	6c02                	ld	s8,0(sp)
    80001752:	6161                	addi	sp,sp,80
    80001754:	8082                	ret

0000000080001756 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001756:	caa5                	beqz	a3,800017c6 <copyin+0x70>
{
    80001758:	715d                	addi	sp,sp,-80
    8000175a:	e486                	sd	ra,72(sp)
    8000175c:	e0a2                	sd	s0,64(sp)
    8000175e:	fc26                	sd	s1,56(sp)
    80001760:	f84a                	sd	s2,48(sp)
    80001762:	f44e                	sd	s3,40(sp)
    80001764:	f052                	sd	s4,32(sp)
    80001766:	ec56                	sd	s5,24(sp)
    80001768:	e85a                	sd	s6,16(sp)
    8000176a:	e45e                	sd	s7,8(sp)
    8000176c:	e062                	sd	s8,0(sp)
    8000176e:	0880                	addi	s0,sp,80
    80001770:	8b2a                	mv	s6,a0
    80001772:	8a2e                	mv	s4,a1
    80001774:	8c32                	mv	s8,a2
    80001776:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001778:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177a:	6a85                	lui	s5,0x1
    8000177c:	a01d                	j	800017a2 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000177e:	018505b3          	add	a1,a0,s8
    80001782:	0004861b          	sext.w	a2,s1
    80001786:	412585b3          	sub	a1,a1,s2
    8000178a:	8552                	mv	a0,s4
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	61a080e7          	jalr	1562(ra) # 80000da6 <memmove>

    len -= n;
    80001794:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001798:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000179a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000179e:	02098263          	beqz	s3,800017c2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a6:	85ca                	mv	a1,s2
    800017a8:	855a                	mv	a0,s6
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	92e080e7          	jalr	-1746(ra) # 800010d8 <walkaddr>
    if(pa0 == 0)
    800017b2:	cd01                	beqz	a0,800017ca <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017b4:	418904b3          	sub	s1,s2,s8
    800017b8:	94d6                	add	s1,s1,s5
    if(n > len)
    800017ba:	fc99f2e3          	bgeu	s3,s1,8000177e <copyin+0x28>
    800017be:	84ce                	mv	s1,s3
    800017c0:	bf7d                	j	8000177e <copyin+0x28>
  }
  return 0;
    800017c2:	4501                	li	a0,0
    800017c4:	a021                	j	800017cc <copyin+0x76>
    800017c6:	4501                	li	a0,0
}
    800017c8:	8082                	ret
      return -1;
    800017ca:	557d                	li	a0,-1
}
    800017cc:	60a6                	ld	ra,72(sp)
    800017ce:	6406                	ld	s0,64(sp)
    800017d0:	74e2                	ld	s1,56(sp)
    800017d2:	7942                	ld	s2,48(sp)
    800017d4:	79a2                	ld	s3,40(sp)
    800017d6:	7a02                	ld	s4,32(sp)
    800017d8:	6ae2                	ld	s5,24(sp)
    800017da:	6b42                	ld	s6,16(sp)
    800017dc:	6ba2                	ld	s7,8(sp)
    800017de:	6c02                	ld	s8,0(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret

00000000800017e4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017e4:	c6c5                	beqz	a3,8000188c <copyinstr+0xa8>
{
    800017e6:	715d                	addi	sp,sp,-80
    800017e8:	e486                	sd	ra,72(sp)
    800017ea:	e0a2                	sd	s0,64(sp)
    800017ec:	fc26                	sd	s1,56(sp)
    800017ee:	f84a                	sd	s2,48(sp)
    800017f0:	f44e                	sd	s3,40(sp)
    800017f2:	f052                	sd	s4,32(sp)
    800017f4:	ec56                	sd	s5,24(sp)
    800017f6:	e85a                	sd	s6,16(sp)
    800017f8:	e45e                	sd	s7,8(sp)
    800017fa:	0880                	addi	s0,sp,80
    800017fc:	8a2a                	mv	s4,a0
    800017fe:	8b2e                	mv	s6,a1
    80001800:	8bb2                	mv	s7,a2
    80001802:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001804:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001806:	6985                	lui	s3,0x1
    80001808:	a035                	j	80001834 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000180a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000180e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001810:	0017b793          	seqz	a5,a5
    80001814:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001818:	60a6                	ld	ra,72(sp)
    8000181a:	6406                	ld	s0,64(sp)
    8000181c:	74e2                	ld	s1,56(sp)
    8000181e:	7942                	ld	s2,48(sp)
    80001820:	79a2                	ld	s3,40(sp)
    80001822:	7a02                	ld	s4,32(sp)
    80001824:	6ae2                	ld	s5,24(sp)
    80001826:	6b42                	ld	s6,16(sp)
    80001828:	6ba2                	ld	s7,8(sp)
    8000182a:	6161                	addi	sp,sp,80
    8000182c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000182e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001832:	c8a9                	beqz	s1,80001884 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001834:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001838:	85ca                	mv	a1,s2
    8000183a:	8552                	mv	a0,s4
    8000183c:	00000097          	auipc	ra,0x0
    80001840:	89c080e7          	jalr	-1892(ra) # 800010d8 <walkaddr>
    if(pa0 == 0)
    80001844:	c131                	beqz	a0,80001888 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001846:	41790833          	sub	a6,s2,s7
    8000184a:	984e                	add	a6,a6,s3
    if(n > max)
    8000184c:	0104f363          	bgeu	s1,a6,80001852 <copyinstr+0x6e>
    80001850:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001852:	955e                	add	a0,a0,s7
    80001854:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001858:	fc080be3          	beqz	a6,8000182e <copyinstr+0x4a>
    8000185c:	985a                	add	a6,a6,s6
    8000185e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001860:	41650633          	sub	a2,a0,s6
    80001864:	14fd                	addi	s1,s1,-1
    80001866:	9b26                	add	s6,s6,s1
    80001868:	00f60733          	add	a4,a2,a5
    8000186c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffab000>
    80001870:	df49                	beqz	a4,8000180a <copyinstr+0x26>
        *dst = *p;
    80001872:	00e78023          	sb	a4,0(a5)
      --max;
    80001876:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000187a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000187c:	ff0796e3          	bne	a5,a6,80001868 <copyinstr+0x84>
      dst++;
    80001880:	8b42                	mv	s6,a6
    80001882:	b775                	j	8000182e <copyinstr+0x4a>
    80001884:	4781                	li	a5,0
    80001886:	b769                	j	80001810 <copyinstr+0x2c>
      return -1;
    80001888:	557d                	li	a0,-1
    8000188a:	b779                	j	80001818 <copyinstr+0x34>
  int got_null = 0;
    8000188c:	4781                	li	a5,0
  if(got_null){
    8000188e:	0017b793          	seqz	a5,a5
    80001892:	40f00533          	neg	a0,a5
}
    80001896:	8082                	ret

0000000080001898 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001898:	715d                	addi	sp,sp,-80
    8000189a:	e486                	sd	ra,72(sp)
    8000189c:	e0a2                	sd	s0,64(sp)
    8000189e:	fc26                	sd	s1,56(sp)
    800018a0:	f84a                	sd	s2,48(sp)
    800018a2:	f44e                	sd	s3,40(sp)
    800018a4:	f052                	sd	s4,32(sp)
    800018a6:	ec56                	sd	s5,24(sp)
    800018a8:	e85a                	sd	s6,16(sp)
    800018aa:	e45e                	sd	s7,8(sp)
    800018ac:	e062                	sd	s8,0(sp)
    800018ae:	0880                	addi	s0,sp,80
    800018b0:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b2:	00012497          	auipc	s1,0x12
    800018b6:	e7648493          	addi	s1,s1,-394 # 80013728 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018ba:	8c26                	mv	s8,s1
    800018bc:	00007b97          	auipc	s7,0x7
    800018c0:	744b8b93          	addi	s7,s7,1860 # 80009000 <etext>
    800018c4:	04000937          	lui	s2,0x4000
    800018c8:	197d                	addi	s2,s2,-1
    800018ca:	0932                	slli	s2,s2,0xc
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018cc:	6a05                	lui	s4,0x1
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ce:	c90a0b13          	addi	s6,s4,-880 # c90 <_entry-0x7ffff370>
    800018d2:	00044a97          	auipc	s5,0x44
    800018d6:	256a8a93          	addi	s5,s5,598 # 80045b28 <tickslock>
    char *pa = kalloc();
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	218080e7          	jalr	536(ra) # 80000af2 <kalloc>
    800018e2:	862a                	mv	a2,a0
    if(pa == 0)
    800018e4:	c139                	beqz	a0,8000192a <proc_mapstacks+0x92>
    uint64 va = KSTACK((int) (p - proc));
    800018e6:	418485b3          	sub	a1,s1,s8
    800018ea:	8591                	srai	a1,a1,0x4
    800018ec:	000bb783          	ld	a5,0(s7)
    800018f0:	02f585b3          	mul	a1,a1,a5
    800018f4:	2585                	addiw	a1,a1,1
    800018f6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018fa:	4719                	li	a4,6
    800018fc:	86d2                	mv	a3,s4
    800018fe:	40b905b3          	sub	a1,s2,a1
    80001902:	854e                	mv	a0,s3
    80001904:	00000097          	auipc	ra,0x0
    80001908:	8a4080e7          	jalr	-1884(ra) # 800011a8 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190c:	94da                	add	s1,s1,s6
    8000190e:	fd5496e3          	bne	s1,s5,800018da <proc_mapstacks+0x42>
  }
}
    80001912:	60a6                	ld	ra,72(sp)
    80001914:	6406                	ld	s0,64(sp)
    80001916:	74e2                	ld	s1,56(sp)
    80001918:	7942                	ld	s2,48(sp)
    8000191a:	79a2                	ld	s3,40(sp)
    8000191c:	7a02                	ld	s4,32(sp)
    8000191e:	6ae2                	ld	s5,24(sp)
    80001920:	6b42                	ld	s6,16(sp)
    80001922:	6ba2                	ld	s7,8(sp)
    80001924:	6c02                	ld	s8,0(sp)
    80001926:	6161                	addi	sp,sp,80
    80001928:	8082                	ret
      panic("kalloc");
    8000192a:	00008517          	auipc	a0,0x8
    8000192e:	8de50513          	addi	a0,a0,-1826 # 80009208 <digits+0x1c8>
    80001932:	fffff097          	auipc	ra,0xfffff
    80001936:	bf8080e7          	jalr	-1032(ra) # 8000052a <panic>

000000008000193a <isStillRunning>:


int isStillRunning(struct thread *t)
{
    8000193a:	1141                	addi	sp,sp,-16
    8000193c:	e422                	sd	s0,8(sp)
    8000193e:	0800                	addi	s0,sp,16
  if(!t->killed && (t->state==USED || t->state==SLEEPING || t->state==RUNNABLE))
    80001940:	455c                	lw	a5,12(a0)
    80001942:	eb81                	bnez	a5,80001952 <isStillRunning+0x18>
    80001944:	4508                	lw	a0,8(a0)
    80001946:	357d                	addiw	a0,a0,-1
  {
    return 1;
    80001948:	00353513          	sltiu	a0,a0,3
  }
  return 0;
}
    8000194c:	6422                	ld	s0,8(sp)
    8000194e:	0141                	addi	sp,sp,16
    80001950:	8082                	ret
  return 0;
    80001952:	4501                	li	a0,0
    80001954:	bfe5                	j	8000194c <isStillRunning+0x12>

0000000080001956 <procinit>:


// initialize the proc table at boot time.
void
procinit(void)
{
    80001956:	7119                	addi	sp,sp,-128
    80001958:	fc86                	sd	ra,120(sp)
    8000195a:	f8a2                	sd	s0,112(sp)
    8000195c:	f4a6                	sd	s1,104(sp)
    8000195e:	f0ca                	sd	s2,96(sp)
    80001960:	ecce                	sd	s3,88(sp)
    80001962:	e8d2                	sd	s4,80(sp)
    80001964:	e4d6                	sd	s5,72(sp)
    80001966:	e0da                	sd	s6,64(sp)
    80001968:	fc5e                	sd	s7,56(sp)
    8000196a:	f862                	sd	s8,48(sp)
    8000196c:	f466                	sd	s9,40(sp)
    8000196e:	f06a                	sd	s10,32(sp)
    80001970:	ec6e                	sd	s11,24(sp)
    80001972:	0100                	addi	s0,sp,128
  struct proc *p;
  struct thread *t;
  
  initlock(&pid_lock, "nextpid");
    80001974:	00008597          	auipc	a1,0x8
    80001978:	89c58593          	addi	a1,a1,-1892 # 80009210 <digits+0x1d0>
    8000197c:	00011517          	auipc	a0,0x11
    80001980:	92450513          	addi	a0,a0,-1756 # 800122a0 <pid_lock>
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	1ce080e7          	jalr	462(ra) # 80000b52 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000198c:	00008597          	auipc	a1,0x8
    80001990:	88c58593          	addi	a1,a1,-1908 # 80009218 <digits+0x1d8>
    80001994:	00011517          	auipc	a0,0x11
    80001998:	92450513          	addi	a0,a0,-1756 # 800122b8 <wait_lock>
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	1b6080e7          	jalr	438(ra) # 80000b52 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a4:	00013917          	auipc	s2,0x13
    800019a8:	a8490913          	addi	s2,s2,-1404 # 80014428 <proc+0xd00>
    800019ac:	00012997          	auipc	s3,0x12
    800019b0:	d7c98993          	addi	s3,s3,-644 # 80013728 <proc>
    800019b4:	6a85                	lui	s5,0x1
    800019b6:	c58a8d93          	addi	s11,s5,-936 # c58 <_entry-0x7ffff3a8>
      initlock(&p->lock, "proc");
      for(t=p->threads;t<&p->threads[NTHREADS];t++)
      {
        initlock(&t->tlock,"tlock");
    800019ba:	00008a17          	auipc	s4,0x8
    800019be:	876a0a13          	addi	s4,s4,-1930 # 80009230 <digits+0x1f0>
      }
      initlock(&p->tid_lock, "proc->tid_lock");
      initlock(&p->join_lock,"proc->join_lock");
    800019c2:	c78a8d13          	addi	s10,s5,-904
      p->threads[0].kstack= KSTACK((int) (p - proc));
    800019c6:	8cce                	mv	s9,s3
    800019c8:	00007c17          	auipc	s8,0x7
    800019cc:	638c0c13          	addi	s8,s8,1592 # 80009000 <etext>
    800019d0:	040007b7          	lui	a5,0x4000
    800019d4:	17fd                	addi	a5,a5,-1
    800019d6:	07b2                	slli	a5,a5,0xc
    800019d8:	f8f43423          	sd	a5,-120(s0)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	c90a8a93          	addi	s5,s5,-880
    800019e0:	a8a1                	j	80001a38 <procinit+0xe2>
      initlock(&p->tid_lock, "proc->tid_lock");
    800019e2:	00008597          	auipc	a1,0x8
    800019e6:	85658593          	addi	a1,a1,-1962 # 80009238 <digits+0x1f8>
    800019ea:	855e                	mv	a0,s7
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	166080e7          	jalr	358(ra) # 80000b52 <initlock>
      initlock(&p->join_lock,"proc->join_lock");
    800019f4:	00008597          	auipc	a1,0x8
    800019f8:	85458593          	addi	a1,a1,-1964 # 80009248 <digits+0x208>
    800019fc:	01ab0533          	add	a0,s6,s10
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	152080e7          	jalr	338(ra) # 80000b52 <initlock>
      p->threads[0].kstack= KSTACK((int) (p - proc));
    80001a08:	419987b3          	sub	a5,s3,s9
    80001a0c:	8791                	srai	a5,a5,0x4
    80001a0e:	000c3703          	ld	a4,0(s8)
    80001a12:	02e787b3          	mul	a5,a5,a4
    80001a16:	2785                	addiw	a5,a5,1
    80001a18:	00d7979b          	slliw	a5,a5,0xd
    80001a1c:	f8843703          	ld	a4,-120(s0)
    80001a20:	40f707b3          	sub	a5,a4,a5
    80001a24:	5af9b823          	sd	a5,1456(s3)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a28:	99d6                	add	s3,s3,s5
    80001a2a:	9956                	add	s2,s2,s5
    80001a2c:	00044797          	auipc	a5,0x44
    80001a30:	0fc78793          	addi	a5,a5,252 # 80045b28 <tickslock>
    80001a34:	02f98b63          	beq	s3,a5,80001a6a <procinit+0x114>
      initlock(&p->lock, "proc");
    80001a38:	8b4e                	mv	s6,s3
    80001a3a:	00007597          	auipc	a1,0x7
    80001a3e:	7ee58593          	addi	a1,a1,2030 # 80009228 <digits+0x1e8>
    80001a42:	854e                	mv	a0,s3
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	10e080e7          	jalr	270(ra) # 80000b52 <initlock>
      for(t=p->threads;t<&p->threads[NTHREADS];t++)
    80001a4c:	01b98bb3          	add	s7,s3,s11
    80001a50:	64098493          	addi	s1,s3,1600
        initlock(&t->tlock,"tlock");
    80001a54:	85d2                	mv	a1,s4
    80001a56:	8526                	mv	a0,s1
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	0fa080e7          	jalr	250(ra) # 80000b52 <initlock>
      for(t=p->threads;t<&p->threads[NTHREADS];t++)
    80001a60:	0d848493          	addi	s1,s1,216
    80001a64:	ff2498e3          	bne	s1,s2,80001a54 <procinit+0xfe>
    80001a68:	bfad                	j	800019e2 <procinit+0x8c>
  }
}
    80001a6a:	70e6                	ld	ra,120(sp)
    80001a6c:	7446                	ld	s0,112(sp)
    80001a6e:	74a6                	ld	s1,104(sp)
    80001a70:	7906                	ld	s2,96(sp)
    80001a72:	69e6                	ld	s3,88(sp)
    80001a74:	6a46                	ld	s4,80(sp)
    80001a76:	6aa6                	ld	s5,72(sp)
    80001a78:	6b06                	ld	s6,64(sp)
    80001a7a:	7be2                	ld	s7,56(sp)
    80001a7c:	7c42                	ld	s8,48(sp)
    80001a7e:	7ca2                	ld	s9,40(sp)
    80001a80:	7d02                	ld	s10,32(sp)
    80001a82:	6de2                	ld	s11,24(sp)
    80001a84:	6109                	addi	sp,sp,128
    80001a86:	8082                	ret

0000000080001a88 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a88:	1141                	addi	sp,sp,-16
    80001a8a:	e422                	sd	s0,8(sp)
    80001a8c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a8e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a90:	2501                	sext.w	a0,a0
    80001a92:	6422                	ld	s0,8(sp)
    80001a94:	0141                	addi	sp,sp,16
    80001a96:	8082                	ret

0000000080001a98 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a98:	1141                	addi	sp,sp,-16
    80001a9a:	e422                	sd	s0,8(sp)
    80001a9c:	0800                	addi	s0,sp,16
    80001a9e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001aa0:	0007851b          	sext.w	a0,a5
    80001aa4:	00451793          	slli	a5,a0,0x4
    80001aa8:	97aa                	add	a5,a5,a0
    80001aaa:	078e                	slli	a5,a5,0x3
  return c;
}
    80001aac:	00011517          	auipc	a0,0x11
    80001ab0:	82450513          	addi	a0,a0,-2012 # 800122d0 <cpus>
    80001ab4:	953e                	add	a0,a0,a5
    80001ab6:	6422                	ld	s0,8(sp)
    80001ab8:	0141                	addi	sp,sp,16
    80001aba:	8082                	ret

0000000080001abc <mythread>:

struct thread*
mythread(void) {
    80001abc:	1101                	addi	sp,sp,-32
    80001abe:	ec06                	sd	ra,24(sp)
    80001ac0:	e822                	sd	s0,16(sp)
    80001ac2:	e426                	sd	s1,8(sp)
    80001ac4:	1000                	addi	s0,sp,32
  push_off();
    80001ac6:	fffff097          	auipc	ra,0xfffff
    80001aca:	118080e7          	jalr	280(ra) # 80000bde <push_off>
    80001ace:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct thread *t = c->thread;
    80001ad0:	0007871b          	sext.w	a4,a5
    80001ad4:	00471793          	slli	a5,a4,0x4
    80001ad8:	97ba                	add	a5,a5,a4
    80001ada:	078e                	slli	a5,a5,0x3
    80001adc:	00010717          	auipc	a4,0x10
    80001ae0:	7c470713          	addi	a4,a4,1988 # 800122a0 <pid_lock>
    80001ae4:	97ba                	add	a5,a5,a4
    80001ae6:	7f84                	ld	s1,56(a5)
  pop_off();
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	198080e7          	jalr	408(ra) # 80000c80 <pop_off>
  return t;
}
    80001af0:	8526                	mv	a0,s1
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	64a2                	ld	s1,8(sp)
    80001af8:	6105                	addi	sp,sp,32
    80001afa:	8082                	ret

0000000080001afc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001afc:	1141                	addi	sp,sp,-16
    80001afe:	e406                	sd	ra,8(sp)
    80001b00:	e022                	sd	s0,0(sp)
    80001b02:	0800                	addi	s0,sp,16
  //printf("forkret\n");
  static int first = 1;
  release(&mythread()->tlock);
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	fb8080e7          	jalr	-72(ra) # 80001abc <mythread>
    80001b0c:	0a850513          	addi	a0,a0,168
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	1d6080e7          	jalr	470(ra) # 80000ce6 <release>
  if (first) {
    80001b18:	00008797          	auipc	a5,0x8
    80001b1c:	dc87a783          	lw	a5,-568(a5) # 800098e0 <first.0>
    80001b20:	eb89                	bnez	a5,80001b32 <forkret+0x36>
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }
  usertrapret();
    80001b22:	00002097          	auipc	ra,0x2
    80001b26:	d60080e7          	jalr	-672(ra) # 80003882 <usertrapret>
}
    80001b2a:	60a2                	ld	ra,8(sp)
    80001b2c:	6402                	ld	s0,0(sp)
    80001b2e:	0141                	addi	sp,sp,16
    80001b30:	8082                	ret
    first = 0;
    80001b32:	00008797          	auipc	a5,0x8
    80001b36:	da07a723          	sw	zero,-594(a5) # 800098e0 <first.0>
    fsinit(ROOTDEV);
    80001b3a:	4505                	li	a0,1
    80001b3c:	00003097          	auipc	ra,0x3
    80001b40:	d44080e7          	jalr	-700(ra) # 80004880 <fsinit>
    80001b44:	bff9                	j	80001b22 <forkret+0x26>

0000000080001b46 <myproc>:
myproc(void) {
    80001b46:	1101                	addi	sp,sp,-32
    80001b48:	ec06                	sd	ra,24(sp)
    80001b4a:	e822                	sd	s0,16(sp)
    80001b4c:	e426                	sd	s1,8(sp)
    80001b4e:	1000                	addi	s0,sp,32
  push_off();
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	08e080e7          	jalr	142(ra) # 80000bde <push_off>
    80001b58:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b5a:	0007871b          	sext.w	a4,a5
    80001b5e:	00471793          	slli	a5,a4,0x4
    80001b62:	97ba                	add	a5,a5,a4
    80001b64:	078e                	slli	a5,a5,0x3
    80001b66:	00010717          	auipc	a4,0x10
    80001b6a:	73a70713          	addi	a4,a4,1850 # 800122a0 <pid_lock>
    80001b6e:	97ba                	add	a5,a5,a4
    80001b70:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	10e080e7          	jalr	270(ra) # 80000c80 <pop_off>
}
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	60e2                	ld	ra,24(sp)
    80001b7e:	6442                	ld	s0,16(sp)
    80001b80:	64a2                	ld	s1,8(sp)
    80001b82:	6105                	addi	sp,sp,32
    80001b84:	8082                	ret

0000000080001b86 <checkIfLastThread>:
{
    80001b86:	7179                	addi	sp,sp,-48
    80001b88:	f406                	sd	ra,40(sp)
    80001b8a:	f022                	sd	s0,32(sp)
    80001b8c:	ec26                	sd	s1,24(sp)
    80001b8e:	e84a                	sd	s2,16(sp)
    80001b90:	e44e                	sd	s3,8(sp)
    80001b92:	e052                	sd	s4,0(sp)
    80001b94:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001b96:	00000097          	auipc	ra,0x0
    80001b9a:	fb0080e7          	jalr	-80(ra) # 80001b46 <myproc>
    80001b9e:	892a                	mv	s2,a0
  struct thread *myT=mythread();
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	f1c080e7          	jalr	-228(ra) # 80001abc <mythread>
  for(tToCheck=p->threads; tToCheck<&p->threads[NTHREADS];tToCheck++)
    80001ba8:	59890493          	addi	s1,s2,1432
    if(tToCheck->tid!=myT->tid && isStillRunning(tToCheck))
    80001bac:	00052a03          	lw	s4,0(a0)
    80001bb0:	6505                	lui	a0,0x1
    80001bb2:	c5850513          	addi	a0,a0,-936 # c58 <_entry-0x7ffff3a8>
    80001bb6:	992a                	add	s2,s2,a0
  int isLast=1;
    80001bb8:	4985                	li	s3,1
    80001bba:	a029                	j	80001bc4 <checkIfLastThread+0x3e>
  for(tToCheck=p->threads; tToCheck<&p->threads[NTHREADS];tToCheck++)
    80001bbc:	0d848493          	addi	s1,s1,216
    80001bc0:	03248163          	beq	s1,s2,80001be2 <checkIfLastThread+0x5c>
    if(tToCheck->tid!=myT->tid && isStillRunning(tToCheck))
    80001bc4:	409c                	lw	a5,0(s1)
    80001bc6:	ff478be3          	beq	a5,s4,80001bbc <checkIfLastThread+0x36>
    80001bca:	8526                	mv	a0,s1
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	d6e080e7          	jalr	-658(ra) # 8000193a <isStillRunning>
        isLast=0;
    80001bd4:	00153513          	seqz	a0,a0
    80001bd8:	40a00533          	neg	a0,a0
    80001bdc:	00a9f9b3          	and	s3,s3,a0
    80001be0:	bff1                	j	80001bbc <checkIfLastThread+0x36>
}
    80001be2:	854e                	mv	a0,s3
    80001be4:	70a2                	ld	ra,40(sp)
    80001be6:	7402                	ld	s0,32(sp)
    80001be8:	64e2                	ld	s1,24(sp)
    80001bea:	6942                	ld	s2,16(sp)
    80001bec:	69a2                	ld	s3,8(sp)
    80001bee:	6a02                	ld	s4,0(sp)
    80001bf0:	6145                	addi	sp,sp,48
    80001bf2:	8082                	ret

0000000080001bf4 <allocpid>:
allocpid() {
    80001bf4:	1101                	addi	sp,sp,-32
    80001bf6:	ec06                	sd	ra,24(sp)
    80001bf8:	e822                	sd	s0,16(sp)
    80001bfa:	e426                	sd	s1,8(sp)
    80001bfc:	e04a                	sd	s2,0(sp)
    80001bfe:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c00:	00010917          	auipc	s2,0x10
    80001c04:	6a090913          	addi	s2,s2,1696 # 800122a0 <pid_lock>
    80001c08:	854a                	mv	a0,s2
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	028080e7          	jalr	40(ra) # 80000c32 <acquire>
  pid = nextpid;
    80001c12:	00008797          	auipc	a5,0x8
    80001c16:	cd278793          	addi	a5,a5,-814 # 800098e4 <nextpid>
    80001c1a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c1c:	0014871b          	addiw	a4,s1,1
    80001c20:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c22:	854a                	mv	a0,s2
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	0c2080e7          	jalr	194(ra) # 80000ce6 <release>
}
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	60e2                	ld	ra,24(sp)
    80001c30:	6442                	ld	s0,16(sp)
    80001c32:	64a2                	ld	s1,8(sp)
    80001c34:	6902                	ld	s2,0(sp)
    80001c36:	6105                	addi	sp,sp,32
    80001c38:	8082                	ret

0000000080001c3a <alloctid>:
alloctid(struct proc *p) {
    80001c3a:	7179                	addi	sp,sp,-48
    80001c3c:	f406                	sd	ra,40(sp)
    80001c3e:	f022                	sd	s0,32(sp)
    80001c40:	ec26                	sd	s1,24(sp)
    80001c42:	e84a                	sd	s2,16(sp)
    80001c44:	e44e                	sd	s3,8(sp)
    80001c46:	1800                	addi	s0,sp,48
    80001c48:	84aa                	mv	s1,a0
  acquire(&p->tid_lock);
    80001c4a:	6985                	lui	s3,0x1
    80001c4c:	c5898913          	addi	s2,s3,-936 # c58 <_entry-0x7ffff3a8>
    80001c50:	992a                	add	s2,s2,a0
    80001c52:	854a                	mv	a0,s2
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	fde080e7          	jalr	-34(ra) # 80000c32 <acquire>
  tid = p->nexttid;
    80001c5c:	94ce                	add	s1,s1,s3
    80001c5e:	c704a983          	lw	s3,-912(s1)
  p->nexttid+= 1;
    80001c62:	0019879b          	addiw	a5,s3,1
    80001c66:	c6f4a823          	sw	a5,-912(s1)
  release(&p->tid_lock);
    80001c6a:	854a                	mv	a0,s2
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	07a080e7          	jalr	122(ra) # 80000ce6 <release>
}
    80001c74:	854e                	mv	a0,s3
    80001c76:	70a2                	ld	ra,40(sp)
    80001c78:	7402                	ld	s0,32(sp)
    80001c7a:	64e2                	ld	s1,24(sp)
    80001c7c:	6942                	ld	s2,16(sp)
    80001c7e:	69a2                	ld	s3,8(sp)
    80001c80:	6145                	addi	sp,sp,48
    80001c82:	8082                	ret

0000000080001c84 <proc_pagetable>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	e04a                	sd	s2,0(sp)
    80001c8e:	1000                	addi	s0,sp,32
    80001c90:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	700080e7          	jalr	1792(ra) # 80001392 <uvmcreate>
    80001c9a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c9c:	c121                	beqz	a0,80001cdc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c9e:	4729                	li	a4,10
    80001ca0:	00006697          	auipc	a3,0x6
    80001ca4:	36068693          	addi	a3,a3,864 # 80008000 <_trampoline>
    80001ca8:	6605                	lui	a2,0x1
    80001caa:	040005b7          	lui	a1,0x4000
    80001cae:	15fd                	addi	a1,a1,-1
    80001cb0:	05b2                	slli	a1,a1,0xc
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	468080e7          	jalr	1128(ra) # 8000111a <mappages>
    80001cba:	02054863          	bltz	a0,80001cea <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cbe:	4719                	li	a4,6
    80001cc0:	04093683          	ld	a3,64(s2)
    80001cc4:	6605                	lui	a2,0x1
    80001cc6:	020005b7          	lui	a1,0x2000
    80001cca:	15fd                	addi	a1,a1,-1
    80001ccc:	05b6                	slli	a1,a1,0xd
    80001cce:	8526                	mv	a0,s1
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	44a080e7          	jalr	1098(ra) # 8000111a <mappages>
    80001cd8:	02054163          	bltz	a0,80001cfa <proc_pagetable+0x76>
}
    80001cdc:	8526                	mv	a0,s1
    80001cde:	60e2                	ld	ra,24(sp)
    80001ce0:	6442                	ld	s0,16(sp)
    80001ce2:	64a2                	ld	s1,8(sp)
    80001ce4:	6902                	ld	s2,0(sp)
    80001ce6:	6105                	addi	sp,sp,32
    80001ce8:	8082                	ret
    uvmfree(pagetable, 0);
    80001cea:	4581                	li	a1,0
    80001cec:	8526                	mv	a0,s1
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	8a0080e7          	jalr	-1888(ra) # 8000158e <uvmfree>
    return 0;
    80001cf6:	4481                	li	s1,0
    80001cf8:	b7d5                	j	80001cdc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cfa:	4681                	li	a3,0
    80001cfc:	4605                	li	a2,1
    80001cfe:	040005b7          	lui	a1,0x4000
    80001d02:	15fd                	addi	a1,a1,-1
    80001d04:	05b2                	slli	a1,a1,0xc
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	5c6080e7          	jalr	1478(ra) # 800012ce <uvmunmap>
    uvmfree(pagetable, 0);
    80001d10:	4581                	li	a1,0
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	87a080e7          	jalr	-1926(ra) # 8000158e <uvmfree>
    return 0;
    80001d1c:	4481                	li	s1,0
    80001d1e:	bf7d                	j	80001cdc <proc_pagetable+0x58>

0000000080001d20 <proc_freepagetable>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	84aa                	mv	s1,a0
    80001d2e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d30:	4681                	li	a3,0
    80001d32:	4605                	li	a2,1
    80001d34:	040005b7          	lui	a1,0x4000
    80001d38:	15fd                	addi	a1,a1,-1
    80001d3a:	05b2                	slli	a1,a1,0xc
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	592080e7          	jalr	1426(ra) # 800012ce <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d44:	4681                	li	a3,0
    80001d46:	4605                	li	a2,1
    80001d48:	020005b7          	lui	a1,0x2000
    80001d4c:	15fd                	addi	a1,a1,-1
    80001d4e:	05b6                	slli	a1,a1,0xd
    80001d50:	8526                	mv	a0,s1
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	57c080e7          	jalr	1404(ra) # 800012ce <uvmunmap>
  uvmfree(pagetable, sz);
    80001d5a:	85ca                	mv	a1,s2
    80001d5c:	8526                	mv	a0,s1
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	830080e7          	jalr	-2000(ra) # 8000158e <uvmfree>
}
    80001d66:	60e2                	ld	ra,24(sp)
    80001d68:	6442                	ld	s0,16(sp)
    80001d6a:	64a2                	ld	s1,8(sp)
    80001d6c:	6902                	ld	s2,0(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret

0000000080001d72 <freeproc>:
{
    80001d72:	1101                	addi	sp,sp,-32
    80001d74:	ec06                	sd	ra,24(sp)
    80001d76:	e822                	sd	s0,16(sp)
    80001d78:	e426                	sd	s1,8(sp)
    80001d7a:	e04a                	sd	s2,0(sp)
    80001d7c:	1000                	addi	s0,sp,32
    80001d7e:	892a                	mv	s2,a0
  if(p->pagetable)
    80001d80:	7d08                	ld	a0,56(a0)
    80001d82:	c519                	beqz	a0,80001d90 <freeproc+0x1e>
    proc_freepagetable(p->pagetable, p->sz);
    80001d84:	03093583          	ld	a1,48(s2)
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	f98080e7          	jalr	-104(ra) # 80001d20 <proc_freepagetable>
  p->pagetable = 0;
    80001d90:	02093c23          	sd	zero,56(s2)
  p->sz = 0;
    80001d94:	02093823          	sd	zero,48(s2)
  p->pid = 0;
    80001d98:	02092223          	sw	zero,36(s2)
  p->parent = 0;
    80001d9c:	02093423          	sd	zero,40(s2)
  p->name[0] = 0;
    80001da0:	0c090823          	sb	zero,208(s2)
  p->killed = 0;
    80001da4:	00092e23          	sw	zero,28(s2)
  p->xstate = 0;
    80001da8:	02092023          	sw	zero,32(s2)
  p->state = UNUSED;
    80001dac:	00092c23          	sw	zero,24(s2)
  for (t=p->threads; t < &p->threads[NTHREADS]; t++)
    80001db0:	64090493          	addi	s1,s2,1600
    80001db4:	6505                	lui	a0,0x1
    80001db6:	d0050513          	addi	a0,a0,-768 # d00 <_entry-0x7ffff300>
    80001dba:	992a                	add	s2,s2,a0
    80001dbc:	a029                	j	80001dc6 <freeproc+0x54>
    80001dbe:	0d848493          	addi	s1,s1,216
    80001dc2:	05248563          	beq	s1,s2,80001e0c <freeproc+0x9a>
    if(t->state!=UNUSED)
    80001dc6:	f604a783          	lw	a5,-160(s1)
    80001dca:	dbf5                	beqz	a5,80001dbe <freeproc+0x4c>
      acquire(&t->tlock);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	e64080e7          	jalr	-412(ra) # 80000c32 <acquire>
      t->trapeframe = 0;
    80001dd6:	f604bc23          	sd	zero,-136(s1)
      t->chan = 0;
    80001dda:	f604b423          	sd	zero,-152(s1)
      t->killed=0;
    80001dde:	f604a223          	sw	zero,-156(s1)
      t->tid=0;
    80001de2:	f404ac23          	sw	zero,-168(s1)
      memset(&t->context,0,sizeof(t->context));
    80001de6:	07000613          	li	a2,112
    80001dea:	4581                	li	a1,0
    80001dec:	f8048513          	addi	a0,s1,-128
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	f5a080e7          	jalr	-166(ra) # 80000d4a <memset>
      t->state=UNUSED;
    80001df8:	f604a023          	sw	zero,-160(s1)
      t->xstate = 0;
    80001dfc:	0004ac23          	sw	zero,24(s1)
      release(&t->tlock);
    80001e00:	8526                	mv	a0,s1
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	ee4080e7          	jalr	-284(ra) # 80000ce6 <release>
    80001e0a:	bf55                	j	80001dbe <freeproc+0x4c>
}
    80001e0c:	60e2                	ld	ra,24(sp)
    80001e0e:	6442                	ld	s0,16(sp)
    80001e10:	64a2                	ld	s1,8(sp)
    80001e12:	6902                	ld	s2,0(sp)
    80001e14:	6105                	addi	sp,sp,32
    80001e16:	8082                	ret

0000000080001e18 <allocproc>:
{
    80001e18:	711d                	addi	sp,sp,-96
    80001e1a:	ec86                	sd	ra,88(sp)
    80001e1c:	e8a2                	sd	s0,80(sp)
    80001e1e:	e4a6                	sd	s1,72(sp)
    80001e20:	e0ca                	sd	s2,64(sp)
    80001e22:	fc4e                	sd	s3,56(sp)
    80001e24:	f852                	sd	s4,48(sp)
    80001e26:	f456                	sd	s5,40(sp)
    80001e28:	f05a                	sd	s6,32(sp)
    80001e2a:	ec5e                	sd	s7,24(sp)
    80001e2c:	e862                	sd	s8,16(sp)
    80001e2e:	e466                	sd	s9,8(sp)
    80001e30:	1080                	addi	s0,sp,96
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e32:	00012497          	auipc	s1,0x12
    80001e36:	8f648493          	addi	s1,s1,-1802 # 80013728 <proc>
    80001e3a:	6905                	lui	s2,0x1
    80001e3c:	c9090913          	addi	s2,s2,-880 # c90 <_entry-0x7ffff370>
    80001e40:	00044a17          	auipc	s4,0x44
    80001e44:	ce8a0a13          	addi	s4,s4,-792 # 80045b28 <tickslock>
    acquire(&p->lock);
    80001e48:	89a6                	mv	s3,s1
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	fffff097          	auipc	ra,0xfffff
    80001e50:	de6080e7          	jalr	-538(ra) # 80000c32 <acquire>
    if(p->state == p_UNUSED) {
    80001e54:	4c9c                	lw	a5,24(s1)
    80001e56:	cb99                	beqz	a5,80001e6c <allocproc+0x54>
      release(&p->lock);
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e8c080e7          	jalr	-372(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e62:	94ca                	add	s1,s1,s2
    80001e64:	ff4492e3          	bne	s1,s4,80001e48 <allocproc+0x30>
  return 0;
    80001e68:	4481                	li	s1,0
    80001e6a:	a0fd                	j	80001f58 <allocproc+0x140>
  p->pid = allocpid();
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	d88080e7          	jalr	-632(ra) # 80001bf4 <allocpid>
    80001e74:	d0c8                	sw	a0,36(s1)
  p->state = p_USED;
    80001e76:	4705                	li	a4,1
    80001e78:	cc98                	sw	a4,24(s1)
  p->nexttid=1;
    80001e7a:	6785                	lui	a5,0x1
    80001e7c:	97a6                	add	a5,a5,s1
    80001e7e:	c6e7a823          	sw	a4,-912(a5) # c70 <_entry-0x7ffff390>
  if((p->headThreadTrapframe = (struct trapframe *)kalloc()) == 0){
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	c70080e7          	jalr	-912(ra) # 80000af2 <kalloc>
    80001e8a:	892a                	mv	s2,a0
    80001e8c:	e0a8                	sd	a0,64(s1)
    80001e8e:	c17d                	beqz	a0,80001f74 <allocproc+0x15c>
  p->pagetable = proc_pagetable(p);
    80001e90:	8526                	mv	a0,s1
    80001e92:	00000097          	auipc	ra,0x0
    80001e96:	df2080e7          	jalr	-526(ra) # 80001c84 <proc_pagetable>
    80001e9a:	892a                	mv	s2,a0
    80001e9c:	fc88                	sd	a0,56(s1)
  if(p->pagetable == 0){
    80001e9e:	c57d                	beqz	a0,80001f8c <allocproc+0x174>
  for ( t = p->threads; t < &p->threads[NTHREADS]; t++)
    80001ea0:	5c048913          	addi	s2,s1,1472
    80001ea4:	6b85                	lui	s7,0x1
    80001ea6:	c80b8b93          	addi	s7,s7,-896 # c80 <_entry-0x7ffff380>
    80001eaa:	9ba6                	add	s7,s7,s1
  if(p->pagetable == 0){
    80001eac:	4a81                	li	s5,0
  int currThreadIdx=0;
    80001eae:	4a01                	li	s4,0
    t->context.sp = t->kstack + PGSIZE; //to change for multi process
    80001eb0:	6c85                	lui	s9,0x1
    t->context.ra = (uint64)forkret;
    80001eb2:	00000c17          	auipc	s8,0x0
    80001eb6:	c4ac0c13          	addi	s8,s8,-950 # 80001afc <forkret>
    acquire(&t->tlock);
    80001eba:	08090b13          	addi	s6,s2,128
    80001ebe:	855a                	mv	a0,s6
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	d72080e7          	jalr	-654(ra) # 80000c32 <acquire>
    t->tid=alloctid(p);
    80001ec8:	8526                	mv	a0,s1
    80001eca:	00000097          	auipc	ra,0x0
    80001ece:	d70080e7          	jalr	-656(ra) # 80001c3a <alloctid>
    80001ed2:	fca92c23          	sw	a0,-40(s2)
    t->HasParent=0;
    80001ed6:	0a092423          	sw	zero,168(s2)
    t->parentThread=0;
    80001eda:	0a093023          	sd	zero,160(s2)
    t->idx=currThreadIdx;
    80001ede:	fd492e23          	sw	s4,-36(s2)
    currThreadIdx+=1;
    80001ee2:	2a05                	addiw	s4,s4,1
    t->chan=0;
    80001ee4:	fe093423          	sd	zero,-24(s2)
    t->killed=0;
    80001ee8:	fe092223          	sw	zero,-28(s2)
    t->state=UNUSED;
    80001eec:	fe092023          	sw	zero,-32(s2)
    t->trapeframe=(struct trapframe*)((uint64)(p->headThreadTrapframe)+(uint64)((t->idx)*sizeof(struct trapframe)));
    80001ef0:	60bc                	ld	a5,64(s1)
    80001ef2:	97d6                	add	a5,a5,s5
    80001ef4:	fef93c23          	sd	a5,-8(s2)
    memset(&t->context, 0, sizeof(t->context));
    80001ef8:	07000613          	li	a2,112
    80001efc:	4581                	li	a1,0
    80001efe:	854a                	mv	a0,s2
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	e4a080e7          	jalr	-438(ra) # 80000d4a <memset>
    t->context.sp = t->kstack + PGSIZE; //to change for multi process
    80001f08:	ff093783          	ld	a5,-16(s2)
    80001f0c:	97e6                	add	a5,a5,s9
    80001f0e:	00f93423          	sd	a5,8(s2)
    t->context.ra = (uint64)forkret;
    80001f12:	01893023          	sd	s8,0(s2)
    release(&t->tlock);
    80001f16:	855a                	mv	a0,s6
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	dce080e7          	jalr	-562(ra) # 80000ce6 <release>
  for ( t = p->threads; t < &p->threads[NTHREADS]; t++)
    80001f20:	120a8a93          	addi	s5,s5,288
    80001f24:	0d890913          	addi	s2,s2,216
    80001f28:	f97919e3          	bne	s2,s7,80001eba <allocproc+0xa2>
    80001f2c:	3f048713          	addi	a4,s1,1008
    80001f30:	1f048793          	addi	a5,s1,496
    80001f34:	3f098693          	addi	a3,s3,1008
    p->IsSigactionPointer[i]=0; //choose from sigactions array
    80001f38:	00072023          	sw	zero,0(a4)
    p->Sigactions[i].sa_handler=SIG_DFL;
    80001f3c:	0007b023          	sd	zero,0(a5)
    p->Sigactions[i].sigmask=0;
    80001f40:	0007a423          	sw	zero,8(a5)
  for (int i = 0; i < 32; i++)
    80001f44:	0711                	addi	a4,a4,4
    80001f46:	07c1                	addi	a5,a5,16
    80001f48:	fed798e3          	bne	a5,a3,80001f38 <allocproc+0x120>
  p-> SignalMask = 0;
    80001f4c:	0e04a223          	sw	zero,228(s1)
  p-> PendingSignals = 0; 
    80001f50:	0e04a023          	sw	zero,224(s1)
  p->stopped=0;
    80001f54:	5804a823          	sw	zero,1424(s1)
}
    80001f58:	8526                	mv	a0,s1
    80001f5a:	60e6                	ld	ra,88(sp)
    80001f5c:	6446                	ld	s0,80(sp)
    80001f5e:	64a6                	ld	s1,72(sp)
    80001f60:	6906                	ld	s2,64(sp)
    80001f62:	79e2                	ld	s3,56(sp)
    80001f64:	7a42                	ld	s4,48(sp)
    80001f66:	7aa2                	ld	s5,40(sp)
    80001f68:	7b02                	ld	s6,32(sp)
    80001f6a:	6be2                	ld	s7,24(sp)
    80001f6c:	6c42                	ld	s8,16(sp)
    80001f6e:	6ca2                	ld	s9,8(sp)
    80001f70:	6125                	addi	sp,sp,96
    80001f72:	8082                	ret
    freeproc(p);
    80001f74:	8526                	mv	a0,s1
    80001f76:	00000097          	auipc	ra,0x0
    80001f7a:	dfc080e7          	jalr	-516(ra) # 80001d72 <freeproc>
    release(&p->lock);
    80001f7e:	8526                	mv	a0,s1
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	d66080e7          	jalr	-666(ra) # 80000ce6 <release>
    return 0;
    80001f88:	84ca                	mv	s1,s2
    80001f8a:	b7f9                	j	80001f58 <allocproc+0x140>
    freeproc(p);
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	00000097          	auipc	ra,0x0
    80001f92:	de4080e7          	jalr	-540(ra) # 80001d72 <freeproc>
    release(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	d4e080e7          	jalr	-690(ra) # 80000ce6 <release>
    return 0;
    80001fa0:	84ca                	mv	s1,s2
    80001fa2:	bf5d                	j	80001f58 <allocproc+0x140>

0000000080001fa4 <userinit>:
{
    80001fa4:	1101                	addi	sp,sp,-32
    80001fa6:	ec06                	sd	ra,24(sp)
    80001fa8:	e822                	sd	s0,16(sp)
    80001faa:	e426                	sd	s1,8(sp)
    80001fac:	1000                	addi	s0,sp,32
  p = allocproc();
    80001fae:	00000097          	auipc	ra,0x0
    80001fb2:	e6a080e7          	jalr	-406(ra) # 80001e18 <allocproc>
    80001fb6:	84aa                	mv	s1,a0
  initproc = p;
    80001fb8:	00008797          	auipc	a5,0x8
    80001fbc:	06a7bc23          	sd	a0,120(a5) # 8000a030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001fc0:	03400613          	li	a2,52
    80001fc4:	00008597          	auipc	a1,0x8
    80001fc8:	92c58593          	addi	a1,a1,-1748 # 800098f0 <initcode>
    80001fcc:	7d08                	ld	a0,56(a0)
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	3f2080e7          	jalr	1010(ra) # 800013c0 <uvminit>
  p->sz = PGSIZE;
    80001fd6:	6785                	lui	a5,0x1
    80001fd8:	f89c                	sd	a5,48(s1)
  p->threads[0].trapeframe->epc = 0;      // user program counter
    80001fda:	5b84b703          	ld	a4,1464(s1)
    80001fde:	00073c23          	sd	zero,24(a4)
  p->threads[0].trapeframe->sp = PGSIZE;  // user stack pointer
    80001fe2:	5b84b703          	ld	a4,1464(s1)
    80001fe6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fe8:	4641                	li	a2,16
    80001fea:	00007597          	auipc	a1,0x7
    80001fee:	26e58593          	addi	a1,a1,622 # 80009258 <digits+0x218>
    80001ff2:	0d048513          	addi	a0,s1,208
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	ea6080e7          	jalr	-346(ra) # 80000e9c <safestrcpy>
  safestrcpy(p->threads[0].name, "initcode", sizeof(p->threads[0].name));
    80001ffe:	4641                	li	a2,16
    80002000:	00007597          	auipc	a1,0x7
    80002004:	25858593          	addi	a1,a1,600 # 80009258 <digits+0x218>
    80002008:	63048513          	addi	a0,s1,1584
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	e90080e7          	jalr	-368(ra) # 80000e9c <safestrcpy>
  p->cwd = namei("/");
    80002014:	00007517          	auipc	a0,0x7
    80002018:	25450513          	addi	a0,a0,596 # 80009268 <digits+0x228>
    8000201c:	00003097          	auipc	ra,0x3
    80002020:	290080e7          	jalr	656(ra) # 800052ac <namei>
    80002024:	e4e8                	sd	a0,200(s1)
  p->threads[0].state=RUNNABLE;
    80002026:	478d                	li	a5,3
    80002028:	5af4a023          	sw	a5,1440(s1)
  release(&p->lock);
    8000202c:	8526                	mv	a0,s1
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	cb8080e7          	jalr	-840(ra) # 80000ce6 <release>
}
    80002036:	60e2                	ld	ra,24(sp)
    80002038:	6442                	ld	s0,16(sp)
    8000203a:	64a2                	ld	s1,8(sp)
    8000203c:	6105                	addi	sp,sp,32
    8000203e:	8082                	ret

0000000080002040 <growproc>:
{
    80002040:	1101                	addi	sp,sp,-32
    80002042:	ec06                	sd	ra,24(sp)
    80002044:	e822                	sd	s0,16(sp)
    80002046:	e426                	sd	s1,8(sp)
    80002048:	e04a                	sd	s2,0(sp)
    8000204a:	1000                	addi	s0,sp,32
    8000204c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	af8080e7          	jalr	-1288(ra) # 80001b46 <myproc>
    80002056:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	bda080e7          	jalr	-1062(ra) # 80000c32 <acquire>
  sz = p->sz;
    80002060:	788c                	ld	a1,48(s1)
    80002062:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002066:	03204363          	bgtz	s2,8000208c <growproc+0x4c>
  } else if(n < 0){
    8000206a:	04094663          	bltz	s2,800020b6 <growproc+0x76>
  p->sz = sz;
    8000206e:	1602                	slli	a2,a2,0x20
    80002070:	9201                	srli	a2,a2,0x20
    80002072:	f890                	sd	a2,48(s1)
  release(&p->lock);
    80002074:	8526                	mv	a0,s1
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	c70080e7          	jalr	-912(ra) # 80000ce6 <release>
  return 0;
    8000207e:	4501                	li	a0,0
}
    80002080:	60e2                	ld	ra,24(sp)
    80002082:	6442                	ld	s0,16(sp)
    80002084:	64a2                	ld	s1,8(sp)
    80002086:	6902                	ld	s2,0(sp)
    80002088:	6105                	addi	sp,sp,32
    8000208a:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000208c:	00c9063b          	addw	a2,s2,a2
    80002090:	1602                	slli	a2,a2,0x20
    80002092:	9201                	srli	a2,a2,0x20
    80002094:	1582                	slli	a1,a1,0x20
    80002096:	9181                	srli	a1,a1,0x20
    80002098:	7c88                	ld	a0,56(s1)
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	3e0080e7          	jalr	992(ra) # 8000147a <uvmalloc>
    800020a2:	0005061b          	sext.w	a2,a0
    800020a6:	f661                	bnez	a2,8000206e <growproc+0x2e>
      release(&p->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	c3c080e7          	jalr	-964(ra) # 80000ce6 <release>
      return -1;
    800020b2:	557d                	li	a0,-1
    800020b4:	b7f1                	j	80002080 <growproc+0x40>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020b6:	00c9063b          	addw	a2,s2,a2
    800020ba:	1602                	slli	a2,a2,0x20
    800020bc:	9201                	srli	a2,a2,0x20
    800020be:	1582                	slli	a1,a1,0x20
    800020c0:	9181                	srli	a1,a1,0x20
    800020c2:	7c88                	ld	a0,56(s1)
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	36e080e7          	jalr	878(ra) # 80001432 <uvmdealloc>
    800020cc:	0005061b          	sext.w	a2,a0
    800020d0:	bf79                	j	8000206e <growproc+0x2e>

00000000800020d2 <fork>:
{
    800020d2:	7139                	addi	sp,sp,-64
    800020d4:	fc06                	sd	ra,56(sp)
    800020d6:	f822                	sd	s0,48(sp)
    800020d8:	f426                	sd	s1,40(sp)
    800020da:	f04a                	sd	s2,32(sp)
    800020dc:	ec4e                	sd	s3,24(sp)
    800020de:	e852                	sd	s4,16(sp)
    800020e0:	e456                	sd	s5,8(sp)
    800020e2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800020e4:	00000097          	auipc	ra,0x0
    800020e8:	a62080e7          	jalr	-1438(ra) # 80001b46 <myproc>
    800020ec:	892a                	mv	s2,a0
  struct thread *t=mythread();
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	9ce080e7          	jalr	-1586(ra) # 80001abc <mythread>
    800020f6:	8a2a                	mv	s4,a0
  if((np = allocproc()) == 0){
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	d20080e7          	jalr	-736(ra) # 80001e18 <allocproc>
    80002100:	18050763          	beqz	a0,8000228e <fork+0x1bc>
    80002104:	84aa                	mv	s1,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002106:	03093603          	ld	a2,48(s2)
    8000210a:	7d0c                	ld	a1,56(a0)
    8000210c:	03893503          	ld	a0,56(s2)
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	4b6080e7          	jalr	1206(ra) # 800015c6 <uvmcopy>
    80002118:	0a054763          	bltz	a0,800021c6 <fork+0xf4>
  np->sz = p->sz;
    8000211c:	03093783          	ld	a5,48(s2)
    80002120:	f89c                	sd	a5,48(s1)
  acquire(&t->tlock);
    80002122:	0a8a0993          	addi	s3,s4,168
    80002126:	854e                	mv	a0,s3
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b0a080e7          	jalr	-1270(ra) # 80000c32 <acquire>
  *(np->threads[0].trapeframe) = *(t->trapeframe);
    80002130:	020a3683          	ld	a3,32(s4)
    80002134:	87b6                	mv	a5,a3
    80002136:	5b84b703          	ld	a4,1464(s1)
    8000213a:	12068693          	addi	a3,a3,288
    8000213e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002142:	6788                	ld	a0,8(a5)
    80002144:	6b8c                	ld	a1,16(a5)
    80002146:	6f90                	ld	a2,24(a5)
    80002148:	01073023          	sd	a6,0(a4)
    8000214c:	e708                	sd	a0,8(a4)
    8000214e:	eb0c                	sd	a1,16(a4)
    80002150:	ef10                	sd	a2,24(a4)
    80002152:	02078793          	addi	a5,a5,32
    80002156:	02070713          	addi	a4,a4,32
    8000215a:	fed792e3          	bne	a5,a3,8000213e <fork+0x6c>
  release(&t->tlock);
    8000215e:	854e                	mv	a0,s3
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	b86080e7          	jalr	-1146(ra) # 80000ce6 <release>
  np->SignalMask = p->SignalMask;
    80002168:	0e492783          	lw	a5,228(s2)
    8000216c:	0ef4a223          	sw	a5,228(s1)
  for (int i = 0; i < 32; i++)
    80002170:	1f090613          	addi	a2,s2,496
    80002174:	1f048693          	addi	a3,s1,496
  np->SignalMask = p->SignalMask;
    80002178:	3f000793          	li	a5,1008
    8000217c:	0f000713          	li	a4,240
  for (int i = 0; i < 32; i++)
    80002180:	47000813          	li	a6,1136
    np->Sigactions[i]=p->Sigactions[i];
    80002184:	620c                	ld	a1,0(a2)
    80002186:	e28c                	sd	a1,0(a3)
    80002188:	660c                	ld	a1,8(a2)
    8000218a:	e68c                	sd	a1,8(a3)
    np->SignalHandlers[i]=p->SignalHandlers[i];
    8000218c:	00e905b3          	add	a1,s2,a4
    80002190:	6188                	ld	a0,0(a1)
    80002192:	00e485b3          	add	a1,s1,a4
    80002196:	e188                	sd	a0,0(a1)
    np->IsSigactionPointer[i]=p->IsSigactionPointer[i];
    80002198:	00f905b3          	add	a1,s2,a5
    8000219c:	4188                	lw	a0,0(a1)
    8000219e:	00f485b3          	add	a1,s1,a5
    800021a2:	c188                	sw	a0,0(a1)
  for (int i = 0; i < 32; i++)
    800021a4:	0641                	addi	a2,a2,16
    800021a6:	06c1                	addi	a3,a3,16
    800021a8:	0721                	addi	a4,a4,8
    800021aa:	0791                	addi	a5,a5,4
    800021ac:	fd079ce3          	bne	a5,a6,80002184 <fork+0xb2>
  np->threads[0].trapeframe->a0 = 0;
    800021b0:	5b84b783          	ld	a5,1464(s1)
    800021b4:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800021b8:	04890993          	addi	s3,s2,72
    800021bc:	04848a13          	addi	s4,s1,72
    800021c0:	0c890a93          	addi	s5,s2,200
    800021c4:	a00d                	j	800021e6 <fork+0x114>
    freeproc(np);
    800021c6:	8526                	mv	a0,s1
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	baa080e7          	jalr	-1110(ra) # 80001d72 <freeproc>
    release(&np->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	b14080e7          	jalr	-1260(ra) # 80000ce6 <release>
    return -1;
    800021da:	5a7d                	li	s4,-1
    800021dc:	a879                	j	8000227a <fork+0x1a8>
  for(i = 0; i < NOFILE; i++)
    800021de:	09a1                	addi	s3,s3,8
    800021e0:	0a21                	addi	s4,s4,8
    800021e2:	01598c63          	beq	s3,s5,800021fa <fork+0x128>
    if(p->ofile[i])
    800021e6:	0009b503          	ld	a0,0(s3)
    800021ea:	d975                	beqz	a0,800021de <fork+0x10c>
      np->ofile[i] = filedup(p->ofile[i]);
    800021ec:	00003097          	auipc	ra,0x3
    800021f0:	75a080e7          	jalr	1882(ra) # 80005946 <filedup>
    800021f4:	00aa3023          	sd	a0,0(s4)
    800021f8:	b7dd                	j	800021de <fork+0x10c>
  np->cwd = idup(p->cwd);
    800021fa:	0c893503          	ld	a0,200(s2)
    800021fe:	00003097          	auipc	ra,0x3
    80002202:	8bc080e7          	jalr	-1860(ra) # 80004aba <idup>
    80002206:	e4e8                	sd	a0,200(s1)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002208:	4641                	li	a2,16
    8000220a:	0d090593          	addi	a1,s2,208
    8000220e:	0d048513          	addi	a0,s1,208
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	c8a080e7          	jalr	-886(ra) # 80000e9c <safestrcpy>
  pid = np->pid;
    8000221a:	0244aa03          	lw	s4,36(s1)
  release(&np->lock);
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	ac6080e7          	jalr	-1338(ra) # 80000ce6 <release>
  acquire(&wait_lock);
    80002228:	00010997          	auipc	s3,0x10
    8000222c:	09098993          	addi	s3,s3,144 # 800122b8 <wait_lock>
    80002230:	854e                	mv	a0,s3
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	a00080e7          	jalr	-1536(ra) # 80000c32 <acquire>
  np->parent = p;
    8000223a:	0324b423          	sd	s2,40(s1)
  release(&wait_lock);
    8000223e:	854e                	mv	a0,s3
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	aa6080e7          	jalr	-1370(ra) # 80000ce6 <release>
  acquire(&np->lock);
    80002248:	8526                	mv	a0,s1
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	9e8080e7          	jalr	-1560(ra) # 80000c32 <acquire>
  acquire(&np->threads[0].tlock);
    80002252:	64048913          	addi	s2,s1,1600
    80002256:	854a                	mv	a0,s2
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	9da080e7          	jalr	-1574(ra) # 80000c32 <acquire>
  np->threads[0].state = RUNNABLE;
    80002260:	478d                	li	a5,3
    80002262:	5af4a023          	sw	a5,1440(s1)
  release(&np->threads[0].tlock);
    80002266:	854a                	mv	a0,s2
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	a7e080e7          	jalr	-1410(ra) # 80000ce6 <release>
  release(&np->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a74080e7          	jalr	-1420(ra) # 80000ce6 <release>
}
    8000227a:	8552                	mv	a0,s4
    8000227c:	70e2                	ld	ra,56(sp)
    8000227e:	7442                	ld	s0,48(sp)
    80002280:	74a2                	ld	s1,40(sp)
    80002282:	7902                	ld	s2,32(sp)
    80002284:	69e2                	ld	s3,24(sp)
    80002286:	6a42                	ld	s4,16(sp)
    80002288:	6aa2                	ld	s5,8(sp)
    8000228a:	6121                	addi	sp,sp,64
    8000228c:	8082                	ret
    return -1;
    8000228e:	5a7d                	li	s4,-1
    80002290:	b7ed                	j	8000227a <fork+0x1a8>

0000000080002292 <freethread>:
  if(t->state!=UNUSED)
    80002292:	451c                	lw	a5,8(a0)
    80002294:	e391                	bnez	a5,80002298 <freethread+0x6>
    80002296:	8082                	ret
void freethread(struct thread *t){
    80002298:	1101                	addi	sp,sp,-32
    8000229a:	ec06                	sd	ra,24(sp)
    8000229c:	e822                	sd	s0,16(sp)
    8000229e:	e426                	sd	s1,8(sp)
    800022a0:	1000                	addi	s0,sp,32
    800022a2:	84aa                	mv	s1,a0
        t->trapeframe = 0;
    800022a4:	02053023          	sd	zero,32(a0)
        t->chan = 0;
    800022a8:	00053823          	sd	zero,16(a0)
        t->killed=0;
    800022ac:	00052623          	sw	zero,12(a0)
        t->tid=0;
    800022b0:	00052023          	sw	zero,0(a0)
        memset(&t->context,0,sizeof(t->context));
    800022b4:	07000613          	li	a2,112
    800022b8:	4581                	li	a1,0
    800022ba:	02850513          	addi	a0,a0,40
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	a8c080e7          	jalr	-1396(ra) # 80000d4a <memset>
        t->state=UNUSED;
    800022c6:	0004a423          	sw	zero,8(s1)
        t->xstate = 0;
    800022ca:	0c04a023          	sw	zero,192(s1)
}
    800022ce:	60e2                	ld	ra,24(sp)
    800022d0:	6442                	ld	s0,16(sp)
    800022d2:	64a2                	ld	s1,8(sp)
    800022d4:	6105                	addi	sp,sp,32
    800022d6:	8082                	ret

00000000800022d8 <kthread_create>:
{
    800022d8:	715d                	addi	sp,sp,-80
    800022da:	e486                	sd	ra,72(sp)
    800022dc:	e0a2                	sd	s0,64(sp)
    800022de:	fc26                	sd	s1,56(sp)
    800022e0:	f84a                	sd	s2,48(sp)
    800022e2:	f44e                	sd	s3,40(sp)
    800022e4:	f052                	sd	s4,32(sp)
    800022e6:	ec56                	sd	s5,24(sp)
    800022e8:	e85a                	sd	s6,16(sp)
    800022ea:	e45e                	sd	s7,8(sp)
    800022ec:	e062                	sd	s8,0(sp)
    800022ee:	0880                	addi	s0,sp,80
    800022f0:	8c2a                	mv	s8,a0
    800022f2:	8b2e                	mv	s6,a1
  struct proc *p=myproc();
    800022f4:	00000097          	auipc	ra,0x0
    800022f8:	852080e7          	jalr	-1966(ra) # 80001b46 <myproc>
    800022fc:	8a2a                	mv	s4,a0
  struct thread *myT=mythread();
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	7be080e7          	jalr	1982(ra) # 80001abc <mythread>
    80002306:	8baa                	mv	s7,a0
  acquire(&p->lock);
    80002308:	8552                	mv	a0,s4
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	928080e7          	jalr	-1752(ra) # 80000c32 <acquire>
  for(t = p->threads; t < &p->threads[NTHREADS]; t++) {
    80002312:	598a0493          	addi	s1,s4,1432
    80002316:	6985                	lui	s3,0x1
    80002318:	c5898993          	addi	s3,s3,-936 # c58 <_entry-0x7ffff3a8>
    8000231c:	99d2                	add	s3,s3,s4
      }else if(t->state==ZOMBIE) 
    8000231e:	4a95                	li	s5,5
    80002320:	a8c1                	j	800023f0 <kthread_create+0x118>
        freethread(t);
    80002322:	8526                	mv	a0,s1
    80002324:	00000097          	auipc	ra,0x0
    80002328:	f6e080e7          	jalr	-146(ra) # 80002292 <freethread>
    release(&p->lock);
    8000232c:	8552                	mv	a0,s4
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	9b8080e7          	jalr	-1608(ra) # 80000ce6 <release>
    retTid=alloctid(p);
    80002336:	8552                	mv	a0,s4
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	902080e7          	jalr	-1790(ra) # 80001c3a <alloctid>
    80002340:	89aa                	mv	s3,a0
    t->tid=retTid;
    80002342:	c088                	sw	a0,0(s1)
    t->chan=0;
    80002344:	0004b823          	sd	zero,16(s1)
    t->killed=0;
    80002348:	0004a623          	sw	zero,12(s1)
    t->HasParent=0;
    8000234c:	0c04a823          	sw	zero,208(s1)
    t->parentThread=0;
    80002350:	0c04b423          	sd	zero,200(s1)
    t->state=RUNNABLE;
    80002354:	478d                	li	a5,3
    80002356:	c49c                	sw	a5,8(s1)
    memset(&t->context, 0, sizeof(t->context));
    80002358:	07000613          	li	a2,112
    8000235c:	4581                	li	a1,0
    8000235e:	02848513          	addi	a0,s1,40
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	9e8080e7          	jalr	-1560(ra) # 80000d4a <memset>
    t->kstack=(uint64)kalloc();
    8000236a:	ffffe097          	auipc	ra,0xffffe
    8000236e:	788080e7          	jalr	1928(ra) # 80000af2 <kalloc>
    80002372:	ec88                	sd	a0,24(s1)
    t->context.sp = t->kstack + PGSIZE-16; //to change for multi process
    80002374:	6785                	lui	a5,0x1
    80002376:	17c1                	addi	a5,a5,-16
    80002378:	953e                	add	a0,a0,a5
    8000237a:	f888                	sd	a0,48(s1)
    t->context.ra = (uint64)forkret;
    8000237c:	fffff797          	auipc	a5,0xfffff
    80002380:	78078793          	addi	a5,a5,1920 # 80001afc <forkret>
    80002384:	f49c                	sd	a5,40(s1)
    acquire(&myT->tlock);
    80002386:	0a8b8a13          	addi	s4,s7,168
    8000238a:	8552                	mv	a0,s4
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8a6080e7          	jalr	-1882(ra) # 80000c32 <acquire>
    *(t->trapeframe)=*(myT->trapeframe);
    80002394:	020bb683          	ld	a3,32(s7)
    80002398:	87b6                	mv	a5,a3
    8000239a:	7098                	ld	a4,32(s1)
    8000239c:	12068693          	addi	a3,a3,288
    800023a0:	0007b803          	ld	a6,0(a5)
    800023a4:	6788                	ld	a0,8(a5)
    800023a6:	6b8c                	ld	a1,16(a5)
    800023a8:	6f90                	ld	a2,24(a5)
    800023aa:	01073023          	sd	a6,0(a4)
    800023ae:	e708                	sd	a0,8(a4)
    800023b0:	eb0c                	sd	a1,16(a4)
    800023b2:	ef10                	sd	a2,24(a4)
    800023b4:	02078793          	addi	a5,a5,32
    800023b8:	02070713          	addi	a4,a4,32
    800023bc:	fed792e3          	bne	a5,a3,800023a0 <kthread_create+0xc8>
    release(&myT->tlock);
    800023c0:	8552                	mv	a0,s4
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	924080e7          	jalr	-1756(ra) # 80000ce6 <release>
    t->trapeframe->epc=(uint64)start_func;
    800023ca:	709c                	ld	a5,32(s1)
    800023cc:	0187bc23          	sd	s8,24(a5)
    t->trapeframe->sp=(uint64) (stack+MAX_STACK_SIZE-16);
    800023d0:	7098                	ld	a4,32(s1)
    800023d2:	6785                	lui	a5,0x1
    800023d4:	17c1                	addi	a5,a5,-16
    800023d6:	9b3e                	add	s6,s6,a5
    800023d8:	03673823          	sd	s6,48(a4)
    release(&t->tlock);
    800023dc:	854a                	mv	a0,s2
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	908080e7          	jalr	-1784(ra) # 80000ce6 <release>
    return retTid;
    800023e6:	a0a9                	j	80002430 <kthread_create+0x158>
  for(t = p->threads; t < &p->threads[NTHREADS]; t++) {
    800023e8:	0d848493          	addi	s1,s1,216
    800023ec:	03348c63          	beq	s1,s3,80002424 <kthread_create+0x14c>
    if(t->tid!=mythread()->tid)
    800023f0:	0004a903          	lw	s2,0(s1)
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	6c8080e7          	jalr	1736(ra) # 80001abc <mythread>
    800023fc:	411c                	lw	a5,0(a0)
    800023fe:	ff2785e3          	beq	a5,s2,800023e8 <kthread_create+0x110>
      acquire(&t->tlock);
    80002402:	0a848913          	addi	s2,s1,168
    80002406:	854a                	mv	a0,s2
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	82a080e7          	jalr	-2006(ra) # 80000c32 <acquire>
      if(t->state == UNUSED) {
    80002410:	449c                	lw	a5,8(s1)
    80002412:	df89                	beqz	a5,8000232c <kthread_create+0x54>
      }else if(t->state==ZOMBIE) 
    80002414:	f15787e3          	beq	a5,s5,80002322 <kthread_create+0x4a>
        release(&t->tlock);
    80002418:	854a                	mv	a0,s2
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	8cc080e7          	jalr	-1844(ra) # 80000ce6 <release>
        countThreadIdx+=1;
    80002422:	b7d9                	j	800023e8 <kthread_create+0x110>
  release(&p->lock);
    80002424:	8552                	mv	a0,s4
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	8c0080e7          	jalr	-1856(ra) # 80000ce6 <release>
  return -1;
    8000242e:	59fd                	li	s3,-1
}
    80002430:	854e                	mv	a0,s3
    80002432:	60a6                	ld	ra,72(sp)
    80002434:	6406                	ld	s0,64(sp)
    80002436:	74e2                	ld	s1,56(sp)
    80002438:	7942                	ld	s2,48(sp)
    8000243a:	79a2                	ld	s3,40(sp)
    8000243c:	7a02                	ld	s4,32(sp)
    8000243e:	6ae2                	ld	s5,24(sp)
    80002440:	6b42                	ld	s6,16(sp)
    80002442:	6ba2                	ld	s7,8(sp)
    80002444:	6c02                	ld	s8,0(sp)
    80002446:	6161                	addi	sp,sp,80
    80002448:	8082                	ret

000000008000244a <thread_is_in_process>:
int thread_is_in_process(int thread_id){
    8000244a:	1101                	addi	sp,sp,-32
    8000244c:	ec06                	sd	ra,24(sp)
    8000244e:	e822                	sd	s0,16(sp)
    80002450:	e426                	sd	s1,8(sp)
    80002452:	1000                	addi	s0,sp,32
    80002454:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	6f0080e7          	jalr	1776(ra) # 80001b46 <myproc>
  for (t = p->threads; t < &p->threads[NTHREADS]; t++){
    8000245e:	59850793          	addi	a5,a0,1432
    80002462:	6705                	lui	a4,0x1
    80002464:	c5870713          	addi	a4,a4,-936 # c58 <_entry-0x7ffff3a8>
    80002468:	972a                	add	a4,a4,a0
    if(t->tid == thread_id){
    8000246a:	4394                	lw	a3,0(a5)
    8000246c:	00968c63          	beq	a3,s1,80002484 <thread_is_in_process+0x3a>
  for (t = p->threads; t < &p->threads[NTHREADS]; t++){
    80002470:	0d878793          	addi	a5,a5,216 # 10d8 <_entry-0x7fffef28>
    80002474:	fee79be3          	bne	a5,a4,8000246a <thread_is_in_process+0x20>
  return 0;
    80002478:	4501                	li	a0,0
}
    8000247a:	60e2                	ld	ra,24(sp)
    8000247c:	6442                	ld	s0,16(sp)
    8000247e:	64a2                	ld	s1,8(sp)
    80002480:	6105                	addi	sp,sp,32
    80002482:	8082                	ret
      return 1;
    80002484:	4505                	li	a0,1
    80002486:	bfd5                	j	8000247a <thread_is_in_process+0x30>

0000000080002488 <our_kill>:
{
    80002488:	715d                	addi	sp,sp,-80
    8000248a:	e486                	sd	ra,72(sp)
    8000248c:	e0a2                	sd	s0,64(sp)
    8000248e:	fc26                	sd	s1,56(sp)
    80002490:	f84a                	sd	s2,48(sp)
    80002492:	f44e                	sd	s3,40(sp)
    80002494:	f052                	sd	s4,32(sp)
    80002496:	ec56                	sd	s5,24(sp)
    80002498:	e85a                	sd	s6,16(sp)
    8000249a:	e45e                	sd	s7,8(sp)
    8000249c:	0880                	addi	s0,sp,80
  for (p = proc; p < &proc[NPROC]; p++)
    8000249e:	00011497          	auipc	s1,0x11
    800024a2:	28a48493          	addi	s1,s1,650 # 80013728 <proc>
    800024a6:	6705                	lui	a4,0x1
    800024a8:	c9070713          	addi	a4,a4,-880 # c90 <_entry-0x7ffff370>
    800024ac:	00043697          	auipc	a3,0x43
    800024b0:	67c68693          	addi	a3,a3,1660 # 80045b28 <tickslock>
      if(p->pid==pid)
    800024b4:	50dc                	lw	a5,36(s1)
    800024b6:	00a78763          	beq	a5,a0,800024c4 <our_kill+0x3c>
  for (p = proc; p < &proc[NPROC]; p++)
    800024ba:	94ba                	add	s1,s1,a4
    800024bc:	fed49ce3          	bne	s1,a3,800024b4 <our_kill+0x2c>
  return -1;
    800024c0:	557d                	li	a0,-1
    800024c2:	a88d                	j	80002534 <our_kill+0xac>
        acquire(&p->lock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	ffffe097          	auipc	ra,0xffffe
    800024ca:	76c080e7          	jalr	1900(ra) # 80000c32 <acquire>
        p->killed=1;
    800024ce:	4785                	li	a5,1
    800024d0:	ccdc                	sw	a5,28(s1)
        release(&p->lock);
    800024d2:	8526                	mv	a0,s1
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	812080e7          	jalr	-2030(ra) # 80000ce6 <release>
        for (t = p->threads; t < &p->threads[NTHREADS]; t++)
    800024dc:	64048913          	addi	s2,s1,1600
    800024e0:	6785                	lui	a5,0x1
    800024e2:	d0078793          	addi	a5,a5,-768 # d00 <_entry-0x7ffff300>
    800024e6:	94be                	add	s1,s1,a5
              t->killed=1;
    800024e8:	4b05                	li	s6,1
              if(t->state==SLEEPING)
    800024ea:	4a89                	li	s5,2
                t->state=RUNNABLE;
    800024ec:	4b8d                	li	s7,3
    800024ee:	a811                	j	80002502 <our_kill+0x7a>
              release(&t->tlock);
    800024f0:	8552                	mv	a0,s4
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	7f4080e7          	jalr	2036(ra) # 80000ce6 <release>
        for (t = p->threads; t < &p->threads[NTHREADS]; t++)
    800024fa:	0d890913          	addi	s2,s2,216
    800024fe:	02990a63          	beq	s2,s1,80002532 <our_kill+0xaa>
          if(t->tid!=mythread()->tid)
    80002502:	8a4a                	mv	s4,s2
    80002504:	f5892983          	lw	s3,-168(s2)
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	5b4080e7          	jalr	1460(ra) # 80001abc <mythread>
    80002510:	411c                	lw	a5,0(a0)
    80002512:	ff3784e3          	beq	a5,s3,800024fa <our_kill+0x72>
              acquire(&t->tlock);
    80002516:	854a                	mv	a0,s2
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	71a080e7          	jalr	1818(ra) # 80000c32 <acquire>
              t->killed=1;
    80002520:	f7692223          	sw	s6,-156(s2)
              if(t->state==SLEEPING)
    80002524:	f6092783          	lw	a5,-160(s2)
    80002528:	fd5794e3          	bne	a5,s5,800024f0 <our_kill+0x68>
                t->state=RUNNABLE;
    8000252c:	f7792023          	sw	s7,-160(s2)
    80002530:	b7c1                	j	800024f0 <our_kill+0x68>
        return 0;
    80002532:	4501                	li	a0,0
}
    80002534:	60a6                	ld	ra,72(sp)
    80002536:	6406                	ld	s0,64(sp)
    80002538:	74e2                	ld	s1,56(sp)
    8000253a:	7942                	ld	s2,48(sp)
    8000253c:	79a2                	ld	s3,40(sp)
    8000253e:	7a02                	ld	s4,32(sp)
    80002540:	6ae2                	ld	s5,24(sp)
    80002542:	6b42                	ld	s6,16(sp)
    80002544:	6ba2                	ld	s7,8(sp)
    80002546:	6161                	addi	sp,sp,80
    80002548:	8082                	ret

000000008000254a <all_threads_killed>:
int all_threads_killed(void){
    8000254a:	1141                	addi	sp,sp,-16
    8000254c:	e406                	sd	ra,8(sp)
    8000254e:	e022                	sd	s0,0(sp)
    80002550:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	5f4080e7          	jalr	1524(ra) # 80001b46 <myproc>
  for(int i=0; i<NTHREADS; i++){
    8000255a:	5a450793          	addi	a5,a0,1444
    8000255e:	6705                	lui	a4,0x1
    80002560:	c6470713          	addi	a4,a4,-924 # c64 <_entry-0x7ffff39c>
    80002564:	972a                	add	a4,a4,a0
    if(p->threads[i].killed == 0){
    80002566:	4388                	lw	a0,0(a5)
    80002568:	c511                	beqz	a0,80002574 <all_threads_killed+0x2a>
  for(int i=0; i<NTHREADS; i++){
    8000256a:	0d878793          	addi	a5,a5,216
    8000256e:	fee79ce3          	bne	a5,a4,80002566 <all_threads_killed+0x1c>
  return 1;
    80002572:	4505                	li	a0,1
}
    80002574:	60a2                	ld	ra,8(sp)
    80002576:	6402                	ld	s0,0(sp)
    80002578:	0141                	addi	sp,sp,16
    8000257a:	8082                	ret

000000008000257c <scheduler>:
{
    8000257c:	711d                	addi	sp,sp,-96
    8000257e:	ec86                	sd	ra,88(sp)
    80002580:	e8a2                	sd	s0,80(sp)
    80002582:	e4a6                	sd	s1,72(sp)
    80002584:	e0ca                	sd	s2,64(sp)
    80002586:	fc4e                	sd	s3,56(sp)
    80002588:	f852                	sd	s4,48(sp)
    8000258a:	f456                	sd	s5,40(sp)
    8000258c:	f05a                	sd	s6,32(sp)
    8000258e:	ec5e                	sd	s7,24(sp)
    80002590:	e862                	sd	s8,16(sp)
    80002592:	e466                	sd	s9,8(sp)
    80002594:	e06a                	sd	s10,0(sp)
    80002596:	1080                	addi	s0,sp,96
    80002598:	8792                	mv	a5,tp
  int id = r_tp();
    8000259a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000259c:	00479713          	slli	a4,a5,0x4
    800025a0:	00f706b3          	add	a3,a4,a5
    800025a4:	00369613          	slli	a2,a3,0x3
    800025a8:	00010697          	auipc	a3,0x10
    800025ac:	cf868693          	addi	a3,a3,-776 # 800122a0 <pid_lock>
    800025b0:	96b2                	add	a3,a3,a2
    800025b2:	0206b823          	sd	zero,48(a3)
  c->thread=0;
    800025b6:	0206bc23          	sd	zero,56(a3)
            swtch(&c->context, &t->context);
    800025ba:	00010717          	auipc	a4,0x10
    800025be:	d2670713          	addi	a4,a4,-730 # 800122e0 <cpus+0x10>
    800025c2:	00e60b33          	add	s6,a2,a4
            c->proc = p;
    800025c6:	8a36                	mv	s4,a3
        for (t = p->threads; t < &p->threads[NTHREADS]; t++)
    800025c8:	6a85                	lui	s5,0x1
    800025ca:	c58a8b93          	addi	s7,s5,-936 # c58 <_entry-0x7ffff3a8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025ce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025d2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025d6:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800025da:	00011917          	auipc	s2,0x11
    800025de:	14e90913          	addi	s2,s2,334 # 80013728 <proc>
    800025e2:	a8b9                	j	80002640 <scheduler+0xc4>
          release(&t->tlock);
    800025e4:	854e                	mv	a0,s3
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	700080e7          	jalr	1792(ra) # 80000ce6 <release>
        for (t = p->threads; t < &p->threads[NTHREADS]; t++)
    800025ee:	0d848493          	addi	s1,s1,216
    800025f2:	03848e63          	beq	s1,s8,8000262e <scheduler+0xb2>
          acquire(&t->tlock);
    800025f6:	0a848993          	addi	s3,s1,168
    800025fa:	854e                	mv	a0,s3
    800025fc:	ffffe097          	auipc	ra,0xffffe
    80002600:	636080e7          	jalr	1590(ra) # 80000c32 <acquire>
          if(t->state==RUNNABLE)
    80002604:	449c                	lw	a5,8(s1)
    80002606:	fd979fe3          	bne	a5,s9,800025e4 <scheduler+0x68>
            t->state = RUNNING;
    8000260a:	01a4a423          	sw	s10,8(s1)
            c->proc = p;
    8000260e:	032a3823          	sd	s2,48(s4)
            c->thread=t;
    80002612:	029a3c23          	sd	s1,56(s4)
            swtch(&c->context, &t->context);
    80002616:	02848593          	addi	a1,s1,40
    8000261a:	855a                	mv	a0,s6
    8000261c:	00001097          	auipc	ra,0x1
    80002620:	1bc080e7          	jalr	444(ra) # 800037d8 <swtch>
            c->proc = 0;
    80002624:	020a3823          	sd	zero,48(s4)
            c->thread=0;
    80002628:	020a3c23          	sd	zero,56(s4)
    8000262c:	bf65                	j	800025e4 <scheduler+0x68>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000262e:	c90a8793          	addi	a5,s5,-880
    80002632:	993e                	add	s2,s2,a5
    80002634:	00043797          	auipc	a5,0x43
    80002638:	4f478793          	addi	a5,a5,1268 # 80045b28 <tickslock>
    8000263c:	f8f909e3          	beq	s2,a5,800025ce <scheduler+0x52>
      if(p->state == p_USED) {
    80002640:	01892703          	lw	a4,24(s2)
    80002644:	4785                	li	a5,1
    80002646:	fef714e3          	bne	a4,a5,8000262e <scheduler+0xb2>
        for (t = p->threads; t < &p->threads[NTHREADS]; t++)
    8000264a:	59890493          	addi	s1,s2,1432
          if(t->state==RUNNABLE)
    8000264e:	4c8d                	li	s9,3
            t->state = RUNNING;
    80002650:	4d11                	li	s10,4
        for (t = p->threads; t < &p->threads[NTHREADS]; t++)
    80002652:	01790c33          	add	s8,s2,s7
    80002656:	b745                	j	800025f6 <scheduler+0x7a>

0000000080002658 <handldeUserHandler>:
{
    80002658:	7139                	addi	sp,sp,-64
    8000265a:	fc06                	sd	ra,56(sp)
    8000265c:	f822                	sd	s0,48(sp)
    8000265e:	f426                	sd	s1,40(sp)
    80002660:	f04a                	sd	s2,32(sp)
    80002662:	ec4e                	sd	s3,24(sp)
    80002664:	0080                	addi	s0,sp,64
    80002666:	89aa                	mv	s3,a0
    80002668:	84ae                	mv	s1,a1
  struct thread *t= mythread();
    8000266a:	fffff097          	auipc	ra,0xfffff
    8000266e:	452080e7          	jalr	1106(ra) # 80001abc <mythread>
    80002672:	892a                	mv	s2,a0
  memmove(&(p->UserTrapFrameBackup),t->trapeframe,sizeof(struct trapframe));
    80002674:	12000613          	li	a2,288
    80002678:	710c                	ld	a1,32(a0)
    8000267a:	47098513          	addi	a0,s3,1136
    8000267e:	ffffe097          	auipc	ra,0xffffe
    80002682:	728080e7          	jalr	1832(ra) # 80000da6 <memmove>
  char arr[]={0x93 ,0x08 ,0x80 ,0x01 ,0x73 ,0x00 ,0x00 ,0x00 };
    80002686:	00007797          	auipc	a5,0x7
    8000268a:	cd27b783          	ld	a5,-814(a5) # 80009358 <digits+0x318>
    8000268e:	fcf43423          	sd	a5,-56(s0)
  copyout(p->pagetable,t->trapeframe->sp,arr,8);  
    80002692:	02093783          	ld	a5,32(s2)
    80002696:	46a1                	li	a3,8
    80002698:	fc840613          	addi	a2,s0,-56
    8000269c:	7b8c                	ld	a1,48(a5)
    8000269e:	0389b503          	ld	a0,56(s3)
    800026a2:	fffff097          	auipc	ra,0xfffff
    800026a6:	028080e7          	jalr	40(ra) # 800016ca <copyout>
  t->trapeframe->ra=t->trapeframe->sp;
    800026aa:	02093783          	ld	a5,32(s2)
    800026ae:	7b98                	ld	a4,48(a5)
    800026b0:	f798                	sd	a4,40(a5)
  t->trapeframe->sp-=8;  
    800026b2:	02093703          	ld	a4,32(s2)
    800026b6:	7b1c                	ld	a5,48(a4)
    800026b8:	17e1                	addi	a5,a5,-8
    800026ba:	fb1c                	sd	a5,48(a4)
  t->trapeframe->a0=signum;
    800026bc:	02093783          	ld	a5,32(s2)
    800026c0:	fba4                	sd	s1,112(a5)
  t->trapeframe->epc= (uint64) (sigPtr->sa_handler);
    800026c2:	02093783          	ld	a5,32(s2)
    800026c6:	04fd                	addi	s1,s1,31
    800026c8:	0492                	slli	s1,s1,0x4
    800026ca:	94ce                	add	s1,s1,s3
    800026cc:	6098                	ld	a4,0(s1)
    800026ce:	ef98                	sd	a4,24(a5)
}
    800026d0:	70e2                	ld	ra,56(sp)
    800026d2:	7442                	ld	s0,48(sp)
    800026d4:	74a2                	ld	s1,40(sp)
    800026d6:	7902                	ld	s2,32(sp)
    800026d8:	69e2                	ld	s3,24(sp)
    800026da:	6121                	addi	sp,sp,64
    800026dc:	8082                	ret

00000000800026de <acquireSchedPanic>:
{
    800026de:	1141                	addi	sp,sp,-16
    800026e0:	e406                	sd	ra,8(sp)
    800026e2:	e022                	sd	s0,0(sp)
    800026e4:	0800                	addi	s0,sp,16
  panic("sched t->lock");
    800026e6:	00007517          	auipc	a0,0x7
    800026ea:	b8a50513          	addi	a0,a0,-1142 # 80009270 <digits+0x230>
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	e3c080e7          	jalr	-452(ra) # 8000052a <panic>

00000000800026f6 <sched>:
{
    800026f6:	7179                	addi	sp,sp,-48
    800026f8:	f406                	sd	ra,40(sp)
    800026fa:	f022                	sd	s0,32(sp)
    800026fc:	ec26                	sd	s1,24(sp)
    800026fe:	e84a                	sd	s2,16(sp)
    80002700:	e44e                	sd	s3,8(sp)
    80002702:	1800                	addi	s0,sp,48
  struct thread *t = mythread();
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	3b8080e7          	jalr	952(ra) # 80001abc <mythread>
    8000270c:	84aa                	mv	s1,a0
  if(!holding(&t->tlock))
    8000270e:	0a850513          	addi	a0,a0,168
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	49e080e7          	jalr	1182(ra) # 80000bb0 <holding>
    8000271a:	c959                	beqz	a0,800027b0 <sched+0xba>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000271c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000271e:	0007871b          	sext.w	a4,a5
    80002722:	00471793          	slli	a5,a4,0x4
    80002726:	97ba                	add	a5,a5,a4
    80002728:	078e                	slli	a5,a5,0x3
    8000272a:	00010717          	auipc	a4,0x10
    8000272e:	b7670713          	addi	a4,a4,-1162 # 800122a0 <pid_lock>
    80002732:	97ba                	add	a5,a5,a4
    80002734:	0b07a703          	lw	a4,176(a5)
    80002738:	4785                	li	a5,1
    8000273a:	06f71f63          	bne	a4,a5,800027b8 <sched+0xc2>
  if(t->state == RUNNING)
    8000273e:	4498                	lw	a4,8(s1)
    80002740:	4791                	li	a5,4
    80002742:	0af70263          	beq	a4,a5,800027e6 <sched+0xf0>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002746:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000274a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000274c:	e7cd                	bnez	a5,800027f6 <sched+0x100>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000274e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002750:	00010917          	auipc	s2,0x10
    80002754:	b5090913          	addi	s2,s2,-1200 # 800122a0 <pid_lock>
    80002758:	0007871b          	sext.w	a4,a5
    8000275c:	00471793          	slli	a5,a4,0x4
    80002760:	97ba                	add	a5,a5,a4
    80002762:	078e                	slli	a5,a5,0x3
    80002764:	97ca                	add	a5,a5,s2
    80002766:	0b47a983          	lw	s3,180(a5)
    8000276a:	8792                	mv	a5,tp
  swtch(&t->context, &mycpu()->context);
    8000276c:	0007859b          	sext.w	a1,a5
    80002770:	00459793          	slli	a5,a1,0x4
    80002774:	97ae                	add	a5,a5,a1
    80002776:	078e                	slli	a5,a5,0x3
    80002778:	00010597          	auipc	a1,0x10
    8000277c:	b6858593          	addi	a1,a1,-1176 # 800122e0 <cpus+0x10>
    80002780:	95be                	add	a1,a1,a5
    80002782:	02848513          	addi	a0,s1,40
    80002786:	00001097          	auipc	ra,0x1
    8000278a:	052080e7          	jalr	82(ra) # 800037d8 <swtch>
    8000278e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002790:	0007871b          	sext.w	a4,a5
    80002794:	00471793          	slli	a5,a4,0x4
    80002798:	97ba                	add	a5,a5,a4
    8000279a:	078e                	slli	a5,a5,0x3
    8000279c:	97ca                	add	a5,a5,s2
    8000279e:	0b37aa23          	sw	s3,180(a5)
}
    800027a2:	70a2                	ld	ra,40(sp)
    800027a4:	7402                	ld	s0,32(sp)
    800027a6:	64e2                	ld	s1,24(sp)
    800027a8:	6942                	ld	s2,16(sp)
    800027aa:	69a2                	ld	s3,8(sp)
    800027ac:	6145                	addi	sp,sp,48
    800027ae:	8082                	ret
    acquireSchedPanic();
    800027b0:	00000097          	auipc	ra,0x0
    800027b4:	f2e080e7          	jalr	-210(ra) # 800026de <acquireSchedPanic>
    printf("pid: %d, tid: %d, idx: %d\n", myproc()->pid,t->tid,t->idx);
    800027b8:	fffff097          	auipc	ra,0xfffff
    800027bc:	38e080e7          	jalr	910(ra) # 80001b46 <myproc>
    800027c0:	40d4                	lw	a3,4(s1)
    800027c2:	4090                	lw	a2,0(s1)
    800027c4:	514c                	lw	a1,36(a0)
    800027c6:	00007517          	auipc	a0,0x7
    800027ca:	aba50513          	addi	a0,a0,-1350 # 80009280 <digits+0x240>
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	da6080e7          	jalr	-602(ra) # 80000574 <printf>
    panic("sched locks");
    800027d6:	00007517          	auipc	a0,0x7
    800027da:	aca50513          	addi	a0,a0,-1334 # 800092a0 <digits+0x260>
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	d4c080e7          	jalr	-692(ra) # 8000052a <panic>
    panic("sched running");
    800027e6:	00007517          	auipc	a0,0x7
    800027ea:	aca50513          	addi	a0,a0,-1334 # 800092b0 <digits+0x270>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	d3c080e7          	jalr	-708(ra) # 8000052a <panic>
    panic("sched interruptible");
    800027f6:	00007517          	auipc	a0,0x7
    800027fa:	aca50513          	addi	a0,a0,-1334 # 800092c0 <digits+0x280>
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	d2c080e7          	jalr	-724(ra) # 8000052a <panic>

0000000080002806 <yield>:
{
    80002806:	1101                	addi	sp,sp,-32
    80002808:	ec06                	sd	ra,24(sp)
    8000280a:	e822                	sd	s0,16(sp)
    8000280c:	e426                	sd	s1,8(sp)
    8000280e:	e04a                	sd	s2,0(sp)
    80002810:	1000                	addi	s0,sp,32
  struct thread *t = mythread();
    80002812:	fffff097          	auipc	ra,0xfffff
    80002816:	2aa080e7          	jalr	682(ra) # 80001abc <mythread>
    8000281a:	84aa                	mv	s1,a0
  acquire(&t->tlock);
    8000281c:	0a850913          	addi	s2,a0,168
    80002820:	854a                	mv	a0,s2
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	410080e7          	jalr	1040(ra) # 80000c32 <acquire>
  t->state = RUNNABLE;
    8000282a:	478d                	li	a5,3
    8000282c:	c49c                	sw	a5,8(s1)
  sched();
    8000282e:	00000097          	auipc	ra,0x0
    80002832:	ec8080e7          	jalr	-312(ra) # 800026f6 <sched>
  release(&t->tlock);
    80002836:	854a                	mv	a0,s2
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	4ae080e7          	jalr	1198(ra) # 80000ce6 <release>
}
    80002840:	60e2                	ld	ra,24(sp)
    80002842:	6442                	ld	s0,16(sp)
    80002844:	64a2                	ld	s1,8(sp)
    80002846:	6902                	ld	s2,0(sp)
    80002848:	6105                	addi	sp,sp,32
    8000284a:	8082                	ret

000000008000284c <checkIfStopped>:
  while(p->stopped)
    8000284c:	59052783          	lw	a5,1424(a0)
    80002850:	cba1                	beqz	a5,800028a0 <checkIfStopped+0x54>
{
    80002852:	1101                	addi	sp,sp,-32
    80002854:	ec06                	sd	ra,24(sp)
    80002856:	e822                	sd	s0,16(sp)
    80002858:	e426                	sd	s1,8(sp)
    8000285a:	e04a                	sd	s2,0(sp)
    8000285c:	1000                	addi	s0,sp,32
    8000285e:	84aa                	mv	s1,a0
    if(p->PendingSignals & (1<<SIGCONT))
    80002860:	00080937          	lui	s2,0x80
    80002864:	a801                	j	80002874 <checkIfStopped+0x28>
        yield();
    80002866:	00000097          	auipc	ra,0x0
    8000286a:	fa0080e7          	jalr	-96(ra) # 80002806 <yield>
  while(p->stopped)
    8000286e:	5904a783          	lw	a5,1424(s1)
    80002872:	cf81                	beqz	a5,8000288a <checkIfStopped+0x3e>
    if(p->PendingSignals & (1<<SIGCONT))
    80002874:	0e04a783          	lw	a5,224(s1)
    80002878:	0127f7b3          	and	a5,a5,s2
    8000287c:	2781                	sext.w	a5,a5
    8000287e:	cf81                	beqz	a5,80002896 <checkIfStopped+0x4a>
      if(p->Sigactions[SIGCONT].sa_handler==SIG_DFL)
    80002880:	3204b783          	ld	a5,800(s1)
    80002884:	f3ed                	bnez	a5,80002866 <checkIfStopped+0x1a>
}

void
contprocess(struct proc* p)
{
  p->stopped=0;
    80002886:	5804a823          	sw	zero,1424(s1)
}
    8000288a:	60e2                	ld	ra,24(sp)
    8000288c:	6442                	ld	s0,16(sp)
    8000288e:	64a2                	ld	s1,8(sp)
    80002890:	6902                	ld	s2,0(sp)
    80002892:	6105                	addi	sp,sp,32
    80002894:	8082                	ret
      yield();
    80002896:	00000097          	auipc	ra,0x0
    8000289a:	f70080e7          	jalr	-144(ra) # 80002806 <yield>
    8000289e:	bfc1                	j	8000286e <checkIfStopped+0x22>
    800028a0:	8082                	ret

00000000800028a2 <sleep>:
{
    800028a2:	7179                	addi	sp,sp,-48
    800028a4:	f406                	sd	ra,40(sp)
    800028a6:	f022                	sd	s0,32(sp)
    800028a8:	ec26                	sd	s1,24(sp)
    800028aa:	e84a                	sd	s2,16(sp)
    800028ac:	e44e                	sd	s3,8(sp)
    800028ae:	e052                	sd	s4,0(sp)
    800028b0:	1800                	addi	s0,sp,48
    800028b2:	89aa                	mv	s3,a0
    800028b4:	892e                	mv	s2,a1
  struct thread *t=mythread(); 
    800028b6:	fffff097          	auipc	ra,0xfffff
    800028ba:	206080e7          	jalr	518(ra) # 80001abc <mythread>
    800028be:	84aa                	mv	s1,a0
  acquire(&t->tlock);
    800028c0:	0a850a13          	addi	s4,a0,168
    800028c4:	8552                	mv	a0,s4
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	36c080e7          	jalr	876(ra) # 80000c32 <acquire>
  release(lk);
    800028ce:	854a                	mv	a0,s2
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	416080e7          	jalr	1046(ra) # 80000ce6 <release>
  t->chan = chan;
    800028d8:	0134b823          	sd	s3,16(s1)
  t->state = SLEEPING;
    800028dc:	4789                	li	a5,2
    800028de:	c49c                	sw	a5,8(s1)
  sched();
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	e16080e7          	jalr	-490(ra) # 800026f6 <sched>
  t->chan = 0;
    800028e8:	0004b823          	sd	zero,16(s1)
  release(&t->tlock);
    800028ec:	8552                	mv	a0,s4
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	3f8080e7          	jalr	1016(ra) # 80000ce6 <release>
  acquire(lk);
    800028f6:	854a                	mv	a0,s2
    800028f8:	ffffe097          	auipc	ra,0xffffe
    800028fc:	33a080e7          	jalr	826(ra) # 80000c32 <acquire>
}
    80002900:	70a2                	ld	ra,40(sp)
    80002902:	7402                	ld	s0,32(sp)
    80002904:	64e2                	ld	s1,24(sp)
    80002906:	6942                	ld	s2,16(sp)
    80002908:	69a2                	ld	s3,8(sp)
    8000290a:	6a02                	ld	s4,0(sp)
    8000290c:	6145                	addi	sp,sp,48
    8000290e:	8082                	ret

0000000080002910 <wait>:
{
    80002910:	715d                	addi	sp,sp,-80
    80002912:	e486                	sd	ra,72(sp)
    80002914:	e0a2                	sd	s0,64(sp)
    80002916:	fc26                	sd	s1,56(sp)
    80002918:	f84a                	sd	s2,48(sp)
    8000291a:	f44e                	sd	s3,40(sp)
    8000291c:	f052                	sd	s4,32(sp)
    8000291e:	ec56                	sd	s5,24(sp)
    80002920:	e85a                	sd	s6,16(sp)
    80002922:	e45e                	sd	s7,8(sp)
    80002924:	0880                	addi	s0,sp,80
    80002926:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002928:	fffff097          	auipc	ra,0xfffff
    8000292c:	21e080e7          	jalr	542(ra) # 80001b46 <myproc>
    80002930:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002932:	00010517          	auipc	a0,0x10
    80002936:	98650513          	addi	a0,a0,-1658 # 800122b8 <wait_lock>
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	2f8080e7          	jalr	760(ra) # 80000c32 <acquire>
        if(np->state == p_ZOMBIE){
    80002942:	4a89                	li	s5,2
        havekids = 1;
    80002944:	4b05                	li	s6,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002946:	6985                	lui	s3,0x1
    80002948:	c9098993          	addi	s3,s3,-880 # c90 <_entry-0x7ffff370>
    8000294c:	00043a17          	auipc	s4,0x43
    80002950:	1dca0a13          	addi	s4,s4,476 # 80045b28 <tickslock>
    havekids = 0;
    80002954:	4701                	li	a4,0
    for(np = proc; np < &proc[NPROC]; np++){
    80002956:	00011497          	auipc	s1,0x11
    8000295a:	dd248493          	addi	s1,s1,-558 # 80013728 <proc>
    8000295e:	a0b5                	j	800029ca <wait+0xba>
          pid = np->pid;
    80002960:	0244a983          	lw	s3,36(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002964:	000b8e63          	beqz	s7,80002980 <wait+0x70>
    80002968:	4691                	li	a3,4
    8000296a:	02048613          	addi	a2,s1,32
    8000296e:	85de                	mv	a1,s7
    80002970:	03893503          	ld	a0,56(s2) # 80038 <_entry-0x7ff7ffc8>
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	d56080e7          	jalr	-682(ra) # 800016ca <copyout>
    8000297c:	02054563          	bltz	a0,800029a6 <wait+0x96>
          freeproc(np);
    80002980:	8526                	mv	a0,s1
    80002982:	fffff097          	auipc	ra,0xfffff
    80002986:	3f0080e7          	jalr	1008(ra) # 80001d72 <freeproc>
          release(&np->lock);
    8000298a:	8526                	mv	a0,s1
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	35a080e7          	jalr	858(ra) # 80000ce6 <release>
          release(&wait_lock);
    80002994:	00010517          	auipc	a0,0x10
    80002998:	92450513          	addi	a0,a0,-1756 # 800122b8 <wait_lock>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	34a080e7          	jalr	842(ra) # 80000ce6 <release>
          return pid;
    800029a4:	a0a5                	j	80002a0c <wait+0xfc>
            release(&np->lock);
    800029a6:	8526                	mv	a0,s1
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	33e080e7          	jalr	830(ra) # 80000ce6 <release>
            release(&wait_lock);
    800029b0:	00010517          	auipc	a0,0x10
    800029b4:	90850513          	addi	a0,a0,-1784 # 800122b8 <wait_lock>
    800029b8:	ffffe097          	auipc	ra,0xffffe
    800029bc:	32e080e7          	jalr	814(ra) # 80000ce6 <release>
            return -1;
    800029c0:	59fd                	li	s3,-1
    800029c2:	a0a9                	j	80002a0c <wait+0xfc>
    for(np = proc; np < &proc[NPROC]; np++){
    800029c4:	94ce                	add	s1,s1,s3
    800029c6:	03448463          	beq	s1,s4,800029ee <wait+0xde>
      if(np->parent == p){
    800029ca:	749c                	ld	a5,40(s1)
    800029cc:	ff279ce3          	bne	a5,s2,800029c4 <wait+0xb4>
        acquire(&np->lock);
    800029d0:	8526                	mv	a0,s1
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	260080e7          	jalr	608(ra) # 80000c32 <acquire>
        if(np->state == p_ZOMBIE){
    800029da:	4c9c                	lw	a5,24(s1)
    800029dc:	f95782e3          	beq	a5,s5,80002960 <wait+0x50>
        release(&np->lock);
    800029e0:	8526                	mv	a0,s1
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	304080e7          	jalr	772(ra) # 80000ce6 <release>
        havekids = 1;
    800029ea:	875a                	mv	a4,s6
    800029ec:	bfe1                	j	800029c4 <wait+0xb4>
    if(!havekids || all_threads_killed()){
    800029ee:	c711                	beqz	a4,800029fa <wait+0xea>
    800029f0:	00000097          	auipc	ra,0x0
    800029f4:	b5a080e7          	jalr	-1190(ra) # 8000254a <all_threads_killed>
    800029f8:	c515                	beqz	a0,80002a24 <wait+0x114>
      release(&wait_lock);
    800029fa:	00010517          	auipc	a0,0x10
    800029fe:	8be50513          	addi	a0,a0,-1858 # 800122b8 <wait_lock>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	2e4080e7          	jalr	740(ra) # 80000ce6 <release>
      return -1;
    80002a0a:	59fd                	li	s3,-1
}
    80002a0c:	854e                	mv	a0,s3
    80002a0e:	60a6                	ld	ra,72(sp)
    80002a10:	6406                	ld	s0,64(sp)
    80002a12:	74e2                	ld	s1,56(sp)
    80002a14:	7942                	ld	s2,48(sp)
    80002a16:	79a2                	ld	s3,40(sp)
    80002a18:	7a02                	ld	s4,32(sp)
    80002a1a:	6ae2                	ld	s5,24(sp)
    80002a1c:	6b42                	ld	s6,16(sp)
    80002a1e:	6ba2                	ld	s7,8(sp)
    80002a20:	6161                	addi	sp,sp,80
    80002a22:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002a24:	00010597          	auipc	a1,0x10
    80002a28:	89458593          	addi	a1,a1,-1900 # 800122b8 <wait_lock>
    80002a2c:	854a                	mv	a0,s2
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	e74080e7          	jalr	-396(ra) # 800028a2 <sleep>
    havekids = 0;
    80002a36:	bf39                	j	80002954 <wait+0x44>

0000000080002a38 <wakeup>:
{
    80002a38:	7159                	addi	sp,sp,-112
    80002a3a:	f486                	sd	ra,104(sp)
    80002a3c:	f0a2                	sd	s0,96(sp)
    80002a3e:	eca6                	sd	s1,88(sp)
    80002a40:	e8ca                	sd	s2,80(sp)
    80002a42:	e4ce                	sd	s3,72(sp)
    80002a44:	e0d2                	sd	s4,64(sp)
    80002a46:	fc56                	sd	s5,56(sp)
    80002a48:	f85a                	sd	s6,48(sp)
    80002a4a:	f45e                	sd	s7,40(sp)
    80002a4c:	f062                	sd	s8,32(sp)
    80002a4e:	ec66                	sd	s9,24(sp)
    80002a50:	e86a                	sd	s10,16(sp)
    80002a52:	e46e                	sd	s11,8(sp)
    80002a54:	1880                	addi	s0,sp,112
    80002a56:	8caa                	mv	s9,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002a58:	00012917          	auipc	s2,0x12
    80002a5c:	92890913          	addi	s2,s2,-1752 # 80014380 <proc+0xc58>
    80002a60:	00011a97          	auipc	s5,0x11
    80002a64:	260a8a93          	addi	s5,s5,608 # 80013cc0 <proc+0x598>
    80002a68:	00043c17          	auipc	s8,0x43
    80002a6c:	658c0c13          	addi	s8,s8,1624 # 800460c0 <bcache+0x580>
      if(p->state==p_USED)
    80002a70:	4a05                	li	s4,1
          if(t->state == SLEEPING && t->chan == chan) {
    80002a72:	4b89                	li	s7,2
            t->state = RUNNABLE;
    80002a74:	4d0d                	li	s10,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002a76:	6b05                	lui	s6,0x1
    80002a78:	c90b0b13          	addi	s6,s6,-880 # c90 <_entry-0x7ffff370>
    80002a7c:	a881                	j	80002acc <wakeup+0x94>
    for (t = p->threads; t < &p->threads[NTHREADS]; t++)
    80002a7e:	0d848493          	addi	s1,s1,216
    80002a82:	05248163          	beq	s1,s2,80002ac4 <wakeup+0x8c>
      if(p->state==p_USED)
    80002a86:	a809a783          	lw	a5,-1408(s3)
    80002a8a:	ff479ae3          	bne	a5,s4,80002a7e <wakeup+0x46>
        if(t!=mythread())
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	02e080e7          	jalr	46(ra) # 80001abc <mythread>
    80002a96:	fea484e3          	beq	s1,a0,80002a7e <wakeup+0x46>
          if(t->state == SLEEPING && t->chan == chan) {
    80002a9a:	449c                	lw	a5,8(s1)
    80002a9c:	ff7791e3          	bne	a5,s7,80002a7e <wakeup+0x46>
    80002aa0:	689c                	ld	a5,16(s1)
    80002aa2:	fd979ee3          	bne	a5,s9,80002a7e <wakeup+0x46>
            acquire(&t->tlock);
    80002aa6:	0a848d93          	addi	s11,s1,168
    80002aaa:	856e                	mv	a0,s11
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	186080e7          	jalr	390(ra) # 80000c32 <acquire>
            t->state = RUNNABLE;
    80002ab4:	01a4a423          	sw	s10,8(s1)
            release(&t->tlock);
    80002ab8:	856e                	mv	a0,s11
    80002aba:	ffffe097          	auipc	ra,0xffffe
    80002abe:	22c080e7          	jalr	556(ra) # 80000ce6 <release>
    80002ac2:	bf75                	j	80002a7e <wakeup+0x46>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002ac4:	995a                	add	s2,s2,s6
    80002ac6:	9ada                	add	s5,s5,s6
    80002ac8:	018a8563          	beq	s5,s8,80002ad2 <wakeup+0x9a>
    for (t = p->threads; t < &p->threads[NTHREADS]; t++)
    80002acc:	89d6                	mv	s3,s5
    80002ace:	84d6                	mv	s1,s5
    80002ad0:	bf5d                	j	80002a86 <wakeup+0x4e>
}
    80002ad2:	70a6                	ld	ra,104(sp)
    80002ad4:	7406                	ld	s0,96(sp)
    80002ad6:	64e6                	ld	s1,88(sp)
    80002ad8:	6946                	ld	s2,80(sp)
    80002ada:	69a6                	ld	s3,72(sp)
    80002adc:	6a06                	ld	s4,64(sp)
    80002ade:	7ae2                	ld	s5,56(sp)
    80002ae0:	7b42                	ld	s6,48(sp)
    80002ae2:	7ba2                	ld	s7,40(sp)
    80002ae4:	7c02                	ld	s8,32(sp)
    80002ae6:	6ce2                	ld	s9,24(sp)
    80002ae8:	6d42                	ld	s10,16(sp)
    80002aea:	6da2                	ld	s11,8(sp)
    80002aec:	6165                	addi	sp,sp,112
    80002aee:	8082                	ret

0000000080002af0 <reparent>:
{
    80002af0:	7139                	addi	sp,sp,-64
    80002af2:	fc06                	sd	ra,56(sp)
    80002af4:	f822                	sd	s0,48(sp)
    80002af6:	f426                	sd	s1,40(sp)
    80002af8:	f04a                	sd	s2,32(sp)
    80002afa:	ec4e                	sd	s3,24(sp)
    80002afc:	e852                	sd	s4,16(sp)
    80002afe:	e456                	sd	s5,8(sp)
    80002b00:	0080                	addi	s0,sp,64
    80002b02:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b04:	00011497          	auipc	s1,0x11
    80002b08:	c2448493          	addi	s1,s1,-988 # 80013728 <proc>
      pp->parent = initproc;
    80002b0c:	00007a97          	auipc	s5,0x7
    80002b10:	524a8a93          	addi	s5,s5,1316 # 8000a030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b14:	6905                	lui	s2,0x1
    80002b16:	c9090913          	addi	s2,s2,-880 # c90 <_entry-0x7ffff370>
    80002b1a:	00043a17          	auipc	s4,0x43
    80002b1e:	00ea0a13          	addi	s4,s4,14 # 80045b28 <tickslock>
    80002b22:	a021                	j	80002b2a <reparent+0x3a>
    80002b24:	94ca                	add	s1,s1,s2
    80002b26:	01448d63          	beq	s1,s4,80002b40 <reparent+0x50>
    if(pp->parent == p){
    80002b2a:	749c                	ld	a5,40(s1)
    80002b2c:	ff379ce3          	bne	a5,s3,80002b24 <reparent+0x34>
      pp->parent = initproc;
    80002b30:	000ab503          	ld	a0,0(s5)
    80002b34:	f488                	sd	a0,40(s1)
      wakeup(initproc);
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	f02080e7          	jalr	-254(ra) # 80002a38 <wakeup>
    80002b3e:	b7dd                	j	80002b24 <reparent+0x34>
}
    80002b40:	70e2                	ld	ra,56(sp)
    80002b42:	7442                	ld	s0,48(sp)
    80002b44:	74a2                	ld	s1,40(sp)
    80002b46:	7902                	ld	s2,32(sp)
    80002b48:	69e2                	ld	s3,24(sp)
    80002b4a:	6a42                	ld	s4,16(sp)
    80002b4c:	6aa2                	ld	s5,8(sp)
    80002b4e:	6121                	addi	sp,sp,64
    80002b50:	8082                	ret

0000000080002b52 <threadExitLast>:
{
    80002b52:	7139                	addi	sp,sp,-64
    80002b54:	fc06                	sd	ra,56(sp)
    80002b56:	f822                	sd	s0,48(sp)
    80002b58:	f426                	sd	s1,40(sp)
    80002b5a:	f04a                	sd	s2,32(sp)
    80002b5c:	ec4e                	sd	s3,24(sp)
    80002b5e:	e852                	sd	s4,16(sp)
    80002b60:	e456                	sd	s5,8(sp)
    80002b62:	0080                	addi	s0,sp,64
    80002b64:	8aaa                	mv	s5,a0
  struct proc *p=myproc();
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	fe0080e7          	jalr	-32(ra) # 80001b46 <myproc>
    80002b6e:	89aa                	mv	s3,a0
  struct thread *myT=mythread();
    80002b70:	fffff097          	auipc	ra,0xfffff
    80002b74:	f4c080e7          	jalr	-180(ra) # 80001abc <mythread>
    80002b78:	8a2a                	mv	s4,a0
  for(int fd = 0; fd < NOFILE; fd++){
    80002b7a:	04898493          	addi	s1,s3,72
    80002b7e:	0c898913          	addi	s2,s3,200
    80002b82:	a021                	j	80002b8a <threadExitLast+0x38>
    80002b84:	04a1                	addi	s1,s1,8
    80002b86:	01248b63          	beq	s1,s2,80002b9c <threadExitLast+0x4a>
    if(p->ofile[fd]){
    80002b8a:	6088                	ld	a0,0(s1)
    80002b8c:	dd65                	beqz	a0,80002b84 <threadExitLast+0x32>
      fileclose(f);
    80002b8e:	00003097          	auipc	ra,0x3
    80002b92:	e0a080e7          	jalr	-502(ra) # 80005998 <fileclose>
      p->ofile[fd] = 0;
    80002b96:	0004b023          	sd	zero,0(s1)
    80002b9a:	b7ed                	j	80002b84 <threadExitLast+0x32>
  begin_op();
    80002b9c:	00003097          	auipc	ra,0x3
    80002ba0:	930080e7          	jalr	-1744(ra) # 800054cc <begin_op>
  iput(p->cwd);
    80002ba4:	0c89b503          	ld	a0,200(s3)
    80002ba8:	00002097          	auipc	ra,0x2
    80002bac:	10a080e7          	jalr	266(ra) # 80004cb2 <iput>
  end_op();
    80002bb0:	00003097          	auipc	ra,0x3
    80002bb4:	99c080e7          	jalr	-1636(ra) # 8000554c <end_op>
  p->cwd = 0;
    80002bb8:	0c09b423          	sd	zero,200(s3)
  acquire(&wait_lock);
    80002bbc:	0000f497          	auipc	s1,0xf
    80002bc0:	6fc48493          	addi	s1,s1,1788 # 800122b8 <wait_lock>
    80002bc4:	8526                	mv	a0,s1
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	06c080e7          	jalr	108(ra) # 80000c32 <acquire>
  reparent(p);
    80002bce:	854e                	mv	a0,s3
    80002bd0:	00000097          	auipc	ra,0x0
    80002bd4:	f20080e7          	jalr	-224(ra) # 80002af0 <reparent>
  wakeup(p->parent);
    80002bd8:	0289b503          	ld	a0,40(s3)
    80002bdc:	00000097          	auipc	ra,0x0
    80002be0:	e5c080e7          	jalr	-420(ra) # 80002a38 <wakeup>
  acquire(&p->lock);
    80002be4:	854e                	mv	a0,s3
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	04c080e7          	jalr	76(ra) # 80000c32 <acquire>
  acquire(&myT->tlock);
    80002bee:	0a8a0513          	addi	a0,s4,168
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	040080e7          	jalr	64(ra) # 80000c32 <acquire>
  p->xstate = status;
    80002bfa:	0359a023          	sw	s5,32(s3)
  p->state = p_ZOMBIE;
    80002bfe:	4789                	li	a5,2
    80002c00:	00f9ac23          	sw	a5,24(s3)
  myT->killed=1;
    80002c04:	4785                	li	a5,1
    80002c06:	00fa2623          	sw	a5,12(s4)
  myT->xstate = status;
    80002c0a:	0d5a2023          	sw	s5,192(s4)
  myT->state=ZOMBIE;
    80002c0e:	4795                	li	a5,5
    80002c10:	00fa2423          	sw	a5,8(s4)
  wakeup(myT);
    80002c14:	8552                	mv	a0,s4
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	e22080e7          	jalr	-478(ra) # 80002a38 <wakeup>
  release(&p->lock);
    80002c1e:	854e                	mv	a0,s3
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	0c6080e7          	jalr	198(ra) # 80000ce6 <release>
  release(&wait_lock);
    80002c28:	8526                	mv	a0,s1
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	0bc080e7          	jalr	188(ra) # 80000ce6 <release>
  sched();
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	ac4080e7          	jalr	-1340(ra) # 800026f6 <sched>
  panic("zombie exit");
    80002c3a:	00006517          	auipc	a0,0x6
    80002c3e:	69e50513          	addi	a0,a0,1694 # 800092d8 <digits+0x298>
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	8e8080e7          	jalr	-1816(ra) # 8000052a <panic>

0000000080002c4a <threadExitNotLast>:
{
    80002c4a:	1101                	addi	sp,sp,-32
    80002c4c:	ec06                	sd	ra,24(sp)
    80002c4e:	e822                	sd	s0,16(sp)
    80002c50:	e426                	sd	s1,8(sp)
    80002c52:	e04a                	sd	s2,0(sp)
    80002c54:	1000                	addi	s0,sp,32
    80002c56:	892a                	mv	s2,a0
  struct thread *t=mythread();
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	e64080e7          	jalr	-412(ra) # 80001abc <mythread>
    80002c60:	84aa                	mv	s1,a0
  acquire(&t->tlock);
    80002c62:	0a850513          	addi	a0,a0,168
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	fcc080e7          	jalr	-52(ra) # 80000c32 <acquire>
  t->killed=1;
    80002c6e:	4785                	li	a5,1
    80002c70:	c4dc                	sw	a5,12(s1)
  t->xstate = status;
    80002c72:	0d24a023          	sw	s2,192(s1)
  t->state=ZOMBIE;
    80002c76:	4795                	li	a5,5
    80002c78:	c49c                	sw	a5,8(s1)
  wakeup(t);
    80002c7a:	8526                	mv	a0,s1
    80002c7c:	00000097          	auipc	ra,0x0
    80002c80:	dbc080e7          	jalr	-580(ra) # 80002a38 <wakeup>
  wakeup(&myproc()->join_lock);
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	ec2080e7          	jalr	-318(ra) # 80001b46 <myproc>
    80002c8c:	6785                	lui	a5,0x1
    80002c8e:	c7878793          	addi	a5,a5,-904 # c78 <_entry-0x7ffff388>
    80002c92:	953e                	add	a0,a0,a5
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	da4080e7          	jalr	-604(ra) # 80002a38 <wakeup>
  release(&myproc()->lock);
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	eaa080e7          	jalr	-342(ra) # 80001b46 <myproc>
    80002ca4:	ffffe097          	auipc	ra,0xffffe
    80002ca8:	042080e7          	jalr	66(ra) # 80000ce6 <release>
  sched();
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	a4a080e7          	jalr	-1462(ra) # 800026f6 <sched>
  panic("Kill thread");
    80002cb4:	00006517          	auipc	a0,0x6
    80002cb8:	63450513          	addi	a0,a0,1588 # 800092e8 <digits+0x2a8>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	86e080e7          	jalr	-1938(ra) # 8000052a <panic>

0000000080002cc4 <waitForThreadToEnd>:
{
    80002cc4:	7139                	addi	sp,sp,-64
    80002cc6:	fc06                	sd	ra,56(sp)
    80002cc8:	f822                	sd	s0,48(sp)
    80002cca:	f426                	sd	s1,40(sp)
    80002ccc:	f04a                	sd	s2,32(sp)
    80002cce:	ec4e                	sd	s3,24(sp)
    80002cd0:	e852                	sd	s4,16(sp)
    80002cd2:	e456                	sd	s5,8(sp)
    80002cd4:	0080                	addi	s0,sp,64
    80002cd6:	892a                	mv	s2,a0
  struct thread *myT=mythread();
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	de4080e7          	jalr	-540(ra) # 80001abc <mythread>
    80002ce0:	8a2a                	mv	s4,a0
  struct proc *p=myproc();
    80002ce2:	fffff097          	auipc	ra,0xfffff
    80002ce6:	e64080e7          	jalr	-412(ra) # 80001b46 <myproc>
    80002cea:	84aa                	mv	s1,a0
    if(t->state==ZOMBIE)
    80002cec:	00892783          	lw	a5,8(s2)
    80002cf0:	4715                	li	a4,5
    80002cf2:	02e78f63          	beq	a5,a4,80002d30 <waitForThreadToEnd+0x6c>
    sleep(t,&p->join_lock);
    80002cf6:	6985                	lui	s3,0x1
    80002cf8:	c7898993          	addi	s3,s3,-904 # c78 <_entry-0x7ffff388>
    80002cfc:	99aa                	add	s3,s3,a0
    if(t->state==ZOMBIE)
    80002cfe:	4a95                	li	s5,5
    if(t->state==UNUSED)
    80002d00:	c7bd                	beqz	a5,80002d6e <waitForThreadToEnd+0xaa>
    if(myT->killed)
    80002d02:	00ca2783          	lw	a5,12(s4)
    80002d06:	ebd9                	bnez	a5,80002d9c <waitForThreadToEnd+0xd8>
    release(&p->lock);
    80002d08:	8526                	mv	a0,s1
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	fdc080e7          	jalr	-36(ra) # 80000ce6 <release>
    sleep(t,&p->join_lock);
    80002d12:	85ce                	mv	a1,s3
    80002d14:	854a                	mv	a0,s2
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	b8c080e7          	jalr	-1140(ra) # 800028a2 <sleep>
    acquire(&p->lock);
    80002d1e:	8526                	mv	a0,s1
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	f12080e7          	jalr	-238(ra) # 80000c32 <acquire>
    if(t->state==ZOMBIE)
    80002d28:	00892783          	lw	a5,8(s2)
    80002d2c:	fd579ae3          	bne	a5,s5,80002d00 <waitForThreadToEnd+0x3c>
      release(&p->join_lock);
    80002d30:	6505                	lui	a0,0x1
    80002d32:	c7850513          	addi	a0,a0,-904 # c78 <_entry-0x7ffff388>
    80002d36:	9526                	add	a0,a0,s1
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	fae080e7          	jalr	-82(ra) # 80000ce6 <release>
      if(checkIfLastThread(t))
    80002d40:	854a                	mv	a0,s2
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	e44080e7          	jalr	-444(ra) # 80001b86 <checkIfLastThread>
    80002d4a:	cd01                	beqz	a0,80002d62 <waitForThreadToEnd+0x9e>
        release(&p->lock);
    80002d4c:	8526                	mv	a0,s1
    80002d4e:	ffffe097          	auipc	ra,0xffffe
    80002d52:	f98080e7          	jalr	-104(ra) # 80000ce6 <release>
        threadExitLast(t->xstate);
    80002d56:	0c092503          	lw	a0,192(s2)
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	df8080e7          	jalr	-520(ra) # 80002b52 <threadExitLast>
        threadExitNotLast(t->xstate);
    80002d62:	0c092503          	lw	a0,192(s2)
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	ee4080e7          	jalr	-284(ra) # 80002c4a <threadExitNotLast>
      release(&p->lock);
    80002d6e:	8526                	mv	a0,s1
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	f76080e7          	jalr	-138(ra) # 80000ce6 <release>
      release(&p->join_lock);
    80002d78:	6505                	lui	a0,0x1
    80002d7a:	c7850513          	addi	a0,a0,-904 # c78 <_entry-0x7ffff388>
    80002d7e:	9526                	add	a0,a0,s1
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	f66080e7          	jalr	-154(ra) # 80000ce6 <release>
      return 1;
    80002d88:	4505                	li	a0,1
}
    80002d8a:	70e2                	ld	ra,56(sp)
    80002d8c:	7442                	ld	s0,48(sp)
    80002d8e:	74a2                	ld	s1,40(sp)
    80002d90:	7902                	ld	s2,32(sp)
    80002d92:	69e2                	ld	s3,24(sp)
    80002d94:	6a42                	ld	s4,16(sp)
    80002d96:	6aa2                	ld	s5,8(sp)
    80002d98:	6121                	addi	sp,sp,64
    80002d9a:	8082                	ret
      release(&p->lock);
    80002d9c:	8526                	mv	a0,s1
    80002d9e:	ffffe097          	auipc	ra,0xffffe
    80002da2:	f48080e7          	jalr	-184(ra) # 80000ce6 <release>
      release(&p->join_lock);
    80002da6:	6505                	lui	a0,0x1
    80002da8:	c7850513          	addi	a0,a0,-904 # c78 <_entry-0x7ffff388>
    80002dac:	9526                	add	a0,a0,s1
    80002dae:	ffffe097          	auipc	ra,0xffffe
    80002db2:	f38080e7          	jalr	-200(ra) # 80000ce6 <release>
      return -1;
    80002db6:	557d                	li	a0,-1
    80002db8:	bfc9                	j	80002d8a <waitForThreadToEnd+0xc6>

0000000080002dba <kthread_join>:
kthread_join(int thread_id, int* status){
    80002dba:	7139                	addi	sp,sp,-64
    80002dbc:	fc06                	sd	ra,56(sp)
    80002dbe:	f822                	sd	s0,48(sp)
    80002dc0:	f426                	sd	s1,40(sp)
    80002dc2:	f04a                	sd	s2,32(sp)
    80002dc4:	ec4e                	sd	s3,24(sp)
    80002dc6:	e852                	sd	s4,16(sp)
    80002dc8:	e456                	sd	s5,8(sp)
    80002dca:	e05a                	sd	s6,0(sp)
    80002dcc:	0080                	addi	s0,sp,64
    80002dce:	89aa                	mv	s3,a0
    80002dd0:	8b2e                	mv	s6,a1
  struct proc *p=myproc();
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	d74080e7          	jalr	-652(ra) # 80001b46 <myproc>
    80002dda:	8a2a                	mv	s4,a0
  acquire(&p->join_lock);
    80002ddc:	6905                	lui	s2,0x1
    80002dde:	c7890a93          	addi	s5,s2,-904 # c78 <_entry-0x7ffff388>
    80002de2:	9aaa                	add	s5,s5,a0
    80002de4:	8556                	mv	a0,s5
    80002de6:	ffffe097          	auipc	ra,0xffffe
    80002dea:	e4c080e7          	jalr	-436(ra) # 80000c32 <acquire>
  acquire(&p->lock);
    80002dee:	8552                	mv	a0,s4
    80002df0:	ffffe097          	auipc	ra,0xffffe
    80002df4:	e42080e7          	jalr	-446(ra) # 80000c32 <acquire>
  for (t=p->threads; t < & p->threads[NTHREADS]; t++)
    80002df8:	598a0493          	addi	s1,s4,1432
    80002dfc:	c5890793          	addi	a5,s2,-936
    80002e00:	97d2                	add	a5,a5,s4
    if(t->tid == thread_id)
    80002e02:	4098                	lw	a4,0(s1)
    80002e04:	03370b63          	beq	a4,s3,80002e3a <kthread_join+0x80>
  for (t=p->threads; t < & p->threads[NTHREADS]; t++)
    80002e08:	0d848493          	addi	s1,s1,216
    80002e0c:	fef49be3          	bne	s1,a5,80002e02 <kthread_join+0x48>
  release(&p->lock);
    80002e10:	8552                	mv	a0,s4
    80002e12:	ffffe097          	auipc	ra,0xffffe
    80002e16:	ed4080e7          	jalr	-300(ra) # 80000ce6 <release>
  release(&p->join_lock);
    80002e1a:	8556                	mv	a0,s5
    80002e1c:	ffffe097          	auipc	ra,0xffffe
    80002e20:	eca080e7          	jalr	-310(ra) # 80000ce6 <release>
  return -1;
    80002e24:	557d                	li	a0,-1
}
    80002e26:	70e2                	ld	ra,56(sp)
    80002e28:	7442                	ld	s0,48(sp)
    80002e2a:	74a2                	ld	s1,40(sp)
    80002e2c:	7902                	ld	s2,32(sp)
    80002e2e:	69e2                	ld	s3,24(sp)
    80002e30:	6a42                	ld	s4,16(sp)
    80002e32:	6aa2                	ld	s5,8(sp)
    80002e34:	6b02                	ld	s6,0(sp)
    80002e36:	6121                	addi	sp,sp,64
    80002e38:	8082                	ret
      int returnVal=waitForThreadToEnd(t);
    80002e3a:	8526                	mv	a0,s1
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	e88080e7          	jalr	-376(ra) # 80002cc4 <waitForThreadToEnd>
      if(returnVal<0)
    80002e44:	fe0541e3          	bltz	a0,80002e26 <kthread_join+0x6c>
      if(status!=(int *)-1)
    80002e48:	57fd                	li	a5,-1
    80002e4a:	00fb0c63          	beq	s6,a5,80002e62 <kthread_join+0xa8>
        copyout(p->pagetable, (uint64) status, (char *)&t->xstate,
    80002e4e:	4691                	li	a3,4
    80002e50:	0c048613          	addi	a2,s1,192
    80002e54:	85da                	mv	a1,s6
    80002e56:	038a3503          	ld	a0,56(s4)
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	870080e7          	jalr	-1936(ra) # 800016ca <copyout>
      return t->xstate;
    80002e62:	0c04a503          	lw	a0,192(s1)
    80002e66:	b7c1                	j	80002e26 <kthread_join+0x6c>

0000000080002e68 <kthread_exit>:
{
    80002e68:	7179                	addi	sp,sp,-48
    80002e6a:	f406                	sd	ra,40(sp)
    80002e6c:	f022                	sd	s0,32(sp)
    80002e6e:	ec26                	sd	s1,24(sp)
    80002e70:	e84a                	sd	s2,16(sp)
    80002e72:	e44e                	sd	s3,8(sp)
    80002e74:	1800                	addi	s0,sp,48
    80002e76:	892a                	mv	s2,a0
  struct thread *myT=mythread();
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	c44080e7          	jalr	-956(ra) # 80001abc <mythread>
    80002e80:	84aa                	mv	s1,a0
  struct proc *p=myproc();
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	cc4080e7          	jalr	-828(ra) # 80001b46 <myproc>
    80002e8a:	89aa                	mv	s3,a0
  acquire(&p->lock);
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	da6080e7          	jalr	-602(ra) # 80000c32 <acquire>
  if(myT->killed)
    80002e94:	44dc                	lw	a5,12(s1)
    80002e96:	e385                	bnez	a5,80002eb6 <kthread_exit+0x4e>
  if (checkIfLastThread())
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	cee080e7          	jalr	-786(ra) # 80001b86 <checkIfLastThread>
    80002ea0:	c51d                	beqz	a0,80002ece <kthread_exit+0x66>
    release(&p->lock);
    80002ea2:	854e                	mv	a0,s3
    80002ea4:	ffffe097          	auipc	ra,0xffffe
    80002ea8:	e42080e7          	jalr	-446(ra) # 80000ce6 <release>
    threadExitLast(status);
    80002eac:	854a                	mv	a0,s2
    80002eae:	00000097          	auipc	ra,0x0
    80002eb2:	ca4080e7          	jalr	-860(ra) # 80002b52 <threadExitLast>
    freethread(myT);
    80002eb6:	8526                	mv	a0,s1
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	3da080e7          	jalr	986(ra) # 80002292 <freethread>
}
    80002ec0:	70a2                	ld	ra,40(sp)
    80002ec2:	7402                	ld	s0,32(sp)
    80002ec4:	64e2                	ld	s1,24(sp)
    80002ec6:	6942                	ld	s2,16(sp)
    80002ec8:	69a2                	ld	s3,8(sp)
    80002eca:	6145                	addi	sp,sp,48
    80002ecc:	8082                	ret
    threadExitNotLast(status);
    80002ece:	854a                	mv	a0,s2
    80002ed0:	00000097          	auipc	ra,0x0
    80002ed4:	d7a080e7          	jalr	-646(ra) # 80002c4a <threadExitNotLast>

0000000080002ed8 <exit>:
{
    80002ed8:	7139                	addi	sp,sp,-64
    80002eda:	fc06                	sd	ra,56(sp)
    80002edc:	f822                	sd	s0,48(sp)
    80002ede:	f426                	sd	s1,40(sp)
    80002ee0:	f04a                	sd	s2,32(sp)
    80002ee2:	ec4e                	sd	s3,24(sp)
    80002ee4:	e852                	sd	s4,16(sp)
    80002ee6:	e456                	sd	s5,8(sp)
    80002ee8:	0080                	addi	s0,sp,64
    80002eea:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	c5a080e7          	jalr	-934(ra) # 80001b46 <myproc>
    80002ef4:	8a2a                	mv	s4,a0
  struct thread *myT=mythread();
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	bc6080e7          	jalr	-1082(ra) # 80001abc <mythread>
  if(p == initproc)
    80002efe:	00007797          	auipc	a5,0x7
    80002f02:	1327b783          	ld	a5,306(a5) # 8000a030 <initproc>
    80002f06:	03478363          	beq	a5,s4,80002f2c <exit+0x54>
    80002f0a:	89aa                	mv	s3,a0
  acquire(&p->lock);
    80002f0c:	8552                	mv	a0,s4
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	d24080e7          	jalr	-732(ra) # 80000c32 <acquire>
  for(tToCheck=p->threads; tToCheck<&p->threads[NTHREADS];tToCheck++)
    80002f16:	598a0493          	addi	s1,s4,1432
    80002f1a:	6905                	lui	s2,0x1
    80002f1c:	c5890913          	addi	s2,s2,-936 # c58 <_entry-0x7ffff3a8>
    80002f20:	9952                	add	s2,s2,s4
    80002f22:	87a6                	mv	a5,s1
      tToCheck->killed=1;
    80002f24:	4585                	li	a1,1
      if(tToCheck->state==SLEEPING)
    80002f26:	4609                	li	a2,2
        tToCheck->state=RUNNABLE;
    80002f28:	450d                	li	a0,3
    80002f2a:	a829                	j	80002f44 <exit+0x6c>
    panic("init exiting");
    80002f2c:	00006517          	auipc	a0,0x6
    80002f30:	3cc50513          	addi	a0,a0,972 # 800092f8 <digits+0x2b8>
    80002f34:	ffffd097          	auipc	ra,0xffffd
    80002f38:	5f6080e7          	jalr	1526(ra) # 8000052a <panic>
  for(tToCheck=p->threads; tToCheck<&p->threads[NTHREADS];tToCheck++)
    80002f3c:	0d878793          	addi	a5,a5,216
    80002f40:	02f90163          	beq	s2,a5,80002f62 <exit+0x8a>
    if(tToCheck->tid!=myT->tid)
    80002f44:	4394                	lw	a3,0(a5)
    80002f46:	0009a703          	lw	a4,0(s3)
    80002f4a:	fee689e3          	beq	a3,a4,80002f3c <exit+0x64>
      tToCheck->killed=1;
    80002f4e:	c7cc                	sw	a1,12(a5)
      if(tToCheck->state==SLEEPING)
    80002f50:	4798                	lw	a4,8(a5)
    80002f52:	fec715e3          	bne	a4,a2,80002f3c <exit+0x64>
        tToCheck->state=RUNNABLE;
    80002f56:	c788                	sw	a0,8(a5)
    80002f58:	b7d5                	j	80002f3c <exit+0x64>
  for (tToCheck = p->threads; tToCheck <&p->threads[NTHREADS]; tToCheck++)
    80002f5a:	0d848493          	addi	s1,s1,216
    80002f5e:	02990963          	beq	s2,s1,80002f90 <exit+0xb8>
    if(tToCheck->tid != myT->tid && tToCheck->tid!=0)
    80002f62:	409c                	lw	a5,0(s1)
    80002f64:	0009a703          	lw	a4,0(s3)
    80002f68:	fef709e3          	beq	a4,a5,80002f5a <exit+0x82>
    80002f6c:	d7fd                	beqz	a5,80002f5a <exit+0x82>
      release(&p->lock);
    80002f6e:	8552                	mv	a0,s4
    80002f70:	ffffe097          	auipc	ra,0xffffe
    80002f74:	d76080e7          	jalr	-650(ra) # 80000ce6 <release>
      kthread_join(tToCheck->tid,(int *)-1);
    80002f78:	55fd                	li	a1,-1
    80002f7a:	4088                	lw	a0,0(s1)
    80002f7c:	00000097          	auipc	ra,0x0
    80002f80:	e3e080e7          	jalr	-450(ra) # 80002dba <kthread_join>
      acquire(&p->lock);
    80002f84:	8552                	mv	a0,s4
    80002f86:	ffffe097          	auipc	ra,0xffffe
    80002f8a:	cac080e7          	jalr	-852(ra) # 80000c32 <acquire>
    80002f8e:	b7f1                	j	80002f5a <exit+0x82>
  int isLast=checkIfLastThread();
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	bf6080e7          	jalr	-1034(ra) # 80001b86 <checkIfLastThread>
  if(isLast)
    80002f98:	c919                	beqz	a0,80002fae <exit+0xd6>
    release(&p->lock);
    80002f9a:	8552                	mv	a0,s4
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	d4a080e7          	jalr	-694(ra) # 80000ce6 <release>
    threadExitLast(status);
    80002fa4:	8556                	mv	a0,s5
    80002fa6:	00000097          	auipc	ra,0x0
    80002faa:	bac080e7          	jalr	-1108(ra) # 80002b52 <threadExitLast>
    threadExitNotLast(status);
    80002fae:	8556                	mv	a0,s5
    80002fb0:	00000097          	auipc	ra,0x0
    80002fb4:	c9a080e7          	jalr	-870(ra) # 80002c4a <threadExitNotLast>

0000000080002fb8 <killThread>:
  if(t->state!=UNUSED && t->state!=ZOMBIE)
    80002fb8:	451c                	lw	a5,8(a0)
    80002fba:	cfb9                	beqz	a5,80003018 <killThread+0x60>
{
    80002fbc:	1101                	addi	sp,sp,-32
    80002fbe:	ec06                	sd	ra,24(sp)
    80002fc0:	e822                	sd	s0,16(sp)
    80002fc2:	e426                	sd	s1,8(sp)
    80002fc4:	e04a                	sd	s2,0(sp)
    80002fc6:	1000                	addi	s0,sp,32
    80002fc8:	84aa                	mv	s1,a0
    80002fca:	892e                	mv	s2,a1
  if(t->state!=UNUSED && t->state!=ZOMBIE)
    80002fcc:	4715                	li	a4,5
    80002fce:	00e79863          	bne	a5,a4,80002fde <killThread+0x26>
}
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	64a2                	ld	s1,8(sp)
    80002fd8:	6902                	ld	s2,0(sp)
    80002fda:	6105                	addi	sp,sp,32
    80002fdc:	8082                	ret
    acquire(&t->tlock);
    80002fde:	0a850513          	addi	a0,a0,168
    80002fe2:	ffffe097          	auipc	ra,0xffffe
    80002fe6:	c50080e7          	jalr	-944(ra) # 80000c32 <acquire>
    t->killed=1;
    80002fea:	4785                	li	a5,1
    80002fec:	c4dc                	sw	a5,12(s1)
    t->xstate = status;
    80002fee:	0d24a023          	sw	s2,192(s1)
    t->state=ZOMBIE;
    80002ff2:	4795                	li	a5,5
    80002ff4:	c49c                	sw	a5,8(s1)
    wakeup(t);
    80002ff6:	8526                	mv	a0,s1
    80002ff8:	00000097          	auipc	ra,0x0
    80002ffc:	a40080e7          	jalr	-1472(ra) # 80002a38 <wakeup>
    sched();
    80003000:	fffff097          	auipc	ra,0xfffff
    80003004:	6f6080e7          	jalr	1782(ra) # 800026f6 <sched>
    panic("Kill thread");
    80003008:	00006517          	auipc	a0,0x6
    8000300c:	2e050513          	addi	a0,a0,736 # 800092e8 <digits+0x2a8>
    80003010:	ffffd097          	auipc	ra,0xffffd
    80003014:	51a080e7          	jalr	1306(ra) # 8000052a <panic>
    80003018:	8082                	ret

000000008000301a <kill>:
  if(signum<0 || signum>31)
    8000301a:	47fd                	li	a5,31
    8000301c:	14b7e763          	bltu	a5,a1,8000316a <kill+0x150>
{
    80003020:	7139                	addi	sp,sp,-64
    80003022:	fc06                	sd	ra,56(sp)
    80003024:	f822                	sd	s0,48(sp)
    80003026:	f426                	sd	s1,40(sp)
    80003028:	f04a                	sd	s2,32(sp)
    8000302a:	ec4e                	sd	s3,24(sp)
    8000302c:	e852                	sd	s4,16(sp)
    8000302e:	e456                	sd	s5,8(sp)
    80003030:	e05a                	sd	s6,0(sp)
    80003032:	0080                	addi	s0,sp,64
    80003034:	892a                	mv	s2,a0
    80003036:	8b2e                	mv	s6,a1
  for(p = proc; p < &proc[NPROC]; p++){
    80003038:	00010497          	auipc	s1,0x10
    8000303c:	6f048493          	addi	s1,s1,1776 # 80013728 <proc>
    80003040:	6a05                	lui	s4,0x1
    80003042:	c90a0a13          	addi	s4,s4,-880 # c90 <_entry-0x7ffff370>
    80003046:	00043a97          	auipc	s5,0x43
    8000304a:	ae2a8a93          	addi	s5,s5,-1310 # 80045b28 <tickslock>
    acquire(&p->lock);
    8000304e:	8526                	mv	a0,s1
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	be2080e7          	jalr	-1054(ra) # 80000c32 <acquire>
    if(p->pid == pid){
    80003058:	50dc                	lw	a5,36(s1)
    8000305a:	01278c63          	beq	a5,s2,80003072 <kill+0x58>
    release(&p->lock);
    8000305e:	8526                	mv	a0,s1
    80003060:	ffffe097          	auipc	ra,0xffffe
    80003064:	c86080e7          	jalr	-890(ra) # 80000ce6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003068:	94d2                	add	s1,s1,s4
    8000306a:	ff5492e3          	bne	s1,s5,8000304e <kill+0x34>
  return -1;
    8000306e:	557d                	li	a0,-1
    80003070:	a0bd                	j	800030de <kill+0xc4>
      if(signum==SIGKILL)
    80003072:	47a5                	li	a5,9
    80003074:	06fb0f63          	beq	s6,a5,800030f2 <kill+0xd8>
      p->PendingSignals = p->PendingSignals | (1<<signum);
    80003078:	4785                	li	a5,1
    8000307a:	016797bb          	sllw	a5,a5,s6
    8000307e:	0e04ab03          	lw	s6,224(s1)
    80003082:	00fb6b33          	or	s6,s6,a5
    80003086:	0f64a023          	sw	s6,224(s1)
      for (t = p->threads; t<&p->threads[NTHREADS]; t++)
    8000308a:	59848913          	addi	s2,s1,1432
    8000308e:	6a85                	lui	s5,0x1
    80003090:	c58a8a93          	addi	s5,s5,-936 # c58 <_entry-0x7ffff3a8>
    80003094:	9aa6                	add	s5,s5,s1
  for(p = proc; p < &proc[NPROC]; p++){
    80003096:	87ca                	mv	a5,s2
        if(t->state == RUNNABLE){
    80003098:	468d                	li	a3,3
    8000309a:	4798                	lw	a4,8(a5)
    8000309c:	0ad70163          	beq	a4,a3,8000313e <kill+0x124>
      for (t = p->threads; t<&p->threads[NTHREADS]; t++)
    800030a0:	0d878793          	addi	a5,a5,216
    800030a4:	ff57ebe3          	bltu	a5,s5,8000309a <kill+0x80>
        if(t->state == SLEEPING){
    800030a8:	4a09                	li	s4,2
        acquire(&t->tlock);
    800030aa:	0a890993          	addi	s3,s2,168
    800030ae:	854e                	mv	a0,s3
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	b82080e7          	jalr	-1150(ra) # 80000c32 <acquire>
        if(t->state == SLEEPING){
    800030b8:	00892783          	lw	a5,8(s2)
    800030bc:	09478863          	beq	a5,s4,8000314c <kill+0x132>
        release(&t->tlock);
    800030c0:	854e                	mv	a0,s3
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	c24080e7          	jalr	-988(ra) # 80000ce6 <release>
      for (t = p->threads; t<&p->threads[NTHREADS]; t++)
    800030ca:	0d890913          	addi	s2,s2,216
    800030ce:	fd596ee3          	bltu	s2,s5,800030aa <kill+0x90>
      release(&p->lock);
    800030d2:	8526                	mv	a0,s1
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	c12080e7          	jalr	-1006(ra) # 80000ce6 <release>
      return -1;
    800030dc:	557d                	li	a0,-1
}
    800030de:	70e2                	ld	ra,56(sp)
    800030e0:	7442                	ld	s0,48(sp)
    800030e2:	74a2                	ld	s1,40(sp)
    800030e4:	7902                	ld	s2,32(sp)
    800030e6:	69e2                	ld	s3,24(sp)
    800030e8:	6a42                	ld	s4,16(sp)
    800030ea:	6aa2                	ld	s5,8(sp)
    800030ec:	6b02                	ld	s6,0(sp)
    800030ee:	6121                	addi	sp,sp,64
    800030f0:	8082                	ret
        p->killed=1;
    800030f2:	4785                	li	a5,1
    800030f4:	ccdc                	sw	a5,28(s1)
        for (t = p->threads; t<&p->threads[NTHREADS]; t++)
    800030f6:	59848913          	addi	s2,s1,1432
    800030fa:	6785                	lui	a5,0x1
    800030fc:	c5878a93          	addi	s5,a5,-936 # c58 <_entry-0x7ffff3a8>
    80003100:	9aa6                	add	s5,s5,s1
    80003102:	64048a13          	addi	s4,s1,1600
    80003106:	d0078793          	addi	a5,a5,-768
    8000310a:	00f489b3          	add	s3,s1,a5
          t->killed=1;
    8000310e:	4b05                	li	s6,1
          acquire(&t->tlock);
    80003110:	8552                	mv	a0,s4
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	b20080e7          	jalr	-1248(ra) # 80000c32 <acquire>
          t->killed=1;
    8000311a:	f76a2223          	sw	s6,-156(s4)
          release(&t->tlock);
    8000311e:	8552                	mv	a0,s4
    80003120:	ffffe097          	auipc	ra,0xffffe
    80003124:	bc6080e7          	jalr	-1082(ra) # 80000ce6 <release>
        for (t = p->threads; t<&p->threads[NTHREADS]; t++)
    80003128:	0d8a0a13          	addi	s4,s4,216
    8000312c:	ff3a12e3          	bne	s4,s3,80003110 <kill+0xf6>
      p->PendingSignals = p->PendingSignals | (1<<signum);
    80003130:	0e04a783          	lw	a5,224(s1)
    80003134:	2007e793          	ori	a5,a5,512
    80003138:	0ef4a023          	sw	a5,224(s1)
      for (t = p->threads; t<&p->threads[NTHREADS]; t++)
    8000313c:	bfa9                	j	80003096 <kill+0x7c>
          release(&p->lock);
    8000313e:	8526                	mv	a0,s1
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	ba6080e7          	jalr	-1114(ra) # 80000ce6 <release>
          return 0;
    80003148:	4501                	li	a0,0
    8000314a:	bf51                	j	800030de <kill+0xc4>
          t->state = RUNNABLE;
    8000314c:	478d                	li	a5,3
    8000314e:	00f92423          	sw	a5,8(s2)
          release(&t->tlock);
    80003152:	854e                	mv	a0,s3
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	b92080e7          	jalr	-1134(ra) # 80000ce6 <release>
          release(&p->lock);
    8000315c:	8526                	mv	a0,s1
    8000315e:	ffffe097          	auipc	ra,0xffffe
    80003162:	b88080e7          	jalr	-1144(ra) # 80000ce6 <release>
          return 0;
    80003166:	4501                	li	a0,0
    80003168:	bf9d                	j	800030de <kill+0xc4>
    return -1;
    8000316a:	557d                	li	a0,-1
}
    8000316c:	8082                	ret

000000008000316e <either_copyout>:
{
    8000316e:	7179                	addi	sp,sp,-48
    80003170:	f406                	sd	ra,40(sp)
    80003172:	f022                	sd	s0,32(sp)
    80003174:	ec26                	sd	s1,24(sp)
    80003176:	e84a                	sd	s2,16(sp)
    80003178:	e44e                	sd	s3,8(sp)
    8000317a:	e052                	sd	s4,0(sp)
    8000317c:	1800                	addi	s0,sp,48
    8000317e:	84aa                	mv	s1,a0
    80003180:	892e                	mv	s2,a1
    80003182:	89b2                	mv	s3,a2
    80003184:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003186:	fffff097          	auipc	ra,0xfffff
    8000318a:	9c0080e7          	jalr	-1600(ra) # 80001b46 <myproc>
  if(user_dst){
    8000318e:	c08d                	beqz	s1,800031b0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80003190:	86d2                	mv	a3,s4
    80003192:	864e                	mv	a2,s3
    80003194:	85ca                	mv	a1,s2
    80003196:	7d08                	ld	a0,56(a0)
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	532080e7          	jalr	1330(ra) # 800016ca <copyout>
}
    800031a0:	70a2                	ld	ra,40(sp)
    800031a2:	7402                	ld	s0,32(sp)
    800031a4:	64e2                	ld	s1,24(sp)
    800031a6:	6942                	ld	s2,16(sp)
    800031a8:	69a2                	ld	s3,8(sp)
    800031aa:	6a02                	ld	s4,0(sp)
    800031ac:	6145                	addi	sp,sp,48
    800031ae:	8082                	ret
    memmove((char *)dst, src, len);
    800031b0:	000a061b          	sext.w	a2,s4
    800031b4:	85ce                	mv	a1,s3
    800031b6:	854a                	mv	a0,s2
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	bee080e7          	jalr	-1042(ra) # 80000da6 <memmove>
    return 0;
    800031c0:	8526                	mv	a0,s1
    800031c2:	bff9                	j	800031a0 <either_copyout+0x32>

00000000800031c4 <either_copyin>:
{
    800031c4:	7179                	addi	sp,sp,-48
    800031c6:	f406                	sd	ra,40(sp)
    800031c8:	f022                	sd	s0,32(sp)
    800031ca:	ec26                	sd	s1,24(sp)
    800031cc:	e84a                	sd	s2,16(sp)
    800031ce:	e44e                	sd	s3,8(sp)
    800031d0:	e052                	sd	s4,0(sp)
    800031d2:	1800                	addi	s0,sp,48
    800031d4:	892a                	mv	s2,a0
    800031d6:	84ae                	mv	s1,a1
    800031d8:	89b2                	mv	s3,a2
    800031da:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800031dc:	fffff097          	auipc	ra,0xfffff
    800031e0:	96a080e7          	jalr	-1686(ra) # 80001b46 <myproc>
  if(user_src){
    800031e4:	c08d                	beqz	s1,80003206 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800031e6:	86d2                	mv	a3,s4
    800031e8:	864e                	mv	a2,s3
    800031ea:	85ca                	mv	a1,s2
    800031ec:	7d08                	ld	a0,56(a0)
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	568080e7          	jalr	1384(ra) # 80001756 <copyin>
}
    800031f6:	70a2                	ld	ra,40(sp)
    800031f8:	7402                	ld	s0,32(sp)
    800031fa:	64e2                	ld	s1,24(sp)
    800031fc:	6942                	ld	s2,16(sp)
    800031fe:	69a2                	ld	s3,8(sp)
    80003200:	6a02                	ld	s4,0(sp)
    80003202:	6145                	addi	sp,sp,48
    80003204:	8082                	ret
    memmove(dst, (char*)src, len);
    80003206:	000a061b          	sext.w	a2,s4
    8000320a:	85ce                	mv	a1,s3
    8000320c:	854a                	mv	a0,s2
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	b98080e7          	jalr	-1128(ra) # 80000da6 <memmove>
    return 0;
    80003216:	8526                	mv	a0,s1
    80003218:	bff9                	j	800031f6 <either_copyin+0x32>

000000008000321a <procdump>:
{
    8000321a:	1141                	addi	sp,sp,-16
    8000321c:	e422                	sd	s0,8(sp)
    8000321e:	0800                	addi	s0,sp,16
}
    80003220:	6422                	ld	s0,8(sp)
    80003222:	0141                	addi	sp,sp,16
    80003224:	8082                	ret

0000000080003226 <sigprocmask>:
{
    80003226:	1101                	addi	sp,sp,-32
    80003228:	ec06                	sd	ra,24(sp)
    8000322a:	e822                	sd	s0,16(sp)
    8000322c:	e426                	sd	s1,8(sp)
    8000322e:	1000                	addi	s0,sp,32
    80003230:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003232:	fffff097          	auipc	ra,0xfffff
    80003236:	914080e7          	jalr	-1772(ra) # 80001b46 <myproc>
    8000323a:	872a                	mv	a4,a0
  uint temp = p->SignalMask;
    8000323c:	0e452503          	lw	a0,228(a0)
  if((mask & (1<<SIGSTOP)) || (mask & (1<<SIGKILL)) )
    80003240:	000207b7          	lui	a5,0x20
    80003244:	20078793          	addi	a5,a5,512 # 20200 <_entry-0x7ffdfe00>
    80003248:	8fe5                	and	a5,a5,s1
    8000324a:	e399                	bnez	a5,80003250 <sigprocmask+0x2a>
    p->SignalMask = mask;
    8000324c:	0e972223          	sw	s1,228(a4)
}
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	64a2                	ld	s1,8(sp)
    80003256:	6105                	addi	sp,sp,32
    80003258:	8082                	ret

000000008000325a <sigaction>:
{
    8000325a:	7139                	addi	sp,sp,-64
    8000325c:	fc06                	sd	ra,56(sp)
    8000325e:	f822                	sd	s0,48(sp)
    80003260:	f426                	sd	s1,40(sp)
    80003262:	f04a                	sd	s2,32(sp)
    80003264:	ec4e                	sd	s3,24(sp)
    80003266:	e852                	sd	s4,16(sp)
    80003268:	e456                	sd	s5,8(sp)
    8000326a:	e05a                	sd	s6,0(sp)
    8000326c:	0080                	addi	s0,sp,64
    8000326e:	84aa                	mv	s1,a0
    80003270:	89ae                	mv	s3,a1
    80003272:	8a32                	mv	s4,a2
  struct proc *p = myproc();
    80003274:	fffff097          	auipc	ra,0xfffff
    80003278:	8d2080e7          	jalr	-1838(ra) # 80001b46 <myproc>
  if(signum<0 || signum>32)
    8000327c:	0004879b          	sext.w	a5,s1
    80003280:	02000713          	li	a4,32
    80003284:	08f76263          	bltu	a4,a5,80003308 <sigaction+0xae>
    80003288:	892a                	mv	s2,a0
  if(signum==SIGKILL || signum == SIGSTOP)
    8000328a:	37dd                	addiw	a5,a5,-9
    8000328c:	9bdd                	andi	a5,a5,-9
    8000328e:	2781                	sext.w	a5,a5
    80003290:	cfb5                	beqz	a5,8000330c <sigaction+0xb2>
  if(oldact!=0)
    80003292:	000a0d63          	beqz	s4,800032ac <sigaction+0x52>
    char* srcptr= (char*) &(p->Sigactions[signum]);
    80003296:	01f48613          	addi	a2,s1,31
    8000329a:	0612                	slli	a2,a2,0x4
    copyout(p->pagetable,(uint64)oldact,srcptr,sizeof(struct sigaction));
    8000329c:	46c1                	li	a3,16
    8000329e:	962a                	add	a2,a2,a0
    800032a0:	85d2                	mv	a1,s4
    800032a2:	7d08                	ld	a0,56(a0)
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	426080e7          	jalr	1062(ra) # 800016ca <copyout>
  return 0;
    800032ac:	4501                	li	a0,0
  if(act != 0) //act not null
    800032ae:	02098d63          	beqz	s3,800032e8 <sigaction+0x8e>
    struct sigaction tempAction=(p->Sigactions[signum]);
    800032b2:	00449a13          	slli	s4,s1,0x4
    800032b6:	9a4a                	add	s4,s4,s2
    800032b8:	1f0a3b03          	ld	s6,496(s4)
    800032bc:	1f8a2a83          	lw	s5,504(s4)
    char* dstptr= (char*) &(p->Sigactions[signum]);
    800032c0:	04fd                	addi	s1,s1,31
    800032c2:	0492                	slli	s1,s1,0x4
    800032c4:	94ca                	add	s1,s1,s2
    copyin(p->pagetable,dstptr,(uint64)act,sizeof(struct sigaction));
    800032c6:	46c1                	li	a3,16
    800032c8:	864e                	mv	a2,s3
    800032ca:	85a6                	mv	a1,s1
    800032cc:	03893503          	ld	a0,56(s2)
    800032d0:	ffffe097          	auipc	ra,0xffffe
    800032d4:	486080e7          	jalr	1158(ra) # 80001756 <copyin>
    if((actPtr->sigmask & (1 << SIGSTOP)) || (actPtr->sigmask & (1 << SIGKILL)))
    800032d8:	649c                	ld	a5,8(s1)
    800032da:	00020737          	lui	a4,0x20
    800032de:	20070713          	addi	a4,a4,512 # 20200 <_entry-0x7ffdfe00>
    800032e2:	8ff9                	and	a5,a5,a4
  return 0;
    800032e4:	4501                	li	a0,0
    if((actPtr->sigmask & (1 << SIGSTOP)) || (actPtr->sigmask & (1 << SIGKILL)))
    800032e6:	eb99                	bnez	a5,800032fc <sigaction+0xa2>
}
    800032e8:	70e2                	ld	ra,56(sp)
    800032ea:	7442                	ld	s0,48(sp)
    800032ec:	74a2                	ld	s1,40(sp)
    800032ee:	7902                	ld	s2,32(sp)
    800032f0:	69e2                	ld	s3,24(sp)
    800032f2:	6a42                	ld	s4,16(sp)
    800032f4:	6aa2                	ld	s5,8(sp)
    800032f6:	6b02                	ld	s6,0(sp)
    800032f8:	6121                	addi	sp,sp,64
    800032fa:	8082                	ret
      *actPtr=tempAction;
    800032fc:	1f6a3823          	sd	s6,496(s4)
    80003300:	1f5a2c23          	sw	s5,504(s4)
      return -1;
    80003304:	557d                	li	a0,-1
    80003306:	b7cd                	j	800032e8 <sigaction+0x8e>
    return -1;
    80003308:	557d                	li	a0,-1
    8000330a:	bff9                	j	800032e8 <sigaction+0x8e>
    return -1;
    8000330c:	557d                	li	a0,-1
    8000330e:	bfe9                	j	800032e8 <sigaction+0x8e>

0000000080003310 <sigret>:
{
    80003310:	1101                	addi	sp,sp,-32
    80003312:	ec06                	sd	ra,24(sp)
    80003314:	e822                	sd	s0,16(sp)
    80003316:	e426                	sd	s1,8(sp)
    80003318:	1000                	addi	s0,sp,32
  struct thread *t= mythread();
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	7a2080e7          	jalr	1954(ra) # 80001abc <mythread>
    80003322:	84aa                	mv	s1,a0
  struct proc *p= myproc();
    80003324:	fffff097          	auipc	ra,0xfffff
    80003328:	822080e7          	jalr	-2014(ra) # 80001b46 <myproc>
  memmove(t->trapeframe,&(p->UserTrapFrameBackup),sizeof(struct trapframe));
    8000332c:	12000613          	li	a2,288
    80003330:	47050593          	addi	a1,a0,1136
    80003334:	7088                	ld	a0,32(s1)
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	a70080e7          	jalr	-1424(ra) # 80000da6 <memmove>
}
    8000333e:	60e2                	ld	ra,24(sp)
    80003340:	6442                	ld	s0,16(sp)
    80003342:	64a2                	ld	s1,8(sp)
    80003344:	6105                	addi	sp,sp,32
    80003346:	8082                	ret

0000000080003348 <stopprocess>:
{
    80003348:	1141                	addi	sp,sp,-16
    8000334a:	e422                	sd	s0,8(sp)
    8000334c:	0800                	addi	s0,sp,16
  p->stopped=1;
    8000334e:	4785                	li	a5,1
    80003350:	58f52823          	sw	a5,1424(a0)
}
    80003354:	6422                	ld	s0,8(sp)
    80003356:	0141                	addi	sp,sp,16
    80003358:	8082                	ret

000000008000335a <contprocess>:
{
    8000335a:	1141                	addi	sp,sp,-16
    8000335c:	e422                	sd	s0,8(sp)
    8000335e:	0800                	addi	s0,sp,16
  p->stopped=0;
    80003360:	58052823          	sw	zero,1424(a0)
}
    80003364:	6422                	ld	s0,8(sp)
    80003366:	0141                	addi	sp,sp,16
    80003368:	8082                	ret

000000008000336a <killprocess>:

void
killprocess(struct proc* p)
{
    8000336a:	1141                	addi	sp,sp,-16
    8000336c:	e406                	sd	ra,8(sp)
    8000336e:	e022                	sd	s0,0(sp)
    80003370:	0800                	addi	s0,sp,16
  p->killed=1;
    80003372:	4785                	li	a5,1
    80003374:	cd5c                	sw	a5,28(a0)
  exit(0);
    80003376:	4501                	li	a0,0
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	b60080e7          	jalr	-1184(ra) # 80002ed8 <exit>

0000000080003380 <defaultHandlerForSignal>:
  if(signum==SIGSTOP)
    80003380:	47c5                	li	a5,17
    80003382:	02f58063          	beq	a1,a5,800033a2 <defaultHandlerForSignal+0x22>
  else if(signum==SIGCONT)
    80003386:	47cd                	li	a5,19
    80003388:	02f58163          	beq	a1,a5,800033aa <defaultHandlerForSignal+0x2a>
{
    8000338c:	1141                	addi	sp,sp,-16
    8000338e:	e406                	sd	ra,8(sp)
    80003390:	e022                	sd	s0,0(sp)
    80003392:	0800                	addi	s0,sp,16
  else if (signum==SIGKILL)
    80003394:	47a5                	li	a5,9
    80003396:	00f58d63          	beq	a1,a5,800033b0 <defaultHandlerForSignal+0x30>
    killprocess(p);
    8000339a:	00000097          	auipc	ra,0x0
    8000339e:	fd0080e7          	jalr	-48(ra) # 8000336a <killprocess>
  p->stopped=1;
    800033a2:	4785                	li	a5,1
    800033a4:	58f52823          	sw	a5,1424(a0)
}
    800033a8:	8082                	ret
  p->stopped=0;
    800033aa:	58052823          	sw	zero,1424(a0)
    800033ae:	8082                	ret
    killprocess(p);
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	fba080e7          	jalr	-70(ra) # 8000336a <killprocess>

00000000800033b8 <handlePendingSignal>:
  p->TempMask=p->SignalMask;
    800033b8:	0e452783          	lw	a5,228(a0)
    800033bc:	0ef52423          	sw	a5,232(a0)
  p->SignalMask=action->sigmask;
    800033c0:	00459793          	slli	a5,a1,0x4
    800033c4:	97aa                	add	a5,a5,a0
    800033c6:	1f87a703          	lw	a4,504(a5)
    800033ca:	0ee52223          	sw	a4,228(a0)
  if(p->Sigactions[signum].sa_handler==(void*)SIG_IGN)
    800033ce:	1f07b783          	ld	a5,496(a5)
    800033d2:	4705                	li	a4,1
    800033d4:	06e78763          	beq	a5,a4,80003442 <handlePendingSignal+0x8a>
{
    800033d8:	1101                	addi	sp,sp,-32
    800033da:	ec06                	sd	ra,24(sp)
    800033dc:	e822                	sd	s0,16(sp)
    800033de:	e426                	sd	s1,8(sp)
    800033e0:	e04a                	sd	s2,0(sp)
    800033e2:	1000                	addi	s0,sp,32
    800033e4:	84aa                	mv	s1,a0
    800033e6:	892e                	mv	s2,a1
    if(p->Sigactions[signum].sa_handler==(void*)SIG_DFL)
    800033e8:	cf8d                	beqz	a5,80003422 <handlePendingSignal+0x6a>
      if(p->Sigactions[signum].sa_handler==(void*)SIGKILL)
    800033ea:	4725                	li	a4,9
    800033ec:	04e78063          	beq	a5,a4,8000342c <handlePendingSignal+0x74>
        if(p->Sigactions[signum].sa_handler==(void*)SIGSTOP)
    800033f0:	4745                	li	a4,17
    800033f2:	04e78163          	beq	a5,a4,80003434 <handlePendingSignal+0x7c>
          if(p->Sigactions[signum].sa_handler==(void*)SIGCONT)
    800033f6:	474d                	li	a4,19
    800033f8:	04e78263          	beq	a5,a4,8000343c <handlePendingSignal+0x84>
            handldeUserHandler(p, signum);
    800033fc:	fffff097          	auipc	ra,0xfffff
    80003400:	25c080e7          	jalr	604(ra) # 80002658 <handldeUserHandler>
  p->PendingSignals = p->PendingSignals^(1<<signum);
    80003404:	4585                	li	a1,1
    80003406:	012595bb          	sllw	a1,a1,s2
    8000340a:	0e04a903          	lw	s2,224(s1)
    8000340e:	00b94933          	xor	s2,s2,a1
    80003412:	0f24a023          	sw	s2,224(s1)
}
    80003416:	60e2                	ld	ra,24(sp)
    80003418:	6442                	ld	s0,16(sp)
    8000341a:	64a2                	ld	s1,8(sp)
    8000341c:	6902                	ld	s2,0(sp)
    8000341e:	6105                	addi	sp,sp,32
    80003420:	8082                	ret
      defaultHandlerForSignal(p, signum);
    80003422:	00000097          	auipc	ra,0x0
    80003426:	f5e080e7          	jalr	-162(ra) # 80003380 <defaultHandlerForSignal>
    8000342a:	bfe9                	j	80003404 <handlePendingSignal+0x4c>
        killprocess(p);
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	f3e080e7          	jalr	-194(ra) # 8000336a <killprocess>
  p->stopped=1;
    80003434:	4785                	li	a5,1
    80003436:	58f52823          	sw	a5,1424(a0)
}
    8000343a:	b7e9                	j	80003404 <handlePendingSignal+0x4c>
  p->stopped=0;
    8000343c:	58052823          	sw	zero,1424(a0)
}
    80003440:	b7d1                	j	80003404 <handlePendingSignal+0x4c>
    80003442:	8082                	ret

0000000080003444 <checkSignalsForProcess>:
{
    80003444:	7179                	addi	sp,sp,-48
    80003446:	f406                	sd	ra,40(sp)
    80003448:	f022                	sd	s0,32(sp)
    8000344a:	ec26                	sd	s1,24(sp)
    8000344c:	e84a                	sd	s2,16(sp)
    8000344e:	e44e                	sd	s3,8(sp)
    80003450:	e052                	sd	s4,0(sp)
    80003452:	1800                	addi	s0,sp,48
    80003454:	892a                	mv	s2,a0
    checkIfStopped(p);
    80003456:	fffff097          	auipc	ra,0xfffff
    8000345a:	3f6080e7          	jalr	1014(ra) # 8000284c <checkIfStopped>
    if(!p->stopped)
    8000345e:	59092483          	lw	s1,1424(s2)
    80003462:	e89d                	bnez	s1,80003498 <checkSignalsForProcess+0x54>
        if(!(p->SignalMask & (1<<i)))
    80003464:	4a05                	li	s4,1
      for (int i = 0; i <= 31; i++)
    80003466:	02000993          	li	s3,32
    8000346a:	a021                	j	80003472 <checkSignalsForProcess+0x2e>
    8000346c:	2485                	addiw	s1,s1,1
    8000346e:	03348563          	beq	s1,s3,80003498 <checkSignalsForProcess+0x54>
        if(!(p->SignalMask & (1<<i)))
    80003472:	009a173b          	sllw	a4,s4,s1
    80003476:	0e492783          	lw	a5,228(s2)
    8000347a:	8ff9                	and	a5,a5,a4
    8000347c:	2781                	sext.w	a5,a5
    8000347e:	f7fd                	bnez	a5,8000346c <checkSignalsForProcess+0x28>
          if(p->PendingSignals & (1<<i))
    80003480:	0e092783          	lw	a5,224(s2)
    80003484:	8ff9                	and	a5,a5,a4
    80003486:	2781                	sext.w	a5,a5
    80003488:	d3f5                	beqz	a5,8000346c <checkSignalsForProcess+0x28>
              handlePendingSignal(p,i);
    8000348a:	85a6                	mv	a1,s1
    8000348c:	854a                	mv	a0,s2
    8000348e:	00000097          	auipc	ra,0x0
    80003492:	f2a080e7          	jalr	-214(ra) # 800033b8 <handlePendingSignal>
    80003496:	bfd9                	j	8000346c <checkSignalsForProcess+0x28>
}
    80003498:	70a2                	ld	ra,40(sp)
    8000349a:	7402                	ld	s0,32(sp)
    8000349c:	64e2                	ld	s1,24(sp)
    8000349e:	6942                	ld	s2,16(sp)
    800034a0:	69a2                	ld	s3,8(sp)
    800034a2:	6a02                	ld	s4,0(sp)
    800034a4:	6145                	addi	sp,sp,48
    800034a6:	8082                	ret

00000000800034a8 <KillOtherThreads>:
}


int KillOtherThreads(struct proc *p)
{
    800034a8:	1101                	addi	sp,sp,-32
    800034aa:	ec06                	sd	ra,24(sp)
    800034ac:	e822                	sd	s0,16(sp)
    800034ae:	e426                	sd	s1,8(sp)
    800034b0:	1000                	addi	s0,sp,32
    800034b2:	84aa                	mv	s1,a0
  struct thread *myT= mythread();
    800034b4:	ffffe097          	auipc	ra,0xffffe
    800034b8:	608080e7          	jalr	1544(ra) # 80001abc <mythread>
    800034bc:	85aa                	mv	a1,a0
  struct thread *t;
  if(myT->killed==1)
    800034be:	4548                	lw	a0,12(a0)
    800034c0:	4785                	li	a5,1
    800034c2:	04f50163          	beq	a0,a5,80003504 <KillOtherThreads+0x5c>
  {
    return 1;
  }

  for (t= p->threads; t < &p->threads[NTHREADS]; t++)
    800034c6:	59848793          	addi	a5,s1,1432
    800034ca:	6605                	lui	a2,0x1
    800034cc:	c5860613          	addi	a2,a2,-936 # c58 <_entry-0x7ffff3a8>
    800034d0:	9626                	add	a2,a2,s1
  {
    if(t->tid!=myT->tid && t->state!=ZOMBIE && t->state != UNUSED)
    800034d2:	4515                	li	a0,5
    {
      t->killed=1;
    800034d4:	4885                	li	a7,1
      if(t->state==SLEEPING)
    800034d6:	4809                	li	a6,2
      {
        t->state=RUNNABLE;
    800034d8:	430d                	li	t1,3
    800034da:	a029                	j	800034e4 <KillOtherThreads+0x3c>
  for (t= p->threads; t < &p->threads[NTHREADS]; t++)
    800034dc:	0d878793          	addi	a5,a5,216
    800034e0:	02f60163          	beq	a2,a5,80003502 <KillOtherThreads+0x5a>
    if(t->tid!=myT->tid && t->state!=ZOMBIE && t->state != UNUSED)
    800034e4:	4394                	lw	a3,0(a5)
    800034e6:	4198                	lw	a4,0(a1)
    800034e8:	fee68ae3          	beq	a3,a4,800034dc <KillOtherThreads+0x34>
    800034ec:	4798                	lw	a4,8(a5)
    800034ee:	fea707e3          	beq	a4,a0,800034dc <KillOtherThreads+0x34>
    800034f2:	d76d                	beqz	a4,800034dc <KillOtherThreads+0x34>
      t->killed=1;
    800034f4:	0117a623          	sw	a7,12(a5)
      if(t->state==SLEEPING)
    800034f8:	ff0712e3          	bne	a4,a6,800034dc <KillOtherThreads+0x34>
        t->state=RUNNABLE;
    800034fc:	0067a423          	sw	t1,8(a5)
    80003500:	bff1                	j	800034dc <KillOtherThreads+0x34>
      }
    }
  }
  
  return 0;
    80003502:	4501                	li	a0,0
}
    80003504:	60e2                	ld	ra,24(sp)
    80003506:	6442                	ld	s0,16(sp)
    80003508:	64a2                	ld	s1,8(sp)
    8000350a:	6105                	addi	sp,sp,32
    8000350c:	8082                	ret

000000008000350e <allocBsem>:

//Bsems
int allocBsem()
{
    8000350e:	7139                	addi	sp,sp,-64
    80003510:	fc06                	sd	ra,56(sp)
    80003512:	f822                	sd	s0,48(sp)
    80003514:	f426                	sd	s1,40(sp)
    80003516:	f04a                	sd	s2,32(sp)
    80003518:	ec4e                	sd	s3,24(sp)
    8000351a:	e852                	sd	s4,16(sp)
    8000351c:	e456                	sd	s5,8(sp)
    8000351e:	e05a                	sd	s6,0(sp)
    80003520:	0080                	addi	s0,sp,64
  int sema_id=-1;
  int found=0;
  if(!isSemaphoresAllocated)
    80003522:	00007797          	auipc	a5,0x7
    80003526:	b0a7a783          	lw	a5,-1270(a5) # 8000a02c <isSemaphoresAllocated>
    8000352a:	c395                	beqz	a5,8000354e <allocBsem+0x40>
    }
    isSemaphoresAllocated=1;
    release(&semaphores_lock);
  }

  acquire(&semaphores_lock);
    8000352c:	0000f517          	auipc	a0,0xf
    80003530:	1e450513          	addi	a0,a0,484 # 80012710 <semaphores_lock>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	6fe080e7          	jalr	1790(ra) # 80000c32 <acquire>
  for (int i = 0; i < MAX_BSEM && found==0; i++)
    8000353c:	0000f497          	auipc	s1,0xf
    80003540:	1f448493          	addi	s1,s1,500 # 80012730 <semaphores+0x8>
    80003544:	4901                	li	s2,0
  {
    acquire(&semaphores[i].sema_lock);
    if(semaphores[i].available==1)
    80003546:	4a85                	li	s5,1
  for (int i = 0; i < MAX_BSEM && found==0; i++)
    80003548:	08000b13          	li	s6,128
    8000354c:	a0ed                	j	80003636 <allocBsem+0x128>
    initlock(&semaphores_lock,"semaphores_lock");
    8000354e:	0000f497          	auipc	s1,0xf
    80003552:	1c248493          	addi	s1,s1,450 # 80012710 <semaphores_lock>
    80003556:	00006597          	auipc	a1,0x6
    8000355a:	db258593          	addi	a1,a1,-590 # 80009308 <digits+0x2c8>
    8000355e:	8526                	mv	a0,s1
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	5f2080e7          	jalr	1522(ra) # 80000b52 <initlock>
    acquire(&semaphores_lock);
    80003568:	8526                	mv	a0,s1
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	6c8080e7          	jalr	1736(ra) # 80000c32 <acquire>
    for (int i = 0; i < MAX_BSEM; i++)
    80003572:	0000f497          	auipc	s1,0xf
    80003576:	1be48493          	addi	s1,s1,446 # 80012730 <semaphores+0x8>
    8000357a:	00010a17          	auipc	s4,0x10
    8000357e:	1b6a0a13          	addi	s4,s4,438 # 80013730 <proc+0x8>
      initlock(&semaphores[i].sema_lock,"sema_lock");
    80003582:	00006997          	auipc	s3,0x6
    80003586:	d9698993          	addi	s3,s3,-618 # 80009318 <digits+0x2d8>
      semaphores[i].available=1;
    8000358a:	4905                	li	s2,1
      initlock(&semaphores[i].sema_lock,"sema_lock");
    8000358c:	85ce                	mv	a1,s3
    8000358e:	8526                	mv	a0,s1
    80003590:	ffffd097          	auipc	ra,0xffffd
    80003594:	5c2080e7          	jalr	1474(ra) # 80000b52 <initlock>
      acquire(&semaphores[i].sema_lock);
    80003598:	8526                	mv	a0,s1
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	698080e7          	jalr	1688(ra) # 80000c32 <acquire>
      semaphores[i].available=1;
    800035a2:	ff24ac23          	sw	s2,-8(s1)
      semaphores[i].value=1;
    800035a6:	ff24ae23          	sw	s2,-4(s1)
      release(&semaphores[i].sema_lock);
    800035aa:	8526                	mv	a0,s1
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	73a080e7          	jalr	1850(ra) # 80000ce6 <release>
    for (int i = 0; i < MAX_BSEM; i++)
    800035b4:	02048493          	addi	s1,s1,32
    800035b8:	fd449ae3          	bne	s1,s4,8000358c <allocBsem+0x7e>
    isSemaphoresAllocated=1;
    800035bc:	4785                	li	a5,1
    800035be:	00007717          	auipc	a4,0x7
    800035c2:	a6f72723          	sw	a5,-1426(a4) # 8000a02c <isSemaphoresAllocated>
    release(&semaphores_lock);
    800035c6:	0000f517          	auipc	a0,0xf
    800035ca:	14a50513          	addi	a0,a0,330 # 80012710 <semaphores_lock>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	718080e7          	jalr	1816(ra) # 80000ce6 <release>
    800035d6:	bf99                	j	8000352c <allocBsem+0x1e>
    {
      semaphores[i].available=0;
    800035d8:	fe04ac23          	sw	zero,-8(s1)
      semaphores[i].value=1;
    800035dc:	4785                	li	a5,1
    800035de:	fef4ae23          	sw	a5,-4(s1)
      found=1;
      sema_id=i;
    }
    
    release(&semaphores[i].sema_lock);
    800035e2:	8526                	mv	a0,s1
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	702080e7          	jalr	1794(ra) # 80000ce6 <release>
  for (int i = 0; i < MAX_BSEM && found==0; i++)
    800035ec:	07f00793          	li	a5,127
    800035f0:	00f91e63          	bne	s2,a5,8000360c <allocBsem+0xfe>
  }
  release(&semaphores_lock);
    800035f4:	0000f517          	auipc	a0,0xf
    800035f8:	11c50513          	addi	a0,a0,284 # 80012710 <semaphores_lock>
    800035fc:	ffffd097          	auipc	ra,0xffffd
    80003600:	6ea080e7          	jalr	1770(ra) # 80000ce6 <release>
  if(found==0)
    80003604:	000a1c63          	bnez	s4,8000361c <allocBsem+0x10e>
  {
    return -1;
    80003608:	597d                	li	s2,-1
    8000360a:	a809                	j	8000361c <allocBsem+0x10e>
  release(&semaphores_lock);
    8000360c:	0000f517          	auipc	a0,0xf
    80003610:	10450513          	addi	a0,a0,260 # 80012710 <semaphores_lock>
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	6d2080e7          	jalr	1746(ra) # 80000ce6 <release>
  }
  //printf("alloc sema_id: %d, value: %d\n",sema_id,semaphores[sema_id].value);
  return sema_id;
}
    8000361c:	854a                	mv	a0,s2
    8000361e:	70e2                	ld	ra,56(sp)
    80003620:	7442                	ld	s0,48(sp)
    80003622:	74a2                	ld	s1,40(sp)
    80003624:	7902                	ld	s2,32(sp)
    80003626:	69e2                	ld	s3,24(sp)
    80003628:	6a42                	ld	s4,16(sp)
    8000362a:	6aa2                	ld	s5,8(sp)
    8000362c:	6b02                	ld	s6,0(sp)
    8000362e:	6121                	addi	sp,sp,64
    80003630:	8082                	ret
  for (int i = 0; i < MAX_BSEM && found==0; i++)
    80003632:	02048493          	addi	s1,s1,32
    acquire(&semaphores[i].sema_lock);
    80003636:	8526                	mv	a0,s1
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	5fa080e7          	jalr	1530(ra) # 80000c32 <acquire>
    if(semaphores[i].available==1)
    80003640:	ff84aa03          	lw	s4,-8(s1)
    80003644:	f95a0ae3          	beq	s4,s5,800035d8 <allocBsem+0xca>
    release(&semaphores[i].sema_lock);
    80003648:	8526                	mv	a0,s1
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	69c080e7          	jalr	1692(ra) # 80000ce6 <release>
  for (int i = 0; i < MAX_BSEM && found==0; i++)
    80003652:	2905                	addiw	s2,s2,1
    80003654:	fd691fe3          	bne	s2,s6,80003632 <allocBsem+0x124>
    80003658:	4a01                	li	s4,0
    8000365a:	597d                	li	s2,-1
    8000365c:	bf61                	j	800035f4 <allocBsem+0xe6>

000000008000365e <bsem_free>:


void bsem_free(int bsem)
{
    8000365e:	1101                	addi	sp,sp,-32
    80003660:	ec06                	sd	ra,24(sp)
    80003662:	e822                	sd	s0,16(sp)
    80003664:	e426                	sd	s1,8(sp)
    80003666:	e04a                	sd	s2,0(sp)
    80003668:	1000                	addi	s0,sp,32
  if(bsem>MAX_BSEM)
    8000366a:	08000793          	li	a5,128
    8000366e:	04a7cb63          	blt	a5,a0,800036c4 <bsem_free+0x66>
    80003672:	84aa                	mv	s1,a0
  {
    panic("semaphore id not valid");
  }
  if(semaphores[bsem].available==1)
    80003674:	00551713          	slli	a4,a0,0x5
    80003678:	0000f797          	auipc	a5,0xf
    8000367c:	0b078793          	addi	a5,a5,176 # 80012728 <semaphores>
    80003680:	97ba                	add	a5,a5,a4
    80003682:	4398                	lw	a4,0(a5)
    80003684:	4785                	li	a5,1
    80003686:	04f70763          	beq	a4,a5,800036d4 <bsem_free+0x76>
  {
    panic("BSEM not allocated");
  }
  
  acquire(&semaphores_lock);
    8000368a:	0000f917          	auipc	s2,0xf
    8000368e:	08690913          	addi	s2,s2,134 # 80012710 <semaphores_lock>
    80003692:	854a                	mv	a0,s2
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	59e080e7          	jalr	1438(ra) # 80000c32 <acquire>
  semaphores[bsem].available=1;
    8000369c:	0496                	slli	s1,s1,0x5
    8000369e:	0000f517          	auipc	a0,0xf
    800036a2:	08a50513          	addi	a0,a0,138 # 80012728 <semaphores>
    800036a6:	94aa                	add	s1,s1,a0
    800036a8:	4785                	li	a5,1
    800036aa:	c09c                	sw	a5,0(s1)
  semaphores[bsem].value=1;
    800036ac:	c0dc                	sw	a5,4(s1)
  release(&semaphores_lock);
    800036ae:	854a                	mv	a0,s2
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	636080e7          	jalr	1590(ra) # 80000ce6 <release>
  
}
    800036b8:	60e2                	ld	ra,24(sp)
    800036ba:	6442                	ld	s0,16(sp)
    800036bc:	64a2                	ld	s1,8(sp)
    800036be:	6902                	ld	s2,0(sp)
    800036c0:	6105                	addi	sp,sp,32
    800036c2:	8082                	ret
    panic("semaphore id not valid");
    800036c4:	00006517          	auipc	a0,0x6
    800036c8:	c6450513          	addi	a0,a0,-924 # 80009328 <digits+0x2e8>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	e5e080e7          	jalr	-418(ra) # 8000052a <panic>
    panic("BSEM not allocated");
    800036d4:	00006517          	auipc	a0,0x6
    800036d8:	c6c50513          	addi	a0,a0,-916 # 80009340 <digits+0x300>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	e4e080e7          	jalr	-434(ra) # 8000052a <panic>

00000000800036e4 <bsem_down>:


void bsem_down(int bsem)
{
    800036e4:	7179                	addi	sp,sp,-48
    800036e6:	f406                	sd	ra,40(sp)
    800036e8:	f022                	sd	s0,32(sp)
    800036ea:	ec26                	sd	s1,24(sp)
    800036ec:	e84a                	sd	s2,16(sp)
    800036ee:	e44e                	sd	s3,8(sp)
    800036f0:	e052                	sd	s4,0(sp)
    800036f2:	1800                	addi	s0,sp,48
    800036f4:	8a2a                	mv	s4,a0
  //printf("bdown\n");
  acquire(&semaphores[bsem].sema_lock);
    800036f6:	00551913          	slli	s2,a0,0x5
    800036fa:	00890493          	addi	s1,s2,8
    800036fe:	0000f997          	auipc	s3,0xf
    80003702:	02a98993          	addi	s3,s3,42 # 80012728 <semaphores>
    80003706:	94ce                	add	s1,s1,s3
    80003708:	8526                	mv	a0,s1
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	528080e7          	jalr	1320(ra) # 80000c32 <acquire>
  //printf("after bsem %d acquire, value: %d\n",bsem,semaphores[bsem].value);
  while(semaphores[bsem].value==0)
    80003712:	99ca                	add	s3,s3,s2
    80003714:	0049a783          	lw	a5,4(s3)
    80003718:	e795                	bnez	a5,80003744 <bsem_down+0x60>
  {
    //printf("pid %d: Go to sleep on %d\n",myproc()->pid,&semaphores[bsem].value);  
    
    sleep(&semaphores[bsem].value,&semaphores[bsem].sema_lock);
    8000371a:	0000f797          	auipc	a5,0xf
    8000371e:	01278793          	addi	a5,a5,18 # 8001272c <semaphores+0x4>
    80003722:	993e                	add	s2,s2,a5
  while(semaphores[bsem].value==0)
    80003724:	005a1793          	slli	a5,s4,0x5
    80003728:	0000f997          	auipc	s3,0xf
    8000372c:	00098993          	mv	s3,s3
    80003730:	99be                	add	s3,s3,a5
    sleep(&semaphores[bsem].value,&semaphores[bsem].sema_lock);
    80003732:	85a6                	mv	a1,s1
    80003734:	854a                	mv	a0,s2
    80003736:	fffff097          	auipc	ra,0xfffff
    8000373a:	16c080e7          	jalr	364(ra) # 800028a2 <sleep>
  while(semaphores[bsem].value==0)
    8000373e:	0049a783          	lw	a5,4(s3) # 8001272c <semaphores+0x4>
    80003742:	dbe5                	beqz	a5,80003732 <bsem_down+0x4e>
    //printf("wakeup\n");
  }
  semaphores[bsem].value=0;
    80003744:	0a16                	slli	s4,s4,0x5
    80003746:	0000f797          	auipc	a5,0xf
    8000374a:	fe278793          	addi	a5,a5,-30 # 80012728 <semaphores>
    8000374e:	9a3e                	add	s4,s4,a5
    80003750:	000a2223          	sw	zero,4(s4)
  release(&semaphores[bsem].sema_lock);
    80003754:	8526                	mv	a0,s1
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	590080e7          	jalr	1424(ra) # 80000ce6 <release>
  // }
  // acquire(&semaphores_lock);
  // semaphores[bsem].value=1;
  // release(&semaphores_lock);
  
}
    8000375e:	70a2                	ld	ra,40(sp)
    80003760:	7402                	ld	s0,32(sp)
    80003762:	64e2                	ld	s1,24(sp)
    80003764:	6942                	ld	s2,16(sp)
    80003766:	69a2                	ld	s3,8(sp)
    80003768:	6a02                	ld	s4,0(sp)
    8000376a:	6145                	addi	sp,sp,48
    8000376c:	8082                	ret

000000008000376e <bsem_up>:
void bsem_up(int bsem)
{
    8000376e:	7179                	addi	sp,sp,-48
    80003770:	f406                	sd	ra,40(sp)
    80003772:	f022                	sd	s0,32(sp)
    80003774:	ec26                	sd	s1,24(sp)
    80003776:	e84a                	sd	s2,16(sp)
    80003778:	e44e                	sd	s3,8(sp)
    8000377a:	e052                	sd	s4,0(sp)
    8000377c:	1800                	addi	s0,sp,48
  acquire(&semaphores[bsem].sema_lock);
    8000377e:	00551a13          	slli	s4,a0,0x5
    80003782:	008a0913          	addi	s2,s4,8
    80003786:	0000f997          	auipc	s3,0xf
    8000378a:	fa298993          	addi	s3,s3,-94 # 80012728 <semaphores>
    8000378e:	994e                	add	s2,s2,s3
    80003790:	854a                	mv	a0,s2
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	4a0080e7          	jalr	1184(ra) # 80000c32 <acquire>
  if(semaphores[bsem].value==0)
    8000379a:	99d2                	add	s3,s3,s4
    8000379c:	0049a783          	lw	a5,4(s3)
    800037a0:	cf91                	beqz	a5,800037bc <bsem_up+0x4e>
    semaphores[bsem].value=1;
    //release(&semaphores_lock);
    //printf("wakeup on: %d\n",&semaphores[bsem].value);
    wakeup(&semaphores[bsem].value);
  }
  release(&semaphores[bsem].sema_lock);
    800037a2:	854a                	mv	a0,s2
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	542080e7          	jalr	1346(ra) # 80000ce6 <release>
}
    800037ac:	70a2                	ld	ra,40(sp)
    800037ae:	7402                	ld	s0,32(sp)
    800037b0:	64e2                	ld	s1,24(sp)
    800037b2:	6942                	ld	s2,16(sp)
    800037b4:	69a2                	ld	s3,8(sp)
    800037b6:	6a02                	ld	s4,0(sp)
    800037b8:	6145                	addi	sp,sp,48
    800037ba:	8082                	ret
    semaphores[bsem].value=1;
    800037bc:	0000f517          	auipc	a0,0xf
    800037c0:	f6c50513          	addi	a0,a0,-148 # 80012728 <semaphores>
    800037c4:	4785                	li	a5,1
    800037c6:	00f9a223          	sw	a5,4(s3)
    wakeup(&semaphores[bsem].value);
    800037ca:	0a11                	addi	s4,s4,4
    800037cc:	9552                	add	a0,a0,s4
    800037ce:	fffff097          	auipc	ra,0xfffff
    800037d2:	26a080e7          	jalr	618(ra) # 80002a38 <wakeup>
    800037d6:	b7f1                	j	800037a2 <bsem_up+0x34>

00000000800037d8 <swtch>:
    800037d8:	00153023          	sd	ra,0(a0)
    800037dc:	00253423          	sd	sp,8(a0)
    800037e0:	e900                	sd	s0,16(a0)
    800037e2:	ed04                	sd	s1,24(a0)
    800037e4:	03253023          	sd	s2,32(a0)
    800037e8:	03353423          	sd	s3,40(a0)
    800037ec:	03453823          	sd	s4,48(a0)
    800037f0:	03553c23          	sd	s5,56(a0)
    800037f4:	05653023          	sd	s6,64(a0)
    800037f8:	05753423          	sd	s7,72(a0)
    800037fc:	05853823          	sd	s8,80(a0)
    80003800:	05953c23          	sd	s9,88(a0)
    80003804:	07a53023          	sd	s10,96(a0)
    80003808:	07b53423          	sd	s11,104(a0)
    8000380c:	0005b083          	ld	ra,0(a1)
    80003810:	0085b103          	ld	sp,8(a1)
    80003814:	6980                	ld	s0,16(a1)
    80003816:	6d84                	ld	s1,24(a1)
    80003818:	0205b903          	ld	s2,32(a1)
    8000381c:	0285b983          	ld	s3,40(a1)
    80003820:	0305ba03          	ld	s4,48(a1)
    80003824:	0385ba83          	ld	s5,56(a1)
    80003828:	0405bb03          	ld	s6,64(a1)
    8000382c:	0485bb83          	ld	s7,72(a1)
    80003830:	0505bc03          	ld	s8,80(a1)
    80003834:	0585bc83          	ld	s9,88(a1)
    80003838:	0605bd03          	ld	s10,96(a1)
    8000383c:	0685bd83          	ld	s11,104(a1)
    80003840:	8082                	ret

0000000080003842 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003842:	1141                	addi	sp,sp,-16
    80003844:	e406                	sd	ra,8(sp)
    80003846:	e022                	sd	s0,0(sp)
    80003848:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000384a:	00006597          	auipc	a1,0x6
    8000384e:	b1658593          	addi	a1,a1,-1258 # 80009360 <digits+0x320>
    80003852:	00042517          	auipc	a0,0x42
    80003856:	2d650513          	addi	a0,a0,726 # 80045b28 <tickslock>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	2f8080e7          	jalr	760(ra) # 80000b52 <initlock>
}
    80003862:	60a2                	ld	ra,8(sp)
    80003864:	6402                	ld	s0,0(sp)
    80003866:	0141                	addi	sp,sp,16
    80003868:	8082                	ret

000000008000386a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000386a:	1141                	addi	sp,sp,-16
    8000386c:	e422                	sd	s0,8(sp)
    8000386e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003870:	00003797          	auipc	a5,0x3
    80003874:	7a078793          	addi	a5,a5,1952 # 80007010 <kernelvec>
    80003878:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000387c:	6422                	ld	s0,8(sp)
    8000387e:	0141                	addi	sp,sp,16
    80003880:	8082                	ret

0000000080003882 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003882:	1101                	addi	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	e426                	sd	s1,8(sp)
    8000388a:	e04a                	sd	s2,0(sp)
    8000388c:	1000                	addi	s0,sp,32
  
  //printf("usertrapret\n");
  struct proc *p = myproc();
    8000388e:	ffffe097          	auipc	ra,0xffffe
    80003892:	2b8080e7          	jalr	696(ra) # 80001b46 <myproc>
    80003896:	892a                	mv	s2,a0
  struct thread *t= mythread();
    80003898:	ffffe097          	auipc	ra,0xffffe
    8000389c:	224080e7          	jalr	548(ra) # 80001abc <mythread>
    800038a0:	84aa                	mv	s1,a0
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800038a2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800038a6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800038a8:	10079073          	csrw	sstatus,a5
  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();
  
  checkSignalsForProcess(p);
    800038ac:	854a                	mv	a0,s2
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	b96080e7          	jalr	-1130(ra) # 80003444 <checkSignalsForProcess>
  
  
  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800038b6:	00004617          	auipc	a2,0x4
    800038ba:	74a60613          	addi	a2,a2,1866 # 80008000 <_trampoline>
    800038be:	00004697          	auipc	a3,0x4
    800038c2:	74268693          	addi	a3,a3,1858 # 80008000 <_trampoline>
    800038c6:	8e91                	sub	a3,a3,a2
    800038c8:	040007b7          	lui	a5,0x4000
    800038cc:	17fd                	addi	a5,a5,-1
    800038ce:	07b2                	slli	a5,a5,0xc
    800038d0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800038d2:	10569073          	csrw	stvec,a3

  
  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  t->trapeframe->kernel_satp = r_satp();         // kernel page table
    800038d6:	7098                	ld	a4,32(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800038d8:	180026f3          	csrr	a3,satp
    800038dc:	e314                	sd	a3,0(a4)
  t->trapeframe->kernel_sp = t->kstack + PGSIZE; // process's kernel stack
    800038de:	7098                	ld	a4,32(s1)
    800038e0:	6c94                	ld	a3,24(s1)
    800038e2:	6585                	lui	a1,0x1
    800038e4:	96ae                	add	a3,a3,a1
    800038e6:	e714                	sd	a3,8(a4)
  t->trapeframe->kernel_trap = (uint64)usertrap;
    800038e8:	7098                	ld	a4,32(s1)
    800038ea:	00000697          	auipc	a3,0x0
    800038ee:	14668693          	addi	a3,a3,326 # 80003a30 <usertrap>
    800038f2:	eb14                	sd	a3,16(a4)
  t->trapeframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800038f4:	7098                	ld	a4,32(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    800038f6:	8692                	mv	a3,tp
    800038f8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800038fa:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800038fe:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003902:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003906:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(t->trapeframe->epc);
    8000390a:	7094                	ld	a3,32(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000390c:	6e98                	ld	a4,24(a3)
    8000390e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003912:	03893583          	ld	a1,56(s2)
    80003916:	81b1                	srli	a1,a1,0xc
  // {
  //   printf("usertrap epc : %p",tp->epc);
  // }
  //struct proc *p=myproc();
    uint64 fn = TRAMPOLINE + (userret - trampoline);
    ((void (*)(uint64,uint64))fn)(TRAPFRAME+(uint64)(t->trapeframe)-(uint64)(p->headThreadTrapframe), satp);
    80003918:	02000537          	lui	a0,0x2000
    8000391c:	157d                	addi	a0,a0,-1
    8000391e:	0536                	slli	a0,a0,0xd
    80003920:	9536                	add	a0,a0,a3
    80003922:	04093683          	ld	a3,64(s2)
    uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003926:	00004717          	auipc	a4,0x4
    8000392a:	76a70713          	addi	a4,a4,1898 # 80008090 <userret>
    8000392e:	8f11                	sub	a4,a4,a2
    80003930:	97ba                	add	a5,a5,a4
    ((void (*)(uint64,uint64))fn)(TRAPFRAME+(uint64)(t->trapeframe)-(uint64)(p->headThreadTrapframe), satp);
    80003932:	577d                	li	a4,-1
    80003934:	177e                	slli	a4,a4,0x3f
    80003936:	8dd9                	or	a1,a1,a4
    80003938:	8d15                	sub	a0,a0,a3
    8000393a:	9782                	jalr	a5
    //+t->idx*sizeof(struct trapframe)
}
    8000393c:	60e2                	ld	ra,24(sp)
    8000393e:	6442                	ld	s0,16(sp)
    80003940:	64a2                	ld	s1,8(sp)
    80003942:	6902                	ld	s2,0(sp)
    80003944:	6105                	addi	sp,sp,32
    80003946:	8082                	ret

0000000080003948 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003948:	1101                	addi	sp,sp,-32
    8000394a:	ec06                	sd	ra,24(sp)
    8000394c:	e822                	sd	s0,16(sp)
    8000394e:	e426                	sd	s1,8(sp)
    80003950:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003952:	00042497          	auipc	s1,0x42
    80003956:	1d648493          	addi	s1,s1,470 # 80045b28 <tickslock>
    8000395a:	8526                	mv	a0,s1
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	2d6080e7          	jalr	726(ra) # 80000c32 <acquire>
  ticks++;
    80003964:	00006517          	auipc	a0,0x6
    80003968:	6d450513          	addi	a0,a0,1748 # 8000a038 <ticks>
    8000396c:	411c                	lw	a5,0(a0)
    8000396e:	2785                	addiw	a5,a5,1
    80003970:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003972:	fffff097          	auipc	ra,0xfffff
    80003976:	0c6080e7          	jalr	198(ra) # 80002a38 <wakeup>
  release(&tickslock);
    8000397a:	8526                	mv	a0,s1
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	36a080e7          	jalr	874(ra) # 80000ce6 <release>
}
    80003984:	60e2                	ld	ra,24(sp)
    80003986:	6442                	ld	s0,16(sp)
    80003988:	64a2                	ld	s1,8(sp)
    8000398a:	6105                	addi	sp,sp,32
    8000398c:	8082                	ret

000000008000398e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000398e:	1101                	addi	sp,sp,-32
    80003990:	ec06                	sd	ra,24(sp)
    80003992:	e822                	sd	s0,16(sp)
    80003994:	e426                	sd	s1,8(sp)
    80003996:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003998:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000399c:	00074d63          	bltz	a4,800039b6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800039a0:	57fd                	li	a5,-1
    800039a2:	17fe                	slli	a5,a5,0x3f
    800039a4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800039a6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800039a8:	06f70363          	beq	a4,a5,80003a0e <devintr+0x80>
  }
}
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6105                	addi	sp,sp,32
    800039b4:	8082                	ret
     (scause & 0xff) == 9){
    800039b6:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800039ba:	46a5                	li	a3,9
    800039bc:	fed792e3          	bne	a5,a3,800039a0 <devintr+0x12>
    int irq = plic_claim();
    800039c0:	00003097          	auipc	ra,0x3
    800039c4:	758080e7          	jalr	1880(ra) # 80007118 <plic_claim>
    800039c8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800039ca:	47a9                	li	a5,10
    800039cc:	02f50763          	beq	a0,a5,800039fa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800039d0:	4785                	li	a5,1
    800039d2:	02f50963          	beq	a0,a5,80003a04 <devintr+0x76>
    return 1;
    800039d6:	4505                	li	a0,1
    } else if(irq){
    800039d8:	d8f1                	beqz	s1,800039ac <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800039da:	85a6                	mv	a1,s1
    800039dc:	00006517          	auipc	a0,0x6
    800039e0:	98c50513          	addi	a0,a0,-1652 # 80009368 <digits+0x328>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	b90080e7          	jalr	-1136(ra) # 80000574 <printf>
      plic_complete(irq);
    800039ec:	8526                	mv	a0,s1
    800039ee:	00003097          	auipc	ra,0x3
    800039f2:	74e080e7          	jalr	1870(ra) # 8000713c <plic_complete>
    return 1;
    800039f6:	4505                	li	a0,1
    800039f8:	bf55                	j	800039ac <devintr+0x1e>
      uartintr();
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	f8c080e7          	jalr	-116(ra) # 80000986 <uartintr>
    80003a02:	b7ed                	j	800039ec <devintr+0x5e>
      virtio_disk_intr();
    80003a04:	00004097          	auipc	ra,0x4
    80003a08:	bca080e7          	jalr	-1078(ra) # 800075ce <virtio_disk_intr>
    80003a0c:	b7c5                	j	800039ec <devintr+0x5e>
    if(cpuid() == 0){
    80003a0e:	ffffe097          	auipc	ra,0xffffe
    80003a12:	07a080e7          	jalr	122(ra) # 80001a88 <cpuid>
    80003a16:	c901                	beqz	a0,80003a26 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003a18:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003a1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003a1e:	14479073          	csrw	sip,a5
    return 2;
    80003a22:	4509                	li	a0,2
    80003a24:	b761                	j	800039ac <devintr+0x1e>
      clockintr();
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	f22080e7          	jalr	-222(ra) # 80003948 <clockintr>
    80003a2e:	b7ed                	j	80003a18 <devintr+0x8a>

0000000080003a30 <usertrap>:
{
    80003a30:	7179                	addi	sp,sp,-48
    80003a32:	f406                	sd	ra,40(sp)
    80003a34:	f022                	sd	s0,32(sp)
    80003a36:	ec26                	sd	s1,24(sp)
    80003a38:	e84a                	sd	s2,16(sp)
    80003a3a:	e44e                	sd	s3,8(sp)
    80003a3c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003a3e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003a42:	1007f793          	andi	a5,a5,256
    80003a46:	e3c1                	bnez	a5,80003ac6 <usertrap+0x96>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003a48:	00003797          	auipc	a5,0x3
    80003a4c:	5c878793          	addi	a5,a5,1480 # 80007010 <kernelvec>
    80003a50:	10579073          	csrw	stvec,a5
  struct thread *t = mythread();
    80003a54:	ffffe097          	auipc	ra,0xffffe
    80003a58:	068080e7          	jalr	104(ra) # 80001abc <mythread>
    80003a5c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003a5e:	ffffe097          	auipc	ra,0xffffe
    80003a62:	0e8080e7          	jalr	232(ra) # 80001b46 <myproc>
    80003a66:	892a                	mv	s2,a0
  t->trapeframe->epc = r_sepc();
    80003a68:	709c                	ld	a5,32(s1)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003a6a:	14102773          	csrr	a4,sepc
    80003a6e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003a70:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003a74:	47a1                	li	a5,8
    80003a76:	06f71c63          	bne	a4,a5,80003aee <usertrap+0xbe>
  if(p->killed)
    80003a7a:	4d5c                	lw	a5,28(a0)
    80003a7c:	efa9                	bnez	a5,80003ad6 <usertrap+0xa6>
  if(t->killed)
    80003a7e:	44dc                	lw	a5,12(s1)
    80003a80:	e3ad                	bnez	a5,80003ae2 <usertrap+0xb2>
    t->trapeframe->epc += 4;
    80003a82:	7098                	ld	a4,32(s1)
    80003a84:	6f1c                	ld	a5,24(a4)
    80003a86:	0791                	addi	a5,a5,4
    80003a88:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003a8a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003a8e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003a92:	10079073          	csrw	sstatus,a5
    syscall();
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	302080e7          	jalr	770(ra) # 80003d98 <syscall>
  int which_dev = 0;
    80003a9e:	4981                	li	s3,0
  if(p->killed)
    80003aa0:	01c92783          	lw	a5,28(s2)
    80003aa4:	efd1                	bnez	a5,80003b40 <usertrap+0x110>
  if(t->killed)
    80003aa6:	44dc                	lw	a5,12(s1)
    80003aa8:	e7d1                	bnez	a5,80003b34 <usertrap+0x104>
  if(which_dev == 2)
    80003aaa:	4789                	li	a5,2
    80003aac:	0af98063          	beq	s3,a5,80003b4c <usertrap+0x11c>
  usertrapret();
    80003ab0:	00000097          	auipc	ra,0x0
    80003ab4:	dd2080e7          	jalr	-558(ra) # 80003882 <usertrapret>
}
    80003ab8:	70a2                	ld	ra,40(sp)
    80003aba:	7402                	ld	s0,32(sp)
    80003abc:	64e2                	ld	s1,24(sp)
    80003abe:	6942                	ld	s2,16(sp)
    80003ac0:	69a2                	ld	s3,8(sp)
    80003ac2:	6145                	addi	sp,sp,48
    80003ac4:	8082                	ret
    panic("usertrap: not from user mode");
    80003ac6:	00006517          	auipc	a0,0x6
    80003aca:	8c250513          	addi	a0,a0,-1854 # 80009388 <digits+0x348>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	a5c080e7          	jalr	-1444(ra) # 8000052a <panic>
    exit(-1);
    80003ad6:	557d                	li	a0,-1
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	400080e7          	jalr	1024(ra) # 80002ed8 <exit>
    80003ae0:	bf79                	j	80003a7e <usertrap+0x4e>
    kthread_exit(-1);
    80003ae2:	557d                	li	a0,-1
    80003ae4:	fffff097          	auipc	ra,0xfffff
    80003ae8:	384080e7          	jalr	900(ra) # 80002e68 <kthread_exit>
    80003aec:	bf59                	j	80003a82 <usertrap+0x52>
  } else if((which_dev = devintr()) != 0){
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	ea0080e7          	jalr	-352(ra) # 8000398e <devintr>
    80003af6:	89aa                	mv	s3,a0
    80003af8:	f545                	bnez	a0,80003aa0 <usertrap+0x70>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003afa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p tid=%d\n", r_scause(), t->tid);
    80003afe:	4090                	lw	a2,0(s1)
    80003b00:	00006517          	auipc	a0,0x6
    80003b04:	8a850513          	addi	a0,a0,-1880 # 800093a8 <digits+0x368>
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	a6c080e7          	jalr	-1428(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003b10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003b14:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003b18:	00006517          	auipc	a0,0x6
    80003b1c:	8c050513          	addi	a0,a0,-1856 # 800093d8 <digits+0x398>
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	a54080e7          	jalr	-1452(ra) # 80000574 <printf>
    t->killed = 1;
    80003b28:	4785                	li	a5,1
    80003b2a:	c4dc                	sw	a5,12(s1)
  if(p->killed)
    80003b2c:	01c92783          	lw	a5,28(s2)
    80003b30:	eb81                	bnez	a5,80003b40 <usertrap+0x110>
  } else if((which_dev = devintr()) != 0){
    80003b32:	89be                	mv	s3,a5
    kthread_exit(-1);
    80003b34:	557d                	li	a0,-1
    80003b36:	fffff097          	auipc	ra,0xfffff
    80003b3a:	332080e7          	jalr	818(ra) # 80002e68 <kthread_exit>
    80003b3e:	b7b5                	j	80003aaa <usertrap+0x7a>
    exit(-1);
    80003b40:	557d                	li	a0,-1
    80003b42:	fffff097          	auipc	ra,0xfffff
    80003b46:	396080e7          	jalr	918(ra) # 80002ed8 <exit>
    80003b4a:	bfb1                	j	80003aa6 <usertrap+0x76>
    yield();
    80003b4c:	fffff097          	auipc	ra,0xfffff
    80003b50:	cba080e7          	jalr	-838(ra) # 80002806 <yield>
    80003b54:	bfb1                	j	80003ab0 <usertrap+0x80>

0000000080003b56 <kerneltrap>:
{
    80003b56:	7179                	addi	sp,sp,-48
    80003b58:	f406                	sd	ra,40(sp)
    80003b5a:	f022                	sd	s0,32(sp)
    80003b5c:	ec26                	sd	s1,24(sp)
    80003b5e:	e84a                	sd	s2,16(sp)
    80003b60:	e44e                	sd	s3,8(sp)
    80003b62:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003b64:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003b68:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003b6c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003b70:	1004f793          	andi	a5,s1,256
    80003b74:	cb85                	beqz	a5,80003ba4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003b76:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80003b7a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003b7c:	ef85                	bnez	a5,80003bb4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	e10080e7          	jalr	-496(ra) # 8000398e <devintr>
    80003b86:	cd1d                	beqz	a0,80003bc4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && mythread()->state == RUNNING)
    80003b88:	4789                	li	a5,2
    80003b8a:	06f50a63          	beq	a0,a5,80003bfe <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003b8e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003b92:	10049073          	csrw	sstatus,s1
}
    80003b96:	70a2                	ld	ra,40(sp)
    80003b98:	7402                	ld	s0,32(sp)
    80003b9a:	64e2                	ld	s1,24(sp)
    80003b9c:	6942                	ld	s2,16(sp)
    80003b9e:	69a2                	ld	s3,8(sp)
    80003ba0:	6145                	addi	sp,sp,48
    80003ba2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003ba4:	00006517          	auipc	a0,0x6
    80003ba8:	85450513          	addi	a0,a0,-1964 # 800093f8 <digits+0x3b8>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	97e080e7          	jalr	-1666(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80003bb4:	00006517          	auipc	a0,0x6
    80003bb8:	86c50513          	addi	a0,a0,-1940 # 80009420 <digits+0x3e0>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	96e080e7          	jalr	-1682(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80003bc4:	85ce                	mv	a1,s3
    80003bc6:	00006517          	auipc	a0,0x6
    80003bca:	87a50513          	addi	a0,a0,-1926 # 80009440 <digits+0x400>
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	9a6080e7          	jalr	-1626(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003bd6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003bda:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003bde:	00006517          	auipc	a0,0x6
    80003be2:	87250513          	addi	a0,a0,-1934 # 80009450 <digits+0x410>
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	98e080e7          	jalr	-1650(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003bee:	00006517          	auipc	a0,0x6
    80003bf2:	87a50513          	addi	a0,a0,-1926 # 80009468 <digits+0x428>
    80003bf6:	ffffd097          	auipc	ra,0xffffd
    80003bfa:	934080e7          	jalr	-1740(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && mythread()->state == RUNNING)
    80003bfe:	ffffe097          	auipc	ra,0xffffe
    80003c02:	f48080e7          	jalr	-184(ra) # 80001b46 <myproc>
    80003c06:	d541                	beqz	a0,80003b8e <kerneltrap+0x38>
    80003c08:	ffffe097          	auipc	ra,0xffffe
    80003c0c:	eb4080e7          	jalr	-332(ra) # 80001abc <mythread>
    80003c10:	4518                	lw	a4,8(a0)
    80003c12:	4791                	li	a5,4
    80003c14:	f6f71de3          	bne	a4,a5,80003b8e <kerneltrap+0x38>
    yield();
    80003c18:	fffff097          	auipc	ra,0xfffff
    80003c1c:	bee080e7          	jalr	-1042(ra) # 80002806 <yield>
    80003c20:	b7bd                	j	80003b8e <kerneltrap+0x38>

0000000080003c22 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003c22:	1101                	addi	sp,sp,-32
    80003c24:	ec06                	sd	ra,24(sp)
    80003c26:	e822                	sd	s0,16(sp)
    80003c28:	e426                	sd	s1,8(sp)
    80003c2a:	1000                	addi	s0,sp,32
    80003c2c:	84aa                	mv	s1,a0
  struct thread *t = mythread();
    80003c2e:	ffffe097          	auipc	ra,0xffffe
    80003c32:	e8e080e7          	jalr	-370(ra) # 80001abc <mythread>
  switch (n) {
    80003c36:	4795                	li	a5,5
    80003c38:	0497e163          	bltu	a5,s1,80003c7a <argraw+0x58>
    80003c3c:	048a                	slli	s1,s1,0x2
    80003c3e:	00006717          	auipc	a4,0x6
    80003c42:	86270713          	addi	a4,a4,-1950 # 800094a0 <digits+0x460>
    80003c46:	94ba                	add	s1,s1,a4
    80003c48:	409c                	lw	a5,0(s1)
    80003c4a:	97ba                	add	a5,a5,a4
    80003c4c:	8782                	jr	a5
  case 0:
    return t->trapeframe ->a0;
    80003c4e:	711c                	ld	a5,32(a0)
    80003c50:	7ba8                	ld	a0,112(a5)
  case 5:
    return t->trapeframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003c52:	60e2                	ld	ra,24(sp)
    80003c54:	6442                	ld	s0,16(sp)
    80003c56:	64a2                	ld	s1,8(sp)
    80003c58:	6105                	addi	sp,sp,32
    80003c5a:	8082                	ret
    return t->trapeframe->a1;
    80003c5c:	711c                	ld	a5,32(a0)
    80003c5e:	7fa8                	ld	a0,120(a5)
    80003c60:	bfcd                	j	80003c52 <argraw+0x30>
    return t->trapeframe->a2;
    80003c62:	711c                	ld	a5,32(a0)
    80003c64:	63c8                	ld	a0,128(a5)
    80003c66:	b7f5                	j	80003c52 <argraw+0x30>
    return t->trapeframe->a3;
    80003c68:	711c                	ld	a5,32(a0)
    80003c6a:	67c8                	ld	a0,136(a5)
    80003c6c:	b7dd                	j	80003c52 <argraw+0x30>
    return t->trapeframe->a4;
    80003c6e:	711c                	ld	a5,32(a0)
    80003c70:	6bc8                	ld	a0,144(a5)
    80003c72:	b7c5                	j	80003c52 <argraw+0x30>
    return t->trapeframe->a5;
    80003c74:	711c                	ld	a5,32(a0)
    80003c76:	6fc8                	ld	a0,152(a5)
    80003c78:	bfe9                	j	80003c52 <argraw+0x30>
  panic("argraw");
    80003c7a:	00005517          	auipc	a0,0x5
    80003c7e:	7fe50513          	addi	a0,a0,2046 # 80009478 <digits+0x438>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	8a8080e7          	jalr	-1880(ra) # 8000052a <panic>

0000000080003c8a <fetchaddr>:
{
    80003c8a:	1101                	addi	sp,sp,-32
    80003c8c:	ec06                	sd	ra,24(sp)
    80003c8e:	e822                	sd	s0,16(sp)
    80003c90:	e426                	sd	s1,8(sp)
    80003c92:	e04a                	sd	s2,0(sp)
    80003c94:	1000                	addi	s0,sp,32
    80003c96:	84aa                	mv	s1,a0
    80003c98:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003c9a:	ffffe097          	auipc	ra,0xffffe
    80003c9e:	eac080e7          	jalr	-340(ra) # 80001b46 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003ca2:	791c                	ld	a5,48(a0)
    80003ca4:	02f4f863          	bgeu	s1,a5,80003cd4 <fetchaddr+0x4a>
    80003ca8:	00848713          	addi	a4,s1,8
    80003cac:	02e7e663          	bltu	a5,a4,80003cd8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003cb0:	46a1                	li	a3,8
    80003cb2:	8626                	mv	a2,s1
    80003cb4:	85ca                	mv	a1,s2
    80003cb6:	7d08                	ld	a0,56(a0)
    80003cb8:	ffffe097          	auipc	ra,0xffffe
    80003cbc:	a9e080e7          	jalr	-1378(ra) # 80001756 <copyin>
    80003cc0:	00a03533          	snez	a0,a0
    80003cc4:	40a00533          	neg	a0,a0
}
    80003cc8:	60e2                	ld	ra,24(sp)
    80003cca:	6442                	ld	s0,16(sp)
    80003ccc:	64a2                	ld	s1,8(sp)
    80003cce:	6902                	ld	s2,0(sp)
    80003cd0:	6105                	addi	sp,sp,32
    80003cd2:	8082                	ret
    return -1;
    80003cd4:	557d                	li	a0,-1
    80003cd6:	bfcd                	j	80003cc8 <fetchaddr+0x3e>
    80003cd8:	557d                	li	a0,-1
    80003cda:	b7fd                	j	80003cc8 <fetchaddr+0x3e>

0000000080003cdc <fetchstr>:
{
    80003cdc:	7179                	addi	sp,sp,-48
    80003cde:	f406                	sd	ra,40(sp)
    80003ce0:	f022                	sd	s0,32(sp)
    80003ce2:	ec26                	sd	s1,24(sp)
    80003ce4:	e84a                	sd	s2,16(sp)
    80003ce6:	e44e                	sd	s3,8(sp)
    80003ce8:	1800                	addi	s0,sp,48
    80003cea:	892a                	mv	s2,a0
    80003cec:	84ae                	mv	s1,a1
    80003cee:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003cf0:	ffffe097          	auipc	ra,0xffffe
    80003cf4:	e56080e7          	jalr	-426(ra) # 80001b46 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003cf8:	86ce                	mv	a3,s3
    80003cfa:	864a                	mv	a2,s2
    80003cfc:	85a6                	mv	a1,s1
    80003cfe:	7d08                	ld	a0,56(a0)
    80003d00:	ffffe097          	auipc	ra,0xffffe
    80003d04:	ae4080e7          	jalr	-1308(ra) # 800017e4 <copyinstr>
  if(err < 0)
    80003d08:	00054763          	bltz	a0,80003d16 <fetchstr+0x3a>
  return strlen(buf);
    80003d0c:	8526                	mv	a0,s1
    80003d0e:	ffffd097          	auipc	ra,0xffffd
    80003d12:	1c0080e7          	jalr	448(ra) # 80000ece <strlen>
}
    80003d16:	70a2                	ld	ra,40(sp)
    80003d18:	7402                	ld	s0,32(sp)
    80003d1a:	64e2                	ld	s1,24(sp)
    80003d1c:	6942                	ld	s2,16(sp)
    80003d1e:	69a2                	ld	s3,8(sp)
    80003d20:	6145                	addi	sp,sp,48
    80003d22:	8082                	ret

0000000080003d24 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003d24:	1101                	addi	sp,sp,-32
    80003d26:	ec06                	sd	ra,24(sp)
    80003d28:	e822                	sd	s0,16(sp)
    80003d2a:	e426                	sd	s1,8(sp)
    80003d2c:	1000                	addi	s0,sp,32
    80003d2e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003d30:	00000097          	auipc	ra,0x0
    80003d34:	ef2080e7          	jalr	-270(ra) # 80003c22 <argraw>
    80003d38:	c088                	sw	a0,0(s1)
  return 0;
}
    80003d3a:	4501                	li	a0,0
    80003d3c:	60e2                	ld	ra,24(sp)
    80003d3e:	6442                	ld	s0,16(sp)
    80003d40:	64a2                	ld	s1,8(sp)
    80003d42:	6105                	addi	sp,sp,32
    80003d44:	8082                	ret

0000000080003d46 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003d46:	1101                	addi	sp,sp,-32
    80003d48:	ec06                	sd	ra,24(sp)
    80003d4a:	e822                	sd	s0,16(sp)
    80003d4c:	e426                	sd	s1,8(sp)
    80003d4e:	1000                	addi	s0,sp,32
    80003d50:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	ed0080e7          	jalr	-304(ra) # 80003c22 <argraw>
    80003d5a:	e088                	sd	a0,0(s1)
  return 0;
}
    80003d5c:	4501                	li	a0,0
    80003d5e:	60e2                	ld	ra,24(sp)
    80003d60:	6442                	ld	s0,16(sp)
    80003d62:	64a2                	ld	s1,8(sp)
    80003d64:	6105                	addi	sp,sp,32
    80003d66:	8082                	ret

0000000080003d68 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003d68:	1101                	addi	sp,sp,-32
    80003d6a:	ec06                	sd	ra,24(sp)
    80003d6c:	e822                	sd	s0,16(sp)
    80003d6e:	e426                	sd	s1,8(sp)
    80003d70:	e04a                	sd	s2,0(sp)
    80003d72:	1000                	addi	s0,sp,32
    80003d74:	84ae                	mv	s1,a1
    80003d76:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	eaa080e7          	jalr	-342(ra) # 80003c22 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003d80:	864a                	mv	a2,s2
    80003d82:	85a6                	mv	a1,s1
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	f58080e7          	jalr	-168(ra) # 80003cdc <fetchstr>
}
    80003d8c:	60e2                	ld	ra,24(sp)
    80003d8e:	6442                	ld	s0,16(sp)
    80003d90:	64a2                	ld	s1,8(sp)
    80003d92:	6902                	ld	s2,0(sp)
    80003d94:	6105                	addi	sp,sp,32
    80003d96:	8082                	ret

0000000080003d98 <syscall>:



void
syscall(void)
{
    80003d98:	1101                	addi	sp,sp,-32
    80003d9a:	ec06                	sd	ra,24(sp)
    80003d9c:	e822                	sd	s0,16(sp)
    80003d9e:	e426                	sd	s1,8(sp)
    80003da0:	1000                	addi	s0,sp,32
  int num;
  struct thread *t = mythread();
    80003da2:	ffffe097          	auipc	ra,0xffffe
    80003da6:	d1a080e7          	jalr	-742(ra) # 80001abc <mythread>
    80003daa:	84aa                	mv	s1,a0
  
  num = t->trapeframe->a7;
    80003dac:	711c                	ld	a5,32(a0)
    80003dae:	77dc                	ld	a5,168(a5)
    80003db0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003db4:	37fd                	addiw	a5,a5,-1
    80003db6:	477d                	li	a4,31
    80003db8:	02f76063          	bltu	a4,a5,80003dd8 <syscall+0x40>
    80003dbc:	00369713          	slli	a4,a3,0x3
    80003dc0:	00005797          	auipc	a5,0x5
    80003dc4:	6f878793          	addi	a5,a5,1784 # 800094b8 <syscalls>
    80003dc8:	97ba                	add	a5,a5,a4
    80003dca:	639c                	ld	a5,0(a5)
    80003dcc:	c791                	beqz	a5,80003dd8 <syscall+0x40>
    //printf("Proc %d ecalled syscall %d\n",p->pid,num);
    int res=syscalls[num]();
    80003dce:	9782                	jalr	a5
    //printf("syscall: %d, res is: %d\n",num,res);
    t->trapeframe->a0 = res;
    80003dd0:	709c                	ld	a5,32(s1)
    80003dd2:	2501                	sext.w	a0,a0
    80003dd4:	fba8                	sd	a0,112(a5)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003dd6:	a839                	j	80003df4 <syscall+0x5c>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003dd8:	09848613          	addi	a2,s1,152
    80003ddc:	408c                	lw	a1,0(s1)
    80003dde:	00005517          	auipc	a0,0x5
    80003de2:	6a250513          	addi	a0,a0,1698 # 80009480 <digits+0x440>
    80003de6:	ffffc097          	auipc	ra,0xffffc
    80003dea:	78e080e7          	jalr	1934(ra) # 80000574 <printf>
            t->tid, t->name, num);
    t->trapeframe->a0 = -1;
    80003dee:	709c                	ld	a5,32(s1)
    80003df0:	577d                	li	a4,-1
    80003df2:	fbb8                	sd	a4,112(a5)
  }
}
    80003df4:	60e2                	ld	ra,24(sp)
    80003df6:	6442                	ld	s0,16(sp)
    80003df8:	64a2                	ld	s1,8(sp)
    80003dfa:	6105                	addi	sp,sp,32
    80003dfc:	8082                	ret

0000000080003dfe <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003dfe:	1101                	addi	sp,sp,-32
    80003e00:	ec06                	sd	ra,24(sp)
    80003e02:	e822                	sd	s0,16(sp)
    80003e04:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003e06:	fec40593          	addi	a1,s0,-20
    80003e0a:	4501                	li	a0,0
    80003e0c:	00000097          	auipc	ra,0x0
    80003e10:	f18080e7          	jalr	-232(ra) # 80003d24 <argint>
    return -1;
    80003e14:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003e16:	00054963          	bltz	a0,80003e28 <sys_exit+0x2a>
  exit(n);
    80003e1a:	fec42503          	lw	a0,-20(s0)
    80003e1e:	fffff097          	auipc	ra,0xfffff
    80003e22:	0ba080e7          	jalr	186(ra) # 80002ed8 <exit>
  return 0;  // not reached
    80003e26:	4781                	li	a5,0
}
    80003e28:	853e                	mv	a0,a5
    80003e2a:	60e2                	ld	ra,24(sp)
    80003e2c:	6442                	ld	s0,16(sp)
    80003e2e:	6105                	addi	sp,sp,32
    80003e30:	8082                	ret

0000000080003e32 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003e32:	1141                	addi	sp,sp,-16
    80003e34:	e406                	sd	ra,8(sp)
    80003e36:	e022                	sd	s0,0(sp)
    80003e38:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003e3a:	ffffe097          	auipc	ra,0xffffe
    80003e3e:	d0c080e7          	jalr	-756(ra) # 80001b46 <myproc>
}
    80003e42:	5148                	lw	a0,36(a0)
    80003e44:	60a2                	ld	ra,8(sp)
    80003e46:	6402                	ld	s0,0(sp)
    80003e48:	0141                	addi	sp,sp,16
    80003e4a:	8082                	ret

0000000080003e4c <sys_fork>:

uint64
sys_fork(void)
{
    80003e4c:	1141                	addi	sp,sp,-16
    80003e4e:	e406                	sd	ra,8(sp)
    80003e50:	e022                	sd	s0,0(sp)
    80003e52:	0800                	addi	s0,sp,16
  return fork();
    80003e54:	ffffe097          	auipc	ra,0xffffe
    80003e58:	27e080e7          	jalr	638(ra) # 800020d2 <fork>
}
    80003e5c:	60a2                	ld	ra,8(sp)
    80003e5e:	6402                	ld	s0,0(sp)
    80003e60:	0141                	addi	sp,sp,16
    80003e62:	8082                	ret

0000000080003e64 <sys_wait>:

uint64
sys_wait(void)
{
    80003e64:	1101                	addi	sp,sp,-32
    80003e66:	ec06                	sd	ra,24(sp)
    80003e68:	e822                	sd	s0,16(sp)
    80003e6a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003e6c:	fe840593          	addi	a1,s0,-24
    80003e70:	4501                	li	a0,0
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	ed4080e7          	jalr	-300(ra) # 80003d46 <argaddr>
    80003e7a:	87aa                	mv	a5,a0
    return -1;
    80003e7c:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003e7e:	0007c863          	bltz	a5,80003e8e <sys_wait+0x2a>
  return wait(p);
    80003e82:	fe843503          	ld	a0,-24(s0)
    80003e86:	fffff097          	auipc	ra,0xfffff
    80003e8a:	a8a080e7          	jalr	-1398(ra) # 80002910 <wait>
}
    80003e8e:	60e2                	ld	ra,24(sp)
    80003e90:	6442                	ld	s0,16(sp)
    80003e92:	6105                	addi	sp,sp,32
    80003e94:	8082                	ret

0000000080003e96 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003e96:	7179                	addi	sp,sp,-48
    80003e98:	f406                	sd	ra,40(sp)
    80003e9a:	f022                	sd	s0,32(sp)
    80003e9c:	ec26                	sd	s1,24(sp)
    80003e9e:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003ea0:	fdc40593          	addi	a1,s0,-36
    80003ea4:	4501                	li	a0,0
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	e7e080e7          	jalr	-386(ra) # 80003d24 <argint>
    return -1;
    80003eae:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80003eb0:	00054f63          	bltz	a0,80003ece <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003eb4:	ffffe097          	auipc	ra,0xffffe
    80003eb8:	c92080e7          	jalr	-878(ra) # 80001b46 <myproc>
    80003ebc:	5904                	lw	s1,48(a0)
  if(growproc(n) < 0)
    80003ebe:	fdc42503          	lw	a0,-36(s0)
    80003ec2:	ffffe097          	auipc	ra,0xffffe
    80003ec6:	17e080e7          	jalr	382(ra) # 80002040 <growproc>
    80003eca:	00054863          	bltz	a0,80003eda <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80003ece:	8526                	mv	a0,s1
    80003ed0:	70a2                	ld	ra,40(sp)
    80003ed2:	7402                	ld	s0,32(sp)
    80003ed4:	64e2                	ld	s1,24(sp)
    80003ed6:	6145                	addi	sp,sp,48
    80003ed8:	8082                	ret
    return -1;
    80003eda:	54fd                	li	s1,-1
    80003edc:	bfcd                	j	80003ece <sys_sbrk+0x38>

0000000080003ede <sys_sleep>:

uint64
sys_sleep(void)
{
    80003ede:	7139                	addi	sp,sp,-64
    80003ee0:	fc06                	sd	ra,56(sp)
    80003ee2:	f822                	sd	s0,48(sp)
    80003ee4:	f426                	sd	s1,40(sp)
    80003ee6:	f04a                	sd	s2,32(sp)
    80003ee8:	ec4e                	sd	s3,24(sp)
    80003eea:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003eec:	fcc40593          	addi	a1,s0,-52
    80003ef0:	4501                	li	a0,0
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	e32080e7          	jalr	-462(ra) # 80003d24 <argint>
    return -1;
    80003efa:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003efc:	06054563          	bltz	a0,80003f66 <sys_sleep+0x88>
  acquire(&tickslock);
    80003f00:	00042517          	auipc	a0,0x42
    80003f04:	c2850513          	addi	a0,a0,-984 # 80045b28 <tickslock>
    80003f08:	ffffd097          	auipc	ra,0xffffd
    80003f0c:	d2a080e7          	jalr	-726(ra) # 80000c32 <acquire>
  ticks0 = ticks;
    80003f10:	00006917          	auipc	s2,0x6
    80003f14:	12892903          	lw	s2,296(s2) # 8000a038 <ticks>
  while(ticks - ticks0 < n){
    80003f18:	fcc42783          	lw	a5,-52(s0)
    80003f1c:	cf85                	beqz	a5,80003f54 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003f1e:	00042997          	auipc	s3,0x42
    80003f22:	c0a98993          	addi	s3,s3,-1014 # 80045b28 <tickslock>
    80003f26:	00006497          	auipc	s1,0x6
    80003f2a:	11248493          	addi	s1,s1,274 # 8000a038 <ticks>
    if(myproc()->killed){
    80003f2e:	ffffe097          	auipc	ra,0xffffe
    80003f32:	c18080e7          	jalr	-1000(ra) # 80001b46 <myproc>
    80003f36:	4d5c                	lw	a5,28(a0)
    80003f38:	ef9d                	bnez	a5,80003f76 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003f3a:	85ce                	mv	a1,s3
    80003f3c:	8526                	mv	a0,s1
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	964080e7          	jalr	-1692(ra) # 800028a2 <sleep>
  while(ticks - ticks0 < n){
    80003f46:	409c                	lw	a5,0(s1)
    80003f48:	412787bb          	subw	a5,a5,s2
    80003f4c:	fcc42703          	lw	a4,-52(s0)
    80003f50:	fce7efe3          	bltu	a5,a4,80003f2e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003f54:	00042517          	auipc	a0,0x42
    80003f58:	bd450513          	addi	a0,a0,-1068 # 80045b28 <tickslock>
    80003f5c:	ffffd097          	auipc	ra,0xffffd
    80003f60:	d8a080e7          	jalr	-630(ra) # 80000ce6 <release>
  return 0;
    80003f64:	4781                	li	a5,0
}
    80003f66:	853e                	mv	a0,a5
    80003f68:	70e2                	ld	ra,56(sp)
    80003f6a:	7442                	ld	s0,48(sp)
    80003f6c:	74a2                	ld	s1,40(sp)
    80003f6e:	7902                	ld	s2,32(sp)
    80003f70:	69e2                	ld	s3,24(sp)
    80003f72:	6121                	addi	sp,sp,64
    80003f74:	8082                	ret
      release(&tickslock);
    80003f76:	00042517          	auipc	a0,0x42
    80003f7a:	bb250513          	addi	a0,a0,-1102 # 80045b28 <tickslock>
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	d68080e7          	jalr	-664(ra) # 80000ce6 <release>
      return -1;
    80003f86:	57fd                	li	a5,-1
    80003f88:	bff9                	j	80003f66 <sys_sleep+0x88>

0000000080003f8a <sys_kill>:

uint64
sys_kill(void)
{
    80003f8a:	1101                	addi	sp,sp,-32
    80003f8c:	ec06                	sd	ra,24(sp)
    80003f8e:	e822                	sd	s0,16(sp)
    80003f90:	1000                	addi	s0,sp,32
  int pid;
  int signum;

  if(argint(0, &pid) < 0)
    80003f92:	fec40593          	addi	a1,s0,-20
    80003f96:	4501                	li	a0,0
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	d8c080e7          	jalr	-628(ra) # 80003d24 <argint>
    return -1;
    80003fa0:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80003fa2:	02054563          	bltz	a0,80003fcc <sys_kill+0x42>
  if(argint(1, &signum) < 0)
    80003fa6:	fe840593          	addi	a1,s0,-24
    80003faa:	4505                	li	a0,1
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	d78080e7          	jalr	-648(ra) # 80003d24 <argint>
    return -1;
    80003fb4:	57fd                	li	a5,-1
  if(argint(1, &signum) < 0)
    80003fb6:	00054b63          	bltz	a0,80003fcc <sys_kill+0x42>
  return kill(pid, signum);
    80003fba:	fe842583          	lw	a1,-24(s0)
    80003fbe:	fec42503          	lw	a0,-20(s0)
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	058080e7          	jalr	88(ra) # 8000301a <kill>
    80003fca:	87aa                	mv	a5,a0
}
    80003fcc:	853e                	mv	a0,a5
    80003fce:	60e2                	ld	ra,24(sp)
    80003fd0:	6442                	ld	s0,16(sp)
    80003fd2:	6105                	addi	sp,sp,32
    80003fd4:	8082                	ret

0000000080003fd6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003fd6:	1101                	addi	sp,sp,-32
    80003fd8:	ec06                	sd	ra,24(sp)
    80003fda:	e822                	sd	s0,16(sp)
    80003fdc:	e426                	sd	s1,8(sp)
    80003fde:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003fe0:	00042517          	auipc	a0,0x42
    80003fe4:	b4850513          	addi	a0,a0,-1208 # 80045b28 <tickslock>
    80003fe8:	ffffd097          	auipc	ra,0xffffd
    80003fec:	c4a080e7          	jalr	-950(ra) # 80000c32 <acquire>
  xticks = ticks;
    80003ff0:	00006497          	auipc	s1,0x6
    80003ff4:	0484a483          	lw	s1,72(s1) # 8000a038 <ticks>
  release(&tickslock);
    80003ff8:	00042517          	auipc	a0,0x42
    80003ffc:	b3050513          	addi	a0,a0,-1232 # 80045b28 <tickslock>
    80004000:	ffffd097          	auipc	ra,0xffffd
    80004004:	ce6080e7          	jalr	-794(ra) # 80000ce6 <release>
  return xticks;
}
    80004008:	02049513          	slli	a0,s1,0x20
    8000400c:	9101                	srli	a0,a0,0x20
    8000400e:	60e2                	ld	ra,24(sp)
    80004010:	6442                	ld	s0,16(sp)
    80004012:	64a2                	ld	s1,8(sp)
    80004014:	6105                	addi	sp,sp,32
    80004016:	8082                	ret

0000000080004018 <sys_sigprocmask>:

uint64
sys_sigprocmask(void)
{
    80004018:	1101                	addi	sp,sp,-32
    8000401a:	ec06                	sd	ra,24(sp)
    8000401c:	e822                	sd	s0,16(sp)
    8000401e:	1000                	addi	s0,sp,32
  
  uint64 mask;
  if(argaddr(0, &mask) < 0)
    80004020:	fe840593          	addi	a1,s0,-24
    80004024:	4501                	li	a0,0
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	d20080e7          	jalr	-736(ra) # 80003d46 <argaddr>
    8000402e:	87aa                	mv	a5,a0
    return -1;
    80004030:	557d                	li	a0,-1
  if(argaddr(0, &mask) < 0)
    80004032:	0007ca63          	bltz	a5,80004046 <sys_sigprocmask+0x2e>
  return sigprocmask(mask);
    80004036:	fe842503          	lw	a0,-24(s0)
    8000403a:	fffff097          	auipc	ra,0xfffff
    8000403e:	1ec080e7          	jalr	492(ra) # 80003226 <sigprocmask>
    80004042:	1502                	slli	a0,a0,0x20
    80004044:	9101                	srli	a0,a0,0x20
}
    80004046:	60e2                	ld	ra,24(sp)
    80004048:	6442                	ld	s0,16(sp)
    8000404a:	6105                	addi	sp,sp,32
    8000404c:	8082                	ret

000000008000404e <sys_sigaction>:

uint64
sys_sigaction(void)
{
    8000404e:	7179                	addi	sp,sp,-48
    80004050:	f406                	sd	ra,40(sp)
    80004052:	f022                	sd	s0,32(sp)
    80004054:	1800                	addi	s0,sp,48
  int signum;
  uint64 act;
  uint64 oldact;
  if(argint(0, &signum) < 0)
    80004056:	fec40593          	addi	a1,s0,-20
    8000405a:	4501                	li	a0,0
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	cc8080e7          	jalr	-824(ra) # 80003d24 <argint>
  {
    return -1;
    80004064:	57fd                	li	a5,-1
  if(argint(0, &signum) < 0)
    80004066:	04054163          	bltz	a0,800040a8 <sys_sigaction+0x5a>
  }
  if(argaddr(1, &act) < 0)
    8000406a:	fe040593          	addi	a1,s0,-32
    8000406e:	4505                	li	a0,1
    80004070:	00000097          	auipc	ra,0x0
    80004074:	cd6080e7          	jalr	-810(ra) # 80003d46 <argaddr>
  {
    return -1;
    80004078:	57fd                	li	a5,-1
  if(argaddr(1, &act) < 0)
    8000407a:	02054763          	bltz	a0,800040a8 <sys_sigaction+0x5a>
  }
  if(argaddr(2, &oldact) < 0)
    8000407e:	fd840593          	addi	a1,s0,-40
    80004082:	4509                	li	a0,2
    80004084:	00000097          	auipc	ra,0x0
    80004088:	cc2080e7          	jalr	-830(ra) # 80003d46 <argaddr>
  {
    return -1;
    8000408c:	57fd                	li	a5,-1
  if(argaddr(2, &oldact) < 0)
    8000408e:	00054d63          	bltz	a0,800040a8 <sys_sigaction+0x5a>
  }
  return sigaction(signum,(struct sigaction*)act,(struct sigaction*)oldact);
    80004092:	fd843603          	ld	a2,-40(s0)
    80004096:	fe043583          	ld	a1,-32(s0)
    8000409a:	fec42503          	lw	a0,-20(s0)
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	1bc080e7          	jalr	444(ra) # 8000325a <sigaction>
    800040a6:	87aa                	mv	a5,a0
}
    800040a8:	853e                	mv	a0,a5
    800040aa:	70a2                	ld	ra,40(sp)
    800040ac:	7402                	ld	s0,32(sp)
    800040ae:	6145                	addi	sp,sp,48
    800040b0:	8082                	ret

00000000800040b2 <sys_sigret>:

uint64
sys_sigret(void)
{
    800040b2:	1141                	addi	sp,sp,-16
    800040b4:	e406                	sd	ra,8(sp)
    800040b6:	e022                	sd	s0,0(sp)
    800040b8:	0800                	addi	s0,sp,16
  sigret();
    800040ba:	fffff097          	auipc	ra,0xfffff
    800040be:	256080e7          	jalr	598(ra) # 80003310 <sigret>
  return 0;
}
    800040c2:	4501                	li	a0,0
    800040c4:	60a2                	ld	ra,8(sp)
    800040c6:	6402                	ld	s0,0(sp)
    800040c8:	0141                	addi	sp,sp,16
    800040ca:	8082                	ret

00000000800040cc <sys_kthread_create>:

uint64
sys_kthread_create(void)
{
    800040cc:	1101                	addi	sp,sp,-32
    800040ce:	ec06                	sd	ra,24(sp)
    800040d0:	e822                	sd	s0,16(sp)
    800040d2:	1000                	addi	s0,sp,32
  uint64 start_func;
  uint64 stack;
  if(argaddr(0, &start_func) < 0)
    800040d4:	fe840593          	addi	a1,s0,-24
    800040d8:	4501                	li	a0,0
    800040da:	00000097          	auipc	ra,0x0
    800040de:	c6c080e7          	jalr	-916(ra) # 80003d46 <argaddr>
    return -1;
    800040e2:	57fd                	li	a5,-1
  if(argaddr(0, &start_func) < 0)
    800040e4:	02054563          	bltz	a0,8000410e <sys_kthread_create+0x42>
  if(argaddr(1, &stack) < 0)
    800040e8:	fe040593          	addi	a1,s0,-32
    800040ec:	4505                	li	a0,1
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	c58080e7          	jalr	-936(ra) # 80003d46 <argaddr>
    return -1;
    800040f6:	57fd                	li	a5,-1
  if(argaddr(1, &stack) < 0)
    800040f8:	00054b63          	bltz	a0,8000410e <sys_kthread_create+0x42>
    
  return kthread_create((void (*)())start_func,(void*)stack);
    800040fc:	fe043583          	ld	a1,-32(s0)
    80004100:	fe843503          	ld	a0,-24(s0)
    80004104:	ffffe097          	auipc	ra,0xffffe
    80004108:	1d4080e7          	jalr	468(ra) # 800022d8 <kthread_create>
    8000410c:	87aa                	mv	a5,a0
}
    8000410e:	853e                	mv	a0,a5
    80004110:	60e2                	ld	ra,24(sp)
    80004112:	6442                	ld	s0,16(sp)
    80004114:	6105                	addi	sp,sp,32
    80004116:	8082                	ret

0000000080004118 <sys_kthread_id>:

uint64
sys_kthread_id(void)
{
    80004118:	1141                	addi	sp,sp,-16
    8000411a:	e406                	sd	ra,8(sp)
    8000411c:	e022                	sd	s0,0(sp)
    8000411e:	0800                	addi	s0,sp,16
  return mythread()->tid;
    80004120:	ffffe097          	auipc	ra,0xffffe
    80004124:	99c080e7          	jalr	-1636(ra) # 80001abc <mythread>
}
    80004128:	4108                	lw	a0,0(a0)
    8000412a:	60a2                	ld	ra,8(sp)
    8000412c:	6402                	ld	s0,0(sp)
    8000412e:	0141                	addi	sp,sp,16
    80004130:	8082                	ret

0000000080004132 <sys_kthread_exit>:

uint64
sys_kthread_exit(void)
{
    80004132:	1101                	addi	sp,sp,-32
    80004134:	ec06                	sd	ra,24(sp)
    80004136:	e822                	sd	s0,16(sp)
    80004138:	1000                	addi	s0,sp,32
  
  int status;
  if(argint(0, &status) < 0)
    8000413a:	fec40593          	addi	a1,s0,-20
    8000413e:	4501                	li	a0,0
    80004140:	00000097          	auipc	ra,0x0
    80004144:	be4080e7          	jalr	-1052(ra) # 80003d24 <argint>
  {
    return -1;
    80004148:	57fd                	li	a5,-1
  if(argint(0, &status) < 0)
    8000414a:	00054963          	bltz	a0,8000415c <sys_kthread_exit+0x2a>
  }
  kthread_exit(status);
    8000414e:	fec42503          	lw	a0,-20(s0)
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	d16080e7          	jalr	-746(ra) # 80002e68 <kthread_exit>
  return 0;
    8000415a:	4781                	li	a5,0
}
    8000415c:	853e                	mv	a0,a5
    8000415e:	60e2                	ld	ra,24(sp)
    80004160:	6442                	ld	s0,16(sp)
    80004162:	6105                	addi	sp,sp,32
    80004164:	8082                	ret

0000000080004166 <sys_kthread_join>:

uint64
sys_kthread_join(void)
{
    80004166:	1101                	addi	sp,sp,-32
    80004168:	ec06                	sd	ra,24(sp)
    8000416a:	e822                	sd	s0,16(sp)
    8000416c:	1000                	addi	s0,sp,32
  
  int thread_id;
  uint64 status;
  if(argint(0, &thread_id) < 0)
    8000416e:	fec40593          	addi	a1,s0,-20
    80004172:	4501                	li	a0,0
    80004174:	00000097          	auipc	ra,0x0
    80004178:	bb0080e7          	jalr	-1104(ra) # 80003d24 <argint>
    return -1;
    8000417c:	57fd                	li	a5,-1
  if(argint(0, &thread_id) < 0)
    8000417e:	02054563          	bltz	a0,800041a8 <sys_kthread_join+0x42>
  if(argaddr(1, &status) < 0)
    80004182:	fe040593          	addi	a1,s0,-32
    80004186:	4505                	li	a0,1
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	bbe080e7          	jalr	-1090(ra) # 80003d46 <argaddr>
    return -1; 
    80004190:	57fd                	li	a5,-1
  if(argaddr(1, &status) < 0)
    80004192:	00054b63          	bltz	a0,800041a8 <sys_kthread_join+0x42>
  return kthread_join(thread_id,(int*)status);
    80004196:	fe043583          	ld	a1,-32(s0)
    8000419a:	fec42503          	lw	a0,-20(s0)
    8000419e:	fffff097          	auipc	ra,0xfffff
    800041a2:	c1c080e7          	jalr	-996(ra) # 80002dba <kthread_join>
    800041a6:	87aa                	mv	a5,a0
}
    800041a8:	853e                	mv	a0,a5
    800041aa:	60e2                	ld	ra,24(sp)
    800041ac:	6442                	ld	s0,16(sp)
    800041ae:	6105                	addi	sp,sp,32
    800041b0:	8082                	ret

00000000800041b2 <sys_bsem_alloc>:

uint64
sys_bsem_alloc(void)
{
    800041b2:	1141                	addi	sp,sp,-16
    800041b4:	e406                	sd	ra,8(sp)
    800041b6:	e022                	sd	s0,0(sp)
    800041b8:	0800                	addi	s0,sp,16
  int bsem_descriptor=allocBsem();
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	354080e7          	jalr	852(ra) # 8000350e <allocBsem>
  return bsem_descriptor;
}
    800041c2:	60a2                	ld	ra,8(sp)
    800041c4:	6402                	ld	s0,0(sp)
    800041c6:	0141                	addi	sp,sp,16
    800041c8:	8082                	ret

00000000800041ca <sys_bsem_free>:

uint64
sys_bsem_free(void)
{
    800041ca:	1101                	addi	sp,sp,-32
    800041cc:	ec06                	sd	ra,24(sp)
    800041ce:	e822                	sd	s0,16(sp)
    800041d0:	1000                	addi	s0,sp,32
  int bsem;
  if(argint(0, &bsem) < 0)
    800041d2:	fec40593          	addi	a1,s0,-20
    800041d6:	4501                	li	a0,0
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	b4c080e7          	jalr	-1204(ra) # 80003d24 <argint>
  {
    return -1;
    800041e0:	57fd                	li	a5,-1
  if(argint(0, &bsem) < 0)
    800041e2:	00054963          	bltz	a0,800041f4 <sys_bsem_free+0x2a>
  }
  bsem_free(bsem);
    800041e6:	fec42503          	lw	a0,-20(s0)
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	474080e7          	jalr	1140(ra) # 8000365e <bsem_free>
  return 0;
    800041f2:	4781                	li	a5,0
}
    800041f4:	853e                	mv	a0,a5
    800041f6:	60e2                	ld	ra,24(sp)
    800041f8:	6442                	ld	s0,16(sp)
    800041fa:	6105                	addi	sp,sp,32
    800041fc:	8082                	ret

00000000800041fe <sys_bsem_down>:

uint64
sys_bsem_down(void)
{
    800041fe:	1101                	addi	sp,sp,-32
    80004200:	ec06                	sd	ra,24(sp)
    80004202:	e822                	sd	s0,16(sp)
    80004204:	1000                	addi	s0,sp,32
  int bsem;
  if(argint(0, &bsem) < 0)
    80004206:	fec40593          	addi	a1,s0,-20
    8000420a:	4501                	li	a0,0
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	b18080e7          	jalr	-1256(ra) # 80003d24 <argint>
  {
    return -1;
    80004214:	57fd                	li	a5,-1
  if(argint(0, &bsem) < 0)
    80004216:	00054963          	bltz	a0,80004228 <sys_bsem_down+0x2a>
  }
  bsem_down(bsem);
    8000421a:	fec42503          	lw	a0,-20(s0)
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	4c6080e7          	jalr	1222(ra) # 800036e4 <bsem_down>
  return 0;
    80004226:	4781                	li	a5,0
}
    80004228:	853e                	mv	a0,a5
    8000422a:	60e2                	ld	ra,24(sp)
    8000422c:	6442                	ld	s0,16(sp)
    8000422e:	6105                	addi	sp,sp,32
    80004230:	8082                	ret

0000000080004232 <sys_bsem_up>:

uint64
sys_bsem_up(void)
{
    80004232:	1101                	addi	sp,sp,-32
    80004234:	ec06                	sd	ra,24(sp)
    80004236:	e822                	sd	s0,16(sp)
    80004238:	1000                	addi	s0,sp,32
  int bsem;
  if(argint(0, &bsem) < 0)
    8000423a:	fec40593          	addi	a1,s0,-20
    8000423e:	4501                	li	a0,0
    80004240:	00000097          	auipc	ra,0x0
    80004244:	ae4080e7          	jalr	-1308(ra) # 80003d24 <argint>
  {
    return -1;
    80004248:	57fd                	li	a5,-1
  if(argint(0, &bsem) < 0)
    8000424a:	00054963          	bltz	a0,8000425c <sys_bsem_up+0x2a>
  }
  bsem_up(bsem);
    8000424e:	fec42503          	lw	a0,-20(s0)
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	51c080e7          	jalr	1308(ra) # 8000376e <bsem_up>
  return 0;
    8000425a:	4781                	li	a5,0
    8000425c:	853e                	mv	a0,a5
    8000425e:	60e2                	ld	ra,24(sp)
    80004260:	6442                	ld	s0,16(sp)
    80004262:	6105                	addi	sp,sp,32
    80004264:	8082                	ret

0000000080004266 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80004266:	7179                	addi	sp,sp,-48
    80004268:	f406                	sd	ra,40(sp)
    8000426a:	f022                	sd	s0,32(sp)
    8000426c:	ec26                	sd	s1,24(sp)
    8000426e:	e84a                	sd	s2,16(sp)
    80004270:	e44e                	sd	s3,8(sp)
    80004272:	e052                	sd	s4,0(sp)
    80004274:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80004276:	00005597          	auipc	a1,0x5
    8000427a:	34a58593          	addi	a1,a1,842 # 800095c0 <syscalls+0x108>
    8000427e:	00042517          	auipc	a0,0x42
    80004282:	8c250513          	addi	a0,a0,-1854 # 80045b40 <bcache>
    80004286:	ffffd097          	auipc	ra,0xffffd
    8000428a:	8cc080e7          	jalr	-1844(ra) # 80000b52 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000428e:	0004a797          	auipc	a5,0x4a
    80004292:	8b278793          	addi	a5,a5,-1870 # 8004db40 <bcache+0x8000>
    80004296:	0004a717          	auipc	a4,0x4a
    8000429a:	b1270713          	addi	a4,a4,-1262 # 8004dda8 <bcache+0x8268>
    8000429e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800042a2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800042a6:	00042497          	auipc	s1,0x42
    800042aa:	8b248493          	addi	s1,s1,-1870 # 80045b58 <bcache+0x18>
    b->next = bcache.head.next;
    800042ae:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800042b0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800042b2:	00005a17          	auipc	s4,0x5
    800042b6:	316a0a13          	addi	s4,s4,790 # 800095c8 <syscalls+0x110>
    b->next = bcache.head.next;
    800042ba:	2b893783          	ld	a5,696(s2)
    800042be:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800042c0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800042c4:	85d2                	mv	a1,s4
    800042c6:	01048513          	addi	a0,s1,16
    800042ca:	00001097          	auipc	ra,0x1
    800042ce:	4c0080e7          	jalr	1216(ra) # 8000578a <initsleeplock>
    bcache.head.next->prev = b;
    800042d2:	2b893783          	ld	a5,696(s2)
    800042d6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800042d8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800042dc:	45848493          	addi	s1,s1,1112
    800042e0:	fd349de3          	bne	s1,s3,800042ba <binit+0x54>
  }
}
    800042e4:	70a2                	ld	ra,40(sp)
    800042e6:	7402                	ld	s0,32(sp)
    800042e8:	64e2                	ld	s1,24(sp)
    800042ea:	6942                	ld	s2,16(sp)
    800042ec:	69a2                	ld	s3,8(sp)
    800042ee:	6a02                	ld	s4,0(sp)
    800042f0:	6145                	addi	sp,sp,48
    800042f2:	8082                	ret

00000000800042f4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800042f4:	7179                	addi	sp,sp,-48
    800042f6:	f406                	sd	ra,40(sp)
    800042f8:	f022                	sd	s0,32(sp)
    800042fa:	ec26                	sd	s1,24(sp)
    800042fc:	e84a                	sd	s2,16(sp)
    800042fe:	e44e                	sd	s3,8(sp)
    80004300:	1800                	addi	s0,sp,48
    80004302:	892a                	mv	s2,a0
    80004304:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80004306:	00042517          	auipc	a0,0x42
    8000430a:	83a50513          	addi	a0,a0,-1990 # 80045b40 <bcache>
    8000430e:	ffffd097          	auipc	ra,0xffffd
    80004312:	924080e7          	jalr	-1756(ra) # 80000c32 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80004316:	0004a497          	auipc	s1,0x4a
    8000431a:	ae24b483          	ld	s1,-1310(s1) # 8004ddf8 <bcache+0x82b8>
    8000431e:	0004a797          	auipc	a5,0x4a
    80004322:	a8a78793          	addi	a5,a5,-1398 # 8004dda8 <bcache+0x8268>
    80004326:	02f48f63          	beq	s1,a5,80004364 <bread+0x70>
    8000432a:	873e                	mv	a4,a5
    8000432c:	a021                	j	80004334 <bread+0x40>
    8000432e:	68a4                	ld	s1,80(s1)
    80004330:	02e48a63          	beq	s1,a4,80004364 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80004334:	449c                	lw	a5,8(s1)
    80004336:	ff279ce3          	bne	a5,s2,8000432e <bread+0x3a>
    8000433a:	44dc                	lw	a5,12(s1)
    8000433c:	ff3799e3          	bne	a5,s3,8000432e <bread+0x3a>
      b->refcnt++;
    80004340:	40bc                	lw	a5,64(s1)
    80004342:	2785                	addiw	a5,a5,1
    80004344:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80004346:	00041517          	auipc	a0,0x41
    8000434a:	7fa50513          	addi	a0,a0,2042 # 80045b40 <bcache>
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	998080e7          	jalr	-1640(ra) # 80000ce6 <release>
      acquiresleep(&b->lock);
    80004356:	01048513          	addi	a0,s1,16
    8000435a:	00001097          	auipc	ra,0x1
    8000435e:	46a080e7          	jalr	1130(ra) # 800057c4 <acquiresleep>
      return b;
    80004362:	a8b9                	j	800043c0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80004364:	0004a497          	auipc	s1,0x4a
    80004368:	a8c4b483          	ld	s1,-1396(s1) # 8004ddf0 <bcache+0x82b0>
    8000436c:	0004a797          	auipc	a5,0x4a
    80004370:	a3c78793          	addi	a5,a5,-1476 # 8004dda8 <bcache+0x8268>
    80004374:	00f48863          	beq	s1,a5,80004384 <bread+0x90>
    80004378:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000437a:	40bc                	lw	a5,64(s1)
    8000437c:	cf81                	beqz	a5,80004394 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000437e:	64a4                	ld	s1,72(s1)
    80004380:	fee49de3          	bne	s1,a4,8000437a <bread+0x86>
  panic("bget: no buffers");
    80004384:	00005517          	auipc	a0,0x5
    80004388:	24c50513          	addi	a0,a0,588 # 800095d0 <syscalls+0x118>
    8000438c:	ffffc097          	auipc	ra,0xffffc
    80004390:	19e080e7          	jalr	414(ra) # 8000052a <panic>
      b->dev = dev;
    80004394:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80004398:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000439c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800043a0:	4785                	li	a5,1
    800043a2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800043a4:	00041517          	auipc	a0,0x41
    800043a8:	79c50513          	addi	a0,a0,1948 # 80045b40 <bcache>
    800043ac:	ffffd097          	auipc	ra,0xffffd
    800043b0:	93a080e7          	jalr	-1734(ra) # 80000ce6 <release>
      acquiresleep(&b->lock);
    800043b4:	01048513          	addi	a0,s1,16
    800043b8:	00001097          	auipc	ra,0x1
    800043bc:	40c080e7          	jalr	1036(ra) # 800057c4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800043c0:	409c                	lw	a5,0(s1)
    800043c2:	cb89                	beqz	a5,800043d4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800043c4:	8526                	mv	a0,s1
    800043c6:	70a2                	ld	ra,40(sp)
    800043c8:	7402                	ld	s0,32(sp)
    800043ca:	64e2                	ld	s1,24(sp)
    800043cc:	6942                	ld	s2,16(sp)
    800043ce:	69a2                	ld	s3,8(sp)
    800043d0:	6145                	addi	sp,sp,48
    800043d2:	8082                	ret
    virtio_disk_rw(b, 0);
    800043d4:	4581                	li	a1,0
    800043d6:	8526                	mv	a0,s1
    800043d8:	00003097          	auipc	ra,0x3
    800043dc:	f6e080e7          	jalr	-146(ra) # 80007346 <virtio_disk_rw>
    b->valid = 1;
    800043e0:	4785                	li	a5,1
    800043e2:	c09c                	sw	a5,0(s1)
  return b;
    800043e4:	b7c5                	j	800043c4 <bread+0xd0>

00000000800043e6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800043e6:	1101                	addi	sp,sp,-32
    800043e8:	ec06                	sd	ra,24(sp)
    800043ea:	e822                	sd	s0,16(sp)
    800043ec:	e426                	sd	s1,8(sp)
    800043ee:	1000                	addi	s0,sp,32
    800043f0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800043f2:	0541                	addi	a0,a0,16
    800043f4:	00001097          	auipc	ra,0x1
    800043f8:	46a080e7          	jalr	1130(ra) # 8000585e <holdingsleep>
    800043fc:	cd01                	beqz	a0,80004414 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800043fe:	4585                	li	a1,1
    80004400:	8526                	mv	a0,s1
    80004402:	00003097          	auipc	ra,0x3
    80004406:	f44080e7          	jalr	-188(ra) # 80007346 <virtio_disk_rw>
}
    8000440a:	60e2                	ld	ra,24(sp)
    8000440c:	6442                	ld	s0,16(sp)
    8000440e:	64a2                	ld	s1,8(sp)
    80004410:	6105                	addi	sp,sp,32
    80004412:	8082                	ret
    panic("bwrite");
    80004414:	00005517          	auipc	a0,0x5
    80004418:	1d450513          	addi	a0,a0,468 # 800095e8 <syscalls+0x130>
    8000441c:	ffffc097          	auipc	ra,0xffffc
    80004420:	10e080e7          	jalr	270(ra) # 8000052a <panic>

0000000080004424 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	e426                	sd	s1,8(sp)
    8000442c:	e04a                	sd	s2,0(sp)
    8000442e:	1000                	addi	s0,sp,32
    80004430:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80004432:	01050913          	addi	s2,a0,16
    80004436:	854a                	mv	a0,s2
    80004438:	00001097          	auipc	ra,0x1
    8000443c:	426080e7          	jalr	1062(ra) # 8000585e <holdingsleep>
    80004440:	c92d                	beqz	a0,800044b2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80004442:	854a                	mv	a0,s2
    80004444:	00001097          	auipc	ra,0x1
    80004448:	3d6080e7          	jalr	982(ra) # 8000581a <releasesleep>

  acquire(&bcache.lock);
    8000444c:	00041517          	auipc	a0,0x41
    80004450:	6f450513          	addi	a0,a0,1780 # 80045b40 <bcache>
    80004454:	ffffc097          	auipc	ra,0xffffc
    80004458:	7de080e7          	jalr	2014(ra) # 80000c32 <acquire>
  b->refcnt--;
    8000445c:	40bc                	lw	a5,64(s1)
    8000445e:	37fd                	addiw	a5,a5,-1
    80004460:	0007871b          	sext.w	a4,a5
    80004464:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80004466:	eb05                	bnez	a4,80004496 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80004468:	68bc                	ld	a5,80(s1)
    8000446a:	64b8                	ld	a4,72(s1)
    8000446c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000446e:	64bc                	ld	a5,72(s1)
    80004470:	68b8                	ld	a4,80(s1)
    80004472:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80004474:	00049797          	auipc	a5,0x49
    80004478:	6cc78793          	addi	a5,a5,1740 # 8004db40 <bcache+0x8000>
    8000447c:	2b87b703          	ld	a4,696(a5)
    80004480:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80004482:	0004a717          	auipc	a4,0x4a
    80004486:	92670713          	addi	a4,a4,-1754 # 8004dda8 <bcache+0x8268>
    8000448a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000448c:	2b87b703          	ld	a4,696(a5)
    80004490:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80004492:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80004496:	00041517          	auipc	a0,0x41
    8000449a:	6aa50513          	addi	a0,a0,1706 # 80045b40 <bcache>
    8000449e:	ffffd097          	auipc	ra,0xffffd
    800044a2:	848080e7          	jalr	-1976(ra) # 80000ce6 <release>
}
    800044a6:	60e2                	ld	ra,24(sp)
    800044a8:	6442                	ld	s0,16(sp)
    800044aa:	64a2                	ld	s1,8(sp)
    800044ac:	6902                	ld	s2,0(sp)
    800044ae:	6105                	addi	sp,sp,32
    800044b0:	8082                	ret
    panic("brelse");
    800044b2:	00005517          	auipc	a0,0x5
    800044b6:	13e50513          	addi	a0,a0,318 # 800095f0 <syscalls+0x138>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	070080e7          	jalr	112(ra) # 8000052a <panic>

00000000800044c2 <bpin>:

void
bpin(struct buf *b) {
    800044c2:	1101                	addi	sp,sp,-32
    800044c4:	ec06                	sd	ra,24(sp)
    800044c6:	e822                	sd	s0,16(sp)
    800044c8:	e426                	sd	s1,8(sp)
    800044ca:	1000                	addi	s0,sp,32
    800044cc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800044ce:	00041517          	auipc	a0,0x41
    800044d2:	67250513          	addi	a0,a0,1650 # 80045b40 <bcache>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	75c080e7          	jalr	1884(ra) # 80000c32 <acquire>
  b->refcnt++;
    800044de:	40bc                	lw	a5,64(s1)
    800044e0:	2785                	addiw	a5,a5,1
    800044e2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800044e4:	00041517          	auipc	a0,0x41
    800044e8:	65c50513          	addi	a0,a0,1628 # 80045b40 <bcache>
    800044ec:	ffffc097          	auipc	ra,0xffffc
    800044f0:	7fa080e7          	jalr	2042(ra) # 80000ce6 <release>
}
    800044f4:	60e2                	ld	ra,24(sp)
    800044f6:	6442                	ld	s0,16(sp)
    800044f8:	64a2                	ld	s1,8(sp)
    800044fa:	6105                	addi	sp,sp,32
    800044fc:	8082                	ret

00000000800044fe <bunpin>:

void
bunpin(struct buf *b) {
    800044fe:	1101                	addi	sp,sp,-32
    80004500:	ec06                	sd	ra,24(sp)
    80004502:	e822                	sd	s0,16(sp)
    80004504:	e426                	sd	s1,8(sp)
    80004506:	1000                	addi	s0,sp,32
    80004508:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000450a:	00041517          	auipc	a0,0x41
    8000450e:	63650513          	addi	a0,a0,1590 # 80045b40 <bcache>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	720080e7          	jalr	1824(ra) # 80000c32 <acquire>
  b->refcnt--;
    8000451a:	40bc                	lw	a5,64(s1)
    8000451c:	37fd                	addiw	a5,a5,-1
    8000451e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80004520:	00041517          	auipc	a0,0x41
    80004524:	62050513          	addi	a0,a0,1568 # 80045b40 <bcache>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	7be080e7          	jalr	1982(ra) # 80000ce6 <release>
}
    80004530:	60e2                	ld	ra,24(sp)
    80004532:	6442                	ld	s0,16(sp)
    80004534:	64a2                	ld	s1,8(sp)
    80004536:	6105                	addi	sp,sp,32
    80004538:	8082                	ret

000000008000453a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000453a:	1101                	addi	sp,sp,-32
    8000453c:	ec06                	sd	ra,24(sp)
    8000453e:	e822                	sd	s0,16(sp)
    80004540:	e426                	sd	s1,8(sp)
    80004542:	e04a                	sd	s2,0(sp)
    80004544:	1000                	addi	s0,sp,32
    80004546:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80004548:	00d5d59b          	srliw	a1,a1,0xd
    8000454c:	0004a797          	auipc	a5,0x4a
    80004550:	cd07a783          	lw	a5,-816(a5) # 8004e21c <sb+0x1c>
    80004554:	9dbd                	addw	a1,a1,a5
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	d9e080e7          	jalr	-610(ra) # 800042f4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000455e:	0074f713          	andi	a4,s1,7
    80004562:	4785                	li	a5,1
    80004564:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80004568:	14ce                	slli	s1,s1,0x33
    8000456a:	90d9                	srli	s1,s1,0x36
    8000456c:	00950733          	add	a4,a0,s1
    80004570:	05874703          	lbu	a4,88(a4)
    80004574:	00e7f6b3          	and	a3,a5,a4
    80004578:	c69d                	beqz	a3,800045a6 <bfree+0x6c>
    8000457a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000457c:	94aa                	add	s1,s1,a0
    8000457e:	fff7c793          	not	a5,a5
    80004582:	8ff9                	and	a5,a5,a4
    80004584:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80004588:	00001097          	auipc	ra,0x1
    8000458c:	11c080e7          	jalr	284(ra) # 800056a4 <log_write>
  brelse(bp);
    80004590:	854a                	mv	a0,s2
    80004592:	00000097          	auipc	ra,0x0
    80004596:	e92080e7          	jalr	-366(ra) # 80004424 <brelse>
}
    8000459a:	60e2                	ld	ra,24(sp)
    8000459c:	6442                	ld	s0,16(sp)
    8000459e:	64a2                	ld	s1,8(sp)
    800045a0:	6902                	ld	s2,0(sp)
    800045a2:	6105                	addi	sp,sp,32
    800045a4:	8082                	ret
    panic("freeing free block");
    800045a6:	00005517          	auipc	a0,0x5
    800045aa:	05250513          	addi	a0,a0,82 # 800095f8 <syscalls+0x140>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	f7c080e7          	jalr	-132(ra) # 8000052a <panic>

00000000800045b6 <balloc>:
{
    800045b6:	711d                	addi	sp,sp,-96
    800045b8:	ec86                	sd	ra,88(sp)
    800045ba:	e8a2                	sd	s0,80(sp)
    800045bc:	e4a6                	sd	s1,72(sp)
    800045be:	e0ca                	sd	s2,64(sp)
    800045c0:	fc4e                	sd	s3,56(sp)
    800045c2:	f852                	sd	s4,48(sp)
    800045c4:	f456                	sd	s5,40(sp)
    800045c6:	f05a                	sd	s6,32(sp)
    800045c8:	ec5e                	sd	s7,24(sp)
    800045ca:	e862                	sd	s8,16(sp)
    800045cc:	e466                	sd	s9,8(sp)
    800045ce:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800045d0:	0004a797          	auipc	a5,0x4a
    800045d4:	c347a783          	lw	a5,-972(a5) # 8004e204 <sb+0x4>
    800045d8:	cbd1                	beqz	a5,8000466c <balloc+0xb6>
    800045da:	8baa                	mv	s7,a0
    800045dc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800045de:	0004ab17          	auipc	s6,0x4a
    800045e2:	c22b0b13          	addi	s6,s6,-990 # 8004e200 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800045e6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800045e8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800045ea:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800045ec:	6c89                	lui	s9,0x2
    800045ee:	a831                	j	8000460a <balloc+0x54>
    brelse(bp);
    800045f0:	854a                	mv	a0,s2
    800045f2:	00000097          	auipc	ra,0x0
    800045f6:	e32080e7          	jalr	-462(ra) # 80004424 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800045fa:	015c87bb          	addw	a5,s9,s5
    800045fe:	00078a9b          	sext.w	s5,a5
    80004602:	004b2703          	lw	a4,4(s6)
    80004606:	06eaf363          	bgeu	s5,a4,8000466c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000460a:	41fad79b          	sraiw	a5,s5,0x1f
    8000460e:	0137d79b          	srliw	a5,a5,0x13
    80004612:	015787bb          	addw	a5,a5,s5
    80004616:	40d7d79b          	sraiw	a5,a5,0xd
    8000461a:	01cb2583          	lw	a1,28(s6)
    8000461e:	9dbd                	addw	a1,a1,a5
    80004620:	855e                	mv	a0,s7
    80004622:	00000097          	auipc	ra,0x0
    80004626:	cd2080e7          	jalr	-814(ra) # 800042f4 <bread>
    8000462a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000462c:	004b2503          	lw	a0,4(s6)
    80004630:	000a849b          	sext.w	s1,s5
    80004634:	8662                	mv	a2,s8
    80004636:	faa4fde3          	bgeu	s1,a0,800045f0 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000463a:	41f6579b          	sraiw	a5,a2,0x1f
    8000463e:	01d7d69b          	srliw	a3,a5,0x1d
    80004642:	00c6873b          	addw	a4,a3,a2
    80004646:	00777793          	andi	a5,a4,7
    8000464a:	9f95                	subw	a5,a5,a3
    8000464c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80004650:	4037571b          	sraiw	a4,a4,0x3
    80004654:	00e906b3          	add	a3,s2,a4
    80004658:	0586c683          	lbu	a3,88(a3)
    8000465c:	00d7f5b3          	and	a1,a5,a3
    80004660:	cd91                	beqz	a1,8000467c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004662:	2605                	addiw	a2,a2,1
    80004664:	2485                	addiw	s1,s1,1
    80004666:	fd4618e3          	bne	a2,s4,80004636 <balloc+0x80>
    8000466a:	b759                	j	800045f0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000466c:	00005517          	auipc	a0,0x5
    80004670:	fa450513          	addi	a0,a0,-92 # 80009610 <syscalls+0x158>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	eb6080e7          	jalr	-330(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000467c:	974a                	add	a4,a4,s2
    8000467e:	8fd5                	or	a5,a5,a3
    80004680:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80004684:	854a                	mv	a0,s2
    80004686:	00001097          	auipc	ra,0x1
    8000468a:	01e080e7          	jalr	30(ra) # 800056a4 <log_write>
        brelse(bp);
    8000468e:	854a                	mv	a0,s2
    80004690:	00000097          	auipc	ra,0x0
    80004694:	d94080e7          	jalr	-620(ra) # 80004424 <brelse>
  bp = bread(dev, bno);
    80004698:	85a6                	mv	a1,s1
    8000469a:	855e                	mv	a0,s7
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	c58080e7          	jalr	-936(ra) # 800042f4 <bread>
    800046a4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800046a6:	40000613          	li	a2,1024
    800046aa:	4581                	li	a1,0
    800046ac:	05850513          	addi	a0,a0,88
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	69a080e7          	jalr	1690(ra) # 80000d4a <memset>
  log_write(bp);
    800046b8:	854a                	mv	a0,s2
    800046ba:	00001097          	auipc	ra,0x1
    800046be:	fea080e7          	jalr	-22(ra) # 800056a4 <log_write>
  brelse(bp);
    800046c2:	854a                	mv	a0,s2
    800046c4:	00000097          	auipc	ra,0x0
    800046c8:	d60080e7          	jalr	-672(ra) # 80004424 <brelse>
}
    800046cc:	8526                	mv	a0,s1
    800046ce:	60e6                	ld	ra,88(sp)
    800046d0:	6446                	ld	s0,80(sp)
    800046d2:	64a6                	ld	s1,72(sp)
    800046d4:	6906                	ld	s2,64(sp)
    800046d6:	79e2                	ld	s3,56(sp)
    800046d8:	7a42                	ld	s4,48(sp)
    800046da:	7aa2                	ld	s5,40(sp)
    800046dc:	7b02                	ld	s6,32(sp)
    800046de:	6be2                	ld	s7,24(sp)
    800046e0:	6c42                	ld	s8,16(sp)
    800046e2:	6ca2                	ld	s9,8(sp)
    800046e4:	6125                	addi	sp,sp,96
    800046e6:	8082                	ret

00000000800046e8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800046e8:	7179                	addi	sp,sp,-48
    800046ea:	f406                	sd	ra,40(sp)
    800046ec:	f022                	sd	s0,32(sp)
    800046ee:	ec26                	sd	s1,24(sp)
    800046f0:	e84a                	sd	s2,16(sp)
    800046f2:	e44e                	sd	s3,8(sp)
    800046f4:	e052                	sd	s4,0(sp)
    800046f6:	1800                	addi	s0,sp,48
    800046f8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800046fa:	47ad                	li	a5,11
    800046fc:	04b7fe63          	bgeu	a5,a1,80004758 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80004700:	ff45849b          	addiw	s1,a1,-12
    80004704:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80004708:	0ff00793          	li	a5,255
    8000470c:	0ae7e463          	bltu	a5,a4,800047b4 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80004710:	08052583          	lw	a1,128(a0)
    80004714:	c5b5                	beqz	a1,80004780 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80004716:	00092503          	lw	a0,0(s2)
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	bda080e7          	jalr	-1062(ra) # 800042f4 <bread>
    80004722:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80004724:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80004728:	02049713          	slli	a4,s1,0x20
    8000472c:	01e75593          	srli	a1,a4,0x1e
    80004730:	00b784b3          	add	s1,a5,a1
    80004734:	0004a983          	lw	s3,0(s1)
    80004738:	04098e63          	beqz	s3,80004794 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000473c:	8552                	mv	a0,s4
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	ce6080e7          	jalr	-794(ra) # 80004424 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80004746:	854e                	mv	a0,s3
    80004748:	70a2                	ld	ra,40(sp)
    8000474a:	7402                	ld	s0,32(sp)
    8000474c:	64e2                	ld	s1,24(sp)
    8000474e:	6942                	ld	s2,16(sp)
    80004750:	69a2                	ld	s3,8(sp)
    80004752:	6a02                	ld	s4,0(sp)
    80004754:	6145                	addi	sp,sp,48
    80004756:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80004758:	02059793          	slli	a5,a1,0x20
    8000475c:	01e7d593          	srli	a1,a5,0x1e
    80004760:	00b504b3          	add	s1,a0,a1
    80004764:	0504a983          	lw	s3,80(s1)
    80004768:	fc099fe3          	bnez	s3,80004746 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000476c:	4108                	lw	a0,0(a0)
    8000476e:	00000097          	auipc	ra,0x0
    80004772:	e48080e7          	jalr	-440(ra) # 800045b6 <balloc>
    80004776:	0005099b          	sext.w	s3,a0
    8000477a:	0534a823          	sw	s3,80(s1)
    8000477e:	b7e1                	j	80004746 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80004780:	4108                	lw	a0,0(a0)
    80004782:	00000097          	auipc	ra,0x0
    80004786:	e34080e7          	jalr	-460(ra) # 800045b6 <balloc>
    8000478a:	0005059b          	sext.w	a1,a0
    8000478e:	08b92023          	sw	a1,128(s2)
    80004792:	b751                	j	80004716 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80004794:	00092503          	lw	a0,0(s2)
    80004798:	00000097          	auipc	ra,0x0
    8000479c:	e1e080e7          	jalr	-482(ra) # 800045b6 <balloc>
    800047a0:	0005099b          	sext.w	s3,a0
    800047a4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800047a8:	8552                	mv	a0,s4
    800047aa:	00001097          	auipc	ra,0x1
    800047ae:	efa080e7          	jalr	-262(ra) # 800056a4 <log_write>
    800047b2:	b769                	j	8000473c <bmap+0x54>
  panic("bmap: out of range");
    800047b4:	00005517          	auipc	a0,0x5
    800047b8:	e7450513          	addi	a0,a0,-396 # 80009628 <syscalls+0x170>
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	d6e080e7          	jalr	-658(ra) # 8000052a <panic>

00000000800047c4 <iget>:
{
    800047c4:	7179                	addi	sp,sp,-48
    800047c6:	f406                	sd	ra,40(sp)
    800047c8:	f022                	sd	s0,32(sp)
    800047ca:	ec26                	sd	s1,24(sp)
    800047cc:	e84a                	sd	s2,16(sp)
    800047ce:	e44e                	sd	s3,8(sp)
    800047d0:	e052                	sd	s4,0(sp)
    800047d2:	1800                	addi	s0,sp,48
    800047d4:	89aa                	mv	s3,a0
    800047d6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800047d8:	0004a517          	auipc	a0,0x4a
    800047dc:	a4850513          	addi	a0,a0,-1464 # 8004e220 <itable>
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	452080e7          	jalr	1106(ra) # 80000c32 <acquire>
  empty = 0;
    800047e8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800047ea:	0004a497          	auipc	s1,0x4a
    800047ee:	a4e48493          	addi	s1,s1,-1458 # 8004e238 <itable+0x18>
    800047f2:	0004b697          	auipc	a3,0x4b
    800047f6:	4d668693          	addi	a3,a3,1238 # 8004fcc8 <log>
    800047fa:	a039                	j	80004808 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800047fc:	02090b63          	beqz	s2,80004832 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004800:	08848493          	addi	s1,s1,136
    80004804:	02d48a63          	beq	s1,a3,80004838 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004808:	449c                	lw	a5,8(s1)
    8000480a:	fef059e3          	blez	a5,800047fc <iget+0x38>
    8000480e:	4098                	lw	a4,0(s1)
    80004810:	ff3716e3          	bne	a4,s3,800047fc <iget+0x38>
    80004814:	40d8                	lw	a4,4(s1)
    80004816:	ff4713e3          	bne	a4,s4,800047fc <iget+0x38>
      ip->ref++;
    8000481a:	2785                	addiw	a5,a5,1
    8000481c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000481e:	0004a517          	auipc	a0,0x4a
    80004822:	a0250513          	addi	a0,a0,-1534 # 8004e220 <itable>
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	4c0080e7          	jalr	1216(ra) # 80000ce6 <release>
      return ip;
    8000482e:	8926                	mv	s2,s1
    80004830:	a03d                	j	8000485e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004832:	f7f9                	bnez	a5,80004800 <iget+0x3c>
    80004834:	8926                	mv	s2,s1
    80004836:	b7e9                	j	80004800 <iget+0x3c>
  if(empty == 0)
    80004838:	02090c63          	beqz	s2,80004870 <iget+0xac>
  ip->dev = dev;
    8000483c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004840:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004844:	4785                	li	a5,1
    80004846:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000484a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000484e:	0004a517          	auipc	a0,0x4a
    80004852:	9d250513          	addi	a0,a0,-1582 # 8004e220 <itable>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	490080e7          	jalr	1168(ra) # 80000ce6 <release>
}
    8000485e:	854a                	mv	a0,s2
    80004860:	70a2                	ld	ra,40(sp)
    80004862:	7402                	ld	s0,32(sp)
    80004864:	64e2                	ld	s1,24(sp)
    80004866:	6942                	ld	s2,16(sp)
    80004868:	69a2                	ld	s3,8(sp)
    8000486a:	6a02                	ld	s4,0(sp)
    8000486c:	6145                	addi	sp,sp,48
    8000486e:	8082                	ret
    panic("iget: no inodes");
    80004870:	00005517          	auipc	a0,0x5
    80004874:	dd050513          	addi	a0,a0,-560 # 80009640 <syscalls+0x188>
    80004878:	ffffc097          	auipc	ra,0xffffc
    8000487c:	cb2080e7          	jalr	-846(ra) # 8000052a <panic>

0000000080004880 <fsinit>:
fsinit(int dev) {
    80004880:	7179                	addi	sp,sp,-48
    80004882:	f406                	sd	ra,40(sp)
    80004884:	f022                	sd	s0,32(sp)
    80004886:	ec26                	sd	s1,24(sp)
    80004888:	e84a                	sd	s2,16(sp)
    8000488a:	e44e                	sd	s3,8(sp)
    8000488c:	1800                	addi	s0,sp,48
    8000488e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004890:	4585                	li	a1,1
    80004892:	00000097          	auipc	ra,0x0
    80004896:	a62080e7          	jalr	-1438(ra) # 800042f4 <bread>
    8000489a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000489c:	0004a997          	auipc	s3,0x4a
    800048a0:	96498993          	addi	s3,s3,-1692 # 8004e200 <sb>
    800048a4:	02000613          	li	a2,32
    800048a8:	05850593          	addi	a1,a0,88
    800048ac:	854e                	mv	a0,s3
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	4f8080e7          	jalr	1272(ra) # 80000da6 <memmove>
  brelse(bp);
    800048b6:	8526                	mv	a0,s1
    800048b8:	00000097          	auipc	ra,0x0
    800048bc:	b6c080e7          	jalr	-1172(ra) # 80004424 <brelse>
  if(sb.magic != FSMAGIC)
    800048c0:	0009a703          	lw	a4,0(s3)
    800048c4:	102037b7          	lui	a5,0x10203
    800048c8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800048cc:	02f71263          	bne	a4,a5,800048f0 <fsinit+0x70>
  initlog(dev, &sb);
    800048d0:	0004a597          	auipc	a1,0x4a
    800048d4:	93058593          	addi	a1,a1,-1744 # 8004e200 <sb>
    800048d8:	854a                	mv	a0,s2
    800048da:	00001097          	auipc	ra,0x1
    800048de:	b4c080e7          	jalr	-1204(ra) # 80005426 <initlog>
}
    800048e2:	70a2                	ld	ra,40(sp)
    800048e4:	7402                	ld	s0,32(sp)
    800048e6:	64e2                	ld	s1,24(sp)
    800048e8:	6942                	ld	s2,16(sp)
    800048ea:	69a2                	ld	s3,8(sp)
    800048ec:	6145                	addi	sp,sp,48
    800048ee:	8082                	ret
    panic("invalid file system");
    800048f0:	00005517          	auipc	a0,0x5
    800048f4:	d6050513          	addi	a0,a0,-672 # 80009650 <syscalls+0x198>
    800048f8:	ffffc097          	auipc	ra,0xffffc
    800048fc:	c32080e7          	jalr	-974(ra) # 8000052a <panic>

0000000080004900 <iinit>:
{
    80004900:	7179                	addi	sp,sp,-48
    80004902:	f406                	sd	ra,40(sp)
    80004904:	f022                	sd	s0,32(sp)
    80004906:	ec26                	sd	s1,24(sp)
    80004908:	e84a                	sd	s2,16(sp)
    8000490a:	e44e                	sd	s3,8(sp)
    8000490c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000490e:	00005597          	auipc	a1,0x5
    80004912:	d5a58593          	addi	a1,a1,-678 # 80009668 <syscalls+0x1b0>
    80004916:	0004a517          	auipc	a0,0x4a
    8000491a:	90a50513          	addi	a0,a0,-1782 # 8004e220 <itable>
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	234080e7          	jalr	564(ra) # 80000b52 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004926:	0004a497          	auipc	s1,0x4a
    8000492a:	92248493          	addi	s1,s1,-1758 # 8004e248 <itable+0x28>
    8000492e:	0004b997          	auipc	s3,0x4b
    80004932:	3aa98993          	addi	s3,s3,938 # 8004fcd8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004936:	00005917          	auipc	s2,0x5
    8000493a:	d3a90913          	addi	s2,s2,-710 # 80009670 <syscalls+0x1b8>
    8000493e:	85ca                	mv	a1,s2
    80004940:	8526                	mv	a0,s1
    80004942:	00001097          	auipc	ra,0x1
    80004946:	e48080e7          	jalr	-440(ra) # 8000578a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000494a:	08848493          	addi	s1,s1,136
    8000494e:	ff3498e3          	bne	s1,s3,8000493e <iinit+0x3e>
}
    80004952:	70a2                	ld	ra,40(sp)
    80004954:	7402                	ld	s0,32(sp)
    80004956:	64e2                	ld	s1,24(sp)
    80004958:	6942                	ld	s2,16(sp)
    8000495a:	69a2                	ld	s3,8(sp)
    8000495c:	6145                	addi	sp,sp,48
    8000495e:	8082                	ret

0000000080004960 <ialloc>:
{
    80004960:	715d                	addi	sp,sp,-80
    80004962:	e486                	sd	ra,72(sp)
    80004964:	e0a2                	sd	s0,64(sp)
    80004966:	fc26                	sd	s1,56(sp)
    80004968:	f84a                	sd	s2,48(sp)
    8000496a:	f44e                	sd	s3,40(sp)
    8000496c:	f052                	sd	s4,32(sp)
    8000496e:	ec56                	sd	s5,24(sp)
    80004970:	e85a                	sd	s6,16(sp)
    80004972:	e45e                	sd	s7,8(sp)
    80004974:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004976:	0004a717          	auipc	a4,0x4a
    8000497a:	89672703          	lw	a4,-1898(a4) # 8004e20c <sb+0xc>
    8000497e:	4785                	li	a5,1
    80004980:	04e7fa63          	bgeu	a5,a4,800049d4 <ialloc+0x74>
    80004984:	8aaa                	mv	s5,a0
    80004986:	8bae                	mv	s7,a1
    80004988:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000498a:	0004aa17          	auipc	s4,0x4a
    8000498e:	876a0a13          	addi	s4,s4,-1930 # 8004e200 <sb>
    80004992:	00048b1b          	sext.w	s6,s1
    80004996:	0044d793          	srli	a5,s1,0x4
    8000499a:	018a2583          	lw	a1,24(s4)
    8000499e:	9dbd                	addw	a1,a1,a5
    800049a0:	8556                	mv	a0,s5
    800049a2:	00000097          	auipc	ra,0x0
    800049a6:	952080e7          	jalr	-1710(ra) # 800042f4 <bread>
    800049aa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800049ac:	05850993          	addi	s3,a0,88
    800049b0:	00f4f793          	andi	a5,s1,15
    800049b4:	079a                	slli	a5,a5,0x6
    800049b6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800049b8:	00099783          	lh	a5,0(s3)
    800049bc:	c785                	beqz	a5,800049e4 <ialloc+0x84>
    brelse(bp);
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	a66080e7          	jalr	-1434(ra) # 80004424 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800049c6:	0485                	addi	s1,s1,1
    800049c8:	00ca2703          	lw	a4,12(s4)
    800049cc:	0004879b          	sext.w	a5,s1
    800049d0:	fce7e1e3          	bltu	a5,a4,80004992 <ialloc+0x32>
  panic("ialloc: no inodes");
    800049d4:	00005517          	auipc	a0,0x5
    800049d8:	ca450513          	addi	a0,a0,-860 # 80009678 <syscalls+0x1c0>
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	b4e080e7          	jalr	-1202(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800049e4:	04000613          	li	a2,64
    800049e8:	4581                	li	a1,0
    800049ea:	854e                	mv	a0,s3
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	35e080e7          	jalr	862(ra) # 80000d4a <memset>
      dip->type = type;
    800049f4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800049f8:	854a                	mv	a0,s2
    800049fa:	00001097          	auipc	ra,0x1
    800049fe:	caa080e7          	jalr	-854(ra) # 800056a4 <log_write>
      brelse(bp);
    80004a02:	854a                	mv	a0,s2
    80004a04:	00000097          	auipc	ra,0x0
    80004a08:	a20080e7          	jalr	-1504(ra) # 80004424 <brelse>
      return iget(dev, inum);
    80004a0c:	85da                	mv	a1,s6
    80004a0e:	8556                	mv	a0,s5
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	db4080e7          	jalr	-588(ra) # 800047c4 <iget>
}
    80004a18:	60a6                	ld	ra,72(sp)
    80004a1a:	6406                	ld	s0,64(sp)
    80004a1c:	74e2                	ld	s1,56(sp)
    80004a1e:	7942                	ld	s2,48(sp)
    80004a20:	79a2                	ld	s3,40(sp)
    80004a22:	7a02                	ld	s4,32(sp)
    80004a24:	6ae2                	ld	s5,24(sp)
    80004a26:	6b42                	ld	s6,16(sp)
    80004a28:	6ba2                	ld	s7,8(sp)
    80004a2a:	6161                	addi	sp,sp,80
    80004a2c:	8082                	ret

0000000080004a2e <iupdate>:
{
    80004a2e:	1101                	addi	sp,sp,-32
    80004a30:	ec06                	sd	ra,24(sp)
    80004a32:	e822                	sd	s0,16(sp)
    80004a34:	e426                	sd	s1,8(sp)
    80004a36:	e04a                	sd	s2,0(sp)
    80004a38:	1000                	addi	s0,sp,32
    80004a3a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004a3c:	415c                	lw	a5,4(a0)
    80004a3e:	0047d79b          	srliw	a5,a5,0x4
    80004a42:	00049597          	auipc	a1,0x49
    80004a46:	7d65a583          	lw	a1,2006(a1) # 8004e218 <sb+0x18>
    80004a4a:	9dbd                	addw	a1,a1,a5
    80004a4c:	4108                	lw	a0,0(a0)
    80004a4e:	00000097          	auipc	ra,0x0
    80004a52:	8a6080e7          	jalr	-1882(ra) # 800042f4 <bread>
    80004a56:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004a58:	05850793          	addi	a5,a0,88
    80004a5c:	40c8                	lw	a0,4(s1)
    80004a5e:	893d                	andi	a0,a0,15
    80004a60:	051a                	slli	a0,a0,0x6
    80004a62:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004a64:	04449703          	lh	a4,68(s1)
    80004a68:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004a6c:	04649703          	lh	a4,70(s1)
    80004a70:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004a74:	04849703          	lh	a4,72(s1)
    80004a78:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004a7c:	04a49703          	lh	a4,74(s1)
    80004a80:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80004a84:	44f8                	lw	a4,76(s1)
    80004a86:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004a88:	03400613          	li	a2,52
    80004a8c:	05048593          	addi	a1,s1,80
    80004a90:	0531                	addi	a0,a0,12
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	314080e7          	jalr	788(ra) # 80000da6 <memmove>
  log_write(bp);
    80004a9a:	854a                	mv	a0,s2
    80004a9c:	00001097          	auipc	ra,0x1
    80004aa0:	c08080e7          	jalr	-1016(ra) # 800056a4 <log_write>
  brelse(bp);
    80004aa4:	854a                	mv	a0,s2
    80004aa6:	00000097          	auipc	ra,0x0
    80004aaa:	97e080e7          	jalr	-1666(ra) # 80004424 <brelse>
}
    80004aae:	60e2                	ld	ra,24(sp)
    80004ab0:	6442                	ld	s0,16(sp)
    80004ab2:	64a2                	ld	s1,8(sp)
    80004ab4:	6902                	ld	s2,0(sp)
    80004ab6:	6105                	addi	sp,sp,32
    80004ab8:	8082                	ret

0000000080004aba <idup>:
{
    80004aba:	1101                	addi	sp,sp,-32
    80004abc:	ec06                	sd	ra,24(sp)
    80004abe:	e822                	sd	s0,16(sp)
    80004ac0:	e426                	sd	s1,8(sp)
    80004ac2:	1000                	addi	s0,sp,32
    80004ac4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004ac6:	00049517          	auipc	a0,0x49
    80004aca:	75a50513          	addi	a0,a0,1882 # 8004e220 <itable>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	164080e7          	jalr	356(ra) # 80000c32 <acquire>
  ip->ref++;
    80004ad6:	449c                	lw	a5,8(s1)
    80004ad8:	2785                	addiw	a5,a5,1
    80004ada:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004adc:	00049517          	auipc	a0,0x49
    80004ae0:	74450513          	addi	a0,a0,1860 # 8004e220 <itable>
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	202080e7          	jalr	514(ra) # 80000ce6 <release>
}
    80004aec:	8526                	mv	a0,s1
    80004aee:	60e2                	ld	ra,24(sp)
    80004af0:	6442                	ld	s0,16(sp)
    80004af2:	64a2                	ld	s1,8(sp)
    80004af4:	6105                	addi	sp,sp,32
    80004af6:	8082                	ret

0000000080004af8 <ilock>:
{
    80004af8:	1101                	addi	sp,sp,-32
    80004afa:	ec06                	sd	ra,24(sp)
    80004afc:	e822                	sd	s0,16(sp)
    80004afe:	e426                	sd	s1,8(sp)
    80004b00:	e04a                	sd	s2,0(sp)
    80004b02:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004b04:	c115                	beqz	a0,80004b28 <ilock+0x30>
    80004b06:	84aa                	mv	s1,a0
    80004b08:	451c                	lw	a5,8(a0)
    80004b0a:	00f05f63          	blez	a5,80004b28 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004b0e:	0541                	addi	a0,a0,16
    80004b10:	00001097          	auipc	ra,0x1
    80004b14:	cb4080e7          	jalr	-844(ra) # 800057c4 <acquiresleep>
  if(ip->valid == 0){
    80004b18:	40bc                	lw	a5,64(s1)
    80004b1a:	cf99                	beqz	a5,80004b38 <ilock+0x40>
}
    80004b1c:	60e2                	ld	ra,24(sp)
    80004b1e:	6442                	ld	s0,16(sp)
    80004b20:	64a2                	ld	s1,8(sp)
    80004b22:	6902                	ld	s2,0(sp)
    80004b24:	6105                	addi	sp,sp,32
    80004b26:	8082                	ret
    panic("ilock");
    80004b28:	00005517          	auipc	a0,0x5
    80004b2c:	b6850513          	addi	a0,a0,-1176 # 80009690 <syscalls+0x1d8>
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	9fa080e7          	jalr	-1542(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004b38:	40dc                	lw	a5,4(s1)
    80004b3a:	0047d79b          	srliw	a5,a5,0x4
    80004b3e:	00049597          	auipc	a1,0x49
    80004b42:	6da5a583          	lw	a1,1754(a1) # 8004e218 <sb+0x18>
    80004b46:	9dbd                	addw	a1,a1,a5
    80004b48:	4088                	lw	a0,0(s1)
    80004b4a:	fffff097          	auipc	ra,0xfffff
    80004b4e:	7aa080e7          	jalr	1962(ra) # 800042f4 <bread>
    80004b52:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004b54:	05850593          	addi	a1,a0,88
    80004b58:	40dc                	lw	a5,4(s1)
    80004b5a:	8bbd                	andi	a5,a5,15
    80004b5c:	079a                	slli	a5,a5,0x6
    80004b5e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004b60:	00059783          	lh	a5,0(a1)
    80004b64:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004b68:	00259783          	lh	a5,2(a1)
    80004b6c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004b70:	00459783          	lh	a5,4(a1)
    80004b74:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004b78:	00659783          	lh	a5,6(a1)
    80004b7c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004b80:	459c                	lw	a5,8(a1)
    80004b82:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004b84:	03400613          	li	a2,52
    80004b88:	05b1                	addi	a1,a1,12
    80004b8a:	05048513          	addi	a0,s1,80
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	218080e7          	jalr	536(ra) # 80000da6 <memmove>
    brelse(bp);
    80004b96:	854a                	mv	a0,s2
    80004b98:	00000097          	auipc	ra,0x0
    80004b9c:	88c080e7          	jalr	-1908(ra) # 80004424 <brelse>
    ip->valid = 1;
    80004ba0:	4785                	li	a5,1
    80004ba2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80004ba4:	04449783          	lh	a5,68(s1)
    80004ba8:	fbb5                	bnez	a5,80004b1c <ilock+0x24>
      panic("ilock: no type");
    80004baa:	00005517          	auipc	a0,0x5
    80004bae:	aee50513          	addi	a0,a0,-1298 # 80009698 <syscalls+0x1e0>
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	978080e7          	jalr	-1672(ra) # 8000052a <panic>

0000000080004bba <iunlock>:
{
    80004bba:	1101                	addi	sp,sp,-32
    80004bbc:	ec06                	sd	ra,24(sp)
    80004bbe:	e822                	sd	s0,16(sp)
    80004bc0:	e426                	sd	s1,8(sp)
    80004bc2:	e04a                	sd	s2,0(sp)
    80004bc4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004bc6:	c905                	beqz	a0,80004bf6 <iunlock+0x3c>
    80004bc8:	84aa                	mv	s1,a0
    80004bca:	01050913          	addi	s2,a0,16
    80004bce:	854a                	mv	a0,s2
    80004bd0:	00001097          	auipc	ra,0x1
    80004bd4:	c8e080e7          	jalr	-882(ra) # 8000585e <holdingsleep>
    80004bd8:	cd19                	beqz	a0,80004bf6 <iunlock+0x3c>
    80004bda:	449c                	lw	a5,8(s1)
    80004bdc:	00f05d63          	blez	a5,80004bf6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004be0:	854a                	mv	a0,s2
    80004be2:	00001097          	auipc	ra,0x1
    80004be6:	c38080e7          	jalr	-968(ra) # 8000581a <releasesleep>
}
    80004bea:	60e2                	ld	ra,24(sp)
    80004bec:	6442                	ld	s0,16(sp)
    80004bee:	64a2                	ld	s1,8(sp)
    80004bf0:	6902                	ld	s2,0(sp)
    80004bf2:	6105                	addi	sp,sp,32
    80004bf4:	8082                	ret
    panic("iunlock");
    80004bf6:	00005517          	auipc	a0,0x5
    80004bfa:	ab250513          	addi	a0,a0,-1358 # 800096a8 <syscalls+0x1f0>
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	92c080e7          	jalr	-1748(ra) # 8000052a <panic>

0000000080004c06 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004c06:	7179                	addi	sp,sp,-48
    80004c08:	f406                	sd	ra,40(sp)
    80004c0a:	f022                	sd	s0,32(sp)
    80004c0c:	ec26                	sd	s1,24(sp)
    80004c0e:	e84a                	sd	s2,16(sp)
    80004c10:	e44e                	sd	s3,8(sp)
    80004c12:	e052                	sd	s4,0(sp)
    80004c14:	1800                	addi	s0,sp,48
    80004c16:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004c18:	05050493          	addi	s1,a0,80
    80004c1c:	08050913          	addi	s2,a0,128
    80004c20:	a021                	j	80004c28 <itrunc+0x22>
    80004c22:	0491                	addi	s1,s1,4
    80004c24:	01248d63          	beq	s1,s2,80004c3e <itrunc+0x38>
    if(ip->addrs[i]){
    80004c28:	408c                	lw	a1,0(s1)
    80004c2a:	dde5                	beqz	a1,80004c22 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004c2c:	0009a503          	lw	a0,0(s3)
    80004c30:	00000097          	auipc	ra,0x0
    80004c34:	90a080e7          	jalr	-1782(ra) # 8000453a <bfree>
      ip->addrs[i] = 0;
    80004c38:	0004a023          	sw	zero,0(s1)
    80004c3c:	b7dd                	j	80004c22 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004c3e:	0809a583          	lw	a1,128(s3)
    80004c42:	e185                	bnez	a1,80004c62 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004c44:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004c48:	854e                	mv	a0,s3
    80004c4a:	00000097          	auipc	ra,0x0
    80004c4e:	de4080e7          	jalr	-540(ra) # 80004a2e <iupdate>
}
    80004c52:	70a2                	ld	ra,40(sp)
    80004c54:	7402                	ld	s0,32(sp)
    80004c56:	64e2                	ld	s1,24(sp)
    80004c58:	6942                	ld	s2,16(sp)
    80004c5a:	69a2                	ld	s3,8(sp)
    80004c5c:	6a02                	ld	s4,0(sp)
    80004c5e:	6145                	addi	sp,sp,48
    80004c60:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004c62:	0009a503          	lw	a0,0(s3)
    80004c66:	fffff097          	auipc	ra,0xfffff
    80004c6a:	68e080e7          	jalr	1678(ra) # 800042f4 <bread>
    80004c6e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004c70:	05850493          	addi	s1,a0,88
    80004c74:	45850913          	addi	s2,a0,1112
    80004c78:	a021                	j	80004c80 <itrunc+0x7a>
    80004c7a:	0491                	addi	s1,s1,4
    80004c7c:	01248b63          	beq	s1,s2,80004c92 <itrunc+0x8c>
      if(a[j])
    80004c80:	408c                	lw	a1,0(s1)
    80004c82:	dde5                	beqz	a1,80004c7a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004c84:	0009a503          	lw	a0,0(s3)
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	8b2080e7          	jalr	-1870(ra) # 8000453a <bfree>
    80004c90:	b7ed                	j	80004c7a <itrunc+0x74>
    brelse(bp);
    80004c92:	8552                	mv	a0,s4
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	790080e7          	jalr	1936(ra) # 80004424 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004c9c:	0809a583          	lw	a1,128(s3)
    80004ca0:	0009a503          	lw	a0,0(s3)
    80004ca4:	00000097          	auipc	ra,0x0
    80004ca8:	896080e7          	jalr	-1898(ra) # 8000453a <bfree>
    ip->addrs[NDIRECT] = 0;
    80004cac:	0809a023          	sw	zero,128(s3)
    80004cb0:	bf51                	j	80004c44 <itrunc+0x3e>

0000000080004cb2 <iput>:
{
    80004cb2:	1101                	addi	sp,sp,-32
    80004cb4:	ec06                	sd	ra,24(sp)
    80004cb6:	e822                	sd	s0,16(sp)
    80004cb8:	e426                	sd	s1,8(sp)
    80004cba:	e04a                	sd	s2,0(sp)
    80004cbc:	1000                	addi	s0,sp,32
    80004cbe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004cc0:	00049517          	auipc	a0,0x49
    80004cc4:	56050513          	addi	a0,a0,1376 # 8004e220 <itable>
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	f6a080e7          	jalr	-150(ra) # 80000c32 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004cd0:	4498                	lw	a4,8(s1)
    80004cd2:	4785                	li	a5,1
    80004cd4:	02f70363          	beq	a4,a5,80004cfa <iput+0x48>
  ip->ref--;
    80004cd8:	449c                	lw	a5,8(s1)
    80004cda:	37fd                	addiw	a5,a5,-1
    80004cdc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004cde:	00049517          	auipc	a0,0x49
    80004ce2:	54250513          	addi	a0,a0,1346 # 8004e220 <itable>
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	000080e7          	jalr	ra # 80000ce6 <release>
}
    80004cee:	60e2                	ld	ra,24(sp)
    80004cf0:	6442                	ld	s0,16(sp)
    80004cf2:	64a2                	ld	s1,8(sp)
    80004cf4:	6902                	ld	s2,0(sp)
    80004cf6:	6105                	addi	sp,sp,32
    80004cf8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004cfa:	40bc                	lw	a5,64(s1)
    80004cfc:	dff1                	beqz	a5,80004cd8 <iput+0x26>
    80004cfe:	04a49783          	lh	a5,74(s1)
    80004d02:	fbf9                	bnez	a5,80004cd8 <iput+0x26>
    acquiresleep(&ip->lock);
    80004d04:	01048913          	addi	s2,s1,16
    80004d08:	854a                	mv	a0,s2
    80004d0a:	00001097          	auipc	ra,0x1
    80004d0e:	aba080e7          	jalr	-1350(ra) # 800057c4 <acquiresleep>
    release(&itable.lock);
    80004d12:	00049517          	auipc	a0,0x49
    80004d16:	50e50513          	addi	a0,a0,1294 # 8004e220 <itable>
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	fcc080e7          	jalr	-52(ra) # 80000ce6 <release>
    itrunc(ip);
    80004d22:	8526                	mv	a0,s1
    80004d24:	00000097          	auipc	ra,0x0
    80004d28:	ee2080e7          	jalr	-286(ra) # 80004c06 <itrunc>
    ip->type = 0;
    80004d2c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004d30:	8526                	mv	a0,s1
    80004d32:	00000097          	auipc	ra,0x0
    80004d36:	cfc080e7          	jalr	-772(ra) # 80004a2e <iupdate>
    ip->valid = 0;
    80004d3a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004d3e:	854a                	mv	a0,s2
    80004d40:	00001097          	auipc	ra,0x1
    80004d44:	ada080e7          	jalr	-1318(ra) # 8000581a <releasesleep>
    acquire(&itable.lock);
    80004d48:	00049517          	auipc	a0,0x49
    80004d4c:	4d850513          	addi	a0,a0,1240 # 8004e220 <itable>
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	ee2080e7          	jalr	-286(ra) # 80000c32 <acquire>
    80004d58:	b741                	j	80004cd8 <iput+0x26>

0000000080004d5a <iunlockput>:
{
    80004d5a:	1101                	addi	sp,sp,-32
    80004d5c:	ec06                	sd	ra,24(sp)
    80004d5e:	e822                	sd	s0,16(sp)
    80004d60:	e426                	sd	s1,8(sp)
    80004d62:	1000                	addi	s0,sp,32
    80004d64:	84aa                	mv	s1,a0
  iunlock(ip);
    80004d66:	00000097          	auipc	ra,0x0
    80004d6a:	e54080e7          	jalr	-428(ra) # 80004bba <iunlock>
  iput(ip);
    80004d6e:	8526                	mv	a0,s1
    80004d70:	00000097          	auipc	ra,0x0
    80004d74:	f42080e7          	jalr	-190(ra) # 80004cb2 <iput>
}
    80004d78:	60e2                	ld	ra,24(sp)
    80004d7a:	6442                	ld	s0,16(sp)
    80004d7c:	64a2                	ld	s1,8(sp)
    80004d7e:	6105                	addi	sp,sp,32
    80004d80:	8082                	ret

0000000080004d82 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004d82:	1141                	addi	sp,sp,-16
    80004d84:	e422                	sd	s0,8(sp)
    80004d86:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004d88:	411c                	lw	a5,0(a0)
    80004d8a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004d8c:	415c                	lw	a5,4(a0)
    80004d8e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004d90:	04451783          	lh	a5,68(a0)
    80004d94:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004d98:	04a51783          	lh	a5,74(a0)
    80004d9c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004da0:	04c56783          	lwu	a5,76(a0)
    80004da4:	e99c                	sd	a5,16(a1)
}
    80004da6:	6422                	ld	s0,8(sp)
    80004da8:	0141                	addi	sp,sp,16
    80004daa:	8082                	ret

0000000080004dac <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004dac:	457c                	lw	a5,76(a0)
    80004dae:	0ed7e963          	bltu	a5,a3,80004ea0 <readi+0xf4>
{
    80004db2:	7159                	addi	sp,sp,-112
    80004db4:	f486                	sd	ra,104(sp)
    80004db6:	f0a2                	sd	s0,96(sp)
    80004db8:	eca6                	sd	s1,88(sp)
    80004dba:	e8ca                	sd	s2,80(sp)
    80004dbc:	e4ce                	sd	s3,72(sp)
    80004dbe:	e0d2                	sd	s4,64(sp)
    80004dc0:	fc56                	sd	s5,56(sp)
    80004dc2:	f85a                	sd	s6,48(sp)
    80004dc4:	f45e                	sd	s7,40(sp)
    80004dc6:	f062                	sd	s8,32(sp)
    80004dc8:	ec66                	sd	s9,24(sp)
    80004dca:	e86a                	sd	s10,16(sp)
    80004dcc:	e46e                	sd	s11,8(sp)
    80004dce:	1880                	addi	s0,sp,112
    80004dd0:	8baa                	mv	s7,a0
    80004dd2:	8c2e                	mv	s8,a1
    80004dd4:	8ab2                	mv	s5,a2
    80004dd6:	84b6                	mv	s1,a3
    80004dd8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004dda:	9f35                	addw	a4,a4,a3
    return 0;
    80004ddc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004dde:	0ad76063          	bltu	a4,a3,80004e7e <readi+0xd2>
  if(off + n > ip->size)
    80004de2:	00e7f463          	bgeu	a5,a4,80004dea <readi+0x3e>
    n = ip->size - off;
    80004de6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004dea:	0a0b0963          	beqz	s6,80004e9c <readi+0xf0>
    80004dee:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004df0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004df4:	5cfd                	li	s9,-1
    80004df6:	a82d                	j	80004e30 <readi+0x84>
    80004df8:	020a1d93          	slli	s11,s4,0x20
    80004dfc:	020ddd93          	srli	s11,s11,0x20
    80004e00:	05890793          	addi	a5,s2,88
    80004e04:	86ee                	mv	a3,s11
    80004e06:	963e                	add	a2,a2,a5
    80004e08:	85d6                	mv	a1,s5
    80004e0a:	8562                	mv	a0,s8
    80004e0c:	ffffe097          	auipc	ra,0xffffe
    80004e10:	362080e7          	jalr	866(ra) # 8000316e <either_copyout>
    80004e14:	05950d63          	beq	a0,s9,80004e6e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004e18:	854a                	mv	a0,s2
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	60a080e7          	jalr	1546(ra) # 80004424 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004e22:	013a09bb          	addw	s3,s4,s3
    80004e26:	009a04bb          	addw	s1,s4,s1
    80004e2a:	9aee                	add	s5,s5,s11
    80004e2c:	0569f763          	bgeu	s3,s6,80004e7a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004e30:	000ba903          	lw	s2,0(s7)
    80004e34:	00a4d59b          	srliw	a1,s1,0xa
    80004e38:	855e                	mv	a0,s7
    80004e3a:	00000097          	auipc	ra,0x0
    80004e3e:	8ae080e7          	jalr	-1874(ra) # 800046e8 <bmap>
    80004e42:	0005059b          	sext.w	a1,a0
    80004e46:	854a                	mv	a0,s2
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	4ac080e7          	jalr	1196(ra) # 800042f4 <bread>
    80004e50:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004e52:	3ff4f613          	andi	a2,s1,1023
    80004e56:	40cd07bb          	subw	a5,s10,a2
    80004e5a:	413b073b          	subw	a4,s6,s3
    80004e5e:	8a3e                	mv	s4,a5
    80004e60:	2781                	sext.w	a5,a5
    80004e62:	0007069b          	sext.w	a3,a4
    80004e66:	f8f6f9e3          	bgeu	a3,a5,80004df8 <readi+0x4c>
    80004e6a:	8a3a                	mv	s4,a4
    80004e6c:	b771                	j	80004df8 <readi+0x4c>
      brelse(bp);
    80004e6e:	854a                	mv	a0,s2
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	5b4080e7          	jalr	1460(ra) # 80004424 <brelse>
      tot = -1;
    80004e78:	59fd                	li	s3,-1
  }
  return tot;
    80004e7a:	0009851b          	sext.w	a0,s3
}
    80004e7e:	70a6                	ld	ra,104(sp)
    80004e80:	7406                	ld	s0,96(sp)
    80004e82:	64e6                	ld	s1,88(sp)
    80004e84:	6946                	ld	s2,80(sp)
    80004e86:	69a6                	ld	s3,72(sp)
    80004e88:	6a06                	ld	s4,64(sp)
    80004e8a:	7ae2                	ld	s5,56(sp)
    80004e8c:	7b42                	ld	s6,48(sp)
    80004e8e:	7ba2                	ld	s7,40(sp)
    80004e90:	7c02                	ld	s8,32(sp)
    80004e92:	6ce2                	ld	s9,24(sp)
    80004e94:	6d42                	ld	s10,16(sp)
    80004e96:	6da2                	ld	s11,8(sp)
    80004e98:	6165                	addi	sp,sp,112
    80004e9a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004e9c:	89da                	mv	s3,s6
    80004e9e:	bff1                	j	80004e7a <readi+0xce>
    return 0;
    80004ea0:	4501                	li	a0,0
}
    80004ea2:	8082                	ret

0000000080004ea4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004ea4:	457c                	lw	a5,76(a0)
    80004ea6:	10d7e863          	bltu	a5,a3,80004fb6 <writei+0x112>
{
    80004eaa:	7159                	addi	sp,sp,-112
    80004eac:	f486                	sd	ra,104(sp)
    80004eae:	f0a2                	sd	s0,96(sp)
    80004eb0:	eca6                	sd	s1,88(sp)
    80004eb2:	e8ca                	sd	s2,80(sp)
    80004eb4:	e4ce                	sd	s3,72(sp)
    80004eb6:	e0d2                	sd	s4,64(sp)
    80004eb8:	fc56                	sd	s5,56(sp)
    80004eba:	f85a                	sd	s6,48(sp)
    80004ebc:	f45e                	sd	s7,40(sp)
    80004ebe:	f062                	sd	s8,32(sp)
    80004ec0:	ec66                	sd	s9,24(sp)
    80004ec2:	e86a                	sd	s10,16(sp)
    80004ec4:	e46e                	sd	s11,8(sp)
    80004ec6:	1880                	addi	s0,sp,112
    80004ec8:	8b2a                	mv	s6,a0
    80004eca:	8c2e                	mv	s8,a1
    80004ecc:	8ab2                	mv	s5,a2
    80004ece:	8936                	mv	s2,a3
    80004ed0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004ed2:	00e687bb          	addw	a5,a3,a4
    80004ed6:	0ed7e263          	bltu	a5,a3,80004fba <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004eda:	00043737          	lui	a4,0x43
    80004ede:	0ef76063          	bltu	a4,a5,80004fbe <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004ee2:	0c0b8863          	beqz	s7,80004fb2 <writei+0x10e>
    80004ee6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004ee8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004eec:	5cfd                	li	s9,-1
    80004eee:	a091                	j	80004f32 <writei+0x8e>
    80004ef0:	02099d93          	slli	s11,s3,0x20
    80004ef4:	020ddd93          	srli	s11,s11,0x20
    80004ef8:	05848793          	addi	a5,s1,88
    80004efc:	86ee                	mv	a3,s11
    80004efe:	8656                	mv	a2,s5
    80004f00:	85e2                	mv	a1,s8
    80004f02:	953e                	add	a0,a0,a5
    80004f04:	ffffe097          	auipc	ra,0xffffe
    80004f08:	2c0080e7          	jalr	704(ra) # 800031c4 <either_copyin>
    80004f0c:	07950263          	beq	a0,s9,80004f70 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004f10:	8526                	mv	a0,s1
    80004f12:	00000097          	auipc	ra,0x0
    80004f16:	792080e7          	jalr	1938(ra) # 800056a4 <log_write>
    brelse(bp);
    80004f1a:	8526                	mv	a0,s1
    80004f1c:	fffff097          	auipc	ra,0xfffff
    80004f20:	508080e7          	jalr	1288(ra) # 80004424 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004f24:	01498a3b          	addw	s4,s3,s4
    80004f28:	0129893b          	addw	s2,s3,s2
    80004f2c:	9aee                	add	s5,s5,s11
    80004f2e:	057a7663          	bgeu	s4,s7,80004f7a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004f32:	000b2483          	lw	s1,0(s6)
    80004f36:	00a9559b          	srliw	a1,s2,0xa
    80004f3a:	855a                	mv	a0,s6
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	7ac080e7          	jalr	1964(ra) # 800046e8 <bmap>
    80004f44:	0005059b          	sext.w	a1,a0
    80004f48:	8526                	mv	a0,s1
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	3aa080e7          	jalr	938(ra) # 800042f4 <bread>
    80004f52:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004f54:	3ff97513          	andi	a0,s2,1023
    80004f58:	40ad07bb          	subw	a5,s10,a0
    80004f5c:	414b873b          	subw	a4,s7,s4
    80004f60:	89be                	mv	s3,a5
    80004f62:	2781                	sext.w	a5,a5
    80004f64:	0007069b          	sext.w	a3,a4
    80004f68:	f8f6f4e3          	bgeu	a3,a5,80004ef0 <writei+0x4c>
    80004f6c:	89ba                	mv	s3,a4
    80004f6e:	b749                	j	80004ef0 <writei+0x4c>
      brelse(bp);
    80004f70:	8526                	mv	a0,s1
    80004f72:	fffff097          	auipc	ra,0xfffff
    80004f76:	4b2080e7          	jalr	1202(ra) # 80004424 <brelse>
  }

  if(off > ip->size)
    80004f7a:	04cb2783          	lw	a5,76(s6)
    80004f7e:	0127f463          	bgeu	a5,s2,80004f86 <writei+0xe2>
    ip->size = off;
    80004f82:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004f86:	855a                	mv	a0,s6
    80004f88:	00000097          	auipc	ra,0x0
    80004f8c:	aa6080e7          	jalr	-1370(ra) # 80004a2e <iupdate>

  return tot;
    80004f90:	000a051b          	sext.w	a0,s4
}
    80004f94:	70a6                	ld	ra,104(sp)
    80004f96:	7406                	ld	s0,96(sp)
    80004f98:	64e6                	ld	s1,88(sp)
    80004f9a:	6946                	ld	s2,80(sp)
    80004f9c:	69a6                	ld	s3,72(sp)
    80004f9e:	6a06                	ld	s4,64(sp)
    80004fa0:	7ae2                	ld	s5,56(sp)
    80004fa2:	7b42                	ld	s6,48(sp)
    80004fa4:	7ba2                	ld	s7,40(sp)
    80004fa6:	7c02                	ld	s8,32(sp)
    80004fa8:	6ce2                	ld	s9,24(sp)
    80004faa:	6d42                	ld	s10,16(sp)
    80004fac:	6da2                	ld	s11,8(sp)
    80004fae:	6165                	addi	sp,sp,112
    80004fb0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004fb2:	8a5e                	mv	s4,s7
    80004fb4:	bfc9                	j	80004f86 <writei+0xe2>
    return -1;
    80004fb6:	557d                	li	a0,-1
}
    80004fb8:	8082                	ret
    return -1;
    80004fba:	557d                	li	a0,-1
    80004fbc:	bfe1                	j	80004f94 <writei+0xf0>
    return -1;
    80004fbe:	557d                	li	a0,-1
    80004fc0:	bfd1                	j	80004f94 <writei+0xf0>

0000000080004fc2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004fc2:	1141                	addi	sp,sp,-16
    80004fc4:	e406                	sd	ra,8(sp)
    80004fc6:	e022                	sd	s0,0(sp)
    80004fc8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004fca:	4639                	li	a2,14
    80004fcc:	ffffc097          	auipc	ra,0xffffc
    80004fd0:	e56080e7          	jalr	-426(ra) # 80000e22 <strncmp>
}
    80004fd4:	60a2                	ld	ra,8(sp)
    80004fd6:	6402                	ld	s0,0(sp)
    80004fd8:	0141                	addi	sp,sp,16
    80004fda:	8082                	ret

0000000080004fdc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004fdc:	7139                	addi	sp,sp,-64
    80004fde:	fc06                	sd	ra,56(sp)
    80004fe0:	f822                	sd	s0,48(sp)
    80004fe2:	f426                	sd	s1,40(sp)
    80004fe4:	f04a                	sd	s2,32(sp)
    80004fe6:	ec4e                	sd	s3,24(sp)
    80004fe8:	e852                	sd	s4,16(sp)
    80004fea:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004fec:	04451703          	lh	a4,68(a0)
    80004ff0:	4785                	li	a5,1
    80004ff2:	00f71a63          	bne	a4,a5,80005006 <dirlookup+0x2a>
    80004ff6:	892a                	mv	s2,a0
    80004ff8:	89ae                	mv	s3,a1
    80004ffa:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004ffc:	457c                	lw	a5,76(a0)
    80004ffe:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80005000:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005002:	e79d                	bnez	a5,80005030 <dirlookup+0x54>
    80005004:	a8a5                	j	8000507c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80005006:	00004517          	auipc	a0,0x4
    8000500a:	6aa50513          	addi	a0,a0,1706 # 800096b0 <syscalls+0x1f8>
    8000500e:	ffffb097          	auipc	ra,0xffffb
    80005012:	51c080e7          	jalr	1308(ra) # 8000052a <panic>
      panic("dirlookup read");
    80005016:	00004517          	auipc	a0,0x4
    8000501a:	6b250513          	addi	a0,a0,1714 # 800096c8 <syscalls+0x210>
    8000501e:	ffffb097          	auipc	ra,0xffffb
    80005022:	50c080e7          	jalr	1292(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005026:	24c1                	addiw	s1,s1,16
    80005028:	04c92783          	lw	a5,76(s2)
    8000502c:	04f4f763          	bgeu	s1,a5,8000507a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005030:	4741                	li	a4,16
    80005032:	86a6                	mv	a3,s1
    80005034:	fc040613          	addi	a2,s0,-64
    80005038:	4581                	li	a1,0
    8000503a:	854a                	mv	a0,s2
    8000503c:	00000097          	auipc	ra,0x0
    80005040:	d70080e7          	jalr	-656(ra) # 80004dac <readi>
    80005044:	47c1                	li	a5,16
    80005046:	fcf518e3          	bne	a0,a5,80005016 <dirlookup+0x3a>
    if(de.inum == 0)
    8000504a:	fc045783          	lhu	a5,-64(s0)
    8000504e:	dfe1                	beqz	a5,80005026 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80005050:	fc240593          	addi	a1,s0,-62
    80005054:	854e                	mv	a0,s3
    80005056:	00000097          	auipc	ra,0x0
    8000505a:	f6c080e7          	jalr	-148(ra) # 80004fc2 <namecmp>
    8000505e:	f561                	bnez	a0,80005026 <dirlookup+0x4a>
      if(poff)
    80005060:	000a0463          	beqz	s4,80005068 <dirlookup+0x8c>
        *poff = off;
    80005064:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80005068:	fc045583          	lhu	a1,-64(s0)
    8000506c:	00092503          	lw	a0,0(s2)
    80005070:	fffff097          	auipc	ra,0xfffff
    80005074:	754080e7          	jalr	1876(ra) # 800047c4 <iget>
    80005078:	a011                	j	8000507c <dirlookup+0xa0>
  return 0;
    8000507a:	4501                	li	a0,0
}
    8000507c:	70e2                	ld	ra,56(sp)
    8000507e:	7442                	ld	s0,48(sp)
    80005080:	74a2                	ld	s1,40(sp)
    80005082:	7902                	ld	s2,32(sp)
    80005084:	69e2                	ld	s3,24(sp)
    80005086:	6a42                	ld	s4,16(sp)
    80005088:	6121                	addi	sp,sp,64
    8000508a:	8082                	ret

000000008000508c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000508c:	711d                	addi	sp,sp,-96
    8000508e:	ec86                	sd	ra,88(sp)
    80005090:	e8a2                	sd	s0,80(sp)
    80005092:	e4a6                	sd	s1,72(sp)
    80005094:	e0ca                	sd	s2,64(sp)
    80005096:	fc4e                	sd	s3,56(sp)
    80005098:	f852                	sd	s4,48(sp)
    8000509a:	f456                	sd	s5,40(sp)
    8000509c:	f05a                	sd	s6,32(sp)
    8000509e:	ec5e                	sd	s7,24(sp)
    800050a0:	e862                	sd	s8,16(sp)
    800050a2:	e466                	sd	s9,8(sp)
    800050a4:	1080                	addi	s0,sp,96
    800050a6:	84aa                	mv	s1,a0
    800050a8:	8aae                	mv	s5,a1
    800050aa:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800050ac:	00054703          	lbu	a4,0(a0)
    800050b0:	02f00793          	li	a5,47
    800050b4:	02f70263          	beq	a4,a5,800050d8 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	a8e080e7          	jalr	-1394(ra) # 80001b46 <myproc>
    800050c0:	6568                	ld	a0,200(a0)
    800050c2:	00000097          	auipc	ra,0x0
    800050c6:	9f8080e7          	jalr	-1544(ra) # 80004aba <idup>
    800050ca:	89aa                	mv	s3,a0
  while(*path == '/')
    800050cc:	02f00913          	li	s2,47
  len = path - s;
    800050d0:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800050d2:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800050d4:	4b85                	li	s7,1
    800050d6:	a865                	j	8000518e <namex+0x102>
    ip = iget(ROOTDEV, ROOTINO);
    800050d8:	4585                	li	a1,1
    800050da:	4505                	li	a0,1
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	6e8080e7          	jalr	1768(ra) # 800047c4 <iget>
    800050e4:	89aa                	mv	s3,a0
    800050e6:	b7dd                	j	800050cc <namex+0x40>
      iunlockput(ip);
    800050e8:	854e                	mv	a0,s3
    800050ea:	00000097          	auipc	ra,0x0
    800050ee:	c70080e7          	jalr	-912(ra) # 80004d5a <iunlockput>
      return 0;
    800050f2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800050f4:	854e                	mv	a0,s3
    800050f6:	60e6                	ld	ra,88(sp)
    800050f8:	6446                	ld	s0,80(sp)
    800050fa:	64a6                	ld	s1,72(sp)
    800050fc:	6906                	ld	s2,64(sp)
    800050fe:	79e2                	ld	s3,56(sp)
    80005100:	7a42                	ld	s4,48(sp)
    80005102:	7aa2                	ld	s5,40(sp)
    80005104:	7b02                	ld	s6,32(sp)
    80005106:	6be2                	ld	s7,24(sp)
    80005108:	6c42                	ld	s8,16(sp)
    8000510a:	6ca2                	ld	s9,8(sp)
    8000510c:	6125                	addi	sp,sp,96
    8000510e:	8082                	ret
      iunlock(ip);
    80005110:	854e                	mv	a0,s3
    80005112:	00000097          	auipc	ra,0x0
    80005116:	aa8080e7          	jalr	-1368(ra) # 80004bba <iunlock>
      return ip;
    8000511a:	bfe9                	j	800050f4 <namex+0x68>
      iunlockput(ip);
    8000511c:	854e                	mv	a0,s3
    8000511e:	00000097          	auipc	ra,0x0
    80005122:	c3c080e7          	jalr	-964(ra) # 80004d5a <iunlockput>
      return 0;
    80005126:	89e6                	mv	s3,s9
    80005128:	b7f1                	j	800050f4 <namex+0x68>
  len = path - s;
    8000512a:	40b48633          	sub	a2,s1,a1
    8000512e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80005132:	099c5463          	bge	s8,s9,800051ba <namex+0x12e>
    memmove(name, s, DIRSIZ);
    80005136:	4639                	li	a2,14
    80005138:	8552                	mv	a0,s4
    8000513a:	ffffc097          	auipc	ra,0xffffc
    8000513e:	c6c080e7          	jalr	-916(ra) # 80000da6 <memmove>
  while(*path == '/')
    80005142:	0004c783          	lbu	a5,0(s1)
    80005146:	01279763          	bne	a5,s2,80005154 <namex+0xc8>
    path++;
    8000514a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000514c:	0004c783          	lbu	a5,0(s1)
    80005150:	ff278de3          	beq	a5,s2,8000514a <namex+0xbe>
    ilock(ip);
    80005154:	854e                	mv	a0,s3
    80005156:	00000097          	auipc	ra,0x0
    8000515a:	9a2080e7          	jalr	-1630(ra) # 80004af8 <ilock>
    if(ip->type != T_DIR){
    8000515e:	04499783          	lh	a5,68(s3)
    80005162:	f97793e3          	bne	a5,s7,800050e8 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80005166:	000a8563          	beqz	s5,80005170 <namex+0xe4>
    8000516a:	0004c783          	lbu	a5,0(s1)
    8000516e:	d3cd                	beqz	a5,80005110 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80005170:	865a                	mv	a2,s6
    80005172:	85d2                	mv	a1,s4
    80005174:	854e                	mv	a0,s3
    80005176:	00000097          	auipc	ra,0x0
    8000517a:	e66080e7          	jalr	-410(ra) # 80004fdc <dirlookup>
    8000517e:	8caa                	mv	s9,a0
    80005180:	dd51                	beqz	a0,8000511c <namex+0x90>
    iunlockput(ip);
    80005182:	854e                	mv	a0,s3
    80005184:	00000097          	auipc	ra,0x0
    80005188:	bd6080e7          	jalr	-1066(ra) # 80004d5a <iunlockput>
    ip = next;
    8000518c:	89e6                	mv	s3,s9
  while(*path == '/')
    8000518e:	0004c783          	lbu	a5,0(s1)
    80005192:	05279763          	bne	a5,s2,800051e0 <namex+0x154>
    path++;
    80005196:	0485                	addi	s1,s1,1
  while(*path == '/')
    80005198:	0004c783          	lbu	a5,0(s1)
    8000519c:	ff278de3          	beq	a5,s2,80005196 <namex+0x10a>
  if(*path == 0)
    800051a0:	c79d                	beqz	a5,800051ce <namex+0x142>
    path++;
    800051a2:	85a6                	mv	a1,s1
  len = path - s;
    800051a4:	8cda                	mv	s9,s6
    800051a6:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800051a8:	01278963          	beq	a5,s2,800051ba <namex+0x12e>
    800051ac:	dfbd                	beqz	a5,8000512a <namex+0x9e>
    path++;
    800051ae:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800051b0:	0004c783          	lbu	a5,0(s1)
    800051b4:	ff279ce3          	bne	a5,s2,800051ac <namex+0x120>
    800051b8:	bf8d                	j	8000512a <namex+0x9e>
    memmove(name, s, len);
    800051ba:	2601                	sext.w	a2,a2
    800051bc:	8552                	mv	a0,s4
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	be8080e7          	jalr	-1048(ra) # 80000da6 <memmove>
    name[len] = 0;
    800051c6:	9cd2                	add	s9,s9,s4
    800051c8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800051cc:	bf9d                	j	80005142 <namex+0xb6>
  if(nameiparent){
    800051ce:	f20a83e3          	beqz	s5,800050f4 <namex+0x68>
    iput(ip);
    800051d2:	854e                	mv	a0,s3
    800051d4:	00000097          	auipc	ra,0x0
    800051d8:	ade080e7          	jalr	-1314(ra) # 80004cb2 <iput>
    return 0;
    800051dc:	4981                	li	s3,0
    800051de:	bf19                	j	800050f4 <namex+0x68>
  if(*path == 0)
    800051e0:	d7fd                	beqz	a5,800051ce <namex+0x142>
  while(*path != '/' && *path != 0)
    800051e2:	0004c783          	lbu	a5,0(s1)
    800051e6:	85a6                	mv	a1,s1
    800051e8:	b7d1                	j	800051ac <namex+0x120>

00000000800051ea <dirlink>:
{
    800051ea:	7139                	addi	sp,sp,-64
    800051ec:	fc06                	sd	ra,56(sp)
    800051ee:	f822                	sd	s0,48(sp)
    800051f0:	f426                	sd	s1,40(sp)
    800051f2:	f04a                	sd	s2,32(sp)
    800051f4:	ec4e                	sd	s3,24(sp)
    800051f6:	e852                	sd	s4,16(sp)
    800051f8:	0080                	addi	s0,sp,64
    800051fa:	892a                	mv	s2,a0
    800051fc:	8a2e                	mv	s4,a1
    800051fe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80005200:	4601                	li	a2,0
    80005202:	00000097          	auipc	ra,0x0
    80005206:	dda080e7          	jalr	-550(ra) # 80004fdc <dirlookup>
    8000520a:	e93d                	bnez	a0,80005280 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000520c:	04c92483          	lw	s1,76(s2)
    80005210:	c49d                	beqz	s1,8000523e <dirlink+0x54>
    80005212:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005214:	4741                	li	a4,16
    80005216:	86a6                	mv	a3,s1
    80005218:	fc040613          	addi	a2,s0,-64
    8000521c:	4581                	li	a1,0
    8000521e:	854a                	mv	a0,s2
    80005220:	00000097          	auipc	ra,0x0
    80005224:	b8c080e7          	jalr	-1140(ra) # 80004dac <readi>
    80005228:	47c1                	li	a5,16
    8000522a:	06f51163          	bne	a0,a5,8000528c <dirlink+0xa2>
    if(de.inum == 0)
    8000522e:	fc045783          	lhu	a5,-64(s0)
    80005232:	c791                	beqz	a5,8000523e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80005234:	24c1                	addiw	s1,s1,16
    80005236:	04c92783          	lw	a5,76(s2)
    8000523a:	fcf4ede3          	bltu	s1,a5,80005214 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000523e:	4639                	li	a2,14
    80005240:	85d2                	mv	a1,s4
    80005242:	fc240513          	addi	a0,s0,-62
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	c18080e7          	jalr	-1000(ra) # 80000e5e <strncpy>
  de.inum = inum;
    8000524e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005252:	4741                	li	a4,16
    80005254:	86a6                	mv	a3,s1
    80005256:	fc040613          	addi	a2,s0,-64
    8000525a:	4581                	li	a1,0
    8000525c:	854a                	mv	a0,s2
    8000525e:	00000097          	auipc	ra,0x0
    80005262:	c46080e7          	jalr	-954(ra) # 80004ea4 <writei>
    80005266:	872a                	mv	a4,a0
    80005268:	47c1                	li	a5,16
  return 0;
    8000526a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000526c:	02f71863          	bne	a4,a5,8000529c <dirlink+0xb2>
}
    80005270:	70e2                	ld	ra,56(sp)
    80005272:	7442                	ld	s0,48(sp)
    80005274:	74a2                	ld	s1,40(sp)
    80005276:	7902                	ld	s2,32(sp)
    80005278:	69e2                	ld	s3,24(sp)
    8000527a:	6a42                	ld	s4,16(sp)
    8000527c:	6121                	addi	sp,sp,64
    8000527e:	8082                	ret
    iput(ip);
    80005280:	00000097          	auipc	ra,0x0
    80005284:	a32080e7          	jalr	-1486(ra) # 80004cb2 <iput>
    return -1;
    80005288:	557d                	li	a0,-1
    8000528a:	b7dd                	j	80005270 <dirlink+0x86>
      panic("dirlink read");
    8000528c:	00004517          	auipc	a0,0x4
    80005290:	44c50513          	addi	a0,a0,1100 # 800096d8 <syscalls+0x220>
    80005294:	ffffb097          	auipc	ra,0xffffb
    80005298:	296080e7          	jalr	662(ra) # 8000052a <panic>
    panic("dirlink");
    8000529c:	00004517          	auipc	a0,0x4
    800052a0:	54c50513          	addi	a0,a0,1356 # 800097e8 <syscalls+0x330>
    800052a4:	ffffb097          	auipc	ra,0xffffb
    800052a8:	286080e7          	jalr	646(ra) # 8000052a <panic>

00000000800052ac <namei>:

struct inode*
namei(char *path)
{
    800052ac:	1101                	addi	sp,sp,-32
    800052ae:	ec06                	sd	ra,24(sp)
    800052b0:	e822                	sd	s0,16(sp)
    800052b2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800052b4:	fe040613          	addi	a2,s0,-32
    800052b8:	4581                	li	a1,0
    800052ba:	00000097          	auipc	ra,0x0
    800052be:	dd2080e7          	jalr	-558(ra) # 8000508c <namex>
}
    800052c2:	60e2                	ld	ra,24(sp)
    800052c4:	6442                	ld	s0,16(sp)
    800052c6:	6105                	addi	sp,sp,32
    800052c8:	8082                	ret

00000000800052ca <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800052ca:	1141                	addi	sp,sp,-16
    800052cc:	e406                	sd	ra,8(sp)
    800052ce:	e022                	sd	s0,0(sp)
    800052d0:	0800                	addi	s0,sp,16
    800052d2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800052d4:	4585                	li	a1,1
    800052d6:	00000097          	auipc	ra,0x0
    800052da:	db6080e7          	jalr	-586(ra) # 8000508c <namex>
}
    800052de:	60a2                	ld	ra,8(sp)
    800052e0:	6402                	ld	s0,0(sp)
    800052e2:	0141                	addi	sp,sp,16
    800052e4:	8082                	ret

00000000800052e6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800052e6:	1101                	addi	sp,sp,-32
    800052e8:	ec06                	sd	ra,24(sp)
    800052ea:	e822                	sd	s0,16(sp)
    800052ec:	e426                	sd	s1,8(sp)
    800052ee:	e04a                	sd	s2,0(sp)
    800052f0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800052f2:	0004b917          	auipc	s2,0x4b
    800052f6:	9d690913          	addi	s2,s2,-1578 # 8004fcc8 <log>
    800052fa:	01892583          	lw	a1,24(s2)
    800052fe:	02892503          	lw	a0,40(s2)
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	ff2080e7          	jalr	-14(ra) # 800042f4 <bread>
    8000530a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000530c:	02c92683          	lw	a3,44(s2)
    80005310:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80005312:	02d05863          	blez	a3,80005342 <write_head+0x5c>
    80005316:	0004b797          	auipc	a5,0x4b
    8000531a:	9e278793          	addi	a5,a5,-1566 # 8004fcf8 <log+0x30>
    8000531e:	05c50713          	addi	a4,a0,92
    80005322:	36fd                	addiw	a3,a3,-1
    80005324:	02069613          	slli	a2,a3,0x20
    80005328:	01e65693          	srli	a3,a2,0x1e
    8000532c:	0004b617          	auipc	a2,0x4b
    80005330:	9d060613          	addi	a2,a2,-1584 # 8004fcfc <log+0x34>
    80005334:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80005336:	4390                	lw	a2,0(a5)
    80005338:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000533a:	0791                	addi	a5,a5,4
    8000533c:	0711                	addi	a4,a4,4
    8000533e:	fed79ce3          	bne	a5,a3,80005336 <write_head+0x50>
  }
  bwrite(buf);
    80005342:	8526                	mv	a0,s1
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	0a2080e7          	jalr	162(ra) # 800043e6 <bwrite>
  brelse(buf);
    8000534c:	8526                	mv	a0,s1
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	0d6080e7          	jalr	214(ra) # 80004424 <brelse>
}
    80005356:	60e2                	ld	ra,24(sp)
    80005358:	6442                	ld	s0,16(sp)
    8000535a:	64a2                	ld	s1,8(sp)
    8000535c:	6902                	ld	s2,0(sp)
    8000535e:	6105                	addi	sp,sp,32
    80005360:	8082                	ret

0000000080005362 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80005362:	0004b797          	auipc	a5,0x4b
    80005366:	9927a783          	lw	a5,-1646(a5) # 8004fcf4 <log+0x2c>
    8000536a:	0af05d63          	blez	a5,80005424 <install_trans+0xc2>
{
    8000536e:	7139                	addi	sp,sp,-64
    80005370:	fc06                	sd	ra,56(sp)
    80005372:	f822                	sd	s0,48(sp)
    80005374:	f426                	sd	s1,40(sp)
    80005376:	f04a                	sd	s2,32(sp)
    80005378:	ec4e                	sd	s3,24(sp)
    8000537a:	e852                	sd	s4,16(sp)
    8000537c:	e456                	sd	s5,8(sp)
    8000537e:	e05a                	sd	s6,0(sp)
    80005380:	0080                	addi	s0,sp,64
    80005382:	8b2a                	mv	s6,a0
    80005384:	0004ba97          	auipc	s5,0x4b
    80005388:	974a8a93          	addi	s5,s5,-1676 # 8004fcf8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000538c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000538e:	0004b997          	auipc	s3,0x4b
    80005392:	93a98993          	addi	s3,s3,-1734 # 8004fcc8 <log>
    80005396:	a00d                	j	800053b8 <install_trans+0x56>
    brelse(lbuf);
    80005398:	854a                	mv	a0,s2
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	08a080e7          	jalr	138(ra) # 80004424 <brelse>
    brelse(dbuf);
    800053a2:	8526                	mv	a0,s1
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	080080e7          	jalr	128(ra) # 80004424 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800053ac:	2a05                	addiw	s4,s4,1
    800053ae:	0a91                	addi	s5,s5,4
    800053b0:	02c9a783          	lw	a5,44(s3)
    800053b4:	04fa5e63          	bge	s4,a5,80005410 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800053b8:	0189a583          	lw	a1,24(s3)
    800053bc:	014585bb          	addw	a1,a1,s4
    800053c0:	2585                	addiw	a1,a1,1
    800053c2:	0289a503          	lw	a0,40(s3)
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	f2e080e7          	jalr	-210(ra) # 800042f4 <bread>
    800053ce:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800053d0:	000aa583          	lw	a1,0(s5)
    800053d4:	0289a503          	lw	a0,40(s3)
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	f1c080e7          	jalr	-228(ra) # 800042f4 <bread>
    800053e0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800053e2:	40000613          	li	a2,1024
    800053e6:	05890593          	addi	a1,s2,88
    800053ea:	05850513          	addi	a0,a0,88
    800053ee:	ffffc097          	auipc	ra,0xffffc
    800053f2:	9b8080e7          	jalr	-1608(ra) # 80000da6 <memmove>
    bwrite(dbuf);  // write dst to disk
    800053f6:	8526                	mv	a0,s1
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	fee080e7          	jalr	-18(ra) # 800043e6 <bwrite>
    if(recovering == 0)
    80005400:	f80b1ce3          	bnez	s6,80005398 <install_trans+0x36>
      bunpin(dbuf);
    80005404:	8526                	mv	a0,s1
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	0f8080e7          	jalr	248(ra) # 800044fe <bunpin>
    8000540e:	b769                	j	80005398 <install_trans+0x36>
}
    80005410:	70e2                	ld	ra,56(sp)
    80005412:	7442                	ld	s0,48(sp)
    80005414:	74a2                	ld	s1,40(sp)
    80005416:	7902                	ld	s2,32(sp)
    80005418:	69e2                	ld	s3,24(sp)
    8000541a:	6a42                	ld	s4,16(sp)
    8000541c:	6aa2                	ld	s5,8(sp)
    8000541e:	6b02                	ld	s6,0(sp)
    80005420:	6121                	addi	sp,sp,64
    80005422:	8082                	ret
    80005424:	8082                	ret

0000000080005426 <initlog>:
{
    80005426:	7179                	addi	sp,sp,-48
    80005428:	f406                	sd	ra,40(sp)
    8000542a:	f022                	sd	s0,32(sp)
    8000542c:	ec26                	sd	s1,24(sp)
    8000542e:	e84a                	sd	s2,16(sp)
    80005430:	e44e                	sd	s3,8(sp)
    80005432:	1800                	addi	s0,sp,48
    80005434:	892a                	mv	s2,a0
    80005436:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80005438:	0004b497          	auipc	s1,0x4b
    8000543c:	89048493          	addi	s1,s1,-1904 # 8004fcc8 <log>
    80005440:	00004597          	auipc	a1,0x4
    80005444:	2a858593          	addi	a1,a1,680 # 800096e8 <syscalls+0x230>
    80005448:	8526                	mv	a0,s1
    8000544a:	ffffb097          	auipc	ra,0xffffb
    8000544e:	708080e7          	jalr	1800(ra) # 80000b52 <initlock>
  log.start = sb->logstart;
    80005452:	0149a583          	lw	a1,20(s3)
    80005456:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80005458:	0109a783          	lw	a5,16(s3)
    8000545c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000545e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80005462:	854a                	mv	a0,s2
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	e90080e7          	jalr	-368(ra) # 800042f4 <bread>
  log.lh.n = lh->n;
    8000546c:	4d34                	lw	a3,88(a0)
    8000546e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80005470:	02d05663          	blez	a3,8000549c <initlog+0x76>
    80005474:	05c50793          	addi	a5,a0,92
    80005478:	0004b717          	auipc	a4,0x4b
    8000547c:	88070713          	addi	a4,a4,-1920 # 8004fcf8 <log+0x30>
    80005480:	36fd                	addiw	a3,a3,-1
    80005482:	02069613          	slli	a2,a3,0x20
    80005486:	01e65693          	srli	a3,a2,0x1e
    8000548a:	06050613          	addi	a2,a0,96
    8000548e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80005490:	4390                	lw	a2,0(a5)
    80005492:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80005494:	0791                	addi	a5,a5,4
    80005496:	0711                	addi	a4,a4,4
    80005498:	fed79ce3          	bne	a5,a3,80005490 <initlog+0x6a>
  brelse(buf);
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	f88080e7          	jalr	-120(ra) # 80004424 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800054a4:	4505                	li	a0,1
    800054a6:	00000097          	auipc	ra,0x0
    800054aa:	ebc080e7          	jalr	-324(ra) # 80005362 <install_trans>
  log.lh.n = 0;
    800054ae:	0004b797          	auipc	a5,0x4b
    800054b2:	8407a323          	sw	zero,-1978(a5) # 8004fcf4 <log+0x2c>
  write_head(); // clear the log
    800054b6:	00000097          	auipc	ra,0x0
    800054ba:	e30080e7          	jalr	-464(ra) # 800052e6 <write_head>
}
    800054be:	70a2                	ld	ra,40(sp)
    800054c0:	7402                	ld	s0,32(sp)
    800054c2:	64e2                	ld	s1,24(sp)
    800054c4:	6942                	ld	s2,16(sp)
    800054c6:	69a2                	ld	s3,8(sp)
    800054c8:	6145                	addi	sp,sp,48
    800054ca:	8082                	ret

00000000800054cc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800054cc:	1101                	addi	sp,sp,-32
    800054ce:	ec06                	sd	ra,24(sp)
    800054d0:	e822                	sd	s0,16(sp)
    800054d2:	e426                	sd	s1,8(sp)
    800054d4:	e04a                	sd	s2,0(sp)
    800054d6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800054d8:	0004a517          	auipc	a0,0x4a
    800054dc:	7f050513          	addi	a0,a0,2032 # 8004fcc8 <log>
    800054e0:	ffffb097          	auipc	ra,0xffffb
    800054e4:	752080e7          	jalr	1874(ra) # 80000c32 <acquire>
  while(1){
    if(log.committing){
    800054e8:	0004a497          	auipc	s1,0x4a
    800054ec:	7e048493          	addi	s1,s1,2016 # 8004fcc8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800054f0:	4979                	li	s2,30
    800054f2:	a039                	j	80005500 <begin_op+0x34>
      sleep(&log, &log.lock);
    800054f4:	85a6                	mv	a1,s1
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffd097          	auipc	ra,0xffffd
    800054fc:	3aa080e7          	jalr	938(ra) # 800028a2 <sleep>
    if(log.committing){
    80005500:	50dc                	lw	a5,36(s1)
    80005502:	fbed                	bnez	a5,800054f4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005504:	509c                	lw	a5,32(s1)
    80005506:	0017871b          	addiw	a4,a5,1
    8000550a:	0007069b          	sext.w	a3,a4
    8000550e:	0027179b          	slliw	a5,a4,0x2
    80005512:	9fb9                	addw	a5,a5,a4
    80005514:	0017979b          	slliw	a5,a5,0x1
    80005518:	54d8                	lw	a4,44(s1)
    8000551a:	9fb9                	addw	a5,a5,a4
    8000551c:	00f95963          	bge	s2,a5,8000552e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80005520:	85a6                	mv	a1,s1
    80005522:	8526                	mv	a0,s1
    80005524:	ffffd097          	auipc	ra,0xffffd
    80005528:	37e080e7          	jalr	894(ra) # 800028a2 <sleep>
    8000552c:	bfd1                	j	80005500 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000552e:	0004a517          	auipc	a0,0x4a
    80005532:	79a50513          	addi	a0,a0,1946 # 8004fcc8 <log>
    80005536:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80005538:	ffffb097          	auipc	ra,0xffffb
    8000553c:	7ae080e7          	jalr	1966(ra) # 80000ce6 <release>
      break;
    }
  }
}
    80005540:	60e2                	ld	ra,24(sp)
    80005542:	6442                	ld	s0,16(sp)
    80005544:	64a2                	ld	s1,8(sp)
    80005546:	6902                	ld	s2,0(sp)
    80005548:	6105                	addi	sp,sp,32
    8000554a:	8082                	ret

000000008000554c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000554c:	7139                	addi	sp,sp,-64
    8000554e:	fc06                	sd	ra,56(sp)
    80005550:	f822                	sd	s0,48(sp)
    80005552:	f426                	sd	s1,40(sp)
    80005554:	f04a                	sd	s2,32(sp)
    80005556:	ec4e                	sd	s3,24(sp)
    80005558:	e852                	sd	s4,16(sp)
    8000555a:	e456                	sd	s5,8(sp)
    8000555c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000555e:	0004a497          	auipc	s1,0x4a
    80005562:	76a48493          	addi	s1,s1,1898 # 8004fcc8 <log>
    80005566:	8526                	mv	a0,s1
    80005568:	ffffb097          	auipc	ra,0xffffb
    8000556c:	6ca080e7          	jalr	1738(ra) # 80000c32 <acquire>
  log.outstanding -= 1;
    80005570:	509c                	lw	a5,32(s1)
    80005572:	37fd                	addiw	a5,a5,-1
    80005574:	0007891b          	sext.w	s2,a5
    80005578:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000557a:	50dc                	lw	a5,36(s1)
    8000557c:	e7b9                	bnez	a5,800055ca <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000557e:	04091e63          	bnez	s2,800055da <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80005582:	0004a497          	auipc	s1,0x4a
    80005586:	74648493          	addi	s1,s1,1862 # 8004fcc8 <log>
    8000558a:	4785                	li	a5,1
    8000558c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000558e:	8526                	mv	a0,s1
    80005590:	ffffb097          	auipc	ra,0xffffb
    80005594:	756080e7          	jalr	1878(ra) # 80000ce6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80005598:	54dc                	lw	a5,44(s1)
    8000559a:	06f04763          	bgtz	a5,80005608 <end_op+0xbc>
    acquire(&log.lock);
    8000559e:	0004a497          	auipc	s1,0x4a
    800055a2:	72a48493          	addi	s1,s1,1834 # 8004fcc8 <log>
    800055a6:	8526                	mv	a0,s1
    800055a8:	ffffb097          	auipc	ra,0xffffb
    800055ac:	68a080e7          	jalr	1674(ra) # 80000c32 <acquire>
    log.committing = 0;
    800055b0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffd097          	auipc	ra,0xffffd
    800055ba:	482080e7          	jalr	1154(ra) # 80002a38 <wakeup>
    release(&log.lock);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffb097          	auipc	ra,0xffffb
    800055c4:	726080e7          	jalr	1830(ra) # 80000ce6 <release>
}
    800055c8:	a03d                	j	800055f6 <end_op+0xaa>
    panic("log.committing");
    800055ca:	00004517          	auipc	a0,0x4
    800055ce:	12650513          	addi	a0,a0,294 # 800096f0 <syscalls+0x238>
    800055d2:	ffffb097          	auipc	ra,0xffffb
    800055d6:	f58080e7          	jalr	-168(ra) # 8000052a <panic>
    wakeup(&log);
    800055da:	0004a497          	auipc	s1,0x4a
    800055de:	6ee48493          	addi	s1,s1,1774 # 8004fcc8 <log>
    800055e2:	8526                	mv	a0,s1
    800055e4:	ffffd097          	auipc	ra,0xffffd
    800055e8:	454080e7          	jalr	1108(ra) # 80002a38 <wakeup>
  release(&log.lock);
    800055ec:	8526                	mv	a0,s1
    800055ee:	ffffb097          	auipc	ra,0xffffb
    800055f2:	6f8080e7          	jalr	1784(ra) # 80000ce6 <release>
}
    800055f6:	70e2                	ld	ra,56(sp)
    800055f8:	7442                	ld	s0,48(sp)
    800055fa:	74a2                	ld	s1,40(sp)
    800055fc:	7902                	ld	s2,32(sp)
    800055fe:	69e2                	ld	s3,24(sp)
    80005600:	6a42                	ld	s4,16(sp)
    80005602:	6aa2                	ld	s5,8(sp)
    80005604:	6121                	addi	sp,sp,64
    80005606:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80005608:	0004aa97          	auipc	s5,0x4a
    8000560c:	6f0a8a93          	addi	s5,s5,1776 # 8004fcf8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80005610:	0004aa17          	auipc	s4,0x4a
    80005614:	6b8a0a13          	addi	s4,s4,1720 # 8004fcc8 <log>
    80005618:	018a2583          	lw	a1,24(s4)
    8000561c:	012585bb          	addw	a1,a1,s2
    80005620:	2585                	addiw	a1,a1,1
    80005622:	028a2503          	lw	a0,40(s4)
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	cce080e7          	jalr	-818(ra) # 800042f4 <bread>
    8000562e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80005630:	000aa583          	lw	a1,0(s5)
    80005634:	028a2503          	lw	a0,40(s4)
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	cbc080e7          	jalr	-836(ra) # 800042f4 <bread>
    80005640:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005642:	40000613          	li	a2,1024
    80005646:	05850593          	addi	a1,a0,88
    8000564a:	05848513          	addi	a0,s1,88
    8000564e:	ffffb097          	auipc	ra,0xffffb
    80005652:	758080e7          	jalr	1880(ra) # 80000da6 <memmove>
    bwrite(to);  // write the log
    80005656:	8526                	mv	a0,s1
    80005658:	fffff097          	auipc	ra,0xfffff
    8000565c:	d8e080e7          	jalr	-626(ra) # 800043e6 <bwrite>
    brelse(from);
    80005660:	854e                	mv	a0,s3
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	dc2080e7          	jalr	-574(ra) # 80004424 <brelse>
    brelse(to);
    8000566a:	8526                	mv	a0,s1
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	db8080e7          	jalr	-584(ra) # 80004424 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005674:	2905                	addiw	s2,s2,1
    80005676:	0a91                	addi	s5,s5,4
    80005678:	02ca2783          	lw	a5,44(s4)
    8000567c:	f8f94ee3          	blt	s2,a5,80005618 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80005680:	00000097          	auipc	ra,0x0
    80005684:	c66080e7          	jalr	-922(ra) # 800052e6 <write_head>
    install_trans(0); // Now install writes to home locations
    80005688:	4501                	li	a0,0
    8000568a:	00000097          	auipc	ra,0x0
    8000568e:	cd8080e7          	jalr	-808(ra) # 80005362 <install_trans>
    log.lh.n = 0;
    80005692:	0004a797          	auipc	a5,0x4a
    80005696:	6607a123          	sw	zero,1634(a5) # 8004fcf4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000569a:	00000097          	auipc	ra,0x0
    8000569e:	c4c080e7          	jalr	-948(ra) # 800052e6 <write_head>
    800056a2:	bdf5                	j	8000559e <end_op+0x52>

00000000800056a4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800056a4:	1101                	addi	sp,sp,-32
    800056a6:	ec06                	sd	ra,24(sp)
    800056a8:	e822                	sd	s0,16(sp)
    800056aa:	e426                	sd	s1,8(sp)
    800056ac:	e04a                	sd	s2,0(sp)
    800056ae:	1000                	addi	s0,sp,32
    800056b0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800056b2:	0004a917          	auipc	s2,0x4a
    800056b6:	61690913          	addi	s2,s2,1558 # 8004fcc8 <log>
    800056ba:	854a                	mv	a0,s2
    800056bc:	ffffb097          	auipc	ra,0xffffb
    800056c0:	576080e7          	jalr	1398(ra) # 80000c32 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800056c4:	02c92603          	lw	a2,44(s2)
    800056c8:	47f5                	li	a5,29
    800056ca:	06c7c563          	blt	a5,a2,80005734 <log_write+0x90>
    800056ce:	0004a797          	auipc	a5,0x4a
    800056d2:	6167a783          	lw	a5,1558(a5) # 8004fce4 <log+0x1c>
    800056d6:	37fd                	addiw	a5,a5,-1
    800056d8:	04f65e63          	bge	a2,a5,80005734 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800056dc:	0004a797          	auipc	a5,0x4a
    800056e0:	60c7a783          	lw	a5,1548(a5) # 8004fce8 <log+0x20>
    800056e4:	06f05063          	blez	a5,80005744 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800056e8:	4781                	li	a5,0
    800056ea:	06c05563          	blez	a2,80005754 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800056ee:	44cc                	lw	a1,12(s1)
    800056f0:	0004a717          	auipc	a4,0x4a
    800056f4:	60870713          	addi	a4,a4,1544 # 8004fcf8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800056f8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800056fa:	4314                	lw	a3,0(a4)
    800056fc:	04b68c63          	beq	a3,a1,80005754 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80005700:	2785                	addiw	a5,a5,1
    80005702:	0711                	addi	a4,a4,4
    80005704:	fef61be3          	bne	a2,a5,800056fa <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80005708:	0621                	addi	a2,a2,8
    8000570a:	060a                	slli	a2,a2,0x2
    8000570c:	0004a797          	auipc	a5,0x4a
    80005710:	5bc78793          	addi	a5,a5,1468 # 8004fcc8 <log>
    80005714:	963e                	add	a2,a2,a5
    80005716:	44dc                	lw	a5,12(s1)
    80005718:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000571a:	8526                	mv	a0,s1
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	da6080e7          	jalr	-602(ra) # 800044c2 <bpin>
    log.lh.n++;
    80005724:	0004a717          	auipc	a4,0x4a
    80005728:	5a470713          	addi	a4,a4,1444 # 8004fcc8 <log>
    8000572c:	575c                	lw	a5,44(a4)
    8000572e:	2785                	addiw	a5,a5,1
    80005730:	d75c                	sw	a5,44(a4)
    80005732:	a835                	j	8000576e <log_write+0xca>
    panic("too big a transaction");
    80005734:	00004517          	auipc	a0,0x4
    80005738:	fcc50513          	addi	a0,a0,-52 # 80009700 <syscalls+0x248>
    8000573c:	ffffb097          	auipc	ra,0xffffb
    80005740:	dee080e7          	jalr	-530(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80005744:	00004517          	auipc	a0,0x4
    80005748:	fd450513          	addi	a0,a0,-44 # 80009718 <syscalls+0x260>
    8000574c:	ffffb097          	auipc	ra,0xffffb
    80005750:	dde080e7          	jalr	-546(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80005754:	00878713          	addi	a4,a5,8
    80005758:	00271693          	slli	a3,a4,0x2
    8000575c:	0004a717          	auipc	a4,0x4a
    80005760:	56c70713          	addi	a4,a4,1388 # 8004fcc8 <log>
    80005764:	9736                	add	a4,a4,a3
    80005766:	44d4                	lw	a3,12(s1)
    80005768:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000576a:	faf608e3          	beq	a2,a5,8000571a <log_write+0x76>
  }
  release(&log.lock);
    8000576e:	0004a517          	auipc	a0,0x4a
    80005772:	55a50513          	addi	a0,a0,1370 # 8004fcc8 <log>
    80005776:	ffffb097          	auipc	ra,0xffffb
    8000577a:	570080e7          	jalr	1392(ra) # 80000ce6 <release>
}
    8000577e:	60e2                	ld	ra,24(sp)
    80005780:	6442                	ld	s0,16(sp)
    80005782:	64a2                	ld	s1,8(sp)
    80005784:	6902                	ld	s2,0(sp)
    80005786:	6105                	addi	sp,sp,32
    80005788:	8082                	ret

000000008000578a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000578a:	1101                	addi	sp,sp,-32
    8000578c:	ec06                	sd	ra,24(sp)
    8000578e:	e822                	sd	s0,16(sp)
    80005790:	e426                	sd	s1,8(sp)
    80005792:	e04a                	sd	s2,0(sp)
    80005794:	1000                	addi	s0,sp,32
    80005796:	84aa                	mv	s1,a0
    80005798:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000579a:	00004597          	auipc	a1,0x4
    8000579e:	f9e58593          	addi	a1,a1,-98 # 80009738 <syscalls+0x280>
    800057a2:	0521                	addi	a0,a0,8
    800057a4:	ffffb097          	auipc	ra,0xffffb
    800057a8:	3ae080e7          	jalr	942(ra) # 80000b52 <initlock>
  lk->name = name;
    800057ac:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800057b0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800057b4:	0204a423          	sw	zero,40(s1)
}
    800057b8:	60e2                	ld	ra,24(sp)
    800057ba:	6442                	ld	s0,16(sp)
    800057bc:	64a2                	ld	s1,8(sp)
    800057be:	6902                	ld	s2,0(sp)
    800057c0:	6105                	addi	sp,sp,32
    800057c2:	8082                	ret

00000000800057c4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800057c4:	1101                	addi	sp,sp,-32
    800057c6:	ec06                	sd	ra,24(sp)
    800057c8:	e822                	sd	s0,16(sp)
    800057ca:	e426                	sd	s1,8(sp)
    800057cc:	e04a                	sd	s2,0(sp)
    800057ce:	1000                	addi	s0,sp,32
    800057d0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800057d2:	00850913          	addi	s2,a0,8
    800057d6:	854a                	mv	a0,s2
    800057d8:	ffffb097          	auipc	ra,0xffffb
    800057dc:	45a080e7          	jalr	1114(ra) # 80000c32 <acquire>
  while (lk->locked) {
    800057e0:	409c                	lw	a5,0(s1)
    800057e2:	cb89                	beqz	a5,800057f4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800057e4:	85ca                	mv	a1,s2
    800057e6:	8526                	mv	a0,s1
    800057e8:	ffffd097          	auipc	ra,0xffffd
    800057ec:	0ba080e7          	jalr	186(ra) # 800028a2 <sleep>
  while (lk->locked) {
    800057f0:	409c                	lw	a5,0(s1)
    800057f2:	fbed                	bnez	a5,800057e4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800057f4:	4785                	li	a5,1
    800057f6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800057f8:	ffffc097          	auipc	ra,0xffffc
    800057fc:	34e080e7          	jalr	846(ra) # 80001b46 <myproc>
    80005800:	515c                	lw	a5,36(a0)
    80005802:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005804:	854a                	mv	a0,s2
    80005806:	ffffb097          	auipc	ra,0xffffb
    8000580a:	4e0080e7          	jalr	1248(ra) # 80000ce6 <release>
}
    8000580e:	60e2                	ld	ra,24(sp)
    80005810:	6442                	ld	s0,16(sp)
    80005812:	64a2                	ld	s1,8(sp)
    80005814:	6902                	ld	s2,0(sp)
    80005816:	6105                	addi	sp,sp,32
    80005818:	8082                	ret

000000008000581a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000581a:	1101                	addi	sp,sp,-32
    8000581c:	ec06                	sd	ra,24(sp)
    8000581e:	e822                	sd	s0,16(sp)
    80005820:	e426                	sd	s1,8(sp)
    80005822:	e04a                	sd	s2,0(sp)
    80005824:	1000                	addi	s0,sp,32
    80005826:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005828:	00850913          	addi	s2,a0,8
    8000582c:	854a                	mv	a0,s2
    8000582e:	ffffb097          	auipc	ra,0xffffb
    80005832:	404080e7          	jalr	1028(ra) # 80000c32 <acquire>
  lk->locked = 0;
    80005836:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000583a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000583e:	8526                	mv	a0,s1
    80005840:	ffffd097          	auipc	ra,0xffffd
    80005844:	1f8080e7          	jalr	504(ra) # 80002a38 <wakeup>
  release(&lk->lk);
    80005848:	854a                	mv	a0,s2
    8000584a:	ffffb097          	auipc	ra,0xffffb
    8000584e:	49c080e7          	jalr	1180(ra) # 80000ce6 <release>
}
    80005852:	60e2                	ld	ra,24(sp)
    80005854:	6442                	ld	s0,16(sp)
    80005856:	64a2                	ld	s1,8(sp)
    80005858:	6902                	ld	s2,0(sp)
    8000585a:	6105                	addi	sp,sp,32
    8000585c:	8082                	ret

000000008000585e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000585e:	7179                	addi	sp,sp,-48
    80005860:	f406                	sd	ra,40(sp)
    80005862:	f022                	sd	s0,32(sp)
    80005864:	ec26                	sd	s1,24(sp)
    80005866:	e84a                	sd	s2,16(sp)
    80005868:	e44e                	sd	s3,8(sp)
    8000586a:	1800                	addi	s0,sp,48
    8000586c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000586e:	00850913          	addi	s2,a0,8
    80005872:	854a                	mv	a0,s2
    80005874:	ffffb097          	auipc	ra,0xffffb
    80005878:	3be080e7          	jalr	958(ra) # 80000c32 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000587c:	409c                	lw	a5,0(s1)
    8000587e:	ef99                	bnez	a5,8000589c <holdingsleep+0x3e>
    80005880:	4481                	li	s1,0
  release(&lk->lk);
    80005882:	854a                	mv	a0,s2
    80005884:	ffffb097          	auipc	ra,0xffffb
    80005888:	462080e7          	jalr	1122(ra) # 80000ce6 <release>
  return r;
}
    8000588c:	8526                	mv	a0,s1
    8000588e:	70a2                	ld	ra,40(sp)
    80005890:	7402                	ld	s0,32(sp)
    80005892:	64e2                	ld	s1,24(sp)
    80005894:	6942                	ld	s2,16(sp)
    80005896:	69a2                	ld	s3,8(sp)
    80005898:	6145                	addi	sp,sp,48
    8000589a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000589c:	0284a983          	lw	s3,40(s1)
    800058a0:	ffffc097          	auipc	ra,0xffffc
    800058a4:	2a6080e7          	jalr	678(ra) # 80001b46 <myproc>
    800058a8:	5144                	lw	s1,36(a0)
    800058aa:	413484b3          	sub	s1,s1,s3
    800058ae:	0014b493          	seqz	s1,s1
    800058b2:	bfc1                	j	80005882 <holdingsleep+0x24>

00000000800058b4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800058b4:	1141                	addi	sp,sp,-16
    800058b6:	e406                	sd	ra,8(sp)
    800058b8:	e022                	sd	s0,0(sp)
    800058ba:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800058bc:	00004597          	auipc	a1,0x4
    800058c0:	e8c58593          	addi	a1,a1,-372 # 80009748 <syscalls+0x290>
    800058c4:	0004a517          	auipc	a0,0x4a
    800058c8:	54c50513          	addi	a0,a0,1356 # 8004fe10 <ftable>
    800058cc:	ffffb097          	auipc	ra,0xffffb
    800058d0:	286080e7          	jalr	646(ra) # 80000b52 <initlock>
}
    800058d4:	60a2                	ld	ra,8(sp)
    800058d6:	6402                	ld	s0,0(sp)
    800058d8:	0141                	addi	sp,sp,16
    800058da:	8082                	ret

00000000800058dc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800058dc:	1101                	addi	sp,sp,-32
    800058de:	ec06                	sd	ra,24(sp)
    800058e0:	e822                	sd	s0,16(sp)
    800058e2:	e426                	sd	s1,8(sp)
    800058e4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800058e6:	0004a517          	auipc	a0,0x4a
    800058ea:	52a50513          	addi	a0,a0,1322 # 8004fe10 <ftable>
    800058ee:	ffffb097          	auipc	ra,0xffffb
    800058f2:	344080e7          	jalr	836(ra) # 80000c32 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800058f6:	0004a497          	auipc	s1,0x4a
    800058fa:	53248493          	addi	s1,s1,1330 # 8004fe28 <ftable+0x18>
    800058fe:	0004b717          	auipc	a4,0x4b
    80005902:	4ca70713          	addi	a4,a4,1226 # 80050dc8 <defaultSigActionExec>
    if(f->ref == 0){
    80005906:	40dc                	lw	a5,4(s1)
    80005908:	cf99                	beqz	a5,80005926 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000590a:	02848493          	addi	s1,s1,40
    8000590e:	fee49ce3          	bne	s1,a4,80005906 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005912:	0004a517          	auipc	a0,0x4a
    80005916:	4fe50513          	addi	a0,a0,1278 # 8004fe10 <ftable>
    8000591a:	ffffb097          	auipc	ra,0xffffb
    8000591e:	3cc080e7          	jalr	972(ra) # 80000ce6 <release>
  return 0;
    80005922:	4481                	li	s1,0
    80005924:	a819                	j	8000593a <filealloc+0x5e>
      f->ref = 1;
    80005926:	4785                	li	a5,1
    80005928:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000592a:	0004a517          	auipc	a0,0x4a
    8000592e:	4e650513          	addi	a0,a0,1254 # 8004fe10 <ftable>
    80005932:	ffffb097          	auipc	ra,0xffffb
    80005936:	3b4080e7          	jalr	948(ra) # 80000ce6 <release>
}
    8000593a:	8526                	mv	a0,s1
    8000593c:	60e2                	ld	ra,24(sp)
    8000593e:	6442                	ld	s0,16(sp)
    80005940:	64a2                	ld	s1,8(sp)
    80005942:	6105                	addi	sp,sp,32
    80005944:	8082                	ret

0000000080005946 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005946:	1101                	addi	sp,sp,-32
    80005948:	ec06                	sd	ra,24(sp)
    8000594a:	e822                	sd	s0,16(sp)
    8000594c:	e426                	sd	s1,8(sp)
    8000594e:	1000                	addi	s0,sp,32
    80005950:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005952:	0004a517          	auipc	a0,0x4a
    80005956:	4be50513          	addi	a0,a0,1214 # 8004fe10 <ftable>
    8000595a:	ffffb097          	auipc	ra,0xffffb
    8000595e:	2d8080e7          	jalr	728(ra) # 80000c32 <acquire>
  if(f->ref < 1)
    80005962:	40dc                	lw	a5,4(s1)
    80005964:	02f05263          	blez	a5,80005988 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005968:	2785                	addiw	a5,a5,1
    8000596a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000596c:	0004a517          	auipc	a0,0x4a
    80005970:	4a450513          	addi	a0,a0,1188 # 8004fe10 <ftable>
    80005974:	ffffb097          	auipc	ra,0xffffb
    80005978:	372080e7          	jalr	882(ra) # 80000ce6 <release>
  return f;
}
    8000597c:	8526                	mv	a0,s1
    8000597e:	60e2                	ld	ra,24(sp)
    80005980:	6442                	ld	s0,16(sp)
    80005982:	64a2                	ld	s1,8(sp)
    80005984:	6105                	addi	sp,sp,32
    80005986:	8082                	ret
    panic("filedup");
    80005988:	00004517          	auipc	a0,0x4
    8000598c:	dc850513          	addi	a0,a0,-568 # 80009750 <syscalls+0x298>
    80005990:	ffffb097          	auipc	ra,0xffffb
    80005994:	b9a080e7          	jalr	-1126(ra) # 8000052a <panic>

0000000080005998 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005998:	7139                	addi	sp,sp,-64
    8000599a:	fc06                	sd	ra,56(sp)
    8000599c:	f822                	sd	s0,48(sp)
    8000599e:	f426                	sd	s1,40(sp)
    800059a0:	f04a                	sd	s2,32(sp)
    800059a2:	ec4e                	sd	s3,24(sp)
    800059a4:	e852                	sd	s4,16(sp)
    800059a6:	e456                	sd	s5,8(sp)
    800059a8:	0080                	addi	s0,sp,64
    800059aa:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800059ac:	0004a517          	auipc	a0,0x4a
    800059b0:	46450513          	addi	a0,a0,1124 # 8004fe10 <ftable>
    800059b4:	ffffb097          	auipc	ra,0xffffb
    800059b8:	27e080e7          	jalr	638(ra) # 80000c32 <acquire>
  if(f->ref < 1)
    800059bc:	40dc                	lw	a5,4(s1)
    800059be:	06f05163          	blez	a5,80005a20 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800059c2:	37fd                	addiw	a5,a5,-1
    800059c4:	0007871b          	sext.w	a4,a5
    800059c8:	c0dc                	sw	a5,4(s1)
    800059ca:	06e04363          	bgtz	a4,80005a30 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800059ce:	0004a903          	lw	s2,0(s1)
    800059d2:	0094ca83          	lbu	s5,9(s1)
    800059d6:	0104ba03          	ld	s4,16(s1)
    800059da:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800059de:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800059e2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800059e6:	0004a517          	auipc	a0,0x4a
    800059ea:	42a50513          	addi	a0,a0,1066 # 8004fe10 <ftable>
    800059ee:	ffffb097          	auipc	ra,0xffffb
    800059f2:	2f8080e7          	jalr	760(ra) # 80000ce6 <release>

  if(ff.type == FD_PIPE){
    800059f6:	4785                	li	a5,1
    800059f8:	04f90d63          	beq	s2,a5,80005a52 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800059fc:	3979                	addiw	s2,s2,-2
    800059fe:	4785                	li	a5,1
    80005a00:	0527e063          	bltu	a5,s2,80005a40 <fileclose+0xa8>
    begin_op();
    80005a04:	00000097          	auipc	ra,0x0
    80005a08:	ac8080e7          	jalr	-1336(ra) # 800054cc <begin_op>
    iput(ff.ip);
    80005a0c:	854e                	mv	a0,s3
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	2a4080e7          	jalr	676(ra) # 80004cb2 <iput>
    end_op();
    80005a16:	00000097          	auipc	ra,0x0
    80005a1a:	b36080e7          	jalr	-1226(ra) # 8000554c <end_op>
    80005a1e:	a00d                	j	80005a40 <fileclose+0xa8>
    panic("fileclose");
    80005a20:	00004517          	auipc	a0,0x4
    80005a24:	d3850513          	addi	a0,a0,-712 # 80009758 <syscalls+0x2a0>
    80005a28:	ffffb097          	auipc	ra,0xffffb
    80005a2c:	b02080e7          	jalr	-1278(ra) # 8000052a <panic>
    release(&ftable.lock);
    80005a30:	0004a517          	auipc	a0,0x4a
    80005a34:	3e050513          	addi	a0,a0,992 # 8004fe10 <ftable>
    80005a38:	ffffb097          	auipc	ra,0xffffb
    80005a3c:	2ae080e7          	jalr	686(ra) # 80000ce6 <release>
  }
}
    80005a40:	70e2                	ld	ra,56(sp)
    80005a42:	7442                	ld	s0,48(sp)
    80005a44:	74a2                	ld	s1,40(sp)
    80005a46:	7902                	ld	s2,32(sp)
    80005a48:	69e2                	ld	s3,24(sp)
    80005a4a:	6a42                	ld	s4,16(sp)
    80005a4c:	6aa2                	ld	s5,8(sp)
    80005a4e:	6121                	addi	sp,sp,64
    80005a50:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005a52:	85d6                	mv	a1,s5
    80005a54:	8552                	mv	a0,s4
    80005a56:	00000097          	auipc	ra,0x0
    80005a5a:	34c080e7          	jalr	844(ra) # 80005da2 <pipeclose>
    80005a5e:	b7cd                	j	80005a40 <fileclose+0xa8>

0000000080005a60 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005a60:	715d                	addi	sp,sp,-80
    80005a62:	e486                	sd	ra,72(sp)
    80005a64:	e0a2                	sd	s0,64(sp)
    80005a66:	fc26                	sd	s1,56(sp)
    80005a68:	f84a                	sd	s2,48(sp)
    80005a6a:	f44e                	sd	s3,40(sp)
    80005a6c:	0880                	addi	s0,sp,80
    80005a6e:	84aa                	mv	s1,a0
    80005a70:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005a72:	ffffc097          	auipc	ra,0xffffc
    80005a76:	0d4080e7          	jalr	212(ra) # 80001b46 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005a7a:	409c                	lw	a5,0(s1)
    80005a7c:	37f9                	addiw	a5,a5,-2
    80005a7e:	4705                	li	a4,1
    80005a80:	04f76763          	bltu	a4,a5,80005ace <filestat+0x6e>
    80005a84:	892a                	mv	s2,a0
    ilock(f->ip);
    80005a86:	6c88                	ld	a0,24(s1)
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	070080e7          	jalr	112(ra) # 80004af8 <ilock>
    stati(f->ip, &st);
    80005a90:	fb840593          	addi	a1,s0,-72
    80005a94:	6c88                	ld	a0,24(s1)
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	2ec080e7          	jalr	748(ra) # 80004d82 <stati>
    iunlock(f->ip);
    80005a9e:	6c88                	ld	a0,24(s1)
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	11a080e7          	jalr	282(ra) # 80004bba <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005aa8:	46e1                	li	a3,24
    80005aaa:	fb840613          	addi	a2,s0,-72
    80005aae:	85ce                	mv	a1,s3
    80005ab0:	03893503          	ld	a0,56(s2)
    80005ab4:	ffffc097          	auipc	ra,0xffffc
    80005ab8:	c16080e7          	jalr	-1002(ra) # 800016ca <copyout>
    80005abc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005ac0:	60a6                	ld	ra,72(sp)
    80005ac2:	6406                	ld	s0,64(sp)
    80005ac4:	74e2                	ld	s1,56(sp)
    80005ac6:	7942                	ld	s2,48(sp)
    80005ac8:	79a2                	ld	s3,40(sp)
    80005aca:	6161                	addi	sp,sp,80
    80005acc:	8082                	ret
  return -1;
    80005ace:	557d                	li	a0,-1
    80005ad0:	bfc5                	j	80005ac0 <filestat+0x60>

0000000080005ad2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005ad2:	7179                	addi	sp,sp,-48
    80005ad4:	f406                	sd	ra,40(sp)
    80005ad6:	f022                	sd	s0,32(sp)
    80005ad8:	ec26                	sd	s1,24(sp)
    80005ada:	e84a                	sd	s2,16(sp)
    80005adc:	e44e                	sd	s3,8(sp)
    80005ade:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005ae0:	00854783          	lbu	a5,8(a0)
    80005ae4:	c3d5                	beqz	a5,80005b88 <fileread+0xb6>
    80005ae6:	84aa                	mv	s1,a0
    80005ae8:	89ae                	mv	s3,a1
    80005aea:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005aec:	411c                	lw	a5,0(a0)
    80005aee:	4705                	li	a4,1
    80005af0:	04e78963          	beq	a5,a4,80005b42 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005af4:	470d                	li	a4,3
    80005af6:	04e78d63          	beq	a5,a4,80005b50 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005afa:	4709                	li	a4,2
    80005afc:	06e79e63          	bne	a5,a4,80005b78 <fileread+0xa6>
    ilock(f->ip);
    80005b00:	6d08                	ld	a0,24(a0)
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	ff6080e7          	jalr	-10(ra) # 80004af8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005b0a:	874a                	mv	a4,s2
    80005b0c:	5094                	lw	a3,32(s1)
    80005b0e:	864e                	mv	a2,s3
    80005b10:	4585                	li	a1,1
    80005b12:	6c88                	ld	a0,24(s1)
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	298080e7          	jalr	664(ra) # 80004dac <readi>
    80005b1c:	892a                	mv	s2,a0
    80005b1e:	00a05563          	blez	a0,80005b28 <fileread+0x56>
      f->off += r;
    80005b22:	509c                	lw	a5,32(s1)
    80005b24:	9fa9                	addw	a5,a5,a0
    80005b26:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005b28:	6c88                	ld	a0,24(s1)
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	090080e7          	jalr	144(ra) # 80004bba <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005b32:	854a                	mv	a0,s2
    80005b34:	70a2                	ld	ra,40(sp)
    80005b36:	7402                	ld	s0,32(sp)
    80005b38:	64e2                	ld	s1,24(sp)
    80005b3a:	6942                	ld	s2,16(sp)
    80005b3c:	69a2                	ld	s3,8(sp)
    80005b3e:	6145                	addi	sp,sp,48
    80005b40:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005b42:	6908                	ld	a0,16(a0)
    80005b44:	00000097          	auipc	ra,0x0
    80005b48:	3c0080e7          	jalr	960(ra) # 80005f04 <piperead>
    80005b4c:	892a                	mv	s2,a0
    80005b4e:	b7d5                	j	80005b32 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005b50:	02451783          	lh	a5,36(a0)
    80005b54:	03079693          	slli	a3,a5,0x30
    80005b58:	92c1                	srli	a3,a3,0x30
    80005b5a:	4725                	li	a4,9
    80005b5c:	02d76863          	bltu	a4,a3,80005b8c <fileread+0xba>
    80005b60:	0792                	slli	a5,a5,0x4
    80005b62:	0004a717          	auipc	a4,0x4a
    80005b66:	20e70713          	addi	a4,a4,526 # 8004fd70 <devsw>
    80005b6a:	97ba                	add	a5,a5,a4
    80005b6c:	639c                	ld	a5,0(a5)
    80005b6e:	c38d                	beqz	a5,80005b90 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005b70:	4505                	li	a0,1
    80005b72:	9782                	jalr	a5
    80005b74:	892a                	mv	s2,a0
    80005b76:	bf75                	j	80005b32 <fileread+0x60>
    panic("fileread");
    80005b78:	00004517          	auipc	a0,0x4
    80005b7c:	bf050513          	addi	a0,a0,-1040 # 80009768 <syscalls+0x2b0>
    80005b80:	ffffb097          	auipc	ra,0xffffb
    80005b84:	9aa080e7          	jalr	-1622(ra) # 8000052a <panic>
    return -1;
    80005b88:	597d                	li	s2,-1
    80005b8a:	b765                	j	80005b32 <fileread+0x60>
      return -1;
    80005b8c:	597d                	li	s2,-1
    80005b8e:	b755                	j	80005b32 <fileread+0x60>
    80005b90:	597d                	li	s2,-1
    80005b92:	b745                	j	80005b32 <fileread+0x60>

0000000080005b94 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005b94:	715d                	addi	sp,sp,-80
    80005b96:	e486                	sd	ra,72(sp)
    80005b98:	e0a2                	sd	s0,64(sp)
    80005b9a:	fc26                	sd	s1,56(sp)
    80005b9c:	f84a                	sd	s2,48(sp)
    80005b9e:	f44e                	sd	s3,40(sp)
    80005ba0:	f052                	sd	s4,32(sp)
    80005ba2:	ec56                	sd	s5,24(sp)
    80005ba4:	e85a                	sd	s6,16(sp)
    80005ba6:	e45e                	sd	s7,8(sp)
    80005ba8:	e062                	sd	s8,0(sp)
    80005baa:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005bac:	00954783          	lbu	a5,9(a0)
    80005bb0:	10078663          	beqz	a5,80005cbc <filewrite+0x128>
    80005bb4:	892a                	mv	s2,a0
    80005bb6:	8aae                	mv	s5,a1
    80005bb8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005bba:	411c                	lw	a5,0(a0)
    80005bbc:	4705                	li	a4,1
    80005bbe:	02e78263          	beq	a5,a4,80005be2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005bc2:	470d                	li	a4,3
    80005bc4:	02e78663          	beq	a5,a4,80005bf0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005bc8:	4709                	li	a4,2
    80005bca:	0ee79163          	bne	a5,a4,80005cac <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005bce:	0ac05d63          	blez	a2,80005c88 <filewrite+0xf4>
    int i = 0;
    80005bd2:	4981                	li	s3,0
    80005bd4:	6b05                	lui	s6,0x1
    80005bd6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005bda:	6b85                	lui	s7,0x1
    80005bdc:	c00b8b9b          	addiw	s7,s7,-1024
    80005be0:	a861                	j	80005c78 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005be2:	6908                	ld	a0,16(a0)
    80005be4:	00000097          	auipc	ra,0x0
    80005be8:	22e080e7          	jalr	558(ra) # 80005e12 <pipewrite>
    80005bec:	8a2a                	mv	s4,a0
    80005bee:	a045                	j	80005c8e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005bf0:	02451783          	lh	a5,36(a0)
    80005bf4:	03079693          	slli	a3,a5,0x30
    80005bf8:	92c1                	srli	a3,a3,0x30
    80005bfa:	4725                	li	a4,9
    80005bfc:	0cd76263          	bltu	a4,a3,80005cc0 <filewrite+0x12c>
    80005c00:	0792                	slli	a5,a5,0x4
    80005c02:	0004a717          	auipc	a4,0x4a
    80005c06:	16e70713          	addi	a4,a4,366 # 8004fd70 <devsw>
    80005c0a:	97ba                	add	a5,a5,a4
    80005c0c:	679c                	ld	a5,8(a5)
    80005c0e:	cbdd                	beqz	a5,80005cc4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005c10:	4505                	li	a0,1
    80005c12:	9782                	jalr	a5
    80005c14:	8a2a                	mv	s4,a0
    80005c16:	a8a5                	j	80005c8e <filewrite+0xfa>
    80005c18:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005c1c:	00000097          	auipc	ra,0x0
    80005c20:	8b0080e7          	jalr	-1872(ra) # 800054cc <begin_op>
      ilock(f->ip);
    80005c24:	01893503          	ld	a0,24(s2)
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	ed0080e7          	jalr	-304(ra) # 80004af8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005c30:	8762                	mv	a4,s8
    80005c32:	02092683          	lw	a3,32(s2)
    80005c36:	01598633          	add	a2,s3,s5
    80005c3a:	4585                	li	a1,1
    80005c3c:	01893503          	ld	a0,24(s2)
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	264080e7          	jalr	612(ra) # 80004ea4 <writei>
    80005c48:	84aa                	mv	s1,a0
    80005c4a:	00a05763          	blez	a0,80005c58 <filewrite+0xc4>
        f->off += r;
    80005c4e:	02092783          	lw	a5,32(s2)
    80005c52:	9fa9                	addw	a5,a5,a0
    80005c54:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005c58:	01893503          	ld	a0,24(s2)
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	f5e080e7          	jalr	-162(ra) # 80004bba <iunlock>
      end_op();
    80005c64:	00000097          	auipc	ra,0x0
    80005c68:	8e8080e7          	jalr	-1816(ra) # 8000554c <end_op>

      if(r != n1){
    80005c6c:	009c1f63          	bne	s8,s1,80005c8a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005c70:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005c74:	0149db63          	bge	s3,s4,80005c8a <filewrite+0xf6>
      int n1 = n - i;
    80005c78:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005c7c:	84be                	mv	s1,a5
    80005c7e:	2781                	sext.w	a5,a5
    80005c80:	f8fb5ce3          	bge	s6,a5,80005c18 <filewrite+0x84>
    80005c84:	84de                	mv	s1,s7
    80005c86:	bf49                	j	80005c18 <filewrite+0x84>
    int i = 0;
    80005c88:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005c8a:	013a1f63          	bne	s4,s3,80005ca8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005c8e:	8552                	mv	a0,s4
    80005c90:	60a6                	ld	ra,72(sp)
    80005c92:	6406                	ld	s0,64(sp)
    80005c94:	74e2                	ld	s1,56(sp)
    80005c96:	7942                	ld	s2,48(sp)
    80005c98:	79a2                	ld	s3,40(sp)
    80005c9a:	7a02                	ld	s4,32(sp)
    80005c9c:	6ae2                	ld	s5,24(sp)
    80005c9e:	6b42                	ld	s6,16(sp)
    80005ca0:	6ba2                	ld	s7,8(sp)
    80005ca2:	6c02                	ld	s8,0(sp)
    80005ca4:	6161                	addi	sp,sp,80
    80005ca6:	8082                	ret
    ret = (i == n ? n : -1);
    80005ca8:	5a7d                	li	s4,-1
    80005caa:	b7d5                	j	80005c8e <filewrite+0xfa>
    panic("filewrite");
    80005cac:	00004517          	auipc	a0,0x4
    80005cb0:	acc50513          	addi	a0,a0,-1332 # 80009778 <syscalls+0x2c0>
    80005cb4:	ffffb097          	auipc	ra,0xffffb
    80005cb8:	876080e7          	jalr	-1930(ra) # 8000052a <panic>
    return -1;
    80005cbc:	5a7d                	li	s4,-1
    80005cbe:	bfc1                	j	80005c8e <filewrite+0xfa>
      return -1;
    80005cc0:	5a7d                	li	s4,-1
    80005cc2:	b7f1                	j	80005c8e <filewrite+0xfa>
    80005cc4:	5a7d                	li	s4,-1
    80005cc6:	b7e1                	j	80005c8e <filewrite+0xfa>

0000000080005cc8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005cc8:	7179                	addi	sp,sp,-48
    80005cca:	f406                	sd	ra,40(sp)
    80005ccc:	f022                	sd	s0,32(sp)
    80005cce:	ec26                	sd	s1,24(sp)
    80005cd0:	e84a                	sd	s2,16(sp)
    80005cd2:	e44e                	sd	s3,8(sp)
    80005cd4:	e052                	sd	s4,0(sp)
    80005cd6:	1800                	addi	s0,sp,48
    80005cd8:	84aa                	mv	s1,a0
    80005cda:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005cdc:	0005b023          	sd	zero,0(a1)
    80005ce0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005ce4:	00000097          	auipc	ra,0x0
    80005ce8:	bf8080e7          	jalr	-1032(ra) # 800058dc <filealloc>
    80005cec:	e088                	sd	a0,0(s1)
    80005cee:	c551                	beqz	a0,80005d7a <pipealloc+0xb2>
    80005cf0:	00000097          	auipc	ra,0x0
    80005cf4:	bec080e7          	jalr	-1044(ra) # 800058dc <filealloc>
    80005cf8:	00aa3023          	sd	a0,0(s4)
    80005cfc:	c92d                	beqz	a0,80005d6e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005cfe:	ffffb097          	auipc	ra,0xffffb
    80005d02:	df4080e7          	jalr	-524(ra) # 80000af2 <kalloc>
    80005d06:	892a                	mv	s2,a0
    80005d08:	c125                	beqz	a0,80005d68 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005d0a:	4985                	li	s3,1
    80005d0c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005d10:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005d14:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005d18:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005d1c:	00004597          	auipc	a1,0x4
    80005d20:	a6c58593          	addi	a1,a1,-1428 # 80009788 <syscalls+0x2d0>
    80005d24:	ffffb097          	auipc	ra,0xffffb
    80005d28:	e2e080e7          	jalr	-466(ra) # 80000b52 <initlock>
  (*f0)->type = FD_PIPE;
    80005d2c:	609c                	ld	a5,0(s1)
    80005d2e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005d32:	609c                	ld	a5,0(s1)
    80005d34:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005d38:	609c                	ld	a5,0(s1)
    80005d3a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005d3e:	609c                	ld	a5,0(s1)
    80005d40:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005d44:	000a3783          	ld	a5,0(s4)
    80005d48:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005d4c:	000a3783          	ld	a5,0(s4)
    80005d50:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005d54:	000a3783          	ld	a5,0(s4)
    80005d58:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005d5c:	000a3783          	ld	a5,0(s4)
    80005d60:	0127b823          	sd	s2,16(a5)
  return 0;
    80005d64:	4501                	li	a0,0
    80005d66:	a025                	j	80005d8e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005d68:	6088                	ld	a0,0(s1)
    80005d6a:	e501                	bnez	a0,80005d72 <pipealloc+0xaa>
    80005d6c:	a039                	j	80005d7a <pipealloc+0xb2>
    80005d6e:	6088                	ld	a0,0(s1)
    80005d70:	c51d                	beqz	a0,80005d9e <pipealloc+0xd6>
    fileclose(*f0);
    80005d72:	00000097          	auipc	ra,0x0
    80005d76:	c26080e7          	jalr	-986(ra) # 80005998 <fileclose>
  if(*f1)
    80005d7a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005d7e:	557d                	li	a0,-1
  if(*f1)
    80005d80:	c799                	beqz	a5,80005d8e <pipealloc+0xc6>
    fileclose(*f1);
    80005d82:	853e                	mv	a0,a5
    80005d84:	00000097          	auipc	ra,0x0
    80005d88:	c14080e7          	jalr	-1004(ra) # 80005998 <fileclose>
  return -1;
    80005d8c:	557d                	li	a0,-1
}
    80005d8e:	70a2                	ld	ra,40(sp)
    80005d90:	7402                	ld	s0,32(sp)
    80005d92:	64e2                	ld	s1,24(sp)
    80005d94:	6942                	ld	s2,16(sp)
    80005d96:	69a2                	ld	s3,8(sp)
    80005d98:	6a02                	ld	s4,0(sp)
    80005d9a:	6145                	addi	sp,sp,48
    80005d9c:	8082                	ret
  return -1;
    80005d9e:	557d                	li	a0,-1
    80005da0:	b7fd                	j	80005d8e <pipealloc+0xc6>

0000000080005da2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005da2:	1101                	addi	sp,sp,-32
    80005da4:	ec06                	sd	ra,24(sp)
    80005da6:	e822                	sd	s0,16(sp)
    80005da8:	e426                	sd	s1,8(sp)
    80005daa:	e04a                	sd	s2,0(sp)
    80005dac:	1000                	addi	s0,sp,32
    80005dae:	84aa                	mv	s1,a0
    80005db0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005db2:	ffffb097          	auipc	ra,0xffffb
    80005db6:	e80080e7          	jalr	-384(ra) # 80000c32 <acquire>
  if(writable){
    80005dba:	02090d63          	beqz	s2,80005df4 <pipeclose+0x52>
    pi->writeopen = 0;
    80005dbe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005dc2:	21848513          	addi	a0,s1,536
    80005dc6:	ffffd097          	auipc	ra,0xffffd
    80005dca:	c72080e7          	jalr	-910(ra) # 80002a38 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005dce:	2204b783          	ld	a5,544(s1)
    80005dd2:	eb95                	bnez	a5,80005e06 <pipeclose+0x64>
    release(&pi->lock);
    80005dd4:	8526                	mv	a0,s1
    80005dd6:	ffffb097          	auipc	ra,0xffffb
    80005dda:	f10080e7          	jalr	-240(ra) # 80000ce6 <release>
    kfree((char*)pi);
    80005dde:	8526                	mv	a0,s1
    80005de0:	ffffb097          	auipc	ra,0xffffb
    80005de4:	bf6080e7          	jalr	-1034(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005de8:	60e2                	ld	ra,24(sp)
    80005dea:	6442                	ld	s0,16(sp)
    80005dec:	64a2                	ld	s1,8(sp)
    80005dee:	6902                	ld	s2,0(sp)
    80005df0:	6105                	addi	sp,sp,32
    80005df2:	8082                	ret
    pi->readopen = 0;
    80005df4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005df8:	21c48513          	addi	a0,s1,540
    80005dfc:	ffffd097          	auipc	ra,0xffffd
    80005e00:	c3c080e7          	jalr	-964(ra) # 80002a38 <wakeup>
    80005e04:	b7e9                	j	80005dce <pipeclose+0x2c>
    release(&pi->lock);
    80005e06:	8526                	mv	a0,s1
    80005e08:	ffffb097          	auipc	ra,0xffffb
    80005e0c:	ede080e7          	jalr	-290(ra) # 80000ce6 <release>
}
    80005e10:	bfe1                	j	80005de8 <pipeclose+0x46>

0000000080005e12 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005e12:	711d                	addi	sp,sp,-96
    80005e14:	ec86                	sd	ra,88(sp)
    80005e16:	e8a2                	sd	s0,80(sp)
    80005e18:	e4a6                	sd	s1,72(sp)
    80005e1a:	e0ca                	sd	s2,64(sp)
    80005e1c:	fc4e                	sd	s3,56(sp)
    80005e1e:	f852                	sd	s4,48(sp)
    80005e20:	f456                	sd	s5,40(sp)
    80005e22:	f05a                	sd	s6,32(sp)
    80005e24:	ec5e                	sd	s7,24(sp)
    80005e26:	e862                	sd	s8,16(sp)
    80005e28:	1080                	addi	s0,sp,96
    80005e2a:	84aa                	mv	s1,a0
    80005e2c:	8aae                	mv	s5,a1
    80005e2e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005e30:	ffffc097          	auipc	ra,0xffffc
    80005e34:	d16080e7          	jalr	-746(ra) # 80001b46 <myproc>
    80005e38:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005e3a:	8526                	mv	a0,s1
    80005e3c:	ffffb097          	auipc	ra,0xffffb
    80005e40:	df6080e7          	jalr	-522(ra) # 80000c32 <acquire>
  while(i < n){
    80005e44:	0b405363          	blez	s4,80005eea <pipewrite+0xd8>
  int i = 0;
    80005e48:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005e4a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005e4c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005e50:	21c48b93          	addi	s7,s1,540
    80005e54:	a089                	j	80005e96 <pipewrite+0x84>
      release(&pi->lock);
    80005e56:	8526                	mv	a0,s1
    80005e58:	ffffb097          	auipc	ra,0xffffb
    80005e5c:	e8e080e7          	jalr	-370(ra) # 80000ce6 <release>
      return -1;
    80005e60:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005e62:	854a                	mv	a0,s2
    80005e64:	60e6                	ld	ra,88(sp)
    80005e66:	6446                	ld	s0,80(sp)
    80005e68:	64a6                	ld	s1,72(sp)
    80005e6a:	6906                	ld	s2,64(sp)
    80005e6c:	79e2                	ld	s3,56(sp)
    80005e6e:	7a42                	ld	s4,48(sp)
    80005e70:	7aa2                	ld	s5,40(sp)
    80005e72:	7b02                	ld	s6,32(sp)
    80005e74:	6be2                	ld	s7,24(sp)
    80005e76:	6c42                	ld	s8,16(sp)
    80005e78:	6125                	addi	sp,sp,96
    80005e7a:	8082                	ret
      wakeup(&pi->nread);
    80005e7c:	8562                	mv	a0,s8
    80005e7e:	ffffd097          	auipc	ra,0xffffd
    80005e82:	bba080e7          	jalr	-1094(ra) # 80002a38 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005e86:	85a6                	mv	a1,s1
    80005e88:	855e                	mv	a0,s7
    80005e8a:	ffffd097          	auipc	ra,0xffffd
    80005e8e:	a18080e7          	jalr	-1512(ra) # 800028a2 <sleep>
  while(i < n){
    80005e92:	05495d63          	bge	s2,s4,80005eec <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005e96:	2204a783          	lw	a5,544(s1)
    80005e9a:	dfd5                	beqz	a5,80005e56 <pipewrite+0x44>
    80005e9c:	01c9a783          	lw	a5,28(s3)
    80005ea0:	fbdd                	bnez	a5,80005e56 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005ea2:	2184a783          	lw	a5,536(s1)
    80005ea6:	21c4a703          	lw	a4,540(s1)
    80005eaa:	2007879b          	addiw	a5,a5,512
    80005eae:	fcf707e3          	beq	a4,a5,80005e7c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005eb2:	4685                	li	a3,1
    80005eb4:	01590633          	add	a2,s2,s5
    80005eb8:	faf40593          	addi	a1,s0,-81
    80005ebc:	0389b503          	ld	a0,56(s3)
    80005ec0:	ffffc097          	auipc	ra,0xffffc
    80005ec4:	896080e7          	jalr	-1898(ra) # 80001756 <copyin>
    80005ec8:	03650263          	beq	a0,s6,80005eec <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005ecc:	21c4a783          	lw	a5,540(s1)
    80005ed0:	0017871b          	addiw	a4,a5,1
    80005ed4:	20e4ae23          	sw	a4,540(s1)
    80005ed8:	1ff7f793          	andi	a5,a5,511
    80005edc:	97a6                	add	a5,a5,s1
    80005ede:	faf44703          	lbu	a4,-81(s0)
    80005ee2:	00e78c23          	sb	a4,24(a5)
      i++;
    80005ee6:	2905                	addiw	s2,s2,1
    80005ee8:	b76d                	j	80005e92 <pipewrite+0x80>
  int i = 0;
    80005eea:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005eec:	21848513          	addi	a0,s1,536
    80005ef0:	ffffd097          	auipc	ra,0xffffd
    80005ef4:	b48080e7          	jalr	-1208(ra) # 80002a38 <wakeup>
  release(&pi->lock);
    80005ef8:	8526                	mv	a0,s1
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	dec080e7          	jalr	-532(ra) # 80000ce6 <release>
  return i;
    80005f02:	b785                	j	80005e62 <pipewrite+0x50>

0000000080005f04 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005f04:	715d                	addi	sp,sp,-80
    80005f06:	e486                	sd	ra,72(sp)
    80005f08:	e0a2                	sd	s0,64(sp)
    80005f0a:	fc26                	sd	s1,56(sp)
    80005f0c:	f84a                	sd	s2,48(sp)
    80005f0e:	f44e                	sd	s3,40(sp)
    80005f10:	f052                	sd	s4,32(sp)
    80005f12:	ec56                	sd	s5,24(sp)
    80005f14:	e85a                	sd	s6,16(sp)
    80005f16:	0880                	addi	s0,sp,80
    80005f18:	84aa                	mv	s1,a0
    80005f1a:	892e                	mv	s2,a1
    80005f1c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005f1e:	ffffc097          	auipc	ra,0xffffc
    80005f22:	c28080e7          	jalr	-984(ra) # 80001b46 <myproc>
    80005f26:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005f28:	8526                	mv	a0,s1
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	d08080e7          	jalr	-760(ra) # 80000c32 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f32:	2184a703          	lw	a4,536(s1)
    80005f36:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005f3a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f3e:	02f71463          	bne	a4,a5,80005f66 <piperead+0x62>
    80005f42:	2244a783          	lw	a5,548(s1)
    80005f46:	c385                	beqz	a5,80005f66 <piperead+0x62>
    if(pr->killed){
    80005f48:	01ca2783          	lw	a5,28(s4)
    80005f4c:	ebc1                	bnez	a5,80005fdc <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005f4e:	85a6                	mv	a1,s1
    80005f50:	854e                	mv	a0,s3
    80005f52:	ffffd097          	auipc	ra,0xffffd
    80005f56:	950080e7          	jalr	-1712(ra) # 800028a2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005f5a:	2184a703          	lw	a4,536(s1)
    80005f5e:	21c4a783          	lw	a5,540(s1)
    80005f62:	fef700e3          	beq	a4,a5,80005f42 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005f66:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005f68:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005f6a:	05505363          	blez	s5,80005fb0 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005f6e:	2184a783          	lw	a5,536(s1)
    80005f72:	21c4a703          	lw	a4,540(s1)
    80005f76:	02f70d63          	beq	a4,a5,80005fb0 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005f7a:	0017871b          	addiw	a4,a5,1
    80005f7e:	20e4ac23          	sw	a4,536(s1)
    80005f82:	1ff7f793          	andi	a5,a5,511
    80005f86:	97a6                	add	a5,a5,s1
    80005f88:	0187c783          	lbu	a5,24(a5)
    80005f8c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005f90:	4685                	li	a3,1
    80005f92:	fbf40613          	addi	a2,s0,-65
    80005f96:	85ca                	mv	a1,s2
    80005f98:	038a3503          	ld	a0,56(s4)
    80005f9c:	ffffb097          	auipc	ra,0xffffb
    80005fa0:	72e080e7          	jalr	1838(ra) # 800016ca <copyout>
    80005fa4:	01650663          	beq	a0,s6,80005fb0 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005fa8:	2985                	addiw	s3,s3,1
    80005faa:	0905                	addi	s2,s2,1
    80005fac:	fd3a91e3          	bne	s5,s3,80005f6e <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005fb0:	21c48513          	addi	a0,s1,540
    80005fb4:	ffffd097          	auipc	ra,0xffffd
    80005fb8:	a84080e7          	jalr	-1404(ra) # 80002a38 <wakeup>
  release(&pi->lock);
    80005fbc:	8526                	mv	a0,s1
    80005fbe:	ffffb097          	auipc	ra,0xffffb
    80005fc2:	d28080e7          	jalr	-728(ra) # 80000ce6 <release>
  return i;
}
    80005fc6:	854e                	mv	a0,s3
    80005fc8:	60a6                	ld	ra,72(sp)
    80005fca:	6406                	ld	s0,64(sp)
    80005fcc:	74e2                	ld	s1,56(sp)
    80005fce:	7942                	ld	s2,48(sp)
    80005fd0:	79a2                	ld	s3,40(sp)
    80005fd2:	7a02                	ld	s4,32(sp)
    80005fd4:	6ae2                	ld	s5,24(sp)
    80005fd6:	6b42                	ld	s6,16(sp)
    80005fd8:	6161                	addi	sp,sp,80
    80005fda:	8082                	ret
      release(&pi->lock);
    80005fdc:	8526                	mv	a0,s1
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	d08080e7          	jalr	-760(ra) # 80000ce6 <release>
      return -1;
    80005fe6:	59fd                	li	s3,-1
    80005fe8:	bff9                	j	80005fc6 <piperead+0xc2>

0000000080005fea <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);
struct sigaction defaultSigActionExec;
int
exec(char *path, char **argv)
{
    80005fea:	de010113          	addi	sp,sp,-544
    80005fee:	20113c23          	sd	ra,536(sp)
    80005ff2:	20813823          	sd	s0,528(sp)
    80005ff6:	20913423          	sd	s1,520(sp)
    80005ffa:	21213023          	sd	s2,512(sp)
    80005ffe:	ffce                	sd	s3,504(sp)
    80006000:	fbd2                	sd	s4,496(sp)
    80006002:	f7d6                	sd	s5,488(sp)
    80006004:	f3da                	sd	s6,480(sp)
    80006006:	efde                	sd	s7,472(sp)
    80006008:	ebe2                	sd	s8,464(sp)
    8000600a:	e7e6                	sd	s9,456(sp)
    8000600c:	e3ea                	sd	s10,448(sp)
    8000600e:	ff6e                	sd	s11,440(sp)
    80006010:	1400                	addi	s0,sp,544
    80006012:	892a                	mv	s2,a0
    80006014:	dea43423          	sd	a0,-536(s0)
    80006018:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000601c:	ffffc097          	auipc	ra,0xffffc
    80006020:	b2a080e7          	jalr	-1238(ra) # 80001b46 <myproc>
    80006024:	84aa                	mv	s1,a0

  begin_op();
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	4a6080e7          	jalr	1190(ra) # 800054cc <begin_op>

  if((ip = namei(path)) == 0){
    8000602e:	854a                	mv	a0,s2
    80006030:	fffff097          	auipc	ra,0xfffff
    80006034:	27c080e7          	jalr	636(ra) # 800052ac <namei>
    80006038:	c93d                	beqz	a0,800060ae <exec+0xc4>
    8000603a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000603c:	fffff097          	auipc	ra,0xfffff
    80006040:	abc080e7          	jalr	-1348(ra) # 80004af8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80006044:	04000713          	li	a4,64
    80006048:	4681                	li	a3,0
    8000604a:	e4840613          	addi	a2,s0,-440
    8000604e:	4581                	li	a1,0
    80006050:	8556                	mv	a0,s5
    80006052:	fffff097          	auipc	ra,0xfffff
    80006056:	d5a080e7          	jalr	-678(ra) # 80004dac <readi>
    8000605a:	04000793          	li	a5,64
    8000605e:	00f51a63          	bne	a0,a5,80006072 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80006062:	e4842703          	lw	a4,-440(s0)
    80006066:	464c47b7          	lui	a5,0x464c4
    8000606a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000606e:	04f70663          	beq	a4,a5,800060ba <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80006072:	8556                	mv	a0,s5
    80006074:	fffff097          	auipc	ra,0xfffff
    80006078:	ce6080e7          	jalr	-794(ra) # 80004d5a <iunlockput>
    end_op();
    8000607c:	fffff097          	auipc	ra,0xfffff
    80006080:	4d0080e7          	jalr	1232(ra) # 8000554c <end_op>
  }
  return -1;
    80006084:	557d                	li	a0,-1
}
    80006086:	21813083          	ld	ra,536(sp)
    8000608a:	21013403          	ld	s0,528(sp)
    8000608e:	20813483          	ld	s1,520(sp)
    80006092:	20013903          	ld	s2,512(sp)
    80006096:	79fe                	ld	s3,504(sp)
    80006098:	7a5e                	ld	s4,496(sp)
    8000609a:	7abe                	ld	s5,488(sp)
    8000609c:	7b1e                	ld	s6,480(sp)
    8000609e:	6bfe                	ld	s7,472(sp)
    800060a0:	6c5e                	ld	s8,464(sp)
    800060a2:	6cbe                	ld	s9,456(sp)
    800060a4:	6d1e                	ld	s10,448(sp)
    800060a6:	7dfa                	ld	s11,440(sp)
    800060a8:	22010113          	addi	sp,sp,544
    800060ac:	8082                	ret
    end_op();
    800060ae:	fffff097          	auipc	ra,0xfffff
    800060b2:	49e080e7          	jalr	1182(ra) # 8000554c <end_op>
    return -1;
    800060b6:	557d                	li	a0,-1
    800060b8:	b7f9                	j	80006086 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800060ba:	8526                	mv	a0,s1
    800060bc:	ffffc097          	auipc	ra,0xffffc
    800060c0:	bc8080e7          	jalr	-1080(ra) # 80001c84 <proc_pagetable>
    800060c4:	8b2a                	mv	s6,a0
    800060c6:	d555                	beqz	a0,80006072 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800060c8:	e6842783          	lw	a5,-408(s0)
    800060cc:	e8045703          	lhu	a4,-384(s0)
    800060d0:	c735                	beqz	a4,8000613c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800060d2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800060d4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800060d8:	6a05                	lui	s4,0x1
    800060da:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800060de:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800060e2:	6d85                	lui	s11,0x1
    800060e4:	7d7d                	lui	s10,0xfffff
    800060e6:	a449                	j	80006368 <exec+0x37e>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800060e8:	00003517          	auipc	a0,0x3
    800060ec:	6a850513          	addi	a0,a0,1704 # 80009790 <syscalls+0x2d8>
    800060f0:	ffffa097          	auipc	ra,0xffffa
    800060f4:	43a080e7          	jalr	1082(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800060f8:	874a                	mv	a4,s2
    800060fa:	009c86bb          	addw	a3,s9,s1
    800060fe:	4581                	li	a1,0
    80006100:	8556                	mv	a0,s5
    80006102:	fffff097          	auipc	ra,0xfffff
    80006106:	caa080e7          	jalr	-854(ra) # 80004dac <readi>
    8000610a:	2501                	sext.w	a0,a0
    8000610c:	1ea91e63          	bne	s2,a0,80006308 <exec+0x31e>
  for(i = 0; i < sz; i += PGSIZE){
    80006110:	009d84bb          	addw	s1,s11,s1
    80006114:	013d09bb          	addw	s3,s10,s3
    80006118:	2374f863          	bgeu	s1,s7,80006348 <exec+0x35e>
    pa = walkaddr(pagetable, va + i);
    8000611c:	02049593          	slli	a1,s1,0x20
    80006120:	9181                	srli	a1,a1,0x20
    80006122:	95e2                	add	a1,a1,s8
    80006124:	855a                	mv	a0,s6
    80006126:	ffffb097          	auipc	ra,0xffffb
    8000612a:	fb2080e7          	jalr	-78(ra) # 800010d8 <walkaddr>
    8000612e:	862a                	mv	a2,a0
    if(pa == 0)
    80006130:	dd45                	beqz	a0,800060e8 <exec+0xfe>
      n = PGSIZE;
    80006132:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80006134:	fd49f2e3          	bgeu	s3,s4,800060f8 <exec+0x10e>
      n = sz - i;
    80006138:	894e                	mv	s2,s3
    8000613a:	bf7d                	j	800060f8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000613c:	4481                	li	s1,0
  iunlockput(ip);
    8000613e:	8556                	mv	a0,s5
    80006140:	fffff097          	auipc	ra,0xfffff
    80006144:	c1a080e7          	jalr	-998(ra) # 80004d5a <iunlockput>
  end_op();
    80006148:	fffff097          	auipc	ra,0xfffff
    8000614c:	404080e7          	jalr	1028(ra) # 8000554c <end_op>
  p = myproc();
    80006150:	ffffc097          	auipc	ra,0xffffc
    80006154:	9f6080e7          	jalr	-1546(ra) # 80001b46 <myproc>
    80006158:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000615a:	03053d03          	ld	s10,48(a0)
  sz = PGROUNDUP(sz);
    8000615e:	6785                	lui	a5,0x1
    80006160:	17fd                	addi	a5,a5,-1
    80006162:	94be                	add	s1,s1,a5
    80006164:	77fd                	lui	a5,0xfffff
    80006166:	8fe5                	and	a5,a5,s1
    80006168:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000616c:	6609                	lui	a2,0x2
    8000616e:	963e                	add	a2,a2,a5
    80006170:	85be                	mv	a1,a5
    80006172:	855a                	mv	a0,s6
    80006174:	ffffb097          	auipc	ra,0xffffb
    80006178:	306080e7          	jalr	774(ra) # 8000147a <uvmalloc>
    8000617c:	8c2a                	mv	s8,a0
  ip = 0;
    8000617e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80006180:	18050463          	beqz	a0,80006308 <exec+0x31e>
  uvmclear(pagetable, sz-2*PGSIZE);
    80006184:	75f9                	lui	a1,0xffffe
    80006186:	95aa                	add	a1,a1,a0
    80006188:	855a                	mv	a0,s6
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	50e080e7          	jalr	1294(ra) # 80001698 <uvmclear>
  stackbase = sp - PGSIZE;
    80006192:	7afd                	lui	s5,0xfffff
    80006194:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80006196:	df043783          	ld	a5,-528(s0)
    8000619a:	6388                	ld	a0,0(a5)
    8000619c:	c925                	beqz	a0,8000620c <exec+0x222>
    8000619e:	e8840993          	addi	s3,s0,-376
    800061a2:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800061a6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800061a8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800061aa:	ffffb097          	auipc	ra,0xffffb
    800061ae:	d24080e7          	jalr	-732(ra) # 80000ece <strlen>
    800061b2:	0015079b          	addiw	a5,a0,1
    800061b6:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800061ba:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800061be:	17596963          	bltu	s2,s5,80006330 <exec+0x346>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800061c2:	df043d83          	ld	s11,-528(s0)
    800061c6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800061ca:	8552                	mv	a0,s4
    800061cc:	ffffb097          	auipc	ra,0xffffb
    800061d0:	d02080e7          	jalr	-766(ra) # 80000ece <strlen>
    800061d4:	0015069b          	addiw	a3,a0,1
    800061d8:	8652                	mv	a2,s4
    800061da:	85ca                	mv	a1,s2
    800061dc:	855a                	mv	a0,s6
    800061de:	ffffb097          	auipc	ra,0xffffb
    800061e2:	4ec080e7          	jalr	1260(ra) # 800016ca <copyout>
    800061e6:	14054963          	bltz	a0,80006338 <exec+0x34e>
    ustack[argc] = sp;
    800061ea:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800061ee:	0485                	addi	s1,s1,1
    800061f0:	008d8793          	addi	a5,s11,8
    800061f4:	def43823          	sd	a5,-528(s0)
    800061f8:	008db503          	ld	a0,8(s11)
    800061fc:	c911                	beqz	a0,80006210 <exec+0x226>
    if(argc >= MAXARG)
    800061fe:	09a1                	addi	s3,s3,8
    80006200:	fb9995e3          	bne	s3,s9,800061aa <exec+0x1c0>
  sz = sz1;
    80006204:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80006208:	4a81                	li	s5,0
    8000620a:	a8fd                	j	80006308 <exec+0x31e>
  sp = sz;
    8000620c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000620e:	4481                	li	s1,0
  ustack[argc] = 0;
    80006210:	00349793          	slli	a5,s1,0x3
    80006214:	f9040713          	addi	a4,s0,-112
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffaaef8>
  sp -= (argc+1) * sizeof(uint64);
    8000621e:	00148693          	addi	a3,s1,1
    80006222:	068e                	slli	a3,a3,0x3
    80006224:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80006228:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000622c:	01597663          	bgeu	s2,s5,80006238 <exec+0x24e>
  sz = sz1;
    80006230:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80006234:	4a81                	li	s5,0
    80006236:	a8c9                	j	80006308 <exec+0x31e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80006238:	e8840613          	addi	a2,s0,-376
    8000623c:	85ca                	mv	a1,s2
    8000623e:	855a                	mv	a0,s6
    80006240:	ffffb097          	auipc	ra,0xffffb
    80006244:	48a080e7          	jalr	1162(ra) # 800016ca <copyout>
    80006248:	0e054c63          	bltz	a0,80006340 <exec+0x356>
  p->headThreadTrapframe->a1 = sp;
    8000624c:	040bb783          	ld	a5,64(s7) # 1040 <_entry-0x7fffefc0>
    80006250:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80006254:	de843783          	ld	a5,-536(s0)
    80006258:	0007c703          	lbu	a4,0(a5)
    8000625c:	cf11                	beqz	a4,80006278 <exec+0x28e>
    8000625e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80006260:	02f00693          	li	a3,47
    80006264:	a039                	j	80006272 <exec+0x288>
      last = s+1;
    80006266:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000626a:	0785                	addi	a5,a5,1
    8000626c:	fff7c703          	lbu	a4,-1(a5)
    80006270:	c701                	beqz	a4,80006278 <exec+0x28e>
    if(*s == '/')
    80006272:	fed71ce3          	bne	a4,a3,8000626a <exec+0x280>
    80006276:	bfc5                	j	80006266 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80006278:	4641                	li	a2,16
    8000627a:	de843583          	ld	a1,-536(s0)
    8000627e:	0d0b8513          	addi	a0,s7,208
    80006282:	ffffb097          	auipc	ra,0xffffb
    80006286:	c1a080e7          	jalr	-998(ra) # 80000e9c <safestrcpy>
  oldpagetable = p->pagetable;
    8000628a:	038bb503          	ld	a0,56(s7)
  p->pagetable = pagetable;
    8000628e:	036bbc23          	sd	s6,56(s7)
  p->sz = sz;
    80006292:	038bb823          	sd	s8,48(s7)
  p->headThreadTrapframe->epc = elf.entry;  // initial program counter = main
    80006296:	040bb783          	ld	a5,64(s7)
    8000629a:	e6043703          	ld	a4,-416(s0)
    8000629e:	ef98                	sd	a4,24(a5)
  p->headThreadTrapframe->sp = sp; // initial stack pointer
    800062a0:	040bb783          	ld	a5,64(s7)
    800062a4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800062a8:	85ea                	mv	a1,s10
    800062aa:	ffffc097          	auipc	ra,0xffffc
    800062ae:	a76080e7          	jalr	-1418(ra) # 80001d20 <proc_freepagetable>
  for (int i = 0; i < 32; i++)
    800062b2:	3f0b8793          	addi	a5,s7,1008
    800062b6:	1f0b8713          	addi	a4,s7,496
    800062ba:	0f0b8693          	addi	a3,s7,240
    800062be:	470b8b93          	addi	s7,s7,1136
      if(p->Sigactions[i].sa_handler==(void*)SIG_DFL || p->Sigactions[i].sa_handler==(void*)SIG_IGN)
    800062c2:	4585                	li	a1,1
    800062c4:	a829                	j	800062de <exec+0x2f4>
    800062c6:	6310                	ld	a2,0(a4)
    800062c8:	00c5f663          	bgeu	a1,a2,800062d4 <exec+0x2ea>
        p->Sigactions[i].sa_handler=SIG_DFL;
    800062cc:	00073023          	sd	zero,0(a4)
        p->Sigactions[i].sigmask=0;
    800062d0:	00072423          	sw	zero,8(a4)
  for (int i = 0; i < 32; i++)
    800062d4:	0791                	addi	a5,a5,4
    800062d6:	0741                	addi	a4,a4,16
    800062d8:	06a1                	addi	a3,a3,8
    800062da:	02fb8263          	beq	s7,a5,800062fe <exec+0x314>
    if(p->IsSigactionPointer[i])
    800062de:	4390                	lw	a2,0(a5)
    800062e0:	d27d                	beqz	a2,800062c6 <exec+0x2dc>
      struct sigaction* ptr=(struct sigaction*)p->SignalHandlers[i];
    800062e2:	6290                	ld	a2,0(a3)
      if(ptr->sa_handler==(void*)SIG_DFL || ptr->sa_handler==(void*)SIG_IGN)
    800062e4:	00063803          	ld	a6,0(a2) # 2000 <_entry-0x7fffe000>
    800062e8:	ff05f6e3          	bgeu	a1,a6,800062d4 <exec+0x2ea>
        ptr->sa_handler=SIG_DFL;
    800062ec:	00063023          	sd	zero,0(a2)
        p->IsSigactionPointer[i]=0;
    800062f0:	0007a023          	sw	zero,0(a5)
        p->Sigactions[i].sa_handler=SIG_DFL;
    800062f4:	00073023          	sd	zero,0(a4)
        p->Sigactions[i].sigmask=0;
    800062f8:	00072423          	sw	zero,8(a4)
    800062fc:	bfe1                	j	800062d4 <exec+0x2ea>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800062fe:	0004851b          	sext.w	a0,s1
    80006302:	b351                	j	80006086 <exec+0x9c>
    80006304:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80006308:	df843583          	ld	a1,-520(s0)
    8000630c:	855a                	mv	a0,s6
    8000630e:	ffffc097          	auipc	ra,0xffffc
    80006312:	a12080e7          	jalr	-1518(ra) # 80001d20 <proc_freepagetable>
  if(ip){
    80006316:	d40a9ee3          	bnez	s5,80006072 <exec+0x88>
  return -1;
    8000631a:	557d                	li	a0,-1
    8000631c:	b3ad                	j	80006086 <exec+0x9c>
    8000631e:	de943c23          	sd	s1,-520(s0)
    80006322:	b7dd                	j	80006308 <exec+0x31e>
    80006324:	de943c23          	sd	s1,-520(s0)
    80006328:	b7c5                	j	80006308 <exec+0x31e>
    8000632a:	de943c23          	sd	s1,-520(s0)
    8000632e:	bfe9                	j	80006308 <exec+0x31e>
  sz = sz1;
    80006330:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80006334:	4a81                	li	s5,0
    80006336:	bfc9                	j	80006308 <exec+0x31e>
  sz = sz1;
    80006338:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000633c:	4a81                	li	s5,0
    8000633e:	b7e9                	j	80006308 <exec+0x31e>
  sz = sz1;
    80006340:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80006344:	4a81                	li	s5,0
    80006346:	b7c9                	j	80006308 <exec+0x31e>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80006348:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000634c:	e0843783          	ld	a5,-504(s0)
    80006350:	0017869b          	addiw	a3,a5,1
    80006354:	e0d43423          	sd	a3,-504(s0)
    80006358:	e0043783          	ld	a5,-512(s0)
    8000635c:	0387879b          	addiw	a5,a5,56
    80006360:	e8045703          	lhu	a4,-384(s0)
    80006364:	dce6dde3          	bge	a3,a4,8000613e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80006368:	2781                	sext.w	a5,a5
    8000636a:	e0f43023          	sd	a5,-512(s0)
    8000636e:	03800713          	li	a4,56
    80006372:	86be                	mv	a3,a5
    80006374:	e1040613          	addi	a2,s0,-496
    80006378:	4581                	li	a1,0
    8000637a:	8556                	mv	a0,s5
    8000637c:	fffff097          	auipc	ra,0xfffff
    80006380:	a30080e7          	jalr	-1488(ra) # 80004dac <readi>
    80006384:	03800793          	li	a5,56
    80006388:	f6f51ee3          	bne	a0,a5,80006304 <exec+0x31a>
    if(ph.type != ELF_PROG_LOAD)
    8000638c:	e1042783          	lw	a5,-496(s0)
    80006390:	4705                	li	a4,1
    80006392:	fae79de3          	bne	a5,a4,8000634c <exec+0x362>
    if(ph.memsz < ph.filesz)
    80006396:	e3843603          	ld	a2,-456(s0)
    8000639a:	e3043783          	ld	a5,-464(s0)
    8000639e:	f8f660e3          	bltu	a2,a5,8000631e <exec+0x334>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800063a2:	e2043783          	ld	a5,-480(s0)
    800063a6:	963e                	add	a2,a2,a5
    800063a8:	f6f66ee3          	bltu	a2,a5,80006324 <exec+0x33a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800063ac:	85a6                	mv	a1,s1
    800063ae:	855a                	mv	a0,s6
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	0ca080e7          	jalr	202(ra) # 8000147a <uvmalloc>
    800063b8:	dea43c23          	sd	a0,-520(s0)
    800063bc:	d53d                	beqz	a0,8000632a <exec+0x340>
    if(ph.vaddr % PGSIZE != 0)
    800063be:	e2043c03          	ld	s8,-480(s0)
    800063c2:	de043783          	ld	a5,-544(s0)
    800063c6:	00fc77b3          	and	a5,s8,a5
    800063ca:	ff9d                	bnez	a5,80006308 <exec+0x31e>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800063cc:	e1842c83          	lw	s9,-488(s0)
    800063d0:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800063d4:	f60b8ae3          	beqz	s7,80006348 <exec+0x35e>
    800063d8:	89de                	mv	s3,s7
    800063da:	4481                	li	s1,0
    800063dc:	b381                	j	8000611c <exec+0x132>

00000000800063de <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800063de:	7179                	addi	sp,sp,-48
    800063e0:	f406                	sd	ra,40(sp)
    800063e2:	f022                	sd	s0,32(sp)
    800063e4:	ec26                	sd	s1,24(sp)
    800063e6:	e84a                	sd	s2,16(sp)
    800063e8:	1800                	addi	s0,sp,48
    800063ea:	892e                	mv	s2,a1
    800063ec:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800063ee:	fdc40593          	addi	a1,s0,-36
    800063f2:	ffffe097          	auipc	ra,0xffffe
    800063f6:	932080e7          	jalr	-1742(ra) # 80003d24 <argint>
    800063fa:	04054063          	bltz	a0,8000643a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800063fe:	fdc42703          	lw	a4,-36(s0)
    80006402:	47bd                	li	a5,15
    80006404:	02e7ed63          	bltu	a5,a4,8000643e <argfd+0x60>
    80006408:	ffffb097          	auipc	ra,0xffffb
    8000640c:	73e080e7          	jalr	1854(ra) # 80001b46 <myproc>
    80006410:	fdc42703          	lw	a4,-36(s0)
    80006414:	00870793          	addi	a5,a4,8
    80006418:	078e                	slli	a5,a5,0x3
    8000641a:	953e                	add	a0,a0,a5
    8000641c:	651c                	ld	a5,8(a0)
    8000641e:	c395                	beqz	a5,80006442 <argfd+0x64>
    return -1;
  if(pfd)
    80006420:	00090463          	beqz	s2,80006428 <argfd+0x4a>
    *pfd = fd;
    80006424:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80006428:	4501                	li	a0,0
  if(pf)
    8000642a:	c091                	beqz	s1,8000642e <argfd+0x50>
    *pf = f;
    8000642c:	e09c                	sd	a5,0(s1)
}
    8000642e:	70a2                	ld	ra,40(sp)
    80006430:	7402                	ld	s0,32(sp)
    80006432:	64e2                	ld	s1,24(sp)
    80006434:	6942                	ld	s2,16(sp)
    80006436:	6145                	addi	sp,sp,48
    80006438:	8082                	ret
    return -1;
    8000643a:	557d                	li	a0,-1
    8000643c:	bfcd                	j	8000642e <argfd+0x50>
    return -1;
    8000643e:	557d                	li	a0,-1
    80006440:	b7fd                	j	8000642e <argfd+0x50>
    80006442:	557d                	li	a0,-1
    80006444:	b7ed                	j	8000642e <argfd+0x50>

0000000080006446 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80006446:	1101                	addi	sp,sp,-32
    80006448:	ec06                	sd	ra,24(sp)
    8000644a:	e822                	sd	s0,16(sp)
    8000644c:	e426                	sd	s1,8(sp)
    8000644e:	1000                	addi	s0,sp,32
    80006450:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80006452:	ffffb097          	auipc	ra,0xffffb
    80006456:	6f4080e7          	jalr	1780(ra) # 80001b46 <myproc>
    8000645a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000645c:	04850793          	addi	a5,a0,72
    80006460:	4501                	li	a0,0
    80006462:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80006464:	6398                	ld	a4,0(a5)
    80006466:	cb19                	beqz	a4,8000647c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80006468:	2505                	addiw	a0,a0,1
    8000646a:	07a1                	addi	a5,a5,8
    8000646c:	fed51ce3          	bne	a0,a3,80006464 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80006470:	557d                	li	a0,-1
}
    80006472:	60e2                	ld	ra,24(sp)
    80006474:	6442                	ld	s0,16(sp)
    80006476:	64a2                	ld	s1,8(sp)
    80006478:	6105                	addi	sp,sp,32
    8000647a:	8082                	ret
      p->ofile[fd] = f;
    8000647c:	00850793          	addi	a5,a0,8
    80006480:	078e                	slli	a5,a5,0x3
    80006482:	963e                	add	a2,a2,a5
    80006484:	e604                	sd	s1,8(a2)
      return fd;
    80006486:	b7f5                	j	80006472 <fdalloc+0x2c>

0000000080006488 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80006488:	715d                	addi	sp,sp,-80
    8000648a:	e486                	sd	ra,72(sp)
    8000648c:	e0a2                	sd	s0,64(sp)
    8000648e:	fc26                	sd	s1,56(sp)
    80006490:	f84a                	sd	s2,48(sp)
    80006492:	f44e                	sd	s3,40(sp)
    80006494:	f052                	sd	s4,32(sp)
    80006496:	ec56                	sd	s5,24(sp)
    80006498:	0880                	addi	s0,sp,80
    8000649a:	89ae                	mv	s3,a1
    8000649c:	8ab2                	mv	s5,a2
    8000649e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800064a0:	fb040593          	addi	a1,s0,-80
    800064a4:	fffff097          	auipc	ra,0xfffff
    800064a8:	e26080e7          	jalr	-474(ra) # 800052ca <nameiparent>
    800064ac:	892a                	mv	s2,a0
    800064ae:	12050e63          	beqz	a0,800065ea <create+0x162>
    return 0;

  ilock(dp);
    800064b2:	ffffe097          	auipc	ra,0xffffe
    800064b6:	646080e7          	jalr	1606(ra) # 80004af8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800064ba:	4601                	li	a2,0
    800064bc:	fb040593          	addi	a1,s0,-80
    800064c0:	854a                	mv	a0,s2
    800064c2:	fffff097          	auipc	ra,0xfffff
    800064c6:	b1a080e7          	jalr	-1254(ra) # 80004fdc <dirlookup>
    800064ca:	84aa                	mv	s1,a0
    800064cc:	c921                	beqz	a0,8000651c <create+0x94>
    iunlockput(dp);
    800064ce:	854a                	mv	a0,s2
    800064d0:	fffff097          	auipc	ra,0xfffff
    800064d4:	88a080e7          	jalr	-1910(ra) # 80004d5a <iunlockput>
    ilock(ip);
    800064d8:	8526                	mv	a0,s1
    800064da:	ffffe097          	auipc	ra,0xffffe
    800064de:	61e080e7          	jalr	1566(ra) # 80004af8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800064e2:	2981                	sext.w	s3,s3
    800064e4:	4789                	li	a5,2
    800064e6:	02f99463          	bne	s3,a5,8000650e <create+0x86>
    800064ea:	0444d783          	lhu	a5,68(s1)
    800064ee:	37f9                	addiw	a5,a5,-2
    800064f0:	17c2                	slli	a5,a5,0x30
    800064f2:	93c1                	srli	a5,a5,0x30
    800064f4:	4705                	li	a4,1
    800064f6:	00f76c63          	bltu	a4,a5,8000650e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800064fa:	8526                	mv	a0,s1
    800064fc:	60a6                	ld	ra,72(sp)
    800064fe:	6406                	ld	s0,64(sp)
    80006500:	74e2                	ld	s1,56(sp)
    80006502:	7942                	ld	s2,48(sp)
    80006504:	79a2                	ld	s3,40(sp)
    80006506:	7a02                	ld	s4,32(sp)
    80006508:	6ae2                	ld	s5,24(sp)
    8000650a:	6161                	addi	sp,sp,80
    8000650c:	8082                	ret
    iunlockput(ip);
    8000650e:	8526                	mv	a0,s1
    80006510:	fffff097          	auipc	ra,0xfffff
    80006514:	84a080e7          	jalr	-1974(ra) # 80004d5a <iunlockput>
    return 0;
    80006518:	4481                	li	s1,0
    8000651a:	b7c5                	j	800064fa <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000651c:	85ce                	mv	a1,s3
    8000651e:	00092503          	lw	a0,0(s2)
    80006522:	ffffe097          	auipc	ra,0xffffe
    80006526:	43e080e7          	jalr	1086(ra) # 80004960 <ialloc>
    8000652a:	84aa                	mv	s1,a0
    8000652c:	c521                	beqz	a0,80006574 <create+0xec>
  ilock(ip);
    8000652e:	ffffe097          	auipc	ra,0xffffe
    80006532:	5ca080e7          	jalr	1482(ra) # 80004af8 <ilock>
  ip->major = major;
    80006536:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000653a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000653e:	4a05                	li	s4,1
    80006540:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80006544:	8526                	mv	a0,s1
    80006546:	ffffe097          	auipc	ra,0xffffe
    8000654a:	4e8080e7          	jalr	1256(ra) # 80004a2e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000654e:	2981                	sext.w	s3,s3
    80006550:	03498a63          	beq	s3,s4,80006584 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80006554:	40d0                	lw	a2,4(s1)
    80006556:	fb040593          	addi	a1,s0,-80
    8000655a:	854a                	mv	a0,s2
    8000655c:	fffff097          	auipc	ra,0xfffff
    80006560:	c8e080e7          	jalr	-882(ra) # 800051ea <dirlink>
    80006564:	06054b63          	bltz	a0,800065da <create+0x152>
  iunlockput(dp);
    80006568:	854a                	mv	a0,s2
    8000656a:	ffffe097          	auipc	ra,0xffffe
    8000656e:	7f0080e7          	jalr	2032(ra) # 80004d5a <iunlockput>
  return ip;
    80006572:	b761                	j	800064fa <create+0x72>
    panic("create: ialloc");
    80006574:	00003517          	auipc	a0,0x3
    80006578:	23c50513          	addi	a0,a0,572 # 800097b0 <syscalls+0x2f8>
    8000657c:	ffffa097          	auipc	ra,0xffffa
    80006580:	fae080e7          	jalr	-82(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80006584:	04a95783          	lhu	a5,74(s2)
    80006588:	2785                	addiw	a5,a5,1
    8000658a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000658e:	854a                	mv	a0,s2
    80006590:	ffffe097          	auipc	ra,0xffffe
    80006594:	49e080e7          	jalr	1182(ra) # 80004a2e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006598:	40d0                	lw	a2,4(s1)
    8000659a:	00003597          	auipc	a1,0x3
    8000659e:	22658593          	addi	a1,a1,550 # 800097c0 <syscalls+0x308>
    800065a2:	8526                	mv	a0,s1
    800065a4:	fffff097          	auipc	ra,0xfffff
    800065a8:	c46080e7          	jalr	-954(ra) # 800051ea <dirlink>
    800065ac:	00054f63          	bltz	a0,800065ca <create+0x142>
    800065b0:	00492603          	lw	a2,4(s2)
    800065b4:	00003597          	auipc	a1,0x3
    800065b8:	21458593          	addi	a1,a1,532 # 800097c8 <syscalls+0x310>
    800065bc:	8526                	mv	a0,s1
    800065be:	fffff097          	auipc	ra,0xfffff
    800065c2:	c2c080e7          	jalr	-980(ra) # 800051ea <dirlink>
    800065c6:	f80557e3          	bgez	a0,80006554 <create+0xcc>
      panic("create dots");
    800065ca:	00003517          	auipc	a0,0x3
    800065ce:	20650513          	addi	a0,a0,518 # 800097d0 <syscalls+0x318>
    800065d2:	ffffa097          	auipc	ra,0xffffa
    800065d6:	f58080e7          	jalr	-168(ra) # 8000052a <panic>
    panic("create: dirlink");
    800065da:	00003517          	auipc	a0,0x3
    800065de:	20650513          	addi	a0,a0,518 # 800097e0 <syscalls+0x328>
    800065e2:	ffffa097          	auipc	ra,0xffffa
    800065e6:	f48080e7          	jalr	-184(ra) # 8000052a <panic>
    return 0;
    800065ea:	84aa                	mv	s1,a0
    800065ec:	b739                	j	800064fa <create+0x72>

00000000800065ee <sys_dup>:
{
    800065ee:	7179                	addi	sp,sp,-48
    800065f0:	f406                	sd	ra,40(sp)
    800065f2:	f022                	sd	s0,32(sp)
    800065f4:	ec26                	sd	s1,24(sp)
    800065f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800065f8:	fd840613          	addi	a2,s0,-40
    800065fc:	4581                	li	a1,0
    800065fe:	4501                	li	a0,0
    80006600:	00000097          	auipc	ra,0x0
    80006604:	dde080e7          	jalr	-546(ra) # 800063de <argfd>
    return -1;
    80006608:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000660a:	02054363          	bltz	a0,80006630 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000660e:	fd843503          	ld	a0,-40(s0)
    80006612:	00000097          	auipc	ra,0x0
    80006616:	e34080e7          	jalr	-460(ra) # 80006446 <fdalloc>
    8000661a:	84aa                	mv	s1,a0
    return -1;
    8000661c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000661e:	00054963          	bltz	a0,80006630 <sys_dup+0x42>
  filedup(f);
    80006622:	fd843503          	ld	a0,-40(s0)
    80006626:	fffff097          	auipc	ra,0xfffff
    8000662a:	320080e7          	jalr	800(ra) # 80005946 <filedup>
  return fd;
    8000662e:	87a6                	mv	a5,s1
}
    80006630:	853e                	mv	a0,a5
    80006632:	70a2                	ld	ra,40(sp)
    80006634:	7402                	ld	s0,32(sp)
    80006636:	64e2                	ld	s1,24(sp)
    80006638:	6145                	addi	sp,sp,48
    8000663a:	8082                	ret

000000008000663c <sys_read>:
{
    8000663c:	7179                	addi	sp,sp,-48
    8000663e:	f406                	sd	ra,40(sp)
    80006640:	f022                	sd	s0,32(sp)
    80006642:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006644:	fe840613          	addi	a2,s0,-24
    80006648:	4581                	li	a1,0
    8000664a:	4501                	li	a0,0
    8000664c:	00000097          	auipc	ra,0x0
    80006650:	d92080e7          	jalr	-622(ra) # 800063de <argfd>
    return -1;
    80006654:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006656:	04054163          	bltz	a0,80006698 <sys_read+0x5c>
    8000665a:	fe440593          	addi	a1,s0,-28
    8000665e:	4509                	li	a0,2
    80006660:	ffffd097          	auipc	ra,0xffffd
    80006664:	6c4080e7          	jalr	1732(ra) # 80003d24 <argint>
    return -1;
    80006668:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000666a:	02054763          	bltz	a0,80006698 <sys_read+0x5c>
    8000666e:	fd840593          	addi	a1,s0,-40
    80006672:	4505                	li	a0,1
    80006674:	ffffd097          	auipc	ra,0xffffd
    80006678:	6d2080e7          	jalr	1746(ra) # 80003d46 <argaddr>
    return -1;
    8000667c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000667e:	00054d63          	bltz	a0,80006698 <sys_read+0x5c>
  return fileread(f, p, n);
    80006682:	fe442603          	lw	a2,-28(s0)
    80006686:	fd843583          	ld	a1,-40(s0)
    8000668a:	fe843503          	ld	a0,-24(s0)
    8000668e:	fffff097          	auipc	ra,0xfffff
    80006692:	444080e7          	jalr	1092(ra) # 80005ad2 <fileread>
    80006696:	87aa                	mv	a5,a0
}
    80006698:	853e                	mv	a0,a5
    8000669a:	70a2                	ld	ra,40(sp)
    8000669c:	7402                	ld	s0,32(sp)
    8000669e:	6145                	addi	sp,sp,48
    800066a0:	8082                	ret

00000000800066a2 <sys_write>:
{
    800066a2:	7179                	addi	sp,sp,-48
    800066a4:	f406                	sd	ra,40(sp)
    800066a6:	f022                	sd	s0,32(sp)
    800066a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800066aa:	fe840613          	addi	a2,s0,-24
    800066ae:	4581                	li	a1,0
    800066b0:	4501                	li	a0,0
    800066b2:	00000097          	auipc	ra,0x0
    800066b6:	d2c080e7          	jalr	-724(ra) # 800063de <argfd>
    return -1;
    800066ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800066bc:	04054163          	bltz	a0,800066fe <sys_write+0x5c>
    800066c0:	fe440593          	addi	a1,s0,-28
    800066c4:	4509                	li	a0,2
    800066c6:	ffffd097          	auipc	ra,0xffffd
    800066ca:	65e080e7          	jalr	1630(ra) # 80003d24 <argint>
    return -1;
    800066ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800066d0:	02054763          	bltz	a0,800066fe <sys_write+0x5c>
    800066d4:	fd840593          	addi	a1,s0,-40
    800066d8:	4505                	li	a0,1
    800066da:	ffffd097          	auipc	ra,0xffffd
    800066de:	66c080e7          	jalr	1644(ra) # 80003d46 <argaddr>
    return -1;
    800066e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800066e4:	00054d63          	bltz	a0,800066fe <sys_write+0x5c>
  return filewrite(f, p, n);
    800066e8:	fe442603          	lw	a2,-28(s0)
    800066ec:	fd843583          	ld	a1,-40(s0)
    800066f0:	fe843503          	ld	a0,-24(s0)
    800066f4:	fffff097          	auipc	ra,0xfffff
    800066f8:	4a0080e7          	jalr	1184(ra) # 80005b94 <filewrite>
    800066fc:	87aa                	mv	a5,a0
}
    800066fe:	853e                	mv	a0,a5
    80006700:	70a2                	ld	ra,40(sp)
    80006702:	7402                	ld	s0,32(sp)
    80006704:	6145                	addi	sp,sp,48
    80006706:	8082                	ret

0000000080006708 <sys_close>:
{
    80006708:	1101                	addi	sp,sp,-32
    8000670a:	ec06                	sd	ra,24(sp)
    8000670c:	e822                	sd	s0,16(sp)
    8000670e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80006710:	fe040613          	addi	a2,s0,-32
    80006714:	fec40593          	addi	a1,s0,-20
    80006718:	4501                	li	a0,0
    8000671a:	00000097          	auipc	ra,0x0
    8000671e:	cc4080e7          	jalr	-828(ra) # 800063de <argfd>
    return -1;
    80006722:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80006724:	02054463          	bltz	a0,8000674c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80006728:	ffffb097          	auipc	ra,0xffffb
    8000672c:	41e080e7          	jalr	1054(ra) # 80001b46 <myproc>
    80006730:	fec42783          	lw	a5,-20(s0)
    80006734:	07a1                	addi	a5,a5,8
    80006736:	078e                	slli	a5,a5,0x3
    80006738:	97aa                	add	a5,a5,a0
    8000673a:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000673e:	fe043503          	ld	a0,-32(s0)
    80006742:	fffff097          	auipc	ra,0xfffff
    80006746:	256080e7          	jalr	598(ra) # 80005998 <fileclose>
  return 0;
    8000674a:	4781                	li	a5,0
}
    8000674c:	853e                	mv	a0,a5
    8000674e:	60e2                	ld	ra,24(sp)
    80006750:	6442                	ld	s0,16(sp)
    80006752:	6105                	addi	sp,sp,32
    80006754:	8082                	ret

0000000080006756 <sys_fstat>:
{
    80006756:	1101                	addi	sp,sp,-32
    80006758:	ec06                	sd	ra,24(sp)
    8000675a:	e822                	sd	s0,16(sp)
    8000675c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000675e:	fe840613          	addi	a2,s0,-24
    80006762:	4581                	li	a1,0
    80006764:	4501                	li	a0,0
    80006766:	00000097          	auipc	ra,0x0
    8000676a:	c78080e7          	jalr	-904(ra) # 800063de <argfd>
    return -1;
    8000676e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006770:	02054563          	bltz	a0,8000679a <sys_fstat+0x44>
    80006774:	fe040593          	addi	a1,s0,-32
    80006778:	4505                	li	a0,1
    8000677a:	ffffd097          	auipc	ra,0xffffd
    8000677e:	5cc080e7          	jalr	1484(ra) # 80003d46 <argaddr>
    return -1;
    80006782:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006784:	00054b63          	bltz	a0,8000679a <sys_fstat+0x44>
  return filestat(f, st);
    80006788:	fe043583          	ld	a1,-32(s0)
    8000678c:	fe843503          	ld	a0,-24(s0)
    80006790:	fffff097          	auipc	ra,0xfffff
    80006794:	2d0080e7          	jalr	720(ra) # 80005a60 <filestat>
    80006798:	87aa                	mv	a5,a0
}
    8000679a:	853e                	mv	a0,a5
    8000679c:	60e2                	ld	ra,24(sp)
    8000679e:	6442                	ld	s0,16(sp)
    800067a0:	6105                	addi	sp,sp,32
    800067a2:	8082                	ret

00000000800067a4 <sys_link>:
{
    800067a4:	7169                	addi	sp,sp,-304
    800067a6:	f606                	sd	ra,296(sp)
    800067a8:	f222                	sd	s0,288(sp)
    800067aa:	ee26                	sd	s1,280(sp)
    800067ac:	ea4a                	sd	s2,272(sp)
    800067ae:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800067b0:	08000613          	li	a2,128
    800067b4:	ed040593          	addi	a1,s0,-304
    800067b8:	4501                	li	a0,0
    800067ba:	ffffd097          	auipc	ra,0xffffd
    800067be:	5ae080e7          	jalr	1454(ra) # 80003d68 <argstr>
    return -1;
    800067c2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800067c4:	10054e63          	bltz	a0,800068e0 <sys_link+0x13c>
    800067c8:	08000613          	li	a2,128
    800067cc:	f5040593          	addi	a1,s0,-176
    800067d0:	4505                	li	a0,1
    800067d2:	ffffd097          	auipc	ra,0xffffd
    800067d6:	596080e7          	jalr	1430(ra) # 80003d68 <argstr>
    return -1;
    800067da:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800067dc:	10054263          	bltz	a0,800068e0 <sys_link+0x13c>
  begin_op();
    800067e0:	fffff097          	auipc	ra,0xfffff
    800067e4:	cec080e7          	jalr	-788(ra) # 800054cc <begin_op>
  if((ip = namei(old)) == 0){
    800067e8:	ed040513          	addi	a0,s0,-304
    800067ec:	fffff097          	auipc	ra,0xfffff
    800067f0:	ac0080e7          	jalr	-1344(ra) # 800052ac <namei>
    800067f4:	84aa                	mv	s1,a0
    800067f6:	c551                	beqz	a0,80006882 <sys_link+0xde>
  ilock(ip);
    800067f8:	ffffe097          	auipc	ra,0xffffe
    800067fc:	300080e7          	jalr	768(ra) # 80004af8 <ilock>
  if(ip->type == T_DIR){
    80006800:	04449703          	lh	a4,68(s1)
    80006804:	4785                	li	a5,1
    80006806:	08f70463          	beq	a4,a5,8000688e <sys_link+0xea>
  ip->nlink++;
    8000680a:	04a4d783          	lhu	a5,74(s1)
    8000680e:	2785                	addiw	a5,a5,1
    80006810:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006814:	8526                	mv	a0,s1
    80006816:	ffffe097          	auipc	ra,0xffffe
    8000681a:	218080e7          	jalr	536(ra) # 80004a2e <iupdate>
  iunlock(ip);
    8000681e:	8526                	mv	a0,s1
    80006820:	ffffe097          	auipc	ra,0xffffe
    80006824:	39a080e7          	jalr	922(ra) # 80004bba <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006828:	fd040593          	addi	a1,s0,-48
    8000682c:	f5040513          	addi	a0,s0,-176
    80006830:	fffff097          	auipc	ra,0xfffff
    80006834:	a9a080e7          	jalr	-1382(ra) # 800052ca <nameiparent>
    80006838:	892a                	mv	s2,a0
    8000683a:	c935                	beqz	a0,800068ae <sys_link+0x10a>
  ilock(dp);
    8000683c:	ffffe097          	auipc	ra,0xffffe
    80006840:	2bc080e7          	jalr	700(ra) # 80004af8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006844:	00092703          	lw	a4,0(s2)
    80006848:	409c                	lw	a5,0(s1)
    8000684a:	04f71d63          	bne	a4,a5,800068a4 <sys_link+0x100>
    8000684e:	40d0                	lw	a2,4(s1)
    80006850:	fd040593          	addi	a1,s0,-48
    80006854:	854a                	mv	a0,s2
    80006856:	fffff097          	auipc	ra,0xfffff
    8000685a:	994080e7          	jalr	-1644(ra) # 800051ea <dirlink>
    8000685e:	04054363          	bltz	a0,800068a4 <sys_link+0x100>
  iunlockput(dp);
    80006862:	854a                	mv	a0,s2
    80006864:	ffffe097          	auipc	ra,0xffffe
    80006868:	4f6080e7          	jalr	1270(ra) # 80004d5a <iunlockput>
  iput(ip);
    8000686c:	8526                	mv	a0,s1
    8000686e:	ffffe097          	auipc	ra,0xffffe
    80006872:	444080e7          	jalr	1092(ra) # 80004cb2 <iput>
  end_op();
    80006876:	fffff097          	auipc	ra,0xfffff
    8000687a:	cd6080e7          	jalr	-810(ra) # 8000554c <end_op>
  return 0;
    8000687e:	4781                	li	a5,0
    80006880:	a085                	j	800068e0 <sys_link+0x13c>
    end_op();
    80006882:	fffff097          	auipc	ra,0xfffff
    80006886:	cca080e7          	jalr	-822(ra) # 8000554c <end_op>
    return -1;
    8000688a:	57fd                	li	a5,-1
    8000688c:	a891                	j	800068e0 <sys_link+0x13c>
    iunlockput(ip);
    8000688e:	8526                	mv	a0,s1
    80006890:	ffffe097          	auipc	ra,0xffffe
    80006894:	4ca080e7          	jalr	1226(ra) # 80004d5a <iunlockput>
    end_op();
    80006898:	fffff097          	auipc	ra,0xfffff
    8000689c:	cb4080e7          	jalr	-844(ra) # 8000554c <end_op>
    return -1;
    800068a0:	57fd                	li	a5,-1
    800068a2:	a83d                	j	800068e0 <sys_link+0x13c>
    iunlockput(dp);
    800068a4:	854a                	mv	a0,s2
    800068a6:	ffffe097          	auipc	ra,0xffffe
    800068aa:	4b4080e7          	jalr	1204(ra) # 80004d5a <iunlockput>
  ilock(ip);
    800068ae:	8526                	mv	a0,s1
    800068b0:	ffffe097          	auipc	ra,0xffffe
    800068b4:	248080e7          	jalr	584(ra) # 80004af8 <ilock>
  ip->nlink--;
    800068b8:	04a4d783          	lhu	a5,74(s1)
    800068bc:	37fd                	addiw	a5,a5,-1
    800068be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800068c2:	8526                	mv	a0,s1
    800068c4:	ffffe097          	auipc	ra,0xffffe
    800068c8:	16a080e7          	jalr	362(ra) # 80004a2e <iupdate>
  iunlockput(ip);
    800068cc:	8526                	mv	a0,s1
    800068ce:	ffffe097          	auipc	ra,0xffffe
    800068d2:	48c080e7          	jalr	1164(ra) # 80004d5a <iunlockput>
  end_op();
    800068d6:	fffff097          	auipc	ra,0xfffff
    800068da:	c76080e7          	jalr	-906(ra) # 8000554c <end_op>
  return -1;
    800068de:	57fd                	li	a5,-1
}
    800068e0:	853e                	mv	a0,a5
    800068e2:	70b2                	ld	ra,296(sp)
    800068e4:	7412                	ld	s0,288(sp)
    800068e6:	64f2                	ld	s1,280(sp)
    800068e8:	6952                	ld	s2,272(sp)
    800068ea:	6155                	addi	sp,sp,304
    800068ec:	8082                	ret

00000000800068ee <sys_unlink>:
{
    800068ee:	7151                	addi	sp,sp,-240
    800068f0:	f586                	sd	ra,232(sp)
    800068f2:	f1a2                	sd	s0,224(sp)
    800068f4:	eda6                	sd	s1,216(sp)
    800068f6:	e9ca                	sd	s2,208(sp)
    800068f8:	e5ce                	sd	s3,200(sp)
    800068fa:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800068fc:	08000613          	li	a2,128
    80006900:	f3040593          	addi	a1,s0,-208
    80006904:	4501                	li	a0,0
    80006906:	ffffd097          	auipc	ra,0xffffd
    8000690a:	462080e7          	jalr	1122(ra) # 80003d68 <argstr>
    8000690e:	18054163          	bltz	a0,80006a90 <sys_unlink+0x1a2>
  begin_op();
    80006912:	fffff097          	auipc	ra,0xfffff
    80006916:	bba080e7          	jalr	-1094(ra) # 800054cc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000691a:	fb040593          	addi	a1,s0,-80
    8000691e:	f3040513          	addi	a0,s0,-208
    80006922:	fffff097          	auipc	ra,0xfffff
    80006926:	9a8080e7          	jalr	-1624(ra) # 800052ca <nameiparent>
    8000692a:	84aa                	mv	s1,a0
    8000692c:	c979                	beqz	a0,80006a02 <sys_unlink+0x114>
  ilock(dp);
    8000692e:	ffffe097          	auipc	ra,0xffffe
    80006932:	1ca080e7          	jalr	458(ra) # 80004af8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006936:	00003597          	auipc	a1,0x3
    8000693a:	e8a58593          	addi	a1,a1,-374 # 800097c0 <syscalls+0x308>
    8000693e:	fb040513          	addi	a0,s0,-80
    80006942:	ffffe097          	auipc	ra,0xffffe
    80006946:	680080e7          	jalr	1664(ra) # 80004fc2 <namecmp>
    8000694a:	14050a63          	beqz	a0,80006a9e <sys_unlink+0x1b0>
    8000694e:	00003597          	auipc	a1,0x3
    80006952:	e7a58593          	addi	a1,a1,-390 # 800097c8 <syscalls+0x310>
    80006956:	fb040513          	addi	a0,s0,-80
    8000695a:	ffffe097          	auipc	ra,0xffffe
    8000695e:	668080e7          	jalr	1640(ra) # 80004fc2 <namecmp>
    80006962:	12050e63          	beqz	a0,80006a9e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006966:	f2c40613          	addi	a2,s0,-212
    8000696a:	fb040593          	addi	a1,s0,-80
    8000696e:	8526                	mv	a0,s1
    80006970:	ffffe097          	auipc	ra,0xffffe
    80006974:	66c080e7          	jalr	1644(ra) # 80004fdc <dirlookup>
    80006978:	892a                	mv	s2,a0
    8000697a:	12050263          	beqz	a0,80006a9e <sys_unlink+0x1b0>
  ilock(ip);
    8000697e:	ffffe097          	auipc	ra,0xffffe
    80006982:	17a080e7          	jalr	378(ra) # 80004af8 <ilock>
  if(ip->nlink < 1)
    80006986:	04a91783          	lh	a5,74(s2)
    8000698a:	08f05263          	blez	a5,80006a0e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000698e:	04491703          	lh	a4,68(s2)
    80006992:	4785                	li	a5,1
    80006994:	08f70563          	beq	a4,a5,80006a1e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80006998:	4641                	li	a2,16
    8000699a:	4581                	li	a1,0
    8000699c:	fc040513          	addi	a0,s0,-64
    800069a0:	ffffa097          	auipc	ra,0xffffa
    800069a4:	3aa080e7          	jalr	938(ra) # 80000d4a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800069a8:	4741                	li	a4,16
    800069aa:	f2c42683          	lw	a3,-212(s0)
    800069ae:	fc040613          	addi	a2,s0,-64
    800069b2:	4581                	li	a1,0
    800069b4:	8526                	mv	a0,s1
    800069b6:	ffffe097          	auipc	ra,0xffffe
    800069ba:	4ee080e7          	jalr	1262(ra) # 80004ea4 <writei>
    800069be:	47c1                	li	a5,16
    800069c0:	0af51563          	bne	a0,a5,80006a6a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800069c4:	04491703          	lh	a4,68(s2)
    800069c8:	4785                	li	a5,1
    800069ca:	0af70863          	beq	a4,a5,80006a7a <sys_unlink+0x18c>
  iunlockput(dp);
    800069ce:	8526                	mv	a0,s1
    800069d0:	ffffe097          	auipc	ra,0xffffe
    800069d4:	38a080e7          	jalr	906(ra) # 80004d5a <iunlockput>
  ip->nlink--;
    800069d8:	04a95783          	lhu	a5,74(s2)
    800069dc:	37fd                	addiw	a5,a5,-1
    800069de:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800069e2:	854a                	mv	a0,s2
    800069e4:	ffffe097          	auipc	ra,0xffffe
    800069e8:	04a080e7          	jalr	74(ra) # 80004a2e <iupdate>
  iunlockput(ip);
    800069ec:	854a                	mv	a0,s2
    800069ee:	ffffe097          	auipc	ra,0xffffe
    800069f2:	36c080e7          	jalr	876(ra) # 80004d5a <iunlockput>
  end_op();
    800069f6:	fffff097          	auipc	ra,0xfffff
    800069fa:	b56080e7          	jalr	-1194(ra) # 8000554c <end_op>
  return 0;
    800069fe:	4501                	li	a0,0
    80006a00:	a84d                	j	80006ab2 <sys_unlink+0x1c4>
    end_op();
    80006a02:	fffff097          	auipc	ra,0xfffff
    80006a06:	b4a080e7          	jalr	-1206(ra) # 8000554c <end_op>
    return -1;
    80006a0a:	557d                	li	a0,-1
    80006a0c:	a05d                	j	80006ab2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006a0e:	00003517          	auipc	a0,0x3
    80006a12:	de250513          	addi	a0,a0,-542 # 800097f0 <syscalls+0x338>
    80006a16:	ffffa097          	auipc	ra,0xffffa
    80006a1a:	b14080e7          	jalr	-1260(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006a1e:	04c92703          	lw	a4,76(s2)
    80006a22:	02000793          	li	a5,32
    80006a26:	f6e7f9e3          	bgeu	a5,a4,80006998 <sys_unlink+0xaa>
    80006a2a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006a2e:	4741                	li	a4,16
    80006a30:	86ce                	mv	a3,s3
    80006a32:	f1840613          	addi	a2,s0,-232
    80006a36:	4581                	li	a1,0
    80006a38:	854a                	mv	a0,s2
    80006a3a:	ffffe097          	auipc	ra,0xffffe
    80006a3e:	372080e7          	jalr	882(ra) # 80004dac <readi>
    80006a42:	47c1                	li	a5,16
    80006a44:	00f51b63          	bne	a0,a5,80006a5a <sys_unlink+0x16c>
    if(de.inum != 0)
    80006a48:	f1845783          	lhu	a5,-232(s0)
    80006a4c:	e7a1                	bnez	a5,80006a94 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006a4e:	29c1                	addiw	s3,s3,16
    80006a50:	04c92783          	lw	a5,76(s2)
    80006a54:	fcf9ede3          	bltu	s3,a5,80006a2e <sys_unlink+0x140>
    80006a58:	b781                	j	80006998 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006a5a:	00003517          	auipc	a0,0x3
    80006a5e:	dae50513          	addi	a0,a0,-594 # 80009808 <syscalls+0x350>
    80006a62:	ffffa097          	auipc	ra,0xffffa
    80006a66:	ac8080e7          	jalr	-1336(ra) # 8000052a <panic>
    panic("unlink: writei");
    80006a6a:	00003517          	auipc	a0,0x3
    80006a6e:	db650513          	addi	a0,a0,-586 # 80009820 <syscalls+0x368>
    80006a72:	ffffa097          	auipc	ra,0xffffa
    80006a76:	ab8080e7          	jalr	-1352(ra) # 8000052a <panic>
    dp->nlink--;
    80006a7a:	04a4d783          	lhu	a5,74(s1)
    80006a7e:	37fd                	addiw	a5,a5,-1
    80006a80:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006a84:	8526                	mv	a0,s1
    80006a86:	ffffe097          	auipc	ra,0xffffe
    80006a8a:	fa8080e7          	jalr	-88(ra) # 80004a2e <iupdate>
    80006a8e:	b781                	j	800069ce <sys_unlink+0xe0>
    return -1;
    80006a90:	557d                	li	a0,-1
    80006a92:	a005                	j	80006ab2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006a94:	854a                	mv	a0,s2
    80006a96:	ffffe097          	auipc	ra,0xffffe
    80006a9a:	2c4080e7          	jalr	708(ra) # 80004d5a <iunlockput>
  iunlockput(dp);
    80006a9e:	8526                	mv	a0,s1
    80006aa0:	ffffe097          	auipc	ra,0xffffe
    80006aa4:	2ba080e7          	jalr	698(ra) # 80004d5a <iunlockput>
  end_op();
    80006aa8:	fffff097          	auipc	ra,0xfffff
    80006aac:	aa4080e7          	jalr	-1372(ra) # 8000554c <end_op>
  return -1;
    80006ab0:	557d                	li	a0,-1
}
    80006ab2:	70ae                	ld	ra,232(sp)
    80006ab4:	740e                	ld	s0,224(sp)
    80006ab6:	64ee                	ld	s1,216(sp)
    80006ab8:	694e                	ld	s2,208(sp)
    80006aba:	69ae                	ld	s3,200(sp)
    80006abc:	616d                	addi	sp,sp,240
    80006abe:	8082                	ret

0000000080006ac0 <sys_open>:

uint64
sys_open(void)
{
    80006ac0:	7131                	addi	sp,sp,-192
    80006ac2:	fd06                	sd	ra,184(sp)
    80006ac4:	f922                	sd	s0,176(sp)
    80006ac6:	f526                	sd	s1,168(sp)
    80006ac8:	f14a                	sd	s2,160(sp)
    80006aca:	ed4e                	sd	s3,152(sp)
    80006acc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006ace:	08000613          	li	a2,128
    80006ad2:	f5040593          	addi	a1,s0,-176
    80006ad6:	4501                	li	a0,0
    80006ad8:	ffffd097          	auipc	ra,0xffffd
    80006adc:	290080e7          	jalr	656(ra) # 80003d68 <argstr>
    return -1;
    80006ae0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006ae2:	0c054163          	bltz	a0,80006ba4 <sys_open+0xe4>
    80006ae6:	f4c40593          	addi	a1,s0,-180
    80006aea:	4505                	li	a0,1
    80006aec:	ffffd097          	auipc	ra,0xffffd
    80006af0:	238080e7          	jalr	568(ra) # 80003d24 <argint>
    80006af4:	0a054863          	bltz	a0,80006ba4 <sys_open+0xe4>

  begin_op();
    80006af8:	fffff097          	auipc	ra,0xfffff
    80006afc:	9d4080e7          	jalr	-1580(ra) # 800054cc <begin_op>

  if(omode & O_CREATE){
    80006b00:	f4c42783          	lw	a5,-180(s0)
    80006b04:	2007f793          	andi	a5,a5,512
    80006b08:	cbdd                	beqz	a5,80006bbe <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006b0a:	4681                	li	a3,0
    80006b0c:	4601                	li	a2,0
    80006b0e:	4589                	li	a1,2
    80006b10:	f5040513          	addi	a0,s0,-176
    80006b14:	00000097          	auipc	ra,0x0
    80006b18:	974080e7          	jalr	-1676(ra) # 80006488 <create>
    80006b1c:	892a                	mv	s2,a0
    if(ip == 0){
    80006b1e:	c959                	beqz	a0,80006bb4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006b20:	04491703          	lh	a4,68(s2)
    80006b24:	478d                	li	a5,3
    80006b26:	00f71763          	bne	a4,a5,80006b34 <sys_open+0x74>
    80006b2a:	04695703          	lhu	a4,70(s2)
    80006b2e:	47a5                	li	a5,9
    80006b30:	0ce7ec63          	bltu	a5,a4,80006c08 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006b34:	fffff097          	auipc	ra,0xfffff
    80006b38:	da8080e7          	jalr	-600(ra) # 800058dc <filealloc>
    80006b3c:	89aa                	mv	s3,a0
    80006b3e:	10050263          	beqz	a0,80006c42 <sys_open+0x182>
    80006b42:	00000097          	auipc	ra,0x0
    80006b46:	904080e7          	jalr	-1788(ra) # 80006446 <fdalloc>
    80006b4a:	84aa                	mv	s1,a0
    80006b4c:	0e054663          	bltz	a0,80006c38 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006b50:	04491703          	lh	a4,68(s2)
    80006b54:	478d                	li	a5,3
    80006b56:	0cf70463          	beq	a4,a5,80006c1e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006b5a:	4789                	li	a5,2
    80006b5c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006b60:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006b64:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006b68:	f4c42783          	lw	a5,-180(s0)
    80006b6c:	0017c713          	xori	a4,a5,1
    80006b70:	8b05                	andi	a4,a4,1
    80006b72:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006b76:	0037f713          	andi	a4,a5,3
    80006b7a:	00e03733          	snez	a4,a4
    80006b7e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006b82:	4007f793          	andi	a5,a5,1024
    80006b86:	c791                	beqz	a5,80006b92 <sys_open+0xd2>
    80006b88:	04491703          	lh	a4,68(s2)
    80006b8c:	4789                	li	a5,2
    80006b8e:	08f70f63          	beq	a4,a5,80006c2c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006b92:	854a                	mv	a0,s2
    80006b94:	ffffe097          	auipc	ra,0xffffe
    80006b98:	026080e7          	jalr	38(ra) # 80004bba <iunlock>
  end_op();
    80006b9c:	fffff097          	auipc	ra,0xfffff
    80006ba0:	9b0080e7          	jalr	-1616(ra) # 8000554c <end_op>

  return fd;
}
    80006ba4:	8526                	mv	a0,s1
    80006ba6:	70ea                	ld	ra,184(sp)
    80006ba8:	744a                	ld	s0,176(sp)
    80006baa:	74aa                	ld	s1,168(sp)
    80006bac:	790a                	ld	s2,160(sp)
    80006bae:	69ea                	ld	s3,152(sp)
    80006bb0:	6129                	addi	sp,sp,192
    80006bb2:	8082                	ret
      end_op();
    80006bb4:	fffff097          	auipc	ra,0xfffff
    80006bb8:	998080e7          	jalr	-1640(ra) # 8000554c <end_op>
      return -1;
    80006bbc:	b7e5                	j	80006ba4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006bbe:	f5040513          	addi	a0,s0,-176
    80006bc2:	ffffe097          	auipc	ra,0xffffe
    80006bc6:	6ea080e7          	jalr	1770(ra) # 800052ac <namei>
    80006bca:	892a                	mv	s2,a0
    80006bcc:	c905                	beqz	a0,80006bfc <sys_open+0x13c>
    ilock(ip);
    80006bce:	ffffe097          	auipc	ra,0xffffe
    80006bd2:	f2a080e7          	jalr	-214(ra) # 80004af8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006bd6:	04491703          	lh	a4,68(s2)
    80006bda:	4785                	li	a5,1
    80006bdc:	f4f712e3          	bne	a4,a5,80006b20 <sys_open+0x60>
    80006be0:	f4c42783          	lw	a5,-180(s0)
    80006be4:	dba1                	beqz	a5,80006b34 <sys_open+0x74>
      iunlockput(ip);
    80006be6:	854a                	mv	a0,s2
    80006be8:	ffffe097          	auipc	ra,0xffffe
    80006bec:	172080e7          	jalr	370(ra) # 80004d5a <iunlockput>
      end_op();
    80006bf0:	fffff097          	auipc	ra,0xfffff
    80006bf4:	95c080e7          	jalr	-1700(ra) # 8000554c <end_op>
      return -1;
    80006bf8:	54fd                	li	s1,-1
    80006bfa:	b76d                	j	80006ba4 <sys_open+0xe4>
      end_op();
    80006bfc:	fffff097          	auipc	ra,0xfffff
    80006c00:	950080e7          	jalr	-1712(ra) # 8000554c <end_op>
      return -1;
    80006c04:	54fd                	li	s1,-1
    80006c06:	bf79                	j	80006ba4 <sys_open+0xe4>
    iunlockput(ip);
    80006c08:	854a                	mv	a0,s2
    80006c0a:	ffffe097          	auipc	ra,0xffffe
    80006c0e:	150080e7          	jalr	336(ra) # 80004d5a <iunlockput>
    end_op();
    80006c12:	fffff097          	auipc	ra,0xfffff
    80006c16:	93a080e7          	jalr	-1734(ra) # 8000554c <end_op>
    return -1;
    80006c1a:	54fd                	li	s1,-1
    80006c1c:	b761                	j	80006ba4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006c1e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006c22:	04691783          	lh	a5,70(s2)
    80006c26:	02f99223          	sh	a5,36(s3)
    80006c2a:	bf2d                	j	80006b64 <sys_open+0xa4>
    itrunc(ip);
    80006c2c:	854a                	mv	a0,s2
    80006c2e:	ffffe097          	auipc	ra,0xffffe
    80006c32:	fd8080e7          	jalr	-40(ra) # 80004c06 <itrunc>
    80006c36:	bfb1                	j	80006b92 <sys_open+0xd2>
      fileclose(f);
    80006c38:	854e                	mv	a0,s3
    80006c3a:	fffff097          	auipc	ra,0xfffff
    80006c3e:	d5e080e7          	jalr	-674(ra) # 80005998 <fileclose>
    iunlockput(ip);
    80006c42:	854a                	mv	a0,s2
    80006c44:	ffffe097          	auipc	ra,0xffffe
    80006c48:	116080e7          	jalr	278(ra) # 80004d5a <iunlockput>
    end_op();
    80006c4c:	fffff097          	auipc	ra,0xfffff
    80006c50:	900080e7          	jalr	-1792(ra) # 8000554c <end_op>
    return -1;
    80006c54:	54fd                	li	s1,-1
    80006c56:	b7b9                	j	80006ba4 <sys_open+0xe4>

0000000080006c58 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006c58:	7175                	addi	sp,sp,-144
    80006c5a:	e506                	sd	ra,136(sp)
    80006c5c:	e122                	sd	s0,128(sp)
    80006c5e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006c60:	fffff097          	auipc	ra,0xfffff
    80006c64:	86c080e7          	jalr	-1940(ra) # 800054cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006c68:	08000613          	li	a2,128
    80006c6c:	f7040593          	addi	a1,s0,-144
    80006c70:	4501                	li	a0,0
    80006c72:	ffffd097          	auipc	ra,0xffffd
    80006c76:	0f6080e7          	jalr	246(ra) # 80003d68 <argstr>
    80006c7a:	02054963          	bltz	a0,80006cac <sys_mkdir+0x54>
    80006c7e:	4681                	li	a3,0
    80006c80:	4601                	li	a2,0
    80006c82:	4585                	li	a1,1
    80006c84:	f7040513          	addi	a0,s0,-144
    80006c88:	00000097          	auipc	ra,0x0
    80006c8c:	800080e7          	jalr	-2048(ra) # 80006488 <create>
    80006c90:	cd11                	beqz	a0,80006cac <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006c92:	ffffe097          	auipc	ra,0xffffe
    80006c96:	0c8080e7          	jalr	200(ra) # 80004d5a <iunlockput>
  end_op();
    80006c9a:	fffff097          	auipc	ra,0xfffff
    80006c9e:	8b2080e7          	jalr	-1870(ra) # 8000554c <end_op>
  return 0;
    80006ca2:	4501                	li	a0,0
}
    80006ca4:	60aa                	ld	ra,136(sp)
    80006ca6:	640a                	ld	s0,128(sp)
    80006ca8:	6149                	addi	sp,sp,144
    80006caa:	8082                	ret
    end_op();
    80006cac:	fffff097          	auipc	ra,0xfffff
    80006cb0:	8a0080e7          	jalr	-1888(ra) # 8000554c <end_op>
    return -1;
    80006cb4:	557d                	li	a0,-1
    80006cb6:	b7fd                	j	80006ca4 <sys_mkdir+0x4c>

0000000080006cb8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006cb8:	7135                	addi	sp,sp,-160
    80006cba:	ed06                	sd	ra,152(sp)
    80006cbc:	e922                	sd	s0,144(sp)
    80006cbe:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006cc0:	fffff097          	auipc	ra,0xfffff
    80006cc4:	80c080e7          	jalr	-2036(ra) # 800054cc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006cc8:	08000613          	li	a2,128
    80006ccc:	f7040593          	addi	a1,s0,-144
    80006cd0:	4501                	li	a0,0
    80006cd2:	ffffd097          	auipc	ra,0xffffd
    80006cd6:	096080e7          	jalr	150(ra) # 80003d68 <argstr>
    80006cda:	04054a63          	bltz	a0,80006d2e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006cde:	f6c40593          	addi	a1,s0,-148
    80006ce2:	4505                	li	a0,1
    80006ce4:	ffffd097          	auipc	ra,0xffffd
    80006ce8:	040080e7          	jalr	64(ra) # 80003d24 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006cec:	04054163          	bltz	a0,80006d2e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006cf0:	f6840593          	addi	a1,s0,-152
    80006cf4:	4509                	li	a0,2
    80006cf6:	ffffd097          	auipc	ra,0xffffd
    80006cfa:	02e080e7          	jalr	46(ra) # 80003d24 <argint>
     argint(1, &major) < 0 ||
    80006cfe:	02054863          	bltz	a0,80006d2e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006d02:	f6841683          	lh	a3,-152(s0)
    80006d06:	f6c41603          	lh	a2,-148(s0)
    80006d0a:	458d                	li	a1,3
    80006d0c:	f7040513          	addi	a0,s0,-144
    80006d10:	fffff097          	auipc	ra,0xfffff
    80006d14:	778080e7          	jalr	1912(ra) # 80006488 <create>
     argint(2, &minor) < 0 ||
    80006d18:	c919                	beqz	a0,80006d2e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006d1a:	ffffe097          	auipc	ra,0xffffe
    80006d1e:	040080e7          	jalr	64(ra) # 80004d5a <iunlockput>
  end_op();
    80006d22:	fffff097          	auipc	ra,0xfffff
    80006d26:	82a080e7          	jalr	-2006(ra) # 8000554c <end_op>
  return 0;
    80006d2a:	4501                	li	a0,0
    80006d2c:	a031                	j	80006d38 <sys_mknod+0x80>
    end_op();
    80006d2e:	fffff097          	auipc	ra,0xfffff
    80006d32:	81e080e7          	jalr	-2018(ra) # 8000554c <end_op>
    return -1;
    80006d36:	557d                	li	a0,-1
}
    80006d38:	60ea                	ld	ra,152(sp)
    80006d3a:	644a                	ld	s0,144(sp)
    80006d3c:	610d                	addi	sp,sp,160
    80006d3e:	8082                	ret

0000000080006d40 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006d40:	7135                	addi	sp,sp,-160
    80006d42:	ed06                	sd	ra,152(sp)
    80006d44:	e922                	sd	s0,144(sp)
    80006d46:	e526                	sd	s1,136(sp)
    80006d48:	e14a                	sd	s2,128(sp)
    80006d4a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006d4c:	ffffb097          	auipc	ra,0xffffb
    80006d50:	dfa080e7          	jalr	-518(ra) # 80001b46 <myproc>
    80006d54:	892a                	mv	s2,a0
  
  begin_op();
    80006d56:	ffffe097          	auipc	ra,0xffffe
    80006d5a:	776080e7          	jalr	1910(ra) # 800054cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006d5e:	08000613          	li	a2,128
    80006d62:	f6040593          	addi	a1,s0,-160
    80006d66:	4501                	li	a0,0
    80006d68:	ffffd097          	auipc	ra,0xffffd
    80006d6c:	000080e7          	jalr	ra # 80003d68 <argstr>
    80006d70:	04054b63          	bltz	a0,80006dc6 <sys_chdir+0x86>
    80006d74:	f6040513          	addi	a0,s0,-160
    80006d78:	ffffe097          	auipc	ra,0xffffe
    80006d7c:	534080e7          	jalr	1332(ra) # 800052ac <namei>
    80006d80:	84aa                	mv	s1,a0
    80006d82:	c131                	beqz	a0,80006dc6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006d84:	ffffe097          	auipc	ra,0xffffe
    80006d88:	d74080e7          	jalr	-652(ra) # 80004af8 <ilock>
  if(ip->type != T_DIR){
    80006d8c:	04449703          	lh	a4,68(s1)
    80006d90:	4785                	li	a5,1
    80006d92:	04f71063          	bne	a4,a5,80006dd2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006d96:	8526                	mv	a0,s1
    80006d98:	ffffe097          	auipc	ra,0xffffe
    80006d9c:	e22080e7          	jalr	-478(ra) # 80004bba <iunlock>
  iput(p->cwd);
    80006da0:	0c893503          	ld	a0,200(s2)
    80006da4:	ffffe097          	auipc	ra,0xffffe
    80006da8:	f0e080e7          	jalr	-242(ra) # 80004cb2 <iput>
  end_op();
    80006dac:	ffffe097          	auipc	ra,0xffffe
    80006db0:	7a0080e7          	jalr	1952(ra) # 8000554c <end_op>
  p->cwd = ip;
    80006db4:	0c993423          	sd	s1,200(s2)
  return 0;
    80006db8:	4501                	li	a0,0
}
    80006dba:	60ea                	ld	ra,152(sp)
    80006dbc:	644a                	ld	s0,144(sp)
    80006dbe:	64aa                	ld	s1,136(sp)
    80006dc0:	690a                	ld	s2,128(sp)
    80006dc2:	610d                	addi	sp,sp,160
    80006dc4:	8082                	ret
    end_op();
    80006dc6:	ffffe097          	auipc	ra,0xffffe
    80006dca:	786080e7          	jalr	1926(ra) # 8000554c <end_op>
    return -1;
    80006dce:	557d                	li	a0,-1
    80006dd0:	b7ed                	j	80006dba <sys_chdir+0x7a>
    iunlockput(ip);
    80006dd2:	8526                	mv	a0,s1
    80006dd4:	ffffe097          	auipc	ra,0xffffe
    80006dd8:	f86080e7          	jalr	-122(ra) # 80004d5a <iunlockput>
    end_op();
    80006ddc:	ffffe097          	auipc	ra,0xffffe
    80006de0:	770080e7          	jalr	1904(ra) # 8000554c <end_op>
    return -1;
    80006de4:	557d                	li	a0,-1
    80006de6:	bfd1                	j	80006dba <sys_chdir+0x7a>

0000000080006de8 <sys_exec>:

uint64
sys_exec(void)
{
    80006de8:	7145                	addi	sp,sp,-464
    80006dea:	e786                	sd	ra,456(sp)
    80006dec:	e3a2                	sd	s0,448(sp)
    80006dee:	ff26                	sd	s1,440(sp)
    80006df0:	fb4a                	sd	s2,432(sp)
    80006df2:	f74e                	sd	s3,424(sp)
    80006df4:	f352                	sd	s4,416(sp)
    80006df6:	ef56                	sd	s5,408(sp)
    80006df8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006dfa:	08000613          	li	a2,128
    80006dfe:	f4040593          	addi	a1,s0,-192
    80006e02:	4501                	li	a0,0
    80006e04:	ffffd097          	auipc	ra,0xffffd
    80006e08:	f64080e7          	jalr	-156(ra) # 80003d68 <argstr>
    return -1;
    80006e0c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006e0e:	0c054a63          	bltz	a0,80006ee2 <sys_exec+0xfa>
    80006e12:	e3840593          	addi	a1,s0,-456
    80006e16:	4505                	li	a0,1
    80006e18:	ffffd097          	auipc	ra,0xffffd
    80006e1c:	f2e080e7          	jalr	-210(ra) # 80003d46 <argaddr>
    80006e20:	0c054163          	bltz	a0,80006ee2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006e24:	10000613          	li	a2,256
    80006e28:	4581                	li	a1,0
    80006e2a:	e4040513          	addi	a0,s0,-448
    80006e2e:	ffffa097          	auipc	ra,0xffffa
    80006e32:	f1c080e7          	jalr	-228(ra) # 80000d4a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006e36:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006e3a:	89a6                	mv	s3,s1
    80006e3c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006e3e:	02000a13          	li	s4,32
    80006e42:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006e46:	00391793          	slli	a5,s2,0x3
    80006e4a:	e3040593          	addi	a1,s0,-464
    80006e4e:	e3843503          	ld	a0,-456(s0)
    80006e52:	953e                	add	a0,a0,a5
    80006e54:	ffffd097          	auipc	ra,0xffffd
    80006e58:	e36080e7          	jalr	-458(ra) # 80003c8a <fetchaddr>
    80006e5c:	02054a63          	bltz	a0,80006e90 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006e60:	e3043783          	ld	a5,-464(s0)
    80006e64:	c3b9                	beqz	a5,80006eaa <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006e66:	ffffa097          	auipc	ra,0xffffa
    80006e6a:	c8c080e7          	jalr	-884(ra) # 80000af2 <kalloc>
    80006e6e:	85aa                	mv	a1,a0
    80006e70:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006e74:	cd11                	beqz	a0,80006e90 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006e76:	6605                	lui	a2,0x1
    80006e78:	e3043503          	ld	a0,-464(s0)
    80006e7c:	ffffd097          	auipc	ra,0xffffd
    80006e80:	e60080e7          	jalr	-416(ra) # 80003cdc <fetchstr>
    80006e84:	00054663          	bltz	a0,80006e90 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006e88:	0905                	addi	s2,s2,1
    80006e8a:	09a1                	addi	s3,s3,8
    80006e8c:	fb491be3          	bne	s2,s4,80006e42 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006e90:	10048913          	addi	s2,s1,256
    80006e94:	6088                	ld	a0,0(s1)
    80006e96:	c529                	beqz	a0,80006ee0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006e98:	ffffa097          	auipc	ra,0xffffa
    80006e9c:	b3e080e7          	jalr	-1218(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006ea0:	04a1                	addi	s1,s1,8
    80006ea2:	ff2499e3          	bne	s1,s2,80006e94 <sys_exec+0xac>
  return -1;
    80006ea6:	597d                	li	s2,-1
    80006ea8:	a82d                	j	80006ee2 <sys_exec+0xfa>
      argv[i] = 0;
    80006eaa:	0a8e                	slli	s5,s5,0x3
    80006eac:	fc040793          	addi	a5,s0,-64
    80006eb0:	9abe                	add	s5,s5,a5
    80006eb2:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffaae80>
  int ret = exec(path, argv);
    80006eb6:	e4040593          	addi	a1,s0,-448
    80006eba:	f4040513          	addi	a0,s0,-192
    80006ebe:	fffff097          	auipc	ra,0xfffff
    80006ec2:	12c080e7          	jalr	300(ra) # 80005fea <exec>
    80006ec6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006ec8:	10048993          	addi	s3,s1,256
    80006ecc:	6088                	ld	a0,0(s1)
    80006ece:	c911                	beqz	a0,80006ee2 <sys_exec+0xfa>
    kfree(argv[i]);
    80006ed0:	ffffa097          	auipc	ra,0xffffa
    80006ed4:	b06080e7          	jalr	-1274(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006ed8:	04a1                	addi	s1,s1,8
    80006eda:	ff3499e3          	bne	s1,s3,80006ecc <sys_exec+0xe4>
    80006ede:	a011                	j	80006ee2 <sys_exec+0xfa>
  return -1;
    80006ee0:	597d                	li	s2,-1
}
    80006ee2:	854a                	mv	a0,s2
    80006ee4:	60be                	ld	ra,456(sp)
    80006ee6:	641e                	ld	s0,448(sp)
    80006ee8:	74fa                	ld	s1,440(sp)
    80006eea:	795a                	ld	s2,432(sp)
    80006eec:	79ba                	ld	s3,424(sp)
    80006eee:	7a1a                	ld	s4,416(sp)
    80006ef0:	6afa                	ld	s5,408(sp)
    80006ef2:	6179                	addi	sp,sp,464
    80006ef4:	8082                	ret

0000000080006ef6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006ef6:	7139                	addi	sp,sp,-64
    80006ef8:	fc06                	sd	ra,56(sp)
    80006efa:	f822                	sd	s0,48(sp)
    80006efc:	f426                	sd	s1,40(sp)
    80006efe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006f00:	ffffb097          	auipc	ra,0xffffb
    80006f04:	c46080e7          	jalr	-954(ra) # 80001b46 <myproc>
    80006f08:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006f0a:	fd840593          	addi	a1,s0,-40
    80006f0e:	4501                	li	a0,0
    80006f10:	ffffd097          	auipc	ra,0xffffd
    80006f14:	e36080e7          	jalr	-458(ra) # 80003d46 <argaddr>
    return -1;
    80006f18:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006f1a:	0e054063          	bltz	a0,80006ffa <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006f1e:	fc840593          	addi	a1,s0,-56
    80006f22:	fd040513          	addi	a0,s0,-48
    80006f26:	fffff097          	auipc	ra,0xfffff
    80006f2a:	da2080e7          	jalr	-606(ra) # 80005cc8 <pipealloc>
    return -1;
    80006f2e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006f30:	0c054563          	bltz	a0,80006ffa <sys_pipe+0x104>
  fd0 = -1;
    80006f34:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006f38:	fd043503          	ld	a0,-48(s0)
    80006f3c:	fffff097          	auipc	ra,0xfffff
    80006f40:	50a080e7          	jalr	1290(ra) # 80006446 <fdalloc>
    80006f44:	fca42223          	sw	a0,-60(s0)
    80006f48:	08054c63          	bltz	a0,80006fe0 <sys_pipe+0xea>
    80006f4c:	fc843503          	ld	a0,-56(s0)
    80006f50:	fffff097          	auipc	ra,0xfffff
    80006f54:	4f6080e7          	jalr	1270(ra) # 80006446 <fdalloc>
    80006f58:	fca42023          	sw	a0,-64(s0)
    80006f5c:	06054863          	bltz	a0,80006fcc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006f60:	4691                	li	a3,4
    80006f62:	fc440613          	addi	a2,s0,-60
    80006f66:	fd843583          	ld	a1,-40(s0)
    80006f6a:	7c88                	ld	a0,56(s1)
    80006f6c:	ffffa097          	auipc	ra,0xffffa
    80006f70:	75e080e7          	jalr	1886(ra) # 800016ca <copyout>
    80006f74:	02054063          	bltz	a0,80006f94 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006f78:	4691                	li	a3,4
    80006f7a:	fc040613          	addi	a2,s0,-64
    80006f7e:	fd843583          	ld	a1,-40(s0)
    80006f82:	0591                	addi	a1,a1,4
    80006f84:	7c88                	ld	a0,56(s1)
    80006f86:	ffffa097          	auipc	ra,0xffffa
    80006f8a:	744080e7          	jalr	1860(ra) # 800016ca <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006f8e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006f90:	06055563          	bgez	a0,80006ffa <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006f94:	fc442783          	lw	a5,-60(s0)
    80006f98:	07a1                	addi	a5,a5,8
    80006f9a:	078e                	slli	a5,a5,0x3
    80006f9c:	97a6                	add	a5,a5,s1
    80006f9e:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006fa2:	fc042503          	lw	a0,-64(s0)
    80006fa6:	0521                	addi	a0,a0,8
    80006fa8:	050e                	slli	a0,a0,0x3
    80006faa:	9526                	add	a0,a0,s1
    80006fac:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006fb0:	fd043503          	ld	a0,-48(s0)
    80006fb4:	fffff097          	auipc	ra,0xfffff
    80006fb8:	9e4080e7          	jalr	-1564(ra) # 80005998 <fileclose>
    fileclose(wf);
    80006fbc:	fc843503          	ld	a0,-56(s0)
    80006fc0:	fffff097          	auipc	ra,0xfffff
    80006fc4:	9d8080e7          	jalr	-1576(ra) # 80005998 <fileclose>
    return -1;
    80006fc8:	57fd                	li	a5,-1
    80006fca:	a805                	j	80006ffa <sys_pipe+0x104>
    if(fd0 >= 0)
    80006fcc:	fc442783          	lw	a5,-60(s0)
    80006fd0:	0007c863          	bltz	a5,80006fe0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006fd4:	00878513          	addi	a0,a5,8
    80006fd8:	050e                	slli	a0,a0,0x3
    80006fda:	9526                	add	a0,a0,s1
    80006fdc:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80006fe0:	fd043503          	ld	a0,-48(s0)
    80006fe4:	fffff097          	auipc	ra,0xfffff
    80006fe8:	9b4080e7          	jalr	-1612(ra) # 80005998 <fileclose>
    fileclose(wf);
    80006fec:	fc843503          	ld	a0,-56(s0)
    80006ff0:	fffff097          	auipc	ra,0xfffff
    80006ff4:	9a8080e7          	jalr	-1624(ra) # 80005998 <fileclose>
    return -1;
    80006ff8:	57fd                	li	a5,-1
}
    80006ffa:	853e                	mv	a0,a5
    80006ffc:	70e2                	ld	ra,56(sp)
    80006ffe:	7442                	ld	s0,48(sp)
    80007000:	74a2                	ld	s1,40(sp)
    80007002:	6121                	addi	sp,sp,64
    80007004:	8082                	ret
	...

0000000080007010 <kernelvec>:
    80007010:	7111                	addi	sp,sp,-256
    80007012:	e006                	sd	ra,0(sp)
    80007014:	e40a                	sd	sp,8(sp)
    80007016:	e80e                	sd	gp,16(sp)
    80007018:	ec12                	sd	tp,24(sp)
    8000701a:	f016                	sd	t0,32(sp)
    8000701c:	f41a                	sd	t1,40(sp)
    8000701e:	f81e                	sd	t2,48(sp)
    80007020:	fc22                	sd	s0,56(sp)
    80007022:	e0a6                	sd	s1,64(sp)
    80007024:	e4aa                	sd	a0,72(sp)
    80007026:	e8ae                	sd	a1,80(sp)
    80007028:	ecb2                	sd	a2,88(sp)
    8000702a:	f0b6                	sd	a3,96(sp)
    8000702c:	f4ba                	sd	a4,104(sp)
    8000702e:	f8be                	sd	a5,112(sp)
    80007030:	fcc2                	sd	a6,120(sp)
    80007032:	e146                	sd	a7,128(sp)
    80007034:	e54a                	sd	s2,136(sp)
    80007036:	e94e                	sd	s3,144(sp)
    80007038:	ed52                	sd	s4,152(sp)
    8000703a:	f156                	sd	s5,160(sp)
    8000703c:	f55a                	sd	s6,168(sp)
    8000703e:	f95e                	sd	s7,176(sp)
    80007040:	fd62                	sd	s8,184(sp)
    80007042:	e1e6                	sd	s9,192(sp)
    80007044:	e5ea                	sd	s10,200(sp)
    80007046:	e9ee                	sd	s11,208(sp)
    80007048:	edf2                	sd	t3,216(sp)
    8000704a:	f1f6                	sd	t4,224(sp)
    8000704c:	f5fa                	sd	t5,232(sp)
    8000704e:	f9fe                	sd	t6,240(sp)
    80007050:	b07fc0ef          	jal	ra,80003b56 <kerneltrap>
    80007054:	6082                	ld	ra,0(sp)
    80007056:	6122                	ld	sp,8(sp)
    80007058:	61c2                	ld	gp,16(sp)
    8000705a:	7282                	ld	t0,32(sp)
    8000705c:	7322                	ld	t1,40(sp)
    8000705e:	73c2                	ld	t2,48(sp)
    80007060:	7462                	ld	s0,56(sp)
    80007062:	6486                	ld	s1,64(sp)
    80007064:	6526                	ld	a0,72(sp)
    80007066:	65c6                	ld	a1,80(sp)
    80007068:	6666                	ld	a2,88(sp)
    8000706a:	7686                	ld	a3,96(sp)
    8000706c:	7726                	ld	a4,104(sp)
    8000706e:	77c6                	ld	a5,112(sp)
    80007070:	7866                	ld	a6,120(sp)
    80007072:	688a                	ld	a7,128(sp)
    80007074:	692a                	ld	s2,136(sp)
    80007076:	69ca                	ld	s3,144(sp)
    80007078:	6a6a                	ld	s4,152(sp)
    8000707a:	7a8a                	ld	s5,160(sp)
    8000707c:	7b2a                	ld	s6,168(sp)
    8000707e:	7bca                	ld	s7,176(sp)
    80007080:	7c6a                	ld	s8,184(sp)
    80007082:	6c8e                	ld	s9,192(sp)
    80007084:	6d2e                	ld	s10,200(sp)
    80007086:	6dce                	ld	s11,208(sp)
    80007088:	6e6e                	ld	t3,216(sp)
    8000708a:	7e8e                	ld	t4,224(sp)
    8000708c:	7f2e                	ld	t5,232(sp)
    8000708e:	7fce                	ld	t6,240(sp)
    80007090:	6111                	addi	sp,sp,256
    80007092:	10200073          	sret
    80007096:	00000013          	nop
    8000709a:	00000013          	nop
    8000709e:	0001                	nop

00000000800070a0 <timervec>:
    800070a0:	34051573          	csrrw	a0,mscratch,a0
    800070a4:	e10c                	sd	a1,0(a0)
    800070a6:	e510                	sd	a2,8(a0)
    800070a8:	e914                	sd	a3,16(a0)
    800070aa:	6d0c                	ld	a1,24(a0)
    800070ac:	7110                	ld	a2,32(a0)
    800070ae:	6194                	ld	a3,0(a1)
    800070b0:	96b2                	add	a3,a3,a2
    800070b2:	e194                	sd	a3,0(a1)
    800070b4:	4589                	li	a1,2
    800070b6:	14459073          	csrw	sip,a1
    800070ba:	6914                	ld	a3,16(a0)
    800070bc:	6510                	ld	a2,8(a0)
    800070be:	610c                	ld	a1,0(a0)
    800070c0:	34051573          	csrrw	a0,mscratch,a0
    800070c4:	30200073          	mret
	...

00000000800070ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800070ca:	1141                	addi	sp,sp,-16
    800070cc:	e422                	sd	s0,8(sp)
    800070ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800070d0:	0c0007b7          	lui	a5,0xc000
    800070d4:	4705                	li	a4,1
    800070d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800070d8:	c3d8                	sw	a4,4(a5)
}
    800070da:	6422                	ld	s0,8(sp)
    800070dc:	0141                	addi	sp,sp,16
    800070de:	8082                	ret

00000000800070e0 <plicinithart>:

void
plicinithart(void)
{
    800070e0:	1141                	addi	sp,sp,-16
    800070e2:	e406                	sd	ra,8(sp)
    800070e4:	e022                	sd	s0,0(sp)
    800070e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800070e8:	ffffb097          	auipc	ra,0xffffb
    800070ec:	9a0080e7          	jalr	-1632(ra) # 80001a88 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800070f0:	0085171b          	slliw	a4,a0,0x8
    800070f4:	0c0027b7          	lui	a5,0xc002
    800070f8:	97ba                	add	a5,a5,a4
    800070fa:	40200713          	li	a4,1026
    800070fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80007102:	00d5151b          	slliw	a0,a0,0xd
    80007106:	0c2017b7          	lui	a5,0xc201
    8000710a:	953e                	add	a0,a0,a5
    8000710c:	00052023          	sw	zero,0(a0)
}
    80007110:	60a2                	ld	ra,8(sp)
    80007112:	6402                	ld	s0,0(sp)
    80007114:	0141                	addi	sp,sp,16
    80007116:	8082                	ret

0000000080007118 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80007118:	1141                	addi	sp,sp,-16
    8000711a:	e406                	sd	ra,8(sp)
    8000711c:	e022                	sd	s0,0(sp)
    8000711e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80007120:	ffffb097          	auipc	ra,0xffffb
    80007124:	968080e7          	jalr	-1688(ra) # 80001a88 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80007128:	00d5179b          	slliw	a5,a0,0xd
    8000712c:	0c201537          	lui	a0,0xc201
    80007130:	953e                	add	a0,a0,a5
  return irq;
}
    80007132:	4148                	lw	a0,4(a0)
    80007134:	60a2                	ld	ra,8(sp)
    80007136:	6402                	ld	s0,0(sp)
    80007138:	0141                	addi	sp,sp,16
    8000713a:	8082                	ret

000000008000713c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000713c:	1101                	addi	sp,sp,-32
    8000713e:	ec06                	sd	ra,24(sp)
    80007140:	e822                	sd	s0,16(sp)
    80007142:	e426                	sd	s1,8(sp)
    80007144:	1000                	addi	s0,sp,32
    80007146:	84aa                	mv	s1,a0
  int hart = cpuid();
    80007148:	ffffb097          	auipc	ra,0xffffb
    8000714c:	940080e7          	jalr	-1728(ra) # 80001a88 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80007150:	00d5151b          	slliw	a0,a0,0xd
    80007154:	0c2017b7          	lui	a5,0xc201
    80007158:	97aa                	add	a5,a5,a0
    8000715a:	c3c4                	sw	s1,4(a5)
}
    8000715c:	60e2                	ld	ra,24(sp)
    8000715e:	6442                	ld	s0,16(sp)
    80007160:	64a2                	ld	s1,8(sp)
    80007162:	6105                	addi	sp,sp,32
    80007164:	8082                	ret

0000000080007166 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80007166:	1141                	addi	sp,sp,-16
    80007168:	e406                	sd	ra,8(sp)
    8000716a:	e022                	sd	s0,0(sp)
    8000716c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000716e:	479d                	li	a5,7
    80007170:	06a7c963          	blt	a5,a0,800071e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80007174:	0004a797          	auipc	a5,0x4a
    80007178:	e8c78793          	addi	a5,a5,-372 # 80051000 <disk>
    8000717c:	00a78733          	add	a4,a5,a0
    80007180:	6789                	lui	a5,0x2
    80007182:	97ba                	add	a5,a5,a4
    80007184:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80007188:	e7ad                	bnez	a5,800071f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000718a:	00451793          	slli	a5,a0,0x4
    8000718e:	0004c717          	auipc	a4,0x4c
    80007192:	e7270713          	addi	a4,a4,-398 # 80053000 <disk+0x2000>
    80007196:	6314                	ld	a3,0(a4)
    80007198:	96be                	add	a3,a3,a5
    8000719a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000719e:	6314                	ld	a3,0(a4)
    800071a0:	96be                	add	a3,a3,a5
    800071a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800071a6:	6314                	ld	a3,0(a4)
    800071a8:	96be                	add	a3,a3,a5
    800071aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800071ae:	6318                	ld	a4,0(a4)
    800071b0:	97ba                	add	a5,a5,a4
    800071b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800071b6:	0004a797          	auipc	a5,0x4a
    800071ba:	e4a78793          	addi	a5,a5,-438 # 80051000 <disk>
    800071be:	97aa                	add	a5,a5,a0
    800071c0:	6509                	lui	a0,0x2
    800071c2:	953e                	add	a0,a0,a5
    800071c4:	4785                	li	a5,1
    800071c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800071ca:	0004c517          	auipc	a0,0x4c
    800071ce:	e4e50513          	addi	a0,a0,-434 # 80053018 <disk+0x2018>
    800071d2:	ffffc097          	auipc	ra,0xffffc
    800071d6:	866080e7          	jalr	-1946(ra) # 80002a38 <wakeup>
}
    800071da:	60a2                	ld	ra,8(sp)
    800071dc:	6402                	ld	s0,0(sp)
    800071de:	0141                	addi	sp,sp,16
    800071e0:	8082                	ret
    panic("free_desc 1");
    800071e2:	00002517          	auipc	a0,0x2
    800071e6:	64e50513          	addi	a0,a0,1614 # 80009830 <syscalls+0x378>
    800071ea:	ffff9097          	auipc	ra,0xffff9
    800071ee:	340080e7          	jalr	832(ra) # 8000052a <panic>
    panic("free_desc 2");
    800071f2:	00002517          	auipc	a0,0x2
    800071f6:	64e50513          	addi	a0,a0,1614 # 80009840 <syscalls+0x388>
    800071fa:	ffff9097          	auipc	ra,0xffff9
    800071fe:	330080e7          	jalr	816(ra) # 8000052a <panic>

0000000080007202 <virtio_disk_init>:
{
    80007202:	1101                	addi	sp,sp,-32
    80007204:	ec06                	sd	ra,24(sp)
    80007206:	e822                	sd	s0,16(sp)
    80007208:	e426                	sd	s1,8(sp)
    8000720a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000720c:	00002597          	auipc	a1,0x2
    80007210:	64458593          	addi	a1,a1,1604 # 80009850 <syscalls+0x398>
    80007214:	0004c517          	auipc	a0,0x4c
    80007218:	f1450513          	addi	a0,a0,-236 # 80053128 <disk+0x2128>
    8000721c:	ffffa097          	auipc	ra,0xffffa
    80007220:	936080e7          	jalr	-1738(ra) # 80000b52 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80007224:	100017b7          	lui	a5,0x10001
    80007228:	4398                	lw	a4,0(a5)
    8000722a:	2701                	sext.w	a4,a4
    8000722c:	747277b7          	lui	a5,0x74727
    80007230:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80007234:	0ef71163          	bne	a4,a5,80007316 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80007238:	100017b7          	lui	a5,0x10001
    8000723c:	43dc                	lw	a5,4(a5)
    8000723e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80007240:	4705                	li	a4,1
    80007242:	0ce79a63          	bne	a5,a4,80007316 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80007246:	100017b7          	lui	a5,0x10001
    8000724a:	479c                	lw	a5,8(a5)
    8000724c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000724e:	4709                	li	a4,2
    80007250:	0ce79363          	bne	a5,a4,80007316 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80007254:	100017b7          	lui	a5,0x10001
    80007258:	47d8                	lw	a4,12(a5)
    8000725a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000725c:	554d47b7          	lui	a5,0x554d4
    80007260:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80007264:	0af71963          	bne	a4,a5,80007316 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80007268:	100017b7          	lui	a5,0x10001
    8000726c:	4705                	li	a4,1
    8000726e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007270:	470d                	li	a4,3
    80007272:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80007274:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80007276:	c7ffe737          	lui	a4,0xc7ffe
    8000727a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47faa75f>
    8000727e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80007280:	2701                	sext.w	a4,a4
    80007282:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007284:	472d                	li	a4,11
    80007286:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80007288:	473d                	li	a4,15
    8000728a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000728c:	6705                	lui	a4,0x1
    8000728e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80007290:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80007294:	5bdc                	lw	a5,52(a5)
    80007296:	2781                	sext.w	a5,a5
  if(max == 0)
    80007298:	c7d9                	beqz	a5,80007326 <virtio_disk_init+0x124>
  if(max < NUM)
    8000729a:	471d                	li	a4,7
    8000729c:	08f77d63          	bgeu	a4,a5,80007336 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800072a0:	100014b7          	lui	s1,0x10001
    800072a4:	47a1                	li	a5,8
    800072a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800072a8:	6609                	lui	a2,0x2
    800072aa:	4581                	li	a1,0
    800072ac:	0004a517          	auipc	a0,0x4a
    800072b0:	d5450513          	addi	a0,a0,-684 # 80051000 <disk>
    800072b4:	ffffa097          	auipc	ra,0xffffa
    800072b8:	a96080e7          	jalr	-1386(ra) # 80000d4a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800072bc:	0004a717          	auipc	a4,0x4a
    800072c0:	d4470713          	addi	a4,a4,-700 # 80051000 <disk>
    800072c4:	00c75793          	srli	a5,a4,0xc
    800072c8:	2781                	sext.w	a5,a5
    800072ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800072cc:	0004c797          	auipc	a5,0x4c
    800072d0:	d3478793          	addi	a5,a5,-716 # 80053000 <disk+0x2000>
    800072d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800072d6:	0004a717          	auipc	a4,0x4a
    800072da:	daa70713          	addi	a4,a4,-598 # 80051080 <disk+0x80>
    800072de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800072e0:	0004b717          	auipc	a4,0x4b
    800072e4:	d2070713          	addi	a4,a4,-736 # 80052000 <disk+0x1000>
    800072e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800072ea:	4705                	li	a4,1
    800072ec:	00e78c23          	sb	a4,24(a5)
    800072f0:	00e78ca3          	sb	a4,25(a5)
    800072f4:	00e78d23          	sb	a4,26(a5)
    800072f8:	00e78da3          	sb	a4,27(a5)
    800072fc:	00e78e23          	sb	a4,28(a5)
    80007300:	00e78ea3          	sb	a4,29(a5)
    80007304:	00e78f23          	sb	a4,30(a5)
    80007308:	00e78fa3          	sb	a4,31(a5)
}
    8000730c:	60e2                	ld	ra,24(sp)
    8000730e:	6442                	ld	s0,16(sp)
    80007310:	64a2                	ld	s1,8(sp)
    80007312:	6105                	addi	sp,sp,32
    80007314:	8082                	ret
    panic("could not find virtio disk");
    80007316:	00002517          	auipc	a0,0x2
    8000731a:	54a50513          	addi	a0,a0,1354 # 80009860 <syscalls+0x3a8>
    8000731e:	ffff9097          	auipc	ra,0xffff9
    80007322:	20c080e7          	jalr	524(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80007326:	00002517          	auipc	a0,0x2
    8000732a:	55a50513          	addi	a0,a0,1370 # 80009880 <syscalls+0x3c8>
    8000732e:	ffff9097          	auipc	ra,0xffff9
    80007332:	1fc080e7          	jalr	508(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80007336:	00002517          	auipc	a0,0x2
    8000733a:	56a50513          	addi	a0,a0,1386 # 800098a0 <syscalls+0x3e8>
    8000733e:	ffff9097          	auipc	ra,0xffff9
    80007342:	1ec080e7          	jalr	492(ra) # 8000052a <panic>

0000000080007346 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80007346:	7119                	addi	sp,sp,-128
    80007348:	fc86                	sd	ra,120(sp)
    8000734a:	f8a2                	sd	s0,112(sp)
    8000734c:	f4a6                	sd	s1,104(sp)
    8000734e:	f0ca                	sd	s2,96(sp)
    80007350:	ecce                	sd	s3,88(sp)
    80007352:	e8d2                	sd	s4,80(sp)
    80007354:	e4d6                	sd	s5,72(sp)
    80007356:	e0da                	sd	s6,64(sp)
    80007358:	fc5e                	sd	s7,56(sp)
    8000735a:	f862                	sd	s8,48(sp)
    8000735c:	f466                	sd	s9,40(sp)
    8000735e:	f06a                	sd	s10,32(sp)
    80007360:	ec6e                	sd	s11,24(sp)
    80007362:	0100                	addi	s0,sp,128
    80007364:	8aaa                	mv	s5,a0
    80007366:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80007368:	00c52c83          	lw	s9,12(a0)
    8000736c:	001c9c9b          	slliw	s9,s9,0x1
    80007370:	1c82                	slli	s9,s9,0x20
    80007372:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80007376:	0004c517          	auipc	a0,0x4c
    8000737a:	db250513          	addi	a0,a0,-590 # 80053128 <disk+0x2128>
    8000737e:	ffffa097          	auipc	ra,0xffffa
    80007382:	8b4080e7          	jalr	-1868(ra) # 80000c32 <acquire>
  for(int i = 0; i < 3; i++){
    80007386:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80007388:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000738a:	0004ac17          	auipc	s8,0x4a
    8000738e:	c76c0c13          	addi	s8,s8,-906 # 80051000 <disk>
    80007392:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80007394:	4b0d                	li	s6,3
    80007396:	a0ad                	j	80007400 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80007398:	00fc0733          	add	a4,s8,a5
    8000739c:	975e                	add	a4,a4,s7
    8000739e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800073a2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800073a4:	0207c563          	bltz	a5,800073ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800073a8:	2905                	addiw	s2,s2,1
    800073aa:	0611                	addi	a2,a2,4
    800073ac:	19690d63          	beq	s2,s6,80007546 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800073b0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800073b2:	0004c717          	auipc	a4,0x4c
    800073b6:	c6670713          	addi	a4,a4,-922 # 80053018 <disk+0x2018>
    800073ba:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800073bc:	00074683          	lbu	a3,0(a4)
    800073c0:	fee1                	bnez	a3,80007398 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800073c2:	2785                	addiw	a5,a5,1
    800073c4:	0705                	addi	a4,a4,1
    800073c6:	fe979be3          	bne	a5,s1,800073bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800073ca:	57fd                	li	a5,-1
    800073cc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800073ce:	01205d63          	blez	s2,800073e8 <virtio_disk_rw+0xa2>
    800073d2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800073d4:	000a2503          	lw	a0,0(s4)
    800073d8:	00000097          	auipc	ra,0x0
    800073dc:	d8e080e7          	jalr	-626(ra) # 80007166 <free_desc>
      for(int j = 0; j < i; j++)
    800073e0:	2d85                	addiw	s11,s11,1
    800073e2:	0a11                	addi	s4,s4,4
    800073e4:	ffb918e3          	bne	s2,s11,800073d4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800073e8:	0004c597          	auipc	a1,0x4c
    800073ec:	d4058593          	addi	a1,a1,-704 # 80053128 <disk+0x2128>
    800073f0:	0004c517          	auipc	a0,0x4c
    800073f4:	c2850513          	addi	a0,a0,-984 # 80053018 <disk+0x2018>
    800073f8:	ffffb097          	auipc	ra,0xffffb
    800073fc:	4aa080e7          	jalr	1194(ra) # 800028a2 <sleep>
  for(int i = 0; i < 3; i++){
    80007400:	f8040a13          	addi	s4,s0,-128
{
    80007404:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80007406:	894e                	mv	s2,s3
    80007408:	b765                	j	800073b0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000740a:	0004c697          	auipc	a3,0x4c
    8000740e:	bf66b683          	ld	a3,-1034(a3) # 80053000 <disk+0x2000>
    80007412:	96ba                	add	a3,a3,a4
    80007414:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80007418:	0004a817          	auipc	a6,0x4a
    8000741c:	be880813          	addi	a6,a6,-1048 # 80051000 <disk>
    80007420:	0004c697          	auipc	a3,0x4c
    80007424:	be068693          	addi	a3,a3,-1056 # 80053000 <disk+0x2000>
    80007428:	6290                	ld	a2,0(a3)
    8000742a:	963a                	add	a2,a2,a4
    8000742c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80007430:	0015e593          	ori	a1,a1,1
    80007434:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80007438:	f8842603          	lw	a2,-120(s0)
    8000743c:	628c                	ld	a1,0(a3)
    8000743e:	972e                	add	a4,a4,a1
    80007440:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80007444:	20050593          	addi	a1,a0,512
    80007448:	0592                	slli	a1,a1,0x4
    8000744a:	95c2                	add	a1,a1,a6
    8000744c:	577d                	li	a4,-1
    8000744e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80007452:	00461713          	slli	a4,a2,0x4
    80007456:	6290                	ld	a2,0(a3)
    80007458:	963a                	add	a2,a2,a4
    8000745a:	03078793          	addi	a5,a5,48
    8000745e:	97c2                	add	a5,a5,a6
    80007460:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80007462:	629c                	ld	a5,0(a3)
    80007464:	97ba                	add	a5,a5,a4
    80007466:	4605                	li	a2,1
    80007468:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000746a:	629c                	ld	a5,0(a3)
    8000746c:	97ba                	add	a5,a5,a4
    8000746e:	4809                	li	a6,2
    80007470:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80007474:	629c                	ld	a5,0(a3)
    80007476:	973e                	add	a4,a4,a5
    80007478:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000747c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80007480:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80007484:	6698                	ld	a4,8(a3)
    80007486:	00275783          	lhu	a5,2(a4)
    8000748a:	8b9d                	andi	a5,a5,7
    8000748c:	0786                	slli	a5,a5,0x1
    8000748e:	97ba                	add	a5,a5,a4
    80007490:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80007494:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80007498:	6698                	ld	a4,8(a3)
    8000749a:	00275783          	lhu	a5,2(a4)
    8000749e:	2785                	addiw	a5,a5,1
    800074a0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800074a4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800074a8:	100017b7          	lui	a5,0x10001
    800074ac:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800074b0:	004aa783          	lw	a5,4(s5)
    800074b4:	02c79163          	bne	a5,a2,800074d6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800074b8:	0004c917          	auipc	s2,0x4c
    800074bc:	c7090913          	addi	s2,s2,-912 # 80053128 <disk+0x2128>
  while(b->disk == 1) {
    800074c0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800074c2:	85ca                	mv	a1,s2
    800074c4:	8556                	mv	a0,s5
    800074c6:	ffffb097          	auipc	ra,0xffffb
    800074ca:	3dc080e7          	jalr	988(ra) # 800028a2 <sleep>
  while(b->disk == 1) {
    800074ce:	004aa783          	lw	a5,4(s5)
    800074d2:	fe9788e3          	beq	a5,s1,800074c2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800074d6:	f8042903          	lw	s2,-128(s0)
    800074da:	20090793          	addi	a5,s2,512
    800074de:	00479713          	slli	a4,a5,0x4
    800074e2:	0004a797          	auipc	a5,0x4a
    800074e6:	b1e78793          	addi	a5,a5,-1250 # 80051000 <disk>
    800074ea:	97ba                	add	a5,a5,a4
    800074ec:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800074f0:	0004c997          	auipc	s3,0x4c
    800074f4:	b1098993          	addi	s3,s3,-1264 # 80053000 <disk+0x2000>
    800074f8:	00491713          	slli	a4,s2,0x4
    800074fc:	0009b783          	ld	a5,0(s3)
    80007500:	97ba                	add	a5,a5,a4
    80007502:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80007506:	854a                	mv	a0,s2
    80007508:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000750c:	00000097          	auipc	ra,0x0
    80007510:	c5a080e7          	jalr	-934(ra) # 80007166 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80007514:	8885                	andi	s1,s1,1
    80007516:	f0ed                	bnez	s1,800074f8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80007518:	0004c517          	auipc	a0,0x4c
    8000751c:	c1050513          	addi	a0,a0,-1008 # 80053128 <disk+0x2128>
    80007520:	ffff9097          	auipc	ra,0xffff9
    80007524:	7c6080e7          	jalr	1990(ra) # 80000ce6 <release>
}
    80007528:	70e6                	ld	ra,120(sp)
    8000752a:	7446                	ld	s0,112(sp)
    8000752c:	74a6                	ld	s1,104(sp)
    8000752e:	7906                	ld	s2,96(sp)
    80007530:	69e6                	ld	s3,88(sp)
    80007532:	6a46                	ld	s4,80(sp)
    80007534:	6aa6                	ld	s5,72(sp)
    80007536:	6b06                	ld	s6,64(sp)
    80007538:	7be2                	ld	s7,56(sp)
    8000753a:	7c42                	ld	s8,48(sp)
    8000753c:	7ca2                	ld	s9,40(sp)
    8000753e:	7d02                	ld	s10,32(sp)
    80007540:	6de2                	ld	s11,24(sp)
    80007542:	6109                	addi	sp,sp,128
    80007544:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80007546:	f8042503          	lw	a0,-128(s0)
    8000754a:	20050793          	addi	a5,a0,512
    8000754e:	0792                	slli	a5,a5,0x4
  if(write)
    80007550:	0004a817          	auipc	a6,0x4a
    80007554:	ab080813          	addi	a6,a6,-1360 # 80051000 <disk>
    80007558:	00f80733          	add	a4,a6,a5
    8000755c:	01a036b3          	snez	a3,s10
    80007560:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80007564:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80007568:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000756c:	7679                	lui	a2,0xffffe
    8000756e:	963e                	add	a2,a2,a5
    80007570:	0004c697          	auipc	a3,0x4c
    80007574:	a9068693          	addi	a3,a3,-1392 # 80053000 <disk+0x2000>
    80007578:	6298                	ld	a4,0(a3)
    8000757a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000757c:	0a878593          	addi	a1,a5,168
    80007580:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80007582:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80007584:	6298                	ld	a4,0(a3)
    80007586:	9732                	add	a4,a4,a2
    80007588:	45c1                	li	a1,16
    8000758a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000758c:	6298                	ld	a4,0(a3)
    8000758e:	9732                	add	a4,a4,a2
    80007590:	4585                	li	a1,1
    80007592:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80007596:	f8442703          	lw	a4,-124(s0)
    8000759a:	628c                	ld	a1,0(a3)
    8000759c:	962e                	add	a2,a2,a1
    8000759e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffaa00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800075a2:	0712                	slli	a4,a4,0x4
    800075a4:	6290                	ld	a2,0(a3)
    800075a6:	963a                	add	a2,a2,a4
    800075a8:	058a8593          	addi	a1,s5,88
    800075ac:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800075ae:	6294                	ld	a3,0(a3)
    800075b0:	96ba                	add	a3,a3,a4
    800075b2:	40000613          	li	a2,1024
    800075b6:	c690                	sw	a2,8(a3)
  if(write)
    800075b8:	e40d19e3          	bnez	s10,8000740a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800075bc:	0004c697          	auipc	a3,0x4c
    800075c0:	a446b683          	ld	a3,-1468(a3) # 80053000 <disk+0x2000>
    800075c4:	96ba                	add	a3,a3,a4
    800075c6:	4609                	li	a2,2
    800075c8:	00c69623          	sh	a2,12(a3)
    800075cc:	b5b1                	j	80007418 <virtio_disk_rw+0xd2>

00000000800075ce <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800075ce:	1101                	addi	sp,sp,-32
    800075d0:	ec06                	sd	ra,24(sp)
    800075d2:	e822                	sd	s0,16(sp)
    800075d4:	e426                	sd	s1,8(sp)
    800075d6:	e04a                	sd	s2,0(sp)
    800075d8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800075da:	0004c517          	auipc	a0,0x4c
    800075de:	b4e50513          	addi	a0,a0,-1202 # 80053128 <disk+0x2128>
    800075e2:	ffff9097          	auipc	ra,0xffff9
    800075e6:	650080e7          	jalr	1616(ra) # 80000c32 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800075ea:	10001737          	lui	a4,0x10001
    800075ee:	533c                	lw	a5,96(a4)
    800075f0:	8b8d                	andi	a5,a5,3
    800075f2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800075f4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800075f8:	0004c797          	auipc	a5,0x4c
    800075fc:	a0878793          	addi	a5,a5,-1528 # 80053000 <disk+0x2000>
    80007600:	6b94                	ld	a3,16(a5)
    80007602:	0207d703          	lhu	a4,32(a5)
    80007606:	0026d783          	lhu	a5,2(a3)
    8000760a:	06f70163          	beq	a4,a5,8000766c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000760e:	0004a917          	auipc	s2,0x4a
    80007612:	9f290913          	addi	s2,s2,-1550 # 80051000 <disk>
    80007616:	0004c497          	auipc	s1,0x4c
    8000761a:	9ea48493          	addi	s1,s1,-1558 # 80053000 <disk+0x2000>
    __sync_synchronize();
    8000761e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007622:	6898                	ld	a4,16(s1)
    80007624:	0204d783          	lhu	a5,32(s1)
    80007628:	8b9d                	andi	a5,a5,7
    8000762a:	078e                	slli	a5,a5,0x3
    8000762c:	97ba                	add	a5,a5,a4
    8000762e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007630:	20078713          	addi	a4,a5,512
    80007634:	0712                	slli	a4,a4,0x4
    80007636:	974a                	add	a4,a4,s2
    80007638:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000763c:	e731                	bnez	a4,80007688 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000763e:	20078793          	addi	a5,a5,512
    80007642:	0792                	slli	a5,a5,0x4
    80007644:	97ca                	add	a5,a5,s2
    80007646:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007648:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000764c:	ffffb097          	auipc	ra,0xffffb
    80007650:	3ec080e7          	jalr	1004(ra) # 80002a38 <wakeup>

    disk.used_idx += 1;
    80007654:	0204d783          	lhu	a5,32(s1)
    80007658:	2785                	addiw	a5,a5,1
    8000765a:	17c2                	slli	a5,a5,0x30
    8000765c:	93c1                	srli	a5,a5,0x30
    8000765e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007662:	6898                	ld	a4,16(s1)
    80007664:	00275703          	lhu	a4,2(a4)
    80007668:	faf71be3          	bne	a4,a5,8000761e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000766c:	0004c517          	auipc	a0,0x4c
    80007670:	abc50513          	addi	a0,a0,-1348 # 80053128 <disk+0x2128>
    80007674:	ffff9097          	auipc	ra,0xffff9
    80007678:	672080e7          	jalr	1650(ra) # 80000ce6 <release>
}
    8000767c:	60e2                	ld	ra,24(sp)
    8000767e:	6442                	ld	s0,16(sp)
    80007680:	64a2                	ld	s1,8(sp)
    80007682:	6902                	ld	s2,0(sp)
    80007684:	6105                	addi	sp,sp,32
    80007686:	8082                	ret
      panic("virtio_disk_intr status");
    80007688:	00002517          	auipc	a0,0x2
    8000768c:	23850513          	addi	a0,a0,568 # 800098c0 <syscalls+0x408>
    80007690:	ffff9097          	auipc	ra,0xffff9
    80007694:	e9a080e7          	jalr	-358(ra) # 8000052a <panic>
	...

0000000080008000 <_trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret

0000000080008112 <myfunc>:
    80008112:	48e1                	li	a7,24
    80008114:	00000073          	ecall

0000000080008118 <endMyFunc>:
	...
