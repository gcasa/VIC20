//
//  VIA6522.m
//  VIC20
//  VIA-6522 Versatile Interface Adapter
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "VIA6522.h"
#import "CPU6502.h"

@implementation VIA6522

- (instancetype)initWithCPU:(CPU6502 *)processor name:(NSString *)name
{
    self = [super init];
    if (self) {
        cpu = processor;
        deviceName = [name copy];
        [self reset];
    }
    return self;
}

- (void)reset
{
    // Clear all registers
    memset(registers, 0, sizeof(registers));
    
    // Initialize I/O ports
    portA = portB = 0x00;
    portAInput = portBInput = 0xFF;  // Default to all inputs high
    ddra = ddrb = 0x00;  // Default to all inputs
    
    // Initialize timers
    timer1Counter = timer1Latch = 0xFFFF;
    timer2Counter = timer2Latch = 0xFFFF;
    timer1Running = timer2Running = NO;
    timer1Mode = timer2Mode = VIA_TIMER_ONE_SHOT;
    
    // Clear interrupts
    interruptFlag = 0x00;
    interruptEnable = 0x00;
    irqOutput = NO;
    
    // Initialize control registers
    auxiliaryControl = 0x00;
    peripheralControl = 0x00;
    shiftRegister = 0x00;
    
    cycles = 0;
}

#pragma mark - Register Access

- (void)writeRegister:(uint8)address value:(uint8)value
{
    if (address >= 16) return;
    
    switch (address) {
        case VIA_REG_ORB_IRB:
            // Output Register B
            portB = (portB & ~ddrb) | (value & ddrb);
            registers[address] = value;
            [self clearInterruptFlag:VIA_IRQ_CB1 | VIA_IRQ_CB2];
            break;
            
        case VIA_REG_ORA_IRA:
        case VIA_REG_ORA_IRA_NH:
            // Output Register A
            portA = (portA & ~ddra) | (value & ddra);
            registers[VIA_REG_ORA_IRA] = value;
            if (address == VIA_REG_ORA_IRA) {
                [self clearInterruptFlag:VIA_IRQ_CA1 | VIA_IRQ_CA2];
            }
            break;
            
        case VIA_REG_DDRB:
            ddrb = value;
            registers[address] = value;
            // Update port B based on new direction
            portB = (portBInput & ~ddrb) | (registers[VIA_REG_ORB_IRB] & ddrb);
            break;
            
        case VIA_REG_DDRA:
            ddra = value;
            registers[address] = value;
            // Update port A based on new direction
            portA = (portAInput & ~ddra) | (registers[VIA_REG_ORA_IRA] & ddra);
            break;
            
        case VIA_REG_T1L_L:
            timer1Latch = (timer1Latch & 0xFF00) | value;
            registers[address] = value;
            break;
            
        case VIA_REG_T1C_L:
            timer1Latch = (timer1Latch & 0xFF00) | value;
            registers[VIA_REG_T1L_L] = value;
            break;
            
        case VIA_REG_T1L_H:
            timer1Latch = (timer1Latch & 0x00FF) | (value << 8);
            registers[address] = value;
            break;
            
        case VIA_REG_T1C_H:
            timer1Latch = (timer1Latch & 0x00FF) | (value << 8);
            timer1Counter = timer1Latch;
            registers[VIA_REG_T1L_H] = value;
            [self clearInterruptFlag:VIA_IRQ_T1];
            timer1Running = YES;
            // Set timer mode from ACR
            timer1Mode = (auxiliaryControl & 0x40) ? VIA_TIMER_FREE_RUN : VIA_TIMER_ONE_SHOT;
            break;
            
        case VIA_REG_T2C_L:
            timer2Latch = (timer2Latch & 0xFF00) | value;
            registers[address] = value;
            break;
            
        case VIA_REG_T2C_H:
            timer2Latch = (timer2Latch & 0x00FF) | (value << 8);
            timer2Counter = timer2Latch;
            [self clearInterruptFlag:VIA_IRQ_T2];
            timer2Running = YES;
            timer2Mode = VIA_TIMER_ONE_SHOT;
            break;
            
        case VIA_REG_SR:
            shiftRegister = value;
            registers[address] = value;
            [self clearInterruptFlag:VIA_IRQ_SR];
            break;
            
        case VIA_REG_ACR:
            auxiliaryControl = value;
            registers[address] = value;
            // Update timer modes
            if (timer1Running) {
                timer1Mode = (value & 0x40) ? VIA_TIMER_FREE_RUN : VIA_TIMER_ONE_SHOT;
            }
            break;
            
        case VIA_REG_PCR:
            peripheralControl = value;
            registers[address] = value;
            break;
            
        case VIA_REG_IFR:
            // Clear interrupt flags (writing 1 clears the bit)
            [self clearInterruptFlag:value & 0x7F];
            break;
            
        case VIA_REG_IER:
            if (value & 0x80) {
                // Set interrupt enable bits
                interruptEnable |= (value & 0x7F);
            } else {
                // Clear interrupt enable bits
                interruptEnable &= ~(value & 0x7F);
            }
            registers[address] = interruptEnable;
            [self updateIRQOutput];
            break;
            
        default:
            registers[address] = value;
            break;
    }
}

