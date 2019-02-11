//
//  CPU6502+CPU6502_Instructions_m.m
//  VIC20
//
//  Created by Gregory John Casamento on 2/11/19.
//  Copyright © 2019 Open Logic. All rights reserved.
//

#import "CPU6502+Instructions.h"
#import "RAM.h"
#import "ROM.h"

@implementation CPU6502 (Instructions)
// Instruction implementations...
/*
 *  add 1 to cycles if page boundery is crossed
 
 ** add 1 to cycles if branch occurs on same page
 add 2 to cycles if branch occurs to different page
 
 
 Legend to Flags:  + .... modified
 - .... not modified
 1 .... set
 0 .... cleared
 M6 .... memory bit 6
 M7 .... memory bit 7
 */


/*
 ADC  Add Memory to Accumulator with Carry
 
 A + M + C -> A, C                N Z C I D V
 + + + - - +
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     ADC #oper     69    2     2
 zeropage      ADC oper      65    2     3
 zeropage,X    ADC oper,X    75    2     4
 absolute      ADC oper      6D    3     4
 absolute,X    ADC oper,X    7D    3     4*
 absolute,Y    ADC oper,Y    79    3     4*
 (indirect,X)  ADC (oper,X)  61    2     6
 (indirect),Y  ADC (oper),Y  71    2     5*
 */
/* Implementation of ADC */
- (void) ADC_immediate
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"%04x ADC #%02x",pc - 1, param1];
    a = a + param1;
    s.status.c = a & 0x80;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ADC */
- (void) ADC_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 val = [ram read: param1];
    [self debugLogWithFormat:@"ADC $%02X", param1];
    a = a + val;
    s.status.c = a & 0x80;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ADC */
- (void) ADC_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 val = [ram read: param1 + x];
    [self debugLogWithFormat:@"ADC ($%02X),X", param1];
    a = a + val;
    s.status.c = a & 0x80;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ADC */
- (void) ADC_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"ADC $%04X", addr];
    uint8 val = [ram read: addr];
    a = a + val;
    s.status.c = a & 0x80;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ADC */
- (void) ADC_absoluteX
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    [self debugLogWithFormat:@"ADC $%04X,X", addr];
    a = a + val;
    s.status.c = a & 0x80;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ADC */
