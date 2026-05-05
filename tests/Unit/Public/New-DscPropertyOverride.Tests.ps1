BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'New-DscPropertyOverride' {

    Context 'With only the mandatory Name parameter' {

        BeforeAll {
            $script:result = New-DscPropertyOverride -Name 'MyProperty'
        }

        It 'Returns a DscPropertyOverride object' {
            $script:result.GetType().Name | Should -BeExactly 'DscPropertyOverride'
        }

        It 'Sets the Name property' {
            $script:result.Name | Should -BeExactly 'MyProperty'
        }

        It 'Leaves Description as null or empty' {
            $script:result.Description | Should -BeNullOrEmpty
        }

        It 'Leaves Title as null or empty' {
            $script:result.Title | Should -BeNullOrEmpty
        }

        It 'Leaves JsonSchema as null' {
            $script:result.JsonSchema | Should -BeNullOrEmpty
        }

        It 'Leaves RemoveKeys as null' {
            $script:result.RemoveKeys | Should -BeNullOrEmpty
        }

        It 'Leaves Required as null' {
            $script:result.Required | Should -BeNullOrEmpty
        }
    }

    Context 'With Description parameter' {

        It 'Sets the Description property' {
            $result = New-DscPropertyOverride -Name 'Enabled' -Description 'Whether this resource is active.'
            $result.Description | Should -BeExactly 'Whether this resource is active.'
        }
    }

    Context 'With Title parameter' {

        It 'Sets the Title property' {
            $result = New-DscPropertyOverride -Name 'Enabled' -Title 'Enabled Flag'
            $result.Title | Should -BeExactly 'Enabled Flag'
        }
    }

    Context 'With JsonSchema parameter' {

        It 'Sets the JsonSchema property' {
            $schema = @{ minimum = 0; maximum = 100 }
            $result = New-DscPropertyOverride -Name 'Count' -JsonSchema $schema
            $result.JsonSchema | Should -Not -BeNullOrEmpty
            $result.JsonSchema['minimum'] | Should -Be 0
            $result.JsonSchema['maximum'] | Should -Be 100
        }
    }

    Context 'With RemoveKeys parameter' {

        It 'Sets the RemoveKeys property' {
            $result = New-DscPropertyOverride -Name 'Status' -RemoveKeys 'type', 'enum'
            $result.RemoveKeys | Should -Contain 'type'
            $result.RemoveKeys | Should -Contain 'enum'
        }
    }

    Context 'With Required parameter' {

        It 'Sets Required to true' {
            $result = New-DscPropertyOverride -Name 'Name' -Required $true
            $result.Required | Should -BeTrue
        }

        It 'Sets Required to false' {
            $result = New-DscPropertyOverride -Name 'Name' -Required $false
            $result.Required | Should -BeFalse
        }
    }

    Context 'With all parameters specified' {

        It 'Populates all properties correctly' {
            $result = New-DscPropertyOverride -Name 'Status' `
                -Description 'The resource status.' `
                -Title 'Status' `
                -JsonSchema @{ anyOf = @(@{ type = 'string' }) } `
                -RemoveKeys 'type' `
                -Required $true
            $result.Name | Should -BeExactly 'Status'
            $result.Description | Should -BeExactly 'The resource status.'
            $result.Title | Should -BeExactly 'Status'
            $result.JsonSchema | Should -Not -BeNullOrEmpty
            $result.RemoveKeys | Should -Contain 'type'
            $result.Required | Should -BeTrue
        }
    }
}
