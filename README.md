# Dekoodaaja

Providers fast decoders for various image formats. (Currently only QOI)

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

It is not recommended to use this library with `ReleaseSmall` mode, if you care about speed as for now:
```
# AMD Ryzen 7 3700X 8-Core Processor
nix run .#bench -- -Doptimize=ReleaseSmall
qoi (image/qoi): 0.13 GB/s in, 1.84 GB/s out, 568.854us
qoi <https://github.com/phoboslab/qoi.git> (image/qoi): 0.17 GB/s in, 2.32 GB/s out, 452.358us
qoi-simd <https://github.com/chocolate42/qoi-simd> (image/qoi): 0.11 GB/s in, 1.49 GB/s out, 702.453us
magicqoi <https://github.com/marty1885/magicqoi> (image/qoi): 0.19 GB/s in, 2.67 GB/s out, 392.934us
zig-qoi <https://github.com/ikskuh/zig-qoi> (image/qoi): 0.16 GB/s in, 2.17 GB/s out, 483.124us
zqoi <https://codeberg.org/Pivok/zqoi.git> (image/qoi): 0.16 GB/s in, 2.26 GB/s out, 464.127us
rapid-qoi <https://github.com/zakarumych/rapid-qoi> (image/qoi): 0.26 GB/s in, 3.62 GB/s out, 289.892us
qoi-rust <https://github.com/aldanor/qoi-rust> (image/qoi): 0.19 GB/s in, 2.69 GB/s out, 389.992us
qoicoubeh <https://github.com/elmarco/qoi-rust> (image/qoi): 0.19 GB/s in, 2.66 GB/s out, 393.472us
```
