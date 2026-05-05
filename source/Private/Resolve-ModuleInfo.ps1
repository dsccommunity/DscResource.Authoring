<#
    .SYNOPSIS
        Resolves module metadata from a .psd1, .psm1 or .ps1 file.

    .DESCRIPTION
        Returns a hashtable containing the module name, version, author,
        description and the path to the script file that should be parsed for
        DSC resources. When a .psd1 path is provided the module manifest is
        imported and the RootModule is resolved relative to the manifest's
        directory. When a .ps1 or .psm1 is provided, a sibling .psd1 is used
        when present; otherwise default values are returned.

    .PARAMETER Path
        The path to a .ps1, .psm1 or .psd1 file.

    .EXAMPLE
        $info = Resolve-ModuleInfo -Path './MyModule/MyModule.psd1'

        Returns a hashtable with ModuleName, Version, Author, Description,
        ScriptPath, Psd1Path and Directory populated from the module manifest.

    .EXAMPLE
        $info = Resolve-ModuleInfo -Path './MyResource.psm1'

        Returns a hashtable with defaults when no companion .psd1 exists.
#>
function Resolve-ModuleInfo
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    $resolvedPath = Resolve-Path -LiteralPath $Path
    $extension = [System.IO.Path]::GetExtension($resolvedPath)
    $directory = [System.IO.Path]::GetDirectoryName($resolvedPath)

    if ($extension -eq '.psd1')
    {
        $manifestData = Import-PowerShellDataFile -Path $resolvedPath
        $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedPath)
        $version = if ($manifestData.ModuleVersion) { $manifestData.ModuleVersion } else { '0.0.1' }
        $author = if ($manifestData.Author) { $manifestData.Author } else { '' }
        $description = if ($manifestData.Description) { $manifestData.Description } else { '' }

        $rootModule = $manifestData.RootModule
        if ([string]::IsNullOrEmpty($rootModule))
        {
            $rootModule = "$moduleName.psm1"
        }
        $scriptPath = Join-Path $directory $rootModule
        $psd1RelativePath = [System.IO.Path]::GetFileName($resolvedPath)

        return @{
            ModuleName  = $moduleName
            Version     = $version
            Author      = $author
            Description = $description
            ScriptPath  = $scriptPath
            Psd1Path    = $psd1RelativePath
            Directory   = $directory
        }
    }

    # derive fileName from .ps1 or .psm1
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedPath)

    # validate if .psd1 is there and use that
    $psd1Path = Join-Path $directory "$moduleName.psd1"
    if (Test-Path -LiteralPath $psd1Path)
    {
        return Resolve-ModuleInfo -Path $psd1Path
    }

    $fileName = [System.IO.Path]::GetFileName($resolvedPath)

    return @{
        ModuleName  = $moduleName
        Version     = '0.0.1'
        Author      = ''
        Description = ''
        ScriptPath  = [string]$resolvedPath
        Psd1Path    = $fileName
        Directory   = $directory
    }
}
