<#
    .SYNOPSIS
        Finds class-based DSC resource type definitions in a PowerShell file.

    .DESCRIPTION
        Parses the AST of a PowerShell file and returns the type definitions that
        are decorated with the [DscResource()] attribute, along with all type
        definitions discovered in the file (used for resolving base types and enums).

    .PARAMETER Path
        The full path to a .ps1 or .psm1 file to parse.

    .EXAMPLE
        $dscTypes = Get-DscResourceTypeDefinition -Path './MyModule/MyModule.psm1'

        Returns a list of hashtables, each containing the TypeDefinitionAst and
        AllTypeDefinitions for a class decorated with [DscResource()].
#>
function Get-DscResourceTypeDefinition
{
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[hashtable]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    [System.Management.Automation.Language.Token[]] $tokens = $null
    [System.Management.Automation.Language.ParseError[]] $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)

    foreach ($e in $errors)
    {
        Write-Error "Parse error in '$Path': $($e.Message)"
    }

    $allTypeDefinitions = $ast.FindAll(
        {
            $typeAst = $args[0] -as [System.Management.Automation.Language.TypeDefinitionAst]
            return $null -ne $typeAst
        },
        $false
    )

    $results = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($typeDefinition in $allTypeDefinitions)
    {
        foreach ($attribute in $typeDefinition.Attributes)
        {
            if ($attribute.TypeName.Name -eq 'DscResource')
            {
                $results.Add(@{
                        TypeDefinitionAst  = $typeDefinition
                        AllTypeDefinitions = $allTypeDefinitions
                    })
                break
            }
        }
    }

    return $results
}
