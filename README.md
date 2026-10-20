# rgbmatrix-wheels

Prebuilt wheels of [hzeller/rpi-rgb-led-matrix](https://github.com/hzeller/rpi-rgb-led-matrix)'s
Python bindings, so a Pi installing
[nhl-led-scoreboard-v2](https://github.com/Tape-to-Tape-IoT/nhl-led-scoreboard-v2) downloads the
panel driver instead of compiling it (10–20 minutes on a Zero 2 W).

Upstream publishes no wheels. Each [release](../../releases) here is one upstream commit, built
unmodified.

## What a wheel is built for

- **Every 64-bit Pi, Zero 2 W to Pi 5.** The library compiles the Pi 5's RP1 backends in beside
  the classic GPIO path and picks one at runtime.
- **Raspberry Pi OS Trixie, CPython 3.13, aarch64.** The scoreboard requires all three.
- **No panel options compiled in.** Mapping, slowdown, PWM timing and `rp1_pio` are all set at
  runtime from the scoreboard's `[display]` config. The one build setting is an include path for
  Pillow's headers, the same one the scoreboard's `pyproject.toml` passes.

## Releasing a new commit

When the scoreboard's pinned `rev` moves:

1. **Actions → Build wheel → Run workflow**, with the new full commit SHA.
2. Put the `url` from the release notes in the scoreboard's `pyproject.toml`, then `uv lock`.

Releases are never replaced: the scoreboard's `uv.lock` pins each wheel's hash.

## Building one by hand

On any arm64 machine with Docker (a Pi 4 or 5 works):

```bash
docker run --rm -v "$PWD:/work" debian:trixie /work/build.sh <commit sha>
```

The wheel, its source and `SHA256SUMS` land in `dist/`.

## License

The wheels are upstream's code, GPL-2.0-or-later. Each release attaches the exact source it was
built from. The scripts in this repo are under the same license.
