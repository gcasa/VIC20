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
    /* DOCS TAKEN FROM: https://www.masswerk.at/6502/6502_instruction_set.html */
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
     BEQ  Branch on Result Zero
     
     branch on Z = 1                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BEQ oper      F0    2     2**
    */
    [self addOpcode:0xf0 name:@"BEQ" params:1 cycles:7 method:@"BEQ_relative"];

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
    [self addOpcode:0x24 name:@"BIT" params:1 cycles:7 method:@"BIT_zeropage"];
    [self addOpcode:0x2c name:@"BIT" params:1 cycles:7 method:@"BIT_absolute"];
    
    /*
     BMI  Branch on Result Minus
     
     branch on N = 1                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BMI oper      30    2     2**
     */
    [self addOpcode:0x30 name:@"BMI" params:1 cycles:7 method:@"BMI_relative"];

    /*
     BNE  Branch on Result not Zero
     
     branch on Z = 0                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BNE oper      D0    2     2**
     */
    [self addOpcode:0xd0 name:@"BNE" params:1 cycles:7 method:@"BNE_relative"];

    /*
     BPL  Branch on Result Plus
     
     branch on N = 0                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BPL oper      10    2     2**
     */
    [self addOpcode:0x10 name:@"BPL" params:1 cycles:7 method:@"BPL_relative"];
    
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
     BVC  Branch on Overflow Clear
     
     branch on V = 0                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BVC oper      50    2     2**
     */
    [self addOpcode:0x50 name:@"BVC" params:1 cycles:7 method:@"BVC_relative"];

    /*
     BVS  Branch on Overflow Set
     
     branch on V = 1                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BVC oper      70    2     2**
     */
    [self addOpcode:0x70 name:@"BVS" params:1 cycles:7 method:@"BVS_relative"];

    /*
     CLC  Clear Carry Flag
     
     0 -> C                           N Z C I D V
                                      - - 0 - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       CLC           18    1     2
     */
    [self addOpcode:0x18 name:@"CLC" params:1 cycles:7 method:@"CLC_implied"];

    /*
     CLD  Clear Decimal Mode
     
     0 -> D                           N Z C I D V
     - - - - 0 -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       CLD           D8    1     2
     */
    [self addOpcode:0xd8 name:@"CLD" params:1 cycles:7 method:@"CLD_implied"];

    /*
     
     CLI  Clear Interrupt Disable Bit
     
     0 -> I                           N Z C I D V
     - - - 0 - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       CLI           58    1     2
     */
    [self addOpcode:0x58 name:@"CLI" params:1 cycles:7 method:@"CLI_implied"];

    /*
     
     CLV  Clear Overflow Flag
     
     0 -> V                           N Z C I D V
     - - - - - 0
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       CLV           B8    1     2
     */
    [self addOpcode:0xb8 name:@"CLV" params:1 cycles:7 method:@"CLV_implied"];

    /*
     CMP  Compare Memory with Accumulator
     
     A - M                            N Z C I D V
     + + + - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     immidiate     CMP #oper     C9    2     2
     zeropage      CMP oper      C5    2     3
     zeropage,X    CMP oper,X    D5    2     4
     absolute      CMP oper      CD    3     4
     absolute,X    CMP oper,X    DD    3     4*
     absolute,Y    CMP oper,Y    D9    3     4*
     (indirect,X)  CMP (oper,X)  C1    2     6
     (indirect),Y  CMP (oper),Y  D1    2     5*
     */
    [self addOpcode:0xc9 name:@"CMP" params:1 cycles:7 method:@"CMP_immediate"];
    [self addOpcode:0xc5 name:@"CMP" params:1 cycles:7 method:@"CMP_zeropage"];
    [self addOpcode:0xd5 name:@"CMP" params:1 cycles:7 method:@"CMP_zeropageX"];
    [self addOpcode:0xcd name:@"CMP" params:1 cycles:7 method:@"CMP_absolute"];
    [self addOpcode:0xdd name:@"CMP" params:1 cycles:7 method:@"CMP_absoluteX"];
    [self addOpcode:0xd9 name:@"CMP" params:1 cycles:7 method:@"CMP_absoluteY"];
    [self addOpcode:0xc1 name:@"CMP" params:1 cycles:7 method:@"CMP_indirectX"];
    [self addOpcode:0xd1 name:@"CMP" params:1 cycles:7 method:@"CMP_indirectY"];

    /*
     CPX  Compare Memory and Index X
     
     X - M                            N Z C I D V
     + + + - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     immidiate     CPX #oper     E0    2     2
     zeropage      CPX oper      E4    2     3
     absolute      CPX oper      EC    3     4
     
     
     CPY  Compare Memory and Index Y
     
     Y - M                            N Z C I D V
     + + + - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     immidiate     CPY #oper     C0    2     2
     zeropage      CPY oper      C4    2     3
     absolute      CPY oper      CC    3     4
     
     
     DEC  Decrement Memory by One
     
     M - 1 -> M                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     zeropage      DEC oper      C6    2     5
     zeropage,X    DEC oper,X    D6    2     6
     absolute      DEC oper      CE    3     3
     absolute,X    DEC oper,X    DE    3     7
     
     
     DEX  Decrement Index X by One
     
     X - 1 -> X                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       DEC           CA    1     2
     
     
     DEY  Decrement Index Y by One
     
     Y - 1 -> Y                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       DEC           88    1     2
     
     
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
     
     
     INC  Increment Memory by One
     
     M + 1 -> M                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     zeropage      INC oper      E6    2     5
     zeropage,X    INC oper,X    F6    2     6
     absolute      INC oper      EE    3     6
     absolute,X    INC oper,X    FE    3     7
     
     
     INX  Increment Index X by One
     
     X + 1 -> X                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       INX           E8    1     2
     
     
     INY  Increment Index Y by One
     
     Y + 1 -> Y                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       INY           C8    1     2
     
     
     JMP  Jump to New Location
     
     (PC+1) -> PCL                    N Z C I D V
     (PC+2) -> PCH                    - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     absolute      JMP oper      4C    3     3
     indirect      JMP (oper)    6C    3     5
     
     
     JSR  Jump to New Location Saving Return Address
     
     push (PC+2),                     N Z C I D V
     (PC+1) -> PCL                    - - - - - -
     (PC+2) -> PCH
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     absolute      JSR oper      20    3     6
     
     
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
     
     
     NOP  No Operation
     
     ---                              N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       NOP           EA    1     2
     */
    
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

     /*
     PHA  Push Accumulator on Stack
     
     push A                           N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       PHA           48    1     3
     */
    [self addOpcode:0x48 name:@"PHA" params:1 cycles:5 method:@"PHA_implied"];

    /*
     
     PHP  Push Processor Status on Stack
     
     push SR                          N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       PHP           08    1     3
     */
    [self addOpcode:0x48 name:@"PHA" params:1 cycles:5 method:@"PHA_implied"];

    /*
     PLA  Pull Accumulator from Stack
     
     pull A                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       PLA           68    1     4
     */
    [self addOpcode:0x68 name:@"PLA" params:1 cycles:5 method:@"PLA_implied"];

    /*
     PLP  Pull Processor Status from Stack
     
     pull SR                          N Z C I D V
     from stack
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       PLP           28    1     4
     */
    [self addOpcode:0x28 name:@"PLP" params:1 cycles:5 method:@"PLP_implied"];

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
    [self addOpcode:0x2a name:@"ROL" params:1 cycles:5 method:@"ROL_accumulator"];
    [self addOpcode:0x26 name:@"ROL" params:1 cycles:5 method:@"ROL_zeropage"];
    [self addOpcode:0x36 name:@"ROL" params:1 cycles:5 method:@"ROL_zeropageX"];
    [self addOpcode:0x2e name:@"ROL" params:1 cycles:5 method:@"ROL_absolute"];
    [self addOpcode:0x3e name:@"ROL" params:1 cycles:5 method:@"ROL_absoluteX"];

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
    [self addOpcode:0x6a name:@"ROR" params:1 cycles:5 method:@"ROR_accumulator"];
    [self addOpcode:0x66 name:@"ROR" params:1 cycles:5 method:@"ROR_zeropage"];
    [self addOpcode:0x76 name:@"ROR" params:1 cycles:5 method:@"ROR_zeropageX"];
    [self addOpcode:0x6e name:@"ROR" params:1 cycles:5 method:@"ROR_absolute"];
    [self addOpcode:0x7e name:@"ROR" params:1 cycles:5 method:@"ROR_absoluteX"];
    
     /*
     RTI  Return from Interrupt
     
     pull SR, pull PC                 N Z C I D V
     from stack
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       RTI           40    1     6
     */
    [self addOpcode:0x40 name:@"RTI" params:1 cycles:5 method:@"RTI_implied"];
    
     /*
     RTS  Return from Subroutine
     
     pull PC, PC+1 -> PC              N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       RTS           60    1     6
     */
    [self addOpcode:0x60 name:@"RTS" params:1 cycles:5 method:@"RTS_implied"];

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
     
     
     SEC  Set Carry Flag
     
     1 -> C                           N Z C I D V
     - - 1 - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       SEC           38    1     2
     
     
     SED  Set Decimal Flag
     
     1 -> D                           N Z C I D V
     - - - - 1 -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       SED           F8    1     2
     
     
     SEI  Set Interrupt Disable Status
     
     1 -> I                           N Z C I D V
     - - - 1 - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       SEI           78    1     2
     
     
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
     
     
     STX  Store Index X in Memory
     
     X -> M                           N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     zeropage      STX oper      86    2     3
     zeropage,Y    STX oper,Y    96    2     4
     absolute      STX oper      8E    3     4
     
     
     STY  Sore Index Y in Memory
     
     Y -> M                           N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     zeropage      STY oper      84    2     3
     zeropage,X    STY oper,X    94    2     4
     absolute      STY oper      8C    3     4
     
     
     TAX  Transfer Accumulator to Index X
     
     A -> X                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TAX           AA    1     2
     
     
     TAY  Transfer Accumulator to Index Y
     
     A -> Y                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TAY           A8    1     2
    */
    
     /*
     TSX  Transfer Stack Pointer to Index X
     
     SP -> X                          N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TSX           BA    1     2
     */
    
    /*
     TXA  Transfer Index X to Accumulator
     
     X -> A                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TXA           8A    1     2
    */
    
    /*
     TXS  Transfer Index X to Stack Register
     
     X -> SP                          N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TXS           9A    1     2
     */
    
     /*
     TYA  Transfer Index Y to Accumulator
     
     Y -> A                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TYA           98    1     2
     */

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
