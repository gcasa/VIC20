# VIC-20 Emulator

A VIC-20 computer emulator written in Objective-C for macOS.   This is BY NO MEANS meant as a replacement for VICE or anything like that.   This is an educational exercise to help me understand how to write an emulator.

## About the VIC-20

The VIC-20 (Video Interface Chip) was an 8-bit home computer produced by Commodore International Inc. and released in 1981. It was the first computer of any description to sell one million units. The VIC-20 was powered by a MOS Technology 6502 microprocessor and featured the VIC video chip (6560/6561), which gave the computer its name.

## Features

This emulator implements a complete VIC-20 system:

### Core Hardware

- **MOS 6502 CPU Emulation**: Full instruction set implementation with proper status flags, addressing modes, and cycle-accurate timing
- **VIC-6561 Video Chip**: Complete video interface chip emulation with 16-color palette, character/bitmap modes, and hardware registers
- **Dual VIA-6522 I/O Chips**: Versatile Interface Adapters for keyboard scanning, joystick input, user port, and cassette interface
- **Keyboard Matrix**: Full VIC-20 keyboard matrix (8×8) with macOS key event integration
- **Memory Management System**: Comprehensive memory mapping with ROM banking, cartridge slots, and expansion memory support

### Memory Configuration  

- **Base RAM**: 4KB (expandable to 22KB with memory expansion modules)
- **ROM Support**: BASIC ROM (8KB), KERNAL ROM (8KB), Character ROM (4KB)
- **Cartridge Support**: Auto-detecting 4KB, 8KB, and 16KB cartridges
- **Memory Expansion**: 3KB RAM expansion + two 8KB expansion modules
- **Memory-Mapped I/O**: Proper $9000-$912F address space for hardware registers

### System Features

- **Integrated Architecture**: All components communicate through proper memory-mapped I/O and interrupt systems
- **Debug Support**: Comprehensive debugging output with component state monitoring and execution tracing
- **ROM Loading**: Automatic loading of VIC-20 system ROMs with fallback defaults
- **State Management**: Full system state inspection and control
- **Timing Synchronization**: Coordinated timing between CPU, VIC, and VIA chips

## System Requirements

- **Operating System**: macOS 10.9 or later
- **Development**: Xcode 9.0 or later (for building from source)
- **Architecture**: Intel or Apple Silicon Macs

## Building and Running

### Building from Source

1. Clone this repository:

   ```bash
   git clone <repository-url>
   cd VIC20
   ```

2. Open the project in Xcode:

   ```bash
   open VIC20.xcodeproj
   ```

3. Build and run the project using Xcode (⌘+R)

### Running the Application

Once built, the VIC-20 emulator will launch as a standard macOS application. The emulator provides a faithful recreation of the original VIC-20 computing environment.

### Testing the System

A comprehensive test program (`VIC20Test.m`) is included that validates all system components:

```bash
# Easy way: Use the build script
./build_and_test.sh

# Or compile manually (command line)
clang -framework Foundation -I./VIC20 VIC20Test.m VIC20/Processor/*.m VIC20/RAM/*.m -o VIC20Test

# Run the test
./VIC20Test
```

The test program validates:

- System component initialization
- Memory management and expansion
- Memory-mapped I/O register access  
- CPU instruction execution
- ROM loading (if ROM files are available)
- Cartridge insertion and detection

See [TEST_README.md](TEST_README.md) for complete testing documentation.

### Current Status

✅ **COMPLETE**: All major VIC-20 hardware components implemented and integrated  
✅ **CPU**: Full 6502 instruction set with proper flag handling  
✅ **VIDEO**: VIC-6561 chip with graphics and color support  
✅ **I/O**: Dual VIA-6522 chips for keyboard and peripherals  
✅ **MEMORY**: Complete memory management with expansion support  
✅ **INTEGRATION**: All components communicate through proper memory-mapped I/O  

🔧 **IN PROGRESS**: macOS UI integration for keyboard input and video display  
📋 **PLANNED**: Save/load states, tape drive emulation, performance optimization

## Project Structure

```
VIC20/
├── VIC20/                    # Main application source
│   ├── AppDelegate.h/m       # Application delegate and main controller
│   ├── main.m               # Application entry point  
│   ├── Info.plist           # Application configuration
│   ├── Processor/           # CPU and chip emulation
│   │   ├── CPU6502.h/m      # 6502 microprocessor emulation (system controller)
│   │   ├── CPU6502+Instructions.h/m # Complete 6502 instruction set
│   │   ├── VIC6560.h/m      # VIC-6561 video interface chip
│   │   ├── VIA6522.h/m      # VIA-6522 versatile interface adapter  
│   │   └── KeyboardMatrix.h/m # VIC-20 keyboard matrix scanner
│   ├── RAM/                 # Memory management system
│   │   ├── Memory.h/m       # Base memory management interface
│   │   ├── RAM.h/m          # RAM implementation
│   │   ├── ROM.h/m          # ROM implementation
│   │   └── VIC20MemoryManager.h/m # Complete VIC-20 memory mapping
│   └── Assets.xcassets/     # Application resources and icons  
├── VIC20.xcodeproj/         # Xcode project configuration
├── VIC20Test.m             # System integration test program
├── build_and_test.sh       # Automated build and test script
├── TEST_README.md          # Test program documentation
├── LICENSE                 # GPL v3 License
└── README.md              # This file
```

