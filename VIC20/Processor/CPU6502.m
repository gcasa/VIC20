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

/*  CPU INSTRUCTION TABLE
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
static NSMutableArray *opCodes;
static NSString *methodsString;

+ (NSDictionary *)buildDictForInstructionName: (NSString *)name
                                    paramters: (NSNumber *)parameters
                                       cycles: (NSNumber *)cycles
                                       method: (NSString *)methodName
{
    NSDictionary *insDict = [NSDictionary dictionaryWithObjectsAndKeys:
                             name, @"name",
                             parameters, @"parameters",
                             cycles, @"cycles",
                             methodName, @"methodName", nil];
    return insDict;
}

+ (void) addOpcode: (NSInteger)op
              name: (NSString *)name
            params: (NSInteger)par
            cycles: (NSInteger)cycles
            method: (NSString *)method
{
    NSNumber *opcode = [NSNumber numberWithInteger:op];
    NSDictionary *dict = [self buildDictForInstructionName:name
                                                 paramters:[NSNumber numberWithInteger:par]
                                                    cycles:[NSNumber numberWithInteger:cycles]
                                                    method:method];
    [instructionMap setObject: dict forKey:opcode];
    [opCodes addObject:opcode];
}

+ (void) generateMethodForDict: (NSDictionary *)dict
{
    NSString *name = [dict objectForKey:@"name"];
    NSString *mname = [dict objectForKey:@"methodName"];
    NSNumber *parameters = [dict objectForKey:@"parameters"];
    NSInteger par = [parameters integerValue];
    NSString *methodString = nil;
    NSString *parameterStatements = @"";
    
    // compose parameters...
    for(int i = 0; i < par - 1; i++)
    {
        parameterStatements = [parameterStatements stringByAppendingFormat:@"    pc++;\n"];
        parameterStatements = [parameterStatements stringByAppendingFormat:@"    uint16 param%d = [ram read: pc];\n",i+1];
        parameterStatements = [parameterStatements stringByAppendingFormat:@"    NSLog(@\"param = %@\", param%d);\n",@"%x", i+1];
    }
    
    // Build method....
    methodString = [NSString stringWithFormat:
                    @"/* Implementation of %@ */\n"
                    @"- (void) %@\n"
                    @"{\n"
                    @"    NSLog(@\"%@\");\n"
                    @"%@"
                    @"}\n",name, mname,
                        name, parameterStatements];

    // Add to methods...
    methodsString = [methodsString stringByAppendingString: methodString];
    methodsString = [methodsString stringByAppendingString: @"\n"];
}

+ (void) generateMethods
{
    NSEnumerator *en = [opCodes objectEnumerator];
    NSObject *k = nil;
    while((k = [en nextObject]) != nil)
    {
        NSDictionary *o = [instructionMap objectForKey:k];
        [self generateMethodForDict: o];
    }
    NSLog(@"\n%@",methodsString);
}