- (void) ADC_absoluteY
{
    [self debugLogWithFormat:@"ADC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + y];
    a = a + val;
    s.status.c = a & 0x80;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ADC */
- (void) ADC_indirectX
{
    [self debugLogWithFormat:@"ADC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 p2 = param1 + x + 1;
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    a = a + val;
    s.status.c = a & 0x80;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ADC */
- (void) ADC_indirectY
{
    [self debugLogWithFormat:@"ADC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 p2 = param1 + y + 1;
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    a = a + val;
    s.status.c = a & 0x80;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of AND */
/*
 AND  AND Memory with Accumulator
 
 A AND M -> A                     N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     AND #oper     29    2     2
 zeropage      AND oper      25    2     3
 zeropage,X    AND oper,X    35    2     4
 absolute      AND oper      2D    3     4
 absolute,X    AND oper,X    3D    3     4*
 absolute,Y    AND oper,Y    39    3     4*
 (indirect,X)  AND (oper,X)  21    2     6
 (indirect),Y  AND (oper),Y  31    2     5*
 */
- (void) AND_immediate
{
    [self debugLogWithFormat:@"AND"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    a = a & param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of AND */
- (void) AND_zeropage
{
    [self debugLogWithFormat:@"AND"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 val = [ram read: param1];
    a = a & val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of AND */
- (void) AND_zeropageX
{
    [self debugLogWithFormat:@"AND"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 val = [ram read: param1 + x];
    a = a & val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of AND */
- (void) AND_absolute
{
    [self debugLogWithFormat:@"AND"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    a = a & val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of AND */
- (void) AND_absoluteX
{
    [self debugLogWithFormat:@"AND"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    a = a & val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of AND */
- (void) AND_absoluteY
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"AND $%04X,X",addr];
    uint8 val = [ram read: addr + y];
    a = a & val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}
/* Implementation of AND */
- (void) AND_indirectX
{
    [self debugLogWithFormat:@"AND"];
    pc++;
    uint8 param1 = [ram read: pc] + x;
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 p2 = [ram read: param1 + 1];
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    a = a & val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of AND */
- (void) AND_indirectY
{
    [self debugLogWithFormat:@"AND"];
    pc++;
    uint8 param1 = [ram read: pc] + y;
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 p2 = [ram read: param1 + 1];
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + y];
    a = a & val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/*
 ASL  Shift Left One Bit (Memory or Accumulator)
 
 C <- [76543210] <- 0             N Z C I D V
 + + + - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 accumulator   ASL A         0A    1     2
 zeropage      ASL oper      06    2     5
 zeropage,X    ASL oper,X    16    2     6
 absolute      ASL oper      0E    3     6
 absolute,X    ASL oper,X    1E    3     7
 */
/* Implementation of ASL */
- (void) ASL_accumulator
{
    [self debugLogWithFormat:@"ASL"];
    a = a << 1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ASL */
- (void) ASL_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"ASL $%X", param1];
    uint8 val = [ram read: param1];
    uint8 r = val << 1;
    s.status.n = r & 0x80;
    s.status.z = !(r);
    [ram write:r loc: param1];
}

/* Implementation of ASL */
- (void) ASL_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"ASL $%X,X", param1];
    uint8 val = [ram read: param1 + x];
    uint8 r = val << 1;
    s.status.n = r & 0x80;
    s.status.z = !(r);
    [ram write:r loc: param1];
}

/* Implementation of ASL */
- (void) ASL_absolute
{
    [self debugLogWithFormat:@"ASL"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    uint8 r = val << 1;
    s.status.n = r & 0x80;
    s.status.z = !(r);
    [ram write:r loc:addr];
}

/* Implementation of ASL */
- (void) ASL_absoluteX
{
    [self debugLogWithFormat:@"ASL"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    uint8 r = val << 1;
    s.status.n = r & 0x80;
    s.status.z = !(r);
    [ram write:r loc: addr];
}

/* Implementation of BCC */
- (void) BCC_relative
{
    [self debugLogWithFormat:@"BCC"];
    pc++;
    int8_t param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(!s.status.c)
    {
        pc += param1;
    }
}

/* Implementation of BCS */
- (void) BCS_relative
{
    [self debugLogWithFormat:@"BCS"];
    pc++;
    int8_t param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(s.status.c)
    {
        pc += param1;
    }
}

/* Implementation of BEQ */
- (void) BEQ_relative
{
    [self debugLogWithFormat:@"BEQ"];
    pc++;
    int8_t param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(s.status.z)
    {
        pc += param1;
    }
}

/*
 BIT  Test Bits in Memory with Accumulator
 
 bits 7 and 6 of operand are transfered to bit 7 and 6 of SR (N,V);
 the zeroflag is set to the result of operand AND accumulator.
 
 A AND M, M7 -> N, M6 -> V        N Z C I D V
 M7 + - - - M6
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 zeropage      BIT oper      24    2     3
 absolute      BIT oper      2C    3     4
 */
/* Implementation of BIT */
- (void) BIT_zeropage
{
    [self debugLogWithFormat:@"BIT"];
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 val = [ram read: param1];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 m6 = val & 0x40; // bit 6
    uint8 m7 = val & 0x80; // bit 7
    a = a & val;
    s.status.z = !(a);
    s.status.n = m7;
    s.status.v = m6;
}

/* Implementation of BIT */
- (void) BIT_absolute
{
    [self debugLogWithFormat:@"BIT"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 m6 = val & 0x40; // bit 6
    uint8 m7 = val & 0x80; // bit 7
    a = a & val;
    s.status.z = !(a);
    s.status.n = m7;
    s.status.v = m6;
}

/*
 BMI  Branch on Result Minus
 
 branch on N = 1                  N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 relative      BMI oper      30    2     2**
 */
/* Implementation of BMI */
- (void) BMI_relative
{
    [self debugLogWithFormat:@"BMI"];
    pc++;
    int8_t param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(s.status.n == 1)
    {
        pc += param1;
    }
}

/*
 BNE  Branch on Result not Zero
 
 branch on Z = 0                  N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 relative      BNE oper      D0    2     2**
 */
/* Implementation of BNE */
- (void) BNE_relative
{
    [self debugLogWithFormat:@"BNE"];
    pc++;
    int8_t param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(!s.status.z)
    {
        pc += param1;
    }
}

/*
 BPL  Branch on Result Plus
 
 branch on N = 0                  N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 relative      BPL oper      10    2     2**
 */
/* Implementation of BPL */
- (void) BPL_relative
{
    [self debugLogWithFormat:@"BPL"];
    pc++;
    int8_t param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(s.status.n == 0)
    {
        pc += param1;
    }
}

/*
 BRK  Force Break
 
 interrupt,                       N Z C I D V
 push PC+2, push SR               - - - 1 - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       BRK           00    1     7
 */
/* Implementation of BRK */
- (void) BRK_implied
{
    [self debugLogWithFormat:@"BRK"];
}

/*
 BVC  Branch on Overflow Clear
 
 branch on V = 0                  N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 relative      BVC oper      50    2     2**
 */
/* Implementation of BVC */
- (void) BVC_relative
{
    [self debugLogWithFormat:@"BVC"];
    pc++;
    int8_t param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(s.status.v == 0)
    {
        pc += param1;
    }
}

/*
 BVS  Branch on Overflow Set
 
 branch on V = 1                  N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 relative      BVC oper      70    2     2**
 */
/* Implementation of BVS */
- (void) BVS_relative
{
    [self debugLogWithFormat:@"BVS"];
    pc++;
    int8_t param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(s.status.v == 1)
    {
        pc += param1;
    }
}

/*
 CLC  Clear Carry Flag
 
 0 -> C                           N Z C I D V
 - - 0 - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       CLC           18    1     2
 */
/* Implementation of CLC */
- (void) CLC_implied
{
    [self debugLogWithFormat:@"CLC"];
    s.status.c = 0;
}

/*
 CLD  Clear Decimal Mode
 
 0 -> D                           N Z C I D V
 - - - - 0 -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       CLD           D8    1     2
 */
/* Implementation of CLD */
- (void) CLD_implied
{
    [self debugLogWithFormat:@"CLD"];
    s.status.d = 0;
    
}

/*
 CLI  Clear Interrupt Disable Bit
 
 0 -> I                           N Z C I D V
 - - - 0 - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       CLI           58    1     2
 */
/* Implementation of CLI */
- (void) CLI_implied
{
    [self debugLogWithFormat:@"CLI"];
    s.status.i = 0;
}

/*
 CLV  Clear Overflow Flag
 
 0 -> V                           N Z C I D V
 - - - - - 0
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       CLV           B8    1     2
 */
/* Implementation of CLV */
- (void) CLV_implied
{
    [self debugLogWithFormat:@"CLV"];
    s.status.v = 0;
}

/* Implementation of CMP */
- (void) CMP_immediate
{
    [self debugLogWithFormat:@"CMP"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(a == param1)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = param1 & 0x80;
    s.status.c = param1 & 0x80;
}

/* Implementation of CMP */
- (void) CMP_zeropage
{
    [self debugLogWithFormat:@"CMP"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    if(a == param1)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = param1 & 0x80;
    s.status.c = param1 & 0x80;
}

/* Implementation of CMP */
- (void) CMP_zeropageX
{
    [self debugLogWithFormat:@"CMP"];
    pc++;
    uint8 param1 = [ram read: pc] + x;
    [self debugLogWithFormat:@"param = %X", param1];
    if(a == param1)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = param1 & 0x80;
    s.status.c = param1 & 0x80;
}

/* Implementation of CMP */
- (void) CMP_absolute
{
    [self debugLogWithFormat:@"CMP"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    if(a == val)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = val & 0x80;
    s.status.c = val & 0x80;
}

/* Implementation of CMP */
- (void) CMP_absoluteX
{
    [self debugLogWithFormat:@"CMP"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    if(a == val)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = val & 0x80;
    s.status.c = val & 0x80;
}

/* Implementation of CMP */
- (void) CMP_absoluteY
{
    [self debugLogWithFormat:@"CMP"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + y];
    if(a == val)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = val & 0x80;
    s.status.c = val & 0x80;
}

/* Implementation of CMP */
- (void) CMP_indirectX
{
    [self debugLogWithFormat:@"CMP"];
    pc++;
    uint8 param1 = [ram read: pc] + x;
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 p2 = param1 + x + 1;
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    if(a == val)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = val & 0x80;
    s.status.c = val & 0x80;
}

/* Implementation of CMP */
- (void) CMP_indirectY
{
    [self debugLogWithFormat:@"CMP"];
    pc++;
    uint8 param1 = [ram read: pc] + y;
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 p2 = param1 + y + 1;
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    if(a == val)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = val & 0x80;
    s.status.c = val & 0x80;
}

/*
 CPX  Compare Memory and Index X
 
 X - M                            N Z C I D V
 + + + - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     CPX #oper     E0    2     2
 zeropage      CPX oper      E4    2     3
 absolute      CPX oper      EC    3     4
 */
/* Implementation of CPX */
- (void) CPX_immediate
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"CPX $%X", param1];
    if(x == param1)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = param1 & 0x80;
    s.status.c = param1 & 0x80;
}

/* Implementation of CPX */
- (void) CPX_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"CPX $%X", param1];
    if(x == param1)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = param1 & 0x80;
    s.status.c = param1 & 0x80;
}

/* Implementation of CPX */
- (void) CPX_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"CPX $%04X",addr];
    uint8 val = [ram read: addr];
    if(x == val)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = val & 0x80;
    s.status.c = val & 0x80;
}

/*
 CPY  Compare Memory and Index Y
 
 Y - M                            N Z C I D V
 + + + - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     CPY #oper     C0    2     2
 zeropage      CPY oper      C4    2     3
 absolute      CPY oper      CC    3     4
 */
/* Implementation of CPY */
- (void) CPY_immediate
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"CPY #%02X", param1];
    if(y == param1)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = param1 & 0x80;
    s.status.c = param1 & 0x80;
}

/* Implementation of CPY */
- (void) CPY_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 val = [ram read: param1];
    [self debugLogWithFormat:@"CPY $%02X", param1];
    if(y == val)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = param1 & 0x80;
    s.status.c = param1 & 0x80;
}

/* Implementation of CPY */
- (void) CPY_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    [self debugLogWithFormat:@"CPY $%04X", param1];
    if(y == val)
    {
        s.status.z = 0;
    }
    else
    {
        s.status.z = 1;
    }
    s.status.n = param1 & 0x80;
    s.status.c = param1 & 0x80;
}

/*
 DEC  Decrement Memory by One
 
 M - 1 -> M                       N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 zeropage      DEC oper      C6    2     5
 zeropage,X    DEC oper,X    D6    2     6
 absolute      DEC oper      CE    3     3
 absolute,X    DEC oper,X    DE    3     7
 */
/* Implementation of DEC */
- (void) DEC_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"DEC $%02X", param1];
    uint8 val = [ram read: param1];
    val = val - 1;
    [ram write: val loc:param1];
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/* Implementation of DEC */
- (void) DEC_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"DEC $%02X", param1];
    uint8 val = [ram read: param1 + x];
    val = val - 1;
    [ram write: val loc:param1 + x];
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/* Implementation of DEC */
- (void) DEC_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"DEC $%04X", addr];
    uint8 val = [ram read: addr];
    val = val - 1;
    [ram write: val loc:addr];
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/* Implementation of DEC */
- (void) DEC_absoluteX
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"DEC $%04X", addr];
    uint8 val = [ram read: addr + x];
    val = val - 1;
    [ram write: val loc:addr + x];
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/*
 DEX  Decrement Index X by One
 
 X - 1 -> X                       N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       DEC           CA    1     2
 */
/* Implementation of DEX */
- (void) DEX_implied
{
    [self debugLogWithFormat:@"DEX"];
    x = x - 1;
    s.status.n = x & 0x80;
    s.status.z = !(x);
}

/*
 DEY  Decrement Index Y by One
 
 Y - 1 -> Y                       N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       DEC           88    1     2
 */
/* Implementation of DEY */
- (void) DEY_implied
{
    [self debugLogWithFormat:@"DEY"];
    y = y - 1;
    s.status.n = y & 0x80;
    s.status.z = !(y);
}

/*
 EOR  Exclusive-OR Memory with Accumulator
 
 A EOR M -> A                     N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     EOR #oper     49    2     2
 zeropage      EOR oper      45    2     3
 zeropage,X    EOR oper,X    55    2     4
 absolute      EOR oper      4D    3     4
 absolute,X    EOR oper,X    5D    3     4*
 absolute,Y    EOR oper,Y    59    3     4*
 (indirect,X)  EOR (oper,X)  41    2     6
 (indirect),Y  EOR (oper),Y  51    2     5*
 */
/* Implementation of EOR */
- (void) EOR_immediate
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"EOR #%02X", param1];
    a = a ^ param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of EOR */
- (void) EOR_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 val = [ram read: param1];
    [self debugLogWithFormat:@"EOR $%02X", val];
    a = a ^ param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of EOR */
- (void) EOR_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 val = [ram read: param1 + x];
    [self debugLogWithFormat:@"EOR $%02X", val];
    a = a ^ param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of EOR */
- (void) EOR_absolute
{
    [self debugLogWithFormat:@"EOR"];
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    [self debugLogWithFormat:@"EOR $%02X", val];
    a = a ^ param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of EOR */
- (void) EOR_absoluteX
{
    [self debugLogWithFormat:@"EOR"];
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    [self debugLogWithFormat:@"EOR $%02X", val];
    a = a ^ param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of EOR */
- (void) EOR_absoluteY
{
    [self debugLogWithFormat:@"EOR"];
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + y];
    [self debugLogWithFormat:@"EOR $%02X", val];
    a = a ^ param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of EOR */
- (void) EOR_indirectX
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 p2 = [ram read: pc + 1];
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    [self debugLogWithFormat:@"EOR $%02X,X", val];
    a = a ^ param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of EOR */
- (void) EOR_indirectY
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 p2 = [ram read: pc + 1];
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + y];
    [self debugLogWithFormat:@"EOR $%02X,X", val];
    a = a ^ param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/*
 INC  Increment Memory by One
 
 M + 1 -> M                       N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 zeropage      INC oper      E6    2     5
 zeropage,X    INC oper,X    F6    2     6
 absolute      INC oper      EE    3     6
 absolute,X    INC oper,X    FE    3     7
 */
/* Implementation of INC */
- (void) INC_zeropage
{
    [self debugLogWithFormat:@"INC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 val = [ram read: param1];
    val++;
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/* Implementation of INC */
- (void) INC_zeropageX
{
    [self debugLogWithFormat:@"INC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 val = [ram read: param1 + x ];
    val++;
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/* Implementation of INC */
- (void) INC_absolute
{
    [self debugLogWithFormat:@"INC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    val++;
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/* Implementation of INC */
- (void) INC_absoluteX
{
    [self debugLogWithFormat:@"INC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    val++;
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/* Implementation of INX */
- (void) INX_implied
{
    [self debugLogWithFormat:@"INX"];
    uint8 val = x;
    val++;
    x = val;
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/* Implementation of INY */
- (void) INY_implied
{
    [self debugLogWithFormat:@"INX"];
    uint8 val = y;
    val++;
    y = val;
    s.status.n = val & 0x80;
    s.status.z = !(val);
}

/*
 JMP  Jump to New Location
 
 (PC+1) -> PCL                    N Z C I D V
 (PC+2) -> PCH                    - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 absolute      JMP oper      4C    3     3
 indirect      JMP (oper)    6C    3     5
 */
/* Implementation of JMP */
- (void) JMP_absolute
{
    [self debugLogWithFormat:@"JMP"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"addr = %X", addr];
    pc = addr;
}

/* Implementation of JMP */
- (void) JMP_indirect
{
    [self debugLogWithFormat:@"JMP"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"addr = %X", addr];
    uint8 p1 = [ram read: addr];
    uint8 p2 = [ram read: addr + 1];
    uint16 naddr = ((uint16)p2 << 8) + (uint16)p1;  // indirect address...
    int8_t offset = [ram read: naddr];
    pc += offset; // Set new location.
}

/*
 JSR  Jump to New Location Saving Return Address
 
 push (PC+2),                     N Z C I D V
 (PC+1) -> PCL                    - - - - - -
 (PC+2) -> PCH
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 absolute      JSR oper      20    3     6
 */
/* Implementation of JSR */
- (void) JSR_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    pc--;
    
    [self push: (pc >> 8) & 0xff];
    [self push: (pc & 0xff)];
    [self debugLogWithFormat:@"JSR $%04X", addr];
    pc = addr; // Set new location.
}

/*
 LDA  Load Accumulator with Memory
 
 M -> A                           N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     LDA #oper     A9    2     2
 zeropage      LDA oper      A5    2     3
 zeropage,X    LDA oper,X    B5    2     4
 absolute      LDA oper      AD    3     4
 absolute,X    LDA oper,X    BD    3     4*
 absolute,Y    LDA oper,Y    B9    3     4*
 (indirect,X)  LDA (oper,X)  A1    2     6
 (indirect),Y  LDA (oper),Y  B1    2     5*
 */
/* Implementation of LDA */
- (void) LDA_immediate
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"LDA #%X", param1];
    a = param1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of LDA */
- (void) LDA_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"LDA $%02X", param1];
    uint8 val = [ram read: param1];
    a = val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of LDA */
- (void) LDA_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"LDA $%02X,X", param1];
    uint8 val = [ram read: param1 + x];
    a = val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of LDA */
- (void) LDA_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"LDA $%04X", addr];
    uint8 val = [ram read: addr];
    a = val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of LDA */
- (void) LDA_absoluteX
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"LDA $%04X,X", addr + x];
    uint8 val = [ram read: addr];
    a = val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of LDA */
- (void) LDA_absoluteY
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"LDA $%04X,Y", addr + y];
    uint8 val = [ram read: addr];
    a = val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of LDA */
- (void) LDA_indirectX
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 p1 = [ram read: param1];
    uint8 p2 = [ram read: param1 + 1];
    uint16 addr = ((uint16)p2 << 8) + (uint16)p1;
    [self debugLogWithFormat:@"LDA ($%04X,X)", addr + x];
    uint8 val = [ram read: addr];
    a = val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of LDA */
- (void) LDA_indirectY
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 p1 = [ram read: param1];
    uint8 p2 = [ram read: param1 + 1];
    uint16 addr = ((uint16)p2 << 8) + (uint16)p1;
    [self debugLogWithFormat:@"LDA ($%04X),Y", addr + y];
    uint8 val = [ram read: addr];
    a = val;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/*
 LDX  Load Index X with Memory
 
 M -> X                           N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     LDX #oper     A2    2     2
 zeropage      LDX oper      A6    2     3
 zeropage,Y    LDX oper,Y    B6    2     4
 absolute      LDX oper      AE    3     4
 absolute,Y    LDX oper,Y    BE    3     4*
 */
/* Implementation of LDX */
- (void) LDX_immediate
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"LDX #%X", param1];
    x = param1;
    s.status.n = x & 0x80;
    s.status.z = !(x);
}

/* Implementation of LDX */
- (void) LDX_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"LDX $%02X", param1];
    uint8 val = [ram read: param1];
    x = val;
    s.status.n = x & 0x80;
    s.status.z = !(x);
}

/* Implementation of LDX */
- (void) LDX_zeropageY
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"LDX $%02X,Y", param1];
    uint8 val = [ram read: param1 + y];
    x = val;
    s.status.n = x & 0x80;
    s.status.z = !(x);
}

/* Implementation of LDX */
- (void) LDX_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"LDX $%04X", addr];
    uint8 val = [ram read: addr];
    x = val;
    s.status.n = x & 0x80;
    s.status.z = !(x);
}

