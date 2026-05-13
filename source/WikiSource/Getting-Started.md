## Contents

1. <a href="#prerequisites">Prerequisites</a>
1. <a href="#install">Install the module</a>
1. <a href="#resource">Prepare a class-based DSC resource</a>
1. <a href="#generate">Generate an adapted resource manifest</a>
1. <a href="#discovery">How DSC discovers adapted resource manifests</a>
1. <a href="#bundle">Create a resource manifest list</a>
1. <a href="#next">Next steps</a>

<a name="prerequisites" />

## Prerequisites

- **PowerShell** — use PowerShell 7 or Windows PowerShell, depending on your
  module authoring workflow.
- **Microsoft DSC** — install the DSC executable when you want to test the
  generated manifests with DSC. See the [official installation guide][01].
- **A PowerShell class-based DSC resource** — the resource must use
  `[DscResource()]` on the class and `[DscProperty()]` on resource properties.

<a name="install" />

## Install the module

Install the module from PowerShell Gallery when a release is available:

```powershell
Install-PSResource -Name DscResource.Authoring
```

For local development, import the built module from the repository output:

```powershell
Import-Module ./output/module/DscResource.Authoring/DscResource.Authoring.psd1
```

<a name="resource" />

## Prepare a class-based DSC resource

Create a module with a PowerShell class-based DSC resource:

```powershell
<#
    .SYNOPSIS
        Manages an example setting.

    .DESCRIPTION
        Demonstrates a PowerShell class-based DSC resource that can be converted
        to a DSC v3 adapted resource manifest.

    .PARAMETER Name
        The unique name of the resource instance.

    .PARAMETER Value
        The desired value for the setting.

    .PARAMETER Status
        The current status returned by the resource.
#>
[DscResource()]
class ExampleResource {
    [DscProperty(Key)]
    [string] $Name

    [DscProperty(Mandatory)]
    [string] $Value

    [DscProperty(NotConfigurable)]
    [string] $Status

    [ExampleResource] Get() {
        return $this
    }

    [bool] Test() {
        return $true
    }

    [void] Set() {
    }
}
```

`DscResource.Authoring` uses this metadata when it builds the manifest:

- `[DscResource()]` marks the class as a DSC resource.
- `[DscProperty(Key)]` marks an identifying property and adds it to the schema
  `required` list.
- `[DscProperty(Mandatory)]` adds the property to the schema `required` list.
- `[DscProperty(NotConfigurable)]` marks the property as `readOnly` in the
  generated JSON schema.
- `Get()`, `Set()`, `Test()`, `Delete()`, `Export()`, `WhatIf()`, and
  `SetHandlesExist()` determine the resource capabilities.
- Comment-based help supplies resource and property descriptions.

<a name="generate" />

## Generate an adapted resource manifest

Run `New-DscAdaptedResourceManifest` against a module manifest, module script,
or standalone PowerShell script:

```powershell
$manifest = New-DscAdaptedResourceManifest -Path ./ExampleModule/ExampleModule.psd1
$manifest.ToJson() | Set-Content -Path ./ExampleResource.dsc.adaptedResource.json
```

The generated adapted resource manifest describes the PowerShell DSC resource
in the format expected by Microsoft DSC v3. DSC uses this metadata to discover
resources faster, execute resources with less discovery overhead, and return
schema information through commands such as:

```powershell
dsc resource schema --resource ExampleModule/ExampleResource
```

<a name="discovery" />

## How DSC discovers adapted resource manifests

Microsoft DSC discovers PowerShell adapted resource manifests through the
[PowerShell discovery extension][03]. The extension reads `$env:PSModulePath`
and searches those module paths for DSC manifest files, including adapted
resource manifest files.

Publish the generated manifest files with your PowerShell module. When users
install the module from PowerShell Gallery, the module installation path is on
`$env:PSModulePath`. DSC can then find the manifest during resource discovery
and use the metadata for resource listing, schema lookup, and execution.

For example, after the module is installed and available through
`$env:PSModulePath`, DSC can use the manifest schema with:

```powershell
dsc resource schema --resource ExampleModule/ExampleResource
```

<a name="bundle" />

## Create a resource manifest list

Bundle one or more adapted resource manifests into a `.dsc.manifests.json` file:

```powershell
$manifestList = New-DscAdaptedResourceManifest -Path ./ExampleModule/ExampleModule.psd1 |
    New-DscResourceManifest

$manifestList.ToJson() | Set-Content -Path ./ExampleModule.dsc.manifests.json
```

Use `Import-DscAdaptedResourceManifest` and `Import-DscResourceManifest` when
you need to load existing JSON files back into objects for inspection or
post-processing.

<a name="next" />

## Next steps

- Review [[Examples]] for common authoring tasks.
- Review the [[Command Reference]] for command synopsis and usage details.
- Read the [Microsoft DSC documentation][02] for DSC configuration and resource
  provider concepts.

<!-- Link references -->
[01]: https://learn.microsoft.com/en-us/powershell/dsc/overview?view=dsc-3.0#installation
[02]: https://learn.microsoft.com/en-us/powershell/dsc/overview?view=dsc-3.0
[03]: https://github.com/PowerShell/DSC/blob/main/extensions/powershell/powershell.discover.ps1
