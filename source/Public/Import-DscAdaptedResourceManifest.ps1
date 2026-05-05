<#
    .SYNOPSIS
        Imports adapted resource manifest objects from `.dsc.adaptedResource.json` files.

    .DESCRIPTION
        Reads one or more `.dsc.adaptedResource.json` files and returns DscAdaptedResourceManifest
        objects. This is the inverse of serializing a manifest with `.ToJson()` - it allows you
        to load existing adapted resource manifests for inspection, modification, or inclusion
        in a resource manifest list via New-DscResourceManifest.

    .PARAMETER Path
        The path to a `.dsc.adaptedResource.json` file. Accepts pipeline input.

    .EXAMPLE
        Import-DscAdaptedResourceManifest -Path ./MyResource.dsc.adaptedResource.json

        Imports a single adapted resource manifest and returns a DscAdaptedResourceManifest object.

    .EXAMPLE
        Get-ChildItem -Filter *.dsc.adaptedResource.json | Import-DscAdaptedResourceManifest

        Imports all adapted resource manifest files in the current directory.

    .EXAMPLE
        Import-DscAdaptedResourceManifest -Path ./MyResource.dsc.adaptedResource.json |
            New-DscResourceManifest

        Imports an adapted resource manifest and bundles it into a resource manifest list.

    .OUTPUTS
        Returns a DscAdaptedResourceManifest object for each file. The object has .ToJson()
        and .ToHashtable() methods for serialization.
#>
function Import-DscAdaptedResourceManifest
{
    [CmdletBinding()]
    [OutputType([DscAdaptedResourceManifest])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
                if (-not (Test-Path -LiteralPath $_))
                {
                    throw "Path '$_' does not exist."
                }
                return $true
            })]
        [Alias('FullName')]
        [string]
        $Path
    )

    process
    {
        $resolvedPath = Resolve-Path -LiteralPath $Path
        Write-Verbose "Importing adapted resource manifest from '$resolvedPath'"

        $jsonContent = Get-Content -LiteralPath $resolvedPath -Raw
        $parsed = ConvertFrom-Json -InputObject $jsonContent
        $hashtable = ConvertTo-Hashtable -InputObject $parsed

        $manifest = ConvertTo-AdaptedResourceManifest -Hashtable $hashtable
        Write-Output $manifest
    }
}