/* Implementation of LDX */
- (void) LDX_absoluteY
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"LDX $%04X", addr];
    uint8 val = [ram read: addr];
    x = val;
    s.status.n = x & 0x80;
    s.status.z = !(x);
}

/*
 LDY  Load Index Y with Memory
 
 M -> Y                           N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     LDY #oper     A0    2     2
 zeropage      LDY oper      A4    2     3
 zeropage,X    LDY oper,X    B4    2     4
 absolute      LDY oper      AC    3     4
 absolute,X    LDY oper,X    BC    3     4*
 */
/* Implementation of LDY */
- (void) LDY_immediate
{
    [self debugLogWithFormat:@"LDY"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    s.status.n = y & 0x80;
    s.status.z = !(y);
}

/* Implementation of LDY */
- (void) LDY_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"LDY #%02X", param1];
    y = param1;
    s.status.n = y & 0x80;
    s.status.z = !(y);
}

/* Implementation of LDY */
- (void) LDY_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"LDY $%02X,X", param1];
    y = param1;
    s.status.n = y & 0x80;
    s.status.z = !(y);
}

/* Implementation of LDY */
- (void) LDY_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"LDY $%04X", addr];
    uint8 val = [ram read: addr];
    y = val;
    s.status.n = y & 0x80;
    s.status.z = !(y);
}

