# Sky1 Gentoo overlay

This overlay offers ebuilds for CIX Sky1 SoC platforms due to the unavailability
of separate patches to use in `emerge`. Do not expect stability or thoroughly
tested changes; use only at your own risk. For safety purposes, keywords other
than ~arm64 are removed from packages if present.

## Installation

As documented in [eselect/repository](https://wiki.gentoo.org/wiki/Eselect/Repository),
you should install `eselect-repository` first and then you can add overlays:

```bash
emerge app-eselect/eselect-repository
eselect repository add sky1 git https://github.com/000exploit/sky1-overlay
```

## Current packages

Package | Status
---     | ---   
media-video/ffmpeg-8.0.1 | Works, may not pass `test`
media-libs/mesa-26.0.0 | Works

## Notes

### `make.conf` flags

Nothing really useful here. My own `COMMON_CFLAGS` variable contains:

```
COMMON_FLAGS="-O2 -pipe -march=native -mtune=native --param=aarch64-autovec-preference=prefer-sve"
```

LTO is enabled for (mostly) all packages on my system for testing. Follow
[LTO](https://wiki.gentoo.org/wiki/LTO) documentation for tuning, otherwise do
not add `-flto` parameter.

### GStreamer

There's no patched GStreamer with V4L2 AV1 decoder support in the repository at
the moment (not required for normal daily usage?), and GStreamer sometimes
prioritizes libav decoders instead of native ones. To mitigate this, it's
possible to change plugin ranks with the environment variable `GST_PLUGIN_FEATURE_RANK`.
For example: `GST_PLUGIN_FEATURE_RANK=v4l2h264dec:MAX,v4l2h265dec:MAX,v4l2mpeg4dec:MAX,v4l2vp8dec:MAX,v4l2vp9dec:MAX`.
If you don't want to use libav for some audio codecs, i.e., `faad`, it's
possible to override this with the specified environment variable.

## TODO

Missing packages:
- [Patched mainline kernel sources](https://github.com/Sky1-Linux/linux)
- Gentoo kernel with sky1 patches (config check?)
- [vulkan-wsi-layer](https://github.com/Sky1-Linux/vulkan-wsi-layer) (?)
- [Mali DKMS driver](https://github.com/Sky1-Linux/cix-gpu-kmd)
- [User-space Mali driver](https://github.com/Sky1-Linux/sky1-gpu-support) (OpenRC? eselect?)
