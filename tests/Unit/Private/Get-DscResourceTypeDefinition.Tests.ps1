BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-DscResourceTypeDefinition' {

    Context 'File with a single DSC resource class' {

        BeforeAll {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path (Join-Path $fixturesPath 'SimpleResource') 'SimpleResource.psm1'
                $script:result = @(Get-DscResourceTypeDefinition -Path $path)
            }
        }

        It 'Returns one entry' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Count | Should -Be 1
            }
        }

        It 'Returns a hashtable with TypeDefinitionAst key' {
            InModuleScope 'DscResource.Authoring' {
                $script:result[0].ContainsKey('TypeDefinitionAst') | Should -BeTrue
            }
        }

        It 'Identifies the correct class name' {
            InModuleScope 'DscResource.Authoring' {
                $script:result[0].TypeDefinitionAst.Name | Should -BeExactly 'SimpleResource'
            }
        }

        It 'Returns AllTypeDefinitions alongside the DSC type' {
            InModuleScope 'DscResource.Authoring' {
                $script:result[0].ContainsKey('AllTypeDefinitions') | Should -BeTrue
                $script:result[0].AllTypeDefinitions | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'File with multiple DSC resource classes' {

        It 'Returns one entry per [DscResource()] class' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path (Join-Path $fixturesPath 'MultiResource') 'MultiResource.psm1'
                $result = @(Get-DscResourceTypeDefinition -Path $path)
                $result.Count | Should -BeGreaterOrEqual 2
            }
        }
    }

    Context 'File with no DSC resource classes' {

        It 'Returns an empty list' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path $fixturesPath 'NoDscResource.psm1'
                $result = @(Get-DscResourceTypeDefinition -Path $path)
                $result.Count | Should -Be 0
            }
        }
    }

    Context 'Standalone .ps1 file' {

        It 'Returns one entry for the DSC class in the standalone file' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path $fixturesPath 'StandaloneResource.ps1'
                $result = @(Get-DscResourceTypeDefinition -Path $path)
                $result.Count | Should -Be 1
                $result[0].TypeDefinitionAst.Name | Should -BeExactly 'StandaloneResource'
            }
        }
    }
}
