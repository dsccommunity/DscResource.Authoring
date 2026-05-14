## Contents

1. <a href="#overview">Overview</a>
1. <a href="#single-module">Generate manifests for one module</a>
1. <a href="#all-modules">Generate manifests for multiple modules</a>
1. <a href="#override-description">Override schema descriptions</a>
1. <a href="#json-schema">Add JSON schema constraints</a>
1. <a href="#readonly">Generate read-only properties</a>
1. <a href="#validateset">Restrict property values with ValidateSet</a>
1. <a href="#validatepattern">Validate property format with ValidatePattern</a>
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

<a name="validateset" />

## Restrict property values with ValidateSet

Decorate a `[string]` property with `[ValidateSet()]` to restrict the values
a caller may supply. `DscResource.Authoring` reads the allowed values from the
AST and emits them as a JSON Schema `enum` array, so DSC and schema-aware
editors enforce the constraint before the resource runs.

```powershell
[DscResource()]
class MyResource
{
    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [ValidateSet('Present', 'Absent')]
    [string] $Ensure

    [DscProperty()]
    [ValidateSet('Low', 'Medium', 'High')]
    [string] $Priority

    # ...
}
```

The generated schema fragment for those two properties:

```json
{
  "Ensure": {
    "type": "string",
    "enum": ["Present", "Absent"],
    "title": "Ensure"
  },
  "Priority": {
    "type": "string",
    "enum": ["Low", "Medium", "High"],
    "title": "Priority"
  }
}
```

A PowerShell `enum` type defined in the same file is handled identically —
you do not need `[ValidateSet()]` when an `enum` type is already used.

<a name="validatepattern" />

## Validate property format with ValidatePattern

Decorate a `[string]` property with `[ValidatePattern()]` to constrain its
format. `DscResource.Authoring` emits the regex as a JSON Schema `pattern`
keyword so DSC and schema-aware tools can validate the value before invoking
the resource.

```powershell
[DscResource()]
class MyResource
{
    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [ValidatePattern('^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
    [string] $CorrelationId

    # ...
}
```

The generated schema fragment:

```json
{
  "CorrelationId": {
    "type": "string",
    "pattern": "^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$",
    "title": "CorrelationId"
  }
}
```

When a property has both `[ValidateSet()]` and `[ValidatePattern()]`, the
`enum` keyword takes precedence and `pattern` is not emitted.

### .NET-specific regex constructs

JSON Schema validators use the ECMA 262 regex dialect. If a pattern contains
.NET-only constructs such as `\A`/`\Z` anchors, atomic groups `(?>...)`,
inline comments `(?#...)`, or inline option flags `(?i)`, `DscResource.Authoring`
skips the `pattern` keyword and writes a warning:

```
WARNING: Property 'Value': ValidatePattern value contains .NET-specific regex
constructs that are not ECMA 262 compatible and will not be emitted.
Use -AllowNonEcmaPattern to override.
```

To emit the pattern anyway, pass `-AllowNonEcmaPattern`:

```powershell
New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1 -AllowNonEcmaPattern
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