- (uint8)readRegister:(uint8)address
{
    if (address >= 16) return 0;
    
    switch (address) {
        case VIA_REG_ORB_IRB:
            // Input Register B
            [self clearInterruptFlag:VIA_IRQ_CB1 | VIA_IRQ_CB2];
            return (portBInput & ~ddrb) | (portB & ddrb);
            
        case VIA_REG_ORA_IRA:
            // Input Register A
            [self clearInterruptFlag:VIA_IRQ_CA1 | VIA_IRQ_CA2];
            return (portAInput & ~ddra) | (portA & ddra);
            
        case VIA_REG_ORA_IRA_NH:
            // Input Register A without handshake
            return (portAInput & ~ddra) | (portA & ddra);
            
        case VIA_REG_T1C_L:
            [self clearInterruptFlag:VIA_IRQ_T1];
            return timer1Counter & 0xFF;
            
        case VIA_REG_T1C_H:
            return (timer1Counter >> 8) & 0xFF;
            
        case VIA_REG_T2C_L:
            [self clearInterruptFlag:VIA_IRQ_T2];
            return timer2Counter & 0xFF;
            
        case VIA_REG_T2C_H:
            return (timer2Counter >> 8) & 0xFF;
            
        case VIA_REG_IFR:
            return interruptFlag | (irqOutput ? 0x80 : 0x00);
            
        case VIA_REG_IER:
            return interruptEnable | 0x80;  // Bit 7 always reads as 1
            
        default:
            return registers[address];
    }
}

#pragma mark - Timer Operations

- (void)tick
{
    cycles++;
    
    // Timer 1 countdown
    if (timer1Running) {
        if (timer1Counter > 0) {
            timer1Counter--;
        } else {
            // Timer 1 underflow
            [self setInterruptFlag:VIA_IRQ_T1];
            
            if (timer1Mode == VIA_TIMER_FREE_RUN) {
                timer1Counter = timer1Latch;  // Reload and continue
            } else {
                timer1Running = NO;  // One-shot mode
            }
            
            // Handle PB7 output modes
            if (auxiliaryControl & 0x80) {
                // Toggle PB7 on timer underflow
                portB ^= 0x80;
            }
        }
    }
    
    // Timer 2 countdown 
    if (timer2Running) {
        if (timer2Counter > 0) {
            timer2Counter--;
        } else {
            // Timer 2 underflow
            [self setInterruptFlag:VIA_IRQ_T2];
            timer2Running = NO;  // Timer 2 is always one-shot
        }
    }
}

- (void)startTimer1:(uint16)value mode:(VIATimerMode)mode
{
    timer1Latch = timer1Counter = value;
    timer1Mode = mode;
    timer1Running = YES;
    [self clearInterruptFlag:VIA_IRQ_T1];
}

- (void)startTimer2:(uint16)value
{
    timer2Latch = timer2Counter = value;
    timer2Mode = VIA_TIMER_ONE_SHOT;
    timer2Running = YES;
    [self clearInterruptFlag:VIA_IRQ_T2];
}

- (void)stopTimer1
{
    timer1Running = NO;
}

- (void)stopTimer2
{
    timer2Running = NO;
}

#pragma mark - I/O Port Operations

- (void)setPortAInput:(uint8)value
{
    portAInput = value;
    // Update actual port A based on data direction
    portA = (value & ~ddra) | (portA & ddra);
}

- (void)setPortBInput:(uint8)value
{
    portBInput = value;
    // Update actual port B based on data direction
    portB = (value & ~ddrb) | (portB & ddrb);
}

- (uint8)getPortAOutput
{
    return portA & ddra;  // Only output bits
}

