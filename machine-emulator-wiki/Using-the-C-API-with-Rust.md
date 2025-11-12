## Requirements

Before trying this example first make sure:
- You have Cartesi Machine installed globally in your system.
- You have `linux.bin` and `rootfs.ext2` images available locally (you could copy them from your installation).
- You have a Rust compiler.
- You are using Cartesi Machine 0.19+ (contains the new C API, it's not released yet).

## Bindings

First we will generate C API bindings into `cartesi.rs` using [rust-bindgen](https://rust-lang.github.io/rust-bindgen/),
you can install it with:

```sh
cargo install bindgen-cli
```

Then we generate the bindings with the following the following command:

```sh
bindgen /usr/include/cartesi-machine/machine-c-api.h \
    -o cartesi.rs \
    --no-layout-tests \
    --allowlist-item '^cm_.*' \
    --allowlist-item '^CM_.*' \
    --merge-extern-blocks \
    --no-doc-comments \
    --no-prepend-enum-name \
    --translate-enum-integer-types
```

It should generate `cartesi.rs` locally from `machine-c-api.h` header,
make sure to use adjust the correct path for your cartesi machine headers.

## Hello example

First make sure you have `cartesi.rs` available in current directory.
The following example boots a machine and prints a hello message:

```rust
use std::ffi::CString;
use std::ffi::CStr;
use std::ptr;

#[allow(dead_code)]
#[allow(non_camel_case_types)]
mod cartesi;

fn get_last_error_message() -> &'static str {
    return unsafe{CStr::from_ptr(cartesi::cm_get_last_error_message())}.to_str().unwrap();
}

fn main() {
    // Set machine configuration
    let config = CString::new(r#"{
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
    }"#).unwrap();

    // Create a new machine
    let mut machine: *mut cartesi::cm_machine = ptr::null_mut();
    if unsafe { cartesi::cm_create_new(config.as_ptr(), ptr::null(), &mut machine) } != cartesi::CM_ERROR_OK {
        panic!("failed to create machine: {}", get_last_error_message());
    }

    // Run the machine
    let mut break_reason = cartesi::CM_BREAK_REASON_FAILED;
    if unsafe { cartesi::cm_run(machine, u64::MAX, &mut break_reason) } != cartesi::CM_ERROR_OK {
        panic!("failed to run machine: {}", get_last_error_message());
    }

    // Print reason for run interruption
    match break_reason {
        cartesi::CM_BREAK_REASON_HALTED => println!("Halted"),
        cartesi::CM_BREAK_REASON_YIELDED_MANUALLY => println!("Yielded manually"),
        cartesi::CM_BREAK_REASON_YIELDED_AUTOMATICALLY => println!("Yielded automatically"),
        cartesi::CM_BREAK_REASON_YIELDED_SOFTLY => println!("Yielded softly"),
        cartesi::CM_BREAK_REASON_REACHED_TARGET_MCYCLE => println!("Reached target machine cycle"),
        cartesi::CM_BREAK_REASON_FAILED | _ => println!("Interpreter failed"),
    }

    // Read and print machine cycles
    let mut mcycle: u64 = 0;
    if unsafe { cartesi::cm_read_reg(machine, cartesi::CM_REG_MCYCLE, &mut mcycle) } != cartesi::CM_ERROR_OK {
        panic!("failed to read machine cycle: {}", get_last_error_message());
    }
    println!("Cycles: {}", mcycle);

    // Cleanup and exit
    unsafe { cartesi::cm_delete(machine) };
}
```

Compile and run with:
```sh
rustc example.rs -lcartesi
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

```rust
use std::ffi::CString;
use std::ffi::CStr;
use std::ptr;

#[allow(dead_code)]
#[allow(non_camel_case_types)]
mod cartesi;

fn get_last_error_message() -> &'static str {
    return unsafe{CStr::from_ptr(cartesi::cm_get_last_error_message())}.to_str().unwrap();
}

fn main() {
    // Set machine configuration
    let config = CString::new(r#"{
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
    }"#).unwrap();

    // Create a new machine
    let mut machine: *mut cartesi::cm_machine = ptr::null_mut();
    if unsafe { cartesi::cm_create_new(config.as_ptr(), ptr::null(), &mut machine) } != cartesi::CM_ERROR_OK {
        panic!("failed to create machine: {}", get_last_error_message());
    }

    // Run the machine
    if unsafe { cartesi::cm_run(machine, u64::MAX, ptr::null_mut()) } != cartesi::CM_ERROR_OK {
        panic!("failed to run machine: {}", get_last_error_message());
    }

    // Receive GIO request
    let mut cmd: u8 = 0;
    let mut domain: u16 = 0;
    let mut request_data = [0u8; 1024];
    let mut length = request_data.len() as u64;
    if unsafe { cartesi::cm_receive_cmio_request(machine, &mut cmd, &mut domain, request_data.as_mut_ptr(), &mut length) } != cartesi::CM_ERROR_OK {
        panic!("failed to receive CMIO request: {}", get_last_error_message());
    }
    if u32::from(cmd) != cartesi::CM_CMIO_YIELD_COMMAND_MANUAL || domain != 16 {
        panic!("unsupported CMIO request, expected GIO with domain=16");
    }
    println!("{}", String::from_utf8_lossy(&request_data[..length as usize]));

    // Send GIO response
    let response_data = "Hello from outside!";
    if unsafe { cartesi::cm_send_cmio_response(machine, domain, response_data.as_ptr(), response_data.len() as u64) } != cartesi::CM_ERROR_OK {
        panic!("failed to send CMIO response: {}", get_last_error_message());
    }

    // Resume the machine
    let mut break_reason = cartesi::CM_BREAK_REASON_FAILED;
    if unsafe { cartesi::cm_run(machine, u64::MAX, &mut break_reason) } != cartesi::CM_ERROR_OK {
        panic!("failed to resume machine: {}", get_last_error_message());
    }

    // Print reason for run interruption
    match break_reason {
        cartesi::CM_BREAK_REASON_HALTED => println!("Halted"),
        cartesi::CM_BREAK_REASON_YIELDED_MANUALLY => println!("Yielded manually"),
        cartesi::CM_BREAK_REASON_YIELDED_AUTOMATICALLY => println!("Yielded automatically"),
        cartesi::CM_BREAK_REASON_YIELDED_SOFTLY => println!("Yielded softly"),
        cartesi::CM_BREAK_REASON_REACHED_TARGET_MCYCLE => println!("Reached target machine cycle"),
        cartesi::CM_BREAK_REASON_FAILED | _ => println!("Interpreter failed"),
    }

    // Read and print machine cycles
    let mut mcycle: u64 = 0;
    if unsafe { cartesi::cm_read_reg(machine, cartesi::CM_REG_MCYCLE, &mut mcycle) } != cartesi::CM_ERROR_OK {
        panic!("failed to read machine cycle: {}", get_last_error_message());
    }
    println!("Cycles: {}", mcycle);

    // Cleanup and exit
    unsafe { cartesi::cm_delete(machine) };
}
```

Compile and run with:
```sh
rustc example-gio.rs -lcartesi
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
