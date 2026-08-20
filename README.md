# Dekoodaaja

Providers fast decoders for various image formats. (Currently only QOI)

## Benchmarks

```
# AMD Ryzen 7 3700X 8-Core Processor
nix run .#bench -- -Doptimize=ReleaseFast
qoi (image/qoi): 0.43 GB/s in, 5.94 GB/s out, (176.424us)
qoi <https://github.com/phoboslab/qoi.git> (image/qoi): 0.14 GB/s in, 1.99 GB/s out, (527.568us)
qoi-simd <https://github.com/chocolate42/qoi-simd> (image/qoi): 0.11 GB/s in, 1.47 GB/s out, (713.751us)
magicqoi <https://github.com/marty1885/magicqoi> (image/qoi): 0.27 GB/s in, 3.81 GB/s out, (275.501us)
zig-qoi <https://github.com/ikskuh/zig-qoi> (image/qoi): 0.24 GB/s in, 3.39 GB/s out, (309.035us)
zqoi <https://codeberg.org/Pivok/zqoi.git> (image/qoi): 0.18 GB/s in, 2.53 GB/s out, (413.984us)
rapid-qoi <https://github.com/zakarumych/rapid-qoi> (image/qoi): 0.32 GB/s in, 4.52 GB/s out, (232.05us)
qoi-rust <https://github.com/aldanor/qoi-rust> (image/qoi): 0.32 GB/s in, 4.49 GB/s out, (233.329us)
```

It is not recommended to use this library with `ReleaseSmall` mode with zig 0.16+ as for now:
```
# AMD Ryzen 7 3700X 8-Core Processor
nix run .#bench -- -Doptimize=ReleaseSmall
qoi (image/qoi): 0.08 GB/s in, 1.12 GB/s out, (937.182us)
qoi <https://github.com/phoboslab/qoi.git> (image/qoi): 0.16 GB/s in, 2.27 GB/s out, (461.497us)
qoi-simd <https://github.com/chocolate42/qoi-simd> (image/qoi): 0.11 GB/s in, 1.48 GB/s out, (709.816us)
magicqoi <https://github.com/marty1885/magicqoi> (image/qoi): 0.19 GB/s in, 2.64 GB/s out, (397.934us)
zig-qoi <https://github.com/ikskuh/zig-qoi> (image/qoi): 0.15 GB/s in, 2.15 GB/s out, (487.185us)
zqoi <https://codeberg.org/Pivok/zqoi.git> (image/qoi): 0.16 GB/s in, 2.28 GB/s out, (459.92us)
rapid-qoi <https://github.com/zakarumych/rapid-qoi> (image/qoi): 0.26 GB/s in, 3.60 GB/s out, (291.645us)
qoi-rust <https://github.com/aldanor/qoi-rust> (image/qoi): 0.19 GB/s in, 2.66 GB/s out, (394.737us)
```

Zig 0.15.2 is fine (rust results not available for 0.15.2):
```
# AMD Ryzen 7 3700X 8-Core Processor
nix shell github:Cloudef/zig2nix#zig-0_15_2 -c sh bench.sh -Doptimize=ReleaseSmall
qoi (image/qoi): 0.17 GB/s in, 2.37 GB/s out, (441.597us)
qoi <https://github.com/phoboslab/qoi.git> (image/qoi): 0.16 GB/s in, 2.28 GB/s out, (460.813us)
qoi-simd <https://github.com/chocolate42/qoi-simd> (image/qoi): 0.10 GB/s in, 1.47 GB/s out, (715.606us)
magicqoi <https://github.com/marty1885/magicqoi> (image/qoi): 0.18 GB/s in, 2.57 GB/s out, (407.722us)
zig-qoi <https://github.com/ikskuh/zig-qoi> (image/qoi): 0.15 GB/s in, 2.12 GB/s out, (495.643us)
zqoi <https://codeberg.org/Pivok/zqoi.git> (image/qoi): 0.17 GB/s in, 2.37 GB/s out, (442.284us)
```
