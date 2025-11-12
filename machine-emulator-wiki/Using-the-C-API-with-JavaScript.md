## Requirements

Before trying this example first make sure:
- You have Cartesi Machine installed globally in your system.
- You have `linux.bin` and `rootfs.ext2` images available locally (you could copy them from your installation).
- You have a Node 20.x+ installed.
- You are using Cartesi Machine 0.19+ (contains the new C API, it's not released yet).

## Binding with FFI

We will be binding using [koffi](https://koffi.dev/) C FFI module for Node.
You can install it with:

```sh
npm install koffi
```

## Hello example

First make sure you have `koffi` package installed.
The following example boots a machine and prints a hello message:

```js
// Bindings
const koffi = require('koffi')
const cartesi = koffi.load('libcartesi.so')
const CM_ERROR_OK = 0
const CM_MCYCLE_MAX = 0xffffffffffffffffff
const CM_BREAK_REASON_FAILED = 0
const CM_BREAK_REASON_HALTED = 1
const CM_BREAK_REASON_YIELDED_MANUALLY = 2
const CM_BREAK_REASON_YIELDED_AUTOMATICALLY = 3
const CM_BREAK_REASON_YIELDED_SOFTLY = 4
const CM_BREAK_REASON_REACHED_TARGET_MCYCLE = 5
const CM_REG_MCYCLE = 69
const cm_machine = koffi.opaque('cm_machine')
const cm_break_reason = koffi.alias('cm_break_reason', 'int32_t')
const cm_get_last_error_message = cartesi.func('const char *cm_get_last_error_message()')
const cm_create_new = cartesi.func('int32_t cm_create_new(const char *config, const char *runtime_config, _Out_ cm_machine **new_machine)')
const cm_delete = cartesi.func('void cm_delete(cm_machine *m)')
const cm_run = cartesi.func('int32_t cm_run(cm_machine *m, uint64_t mcycle_end, _Out_ cm_break_reason *break_reason)')
const cm_read_reg = cartesi.func('int32_t cm_read_reg(const cm_machine *m, int32_t reg, _Out_ uint64_t *val)')

// Set machine configuration
const config = {
  dtb: {
    entrypoint: "echo Hello from inside!",
  },
  flash_drive: [
    {image_filename: "rootfs.ext2"},
  ],
  ram: {
    image_filename: "linux.bin",
    length: 0x8000000,
  },
}
const runtime_config = {}

// Create a new machine
let machine_out = [null]
if (cm_create_new(JSON.stringify(config), JSON.stringify(runtime_config), machine_out) != CM_ERROR_OK) {
  throw new Error(`failed to create machine: ${cm_get_last_error_message()}`)
}
let machine = machine_out[0]

// Wrap in a try/finally block to auto free machine memory
try {
  // Run the machine
  let break_reason_out = [null]
  if (cm_run(machine, CM_MCYCLE_MAX, break_reason_out) != CM_ERROR_OK) {
    throw new Error(`failed to run machine: ${cm_get_last_error_message()}`)
  }
  let break_reason = break_reason_out[0]

  // Print reason for run interruption
  switch (break_reason) {
    case CM_BREAK_REASON_HALTED:
      console.log("Halted")
      break
    case CM_BREAK_REASON_YIELDED_MANUALLY:
      console.log("Yielded manually")
      break
    case CM_BREAK_REASON_YIELDED_AUTOMATICALLY:
      console.log("Yielded automatically")
      break
    case CM_BREAK_REASON_YIELDED_SOFTLY:
      console.log("Yielded softly")
      break
    case CM_BREAK_REASON_REACHED_TARGET_MCYCLE:
      console.log("Reached target machine cycle")
      break
    case CM_BREAK_REASON_FAILED:
    default:
      console.log("Interpreter failed")
      break
  }

  // Read and print machine cycles
  let mcycle_out = [null]
  if (cm_read_reg(machine, CM_REG_MCYCLE, mcycle_out) != CM_ERROR_OK) {
    throw new Error(`failed to read machine cycle: ${cm_get_last_error_message()}`)
  }
  let mcycle = mcycle_out[0]
  console.log("Cycles:", mcycle)
} finally {
  cm_delete(machine)
}
```

Compile and run with:
```sh
node example.js
```

You should get the following output:
```
Hello from inside!
Halted
Cycles: 48985837
```

## IO example

To perform input/output operations from inside a machine to the outside you can use the CMIO (Cartesi Machine IO) with its GIO (generic IO) interface, the following example demonstrates this:

```js
// Bindings
const koffi = require('koffi')
const cartesi = koffi.load('libcartesi.so')
const CM_ERROR_OK = 0
const CM_MCYCLE_MAX = 0xffffffffffffffffff
const CM_CMIO_YIELD_COMMAND_MANUAL = 1
const CM_BREAK_REASON_FAILED = 0
const CM_BREAK_REASON_HALTED = 1
const CM_BREAK_REASON_YIELDED_MANUALLY = 2
const CM_BREAK_REASON_YIELDED_AUTOMATICALLY = 3
const CM_BREAK_REASON_YIELDED_SOFTLY = 4
const CM_BREAK_REASON_REACHED_TARGET_MCYCLE = 5
const CM_REG_MCYCLE = 69
const cm_machine = koffi.opaque('cm_machine')
const cm_break_reason = koffi.alias('cm_break_reason', 'int32_t')
const cm_get_last_error_message = cartesi.func('const char *cm_get_last_error_message()')
const cm_create_new = cartesi.func('int32_t cm_create_new(const char *config, const char *runtime_config, _Out_ cm_machine **new_machine)')
const cm_delete = cartesi.func('void cm_delete(cm_machine *m)')
const cm_run = cartesi.func('int32_t cm_run(cm_machine *m, uint64_t mcycle_end, _Out_ cm_break_reason *break_reason)')
const cm_read_reg = cartesi.func('int32_t cm_read_reg(const cm_machine *m, int32_t reg, _Out_ uint64_t *val)')
const cm_receive_cmio_request = cartesi.func('int32_t cm_receive_cmio_request(const cm_machine *m, _Out_ uint8_t *cmd, _Out_ uint16_t *reason, uint8_t *data, _Inout_ uint64_t *length)')
const cm_send_cmio_response = cartesi.func('int32_t cm_send_cmio_response(cm_machine *m, uint16_t reason, const uint8_t *data, uint64_t length)')

// Set machine configuration
const config = {
  dtb: {
    entrypoint: `echo '{"domain":16,"id":"'$(echo -n Hello from inside! | hex --encode)'"}' | rollup gio | grep -Eo '0x[0-9a-f]+' | tr -d '\n' | hex --decode; echo`,
  },
  flash_drive: [
    {image_filename: "rootfs.ext2"},
  ],
  ram: {
    image_filename: "linux.bin",
    length: 0x8000000,
  },
}
const runtime_config = {}

// Create a new machine
let machine_out = [null]
if (cm_create_new(JSON.stringify(config), JSON.stringify(runtime_config), machine_out) != CM_ERROR_OK) {
  throw new Error(`failed to create machine: ${cm_get_last_error_message()}`)
}
let machine = machine_out[0]

// Wrap in a try/finally block to auto free machine memory
try {
  // Run the machine
  if (cm_run(machine, CM_MCYCLE_MAX, null) != CM_ERROR_OK) {
    throw new Error(`failed to run machine: ${cm_get_last_error_message()}`)
  }

  // Receive GIO request
  let cmd_out = [null], domain_out = [null];
  let request_data = Buffer.alloc(1024);
  let length_out = [request_data.length];
  if (cm_receive_cmio_request(machine, cmd_out, domain_out, request_data, length_out) != CM_ERROR_OK) {
    throw new Error(`failed to receive CMIO request: ${cm_get_last_error_message()}`)
  }
  let cmd = cmd_out[0], domain = domain_out[0];
  if (cmd != CM_CMIO_YIELD_COMMAND_MANUAL || domain != 16) {
    throw new Error("unsupported CMIO request, expected GIO with domain=16")
  }
  let length = length_out[0];
  console.log(request_data.toString('utf8', 0, length));

  // Send GIO response
  let response_data = Buffer.from("Hello from outside!", 'utf8')
  if (cm_send_cmio_response(machine, domain, response_data, response_data.length) != CM_ERROR_OK) {
    throw new Error("failed to send CMIO response")
  }

  // Resume the machine
  let break_reason_out = [null]
  if (cm_run(machine, CM_MCYCLE_MAX, break_reason_out) != CM_ERROR_OK) {
    throw new Error(`failed to resume machine: ${cm_get_last_error_message()}`)
  }
  let break_reason = break_reason_out[0]

  // Print reason for run interruption
  switch (break_reason) {
    case CM_BREAK_REASON_HALTED:
      console.log("Halted")
      break
    case CM_BREAK_REASON_YIELDED_MANUALLY:
      console.log("Yielded manually")
      break
    case CM_BREAK_REASON_YIELDED_AUTOMATICALLY:
      console.log("Yielded automatically")
      break
    case CM_BREAK_REASON_YIELDED_SOFTLY:
      console.log("Yielded softly")
      break
    case CM_BREAK_REASON_REACHED_TARGET_MCYCLE:
      console.log("Reached target machine cycle")
      break
    case CM_BREAK_REASON_FAILED:
    default:
      console.log("Interpreter failed")
      break
  }

  // Read and print machine cycles
  let mcycle_out = [null]
  if (cm_read_reg(machine, CM_REG_MCYCLE, mcycle_out) != CM_ERROR_OK) {
    throw new Error(`failed to read machine cycle: ${cm_get_last_error_message()}`)
  }
  let mcycle = mcycle_out[0]
  console.log("Cycles:", mcycle)
} finally {
  cm_delete(machine)
}
```

Compile and run with:
```sh
node example-gio.js
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
