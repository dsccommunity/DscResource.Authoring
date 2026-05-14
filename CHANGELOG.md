# Changelog for DscResource.Authoring

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added support for `[ValidatePattern()]` attributes on DSC properties, emitting the regex as a `pattern` keyword in the generated JSON schema.
- Added `-AllowNonEcmaPattern` switch to `New-DscAdaptedResourceManifest` to force-emit patterns containing .NET-specific regex constructs that are not ECMA 262 compatible.

### Fixed

- Fixed build task import so module aliases are correctly exported when the module is loaded.
- Fixed `[ValidateSet()]` attributes on `[string]` DSC properties now being correctly emitted as `enum` in the generated JSON schema.
- Fixed `UTF8BOM` issue on new script.

## [0.2.0] - 2026-05-14

### Added

- Added `New-DscAdaptedResourceManifest` to generate adapted resource manifests from PowerShell class-based DSC resources.
- Added `-Version` parameter to `New-DscAdaptedResourceManifest` to override the version resolved from the module manifest, accepting a semantic version string.

### Fixed

- Fixed descriptions in generated manifests containing literal `\r\n`.
- Added `Import-DscAdaptedResourceManifest` to load an adapted resource manifest from a `.dsc.adaptedResource.json` file.
- Added `Import-DscResourceManifest` to load a full DSC resource manifest list from a `.dsc.manifests.json` file.
- Added `New-DscResourceManifest` to build a `DscResourceManifestList` object from adapted resource manifests.
- Added `New-DscPropertyOverride` to create property override objects for use with `Update-DscAdaptedResourceManifest`.
- Added `Update-DscAdaptedResourceManifest` to apply property overrides to the embedded JSON schema of an adapted resource manifest.
