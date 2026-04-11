#!/bin/bash

# VIC-20 Emulator Build and Test Script
# Compiles and runs the VIC-20 emulator test program

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory and project paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
TEST_EXECUTABLE="$PROJECT_DIR/VIC20Test"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a file exists
check_file() {
    if [ ! -f "$1" ]; then
        print_error "Required file not found: $1"
        return 1
    fi
    return 0
}

# Function to compile the test program
compile_test() {
    print_status "Compiling VIC-20 Emulator Test Program..."
    
    # Check if all required source files exist
    local files_to_check=(
        "VIC20Test.m"
        "VIC20/Processor/CPU6502.m"
        "VIC20/Processor/CPU6502+Instructions.m"
        "VIC20/Processor/VIC6560.m"
        "VIC20/Processor/VIA6522.m"
        "VIC20/Processor/KeyboardMatrix.m"
        "VIC20/RAM/Memory.m"
        "VIC20/RAM/RAM.m"
        "VIC20/RAM/ROM.m"
        "VIC20/Processor/VIC20MemoryManager.m"
    )
    
    echo "Checking required source files..."
    for file in "${files_to_check[@]}"; do
        if ! check_file "$PROJECT_DIR/$file"; then
            exit 1
        fi
    done
    
    print_success "All source files found"
    
    # Remove existing executable if it exists
    if [ -f "$TEST_EXECUTABLE" ]; then
        print_status "Removing existing executable..."
        rm "$TEST_EXECUTABLE"
    fi
    
    # Compile command
    print_status "Running compiler..."
    
    # Detect platform and use appropriate build flags
    if command -v gnustep-config &> /dev/null; then
        # GNUstep on Linux
        print_status "Building for GNUstep/Linux..."
        gcc -DGNUSTEP=1 \
            $(gnustep-config --objc-flags) \
            -I./VIC20 \
            VIC20Test.m \
            VIC20/Processor/CPU6502.m \
            VIC20/Processor/CPU6502+Instructions.m \
            VIC20/Processor/VIC6560.m \
            VIC20/Processor/VIA6522.m \
            VIC20/Processor/KeyboardMatrix.m \
            VIC20/RAM/Memory.m \
            VIC20/RAM/RAM.m \
            VIC20/RAM/ROM.m \
            VIC20/Processor/VIC20MemoryManager.m \
            $(gnustep-config --objc-libs) \
            -o VIC20Test
    else
        # macOS with Foundation framework
        print_status "Building for macOS..."
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
            VIC20/Processor/VIC20MemoryManager.m \
            -o VIC20Test
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Compilation successful! Executable created: VIC20Test"
        return 0
    else
        print_error "Compilation failed!"
        return 1
    fi
}

# Function to run the test program
run_test() {
    if [ ! -f "$TEST_EXECUTABLE" ]; then
        print_error "Test executable not found. Run compilation first."
        return 1
    fi
    
    print_status "Running VIC-20 Emulator Test Program..."
    echo "=================================="
    
    # Run the test program
    "$TEST_EXECUTABLE"
    
    local exit_code=$?
    echo "=================================="
    
    if [ $exit_code -eq 0 ]; then
        print_success "Test program completed successfully"
    else
        print_warning "Test program exited with code: $exit_code"
    fi
    
    return $exit_code
}

# Function to check for ROM files
check_roms() {
    local rom_dir="$PROJECT_DIR/roms"
    
    if [ -d "$rom_dir" ]; then
        print_status "ROM directory found: $rom_dir"
        
        local rom_files=("basic.rom" "kernal.rom" "characters.rom")
        local found_roms=0
        
        for rom in "${rom_files[@]}"; do
            if [ -f "$rom_dir/$rom" ]; then
                print_success "Found: $rom ($(stat -f%z "$rom_dir/$rom" 2>/dev/null || echo "unknown size") bytes)"
                ((found_roms++))
            else
                print_warning "Missing: $rom"
            fi
        done
        
        if [ $found_roms -eq 0 ]; then
            print_warning "No ROM files found. Test will run with defaults."
        fi
    else
        print_warning "ROM directory not found: $rom_dir"
        print_status "Create '$rom_dir' and place VIC-20 ROM files there for full testing"
    fi
}

# Function to check for test cartridge
check_cartridge() {
    local cart_file="$PROJECT_DIR/test.prg"
    
    if [ -f "$cart_file" ]; then
        print_success "Test cartridge found: test.prg ($(stat -f%z "$cart_file" 2>/dev/null || echo "unknown size") bytes)"
    else
        print_status "No test cartridge found. Place a .prg file as 'test.prg' for cartridge testing."
    fi
}

# Function to clean build artifacts
clean() {
    print_status "Cleaning build artifacts..."
    
    if [ -f "$TEST_EXECUTABLE" ]; then
        rm "$TEST_EXECUTABLE"
        print_success "Removed: VIC20Test"
    fi
    
    # Remove any .dSYM directories
    if [ -d "$PROJECT_DIR/VIC20Test.dSYM" ]; then
        rm -rf "$PROJECT_DIR/VIC20Test.dSYM"
        print_success "Removed: VIC20Test.dSYM"
    fi
    
    print_success "Clean complete"
}

# Function to show help
show_help() {
    echo "VIC-20 Emulator Build and Test Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  compile, build, c    Compile the test program only"
    echo "  test, run, r         Run the test program (compiles if needed)"
    echo "  clean                Remove build artifacts"
    echo "  check                Check for ROM files and cartridges"
    echo "  help, h, --help      Show this help message"
    echo ""
    echo "Default: compile and run the test program"
    echo ""
    echo "Examples:"
    echo "  $0                   # Compile and run"
    echo "  $0 compile           # Compile only"
    echo "  $0 test              # Run test (compile if needed)"
    echo "  $0 clean             # Clean build artifacts"
}

# Main script logic
main() {
    cd "$PROJECT_DIR"
    
    case "${1:-default}" in
        "compile"|"build"|"c")
            check_roms
            check_cartridge
            compile_test
            ;;
        "test"|"run"|"r")
            check_roms
            check_cartridge
            if [ ! -f "$TEST_EXECUTABLE" ]; then
                compile_test || exit 1
            fi
            run_test
            ;;
        "clean")
            clean
            ;;
        "check")
            check_roms
            check_cartridge
            ;;
        "help"|"h"|"--help")
            show_help
            ;;
        "default")
            print_status "VIC-20 Emulator Build and Test Script"
            check_roms
            check_cartridge
            compile_test || exit 1
            echo ""
            run_test
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