+ (void) buildInstructionMap
{
    NSLog(@"####### Initializing CPU");

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
    opCodes = [NSMutableArray array];
    methodsString = @"";
    
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
    [self addOpcode:0x69 name:@"ADC" params:2 cycles:2 method:@"ADC_immediate"];
    [self addOpcode:0x65 name:@"ADC" params:2 cycles:3 method:@"ADC_zeropage"];
    [self addOpcode:0x75 name:@"ADC" params:2 cycles:4 method:@"ADC_zeropageX"];
    [self addOpcode:0x6d name:@"ADC" params:3 cycles:4 method:@"ADC_absolute"];
    [self addOpcode:0x7d name:@"ADC" params:3 cycles:4 method:@"ADC_absoluteX"];
    [self addOpcode:0x79 name:@"ADC" params:3 cycles:4 method:@"ADC_absoluteY"];
    [self addOpcode:0x61 name:@"ADC" params:4 cycles:6 method:@"ADC_indirectX"];
    [self addOpcode:0x71 name:@"ADC" params:4 cycles:5 method:@"ADC_indirectY"];
    
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
    [self addOpcode:0x29 name:@"AND" params:2 cycles:2 method:@"AND_immediate"];
    [self addOpcode:0x25 name:@"AND" params:2 cycles:3 method:@"AND_zeropage"];
    [self addOpcode:0x35 name:@"AND" params:2 cycles:4 method:@"AND_zeropageX"];
    [self addOpcode:0x2d name:@"AND" params:3 cycles:4 method:@"AND_absolute"];
    [self addOpcode:0x3d name:@"AND" params:3 cycles:4 method:@"AND_absoluteX"];
    [self addOpcode:0x39 name:@"AND" params:3 cycles:4 method:@"AND_absoluteY"];
    [self addOpcode:0x21 name:@"AND" params:2 cycles:6 method:@"AND_indirectX"];
    [self addOpcode:0x31 name:@"AND" params:2 cycles:5 method:@"AND_indirectY"];
    
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
    [self addOpcode:0x0a name:@"ASL" params:1 cycles:2 method:@"ASL_accumulator"];
    [self addOpcode:0x06 name:@"ASL" params:2 cycles:5 method:@"ASL_zeropage"];
    [self addOpcode:0x16 name:@"ASL" params:2 cycles:6 method:@"ASL_zeropageX"];
    [self addOpcode:0x0e name:@"ASL" params:3 cycles:6 method:@"ASL_absolute"];
    [self addOpcode:0x1e name:@"ASL" params:3 cycles:7 method:@"ASL_absoluteX"];
    
    /*
     BCC  Branch on Carry Clear
     
     branch on C = 0                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BCC oper      90    2     2**
     */
    [self addOpcode:0x90 name:@"BCC" params:2 cycles:2 method:@"BCC_relative"];
    
    /*
     BCS  Branch on Carry Set
     
     branch on C = 1                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BCS oper      B0    2     2**
     */
    [self addOpcode:0xb0 name:@"BCS" params:2 cycles:2 method:@"BCS_relative"];
    
    /*
     BEQ  Branch on Result Zero
     
     branch on Z = 1                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BEQ oper      F0    2     2**
    */
    [self addOpcode:0xf0 name:@"BEQ" params:2 cycles:2 method:@"BEQ_relative"];

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
    [self addOpcode:0x24 name:@"BIT" params:2 cycles:3 method:@"BIT_zeropage"];
    [self addOpcode:0x2c name:@"BIT" params:3 cycles:4 method:@"BIT_absolute"];
    
    /*
     BMI  Branch on Result Minus
     
     branch on N = 1                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BMI oper      30    2     2**
     */
    [self addOpcode:0x30 name:@"BMI" params:2 cycles:2 method:@"BMI_relative"];

    /*
     BNE  Branch on Result not Zero
     
     branch on Z = 0                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BNE oper      D0    2     2**
     */
    [self addOpcode:0xd0 name:@"BNE" params:2 cycles:2 method:@"BNE_relative"];

    /*
     BPL  Branch on Result Plus
     
     branch on N = 0                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BPL oper      10    2     2**
     */
    [self addOpcode:0x10 name:@"BPL" params:2 cycles:2 method:@"BPL_relative"];
    
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
    [self addOpcode:0x50 name:@"BVC" params:2 cycles:2 method:@"BVC_relative"];

    /*
     BVS  Branch on Overflow Set
     
     branch on V = 1                  N Z C I D V
                                      - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     relative      BVC oper      70    2     2**
     */
    [self addOpcode:0x70 name:@"BVS" params:2 cycles:2 method:@"BVS_relative"];

    /*
     CLC  Clear Carry Flag
     
     0 -> C                           N Z C I D V
                                      - - 0 - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       CLC           18    1     2
     */
    [self addOpcode:0x18 name:@"CLC" params:2 cycles:2 method:@"CLC_implied"];

    /*
     CLD  Clear Decimal Mode
     
     0 -> D                           N Z C I D V
     - - - - 0 -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       CLD           D8    1     2
     */
    [self addOpcode:0xd8 name:@"CLD" params:1 cycles:2 method:@"CLD_implied"];

    /*
     
     CLI  Clear Interrupt Disable Bit
     
     0 -> I                           N Z C I D V
     - - - 0 - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       CLI           58    1     2
     */
    [self addOpcode:0x58 name:@"CLI" params:1 cycles:2 method:@"CLI_implied"];

    /*
     
     CLV  Clear Overflow Flag
     
     0 -> V                           N Z C I D V
     - - - - - 0
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       CLV           B8    1     2
     */
    [self addOpcode:0xb8 name:@"CLV" params:1 cycles:2 method:@"CLV_implied"];

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
    [self addOpcode:0xc9 name:@"CMP" params:2 cycles:2 method:@"CMP_immediate"];
    [self addOpcode:0xc5 name:@"CMP" params:2 cycles:3 method:@"CMP_zeropage"];
    [self addOpcode:0xd5 name:@"CMP" params:2 cycles:4 method:@"CMP_zeropageX"];
    [self addOpcode:0xcd name:@"CMP" params:3 cycles:4 method:@"CMP_absolute"];
    [self addOpcode:0xdd name:@"CMP" params:3 cycles:4 method:@"CMP_absoluteX"];
    [self addOpcode:0xd9 name:@"CMP" params:3 cycles:4 method:@"CMP_absoluteY"];
    [self addOpcode:0xc1 name:@"CMP" params:2 cycles:6 method:@"CMP_indirectX"];
    [self addOpcode:0xd1 name:@"CMP" params:2 cycles:5 method:@"CMP_indirectY"];

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
    [self addOpcode:0xe0 name:@"CPX" params:2 cycles:2 method:@"CPX_immediate"];
    [self addOpcode:0xe4 name:@"CPX" params:2 cycles:3 method:@"CPX_zeropage"];
    [self addOpcode:0xec name:@"CPX" params:3 cycles:4 method:@"CPX_absolute"];

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
    [self addOpcode:0xc0 name:@"CPY" params:2 cycles:2 method:@"CPY_immediate"];
    [self addOpcode:0xc4 name:@"CPY" params:2 cycles:3 method:@"CPY_zeropage"];
    [self addOpcode:0xcc name:@"CPY" params:3 cycles:4 method:@"CPY_absolute"];

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
    [self addOpcode:0xc6 name:@"DEC" params:2 cycles:2 method:@"DEC_zeropage"];
    [self addOpcode:0xd6 name:@"DEC" params:2 cycles:3 method:@"DEC_zeropageX"];
    [self addOpcode:0xce name:@"DEC" params:3 cycles:4 method:@"DEC_absolute"];
    [self addOpcode:0xde name:@"DEC" params:3 cycles:4 method:@"DEC_absoluteX"];

     /*
     DEX  Decrement Index X by One
     
     X - 1 -> X                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       DEC           CA    1     2
     */
    [self addOpcode:0xca name:@"DEX" params:1 cycles:2 method:@"DEX_implied"];

    /*
     DEY  Decrement Index Y by One
     
     Y - 1 -> Y                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       DEC           88    1     2
    */
    [self addOpcode:0x88 name:@"DEY" params:1 cycles:2 method:@"DEY_implied"];

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
    [self addOpcode:0x49 name:@"EOR" params:2 cycles:2 method:@"EOR_immediate"];
    [self addOpcode:0x45 name:@"EOR" params:2 cycles:3 method:@"EOR_zeropage"];
    [self addOpcode:0x55 name:@"EOR" params:2 cycles:4 method:@"EOR_zeropageX"];
    [self addOpcode:0x4d name:@"EOR" params:3 cycles:4 method:@"EOR_absolute"];
    [self addOpcode:0x5d name:@"EOR" params:3 cycles:4 method:@"EOR_absoluteX"];
    [self addOpcode:0x59 name:@"EOR" params:3 cycles:4 method:@"EOR_absoluteY"];
    [self addOpcode:0x41 name:@"EOR" params:2 cycles:6 method:@"EOR_indirectX"];
    [self addOpcode:0x51 name:@"EOR" params:2 cycles:5 method:@"EOR_indirectY"];
    
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
    [self addOpcode:0xe6 name:@"INC" params:2 cycles:2 method:@"INC_zeropage"];
    [self addOpcode:0xf6 name:@"INC" params:2 cycles:3 method:@"INC_zeropageX"];
    [self addOpcode:0xee name:@"INC" params:3 cycles:4 method:@"INC_absolute"];
    [self addOpcode:0xfe name:@"INC" params:3 cycles:4 method:@"INC_absoluteX"];

    /*
     INX  Increment Index X by One
     
     X + 1 -> X                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       INX           E8    1     2
     */
    [self addOpcode:0xe8 name:@"INX" params:1 cycles:2 method:@"INX_implied"];

    /*
     INY  Increment Index Y by One
     
     Y + 1 -> Y                       N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       INY           C8    1     2
    */
    [self addOpcode:0xc8 name:@"INY" params:1 cycles:2 method:@"INY_implied"];

    /*
     JMP  Jump to New Location
     
     (PC+1) -> PCL                    N Z C I D V
     (PC+2) -> PCH                    - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     absolute      JMP oper      4C    3     3
     indirect      JMP (oper)    6C    3     5
     */
    [self addOpcode:0x4c name:@"JMP" params:1 cycles:2 method:@"INX_absolute"];
    [self addOpcode:0x6c name:@"JMP" params:1 cycles:2 method:@"JMP_indirect"];

    /*
     JSR  Jump to New Location Saving Return Address
     
     push (PC+2),                     N Z C I D V
     (PC+1) -> PCL                    - - - - - -
     (PC+2) -> PCH
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     absolute      JSR oper      20    3     6
     */
    [self addOpcode:0x20 name:@"JSR" params:3 cycles:6 method:@"JSR_absolute"];
    
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
    [self addOpcode:0xa9 name:@"LDA" params:2 cycles:2 method:@"LDA_immediate"];
    [self addOpcode:0xa5 name:@"LDA" params:2 cycles:3 method:@"LDA_zeropage"];
    [self addOpcode:0xb5 name:@"LDA" params:2 cycles:4 method:@"LDA_zeropageX"];
    [self addOpcode:0xad name:@"LDA" params:3 cycles:4 method:@"LDA_absolute"];
    [self addOpcode:0xbd name:@"LDA" params:3 cycles:4 method:@"LDA_absoluteX"];
    [self addOpcode:0xb9 name:@"LDA" params:3 cycles:4 method:@"LDA_absoluteY"];
    [self addOpcode:0xa1 name:@"LDA" params:2 cycles:6 method:@"LDA_indirectX"];
    [self addOpcode:0xb1 name:@"LDA" params:2 cycles:5 method:@"LDA_indirectY"];
    
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
    [self addOpcode:0xa2 name:@"LDX" params:2 cycles:2 method:@"LDX_immediate"];
    [self addOpcode:0xa6 name:@"LDX" params:2 cycles:3 method:@"LDX_zeropage"];
    [self addOpcode:0xb6 name:@"LDX" params:2 cycles:4 method:@"LDX_zeropageY"];
    [self addOpcode:0xae name:@"LDX" params:3 cycles:4 method:@"LDX_absolute"];
    [self addOpcode:0xbe name:@"LDX" params:3 cycles:4 method:@"LDX_absoluteY"];
    
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
    [self addOpcode:0xa0 name:@"LDY" params:2 cycles:2 method:@"LDY_immediate"];
    [self addOpcode:0xa4 name:@"LDY" params:2 cycles:3 method:@"LDY_zeropage"];
    [self addOpcode:0xb4 name:@"LDY" params:2 cycles:4 method:@"LDY_zeropageX"];
    [self addOpcode:0xac name:@"LDY" params:3 cycles:4 method:@"LDY_absolute"];
    [self addOpcode:0xbc name:@"LDY" params:3 cycles:4 method:@"LDY_absoluteX"];

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
    [self addOpcode:0x4a name:@"LSR" params:2 cycles:2 method:@"LSR_accumulator"];
    [self addOpcode:0x46 name:@"LSR" params:2 cycles:3 method:@"LSR_zeropage"];
    [self addOpcode:0x56 name:@"LSR" params:2 cycles:4 method:@"LSR_zeropageX"];
    [self addOpcode:0x4e name:@"LSR" params:3 cycles:4 method:@"LSR_absolute"];
    [self addOpcode:0x5e name:@"LSR" params:3 cycles:4 method:@"LSR_absoluteX"];
    /*
     NOP  No Operation
     
     ---                              N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       NOP           EA    1     2
     */
    [self addOpcode:0xea name:@"NOP" params:1 cycles:2 method:@"NOP_implied"];
    
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
    [self addOpcode:0x09 name:@"ORA" params:2 cycles:2 method:@"ORA_immediate"];
    [self addOpcode:0x05 name:@"ORA" params:2 cycles:3 method:@"ORA_zeropage"];
    [self addOpcode:0x15 name:@"ORA" params:2 cycles:4 method:@"ORA_zeropageX"];
    [self addOpcode:0x0D name:@"ORA" params:3 cycles:4 method:@"ORA_absolute"];
    [self addOpcode:0x1D name:@"ORA" params:3 cycles:4 method:@"ORA_absoluteX"];
    [self addOpcode:0x19 name:@"ORA" params:3 cycles:4 method:@"ORA_absoluteY"];
    [self addOpcode:0x01 name:@"ORA" params:2 cycles:6 method:@"ORA_indirectX"];
    [self addOpcode:0x11 name:@"ORA" params:2 cycles:5 method:@"ORA_indirectY"];

     /*
     PHA  Push Accumulator on Stack
     
     push A                           N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       PHA           48    1     3
     */
    [self addOpcode:0x48 name:@"PHA" params:1 cycles:3 method:@"PHA_implied"];

    /*
     
     PHP  Push Processor Status on Stack
     
     push SR                          N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       PHP           08    1     3
     */
    [self addOpcode:0x08 name:@"PHP" params:1 cycles:3 method:@"PHP_implied"];

    /*
     PLA  Pull Accumulator from Stack
     
     pull A                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       PLA           68    1     4
     */
    [self addOpcode:0x68 name:@"PLA" params:1 cycles:4 method:@"PLA_implied"];

    /*
     PLP  Pull Processor Status from Stack
     
     pull SR                          N Z C I D V
     from stack
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       PLP           28    1     4
     */
    [self addOpcode:0x28 name:@"PLP" params:1 cycles:4 method:@"PLP_implied"];

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
    [self addOpcode:0x2a name:@"ROL" params:1 cycles:2 method:@"ROL_accumulator"];
    [self addOpcode:0x26 name:@"ROL" params:2 cycles:5 method:@"ROL_zeropage"];
    [self addOpcode:0x36 name:@"ROL" params:2 cycles:6 method:@"ROL_zeropageX"];
    [self addOpcode:0x2e name:@"ROL" params:3 cycles:6 method:@"ROL_absolute"];
    [self addOpcode:0x3e name:@"ROL" params:3 cycles:7 method:@"ROL_absoluteX"];

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
    [self addOpcode:0x6a name:@"ROR" params:1 cycles:2 method:@"ROR_accumulator"];
    [self addOpcode:0x66 name:@"ROR" params:2 cycles:5 method:@"ROR_zeropage"];
    [self addOpcode:0x76 name:@"ROR" params:2 cycles:6 method:@"ROR_zeropageX"];
    [self addOpcode:0x6e name:@"ROR" params:3 cycles:6 method:@"ROR_absolute"];
    [self addOpcode:0x7e name:@"ROR" params:3 cycles:7 method:@"ROR_absoluteX"];
    
     /*
     RTI  Return from Interrupt
     
     pull SR, pull PC                 N Z C I D V
     from stack
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       RTI           40    1     6
     */
    [self addOpcode:0x40 name:@"RTI" params:1 cycles:6 method:@"RTI_implied"];
    
     /*
     RTS  Return from Subroutine
     
     pull PC, PC+1 -> PC              N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       RTS           60    1     6
     */
    [self addOpcode:0x60 name:@"RTS" params:1 cycles:6 method:@"RTS_implied"];

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
    [self addOpcode:0xe9 name:@"SBC" params:2 cycles:2 method:@"SBC_immediate"];
    [self addOpcode:0xe5 name:@"SBC" params:2 cycles:3 method:@"SBC_zeropage"];
    [self addOpcode:0xf5 name:@"SBC" params:2 cycles:4 method:@"SBC_zeropageX"];
    [self addOpcode:0xed name:@"SBC" params:3 cycles:4 method:@"SBC_absolute"];
    [self addOpcode:0xfd name:@"SBC" params:3 cycles:4 method:@"SBC_absoluteX"];
    [self addOpcode:0xf9 name:@"SBC" params:3 cycles:4 method:@"SBC_absoluteY"];
    [self addOpcode:0xe1 name:@"SBC" params:2 cycles:6 method:@"SBC_indirectX"];
    [self addOpcode:0xf1 name:@"SBC" params:2 cycles:5 method:@"SBC_indirectY"];
    
     /*
     SEC  Set Carry Flag
     
     1 -> C                           N Z C I D V
     - - 1 - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       SEC           38    1     2
     */
    [self addOpcode:0x38 name:@"SEC" params:1 cycles:2 method:@"SEC_implied"];

    /*
     SED  Set Decimal Flag
     
     1 -> D                           N Z C I D V
     - - - - 1 -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       SED           F8    1     2
     */
    [self addOpcode:0xf8 name:@"SED" params:1 cycles:2 method:@"SED_implied"];

     /*
     SEI  Set Interrupt Disable Status
     
     1 -> I                           N Z C I D V
     - - - 1 - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       SEI           78    1     2
     */
    [self addOpcode:0x78 name:@"SEI" params:1 cycles:2 method:@"SEI_implied"];

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
    [self addOpcode:0x85 name:@"STA" params:2 cycles:3 method:@"STA_zeropage"];
    [self addOpcode:0x95 name:@"STA" params:2 cycles:4 method:@"STA_zeropageX"];
    [self addOpcode:0x8d name:@"STA" params:3 cycles:4 method:@"STA_absolute"];
    [self addOpcode:0x9d name:@"STA" params:3 cycles:5 method:@"STA_absoluteX"];
    [self addOpcode:0x99 name:@"STA" params:3 cycles:5 method:@"STA_absoluteY"];
    [self addOpcode:0x81 name:@"STA" params:2 cycles:6 method:@"STA_indirectX"];
    [self addOpcode:0x91 name:@"STA" params:2 cycles:6 method:@"STA_inderectY"];

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
    [self addOpcode:0x86 name:@"STX" params:2 cycles:3 method:@"STX_zeropage"];
    [self addOpcode:0x96 name:@"STX" params:2 cycles:4 method:@"STX_zeropageY"];
    [self addOpcode:0x8e name:@"STX" params:3 cycles:4 method:@"STX_absolute"];
    
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
    [self addOpcode:0x84 name:@"STY" params:2 cycles:3 method:@"STY_zeropage"];
    [self addOpcode:0x94 name:@"STY" params:2 cycles:4 method:@"STY_zeropageX"];
    [self addOpcode:0x8c name:@"STY" params:3 cycles:4 method:@"STY_absolute"];

    /*
     TAX  Transfer Accumulator to Index X
     
     A -> X                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TAX           AA    1     2
     */
    [self addOpcode:0xaa name:@"TAX" params:1 cycles:2 method:@"TAX_implied"];

    /*
     TAY  Transfer Accumulator to Index Y
     
     A -> Y                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TAY           A8    1     2
    */
    [self addOpcode:0xa8 name:@"TAY" params:1 cycles:2 method:@"TAY_implied"];

     /*
     TSX  Transfer Stack Pointer to Index X
     
     SP -> X                          N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TSX           BA    1     2
     */
    [self addOpcode:0xba name:@"TSX" params:1 cycles:2 method:@"TSX_implied"];

    /*
     TXA  Transfer Index X to Accumulator
     
     X -> A                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TXA           8A    1     2
    */
    [self addOpcode:0x8a name:@"TXA" params:1 cycles:2 method:@"TXA_implied"];

    /*
     TXS  Transfer Index X to Stack Register
     
     X -> SP                          N Z C I D V
     - - - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TXS           9A    1     2
     */
    [self addOpcode:0x9a name:@"TXS" params:1 cycles:2 method:@"TXS_implied"];

     /*
     TYA  Transfer Index Y to Accumulator
     
     Y -> A                           N Z C I D V
     + + - - - -
     
     addressing    assembler    opc  bytes  cyles
     --------------------------------------------
     implied       TYA           98    1     2
     */
    [self addOpcode:0x98 name:@"TYA" params:1 cycles:2 method:@"TYA_implied"];

    [self generateMethods];  /* Used to generate the method calls for each instruction */
    NSLog(@"####### Finished initializing CPU");
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
    return self;
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
    s  = NO;
    b  = NO;
    d  = NO;
    i  = NO;
    z  = NO;
    c  = NO;
}

