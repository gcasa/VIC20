//
//  VIA6522.h
//  VIC20
//  VIA-6522 Versatile Interface Adapter
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Foundation/Foundation.h>

// Type definitions for GNUstep compatibility 
#ifndef VIC20_UINT_TYPES_DEFINED
#define VIC20_UINT_TYPES_DEFINED
typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;
#endif

@class CPU6502;

// VIA-6522 Register Offsets
#define VIA_REG_ORB_IRB         0x00  // Output/Input Register B
#define VIA_REG_ORA_IRA         0x01  // Output/Input Register A
#define VIA_REG_DDRB            0x02  // Data Direction Register B
#define VIA_REG_DDRA            0x03  // Data Direction Register A
#define VIA_REG_T1C_L           0x04  // Timer 1 Counter Low
#define VIA_REG_T1C_H           0x05  // Timer 1 Counter High
#define VIA_REG_T1L_L           0x06  // Timer 1 Latch Low
#define VIA_REG_T1L_H           0x07  // Timer 1 Latch High
#define VIA_REG_T2C_L           0x08  // Timer 2 Counter Low
#define VIA_REG_T2C_H           0x09  // Timer 2 Counter High
#define VIA_REG_SR              0x0A  // Shift Register
#define VIA_REG_ACR             0x0B  // Auxiliary Control Register
#define VIA_REG_PCR             0x0C  // Peripheral Control Register
#define VIA_REG_IFR             0x0D  // Interrupt Flag Register
#define VIA_REG_IER             0x0E  // Interrupt Enable Register
#define VIA_REG_ORA_IRA_NH      0x0F  // ORA/IRA without handshake

// Interrupt flags
#define VIA_IRQ_CA2             0x01
#define VIA_IRQ_CA1             0x02
#define VIA_IRQ_SR              0x04
#define VIA_IRQ_CB2             0x08
#define VIA_IRQ_CB1             0x10
#define VIA_IRQ_T2              0x20
#define VIA_IRQ_T1              0x40
#define VIA_IRQ_IRQ             0x80

// Timer modes
typedef enum {
    VIA_TIMER_ONE_SHOT = 0,
    VIA_TIMER_FREE_RUN = 1,
    VIA_TIMER_ONE_SHOT_PB7 = 2,
    VIA_TIMER_SQUARE_WAVE = 3
} VIATimerMode;

@interface VIA6522 : NSObject
{
    // VIA Registers
    uint8 registers[16];
    
    // I/O Ports
    uint8 portA, portB;
    uint8 portAInput, portBInput;
    uint8 ddra, ddrb;  // Data Direction Registers
    
    // Timers
    uint16 timer1Counter, timer1Latch;
    uint16 timer2Counter, timer2Latch;
    BOOL timer1Running, timer2Running;
    VIATimerMode timer1Mode, timer2Mode;
    
    // Interrupts
    uint8 interruptFlag;
    uint8 interruptEnable;
    BOOL irqOutput;
    
    // Control
    uint8 auxiliaryControl;
    uint8 peripheralControl;
    uint8 shiftRegister;
    
    // Timing
    NSUInteger cycles;
    
    // CPU reference for interrupts
    CPU6502 *cpu; // weak
    
    // Device identification
    NSString *deviceName;
}

// Initialization
- (instancetype)initWithCPU:(CPU6502 *)processor name:(NSString *)name;

// Register access
- (void)writeRegister:(uint8)address value:(uint8)value;
- (uint8)readRegister:(uint8)address;

// Timer operations
- (void)tick;
- (void)startTimer1:(uint16)value mode:(VIATimerMode)mode;
- (void)startTimer2:(uint16)value;
- (void)stopTimer1;
- (void)stopTimer2;

// I/O Port operations
- (void)setPortAInput:(uint8)value;
- (void)setPortBInput:(uint8)value;
- (uint8)getPortAOutput;
- (uint8)getPortBOutput;

// Interrupt handling
- (void)setInterruptFlag:(uint8)flag;
- (void)clearInterruptFlag:(uint8)flag;
- (void)updateIRQOutput;
- (BOOL)isIRQActive;

// Control line operations
- (void)setCA1:(BOOL)state;
- (void)setCA2:(BOOL)state;
- (void)setCB1:(BOOL)state;
- (void)setCB2:(BOOL)state;

// Debug
- (NSString *)getRegisterStatus;
- (void)dumpRegisters;

@end
