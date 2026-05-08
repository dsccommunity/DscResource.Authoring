BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force

    $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
    $script:simplePsm1 = Join-Path (Join-Path $fixturesPath 'SimpleResource') 'SimpleResource.psm1'
    $script:multiPsm1 = Join-Path (Join-Path $fixturesPath 'MultiResource') 'MultiResource.psm1'
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-DscResourceCapability' {

    Context 'Class with Get, Test and Set methods' {

        BeforeAll {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path (Join-Path $fixturesPath 'SimpleResource') 'SimpleResource.psm1'
                [System.Management.Automation.Language.Token[]] $tokens = $null
                [System.Management.Automation.Language.ParseError[]] $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
                $allTypes = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false)
                $typeAst = $allTypes | Where-Object { $_.Name -eq 'SimpleResource' }
                $script:capabilities = Get-DscResourceCapability -MemberAst $typeAst.Members
            }
        }

        It 'Returns get capability' {
            InModuleScope 'DscResource.Authoring' {
                $script:capabilities | Should -Contain 'get'
            }
        }

        It 'Returns set capability' {
            InModuleScope 'DscResource.Authoring' {
                $script:capabilities | Should -Contain 'set'
            }
        }

        It 'Returns test capability' {
            InModuleScope 'DscResource.Authoring' {
                $script:capabilities | Should -Contain 'test'
            }
        }

        It 'Does not return delete or export capabilities' {
            InModuleScope 'DscResource.Authoring' {
                $script:capabilities | Should -Not -Contain 'delete'
                $script:capabilities | Should -Not -Contain 'export'
            }
        }

        It 'Returns unique capability values only' {
            InModuleScope 'DscResource.Authoring' {
                $script:capabilities.Count | Should -Be ($script:capabilities | Select-Object -Unique).Count
            }
        }
    }
}