/* Implementation of LDY */
- (void) LDY_absoluteX
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"LDY $%04X", addr];
    uint8 val = [ram read: addr];
    y = val;
    s.status.n = y & 0x80;
    s.status.z = !(y);
}

/*
 LSR  Shift One Bit Right (Memory or Accumulator)
 
 0 -> [76543210] -> C             N Z C I D V
 - + + - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 accumulator   LSR A         4A    1     2
 zeropage      LSR oper      46    2     5
 zeropage,X    LSR oper,X    56    2     6
 absolute      LSR oper      4E    3     6
 absolute,X    LSR oper,X    5E    3     7
 */
/* Implementation of LSR */
- (void) LSR_accumulator
{
    [self debugLogWithFormat:@"LSR"];
    a = a >> 1;
    s.status.z = !(a);
    s.status.c = a & 0x80;
}

/* Implementation of LSR */
- (void) LSR_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 val = [ram read: param1];
    [self debugLogWithFormat:@"LSR $%02X", param1];
    uint8 r = val << 1;
    [ram write:r loc:param1];
    s.status.z = !(r);
    s.status.c = r & 0x80;
}

/* Implementation of LSR */
- (void) LSR_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    uint8 val = [ram read: param1 + x];
    [self debugLogWithFormat:@"LSR $%02X,X", param1];
    uint8 r = val << 1;
    [ram write:r loc:param1];
    s.status.z = !(r);
    s.status.c = r & 0x80;
}

