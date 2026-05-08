<#
    .SYNOPSIS
        Creates a DSC resource manifests list for bundling multiple resources in a single file.

    .DESCRIPTION
        Builds a DscResourceManifestList object that can contain both adapted resources and
        command-based resources. The resulting object can be serialized to JSON and written
        to a `.dsc.manifests.json` file, which DSCv3 discovers and loads as a bundle.

        Adapted resources can be added by piping DscAdaptedResourceManifest objects from
        New-DscAdaptedResourceManifest. Command-based resources can be added via the
        -Resource parameter as hashtables matching the DSCv3 resource manifest schema.

    .PARAMETER AdaptedResource
        One or more DscAdaptedResourceManifest objects to include in the manifests list.
        These are typically produced by New-DscAdaptedResourceManifest.

    .PARAMETER Resource
        One or more hashtables representing command-based DSC resource manifests. Each
        hashtable should conform to the DSCv3 resource manifest schema with keys such as
        `$schema`, `type`, `version`, `get`, `set`, `test`, `schema`, etc.

    .EXAMPLE
        $adapted = New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1
        New-DscResourceManifest -AdaptedResource $adapted

        Creates a manifests list from adapted resource manifests generated from a module.

    .EXAMPLE
        $resource = @{
            '$schema'  = 'https://aka.ms/dsc/schemas/v3/bundled/resource/manifest.json'
            type       = 'MyCompany/MyTool'
            version    = '1.0.0'
            get        = @{ executable = 'mytool'; args = @('get') }
            set        = @{ executable = 'mytool'; args = @('set'); implementsPretest = $false; return = 'state' }
            test       = @{ executable = 'mytool'; args = @('test'); return = 'state' }
            exitCodes  = @{ '0' = 'Success'; '1' = 'Error' }
            schema     = @{ command = @{ executable = 'mytool'; args = @('schema') } }
        }
        New-DscResourceManifest -Resource $resource

        Creates a manifests list containing a single command-based resource.

    .EXAMPLE
        New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1 |
            New-DscResourceManifest

        Pipes adapted resource manifests directly into the function via the pipeline.

    .OUTPUTS
        Returns a DscResourceManifestList object with a .ToJson() method for serialization
        to the `.dsc.manifests.json` format.
#>
function New-DscResourceManifest
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([DscResourceManifestList])]
    param
    (
        [Parameter(ValueFromPipeline = $true)]
        [DscAdaptedResourceManifest[]]
        $AdaptedResource,

        [Parameter()]
        [hashtable[]]
        $Resource
    )

    begin
    {
        $manifestList = [DscResourceManifestList]::new()

        if ($Resource)
        {
            foreach ($res in $Resource)
            {
                $manifestList.AddResource($res)
            }
        }
    }

    process
    {
        if ($AdaptedResource)
        {
            foreach ($adapted in $AdaptedResource)
            {
                $manifestList.AddAdaptedResource($adapted)
            }
        }
    }

    end
    {
        Write-Output $manifestList
    }
}
