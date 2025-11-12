## Requirements

Before trying this example first make sure:
- You have Cartesi Machine installed globally in your system.
- You have `linux.bin` and `rootfs.ext2` images available locally (you could copy them from your installation).
- You have Python 3.8+ installed.
- You are using Cartesi Machine 0.19+ (contains the new C API, it's not released yet).

## Binding with FFI

We will be binding using [C FFI](https://cffi.readthedocs.io/en/stable/) for Python.
You can install it with:

```sh
pip install cffi
```

## Hello example

First make sure you have `cffi` package installed.
The following example boots a machine and prints a hello message:

```python
from cffi import FFI
import sys

# Create an FFI instance
ffi = FFI()

# Define the C enums and function prototypes
ffi.cdef("""
typedef struct cm_machine cm_machine;
typedef enum {
    CM_ERROR_OK = 0,
} cm_error;
typedef enum {
    CM_BREAK_REASON_FAILED,
    CM_BREAK_REASON_HALTED,
    CM_BREAK_REASON_YIELDED_MANUALLY,
    CM_BREAK_REASON_YIELDED_AUTOMATICALLY,
    CM_BREAK_REASON_YIELDED_SOFTLY,
    CM_BREAK_REASON_REACHED_TARGET_MCYCLE,
} cm_break_reason;
typedef enum {
    CM_REG_MCYCLE = 69,
} cm_reg;
const char* cm_get_last_error_message();
cm_error cm_create_new(const char *config, const char *options, cm_machine **machine);
void cm_delete(cm_machine *machine);
cm_error cm_read_reg(cm_machine *machine, cm_reg reg, uint64_t *mcycle);
cm_error cm_run(cm_machine *machine, uint64_t max_cycles, cm_break_reason *break_reason);
""")

# Load the Cartesi machine C API
C = ffi.dlopen("libcartesi.so")

# Define constants
CM_MCYCLE_MAX = 0xFFFFFFFFFFFFFFFF # Max uint64 value

# Machine configuration string
config = """{
    "dtb": {
        "entrypoint": "echo Hello from inside!"
    },
    "flash_drive": [
        {"image_filename": "rootfs.ext2"}
    ],
    "ram": {
        "length": 134217728,
        "image_filename": "linux.bin"
    }
}"""

# Create a new machine
machine_out = ffi.new("cm_machine **")
if C.cm_create_new(config.encode(), ffi.NULL, machine_out) != C.CM_ERROR_OK:
    raise Exception(f"failed to create machine: {ffi.string(C.cm_get_last_error_message()).decode()}")
machine = ffi.gc(machine_out[0], lambda m: C.cm_delete(m))

# Run the machine
break_reason_out = ffi.new("cm_break_reason *")
if C.cm_run(machine, CM_MCYCLE_MAX, break_reason_out) != C.CM_ERROR_OK:
    raise Exception(f"failed to run machine: {ffi.string(C.cm_get_last_error_message()).decode()}")
break_reason = break_reason_out[0]

# Print reason for run interruption
if break_reason == C.CM_BREAK_REASON_HALTED:
    print("Halted")
elif break_reason == C.CM_BREAK_REASON_YIELDED_MANUALLY:
    print("Yielded manually")
elif break_reason == C.CM_BREAK_REASON_YIELDED_AUTOMATICALLY:
    print("Yielded automatically")
elif break_reason == C.CM_BREAK_REASON_YIELDED_SOFTLY:
    print("Yielded softly")
elif break_reason == C.CM_BREAK_REASON_REACHED_TARGET_MCYCLE:
    print("Reached target machine cycle")
else:
    print("Interpreter failed")

# Read and print machine cycles
mcycle_out = ffi.new("uint64_t *")
if C.cm_read_reg(machine, C.CM_REG_MCYCLE, mcycle_out) != C.CM_ERROR_OK:
    raise Exception(f"failed to read machine cycle: {ffi.string(C.cm_get_last_error_message()).decode()}")
mcycle = mcycle_out[0]
print(f"Cycles: {mcycle}")
```

Compile and run with:
```sh
pyhton example.py
```

You should get the following output:
```
Hello from inside!
Halted
Cycles: 48985837
```

## More information

For more information on how to use API please read the C API header, every function there is documented.
