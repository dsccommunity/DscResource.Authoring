## Contents

1. <a href="#overview">Overview</a>
1. <a href="#new-dscadaptedresourcemanifest">New-DscAdaptedResourceManifest</a>
1. <a href="#import-dscadaptedresourcemanifest">Import-DscAdaptedResourceManifest</a>
1. <a href="#import-dscresourcemanifest">Import-DscResourceManifest</a>
1. <a href="#new-dscpropertyoverride">New-DscPropertyOverride</a>
1. <a href="#new-dscresourcemanifest">New-DscResourceManifest</a>
1. <a href="#update-dscadaptedresourcemanifest">Update-DscAdaptedResourceManifest</a>

<a name="overview" />

## Overview

This page lists the public commands in `DscResource.Authoring`. The SYNOPSIS
text matches the command help used by the module.

| Command                             | Synopsis                                                                                 |
|-------------------------------------|------------------------------------------------------------------------------------------|
| `New-DscAdaptedResourceManifest`    | Creates adapted resource manifest objects from class-based PowerShell DSC resources.     |
| `Import-DscAdaptedResourceManifest` | Imports adapted resource manifest objects from `.dsc.adaptedResource.json` files.        |
| `Import-DscResourceManifest`        | Imports a DSC resource manifest list from a `.dsc.manifests.json` file.                  |
| `New-DscPropertyOverride`           | Creates a `DscPropertyOverride` object for use with `Update-DscAdaptedResourceManifest`. |
| `New-DscResourceManifest`           | Creates a DSC resource manifests list for bundling multiple resources in a single file.  |
| `Update-DscAdaptedResourceManifest` | Applies post-processing overrides to adapted resource manifest objects.                  |

---

<a name="new-dscadaptedresourcemanifest" />

## New-DscAdaptedResourceManifest

### SYNOPSIS

Creates adapted resource manifest objects from class-based PowerShell DSC
resources.

### SYNTAX

```powershell
New-DscAdaptedResourceManifest [-Path] <String> [<CommonParameters>]
```

### DESCRIPTION

Parses a `.ps1`, `.psm1`, or `.psd1` file to find classes marked with
`[DscResource()]`. For each resource, the command returns a
`DscAdaptedResourceManifest` object that can be serialized to JSON with
`.ToJson()`.

### EXAMPLE

```powershell
New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1
```

Creates adapted resource manifest objects for all class-based DSC resources in
the module.

---

<a name="import-dscadaptedresourcemanifest" />

## Import-DscAdaptedResourceManifest

### SYNOPSIS

Imports adapted resource manifest objects from `.dsc.adaptedResource.json`
files.

### SYNTAX

```powershell
Import-DscAdaptedResourceManifest [-Path] <String> [<CommonParameters>]
```

### DESCRIPTION

Reads one or more adapted resource manifest JSON files and returns
`DscAdaptedResourceManifest` objects. Use this command to inspect, update, or
bundle existing adapted resource manifests.

### EXAMPLE

```powershell
Get-ChildItem -Filter *.dsc.adaptedResource.json | Import-DscAdaptedResourceManifest
```

Imports all adapted resource manifest files in the current directory.

---

<a name="import-dscresourcemanifest" />

## Import-DscResourceManifest

### SYNOPSIS

Imports a DSC resource manifest list from a `.dsc.manifests.json` file.

### SYNTAX

```powershell
Import-DscResourceManifest [-Path] <String> [<CommonParameters>]
```

### DESCRIPTION

Reads a DSC resource manifest list and returns a `DscResourceManifestList`
object. The object contains adapted resources, command-based resources, and
extensions defined in the manifest list.

### EXAMPLE

```powershell
$list = Import-DscResourceManifest -Path ./MyModule.dsc.manifests.json
$list.AdaptedResources.Count
```

Imports a manifest list and inspects the number of adapted resources.

---

<a name="new-dscpropertyoverride" />

## New-DscPropertyOverride

### SYNOPSIS

Creates a `DscPropertyOverride` object for use with
`Update-DscAdaptedResourceManifest`.

### SYNTAX

```powershell
New-DscPropertyOverride [-Name] <String> [[-Description] <String>] [[-Title] <String>] [[-JsonSchema] <Hashtable>] [[-RemoveKeys] <String[]>] [[-Required] <Nullable[Boolean]>] [<CommonParameters>]
```

### DESCRIPTION

Creates an object that describes how to update a single property in an embedded
JSON schema. Use property overrides to adjust descriptions, titles, required
status, and JSON schema keywords.

### EXAMPLE

```powershell
New-DscPropertyOverride -Name 'Count' -JsonSchema @{ minimum = 0; maximum = 100 }
```

Creates an override that adds numeric constraints to the `Count` property.

---

<a name="new-dscresourcemanifest" />

## New-DscResourceManifest

### SYNOPSIS

Creates a DSC resource manifests list for bundling multiple resources in a
single file.

### SYNTAX

```powershell
New-DscResourceManifest [[-AdaptedResource] <DscAdaptedResourceManifest[]>] [[-Resource] <Hashtable[]>] [<CommonParameters>]
```

### DESCRIPTION

Builds a `DscResourceManifestList` object that can contain adapted resources and
command-based resources. Serialize the object with `.ToJson()` and save it as a
`.dsc.manifests.json` file.

### EXAMPLE

```powershell
New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1 |
    New-DscResourceManifest
```

Creates a manifest list from generated adapted resource manifests.

---

<a name="update-dscadaptedresourcemanifest" />

## Update-DscAdaptedResourceManifest

### SYNOPSIS

Applies post-processing overrides to adapted resource manifest objects.

### SYNTAX

```powershell
Update-DscAdaptedResourceManifest [-InputObject] <DscAdaptedResourceManifest> [[-PropertyOverride] <DscPropertyOverride[]>] [[-Description] <String>] [<CommonParameters>]
```

### DESCRIPTION

Updates the embedded JSON schema of a `DscAdaptedResourceManifest` object. Use
this command to refine schema descriptions, add JSON schema constraints, remove
schema keys, or update the required property list.

### EXAMPLE

```powershell
$override = New-DscPropertyOverride -Name 'Tags' -Required $false
$manifest | Update-DscAdaptedResourceManifest -PropertyOverride $override
```

Removes the `Tags` property from the schema required list.
