<#
    .SYNOPSIS
        Hydrates a hashtable into a DscAdaptedResourceManifest object.

    .DESCRIPTION
        Maps the keys of an adapted resource manifest hashtable (such as the
        output of ConvertFrom-Json followed by ConvertTo-Hashtable) onto the
        properties of a new DscAdaptedResourceManifest instance, including the
        nested embedded JSON schema.

    .PARAMETER Hashtable
        The hashtable representation of an adapted resource manifest document.
#>
function ConvertTo-AdaptedResourceManifest
{
    [CmdletBinding()]
    [OutputType([DscAdaptedResourceManifest])]
    param
    (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Hashtable
    )

    $manifest = [DscAdaptedResourceManifest]::new()
    $manifest.Schema = $Hashtable['$schema']
    $manifest.Type = $Hashtable['type']
    $manifest.Kind = if ($Hashtable.Contains('kind')) { $Hashtable['kind'] } else { 'resource' }
    $manifest.Version = $Hashtable['version']
    $manifest.Capabilities = if ($Hashtable.Contains('capabilities') -and $null -ne $Hashtable['capabilities']) { @($Hashtable['capabilities']) } else { [string[]]::new(0) }
    $manifest.Description = if ($Hashtable.Contains('description')) { [string]$Hashtable['description'] } else { '' }
    $manifest.Author = if ($Hashtable.Contains('author')) { [string]$Hashtable['author'] } else { '' }
    $manifest.RequireAdapter = $Hashtable['requireAdapter']
    $manifest.Path = if ($Hashtable.Contains('path')) { [string]$Hashtable['path'] } else { '' }

    $schemaData = $Hashtable['schema']
    if ($schemaData)
    {
        $embeddedSchema = if ($schemaData.Contains('embedded')) { $schemaData['embedded'] } else { $schemaData }
        $manifest.ManifestSchema = [DscAdaptedResourceManifestSchema]@{
            Embedded = $embeddedSchema
        }
    }

    return $manifest
}
