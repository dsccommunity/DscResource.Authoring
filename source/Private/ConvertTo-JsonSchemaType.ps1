<#
    .SYNOPSIS
        Converts a PowerShell type name to its JSON Schema type definition.

    .DESCRIPTION
        Maps a PowerShell type name (such as 'string', 'int', 'bool', 'datetime'
        or an array form like 'string[]') to a hashtable describing the
        equivalent JSON Schema type. Unknown types fall back to 'string'.

    .PARAMETER TypeName
        The PowerShell type name to convert.

    .EXAMPLE
        ConvertTo-JsonSchemaType -TypeName 'bool'

        Returns @{ type = 'boolean' }.

    .EXAMPLE
        ConvertTo-JsonSchemaType -TypeName 'string[]'

        Returns @{ type = 'array'; items = @{ type = 'string' } }.
#>
function ConvertTo-JsonSchemaType
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $TypeName
    )

    switch ($TypeName)
    {
        'string' { return @{ type = 'string' } }
        'int' { return @{ type = 'integer' } }
        'int32' { return @{ type = 'integer' } }
        'int64' { return @{ type = 'integer' } }
        'long' { return @{ type = 'integer' } }
        'double' { return @{ type = 'number' } }
        'float' { return @{ type = 'number' } }
        'single' { return @{ type = 'number' } }
        'decimal' { return @{ type = 'number' } }
        'bool' { return @{ type = 'boolean' } }
        'boolean' { return @{ type = 'boolean' } }
        'switch' { return @{ type = 'boolean' } }
        'hashtable' { return @{ type = 'object' } }
        'datetime' { return @{ type = 'string'; format = 'date-time' } }
        default
        {
            # arrays like string[] or int[]
            if ($TypeName -match '^(.+)\[\]$')
            {
                $innerType = ConvertTo-JsonSchemaType -TypeName $Matches[1]
                return @{ type = 'array'; items = $innerType }
            }
            # default to string for unknown types
            return @{ type = 'string' }
        }
    }
}
