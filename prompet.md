I have a Flutter image preprocessing pipeline (file: lib/core/ocr/image_preprocessor.dart)
that currently uses the pure-Dart `image` package for resizing and JPEG encoding before
sending images to an OCR API. Based on profiling logs, encoding takes ~1.1s and resizing
takes ~1s on a ~10MP image (upscaled to 2902x3600), which is slow because it's pure-Dart
pixel loops with no SIMD/native acceleration.

Goal: Replace the resize + encode step with native platform codecs to cut that time
significantly, while keeping the existing upscale/downscale logic and thresholds
(minLongestSide=3600, maxLongestSide=4000, jpegQuality=90) unchanged.

Requirements:

1. Add `flutter_image_compress` (or suggest a better-suited package if you know one)
   as a dependency.
2. Replace the `img.copyResize` + `img.encodeJpg` calls inside `_enhanceImageBytes`
   with the native equivalent — resize to target dimensions and encode to JPEG at the
   same quality, using the native package's API.
3. Keep the function isolate-safe (it currently runs inside `compute()`) — check if
   the chosen native package supports being called from inside `compute()`/a background
   isolate, and if not, restructure the call site so the native compression still runs
   off the main UI thread.
4. Preserve all existing logic: decode to get source dimensions, decide upscale vs
   downscale vs no-op based on longestSide, and keep the existing logOcr() timing logs
   at each step (decode/resize/encode) so I can compare before/after performance.
5. Don't change the public API of `ImagePreprocessor.enhance()` — same input (File),
   same output (File written to temp dir), same cleanup behavior.
6. After implementing, tell me what accuracy/quality tradeoffs (if any) the native
   encoder has vs `img.encodeJpg` at quality 90, since this feeds an OCR model reading
   PIN/serial numbers off a scratch card.

Here's the current file: [paste image_preprocessor.dart]
