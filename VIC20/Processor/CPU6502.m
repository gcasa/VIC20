//
//  CPU6502.m
//  VIC20
//
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "CPU6502.h"
#import "RAM.h"
#import "ROM.h"

@implementation CPU6502

/*
 HI    LO-NIBBLE
       00          01          02     03     04        05         06         07   08       09         0A       0B   0C        0D          0E         0F
 00    BRK impl    ORA X,ind   ---    ---    ---       ORA zpg    ASL zpg    ---  PHP impl ORA #      ASL A    ---  ---       ORA abs     ASL abs    ---
 10    BPL rel     ORA ind,Y   ---    ---    ---       ORA zpg,X  ASL zpg,X  ---  CLC impl ORA abs,Y  ---      ---  ---       ORA abs,X   ASL abs,X  ---
 20    JSR abs     AND X,ind   ---    ---    BIT zpg   AND zpg    ROL zpg    ---  PLP impl AND #      ROL A    ---  BIT abs   AND abs     ROL abs    ---
 30    BMI rel     AND ind,Y   ---    ---    ---       AND zpg,X  ROL zpg,X  ---  SEC impl AND abs,Y  ---      ---  ---       AND abs,X   ROL abs,X  ---
 40    RTI impl    EOR X,ind   ---    ---    ---       EOR zpg    LSR zpg    ---  PHA impl EOR #      LSR A    ---  JMP abs   EOR abs     LSR abs    ---
 50    BVC rel     EOR ind,Y   ---    ---    ---       EOR zpg,X  LSR zpg,X  ---  CLI impl EOR abs,Y  ---      ---  ---       EOR abs,X   LSR abs,X  ---
 60    RTS impl    ADC X,ind   ---    ---    ---       ADC zpg    ROR zpg    ---  PLA impl ADC #      ROR A    ---  JMP ind   ADC abs     ROR abs    ---
 70    BVS rel     ADC ind,Y   ---    ---    ---       ADC zpg,X  ROR zpg,X  ---  SEI impl ADC abs,Y  ---      ---  ---       ADC abs,X   ROR abs,X  ---
 80    ---         STA X,ind   ---    ---    STY zpg   STA zpg    STX zpg    ---  DEY impl ---        TXA impl ---  STY abs   STA abs     STX abs    ---
 90    BCC rel     STA ind,Y   ---    ---    STY zpg,X STA zpg,X  STX zpg,Y  ---  TYA impl STA abs,Y  TXS impl ---  ---       STA abs,X   ---        ---
 A0    LDY #       LDA X,ind   LDX #  ---    LDY zpg   LDA zpg    LDX zpg    ---  TAY impl LDA #      TAX impl ---  LDY abs   LDA abs     LDX abs    ---
 B0    BCS rel     LDA ind,Y   ---    ---    LDY zpg,X LDA zpg,X  LDX zpg,Y  ---  CLV impl LDA abs,Y  TSX impl ---  LDY abs,X LDA abs,X   LDX abs,Y  ---
 C0    CPY #       CMP X,ind   ---    ---    CPY zpg   CMP zpg    DEC zpg    ---  INY impl CMP #      DEX impl ---  CPY abs   CMP abs     DEC abs    ---
 D0    BNE rel     CMP ind,Y   ---    ---    ---       CMP zpg,X  DEC zpg,X  ---  CLD impl CMP abs,Y  ---      ---  ---       CMP abs,X   DEC abs,X  ---
 E0    CPX #       SBC X,ind   ---    ---    CPX zpg   SBC zpg    INC zpg    ---  INX impl SBC #      NOP impl ---  CPX abs   SBC abs     INC abs    ---
 F0    BEQ rel     SBC ind,Y   ---    ---    ---       SBC zpg,X  INC zpg,X  ---  SED impl SBC abs,Y  ---      ---  ---       SBC abs,X   INC abs,X  ---
 */

static NSMutableDictionary *instructionMap;

+ (NSDictionary *)buildDictForInstructionName: (NSString *)name
                                    paramters: (NSNumber *)parameters
                                       cycles: (NSNumber *)cycles
                                       method: (NSString *)methodName
{
    NSDictionary *insDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"name", name,
                             @"paramters", parameters,
                             @"cycles", cycles,
                             @"methodName", methodName, nil];
    return insDict;
}

+ (void) addOpcode: (NSInteger)op
              name: (NSString *)name
            params: (NSInteger)par
            cycles: (NSInteger)cycles
            method: (NSString *)method
{
    NSDictionary *dict = [self buildDictForInstructionName:name
                                                 paramters:[NSNumber numberWithInteger:par]
                                                    cycles:[NSNumber numberWithInteger:cycles]
                                                    method:method];
    [instructionMap setObject: dict forKey:[NSNumber numberWithInteger:op]];
}

