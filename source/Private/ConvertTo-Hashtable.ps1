<#
    .SYNOPSIS
        Recursively converts PSCustomObject and array structures to hashtables.

    .DESCRIPTION
        Walks the supplied object and converts every PSCustomObject into an
        ordered hashtable, every IDictionary into an ordered hashtable, and
        every IList into an array, recursing into the values. Scalar values
        are returned unchanged. Useful for normalizing the output of
        ConvertFrom-Json before consuming it as hashtables.

    .PARAMETER InputObject
        The object to convert.
#>
function ConvertTo-Hashtable
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [object]
        $InputObject
    )

    if ($InputObject -is [System.Collections.IDictionary])
    {
        $result = [ordered]@{}
        foreach ($key in $InputObject.Keys)
        {
            $result[$key] = ConvertTo-Hashtable -InputObject $InputObject[$key]
        }
        return $result
    }

    if ($InputObject -is [PSCustomObject])
    {
        $result = [ordered]@{}
        foreach ($property in $InputObject.PSObject.Properties)
        {
            $result[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
        }
        return $result
    }

    if ($InputObject -is [System.Collections.IList])
    {
        $items = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $InputObject)
        {
            $items.Add((ConvertTo-Hashtable -InputObject $item))
        }
        return @($items)
    }

    return $InputObject
}
