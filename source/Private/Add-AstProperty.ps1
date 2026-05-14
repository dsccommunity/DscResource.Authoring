<#
    .SYNOPSIS
        Recursively collects DSC properties from a class type definition AST.

    .DESCRIPTION
        Walks the base type chain of the supplied type definition AST and adds a
        hashtable describing each property decorated with the [DscProperty()]
        attribute to the supplied list. Properties from base classes are added
        first so that derived class properties override them when the list is
        consumed.

    .PARAMETER AllTypeDefinitions
        All type definition AST nodes discovered in the script. Used to resolve
        base class types and enum types defined in the same file.

    .PARAMETER TypeAst
        The type definition AST to collect properties from.

    .PARAMETER Properties
        The list to which property hashtables are added. Each hashtable contains
        the property Name, TypeName, IsKey, IsMandatory, IsNotConfigurable and EnumValues.

    .EXAMPLE
        $properties = [System.Collections.Generic.List[hashtable]]::new()
        Add-AstProperty -AllTypeDefinitions $allTypes -TypeAst $typeAst -Properties $properties

        Collects all [DscProperty()] decorated properties from $typeAst into $properties.
#>
function Add-AstProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.TypeDefinitionAst[]]
        $AllTypeDefinitions,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.TypeDefinitionAst]
        $TypeAst,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[hashtable]]
        $Properties
    )

    foreach ($typeConstraint in $TypeAst.BaseTypes)
    {
        $baseType = $AllTypeDefinitions | Where-Object { $_.Name -eq $typeConstraint.TypeName.Name }
        if ($baseType)
        {
            Add-AstProperty -AllTypeDefinitions $AllTypeDefinitions -TypeAst $baseType -Properties $Properties
        }
    }

    foreach ($member in $TypeAst.Members)
    {
        $propertyAst = $member -as [System.Management.Automation.Language.PropertyMemberAst]
        if (($null -eq $propertyAst) -or ($propertyAst.IsStatic))
        {
            continue
        }

        $isDscProperty = $false
        $isKey = $false
        $isMandatory = $false
        $isNotConfigurable = $false
        $validateSetValues = $null
        $validatePatternValue = $null
        foreach ($attr in $propertyAst.Attributes)
        {
            if ($attr.TypeName.Name -eq 'DscProperty')
            {
                $isDscProperty = $true
                foreach ($namedArg in $attr.NamedArguments)
                {
                    switch ($namedArg.ArgumentName)
                    {
                        'Key' { $isKey = $true }
                        'Mandatory' { $isMandatory = $true }
                        'NotConfigurable' { $isNotConfigurable = $true }
                    }
                }
            }

            if ($attr.TypeName.Name -eq 'ValidateSet')
            {
                $validateSetValues = @($attr.PositionalArguments | ForEach-Object { $_.Value })
            }

            if ($attr.TypeName.Name -eq 'ValidatePattern')
            {
                $validatePatternValue = $attr.PositionalArguments[0].Value
            }
        }

        if (-not $isDscProperty)
        {
            continue
        }

        $typeName = if ($propertyAst.PropertyType)
        {
            $propertyAst.PropertyType.TypeName.Name
        }
        else
        {
            'string'
        }

        # check if the type is an enum defined in the same file
        $enumValues = $null
        $enumAst = $AllTypeDefinitions | Where-Object {
            $_.Name -eq $typeName -and $_.IsEnum
        }
        if ($enumAst)
        {
            $enumValues = @($enumAst.Members | ForEach-Object { $_.Name })
        }
        elseif ($validateSetValues)
        {
            $enumValues = $validateSetValues
        }

        $Properties.Add(@{
                Name              = $propertyAst.Name
                TypeName          = $typeName
                IsKey             = $isKey
                IsMandatory       = $isMandatory -or $isKey
                IsNotConfigurable = $isNotConfigurable
                EnumValues        = $enumValues
                PatternValue      = $validatePatternValue
            })
    }
}
