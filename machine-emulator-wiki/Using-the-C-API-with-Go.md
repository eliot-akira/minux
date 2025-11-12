## Requirements

Before trying this example first make sure:
- You have Cartesi Machine installed globally in your system.
- You have `linux.bin` and `rootfs.ext2` images available locally (you could copy them from your installation).
- You have a Go compiler.
- You are using Cartesi Machine 0.19+ (contains the new C API, it's not released yet).

## Hello example

We will be using [CGO](https://pkg.go.dev/cmd/cgo) to call functions from C libraries.
The following example boots a machine and prints a hello message:

```go
package main
import "fmt"
import "log"
// #cgo LDFLAGS: -lcartesi
// #include <cartesi-machine/machine-c-api.h>
import "C"

func main() {
  // Set machine configuration
  config := `{
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
  }`
  runtime_config := "{}"

  // Create a new machine
  var machine *C.cm_machine
  if C.cm_create_new(C.CString(config), C.CString(runtime_config), &machine) != C.CM_ERROR_OK {
    log.Fatal("failed to create machine: ", C.GoString(C.cm_get_last_error_message()))
  }
  defer C.cm_delete(machine)

  // Run the machine
  var break_reason C.cm_break_reason
  if C.cm_run(machine, C.CM_MCYCLE_MAX, &break_reason) != C.CM_ERROR_OK {
    log.Fatal("failed to run machine: ", C.GoString(C.cm_get_last_error_message()))
  }

  // Print reason for run interruption
  switch break_reason {
    case C.CM_BREAK_REASON_HALTED:
      fmt.Println("Halted")
    case C.CM_BREAK_REASON_YIELDED_MANUALLY:
      fmt.Println("Yielded manually")
    case C.CM_BREAK_REASON_YIELDED_AUTOMATICALLY:
      fmt.Println("Yielded automatically")
    case C.CM_BREAK_REASON_YIELDED_SOFTLY:
      fmt.Println("Yielded softly")
    case C.CM_BREAK_REASON_REACHED_TARGET_MCYCLE:
      fmt.Println("Reached target machine cycle")
    case C.CM_BREAK_REASON_FAILED:
    default:
      fmt.Println("Interpreter failed")
  }

  // Read and print machine cycles
  var mcycle C.uint64_t
  if (C.cm_read_reg(machine, C.CM_REG_MCYCLE, &mcycle) != C.CM_ERROR_OK) {
    log.Fatal("failed to read machine cycle: ", C.GoString(C.cm_get_last_error_message()))
  }
  fmt.Println("Cycles:", mcycle)
}
```

Compile and run with:
```sh
go run example.go
```

You should get the following output:
```
Hello from inside!
Halted
Cycles: 48985837
```

## IO example

To perform input/output operations from inside a machine to the outside you can use the CMIO (Cartesi Machine IO) with its GIO (generic IO) interface, the following example demonstrates this:

```go
package main
import "fmt"
import "log"
import "unsafe"

// #cgo LDFLAGS: -lcartesi
// #include <cartesi-machine/machine-c-api.h>
import "C"

func main() {
  // Set machine configuration
  config := `{
    "dtb": {
      "entrypoint": "echo '{\"domain\":16,\"id\":\"'$(echo -n Hello from inside! | hex --encode)'\"}' | rollup gio | grep -Eo '0x[0-9a-f]+' | tr -d '\n' | hex --decode; echo"
    },
    "flash_drive": [
      {"image_filename": "rootfs.ext2"}
    ],
    "ram": {
      "length": 134217728,
      "image_filename": "linux.bin"
    }
  }`
  runtime_config := "{}"

  // Create a new machine
  var machine *C.cm_machine
  if C.cm_create_new(C.CString(config), C.CString(runtime_config), &machine) != C.CM_ERROR_OK {
    log.Fatal("failed to create machine: ", C.GoString(C.cm_get_last_error_message()))
  }
  defer C.cm_delete(machine)

  // Run the machine
  if C.cm_run(machine, C.CM_MCYCLE_MAX, (*C.cm_break_reason)(unsafe.Pointer(C.NULL))) != C.CM_ERROR_OK {
    log.Fatal("failed to run machine: ", C.GoString(C.cm_get_last_error_message()))
  }

  // Receive GIO request
  var cmd C.uint8_t
  var domain C.uint16_t
  var request_data [1024]C.uint8_t
  var length C.uint64_t = 1024
  if C.cm_receive_cmio_request(machine, &cmd, &domain, (*C.uint8_t)(unsafe.Pointer(&request_data)), &length) != C.CM_ERROR_OK {
    log.Fatal("failed to receive CMIO request: ", C.GoString(C.cm_get_last_error_message()))
  }
  if cmd != C.CM_CMIO_YIELD_COMMAND_MANUAL || domain != 16 {
    log.Fatal("unsupported CMIO request, expected GIO with domain=16")
  }
  fmt.Printf("%.*s\n", length, request_data);

  // Send GIO response
  response_data := "Hello from outside!";
  if C.cm_send_cmio_response(machine, domain, (*C.uint8_t)(unsafe.Pointer(C.CString(response_data))), C.uint64_t(len(response_data))) != C.CM_ERROR_OK {
    log.Fatal("failed to send CMIO response: ", C.GoString(C.cm_get_last_error_message()))
  }

  // Resume the machine
  var break_reason C.cm_break_reason
  if C.cm_run(machine, C.CM_MCYCLE_MAX, &break_reason) != C.CM_ERROR_OK {
    log.Fatal("failed to resume machine: ", C.GoString(C.cm_get_last_error_message()))
  }

  // Print reason for run interruption
  switch break_reason {
    case C.CM_BREAK_REASON_HALTED:
      fmt.Println("Halted")
    case C.CM_BREAK_REASON_YIELDED_MANUALLY:
      fmt.Println("Yielded manually")
    case C.CM_BREAK_REASON_YIELDED_AUTOMATICALLY:
      fmt.Println("Yielded automatically")
    case C.CM_BREAK_REASON_YIELDED_SOFTLY:
      fmt.Println("Yielded softly")
    case C.CM_BREAK_REASON_REACHED_TARGET_MCYCLE:
      fmt.Println("Reached target machine cycle")
    case C.CM_BREAK_REASON_FAILED:
    default:
      fmt.Println("Interpreter failed")
  }

  // Read and print machine cycles
  var mcycle C.uint64_t
  if (C.cm_read_reg(machine, C.CM_REG_MCYCLE, &mcycle) != C.CM_ERROR_OK) {
    log.Fatal("failed to read machine cycle: ", C.GoString(C.cm_get_last_error_message()))
  }
  fmt.Println("Cycles:", mcycle)
}
```

Compile and run with:
```sh
go run example-gio.go
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
