<#
    .SYNOPSIS
        Returns the DSC properties for a class-based DSC resource.

    .DESCRIPTION
        Returns a list of hashtables describing each [DscProperty()] decorated
        property on the supplied class type definition AST, including properties
        inherited from base classes defined in the same file.

    .PARAMETER AllTypeDefinitions
        All type definition AST nodes discovered in the script. Used to resolve
        base class types and enum types defined in the same file.

    .PARAMETER TypeDefinitionAst
        The type definition AST of the class to collect properties from.

    .EXAMPLE
        $properties = Get-DscResourceProperty -AllTypeDefinitions $allTypes -TypeDefinitionAst $typeAst

        Returns a list of hashtables describing every [DscProperty()] decorated
        property on the class and any base classes defined in the same file.
#>
function Get-DscResourceProperty
{
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[hashtable]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.TypeDefinitionAst[]]
        $AllTypeDefinitions,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.TypeDefinitionAst]
        $TypeDefinitionAst
    )

    $properties = [System.Collections.Generic.List[hashtable]]::new()
    Add-AstProperty -AllTypeDefinitions $AllTypeDefinitions -TypeAst $TypeDefinitionAst -Properties $properties
    return , $properties
}
