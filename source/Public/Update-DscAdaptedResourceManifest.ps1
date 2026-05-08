<#
    .SYNOPSIS
        Applies post-processing overrides to adapted resource manifest objects.

    .DESCRIPTION
        Modifies the embedded JSON schema of a DscAdaptedResourceManifest object by applying
        property-level overrides. This enables customization that AST extraction alone cannot
        provide, such as meaningful property descriptions, JSON schema keywords like anyOf or
        oneOf for complex type unions, default values, numeric ranges, and string patterns.

        Property overrides are specified via DscPropertyOverride objects that target individual
        properties by name. Each override can change the description, title, required status,
        remove existing JSON schema keys, and merge in new JSON schema keywords.

    .PARAMETER InputObject
        A DscAdaptedResourceManifest object to update. Typically produced by
        New-DscAdaptedResourceManifest. Accepts pipeline input.

    .PARAMETER PropertyOverride
        One or more DscPropertyOverride objects specifying modifications to individual
        properties in the embedded JSON schema. Each override targets a property by Name.

        DscPropertyOverride supports the following fields:
        - Name:        (Required) The property name to modify.
        - Description: Override the property description.
        - Title:       Override the property title.
        - JsonSchema:  A hashtable of JSON schema keywords to merge into the property
                       (e.g., anyOf, oneOf, default, minimum, maximum, pattern, format).
        - RemoveKeys:  An array of JSON schema key names to remove before merging
                       (e.g., 'type', 'enum' when replacing with anyOf).
        - Required:    Set to $true to mark as required, $false to remove from required,
                       or leave $null to keep unchanged.

    .PARAMETER Description
        Override the resource-level description on both the manifest object and the embedded
        JSON schema.

    .EXAMPLE
        New-DscAdaptedResourceManifest -Path ./MyModule/MyModule.psd1 |
            Update-DscAdaptedResourceManifest -PropertyOverride @(
                [DscPropertyOverride]@{
                    Name        = 'Name'
                    Description = 'The unique name identifying this resource instance.'
                }
            )

        Overrides the auto-generated description for the Name property.

    .EXAMPLE
        $overrides = @(
            [DscPropertyOverride]@{
                Name        = 'Status'
                Description = 'The desired status, as a label or numeric code.'
                RemoveKeys  = @('type', 'enum')
                JsonSchema  = @{
                    anyOf = @(
                        @{ type = 'string'; enum = @('Active', 'Inactive') }
                        @{ type = 'integer'; minimum = 0 }
                    )
                }
            }
        )
        New-DscAdaptedResourceManifest -Path ./MyModule.psd1 |
            Update-DscAdaptedResourceManifest -PropertyOverride $overrides

        Replaces a simple enum property with an anyOf schema allowing either a string
        enum or an integer value.

    .EXAMPLE
        $override = [DscPropertyOverride]@{
            Name       = 'Count'
            JsonSchema = @{ minimum = 0; maximum = 100; default = 1 }
        }
        $manifest | Update-DscAdaptedResourceManifest -PropertyOverride $override

        Adds numeric constraints and a default value to an existing integer property.

    .EXAMPLE
        $override = [DscPropertyOverride]@{
            Name     = 'Tags'
            Required = $false
        }
        $manifest | Update-DscAdaptedResourceManifest -PropertyOverride $override

        Removes a property from the required list.

    .OUTPUTS
        Returns the modified DscAdaptedResourceManifest object.
#>
function Update-DscAdaptedResourceManifest
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([DscAdaptedResourceManifest])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [DscAdaptedResourceManifest]
        $InputObject,

        [Parameter()]
        [DscPropertyOverride[]]
        $PropertyOverride,

        [Parameter()]
        [string]
        $Description
    )

    process
    {
        $schema = $InputObject.ManifestSchema.Embedded

        if (-not [string]::IsNullOrEmpty($Description))
        {
            $InputObject.Description = $Description
            if ($schema.Contains('description'))
            {
                $schema['description'] = $Description
            }
        }

        if ($PropertyOverride)
        {
            $properties = $schema['properties']
            $requiredList = [System.Collections.Generic.List[string]]::new()
            if ($schema.Contains('required') -and $null -ne $schema['required'])
            {
                foreach ($r in $schema['required'])
                {
                    $requiredList.Add($r)
                }
            }

            foreach ($override in $PropertyOverride)
            {
                if (-not $properties.Contains($override.Name))
                {
                    Write-Warning "Property '$($override.Name)' not found in schema for '$($InputObject.Type)'. Skipping."
                    continue
                }

                $prop = $properties[$override.Name]

                # Remove specified keys first
                if ($override.RemoveKeys)
                {
                    foreach ($key in $override.RemoveKeys)
                    {
                        if ($prop.Contains($key))
                        {
                            $prop.Remove($key)
                        }
                    }
                }

                # Apply description override
                if (-not [string]::IsNullOrEmpty($override.Description))
                {
                    $prop['description'] = $override.Description
                }

                # Apply title override
                if (-not [string]::IsNullOrEmpty($override.Title))
                {
                    $prop['title'] = $override.Title
                }

                # Merge JSON schema keywords
                if ($override.JsonSchema -and $override.JsonSchema.Count -gt 0)
                {
                    foreach ($key in $override.JsonSchema.Keys)
                    {
                        $prop[$key] = $override.JsonSchema[$key]
                    }
                }

                # Handle required override
                if ($null -ne $override.Required)
                {
                    if ([bool]$override.Required -and $override.Name -notin $requiredList)
                    {
                        $requiredList.Add($override.Name)
                    }
                    elseif (-not [bool]$override.Required)
                    {
                        $requiredList.Remove($override.Name) | Out-Null
                    }
                }
            }

            $schema['required'] = @($requiredList)
        }

        Write-Output $InputObject
    }
}
