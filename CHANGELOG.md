# Changelog for DscResource.Authoring

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