/* Implementation of LSR */
- (void) LSR_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"LSR $%04X", addr];
    uint8 val = [ram read: addr];
    uint8 r = val << 1;
    [ram write:r loc:param1];
    s.status.z = !(r);
    s.status.c = r & 0x80;
}

/* Implementation of LSR */
- (void) LSR_absoluteX
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"LSR $%04X", addr + x];
    uint8 val = [ram read: addr];
    uint8 r = val << 1;
    [ram write:r loc:param1];
    s.status.z = !(r);
    s.status.c = r & 0x80;
}

/*
 NOP  No Operation
 
 ---                              N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       NOP           EA    1     2
 */
/* Implementation of NOP */
- (void) NOP_implied
{
    [self debugLogWithFormat:@"NOP"];  // literally does nothing...
}

/*
 ORA  OR Memory with Accumulator
 
 A OR M -> A                      N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     ORA #oper     09    2     2
 zeropage      ORA oper      05    2     3
 zeropage,X    ORA oper,X    15    2     4
 absolute      ORA oper      0D    3     4
 absolute,X    ORA oper,X    1D    3     4*
 absolute,Y    ORA oper,Y    19    3     4*
 (indirect,X)  ORA (oper,X)  01    2     6
 (indirect),Y  ORA (oper),Y  11    2     5*
 */
