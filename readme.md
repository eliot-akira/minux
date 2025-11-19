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

## References

- [Web Cartesi Machine](https://github.com/edubart/webcm)
- [Cartesi Machine Emulator Wiki](https://github.com/cartesi/machine-emulator)
- Image builders for [Linux Kernel](https://github.com/cartesi/machine-linux-image) and [RootFS](https://github.com/cartesi/machine-rootfs-image)
- [The Core of Cartesi](https://w3.impa.br/~diego/publications/TexNeh18.pdf) (PDF)
