<#
    .SYNOPSIS
        Build task for creating Microsoft DSC adapted resource manifests
        from a built PowerShell module using the DscResource.Authoring module.

    .DESCRIPTION
        Provides two Invoke-Build tasks that use the DscResource.Authoring module
        to generate Microsoft DSC adapted resource manifests from class-based DSC resources
        found in the built module:

        - Create_DscAdaptedResourceManifests: Creates one
          `.dsc.adaptedResource.json` file per class-based DSC resource found in
          the built module and writes them alongside the module manifest.

        - Create_DscResourceManifestsList: Creates a single
          `.dsc.manifests.json` bundle file that contains every adapted resource
          manifest and writes it alongside the module manifest.

        Both tasks target the module manifest produced by the ModuleBuilder build
        step and therefore must run after the module has been built
        (i.e., after `Build_Module_ModuleBuilder`).

        Configuration for both tasks is read from the `DscResource.Authoring`
        section of the build configuration file (e.g., `build.yaml`).

    .PARAMETER ProjectName
        The name of the project being built.

    .PARAMETER SourcePath
        The path to the source directory of the module.

    .PARAMETER OutputDirectory
        The base directory for all build output. Defaults to 'output' relative
        to the build root.

    .PARAMETER BuiltModuleSubdirectory
        The sub-directory under OutputDirectory where the built module is placed.

    .PARAMETER VersionedOutputDirectory
        Whether the built module is placed in a versioned sub-directory.
        Defaults to $true.

    .PARAMETER ModuleVersion
        The version of the module being built.

    .PARAMETER BuildInfo
        The build configuration hashtable, typically populated from `build.yaml`.

    .NOTES
        This task file is intended to be placed in the Sampler module's tasks
        directory so that it is exported as an alias and loaded via the
        `ModuleBuildTasks` mechanism in `build.yaml`.

        The DscResource.Authoring module must be available to the build
        environment before these tasks run. Add it to `RequiredModules.psd1`
        to ensure it is resolved as a build dependency.
#>

param
(
    [Parameter()]
    [System.String]
    $ProjectName = (property ProjectName ''),

    [Parameter()]
    [System.String]
    $SourcePath = (property SourcePath ''),

    [Parameter()]
    [System.String]
    $OutputDirectory = (property OutputDirectory (Join-Path $BuildRoot 'output')),

    [Parameter()]
    [System.String]
    $BuiltModuleSubdirectory = (property BuiltModuleSubdirectory ''),

    [Parameter()]
    [System.Management.Automation.SwitchParameter]
    $VersionedOutputDirectory = (property VersionedOutputDirectory $true),

    [Parameter()]
    [System.String]
    $ModuleVersion = (property ModuleVersion ''),

    [Parameter()]
    [System.Collections.Hashtable]
    $BuildInfo = (property BuildInfo @{ })
)

<#
    Synopsis: Creates individual Microsoft DSC adapted resource manifest files
    (.dsc.adaptedResource.json) for every class-based DSC resource found in
    the built module.

    One file is created per resource class and written to the root of the
    built module directory alongside the module manifest (.psd1). The file
    name follows the pattern `<ModuleName>.<ResourceName>.dsc.adaptedResource.json`.

    Use this task if you want to leverage Microsoft's DSC engine with the PowerShell
    discovery extension.
#>
task Create_DscAdaptedResourceManifests {
    # Get the task variables. See https://github.com/gaelcolas/Sampler#task-variables.
    . Set-SamplerTaskVariable

    "`tBuilt Module Manifest  = '$BuiltModuleManifest'"
    "`tBuilt Module Base      = '$BuiltModuleBase'"

    if ([System.String]::IsNullOrEmpty($BuiltModuleManifest) -or -not (Test-Path -Path $BuiltModuleManifest))
    {
        throw "The built module manifest '$BuiltModuleManifest' could not be found. Make sure the module has been built before running this task."
    }

    $taskConfig = @{}

    if ($BuildInfo.ContainsKey('DscResource.Authoring') -and
        $BuildInfo['DscResource.Authoring'].ContainsKey('Create_DscAdaptedResourceManifests'))
    {
        $taskConfig = $BuildInfo['DscResource.Authoring']['Create_DscAdaptedResourceManifests']
    }

    if ($null -eq $taskConfig)
    {
        $taskConfig = @{}
    }

    "`tTask Configuration     = $(if ($taskConfig.Count -gt 0) { $taskConfig | ConvertTo-Json -Depth 5 } else { '(none)' })"

    $fileNamePattern = '{ProjectName}.{ResourceName}.dsc.adaptedResource.json'

    if ($taskConfig.ContainsKey('FileNamePattern') -and -not [System.String]::IsNullOrEmpty($taskConfig['FileNamePattern']))
    {
        $fileNamePattern = $taskConfig['FileNamePattern']
    }

    "`tFile Name Pattern       = '$fileNamePattern'"

    $propertyOverridesConfig = @{}

    if ($taskConfig.ContainsKey('PropertyOverrides') -and $null -ne $taskConfig['PropertyOverrides'])
    {
        $propertyOverridesConfig = $taskConfig['PropertyOverrides']
    }

    Write-Build -Color 'DarkGray' -Text "`tGenerating adapted resource manifests from '$BuiltModuleManifest'..."

    $adaptedManifests = New-DscAdaptedResourceManifest -Path $BuiltModuleManifest

    if (-not $adaptedManifests)
    {
        Write-Build -Color 'Yellow' -Text "`tNo class-based DSC resources found in '$BuiltModuleManifest'. No manifest files were created."

        return
    }

    foreach ($manifest in $adaptedManifests)
    {
        $resourceName = ($manifest.Type -split '/')[-1]

        if ($propertyOverridesConfig.ContainsKey($resourceName))
        {
            Write-Build -Color 'DarkGray' -Text "`tApplying property overrides for '$resourceName'..."

            $overrideList = ConvertTo-DscPropertyOverrideFromConfig -OverrideConfig @($propertyOverridesConfig[$resourceName])
            $manifest = $manifest | Update-DscAdaptedResourceManifest -PropertyOverride $overrideList
        }

        $outputFileName = $fileNamePattern -replace '\{ProjectName\}', $ProjectName -replace '\{ResourceName\}', $resourceName
        $outputFilePath = Join-Path -Path $BuiltModuleBase -ChildPath $outputFileName

        Write-Build -Color 'DarkGray' -Text "`tWriting '$outputFilePath'..."

        $manifest.ToJson() | Set-Content -Path $outputFilePath -Encoding 'UTF8' -Force

        Write-Build -Color 'Green' -Text "`tCreated adapted resource manifest '$outputFileName'."
    }

    Write-Build -Color 'Green' -Text "`tCreated $(@($adaptedManifests).Count) adapted resource manifest file(s) in '$BuiltModuleBase'."
}