/* Implementation of ORA */
- (void) ORA_immediate
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"ORA #%02X", param1];
    uint8 r = a | param1;
    a = r;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ORA */
- (void) ORA_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"ORA $%02X", param1];
    uint8 v = [ram read: param1];
    uint8 r = a | v;
    a = r;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ORA */
- (void) ORA_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"ORA $%02X,X", param1];
    uint8 v = [ram read: param1 + x];
    uint8 r = a | v;
    a = r;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ORA */
- (void) ORA_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"ORA $%04X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 v = [ram read: addr];
    uint8 r = a | v;
    a = r;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ORA */
- (void) ORA_absoluteX
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"ORA $%04X,X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 v = [ram read: addr + x];
    uint8 r = a | v;
    a = r;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ORA */
- (void) ORA_absoluteY
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"ORA $%04X,Y", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 v = [ram read: addr + y];
    uint8 r = a | v;
    a = r;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/* Implementation of ORA */
- (void) ORA_indirectX
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 p2 = [ram read: pc + 1];
    [self debugLogWithFormat:@"ORA $%04X,Y", param1];
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 v = [ram read: addr + x];
    uint8 r = a | v;
    a = r;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}


- (void) ORA_indirectY
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 p2 = [ram read: pc + 1];
    [self debugLogWithFormat:@"ORA $%04X,Y", param1];
    uint16 addr = ((uint16)p2 << 8) + (uint16)param1;
    uint8 v = [ram read: addr + y];
    uint8 r = a | v;
    a = r;
    s.status.n = a & 0x80;
    s.status.z = !(a);
}

/*
 PHA  Push Accumulator on Stack
 
 push A                           N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       PHA           48    1     3
 */
/* Implementation of PHA */
- (void) PHA_implied
{
    [self debugLogWithFormat:@"PHA"];
    [self push: a];
}

/*
 PHP  Push Processor Status on Stack
 
 push SR                          N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       PHP           08    1     3
 */
/* Implementation of PHP */
- (void) PHP_implied
{
    [self debugLogWithFormat:@"PHP"];
    [self push: s.sr];
}

/*
 PLA  Pull Accumulator from Stack
 
 pull A                           N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       PLA           68    1     4
 */
/* Implementation of PLA */
- (void) PLA_implied
{
    [self debugLogWithFormat:@"PLA"];
    a = [self pop];
}

/*
 PLP  Pull Processor Status from Stack
 
 pull SR                          N Z C I D V
 from stack
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       PLP           28    1     4
 */
/* Implementation of PLP */
- (void) PLP_implied
{
    [self debugLogWithFormat:@"PLP"];
    s.sr = [self pop];
}

/*
 ROL  Rotate One Bit Left (Memory or Accumulator)
 
 C <- [76543210] <- C             N Z C I D V
 + + + - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 accumulator   ROL A         2A    1     2
 zeropage      ROL oper      26    2     5
 zeropage,X    ROL oper,X    36    2     6
 absolute      ROL oper      2E    3     6
 absolute,X    ROL oper,X    3E    3     7
 */
/* Implementation of ROL */
- (void) ROL_accumulator
{
    [self debugLogWithFormat:@"ROL"];
    a = a << 1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
    s.status.c = a & 0x80;
}

