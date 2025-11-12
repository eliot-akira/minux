## Requirements

Before trying this example first make sure:
- You have Cartesi Machine installed globally in your system.
- You have `linux.bin` and `rootfs.ext2` images available locally (you could copy them from your installation).
- You have a Lua 5.4 installed.
- The `LUA_CPATH_5_4` is able to find `cartesi.so` (default for global installations).
- You are using Cartesi Machine 0.20+ (contains the new C API, it's not released yet).

## Hello example

The following example boots a machine and prints a hello message:

```lua
local cartesi = require 'cartesi'
-- Set machine configuration
local config = {
  dtb = {
    entrypoint = [[echo Hello from inside!]]
  },
  flash_drive = {
    {image_filename = "rootfs.ext2"},
  },
  ram = {
    image_filename = "linux.bin",
    length = 0x8000000,
  },
}
-- Create a new machine
local machine <close> = cartesi.machine(config)
-- Run the machine
local break_reason = machine:run()
-- Print reason for run interruption
print(({
  [cartesi.BREAK_REASON_HALTED] = 'Halted',
  [cartesi.BREAK_REASON_YIELDED_MANUALLY] = 'Yielded manually\n',
  [cartesi.BREAK_REASON_YIELDED_AUTOMATICALLY] = 'Yielded automatically\n',
  [cartesi.BREAK_REASON_YIELDED_SOFTLY] = 'Yielded softly\n',
  [cartesi.BREAK_REASON_REACHED_TARGET_MCYCLE] = 'Reached target machine cycle\n',
  [cartesi.BREAK_REASON_FAILED] = 'Interpreter failed\n',
})[break_reason])
-- Read and print machine cycles
print('Cycles: '..machine:read_reg('mcycle'))
```

Compile and run with:
```sh
lua5.4 example.lua
```

You should get the following output:
```
Hello from inside!
Halted
Cycles: 48985837
```

## IO example

To perform input/output operations from inside a machine to the outside you can use the CMIO (Cartesi Machine IO) with its GIO (generic IO) interface, the following example demonstrates this:

```lua
local cartesi = require 'cartesi'
-- Set machine configuration
local config = {
  dtb = {
    entrypoint = [[echo '{"domain":16,"id":"'$(echo -n Hello from inside! | hex --encode)'"}' | rollup gio | grep -Eo '0x[0-9a-f]+' | tr -d '\n' | hex --decode; echo]]
  },
  flash_drive = {
    {image_filename = "rootfs.ext2"},
  },
  ram = {
    image_filename = "linux.bin",
    length = 0x8000000,
  },
}
-- Create a new machine
local machine <close> = cartesi.machine(config)
-- Run the machine
machine:run()
-- Receive GIO request
local cmd, domain, data = machine:receive_cmio_request()
assert(cmd == cartesi.CMIO_YIELD_COMMAND_MANUAL and domain == 16, 'unexpected CMIO request')
print(data)
-- Send GIO response
machine:send_cmio_response(domain, 'Hello from outside!')
-- Resume the machine
local break_reason = machine:run()
-- Print reason for run interruption
print(({
  [cartesi.BREAK_REASON_HALTED] = 'Halted',
  [cartesi.BREAK_REASON_YIELDED_MANUALLY] = 'Yielded manually\n',
  [cartesi.BREAK_REASON_YIELDED_AUTOMATICALLY] = 'Yielded automatically\n',
  [cartesi.BREAK_REASON_YIELDED_SOFTLY] = 'Yielded softly\n',
  [cartesi.BREAK_REASON_REACHED_TARGET_MCYCLE] = 'Reached target machine cycle\n',
  [cartesi.BREAK_REASON_FAILED] = 'Interpreter failed\n',
})[break_reason])
-- Read and print machine cycles
print('Cycles: '..machine:read_reg('mcycle'))
```

Compile and run with:
```sh
lua5.4 example-gio.lua
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