- (void) interrupt
{
    
}

- (void) fetch
{
    uint8 opcode = [ram read: pc];
    currentInstruction = [NSNumber numberWithInt: opcode];
}

- (void) execute
{
    [self fetch];
    [self executeOperation: currentInstruction];
}

- (void) executeAtLocation: (uint16)loc
{
    pc = loc;
    [self execute];
}

- (void) loadProgramFile: (NSString *)fileName atLocation: (uint16)loc
{
    [ram loadProgramFile:fileName atLocation:loc];
}

- (void) runAtLocation: (uint16)loc
{
    // return;
    pc = loc;
    [self fetch];
    while([currentInstruction integerValue] != 0x00)
    {
        [self execute];
    }
}

- (void) run
{
    [self runAtLocation:0];
}

- (void) step
{
    pc++;
}

- (void) state
{
    NSLog(@"A = %08x, X = %08x, Y = %08x, PC = %08x, P = %08x, SP = %08x", a, x, y, pc, p, sp);
}

- (void) tick
{
    
}

// Instruction interpretation....
- (void) executeOperation: (NSNumber *)operation
{
    NSString *methodName = [[instructionMap objectForKey:operation] objectForKey: @"methodName"];
    // NSLog(@"methodName = %@",methodName);
    SEL selector = NSSelectorFromString(methodName);
    [self performSelector:selector];
    [self step];
}