/* Implementation of ROL */
- (void) ROL_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"ROL $%02X", param1];
    uint8 v = [ram read: param1];
    v = v << 1;
    [ram write:v loc:param1];
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of ROL */
- (void) ROL_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"ROL $%02X,X", param1];
    uint8 v = [ram read: param1];
    v = v << 1;
    [ram write:v loc:param1 + x];
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of ROL */
- (void) ROL_absolute
{
    [self debugLogWithFormat:@"ROL"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 v = [ram read: addr];
    v = v << 1;
    [ram write:v loc:addr];
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of ROL */
- (void) ROL_absoluteX
{
    [self debugLogWithFormat:@"ROL"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 v = [ram read: addr + x];
    v = v << 1;
    [ram write:v loc:addr + x];
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/*
 ROR  Rotate One Bit Right (Memory or Accumulator)
 
 C -> [76543210] -> C             N Z C I D V
 + + + - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 accumulator   ROR A         6A    1     2
 zeropage      ROR oper      66    2     5
 zeropage,X    ROR oper,X    76    2     6
 absolute      ROR oper      6E    3     6
 absolute,X    ROR oper,X    7E    3     7
 */
/* Implementation of ROR */
- (void) ROR_accumulator
{
    [self debugLogWithFormat:@"ROR"];
    [self debugLogWithFormat:@"ROL"];
    a = a >> 1;
    s.status.n = a & 0x80;
    s.status.z = !(a);
    s.status.c = a & 0x80;
}

/* Implementation of ROR */
- (void) ROR_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"ROL $%02X", param1];
    uint8 v = [ram read: param1];
    v = v >> 1;
    [ram write:v loc:param1];
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of ROR */
- (void) ROR_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"ROL $%02X,X", param1];
    uint8 v = [ram read: param1];
    v = v >> 1;
    [ram write:v loc:param1 + x];
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of ROR */
- (void) ROR_absolute
{
    [self debugLogWithFormat:@"ROL"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 v = [ram read: addr];
    v = v >> 1;
    [ram write:v loc:addr];
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of ROR */
- (void) ROR_absoluteX
{
    [self debugLogWithFormat:@"ROL"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 v = [ram read: addr + x];
    v = v << 1;
    [ram write:v loc:addr + x];
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/*
 RTI  Return from Interrupt
 
 pull SR, pull PC                 N Z C I D V
 from stack
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       RTI           40    1     6
 */
/* Implementation of RTI */
- (void) RTI_implied
{
    [self debugLogWithFormat:@"RTI"];
    uint8_t lo, hi;
    
    s.sr = [self pop];
    
    lo = [self pop];
    hi = [self pop];
    
    pc = (hi << 8) | lo;
}

/*
 RTS  Return from Subroutine
 
 pull PC, PC+1 -> PC              N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       RTS           60    1     6
 */
/* Implementation of RTS */
- (void) RTS_implied
{
    [self debugLogWithFormat:@"RTS"];
    uint8_t lo, hi;
    
    lo = [self pop];
    hi = [self pop];
    
    pc = ((hi << 8) | lo) + 1;
}

/*
 SBC  Subtract Memory from Accumulator with Borrow
 
 A - M - C -> A                   N Z C I D V
 + + + - - +
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 immidiate     SBC #oper     E9    2     2
 zeropage      SBC oper      E5    2     3
 zeropage,X    SBC oper,X    F5    2     4
 absolute      SBC oper      ED    3     4
 absolute,X    SBC oper,X    FD    3     4*
 absolute,Y    SBC oper,Y    F9    3     4*
 (indirect,X)  SBC (oper,X)  E1    2     6
 (indirect),Y  SBC (oper),Y  F1    2     5*
 */
/* Implementation of SBC */
- (void) SBC_immediate
{
    [self debugLogWithFormat:@"SBC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    a = a - param1;
    uint8 v = a;
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of SBC */
- (void) SBC_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"SBC #%04X", param1];
    uint8 val = [ram read: param1];
    a = a - val;
    uint8 v = a;
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of SBC */
- (void) SBC_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"SBC #%04X,X", param1];
    uint8 val = [ram read: param1 + x];
    a = a - val;
    uint8 v = a;
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of SBC */
- (void) SBC_absolute
{
    [self debugLogWithFormat:@"SBC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr];
    a = a - val;
    uint8 v = a;
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of SBC */
- (void) SBC_absoluteX
{
    [self debugLogWithFormat:@"SBC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    a = a - val;
    uint8 v = a;
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of SBC */
- (void) SBC_absoluteY
{
    [self debugLogWithFormat:@"SBC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    pc++;
    uint8 param2 = [ram read: pc + 1];
    [self debugLogWithFormat:@"param = %X", param2];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + y];
    a = a - val;
    uint8 v = a;
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of SBC */
- (void) SBC_indirectX
{
    [self debugLogWithFormat:@"SBC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 param2 = [ram read: pc + 1];
    
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + x];
    a = a - val;
    uint8 v = a;
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/* Implementation of SBC */
- (void) SBC_indirectY
{
    [self debugLogWithFormat:@"SBC"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
    uint8 param2 = [ram read: pc + 1];
    
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    uint8 val = [ram read: addr + y];
    a = a - val;
    uint8 v = a;
    s.status.n = v & 0x80;
    s.status.z = !(v);
    s.status.c = v & 0x80;
}

/*
 SEC  Set Carry Flag
 
 1 -> C                           N Z C I D V
 - - 1 - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       SEC           38    1     2
 */
/* Implementation of SEC */
- (void) SEC_implied
{
    [self debugLogWithFormat:@"SEC"];
    s.status.c = 1;
}

/*
 SED  Set Decimal Flag
 
 1 -> D                           N Z C I D V
 - - - - 1 -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       SED           F8    1     2
 */
/* Implementation of SED */
- (void) SED_implied
{
    [self debugLogWithFormat:@"SED"];
    s.status.d = 1;
}

/*
 SEI  Set Interrupt Disable Status
 
 1 -> I                           N Z C I D V
 - - - 1 - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       SEI           78    1     2
 */
/* Implementation of SEI */
- (void) SEI_implied
{
    [self debugLogWithFormat:@"SEI"];
    s.status.i = 1;
}

/*
 STA  Store Accumulator in Memory
 
 A -> M                           N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 zeropage      STA oper      85    2     3
 zeropage,X    STA oper,X    95    2     4
 absolute      STA oper      8D    3     4
 absolute,X    STA oper,X    9D    3     5
 absolute,Y    STA oper,Y    99    3     5
 (indirect,X)  STA (oper,X)  81    2     6
 (indirect),Y  STA (oper),Y  91    2     6
 */
/* Implementation of STA */
- (void) STA_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"STA #%02x", param1];
    [ram write:a loc:param1];
}

/* Implementation of STA */
- (void) STA_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"STA #%02x,X", param1];
    [ram write:a loc:param1 + x];
}

/* Implementation of STA */
- (void) STA_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [ram write:a loc:addr];
}

/* Implementation of STA */
- (void) STA_absoluteX
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"STA $%04x,X", addr];
    [ram write:a loc:addr + x];
}

/* Implementation of STA */
- (void) STA_absoluteY
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"STA $%04x,Y", addr];
    [ram write:a loc:addr + y];
}

/* Implementation of STA */
- (void) STA_indirectX
{
    [self debugLogWithFormat:@"STA"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
}

/* Implementation of STA */
- (void) STA_indirectY
{
    [self debugLogWithFormat:@"STA"];
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"param = %X", param1];
}

/*
 STX  Store Index X in Memory
 
 X -> M                           N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 zeropage      STX oper      86    2     3
 zeropage,Y    STX oper,Y    96    2     4
 absolute      STX oper      8E    3     4
 */
/* Implementation of STX */
- (void) STX_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"STX $%02x", param1];
    [ram write:x loc:param1];
}

/* Implementation of STX */
- (void) STX_zeropageY
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"STY $%02x,Y", param1];
    [ram write:x loc:param1 + y];
    
}

