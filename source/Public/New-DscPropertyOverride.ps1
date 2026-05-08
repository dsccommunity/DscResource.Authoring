<#
    .SYNOPSIS
        Creates a DscPropertyOverride object for use with Update-DscAdaptedResourceManifest.

    .DESCRIPTION
        Constructs a DscPropertyOverride object that specifies how to modify a single property
        in the embedded JSON schema of an adapted resource manifest.

    .PARAMETER Name
        The name of the property in the embedded JSON schema to override.

    .PARAMETER Description
        Override the property description text.

    .PARAMETER Title
        Override the property title text.

    .PARAMETER JsonSchema
        A hashtable of JSON schema keywords to merge into the property definition
        (e.g., anyOf, oneOf, default, minimum, maximum, pattern, format).

    .PARAMETER RemoveKeys
        An array of JSON schema key names to remove from the property before merging
        JsonSchema (e.g., 'type', 'enum' when replacing with anyOf).

    .PARAMETER Required
        Set to $true to add the property to the required list, $false to remove it,
        or omit to leave unchanged.

    .EXAMPLE
        New-DscPropertyOverride -Name 'Enabled' -Description 'Whether this resource is active.'

        Creates an override that sets a custom description for the Enabled property.

    .EXAMPLE
        New-DscPropertyOverride -Name 'Status' -RemoveKeys 'type','enum' -JsonSchema @{
            anyOf = @(
                @{ type = 'string'; enum = @('Active', 'Inactive') }
                @{ type = 'integer'; minimum = 0 }
            )
        }

        Creates an override that replaces the type/enum with an anyOf schema.

    .EXAMPLE
        $overrides = @(
            New-DscPropertyOverride -Name 'Name' -Description 'The unique identifier.'
            New-DscPropertyOverride -Name 'Count' -JsonSchema @{ minimum = 0; maximum = 100 }
        )
        $manifest | Update-DscAdaptedResourceManifest -PropertyOverride $overrides

        Creates multiple overrides and pipes them to Update-DscAdaptedResourceManifest.

    .OUTPUTS
        Returns a DscPropertyOverride object.
#>
function New-DscPropertyOverride
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([DscPropertyOverride])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [string]
        $Title,

        [Parameter()]
        [hashtable]
        $JsonSchema,

        [Parameter()]
        [string[]]
        $RemoveKeys,

        [Parameter()]
        [nullable[bool]]
        $Required
    )

    $override = [DscPropertyOverride]::new()
    $override.Name = $Name

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        $override.Description = $Description
    }

    if ($PSBoundParameters.ContainsKey('Title'))
    {
        $override.Title = $Title
    }

    if ($PSBoundParameters.ContainsKey('JsonSchema'))
    {
        $override.JsonSchema = $JsonSchema
    }

    if ($PSBoundParameters.ContainsKey('RemoveKeys'))
    {
        $override.RemoveKeys = $RemoveKeys
    }

    if ($PSBoundParameters.ContainsKey('Required'))
    {
        $override.Required = $Required
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Overwrite property in adapted resource manifest'))
    {
        Write-Output $override
    }
}
