# Pico SDK Dev Container - AI Coding Agent Instructions

## Project Overview
This is a **Docker-based development container** for Raspberry Pi Pico C++ development using the Pico SDK. Users consume this container via VSCode Dev Containers to build embedded firmware (`.uf2` files) without installing toolchains locally.

**Architecture:** Dockerfile → Docker image published to GHCR → consumed by user projects via `.devcontainer/devcontainer.json`

## Critical Environment Setup
- **Pico SDK location:** `/opt/pico-sdk` (always reference via `$PICO_SDK_PATH` environment variable)
- **SDK version:** Pinned in `Dockerfile` via `PICO_SDK_VERSION` (currently 1.5.0)
- **Toolchain:** `gcc-arm-none-eabi` for ARM Cortex-M0+ compilation (pre-installed in container)
- **CMake requirement:** Minimum version 3.13 (Pico SDK requirement)

## CMake Pattern (Critical)
Every Pico project MUST follow this exact initialization sequence in `CMakeLists.txt`:
```cmake
cmake_minimum_required(VERSION 3.13)
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)  # Must be before project()
project(my_project)
pico_sdk_init()  # Must be after project()
```
This order is **non-negotiable** - Pico SDK will fail if these are out of sequence.

## Build Workflow
Standard build from project root:
```bash
mkdir build && cd build && cmake .. && make
```
Output artifacts in `build/`: `*.elf`, `*.bin`, `*.hex`, `*.uf2` (`.uf2` is what users flash to Pico hardware).

To generate `.uf2` firmware, executables MUST call `pico_add_extra_outputs(target_name)` in CMakeLists.txt.

## VSCode Integration Patterns
- **Include paths:** Must include `${env.PICO_SDK_PATH}/**` in devcontainer.json settings or .vscode/c_cpp_properties.json for IntelliSense
- **Build task:** Users typically create VSCode task with `mkdir build && cd build && cmake .. && make` (see [example/.vscode/tasks.json](example/.vscode/tasks.json))
- **Devcontainer extensions:** CMake Tools + C++ extensions are standard (defined in [example/.devcontainer/devcontainer.json](example/.devcontainer/devcontainer.json))

## Common Libraries
- `pico_stdlib`: Aggregates core functionality (GPIO, UART, timers) - almost always required
- Always link libraries with `target_link_libraries(target pico_stdlib ...)`

## Docker Image Publishing
- **Registry:** GitHub Container Registry (`ghcr.io/n-i-x/pico-sdk-dev-container`)
- **Triggers:** Daily cron (10:00 UTC), all branch pushes, PRs to main, semver tags
- **Multi-arch:** Builds for `linux/amd64` and `linux/arm64`
- **Tagging:** `latest` (main branch), `sha-<commit>`, semver patterns for releases

## Updating Pico SDK Version
To update the SDK version in the container:
1. Modify `PICO_SDK_VERSION` in [Dockerfile](Dockerfile) (e.g., `ENV PICO_SDK_VERSION 1.5.1`)
2. The version must match a valid git tag from [raspberrypi/pico-sdk](https://github.com/raspberrypi/pico-sdk)
3. Commit and tag with matching semver (e.g., `git tag v1.5.1 && git push origin v1.5.1`)
4. GitHub Actions builds and publishes with semver tags (`1.5.1`, `1.5`, `1`) plus `latest`

## Project Structure Conventions
- Root `Dockerfile`: Defines the dev container image
- `example/`: Reference implementation showing proper setup
- Users create `.devcontainer/` in their own projects to consume this image

## Key Files
- [Dockerfile](Dockerfile): Container definition with toolchain installation
- [example/CMakeLists.txt](example/CMakeLists.txt): Reference CMake structure
- [README.md](README.md): Comprehensive setup guide for end users
- [.github/workflows/build-docker.yml](.github/workflows/build-docker.yml): CI/CD for container builds
