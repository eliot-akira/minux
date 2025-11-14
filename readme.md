# Minux

Minimal Linux on WebAssembly with [Alpine](https://www.alpinelinux.org/) and [Cartesi Machine](https://github.com/cartesi/machine-emulator) (64-bit RISC-V CPU emulator).

![Minux screenshot](minux-screenshot.png)

Website: https://eliot-akira.github.io/minux/

## Develop

Build machine.

```sh
cd machine-emulator
make install PREFIX="$(realpath ../cartesi)"
cd ..
```

Builld operating system as WebAssembly binary.

```sh
make
```

Run machine.

```sh
./run
```
