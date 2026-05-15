<#
    .SYNOPSIS
        Converts property override configuration entries into DscPropertyOverride objects.

    .DESCRIPTION
        Maps each hashtable entry from the build configuration PropertyOverrides section
        into a DscPropertyOverride object understood by Update-DscAdaptedResourceManifest.
        Each entry must contain at least a 'Name' key. Supported optional keys are
        'Description', 'Title', 'JsonSchema', 'RemoveKeys', and 'Required'.

        This function must only be called after DscResource.Authoring has been imported
        into the session.

    .PARAMETER OverrideConfig
        An array of hashtables, each describing one property override.

    .EXAMPLE
        $overrides = ConvertTo-DscPropertyOverrideFromConfig -OverrideConfig $configEntries

        Converts a list of configuration hashtables into DscPropertyOverride objects.
#>
function ConvertTo-DscPropertyOverrideFromConfig
{
    [CmdletBinding()]
    [OutputType([object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [object[]]
        $OverrideConfig
    )

    $overrides = [System.Collections.Generic.List[object]]::new()

    foreach ($entry in $OverrideConfig)
    {
        if (-not $entry.ContainsKey('Name') -or [string]::IsNullOrEmpty($entry['Name']))
        {
            Write-Warning 'Skipping a property override entry with a missing or empty Name key.'
            continue
        }

        $overrideParams = @{
            Name = [string] $entry['Name']
        }

        if ($entry.ContainsKey('Description') -and -not [string]::IsNullOrEmpty($entry['Description']))
        {
            $overrideParams['Description'] = [string] $entry['Description']
        }

        if ($entry.ContainsKey('Title') -and -not [string]::IsNullOrEmpty($entry['Title']))
        {
            $overrideParams['Title'] = [string] $entry['Title']
        }

        if ($entry.ContainsKey('JsonSchema') -and $null -ne $entry['JsonSchema'])
        {
            $overrideParams['JsonSchema'] = $entry['JsonSchema']
        }

        if ($entry.ContainsKey('RemoveKeys') -and $null -ne $entry['RemoveKeys'])
        {
            $overrideParams['RemoveKeys'] = @($entry['RemoveKeys'])
        }

        if ($entry.ContainsKey('Required') -and $null -ne $entry['Required'])
        {
            $overrideParams['Required'] = [bool] $entry['Required']
        }

        $overrides.Add((New-DscPropertyOverride @overrideParams))
    }

    return , $overrides.ToArray()
}