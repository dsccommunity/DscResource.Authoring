BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'ConvertFrom-CommentBasedHelp' {

    Context 'Block comment with all sections' {

        BeforeAll {
            InModuleScope 'DscResource.Authoring' {
                $script:comment = @'
<#
    .SYNOPSIS
        A short synopsis.

    .DESCRIPTION
        A longer description.

    .PARAMETER Name
        The name parameter.

    .PARAMETER Value
        The value parameter.
#>
'@
                $script:result = ConvertFrom-CommentBasedHelp -CommentText $script:comment
            }
        }

        It 'Returns a hashtable' {
            InModuleScope 'DscResource.Authoring' {
                $script:result | Should -BeOfType [hashtable]
            }
        }

        It 'Extracts the Synopsis' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Synopsis | Should -BeExactly 'A short synopsis.'
            }
        }

        It 'Extracts the Description' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Description | Should -BeExactly 'A longer description.'
            }
        }

        It 'Extracts the Name parameter description' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Parameters['Name'] | Should -BeExactly 'The name parameter.'
            }
        }

        It 'Extracts the Value parameter description' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Parameters['Value'] | Should -BeExactly 'The value parameter.'
            }
        }
    }

    Context 'Block comment with no recognized keywords' {

        It 'Returns empty Synopsis and Description' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertFrom-CommentBasedHelp -CommentText '<# some freeform text #>'
                $result.Synopsis | Should -BeNullOrEmpty
                $result.Description | Should -BeNullOrEmpty
                $result.Parameters.Count | Should -Be 0
            }
        }
    }

    Context 'Block comment with only Synopsis' {

        It 'Returns only the Synopsis' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertFrom-CommentBasedHelp -CommentText "<#`n    .SYNOPSIS`n        Just a synopsis.`n#>"
                $result.Synopsis | Should -BeExactly 'Just a synopsis.'
                $result.Description | Should -BeNullOrEmpty
                $result.Parameters.Count | Should -Be 0
            }
        }
    }
}
