# VIC-20 Emulator

A VIC-20 computer emulator written in Objective-C for macOS.

## About the VIC-20

The VIC-20 (Video Interface Chip) was an 8-bit home computer produced by Commodore International Inc. and released in 1981. It was the first computer of any description to sell one million units. The VIC-20 was powered by a MOS Technology 6502 microprocessor and featured the VIC video chip (6560/6561), which gave the computer its name.

## Features

This emulator implements:

- **MOS 6502 CPU Emulation**: Full instruction set implementation with proper status flags (carry, zero, interrupt, decimal, break, overflow, negative)
- **VIC Chip Emulation**: VIC-6560/6561 video interface chip emulation
- **Memory Management**: Separate RAM and ROM components with proper memory mapping
- **Zero Page and Stack**: Proper implementation of 6502 zero page (0x0000-0x00FF) and stack (0x0100-0x01FF) addressing
- **Interrupt Vectors**: Support for reset vector (0xFFFC-0xFFFD) and IRQ vector (0xFFFE-0xFFFF)

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

## Project Structure

```
VIC20/
├── VIC20/                    # Main application source
│   ├── AppDelegate.h/m       # Application delegate and main controller
│   ├── main.m               # Application entry point
│   ├── Info.plist           # Application configuration
│   ├── Processor/           # CPU and VIC chip emulation
│   │   ├── CPU6502.h/m      # 6502 microprocessor emulation
│   │   ├── CPU6502+Instructions.h/m # 6502 instruction set
│   │   └── VIC6560.h/m      # VIC video chip emulation
│   ├── RAM/                 # Memory management components
│   │   ├── Memory.h/m       # Base memory management
│   │   ├── RAM.h/m          # RAM implementation
│   │   └── ROM.h/m          # ROM implementation
│   └── Assets.xcassets/     # Application resources and icons
├── VIC20.xcodeproj/         # Xcode project configuration
├── LICENSE                  # GPL v3 License
└── README.md               # This file
```

## Architecture

The emulator follows a modular design:

- **CPU6502**: Implements the complete MOS 6502 instruction set with proper timing and status flag handling
- **VIC6560/6561**: Emulates the video interface chip responsible for display output
- **Memory System**: Manages different types of memory (RAM, ROM) with proper address space mapping
- **AppDelegate**: Coordinates the emulator components and provides the macOS application interface

## Development

### Key Components

- **CPU Emulation**: The `CPU6502` class handles processor state, instruction execution, and memory access
- **Memory Management**: Flexible memory system supporting different memory types and address ranges
- **Video Emulation**: VIC chip implementation for authentic video output

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
