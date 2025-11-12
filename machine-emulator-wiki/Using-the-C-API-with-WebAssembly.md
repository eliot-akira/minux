## How to compile for WASM

The Cartesi machine emulator library can be compiled for WASM and used in the frontend of web applications. Here we will guide step-by-step on how to do this.

### 1. Prerequisites

First make sure you have:

- Git, wget, and other build utilities.
- [Emscripten](https://emscripten.org/docs/getting_started/downloads.html) toolchain installed and ready for use

You can install them on Ubuntu with:

```sh
apt-get install --no-install-recommends ca-certificates git wget build-essential emscripten lua5.4
```

If you are not downloading `add-generated-files.diff` files for your Emulator release, you will need Docker to build them.

### 2. Clone:
```sh
# clone a stable branch of the emulator
git clone --branch v0.19.0 https://github.com/cartesi/machine-emulator.git
cd machine-emulator

# patch the sources with required generated files (you can skip this step if you have Docker)
wget https://github.com/cartesi/machine-emulator/releases/download/v0.19.0/add-generated-files.diff
git apply add-generated-files.diff

# bundle dependencies
make bundle-boost
```

### 3. Compile `libcartesi.a`
```sh
make CC=emcc CXX=em++ AR="emar rcs" slirp=no libcartesi.a
```

### 4. Generate a WASM package
```sh
make EMU_TO_LIB_A=src/libcartesi.a DESTDIR=wasm-pkg install-headers install-static-libs
```

Now you should have a directory with all required files in `wasm-pkg` for building C applications targeting WASM with the Emscripten toolchain:

```sh
$ tree wasm-pkg
wasm-pkg/
└── usr
    ├── include
    │   └── cartesi-machine
    │       ├── jsonrpc-machine-c-api.h
    │       ├── machine-c-api.h
    │       ├── machine-c-version.h
    └── lib
        └── libcartesi.a
```

You should use `libcartesi.a` to link to your WASM application, and the `cartesi-machine/machine-c-api.h` header for using the cartesi machine C API.

## Testing

Create a `test.c` file with the following contents:

```c
#include <cartesi-machine/machine-c-api.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
  // Set machine configuration
  const char *config = "{\
    \"dtb\": {\
      \"entrypoint\": \"uname -a; echo Hello from inside!\"\
    },\
    \"flash_drive\": [\
      {\"image_filename\": \"rootfs.ext2\"}\
    ],\
    \"ram\": {\
      \"length\": 134217728,\
      \"image_filename\": \"linux.bin\"\
    }\
  }";

  // Create a new machine
  cm_machine *machine = NULL;
  if (cm_create_new(config, NULL, &machine) != CM_ERROR_OK) {
    printf("failed to create machine: %s\n", cm_get_last_error_message());
    return 1;
  }

  // Run the machine
  cm_break_reason break_reason;
  if (cm_run(machine, CM_MCYCLE_MAX, &break_reason) != CM_ERROR_OK) {
    printf("failed to run machine: %s\n", cm_get_last_error_message());
    cm_delete(machine);
    return 1;
  }

  // Print reason for run interruption
  switch (break_reason) {
    case CM_BREAK_REASON_HALTED:
      printf("Halted\n");
      break;
    case CM_BREAK_REASON_YIELDED_MANUALLY:
      printf("Yielded manually\n");
      break;
    case CM_BREAK_REASON_YIELDED_AUTOMATICALLY:
      printf("Yielded automatically\n");
      break;
    case CM_BREAK_REASON_YIELDED_SOFTLY:
      printf("Yielded softly\n");
      break;
    case CM_BREAK_REASON_REACHED_TARGET_MCYCLE:
      printf("Reached target machine cycle\n");
      break;
    case CM_BREAK_REASON_FAILED:
    default:
      printf("Interpreter failed\n");
      break;
  }

  // Read and print machine cycles
  uint64_t mcycle;
  if (cm_read_reg(machine, CM_REG_MCYCLE, &mcycle) != CM_ERROR_OK) {
    printf("failed to read machine cycle: %s\n", cm_get_last_error_message());
    cm_delete(machine);
    return 1;
  }
  printf("Cycles: %lu\n", (unsigned long)mcycle);

  // Cleanup and exit
  cm_delete(machine);
  return 0;
}
```

Before compiling, make sure you have `linux.bin` and `rootfs.ext2` files available, these files will be used to boot the machine.
You can download them with:

```sh
wget -O rootfs.ext2 https://github.com/cartesi/machine-guest-tools/releases/download/v0.17.1/rootfs-tools.ext2
wget -O linux.bin https://github.com/cartesi/machine-linux-image/releases/download/v0.20.0/linux-6.5.13-ctsi-1-v0.20.0.bin
```

Now you can compile with:

```sh
emcc test.c -o test.html \
    -O3 \
    -I./wasm-pkg/usr/include -L./wasm-pkg/usr/lib -lcartesi \
    --embed-file linux.bin@linux.bin \
    --embed-file rootfs.ext2@rootfs.ext2 \
    -sTOTAL_STACK=4MB \
    -sTOTAL_MEMORY=1024MB \
    -sNO_DISABLE_EXCEPTION_CATCHING
```

The files `test.html`, `test.js` and `test.wasm` will be compiled, and be ready for testing in a web application:

```
ls -la test.*
-rwxr-xr-x 1 bart bart 155M Jan 23 15:10 test.wasm
-rw-r--r-- 1 bart bart  85K Jan 23 15:10 test.js
-rw-r--r-- 1 bart bart  20K Jan 23 15:10 test.html
-rw-r--r-- 1 bart bart 1.9K Jan 23 15:10 test.c
```

You can quickly test in your browser with `emrun` tool, which is a very simple HTTP server:

```sh
emrun test.html
```

If everything works, a page will open in your web browser, and after a few seconds the machine will boot with a message like:
```
Linux localhost.localdomain 6.5.13-ctsi-1 #1 Mon, 15 Apr 2024 15:09:27 +0000 riscv64 riscv64 riscv64 GNU/Linux
Hello from inside!
Halted
Cycles: 57170090
```

Here is a screenshot:

![image](https://github.com/user-attachments/assets/e865d6a3-b898-4664-ae22-969b02bb467d)

### Compile options

When compiling with `emcc` a few options were used, here is the reason for each one:

- `-O3` optimizes the build. It's recommended to always generate optimized builds for WASM, otherwise the WASM file will be too big and slow, some browsers may even fail to load.
- `-I./wasm-pkg/usr/include -L./wasm-pkg/usr/lib -lcartesi` exposes the libcartesi headers and library for linking.
- `--embed-file` options will bundle kernel and rootfs files used by the machine.
- `-sTOTAL_STACK=4MB` is mandatory, otherwise the "stack size" will be too small for running the emulator.
- `-sTOTAL_MEMORY=1024MB` is mandatory, otherwise WASM memory will be too small for running the machine, this can be adjusted though depending on the size of kernel, rootfs and machine memory.
- `-sNO_DISABLE_EXCEPTION_CATCHING` helps on giving tracebacks for any error in case of any.

### Machine interoperability with HTML5

All this is only useful if you can interact with environment inside the machine in the HTML5 page, but how can you do with?

You can pass messages between the C code and anything running inside the emulator with the **CMIO** device. By yielding from inside the machine `cm_run` will break, and you can read/write to CMIO buffers to exchange messages, check the official [IO example](https://github.com/cartesi/machine-emulator/wiki/Using-the-C-API#io-example) on how to do this.

Once your messages are in the C code, you can propagate to javascript and HTML5 web page, please check [Emscripten documentation](https://emscripten.org/docs/api_reference/emscripten.h.html) on how to call between C and JavaScript code.
