<#
    .SYNOPSIS
        Creates adapted resource manifest objects from class-based PowerShell DSC resources.

    .DESCRIPTION
        Parses the AST of a PowerShell file (.ps1, .psm1, or .psd1) to find class-based DSC
        resources decorated with the [DscResource()] attribute. For each resource found, it
        returns a DscAdaptedResourceManifest object that complies with the DSCv3 adapted
        resource manifest JSON schema.

        The returned objects can be serialized to JSON using the .ToJson() method and written
        to `.dsc.adaptedResource.json` files. These manifests enable DSCv3 to discover and
        use PowerShell DSC resources without running Invoke-DscCacheRefresh.

    .PARAMETER Path
        The path to a .ps1, .psm1, or .psd1 file containing class-based DSC resources.
        When a .psd1 is provided, the RootModule is resolved and parsed automatically.
        If no .psd1 is available (e.g. a standalone .ps1 or .psm1 without a sibling manifest),
        the version defaults to '0.0.1'. Use the Version parameter to supply the correct version
        in that case.

    .PARAMETER Version
        Overrides the version resolved from the module manifest. Must be a valid semantic version
        string (e.g. '1.2.3' or '1.2.3-preview'). When omitted, the version from the .psd1
        ModuleVersion field is used, or '0.0.1' for files without a co-located manifest.

    .EXAMPLE
        New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1

        Returns adapted resource manifest objects for all class-based DSC resources in the module.

    .EXAMPLE
        New-DscAdaptedResourceManifest -Path ./MyResource.ps1 | ForEach-Object {
            $_.ToJson() | Set-Content "$($_.Type -replace '/', '.').dsc.adaptedResource.json"
        }

        Generates manifest objects and writes each to a JSON file.

    .EXAMPLE
        Get-ChildItem -Path ./MyModules -Filter *.psd1 -Recurse | New-DscAdaptedResourceManifest

        Discovers all module manifests under `./MyModules` and pipes them into the function
        to generate adapted resource manifests for every class-based DSC resource found.

    .OUTPUTS
        Returns a DscAdaptedResourceManifest object for each class-based DSC resource found.
        The object has a .ToJson() method for serialization to the adapted resource manifest
        JSON format.

    .PARAMETER AllowNonEcmaPattern
        When specified, `[ValidatePattern()]` regex values that contain .NET-specific constructs
        incompatible with ECMA 262 (e.g. `\A`, `\Z`, atomic groups, inline flags) are still
        written into the JSON Schema `pattern` keyword. By default such patterns are skipped
        and a warning is written instead.
#>
function New-DscAdaptedResourceManifest
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([DscAdaptedResourceManifest])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [ValidateScript({
                if (-not (Test-Path -LiteralPath $_))
                {
                    throw "Path '$_' does not exist."
                }
                $ext = [System.IO.Path]::GetExtension($_)
                if ($ext -notin '.ps1', '.psm1', '.psd1')
                {
                    throw "Path '$_' must be a .ps1, .psm1, or .psd1 file."
                }
                return $true
            })]
        [string]
        $Path,

        # Semantic version string for PS7: SemanticVersion Class
        [Parameter()]
        [ValidateScript({
                if ($_ -notmatch '^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$')
                {
                    throw "Version '$_' is not a valid semantic version (e.g. '1.2.3' or '1.2.3-preview')."
                }
                return $true
            })]
        [string]
        $Version,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $AllowNonEcmaPattern
    )

    process
    {
        $moduleInfo = Resolve-ModuleInfo -Path $Path

        if (-not (Test-Path -LiteralPath $moduleInfo.ScriptPath))
        {
            Write-Error "Cannot find script file '$($moduleInfo.ScriptPath)' to parse."
            return
        }

        $dscTypes = Get-DscResourceTypeDefinition -Path $moduleInfo.ScriptPath

        if ($dscTypes.Count -eq 0)
        {
            Write-Warning "No class-based DSC resources found in '$Path'."
            return
        }

        $classHelpMap = Get-ClassCommentBasedHelp -Path $moduleInfo.ScriptPath

        foreach ($entry in $dscTypes)
        {
            $typeDefinitionAst = $entry.TypeDefinitionAst
            $allTypeDefinitions = $entry.AllTypeDefinitions
            $resourceName = $typeDefinitionAst.Name
            $resourceType = "$($moduleInfo.ModuleName)/$resourceName"

            Write-Verbose "Processing DSC resource '$resourceType'"

            $capabilities = Get-DscResourceCapability -MemberAst $typeDefinitionAst.Members
            $properties = Get-DscResourceProperty -AllTypeDefinitions $allTypeDefinitions -TypeDefinitionAst $typeDefinitionAst

            $classHelp = $null
            $resourceDescription = $moduleInfo.Description

            if ($classHelpMap.ContainsKey($resourceName))
            {
                $classHelp = $classHelpMap[$resourceName]

                if (-not [string]::IsNullOrWhiteSpace($classHelp.Synopsis))
                {
                    $resourceDescription = $classHelp.Synopsis
                }
                elseif (-not [string]::IsNullOrWhiteSpace($classHelp.Description))
                {
                    $resourceDescription = $classHelp.Description
                }

                $missingParams = @()
                foreach ($prop in $properties)
                {
                    if (-not $classHelp.Parameters.ContainsKey($prop.Name))
                    {
                        $missingParams += $prop.Name
                    }
                }

                if ($missingParams.Count -gt 0)
                {
                    Write-Warning "Class '$resourceName' comment-based help is missing .PARAMETER documentation for: $($missingParams -join ', ')"
                }
            }
            else
            {
                Write-Warning "No comment-based help found above class '$resourceName'. Using default descriptions."
            }

            $newEmbeddedJsonSchemaParameters = @{
                ResourceName        = $resourceType
                Properties          = $properties
                Description         = $resourceDescription
                ClassHelp           = $classHelp
                AllowNonEcmaPattern = $AllowNonEcmaPattern
            }

            $embeddedSchema = New-EmbeddedJsonSchema @newEmbeddedJsonSchemaParameters

            $manifest = [DscAdaptedResourceManifest]::new()
            $manifest.Schema = $script:AdaptedResourceSchemaUri
            $manifest.Type = $resourceType
            $manifest.Kind = 'resource'
            $manifest.Version = if ($PSBoundParameters.ContainsKey('Version')) { $Version } else { $moduleInfo.Version }
            $manifest.Capabilities = @($capabilities)
            $manifest.Description = $resourceDescription
            $manifest.Author = $moduleInfo.Author
            $manifest.RequireAdapter = $script:DefaultAdapter
            $manifest.Path = $moduleInfo.Psd1Path
            $manifest.ManifestSchema = [DscAdaptedResourceManifestSchema]@{
                Embedded = $embeddedSchema
            }

            if ($PSCmdlet.ShouldProcess($resourceType, 'Create adapted resource manifest'))
            {
                Write-Output $manifest
            }
        }
    }
}