/* Implementation of STX */
- (void) STX_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"STX $%04x", addr];
    [ram write:x loc:addr];
}

/*
 STY  Sore Index Y in Memory
 
 Y -> M                           N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 zeropage      STY oper      84    2     3
 zeropage,X    STY oper,X    94    2     4
 absolute      STY oper      8C    3     4
 */
/* Implementation of STY */
- (void) STY_zeropage
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"STY $%02x", param1];
    [ram write:y loc:param1];
}

/* Implementation of STY */
- (void) STY_zeropageX
{
    pc++;
    uint8 param1 = [ram read: pc];
    [self debugLogWithFormat:@"STY $%02x,X", param1];
    [ram write:x loc:param1 + x];
}

/* Implementation of STY */
- (void) STY_absolute
{
    pc++;
    uint8 param1 = [ram read: pc];
    pc++;
    uint8 param2 = [ram read: pc];
    uint16 addr = ((uint16)param2 << 8) + (uint16)param1;
    [self debugLogWithFormat:@"STY $%04x", addr];
    [ram write:y loc:addr];
}

/*
 TAX  Transfer Accumulator to Index X
 
 A -> X                           N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       TAX           AA    1     2
 */
/* Implementation of TAX */
- (void) TAX_implied
{
    [self debugLogWithFormat:@"TAX"];
    x = a;
}

/*
 TAY  Transfer Accumulator to Index Y
 
 A -> Y                           N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       TAY           A8    1     2
 */
/* Implementation of TAY */
- (void) TAY_implied
{
    [self debugLogWithFormat:@"TAY"];
    y = a;
}

/*
 TSX  Transfer Stack Pointer to Index X
 
 SP -> X                          N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       TSX           BA    1     2
 */
/* Implementation of TSX */
- (void) TSX_implied
{
    [self debugLogWithFormat:@"TSX"];
    x = sp;
}

/*
 TXA  Transfer Index X to Accumulator
 
 X -> A                           N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       TXA           8A    1     2
 */
/* Implementation of TXA */
- (void) TXA_implied
{
    [self debugLogWithFormat:@"TXA"];
    a = x;
}

/*
 TXS  Transfer Index X to Stack Register
 
 X -> SP                          N Z C I D V
 - - - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       TXS           9A    1     2
 */
/* Implementation of TXS */
- (void) TXS_implied
{
    [self debugLogWithFormat:@"TXS"];
    sp = x;
}

/*
 TYA  Transfer Index Y to Accumulator
 
 Y -> A                           N Z C I D V
 + + - - - -
 
 addressing    assembler    opc  bytes  cyles
 --------------------------------------------
 implied       TYA           98    1     2
 */
/* Implementation of TYA */
- (void) TYA_implied
{
    [self debugLogWithFormat:@"TYA"];
    y = a;
}@end
