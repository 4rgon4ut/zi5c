#!/bin/bash

DEFAULT_RAM_SIZE="0x100000"
DEFAULT_STARTUP_S="linker/startup.s"
OUTPUT_ELF="zig-out/program.elf"

# Paths for linker scripts
TEMPLATE_LD_SCRIPT="linker/template.ld"
GENERATED_LD_SCRIPT="zig-out/generated.ld"

# Initialize variables with defaults
RAM_SIZE="$DEFAULT_RAM_SIZE"
STARTUP_S="$DEFAULT_STARTUP_S"

# --- Function to Display Usage ---
usage() {
  echo "Usage: $0 -f <zig_source_file> [-r <ram_size_hex>] [-a <startup_s_file>] [-o <output_elf_file>]"
  echo "  -f <zig_source_file> : Path to the main Zig source file (required)."
  echo "  -r <ram_size_hex>    : RAM size in hexadecimal (e.g., 0x80000). Default: $DEFAULT_RAM_SIZE."
  echo "  -a <startup_s_file>  : Path to the assembly startup file. Default: $DEFAULT_STARTUP_S."
  echo "  -o <output_elf_file> : Path for the output ELF file. Default: $OUTPUT_ELF."
  echo "Example: $0 -f examples/fib_5th.zig -r 0x80000"
  exit 1
}

# --- Argument Parsing using getopts ---
# 'f:' means -f requires an argument
# 'r:' means -r requires an argument
# 'a:' means -a requires an argument
# 'o:' means -o requires an argument
REQUIRED_F_FLAG=0
while getopts "f:r:a:o:h" opt; do
  case $opt in
    f)
      ZIG_SOURCE_TARGET="$OPTARG"
      REQUIRED_F_FLAG=1
      ;;
    r)
      RAM_SIZE="$OPTARG"
      ;;
    a)
      STARTUP_S="$OPTARG"
      ;;
    o)
      OUTPUT_ELF="$OPTARG"
      ;;
    h)
      usage
      ;;
    \?) # Invalid option
      usage
      ;;
  esac
done

# Check if mandatory -f flag was provided
if [ "$REQUIRED_F_FLAG" -eq 0 ]; then
  echo "Error: -f <zig_source_file> is a required argument."
  usage
fi

# --- Linker Script Generation ---
# Check if the template file exists
if [ ! -f "$TEMPLATE_LD_SCRIPT" ]; then
  echo "Error: Template linker script '$TEMPLATE_LD_SCRIPT' not found."
  exit 1
fi

echo "Generating linker script '$GENERATED_LD_SCRIPT' with RAM LENGTH = $RAM_SIZE\n"

# Use sed to replace the placeholder or the specific line
# Assuming placeholder __RAM_LENGTH__ in your template (linker/default.ld.template):
sed "s/__RAM_LENGTH__/$RAM_SIZE/" "$TEMPLATE_LD_SCRIPT" > "$GENERATED_LD_SCRIPT"
# Or if replacing the exact line in a script without a placeholder:
# sed "s/LENGTH = 0x100000/LENGTH = $RAM_SIZE/" "$TEMPLATE_LD_SCRIPT" > "$GENERATED_LD_SCRIPT"

if [ $? -ne 0 ]; then
  echo "Error: Failed to generate linker script."
  exit 1
fi

# --- Zig Build Command ---
echo "Building $ZIG_SOURCE_TARGET elf...\n"

# Construct the zig build command in an array for robustness
ZIG_BUILD_CMD=(zig build-exe "$ZIG_SOURCE_TARGET")

# Add startup.s if it exists and is specified
if [ -n "$STARTUP_S" ]; then # Check if STARTUP_S is not an empty string
  if [ -f "$STARTUP_S" ]; then
    ZIG_BUILD_CMD+=("$STARTUP_S")
  else
    echo "Warning: Startup file '$STARTUP_S' specified but not found. Attempting build without it."
  fi
elif [ -f "$DEFAULT_STARTUP_S" ] && [ "$STARTUP_S" == "$DEFAULT_STARTUP_S" ]; then
    # If default startup file was intended and exists, add it
    ZIG_BUILD_CMD+=("$DEFAULT_STARTUP_S")
fi


ZIG_BUILD_CMD+=( \
  -target riscv32-freestanding-musl \
  -mcpu generic_rv32 \
  --script "$GENERATED_LD_SCRIPT" \
  -femit-bin="$OUTPUT_ELF" \
  -O ReleaseSmall \
)

# Print the command for debugging (optional)
echo "Build cmd: ${ZIG_BUILD_CMD[*]}\n"

# Execute the command
"${ZIG_BUILD_CMD[@]}"

if [ $? -ne 0 ]; then
  echo "Error: Zig build failed for $ZIG_SOURCE_TARGET."
  exit 1
fi

echo "Success! Output: $OUTPUT_ELF"