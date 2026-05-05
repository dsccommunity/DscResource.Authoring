<#
    .SYNOPSIS
        Builds the embedded JSON schema for a class-based DSC resource.

    .DESCRIPTION
        Produces an ordered hashtable representing the embedded JSON Schema
        document for an adapted resource manifest. The schema describes the
        DSC resource properties and their required-ness, and uses descriptions
        from the supplied class comment-based help when available.

    .PARAMETER ResourceName
        The fully-qualified resource type name (for example 'MyModule/MyResource')
        used as the schema title.

    .PARAMETER Properties
        The list of property hashtables produced by Get-DscResourceProperty.

    .PARAMETER Description
        Optional description to embed in the schema document.

    .PARAMETER ClassHelp
        Optional hashtable produced by Get-ClassCommentBasedHelp containing
        per-parameter descriptions to use for property descriptions.
#>
function New-EmbeddedJsonSchema
{
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[hashtable]]
        $Properties,

        [Parameter()]
        [string]
        $Description,

        [Parameter()]
        [hashtable]
        $ClassHelp
    )

    $schemaProperties = [ordered]@{}
    $requiredList = [System.Collections.Generic.List[string]]::new()

    foreach ($prop in $Properties)
    {
        $schemaProp = [ordered]@{}

        if ($prop.EnumValues)
        {
            $schemaProp['type'] = 'string'
            $schemaProp['enum'] = $prop.EnumValues
        }
        else
        {
            $jsonType = ConvertTo-JsonSchemaType -TypeName $prop.TypeName
            foreach ($key in $jsonType.Keys)
            {
                $schemaProp[$key] = $jsonType[$key]
            }
        }

        $schemaProp['title'] = $prop.Name

        if ($ClassHelp -and $ClassHelp.Parameters.ContainsKey($prop.Name))
        {
            $schemaProp['description'] = $ClassHelp.Parameters[$prop.Name]
        }
        else
        {
            $schemaProp['description'] = "The $($prop.Name) property."
        }

        $schemaProperties[$prop.Name] = $schemaProp

        if ($prop.IsMandatory)
        {
            $requiredList.Add($prop.Name)
        }
    }

    $schema = [ordered]@{
        '$schema'            = $script:JsonSchemaUri
        title                = $ResourceName
        type                 = 'object'
        required             = @($requiredList)
        additionalProperties = $false
        properties           = $schemaProperties
    }

    if (-not [string]::IsNullOrEmpty($Description))
    {
        $schema['description'] = $Description
    }

    return $schema
}