// Instruction implementations...
/* Implementation of ADC */
- (void) ADC_immediate
{
    NSLog(@"ADC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ADC */
- (void) ADC_zeropage
{
    NSLog(@"ADC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ADC */
- (void) ADC_zeropageX
{
    NSLog(@"ADC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ADC */
- (void) ADC_absolute
{
    NSLog(@"ADC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ADC */
- (void) ADC_absoluteX
{
    NSLog(@"ADC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ADC */
- (void) ADC_absoluteY
{
    NSLog(@"ADC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ADC */
- (void) ADC_indirectX
{
    NSLog(@"ADC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
    pc++;
    uint16 param3 = [ram read: pc];
    NSLog(@"param = %x", param3);
}

/* Implementation of ADC */
- (void) ADC_indirectY
{
    NSLog(@"ADC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
    pc++;
    uint16 param3 = [ram read: pc];
    NSLog(@"param = %x", param3);
}

/* Implementation of AND */
- (void) AND_immediate
{
    NSLog(@"AND");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of AND */
- (void) AND_zeropage
{
    NSLog(@"AND");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of AND */
- (void) AND_zeropageX
{
    NSLog(@"AND");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of AND */
- (void) AND_absolute
{
    NSLog(@"AND");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of AND */
- (void) AND_absoluteX
{
    NSLog(@"AND");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of AND */
- (void) AND_absoluteY
{
    NSLog(@"AND");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of AND */
- (void) AND_indirectX
{
    NSLog(@"AND");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of AND */
- (void) AND_indirectY
{
    NSLog(@"AND");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ASL */
- (void) ASL_accumulator
{
    NSLog(@"ASL");
}

/* Implementation of ASL */
- (void) ASL_zeropage
{
    NSLog(@"ASL");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ASL */
- (void) ASL_zeropageX
{
    NSLog(@"ASL");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ASL */
- (void) ASL_absolute
{
    NSLog(@"ASL");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ASL */
- (void) ASL_absoluteX
{
    NSLog(@"ASL");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of BCC */
- (void) BCC_relative
{
    NSLog(@"BCC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of BCS */
- (void) BCS_relative
{
    NSLog(@"BCS");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of BEQ */
- (void) BEQ_relative
{
    NSLog(@"BEQ");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of BIT */
- (void) BIT_zeropage
{
    NSLog(@"BIT");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of BIT */
- (void) BIT_absolute
{
    NSLog(@"BIT");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of BMI */
- (void) BMI_relative
{
    NSLog(@"BMI");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of BNE */
- (void) BNE_relative
{
    NSLog(@"BNE");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of BPL */
- (void) BPL_relative
{
    NSLog(@"BPL");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of BRK */
- (void) BRK_implied
{
    NSLog(@"BRK");
}

/* Implementation of BVC */
- (void) BVC_relative
{
    NSLog(@"BVC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of BVS */
- (void) BVS_relative
{
    NSLog(@"BVS");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CLC */
- (void) CLC_implied
{
    NSLog(@"CLC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CLD */
- (void) CLD_implied
{
    NSLog(@"CLD");
}

/* Implementation of CLI */
- (void) CLI_implied
{
    NSLog(@"CLI");
}

/* Implementation of CLV */
- (void) CLV_implied
{
    NSLog(@"CLV");
}

/* Implementation of CMP */
- (void) CMP_immediate
{
    NSLog(@"CMP");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CMP */
- (void) CMP_zeropage
{
    NSLog(@"CMP");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CMP */
- (void) CMP_zeropageX
{
    NSLog(@"CMP");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CMP */
- (void) CMP_absolute
{
    NSLog(@"CMP");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of CMP */
- (void) CMP_absoluteX
{
    NSLog(@"CMP");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of CMP */
- (void) CMP_absoluteY
{
    NSLog(@"CMP");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of CMP */
- (void) CMP_indirectX
{
    NSLog(@"CMP");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CMP */
- (void) CMP_indirectY
{
    NSLog(@"CMP");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CPX */
- (void) CPX_immediate
{
    NSLog(@"CPX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CPX */
- (void) CPX_zeropage
{
    NSLog(@"CPX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CPX */
- (void) CPX_absolute
{
    NSLog(@"CPX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of CPY */
- (void) CPY_immediate
{
    NSLog(@"CPY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CPY */
- (void) CPY_zeropage
{
    NSLog(@"CPY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of CPY */
- (void) CPY_absolute
{
    NSLog(@"CPY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of DEC */
- (void) DEC_zeropage
{
    NSLog(@"DEC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of DEC */
- (void) DEC_zeropageX
{
    NSLog(@"DEC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of DEC */
- (void) DEC_absolute
{
    NSLog(@"DEC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of DEC */
- (void) DEC_absoluteX
{
    NSLog(@"DEC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of DEX */
- (void) DEX_implied
{
    NSLog(@"DEX");
}

/* Implementation of DEY */
- (void) DEY_implied
{
    NSLog(@"DEY");
}

/* Implementation of EOR */
- (void) EOR_immediate
{
    NSLog(@"EOR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of EOR */
- (void) EOR_zeropage
{
    NSLog(@"EOR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of EOR */
- (void) EOR_zeropageX
{
    NSLog(@"EOR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of EOR */
- (void) EOR_absolute
{
    NSLog(@"EOR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of EOR */
- (void) EOR_absoluteX
{
    NSLog(@"EOR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of EOR */
- (void) EOR_absoluteY
{
    NSLog(@"EOR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of EOR */
- (void) EOR_indirectX
{
    NSLog(@"EOR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of EOR */
- (void) EOR_indirectY
{
    NSLog(@"EOR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of INC */
- (void) INC_zeropage
{
    NSLog(@"INC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of INC */
- (void) INC_zeropageX
{
    NSLog(@"INC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of INC */
- (void) INC_absolute
{
    NSLog(@"INC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of INC */
- (void) INC_absoluteX
{
    NSLog(@"INC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of INX */
- (void) INX_implied
{
    NSLog(@"INX");
}

/* Implementation of INY */
- (void) INY_implied
{
    NSLog(@"INY");
}

/* Implementation of JMP */
- (void) INX_absolute
{
    NSLog(@"JMP");
}

/* Implementation of JMP */
- (void) JMP_indirect
{
    NSLog(@"JMP");
}

/* Implementation of JSR */
- (void) JSR_absolute
{
    NSLog(@"JSR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of LDA */
- (void) LDA_immediate
{
    NSLog(@"LDA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDA */
- (void) LDA_zeropage
{
    NSLog(@"LDA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDA */
- (void) LDA_zeropageX
{
    NSLog(@"LDA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDA */
- (void) LDA_absolute
{
    NSLog(@"LDA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of LDA */
- (void) LDA_absoluteX
{
    NSLog(@"LDA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of LDA */
- (void) LDA_absoluteY
{
    NSLog(@"LDA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of LDA */
- (void) LDA_indirectX
{
    NSLog(@"LDA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDA */
- (void) LDA_indirectY
{
    NSLog(@"LDA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDX */
- (void) LDX_immediate
{
    NSLog(@"LDX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDX */
- (void) LDX_zeropage
{
    NSLog(@"LDX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDX */
- (void) LDX_zeropageY
{
    NSLog(@"LDX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDX */
- (void) LDX_absolute
{
    NSLog(@"LDX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of LDX */
- (void) LDX_absoluteY
{
    NSLog(@"LDX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of LDY */
- (void) LDY_immediate
{
    NSLog(@"LDY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDY */
- (void) LDY_zeropage
{
    NSLog(@"LDY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDY */
- (void) LDY_zeropageX
{
    NSLog(@"LDY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LDY */
- (void) LDY_absolute
{
    NSLog(@"LDY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of LDY */
- (void) LDY_absoluteX
{
    NSLog(@"LDY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of LSR */
- (void) LSR_accumulator
{
    NSLog(@"LSR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LSR */
- (void) LSR_zeropage
{
    NSLog(@"LSR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LSR */
- (void) LSR_zeropageX
{
    NSLog(@"LSR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of LSR */
- (void) LSR_absolute
{
    NSLog(@"LSR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of LSR */
- (void) LSR_absoluteX
{
    NSLog(@"LSR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of NOP */
- (void) NOP_implied
{
    NSLog(@"NOP");
}

/* Implementation of ORA */
- (void) ORA_immediate
{
    NSLog(@"ORA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ORA */
- (void) ORA_zeropage
{
    NSLog(@"ORA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ORA */
- (void) ORA_zeropageX
{
    NSLog(@"ORA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ORA */
- (void) ORA_absolute
{
    NSLog(@"ORA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ORA */
- (void) ORA_absoluteX
{
    NSLog(@"ORA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ORA */
- (void) ORA_absoluteY
{
    NSLog(@"ORA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ORA */
- (void) ORA_indirectX
{
    NSLog(@"ORA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ORA */
- (void) ORA_indirectY
{
    NSLog(@"ORA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of PHA */
- (void) PHA_implied
{
    NSLog(@"PHA");
}

/* Implementation of PHP */
- (void) PHP_implied
{
    NSLog(@"PHP");
}

/* Implementation of PLA */
- (void) PLA_implied
{
    NSLog(@"PLA");
}

/* Implementation of PLP */
- (void) PLP_implied
{
    NSLog(@"PLP");
}

/* Implementation of ROL */
- (void) ROL_accumulator
{
    NSLog(@"ROL");
}

/* Implementation of ROL */
- (void) ROL_zeropage
{
    NSLog(@"ROL");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ROL */
- (void) ROL_zeropageX
{
    NSLog(@"ROL");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ROL */
- (void) ROL_absolute
{
    NSLog(@"ROL");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ROL */
- (void) ROL_absoluteX
{
    NSLog(@"ROL");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ROR */
- (void) ROR_accumulator
{
    NSLog(@"ROR");
}

/* Implementation of ROR */
- (void) ROR_zeropage
{
    NSLog(@"ROR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ROR */
- (void) ROR_zeropageX
{
    NSLog(@"ROR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of ROR */
- (void) ROR_absolute
{
    NSLog(@"ROR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of ROR */
- (void) ROR_absoluteX
{
    NSLog(@"ROR");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of RTI */
- (void) RTI_implied
{
    NSLog(@"RTI");
}

/* Implementation of RTS */
- (void) RTS_implied
{
    NSLog(@"RTS");
}

/* Implementation of SBC */
- (void) SBC_immediate
{
    NSLog(@"SBC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of SBC */
- (void) SBC_zeropage
{
    NSLog(@"SBC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of SBC */
- (void) SBC_zeropageX
{
    NSLog(@"SBC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of SBC */
- (void) SBC_absolute
{
    NSLog(@"SBC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of SBC */
- (void) SBC_absoluteX
{
    NSLog(@"SBC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of SBC */
- (void) SBC_absoluteY
{
    NSLog(@"SBC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of SBC */
- (void) SBC_indirectX
{
    NSLog(@"SBC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of SBC */
- (void) SBC_indirectY
{
    NSLog(@"SBC");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of SEC */
- (void) SEC_implied
{
    NSLog(@"SEC");
}

/* Implementation of SED */
- (void) SED_implied
{
    NSLog(@"SED");
}

/* Implementation of SEI */
- (void) SEI_implied
{
    NSLog(@"SEI");
}

/* Implementation of STA */
- (void) STA_zeropage
{
    NSLog(@"STA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of STA */
- (void) STA_zeropageX
{
    NSLog(@"STA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of STA */
- (void) STA_absolute
{
    NSLog(@"STA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of STA */
- (void) STA_absoluteX
{
    NSLog(@"STA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of STA */
- (void) STA_absoluteY
{
    NSLog(@"STA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of STA */
- (void) STA_indirectX
{
    NSLog(@"STA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of STA */
- (void) STA_inderectY
{
    NSLog(@"STA");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of STX */
- (void) STX_zeropage
{
    NSLog(@"STX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of STX */
- (void) STX_zeropageY
{
    NSLog(@"STX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of STX */
- (void) STX_absolute
{
    NSLog(@"STX");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of STY */
- (void) STY_zeropage
{
    NSLog(@"STY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of STY */
- (void) STY_zeropageX
{
    NSLog(@"STY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
}

/* Implementation of STY */
- (void) STY_absolute
{
    NSLog(@"STY");
    pc++;
    uint16 param1 = [ram read: pc];
    NSLog(@"param = %x", param1);
    pc++;
    uint16 param2 = [ram read: pc];
    NSLog(@"param = %x", param2);
}

/* Implementation of TAX */
- (void) TAX_implied
{
    NSLog(@"TAX");
}

/* Implementation of TAY */
- (void) TAY_implied
{
    NSLog(@"TAY");
}

/* Implementation of TSX */
- (void) TSX_implied
{
    NSLog(@"TSX");
}

/* Implementation of TXA */
- (void) TXA_implied
{
    NSLog(@"TXA");
}

/* Implementation of TXS */
- (void) TXS_implied
{
    NSLog(@"TXS");
}

/* Implementation of TYA */
- (void) TYA_implied
{
    NSLog(@"TYA");
}
@end
