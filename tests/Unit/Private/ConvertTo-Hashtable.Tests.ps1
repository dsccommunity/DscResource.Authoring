BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'ConvertTo-Hashtable' {

    Context 'PSCustomObject input' {

        It 'Converts a flat PSCustomObject to an ordered hashtable' {
            InModuleScope 'DscResource.Authoring' {
                $obj = [PSCustomObject]@{ Name = 'Alice'; Age = 30 }
                $result = ConvertTo-Hashtable -InputObject $obj
                $result | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
                $result['Name'] | Should -BeExactly 'Alice'
                $result['Age'] | Should -Be 30
            }
        }

        It 'Recursively converts nested PSCustomObjects' {
            InModuleScope 'DscResource.Authoring' {
                $inner = [PSCustomObject]@{ City = 'London' }
                $obj = [PSCustomObject]@{ Name = 'Bob'; Address = $inner }
                $result = ConvertTo-Hashtable -InputObject $obj
                $result['Address'] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
                $result['Address']['City'] | Should -BeExactly 'London'
            }
        }
    }

    Context 'Array/IList input' {

        It 'Converts an array of PSCustomObjects to an array of hashtables' {
            InModuleScope 'DscResource.Authoring' {
                $list = @(
                    [PSCustomObject]@{ Id = 1 }
                    [PSCustomObject]@{ Id = 2 }
                )
                $result = ConvertTo-Hashtable -InputObject $list
                $result | Should -HaveCount 2
                $result[0]['Id'] | Should -Be 1
                $result[1]['Id'] | Should -Be 2
            }
        }
    }

    Context 'Scalar input' {

        It 'Returns a string unchanged' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-Hashtable -InputObject 'hello'
                $result | Should -BeExactly 'hello'
            }
        }

        It 'Returns an integer unchanged' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-Hashtable -InputObject 42
                $result | Should -Be 42
            }
        }
    }

    Context 'ConvertFrom-Json round-trip' {

        It 'Converts ConvertFrom-Json output to nested hashtables' {
            InModuleScope 'DscResource.Authoring' {
                $json = '{"type":"MyModule/MyRes","capabilities":["get","set"],"nested":{"key":"value"}}'
                $parsed = ConvertFrom-Json -InputObject $json
                $result = ConvertTo-Hashtable -InputObject $parsed
                $result['type'] | Should -BeExactly 'MyModule/MyRes'
                $result['capabilities'] | Should -HaveCount 2
                $result['nested']['key'] | Should -BeExactly 'value'
            }
        }
    }
}
