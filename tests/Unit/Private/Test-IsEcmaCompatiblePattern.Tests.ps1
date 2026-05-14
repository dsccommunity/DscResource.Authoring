BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Test-IsEcmaCompatiblePattern' {

    Context 'Compatible patterns' {

        It 'Returns $true for a simple character class pattern' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '^[a-z]+$' | Should -BeTrue
            }
        }

        It 'Returns $true for a GUID pattern using portable syntax' {
            InModuleScope 'DscResource.Authoring' {
                $pattern = '^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$'
                Test-IsEcmaCompatiblePattern -Pattern $pattern | Should -BeTrue
            }
        }

        It 'Returns $true for a pattern using lookahead (supported in ECMA 262)' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '(?=.*\d)(?=.*[a-z]).{8,}' | Should -BeTrue
            }
        }

        It 'Returns $true for a pattern using lookbehind (supported in ECMA 2018)' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '(?<=prefix-)[\w]+' | Should -BeTrue
            }
        }
    }

    Context 'Incompatible patterns' {

        It 'Returns $false for a pattern using .NET anchor \A' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '\A[a-z]+\Z' | Should -BeFalse
            }
        }

        It 'Returns $false for a pattern using .NET anchor \Z' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '^[a-z]+\Z' | Should -BeFalse
            }
        }

        It 'Returns $false for a pattern using .NET anchor \z' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '^[a-z]+\z' | Should -BeFalse
            }
        }

        It 'Returns $false for a pattern using an atomic group' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '(?>a+)b' | Should -BeFalse
            }
        }

        It 'Returns $false for a pattern using an inline comment' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '(?#this is a comment)[a-z]+' | Should -BeFalse
            }
        }

        It 'Returns $false for a pattern using inline option flags' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '(?i)[a-z]+' | Should -BeFalse
            }
        }

        It 'Returns $false for a pattern using a balancing group' {
            InModuleScope 'DscResource.Authoring' {
                Test-IsEcmaCompatiblePattern -Pattern '(?<open>\()(?<close-open>\))' | Should -BeFalse
            }
        }
    }
}
