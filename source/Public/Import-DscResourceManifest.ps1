<#
    .SYNOPSIS
        Imports a DSC resource manifest list from a `.dsc.manifests.json` file.

    .DESCRIPTION
        Reads a `.dsc.manifests.json` file and returns a DscResourceManifestList object
        containing the adapted resources, command-based resources, and extensions defined
        in the file. This is the inverse of serializing a manifest list with `.ToJson()`.

        The adapted resources in the returned list are hydrated into DscAdaptedResourceManifest
        objects and stored via AddAdaptedResource. Resources and extensions are stored as
        hashtables.

    .PARAMETER Path
        The path to a `.dsc.manifests.json` file. Accepts pipeline input.

    .EXAMPLE
        Import-DscResourceManifest -Path ./MyModule.dsc.manifests.json

        Imports a manifest list file and returns a DscResourceManifestList object.

    .EXAMPLE
        Get-ChildItem -Filter *.dsc.manifests.json | Import-DscResourceManifest

        Imports all manifest list files in the current directory.

    .EXAMPLE
        $list = Import-DscResourceManifest -Path ./existing.dsc.manifests.json
        $list.AdaptedResources.Count

        Imports a manifest list and inspects the number of adapted resources.

    .OUTPUTS
        Returns a DscResourceManifestList object with .ToJson() for serialization.
#>
function Import-DscResourceManifest
{
    [CmdletBinding()]
    [OutputType([DscResourceManifestList])]
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
        Write-Verbose "Importing resource manifest list from '$resolvedPath'"

        $jsonContent = Get-Content -LiteralPath $resolvedPath -Raw
        $parsed = ConvertFrom-Json -InputObject $jsonContent
        $hashtable = ConvertTo-Hashtable -InputObject $parsed

        $manifestList = [DscResourceManifestList]::new()

        if ($hashtable.Contains('adaptedResources'))
        {
            foreach ($ar in $hashtable['adaptedResources'])
            {
                $manifest = ConvertTo-AdaptedResourceManifest -Hashtable $ar
                $manifestList.AddAdaptedResource($manifest)
            }
        }

        if ($hashtable.Contains('resources'))
        {
            foreach ($res in $hashtable['resources'])
            {
                $manifestList.AddResource($res)
            }
        }

        if ($hashtable.Contains('extensions'))
        {
            foreach ($ext in $hashtable['extensions'])
            {
                $manifestList.AddExtension($ext)
            }
        }

        Write-Output $manifestList
    }
}