+ (void) buildInstructionMap
{
    instructionMap = [NSMutableDictionary dictionary];
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
    [self addOpcode:0x69 name:@"ADC" params:1 cycles:7 method:@"ADC_immediate"];
    [self addOpcode:0x65 name:@"ADC" params:1 cycles:7 method:@"ADC_zeropage"];
    [self addOpcode:0x75 name:@"ADC" params:1 cycles:7 method:@"ADC_zeropageX"];
    [self addOpcode:0x6d name:@"ADC" params:1 cycles:7 method:@"ADC_absolute"];
    [self addOpcode:0x7d name:@"ADC" params:1 cycles:7 method:@"ADC_absoluteX"];
    [self addOpcode:0x79 name:@"ADC" params:1 cycles:7 method:@"ADC_absoluteY"];
    [self addOpcode:0x61 name:@"ADC" params:1 cycles:7 method:@"ADC_indirectX"];
    [self addOpcode:0x71 name:@"ADC" params:1 cycles:7 method:@"ADC_indirectY"];
    
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
    [self addOpcode:0x29 name:@"AND" params:1 cycles:7 method:@"AND_immediate"];
    [self addOpcode:0x25 name:@"AND" params:1 cycles:7 method:@"AND_zeropage"];
    [self addOpcode:0x35 name:@"AND" params:1 cycles:7 method:@"AND_zeropageX"];
    [self addOpcode:0x2d name:@"AND" params:1 cycles:7 method:@"AND_absolute"];
    [self addOpcode:0x3d name:@"AND" params:1 cycles:7 method:@"AND_absoluteX"];
    [self addOpcode:0x39 name:@"AND" params:1 cycles:7 method:@"AND_absoluteY"];
    [self addOpcode:0x21 name:@"AND" params:1 cycles:7 method:@"AND_indirectX"];
    [self addOpcode:0x31 name:@"AND" params:1 cycles:7 method:@"AND_indirectY"];
    
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
    [self addOpcode:0x29 name:@"ASL" params:1 cycles:7 method:@"ASL_accumulator"];
    [self addOpcode:0x25 name:@"ASL" params:1 cycles:7 method:@"ASL_zeropage"];
    [self addOpcode:0x35 name:@"ASL" params:1 cycles:7 method:@"ASL_zeropageX"];
    [self addOpcode:0x2d name:@"ASL" params:1 cycles:7 method:@"ASL_absolute"];
    [self addOpcode:0x3d name:@"ASL" params:1 cycles:7 method:@"ASL_absoluteX"];
    
    /*
     BCC  Branch on Carry Clear
     
     branch on C = 0                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BCC oper      90    2     2**
     */
    [self addOpcode:0x90 name:@"BCC" params:1 cycles:7 method:@"BCC_relative"];
    
    /*
     BCS  Branch on Carry Set
     
     branch on C = 1                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BCS oper      B0    2     2**
     */
    [self addOpcode:0xb0 name:@"BCS" params:1 cycles:7 method:@"BCS_relative"];
    
    /*
     BRK  Force Break
     
     interrupt,                       N Z C I D V
     push PC+2, push SR               - - - 1 - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       BRK           00    1     7
     */
    [self addOpcode:0x00 name:@"BRK" params:1 cycles:7 method:@"BRK_implied"];
    
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
    [self addOpcode:0x09 name:@"ORA" params:1 cycles:2 method:@"ORA_immediate"];
    [self addOpcode:0x05 name:@"ORA" params:1 cycles:3 method:@"ORA_zeropage"];
    [self addOpcode:0x15 name:@"ORA" params:1 cycles:4 method:@"ORA_zeropageX"];
    [self addOpcode:0x0D name:@"ORA" params:1 cycles:4 method:@"ORA_absolute"];
    [self addOpcode:0x1D name:@"ORA" params:1 cycles:4 method:@"ORA_absoluteX"];
    [self addOpcode:0x19 name:@"ORA" params:1 cycles:4 method:@"ORA_absoluteY"];
    [self addOpcode:0x01 name:@"ORA" params:1 cycles:6 method:@"ORA_indirectX"];
    [self addOpcode:0x11 name:@"ORA" params:1 cycles:5 method:@"ORA_indirectY"];

}

+ (void) initialize
{
    [self buildInstructionMap];
}

- (id) initWithSize: (NSUInteger)size
{
    if (([super init]) != nil)
    {
        [self reset];
        ram = [[RAM alloc] initWithSize: size];
    }
    return nil;
}

- (void) reset
{
    // Initialize registers...
    a  = 0x00;
    x  = 0x00;
    y  = 0x00;
    pc = 0x00;
    p  = 0x00;
    sp = 0x00;
    sr = 0xFF;
    
    // Initialize flags...
    s  = 0x00;
    b  = 0x00;
    d  = 0x00;
    i  = 0x00;
    z  = 0x00;
    c  = 0x00;
}

- (void) interrupt
{
    
}

- (void) fetch
{
    
}

- (void) execute
{
    
}

- (void) step
{
    
}

- (void) state
{
    NSLog(@"A = %08x, X = %08x, Y = %08x, PC = %08x, P = %08x, SP = %08x", a, x, y, pc, p, sp);
}

- (void) tick
{
    
}

// Instruction interpretation....
- (void) executeOperation: (uint8)operation
{
    
}



@end