## Architecture

The emulator implements a complete VIC-20 system with fully integrated components:

### System Integration

- **CPU6502**: Acts as the main system controller, orchestrating all hardware components  
- **VIC6561**: Video Interface Chip providing graphics rendering, color palette, and sound generation
- **VIA6522 (×2)**: Dual I/O adapters handling keyboard matrix scanning, joystick input, and peripheral interfaces
- **KeyboardMatrix**: Hardware-accurate 8×8 keyboard matrix with macOS integration
- **VIC20MemoryManager**: Complete memory mapping system with ROM/RAM/cartridge management
- **Memory-Mapped I/O**: Authentic hardware register access at $9000-$912F address space

### Memory Architecture

```
$0000-$0FFF   Base RAM (4KB)
$1000-$1FFF   Expansion RAM area
$2000-$3FFF   8KB RAM Expansion 1 / Cartridge area  
$4000-$5FFF   8KB RAM Expansion 2 / Cartridge area
$6000-$6FFF   4KB Cartridge area
$8000-$8FFF   Character ROM area
$9000-$900F   VIC-6561 Registers
$9110-$911F   VIA-6522 #1 Registers (Keyboard)
$9120-$912F   VIA-6522 #2 Registers (User Port)
$A000-$BFFF   BASIC ROM (8KB)  
$C000-$DFFF   Expansion ROM area
$E000-$FFFF   KERNAL ROM (8KB)
```

### Component Communication

- **Interrupt System**: VIA timers generate interrupts processed by CPU
- **Keyboard Interface**: Keyboard matrix connects through VIA1 for authentic key scanning
- **Video System**: VIC chip provides raster timing and video memory access
- **Memory Management**: Unified memory access routing through VIC20MemoryManager
- **Debug Integration**: All components provide state inspection and logging

### Usage Example

```objc  
// Initialize complete VIC-20 system
CPU6502 *vic20 = [[CPU6502 alloc] init];
[vic20 initVIC20System];

// Configure maximum memory (22KB total)
[vic20 configureMemoryExpansion:YES enable8K1:YES enable8K2:YES];

// Load system ROMs
[vic20 loadROMs:@"/path/to/roms"];

// Reset and run
[vic20 reset];
[vic20 run];
```

## Development

### System Architecture

- **CPU6502**: Main system controller integrating all VIC-20 components with complete 6502 instruction set
- **VIC6561**: Video Interface Chip handling graphics rendering, color palette, and sound generation  
- **VIA6522**: Dual Versatile Interface Adapters managing keyboard matrix, joystick input, and I/O ports
- **KeyboardMatrix**: Hardware-accurate keyboard matrix scanner with macOS event integration
- **VIC20MemoryManager**: Comprehensive memory mapping supporting ROM, RAM, cartridges, and expansions
- **Memory System**: Unified memory access with proper address space routing and expansion support

### Key Integration Points

- **Memory-Mapped I/O**: All hardware components accessible through $9000-$912F address space
- **Interrupt Handling**: VIA timer interrupts processed by CPU for authentic timing
- **Component Synchronization**: Coordinated tick() methods maintain proper timing relationships
- **Debug Integration**: Comprehensive logging and state inspection across all components

### ROM Requirements  

For fully functional emulation, place these ROM files in a `roms/` directory:

- `basic.rom` - VIC-20 BASIC interpreter (8KB)  
- `kernal.rom` - VIC-20 KERNAL operating system (8KB)
- `characters.rom` - Character generator ROM (4KB, optional)

ROM files can be obtained from the VICE emulator distribution or other legal sources.

### Cartridge Support

The emulator supports VIC-20 cartridges:

- **4KB cartridges** - Mapped to $6000-$6FFF
- **8KB cartridges** - Mapped to $2000-$3FFF or $4000-$5FFF  
- **16KB cartridges** - Mapped across multiple areas
- Auto-detection based on file size

### Contributing

Contributions are welcome! Please feel free to submit pull requests or report issues.

## Version History

- **v1.0** (2018): Initial release with basic VIC-20 emulation

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Credits

- **Developer**: Gregory Casamento
- **Organization**: Open Logic Corporation
- **Year**: 2018

## Acknowledgments

- Commodore International for creating the original VIC-20 computer
- The retro computing community for preserving VIC-20 documentation and resources

---

*Bringing the classic VIC-20 computing experience to modern macOS systems.*
