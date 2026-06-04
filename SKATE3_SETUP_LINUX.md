# Skate 3 Recomp Linux / Docker Setup Notes

This repo already contains Linux presets and Vulkan/GTK runtime support from ReXGlue.
The easiest reproducible path from Windows is Docker Desktop.

## Prerequisites

- Docker Desktop with Linux containers enabled.
- Git submodules initialized.
- A legally obtained Skate 3 dump containing:
  - `default.xex`
  - `default.xex_uncrypted.xex`
  - `data`
  - `nxeart`
- For the tested Docker flow, Clang 20 is used on Linux.

## Build The Linux SDK In Docker

From the repo root in PowerShell:

```powershell
git submodule update --init --recursive
.\tools\Invoke-LinuxDockerBuild.ps1 -Clean
```

Output:

```text
out\install\linux-amd64
```

## Generate And Build A Linux Skate 3 Project In Docker

Example using the provided asset folder:

```powershell
.\tools\Invoke-LinuxDockerBuild.ps1 `
  -Clean `
  -AssetRoot "C:\Users\kurt\Documents\Skate3Recomp-Windows\Skate 3 Files" `
  -ProjectRoot "C:\Users\kurt\Documents\skate3-linux"
```

This will:

1. Build and install the Linux SDK.
2. Run `rexglue init` for Skate 3 if `skate3_manifest.toml` is missing.
3. Run `rexglue codegen`.
4. Configure and build the generated Linux app.

Expected generated binary location:

```text
C:\Users\kurt\Documents\skate3-linux\out\build\linux-amd64-relwithdebinfo\skate3
```

## Native Linux Notes

If you build natively on Linux instead of Docker, install the same core deps used by the Docker image:

- Clang 20+
- CMake 3.25+
- Ninja
- GTK3 development headers
- X11 XCB development headers
- Vulkan development headers/tools
- ALSA / PulseAudio / PipeWire development headers

On Ubuntu-like distros, the Dockerfile under `docker/linux-amd64/Dockerfile` is the reference dependency list.

## Notes

- Release packaging in this repo is still Windows-oriented.
- Linux source builds use the Vulkan + GTK path.
- The local timing patch documented in `SKATE3_SETUP.md` may still be useful after codegen, depending on the current Skate 3 bring-up state.
