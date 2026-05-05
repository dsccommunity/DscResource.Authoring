<#
    .SYNOPSIS
        Returns the DSCv3 capabilities for a class-based DSC resource.

    .DESCRIPTION
        Inspects the member AST of a class-based DSC resource type definition and
        returns the DSCv3 capability strings (such as 'get', 'set', 'test',
        'whatIf', 'setHandlesExist', 'delete', 'export') corresponding to the
        methods implemented on the class.

    .PARAMETER MemberAst
        The collection of member AST nodes from the class type definition.

    .EXAMPLE
        $capabilities = Get-DscResourceCapability -MemberAst $typeDefinitionAst.Members

        Returns strings such as 'get', 'set' and 'test' for each DSCv3 method
        implemented on the class.
#>
function Get-DscResourceCapability
{
    [CmdletBinding()]
    [OutputType([string[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.MemberAst[]]
        $MemberAst
    )

    $capabilities = [System.Collections.Generic.List[string]]::new()
    $availableMethods = @('get', 'set', 'setHandlesExist', 'whatIf', 'test', 'delete', 'export')
    $methods = $MemberAst | Where-Object {
        $_ -is [System.Management.Automation.Language.FunctionMemberAst] -and $_.Name -in $availableMethods
    }

    foreach ($method in $methods.Name)
    {
        switch ($method)
        {
            'Get' { $capabilities.Add('get') }
            'Set' { $capabilities.Add('set') }
            'Test' { $capabilities.Add('test') }
            'WhatIf' { $capabilities.Add('whatIf') }
            'SetHandlesExist' { $capabilities.Add('setHandlesExist') }
            'Delete' { $capabilities.Add('delete') }
            'Export' { $capabilities.Add('export') }
        }
    }

    return ($capabilities | Select-Object -Unique)
}