- (uint8)getPortBOutput
{
    return portB & ddrb;  // Only output bits
}

#pragma mark - Interrupt Handling

- (void)setInterruptFlag:(uint8)flag
{
    interruptFlag |= (flag & 0x7F);
    [self updateIRQOutput];
}

- (void)clearInterruptFlag:(uint8)flag
{
    interruptFlag &= ~(flag & 0x7F);
    [self updateIRQOutput];
}

- (void)updateIRQOutput
{
    BOOL oldIRQ = irqOutput;
    irqOutput = (interruptFlag & interruptEnable) != 0;
    
    // Trigger CPU interrupt on rising edge
    if (irqOutput && !oldIRQ && cpu) {
        [cpu interrupt];
    }
}

- (BOOL)isIRQActive
{
    return irqOutput;
}

#pragma mark - Control Line Operations

- (void)setCA1:(BOOL)state
{
    // CA1 interrupt on edge (configured by PCR)
    BOOL risingEdge = (peripheralControl & 0x01) != 0;
    static BOOL lastCA1 = NO;
    
    if ((risingEdge && !lastCA1 && state) || (!risingEdge && lastCA1 && !state)) {
        [self setInterruptFlag:VIA_IRQ_CA1];
    }
    lastCA1 = state;
}

- (void)setCA2:(BOOL)state
{
    // CA2 functionality depends on PCR configuration
    uint8 ca2Control = (peripheralControl >> 1) & 0x07;
    
    if (ca2Control & 0x04) {
        // CA2 is output mode - ignore input
        return;
    }
    
    // CA2 is input mode
    BOOL risingEdge = (ca2Control & 0x01) != 0;
    static BOOL lastCA2 = NO;
    
    if ((risingEdge && !lastCA2 && state) || (!risingEdge && lastCA2 && !state)) {
        [self setInterruptFlag:VIA_IRQ_CA2];
    }
    lastCA2 = state;
}

- (void)setCB1:(BOOL)state
{
    // CB1 interrupt on edge (configured by PCR)
    BOOL risingEdge = (peripheralControl & 0x10) != 0;
    static BOOL lastCB1 = NO;
    
    if ((risingEdge && !lastCB1 && state) || (!risingEdge && lastCB1 && !state)) {
        [self setInterruptFlag:VIA_IRQ_CB1];
    }
    lastCB1 = state;
}

- (void)setCB2:(BOOL)state
{
    // CB2 functionality depends on PCR configuration
    uint8 cb2Control = (peripheralControl >> 5) & 0x07;
    
    if (cb2Control & 0x04) {
        // CB2 is output mode - ignore input
        return;
    }
    
    // CB2 is input mode
    BOOL risingEdge = (cb2Control & 0x01) != 0;
    static BOOL lastCB2 = NO;
    
    if ((risingEdge && !lastCB2 && state) || (!risingEdge && lastCB2 && !state)) {
        [self setInterruptFlag:VIA_IRQ_CB2];
    }
    lastCB2 = state;
}

#pragma mark - Debug

- (NSString *)getRegisterStatus
{
    NSMutableString *status = [NSMutableString string];
    
    [status appendFormat:@"%@ VIA-6522 Status:\n", deviceName];
    [status appendFormat:@"Port A: $%02X (DDR: $%02X, Input: $%02X)\n", portA, ddra, portAInput];
    [status appendFormat:@"Port B: $%02X (DDR: $%02X, Input: $%02X)\n", portB, ddrb, portBInput];
    [status appendFormat:@"Timer 1: $%04X (Latch: $%04X, Running: %s)\n", 
     timer1Counter, timer1Latch, timer1Running ? "Yes" : "No"];
    [status appendFormat:@"Timer 2: $%04X (Running: %s)\n", 
     timer2Counter, timer2Running ? "Yes" : "No"];
    [status appendFormat:@"IFR: $%02X, IER: $%02X, IRQ: %s\n", 
     interruptFlag, interruptEnable, irqOutput ? "Active" : "Inactive"];
    [status appendFormat:@"ACR: $%02X, PCR: $%02X, SR: $%02X\n", 
     auxiliaryControl, peripheralControl, shiftRegister];
    
    return status;
}

- (void)dumpRegisters
{
    NSLog(@"%@", [self getRegisterStatus]);
    
    NSLog(@"Register dump:");
    for (int i = 0; i < 16; i++) {
        NSLog(@"  $%X: $%02X", i, registers[i]);
    }
}

@end