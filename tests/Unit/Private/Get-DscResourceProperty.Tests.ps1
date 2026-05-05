BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-DscResourceProperty' {

    Context 'Simple class with Key, Mandatory and optional properties' {

        BeforeAll {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path $PSScriptRoot '..' 'Fixtures'
                $path = Join-Path $fixturesPath 'SimpleResource' 'SimpleResource.psm1'
                [System.Management.Automation.Language.Token[]] $tokens = $null
                [System.Management.Automation.Language.ParseError[]] $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
                $allTypes = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false)
                $typeAst = $allTypes | Where-Object { $_.Name -eq 'SimpleResource' }
                $script:properties = Get-DscResourceProperty -AllTypeDefinitions $allTypes -TypeDefinitionAst $typeAst
            }
        }

        It 'Returns four properties' {
            InModuleScope 'DscResource.Authoring' {
                $script:properties.Count | Should -Be 4
            }
        }

        It 'Includes the Name property as Key and Mandatory' {
            InModuleScope 'DscResource.Authoring' {
                $nameProp = $script:properties | Where-Object { $_.Name -eq 'Name' }
                $nameProp | Should -Not -BeNullOrEmpty
                $nameProp.IsKey | Should -BeTrue
                $nameProp.IsMandatory | Should -BeTrue
            }
        }

        It 'Includes the Value property as Mandatory but not Key' {
            InModuleScope 'DscResource.Authoring' {
                $valueProp = $script:properties | Where-Object { $_.Name -eq 'Value' }
                $valueProp | Should -Not -BeNullOrEmpty
                $valueProp.IsKey | Should -BeFalse
                $valueProp.IsMandatory | Should -BeTrue
            }
        }

        It 'Includes the Enabled property with bool TypeName' {
            InModuleScope 'DscResource.Authoring' {
                $enabledProp = $script:properties | Where-Object { $_.Name -eq 'Enabled' }
                $enabledProp | Should -Not -BeNullOrEmpty
                $enabledProp.TypeName.ToLower() | Should -BeExactly 'bool'
            }
        }

        It 'Includes the ComputedStatus property marked as NotConfigurable' {
            InModuleScope 'DscResource.Authoring' {
                $computedProp = $script:properties | Where-Object { $_.Name -eq 'ComputedStatus' }
                $computedProp | Should -Not -BeNullOrEmpty
                $computedProp.IsNotConfigurable | Should -BeTrue
                $computedProp.IsMandatory | Should -BeFalse
            }
        }
    }

    Context 'Class with inherited base class properties' {

        It 'Returns properties from both base and derived class' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path $PSScriptRoot '..' 'Fixtures'
                $path = Join-Path $fixturesPath 'MultiResource' 'MultiResource.psm1'
                [System.Management.Automation.Language.Token[]] $tokens = $null
                [System.Management.Automation.Language.ParseError[]] $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
                $allTypes = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false)
                $typeAst = $allTypes | Where-Object { $_.Name -eq 'ResourceA' }

                $properties = Get-DscResourceProperty -AllTypeDefinitions $allTypes -TypeDefinitionAst $typeAst
                $propNames = $properties | ForEach-Object { $_.Name }
                $propNames | Should -Contain 'BaseProperty'
                $propNames | Should -Contain 'Name'
            }
        }
    }
}
