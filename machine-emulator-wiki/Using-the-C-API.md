## Requirements

Before trying this example first make sure:
- You have Cartesi Machine installed globally in your system.
- You have `linux.bin` and `rootfs.ext2` images available locally (you could copy them from your installation).
- You have a C compiler.
- You are using Cartesi Machine 0.19+ (contains the new C API, it's not released yet).

## Hello example

The following example boots a machine and prints a hello message:

```c
#include <cartesi-machine/machine-c-api.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
  // Set machine configuration
  const char *config = "{\
    \"dtb\": {\
      \"entrypoint\": \"echo Hello from inside!\"\
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
  printf("Cycles: %lu\n", mcycle);

  // Cleanup and exit
  cm_delete(machine);
  return 0;
}
```

Compile and run with:
```sh
gcc example.c -o example -lcartesi
./example
```

You should get the following output:
```
Hello from inside!
Halted
Cycles: 48985837
```

## IO example

To perform input/output operations from inside a machine to the outside you can use the CMIO (Cartesi Machine IO) with its GIO (generic IO) interface, the following example demonstrates this:

```c
#include <cartesi-machine/machine-c-api.h>
#include <stdio.h>
#include <stdlib.h>

int main() {
  // Set machine configuration
  const char *config = "{\
    \"dtb\": {\
      \"entrypoint\": \"echo '{\\\"domain\\\":16,\\\"id\\\":\\\"'$(echo -n Hello from inside! | hex --encode)'\\\"}' | rollup gio | grep -Eo '0x[0-9a-f]+' | tr -d '\\n' | hex --decode; echo\"\
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
  if (cm_run(machine, CM_MCYCLE_MAX, NULL) != CM_ERROR_OK) {
    printf("failed to run machine: %s\n", cm_get_last_error_message());
    cm_delete(machine);
    return 1;
  }

  // Receive GIO request
  uint8_t cmd;
  uint16_t domain;
  uint8_t request_data[1024];
  uint64_t length = sizeof(request_data);
  if (cm_receive_cmio_request(machine, &cmd, &domain, request_data, &length)) {
    printf("failed to receive CMIO request: %s\n", cm_get_last_error_message());
    cm_delete(machine);
    return 1;
  }
  if (cmd != CM_CMIO_YIELD_COMMAND_MANUAL || domain != 16) {
    printf("unsupported CMIO request, expected GIO with domain=16\n");
    cm_delete(machine);
    return 1;
  }
  printf("%.*s\n", (int)length, (char*)request_data);

  // Send GIO response
  const char response_data[] = "Hello from outside!";
  if (cm_send_cmio_response(machine, domain, (uint8_t*)response_data, sizeof(response_data)-1) != CM_ERROR_OK) {
    printf("failed to send CMIO response: %s\n", cm_get_last_error_message());
    cm_delete(machine);
    return 1;
  }

  // Resume the machine
  cm_break_reason break_reason;
  if (cm_run(machine, CM_MCYCLE_MAX, &break_reason) != CM_ERROR_OK) {
    printf("failed to resume machine: %s\n", cm_get_last_error_message());
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
  printf("Cycles: %lu\n", mcycle);

  // Cleanup and exit
  cm_delete(machine);
  return 0;
}
```


Compile and run with:
```sh
gcc example-gio.c -o example-gio -lcartesi
./example-gio
```

You should get the following output:
```
Hello from inside!
Hello from outside!
Halted
Cycles: 61800308
```

## More information

For more information on how to use API please read the C API header, every function there is documented.
