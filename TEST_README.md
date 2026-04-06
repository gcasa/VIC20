# VIC-20 Emulator Test Program

This test program demonstrates the complete VIC-20 emulator system with all integrated components.

## What It Tests

1. **System Initialization** - All VIC-20 components (CPU, VIC, VIAs, Keyboard, Memory)
2. **Memory Management** - RAM expansion configuration and memory mapping
3. **I/O Operations** - Memory-mapped access to VIC and VIA chip registers
4. **CPU Instructions** - Basic 6502 instruction execution
5. **ROM Loading** - Loading BASIC, KERNAL, and Character ROMs (if available)
6. **Cartridge Support** - Cartridge insertion and auto-detection

## Compilation

### Using Xcode
1. Add `VIC20Test.m` to your Xcode project
2. Build and run the project

### Using Command Line
```bash
# Compile the test program
clang -framework Foundation -I./VIC20 \
  VIC20Test.m \
  VIC20/Processor/CPU6502.m \
  VIC20/Processor/CPU6502+Instructions.m \
  VIC20/Processor/VIC6560.m \
  VIC20/Processor/VIA6522.m \
  VIC20/Processor/KeyboardMatrix.m \
  VIC20/RAM/Memory.m \
  VIC20/RAM/RAM.m \
  VIC20/RAM/ROM.m \
  VIC20/RAM/VIC20MemoryManager.m \
  -o VIC20Test

# Run the test
./VIC20Test
```

## Expected Output

The test will display:
- Component initialization status
- Memory configuration details  
- Memory access test results (RAM, VIC, VIA registers)
- CPU instruction execution test
- System state before and after tests

## Testing with ROM Files

To test with actual VIC-20 ROM files:

1. Create a `roms` directory in the project root
2. Place these ROM files in the directory:
   - `basic.rom` - VIC-20 BASIC interpreter (8KB)
   - `kernal.rom` - VIC-20 KERNAL operating system (8KB)  
   - `characters.rom` - Character generator ROM (4KB)
3. Run the test program again

### ROM File Sources
- Original VIC-20 ROMs can be found in VICE emulator distribution
- ROM files should be 4KB or 8KB in size
- Character ROM is optional (default character set will be used)

## Testing with Cartridges

To test cartridge loading:

1. Place a VIC-20 program file (`.prg`) as `test.prg` in the project root
2. The test will automatically detect and load it
3. Supported cartridge sizes: 4KB, 8KB, 16KB

## Memory Configuration

The test configures maximum memory expansion:
- Base RAM: 4KB (0x0000-0x0FFF, minus 1KB for screen/color)  
- 3KB Expansion: 0x0400-0x0FFF
- 8KB Expansion 1: 0x2000-0x3FFF
- 8KB Expansion 2: 0x4000-0x5FFF
- **Total: 22KB usable RAM**

## I/O Memory Map

The test verifies memory-mapped I/O access:
- VIC-6561 Registers: 0x9000-0x900F (video/sound)
- VIA-6522 #1 Registers: 0x9110-0x911F (keyboard interface)
- VIA-6522 #2 Registers: 0x9120-0x912F (user port)

## Test Results

Each test shows PASS/FAIL status:
- **RAM Test**: Basic memory read/write
- **VIC Test**: Video chip register access
- **VIA1 Test**: Keyboard interface register access  
- **VIA2 Test**: User port register access
- **CPU Test**: Instruction execution and memory storage

## Troubleshooting

If tests fail:
1. Check that all source files are properly included
2. Verify memory management component initialization
3. Review debug output for detailed error information
4. Ensure proper linking of all VIC-20 components

## Next Steps

After successful testing:
1. Integrate with macOS UI for keyboard input and video output
2. Add ROM loading interface for easy ROM file selection
3. Implement save/load state functionality
4. Add tape and disk drive emulation
5. Create performance optimizations for real-time operation