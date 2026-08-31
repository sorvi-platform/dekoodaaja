# Dekoodaaja

Provides fast decoders for various image formats. (Currently only QOI)

## Benchmarks

```
# AMD Ryzen 7 3700X 8-Core Processor
nix run .#bench -- -Doptimize=ReleaseFast
qoi (image/qoi): 0.44 GB/s in, 6.17 GB/s out, 170.081us
qoi <https://github.com/phoboslab/qoi.git> (image/qoi): 0.14 GB/s in, 2.00 GB/s out, 523.124us
qoi-simd <https://github.com/chocolate42/qoi-simd> (image/qoi): 0.11 GB/s in, 1.49 GB/s out, 705.961us
magicqoi <https://github.com/marty1885/magicqoi> (image/qoi): 0.28 GB/s in, 3.86 GB/s out, 271.645us
zig-qoi <https://github.com/ikskuh/zig-qoi> (image/qoi): 0.24 GB/s in, 3.42 GB/s out, 306.602us
zqoi <https://codeberg.org/Pivok/zqoi.git> (image/qoi): 0.18 GB/s in, 2.55 GB/s out, 410.529us
rapid-qoi <https://github.com/zakarumych/rapid-qoi> (image/qoi): 0.32 GB/s in, 4.44 GB/s out, 236.404us
qoi-rust <https://github.com/aldanor/qoi-rust> (image/qoi): 0.32 GB/s in, 4.48 GB/s out, 234.275us
qoicoubeh <https://github.com/elmarco/qoi-rust> (image/qoi): 0.34 GB/s in, 4.75 GB/s out, 220.692us
```

```
# AMD Ryzen 7 3700X 8-Core Processor
nix run .#bench -- -Doptimize=ReleaseSmall
qoi (image/qoi): 0.20 GB/s in, 2.82 GB/s out, 372.37us
qoi <https://github.com/phoboslab/qoi.git> (image/qoi): 0.15 GB/s in, 2.11 GB/s out, 496.278us
qoi-simd <https://github.com/chocolate42/qoi-simd> (image/qoi): 0.11 GB/s in, 1.49 GB/s out, 704.787us
magicqoi <https://github.com/marty1885/magicqoi> (image/qoi): 0.18 GB/s in, 2.58 GB/s out, 407.179us
zig-qoi <https://github.com/ikskuh/zig-qoi> (image/qoi): 0.11 GB/s in, 1.49 GB/s out, 703.877us
zqoi <https://codeberg.org/Pivok/zqoi.git> (image/qoi): 0.15 GB/s in, 2.13 GB/s out, 491.462us
rapid-qoi <https://github.com/zakarumych/rapid-qoi> (image/qoi): 0.25 GB/s in, 3.56 GB/s out, 294.652us
qoi-rust <https://github.com/aldanor/qoi-rust> (image/qoi): 0.19 GB/s in, 2.64 GB/s out, 396.598us
qoicoubeh <https://github.com/elmarco/qoi-rust> (image/qoi): 0.19 GB/s in, 2.66 GB/s out, 394.937us
```
