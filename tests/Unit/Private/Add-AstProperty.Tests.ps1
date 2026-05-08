BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force

    $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
    $script:simplePsm1 = Join-Path $fixturesPath 'SimpleResource' 'SimpleResource.psm1'
    $script:multiPsm1 = Join-Path $fixturesPath 'MultiResource' 'MultiResource.psm1'
    $script:noDscPsm1 = Join-Path $fixturesPath 'NoDscResource.psm1'

    InModuleScope $script:dscModuleName {
        # Re-export internal function reference so tests can call it directly
    }
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Add-AstProperty' {

    Context 'Class with Key and Mandatory properties' {

        BeforeAll {
            InModuleScope 'DscResource.Authoring' {
                $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                    (Join-Path $TestDrive 'dummy.psm1'),
                    [ref]$null, [ref]$null
                )
            }
        }

        It 'Collects all [DscProperty()] decorated properties from SimpleResource' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path $fixturesPath 'SimpleResource' 'SimpleResource.psm1'
                [System.Management.Automation.Language.Token[]] $tokens = $null
                [System.Management.Automation.Language.ParseError[]] $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
                $allTypes = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false)
                $typeAst = $allTypes | Where-Object { $_.Name -eq 'SimpleResource' }

                $properties = [System.Collections.Generic.List[hashtable]]::new()
                Add-AstProperty -AllTypeDefinitions $allTypes -TypeAst $typeAst -Properties $properties

                $properties.Count | Should -Be 4
            }
        }

        It 'Marks the Key property correctly' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path $fixturesPath 'SimpleResource' 'SimpleResource.psm1'
                [System.Management.Automation.Language.Token[]] $tokens = $null
                [System.Management.Automation.Language.ParseError[]] $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
                $allTypes = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false)
                $typeAst = $allTypes | Where-Object { $_.Name -eq 'SimpleResource' }

                $properties = [System.Collections.Generic.List[hashtable]]::new()
                Add-AstProperty -AllTypeDefinitions $allTypes -TypeAst $typeAst -Properties $properties

                $nameProp = $properties | Where-Object { $_.Name -eq 'Name' }
                $nameProp.IsKey | Should -BeTrue
                $nameProp.IsMandatory | Should -BeTrue
            }
        }

        It 'Marks the Mandatory property correctly' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path $fixturesPath 'SimpleResource' 'SimpleResource.psm1'
                [System.Management.Automation.Language.Token[]] $tokens = $null
                [System.Management.Automation.Language.ParseError[]] $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
                $allTypes = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false)
                $typeAst = $allTypes | Where-Object { $_.Name -eq 'SimpleResource' }

                $properties = [System.Collections.Generic.List[hashtable]]::new()
                Add-AstProperty -AllTypeDefinitions $allTypes -TypeAst $typeAst -Properties $properties

                $valueProp = $properties | Where-Object { $_.Name -eq 'Value' }
                $valueProp.IsKey | Should -BeFalse
                $valueProp.IsMandatory | Should -BeTrue
            }
        }

        It 'Resolves enum values for enum-typed properties' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path $fixturesPath 'MultiResource' 'MultiResource.psm1'
                [System.Management.Automation.Language.Token[]] $tokens = $null
                [System.Management.Automation.Language.ParseError[]] $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
                $allTypes = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false)
                $typeAst = $allTypes | Where-Object { $_.Name -eq 'ResourceA' }

                $properties = [System.Collections.Generic.List[hashtable]]::new()
                Add-AstProperty -AllTypeDefinitions $allTypes -TypeAst $typeAst -Properties $properties

                $ensureProp = $properties | Where-Object { $_.Name -eq 'Ensure' }
                $ensureProp.EnumValues | Should -Contain 'Present'
                $ensureProp.EnumValues | Should -Contain 'Absent'
            }
        }

        It 'Collects inherited base class properties' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $path = Join-Path $fixturesPath 'MultiResource' 'MultiResource.psm1'
                [System.Management.Automation.Language.Token[]] $tokens = $null
                [System.Management.Automation.Language.ParseError[]] $errors = $null
                $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
                $allTypes = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst] }, $false)
                $typeAst = $allTypes | Where-Object { $_.Name -eq 'ResourceA' }

                $properties = [System.Collections.Generic.List[hashtable]]::new()
                Add-AstProperty -AllTypeDefinitions $allTypes -TypeAst $typeAst -Properties $properties

                $propNames = $properties | ForEach-Object { $_.Name }
                $propNames | Should -Contain 'BaseProperty'
            }
        }
    }
}
