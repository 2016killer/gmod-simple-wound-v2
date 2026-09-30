<p align="right">
  <strong>English</strong> |
  <a href="README.zh-CN.md">简体中文</a>
</p>

# Simple Wound 2

Simple Wound 2 is a Garry's Mod addon for creating up to three projected,
bone-aware wounds on entities.

## Features

- Three independent wound slots per entity.
- Vertex-deformation and ellipsoid-clipping wound shaders.
- Unlit and VertexLit shader variants.
- Tool Gun support with per-axis scale, blood spread, texture selection, and
  Lite Gore compatibility.
- NPC damage triggers, including wounds created on death, ragdolls, and
  clientside corpses.
- Localization for English, Simplified Chinese, Traditional Chinese, Japanese,
  Korean, Russian, German, French, Spanish, Portuguese (Brazil), Polish,
  Turkish, Italian, Dutch, Swedish, Czech, and Ukrainian.

## Source Layout

- `lua/`: addon logic, trigger handling, menus, and the Tool Gun.
- `materials/`: bundled wound materials and textures.
- `resource/localization/`: localized interface strings.
- `binary/src/`: C++ shader bridge and shader definitions.
- `binary/src/shaders/hlsl/`: shader source.
- `binary/src/shaders/vcs/` and `binary/src/shaders/inc/`: compiled shader data
  used by the binary module.
- `TEMP/`: ignored legacy reference code. It is not part of the runtime addon.

## Shader Compiler Environment

Reference documentation:

https://developer.valvesoftware.com/wiki/Shader_Authoring

This project uses the Source SDK 2013 shader compiler workflow, including
SCell555's `ShaderCompile` tool. A standalone HLSL compiler is not sufficient.

### Prerequisites

1. Source SDK 2013 source checkout:
   https://github.com/ValveSoftware/source-sdk-2013
   Use commit `b8cfb12c0e083a2ef5b2f9f9b50f3902fa034474`.
2. Source SDK Base 2013 runtime from Steam:
   `Source SDK Base 2013 Singleplayer` and, for compatibility testing,
   `Source SDK Base 2013 Multiplayer`.
3. SCell555 `ShaderCompile` release:
   https://github.com/SCell555/ShaderCompile/releases/tag/build_235_20231013.2
4. `premake5`.
5. The Visual Studio 2019 toolset.

Complete the environment preparation steps highlighted in the Valve guide.

![tip1](img/tip1.jpg)

### Configure The Shader Build

1. Edit the default `--sdk-path` in `binary/buildshaders30.py`, or pass the path
   explicitly when running the script. It must point to the SDK source tree's
   `materialsystem/stdshaders` directory.
2. If the default Garry's Mod path is not correct for your machine, edit
   `GAME_DIR` in `binary/buildgmodshaders.bat`.
3. Run the shader build:

```powershell
python binary/buildshaders30.py --sdk-path "C:\path\to\source-sdk-2013\src\materialsystem\stdshaders"
```

The script copies the project HLSL files into the SDK tree, builds the DX9
shader combinations, and writes the resulting `.vcs` and generated `.inc`
files back into `binary/src/shaders/vcs` and `binary/src/shaders/inc`.

## Building Modules

Initialize the submodules first:

```bash
git submodule update --init --recursive
```

Edit the relevant path in `binary/premakevs2019.bat` or
`binary/premakevs2019_x86_x64.bat`, then run it. If a configured path does not
exist, create it first; otherwise Premake or Visual Studio generation can stall.

The scripts generate the support branches:

- `binary/premake5.lua` for the main 32-bit branch.
- `binary/premake5_x86_x64.lua` for the x86_x64 32-bit and 64-bit branches.

Open the generated solution and build the Release configurations:

- `gmcl_simple_wound_win32.dll`
- `gmcl_simple_wound_x86_x64_win32.dll`
- `gmcl_simple_wound_x86_x64_win64.dll`

Place the resulting DLLs in `garrysmod/lua/bin`. The shader `.vcs` files must be
available in `garrysmod/shaders/fxc`.

## Licenses

This project includes code derived from multiple sources:

- GPLv3 portions: `LICENSE`
- `garrysmod_common` (MIT-style license):
  `binary/garrysmod_common/license.txt` and
  `binary/garrysmod_common_x86_x64/license.txt`
- Source SDK 2013 (SOURCE 1 SDK License):
  `binary/garrysmod_common/sourcesdk-minimal/LICENSE` and
  `binary/garrysmod_common_x86_x64/sourcesdk-minimal/LICENSE`
- Third-party notices:
  `binary/garrysmod_common/sourcesdk-minimal/thirdpartylegalnotices.txt` and
  `binary/garrysmod_common_x86_x64/sourcesdk-minimal/thirdpartylegalnotices.txt`
