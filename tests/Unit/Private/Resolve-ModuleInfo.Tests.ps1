BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Resolve-ModuleInfo' {

    Context 'With a .psd1 path' {

        BeforeAll {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $psd1 = Join-Path (Join-Path $fixturesPath 'SimpleResource') 'SimpleResource.psd1'
                $script:result = Resolve-ModuleInfo -Path $psd1
            }
        }

        It 'Returns a hashtable' {
            InModuleScope 'DscResource.Authoring' {
                $script:result | Should -BeOfType [hashtable]
            }
        }

        It 'Returns the correct ModuleName' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.ModuleName | Should -BeExactly 'SimpleResource'
            }
        }

        It 'Returns a Version string' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Version | Should -Not -BeNullOrEmpty
            }
        }

        It 'Returns a ScriptPath that exists' {
            InModuleScope 'DscResource.Authoring' {
                Test-Path -LiteralPath $script:result.ScriptPath | Should -BeTrue
            }
        }

        It 'Returns the Directory key' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.ContainsKey('Directory') | Should -BeTrue
                $script:result.Directory | Should -Not -BeNullOrEmpty
            }
        }

        It 'Returns the Psd1Path key' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.ContainsKey('Psd1Path') | Should -BeTrue
            }
        }
    }

    Context 'With a .psm1 path that has a sibling .psd1' {

        It 'Reads the sibling manifest and returns correct ModuleName' {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $psm1 = Join-Path (Join-Path $fixturesPath 'SimpleResource') 'SimpleResource.psm1'
                $result = Resolve-ModuleInfo -Path $psm1
                $result.ModuleName | Should -BeExactly 'SimpleResource'
            }
        }
    }

    Context 'With a standalone .ps1 file (no sibling .psd1)' {

        BeforeAll {
            InModuleScope 'DscResource.Authoring' {
                $fixturesPath = Join-Path (Join-Path $PSScriptRoot '..') 'Fixtures'
                $ps1 = Join-Path $fixturesPath 'StandaloneResource.ps1'
                $script:result = Resolve-ModuleInfo -Path $ps1
            }
        }

        It 'Returns default version 0.0.1' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Version | Should -BeExactly '0.0.1'
            }
        }

        It 'Returns a ScriptPath pointing to the provided file' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.ScriptPath | Should -Not -BeNullOrEmpty
            }
        }

        It 'Returns all expected keys' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.ContainsKey('ModuleName') | Should -BeTrue
                $script:result.ContainsKey('Version') | Should -BeTrue
                $script:result.ContainsKey('Author') | Should -BeTrue
                $script:result.ContainsKey('Description') | Should -BeTrue
                $script:result.ContainsKey('ScriptPath') | Should -BeTrue
                $script:result.ContainsKey('Directory') | Should -BeTrue
            }
        }
    }
}
