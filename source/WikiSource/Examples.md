## Contents

1. <a href="#overview">Overview</a>
1. <a href="#single-module">Generate manifests for one module</a>
1. <a href="#all-modules">Generate manifests for multiple modules</a>
1. <a href="#override-description">Override schema descriptions</a>
1. <a href="#json-schema">Add JSON schema constraints</a>
1. <a href="#readonly">Generate read-only properties</a>
1. <a href="#publish">Publish manifests with a module</a>

<a name="overview" />

## Overview

These examples show common authoring tasks for PowerShell class-based DSC
resources and Microsoft DSC v3 manifests. Adapted resource manifests provide
`dsc.exe` with resource metadata and schema context before execution, which
improves discovery speed and enables commands such as
`dsc resource schema --resource <resource-type>`.

<a name="single-module" />

## Generate manifests for one module

Generate adapted resource manifests from a module manifest and write one JSON
file per resource:

```powershell
New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1 |
    ForEach-Object {
        $fileName = '{0}.dsc.adaptedResource.json' -f ($_.Type -replace '/', '.')
        $_.ToJson() | Set-Content -Path $fileName
    }
```

<a name="all-modules" />

## Generate manifests for multiple modules

Discover module manifests below a folder and generate adapted resource
manifests for every class-based DSC resource:

```powershell
Get-ChildItem -Path ./Modules -Filter *.psd1 -Recurse |
    New-DscAdaptedResourceManifest |
    New-DscResourceManifest |
    ForEach-Object {
        $_.ToJson() | Set-Content -Path ./resources.dsc.manifests.json
    }
```

<a name="override-description" />

## Override schema descriptions

Use `New-DscPropertyOverride` and `Update-DscAdaptedResourceManifest` when the
generated schema needs more specific text:

```powershell
$overrides = @(
    New-DscPropertyOverride -Name 'Name' `
        -Description 'The unique name of the resource instance.'
)

New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1 |
    Update-DscAdaptedResourceManifest -PropertyOverride $overrides |
    ForEach-Object {
        $_.ToJson() | Set-Content -Path ./MyResource.dsc.adaptedResource.json
    }
```

<a name="json-schema" />

## Add JSON schema constraints

Add JSON schema keywords that cannot be inferred from PowerShell type metadata:

```powershell
$override = New-DscPropertyOverride -Name 'Count' -JsonSchema @{
    minimum = 0
    maximum = 100
    default = 1
}

$manifest = New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1
$manifest = $manifest | Update-DscAdaptedResourceManifest -PropertyOverride $override
$manifest.ToJson() | Set-Content -Path ./MyResource.dsc.adaptedResource.json
```

<a name="readonly" />

## Generate read-only properties

Mark a property with `[DscProperty(NotConfigurable)]` in the class-based DSC
resource:

```powershell
[DscProperty(NotConfigurable)]
[string] $Status
```

`DscResource.Authoring` emits the property as read-only in the embedded JSON
schema:

```json
{
  "Status": {
    "type": "string",
    "title": "Status",
    "readOnly": true,
    "description": "The current status returned by the resource."
  }
}
```

<a name="publish" />

## Publish manifests with a module

Place adapted resource manifest files in the module that you publish to
PowerShell Gallery. The PowerShell discovery extension searches paths from
`$env:PSModulePath` for DSC manifest files. When the module is installed, DSC
can discover those manifests from the installed module path.

Example module layout:

```text
ExampleModule/
    ExampleModule.psd1
    ExampleModule.psm1
    ExampleModule.ExampleResource.dsc.adaptedResource.json
```

After installation, DSC can use the manifest metadata for schema lookup:

```powershell
dsc resource schema --resource ExampleModule/ExampleResource
```
