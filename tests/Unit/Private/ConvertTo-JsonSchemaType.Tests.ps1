BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'ConvertTo-JsonSchemaType' {

    Context 'String types' {

        It 'Maps string to { type = string }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'string'
                $result['type'] | Should -BeExactly 'string'
            }
        }

        It 'Maps datetime to { type = string; format = date-time }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'datetime'
                $result['type'] | Should -BeExactly 'string'
                $result['format'] | Should -BeExactly 'date-time'
            }
        }
    }

    Context 'Integer types' {

        It 'Maps int to { type = integer }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'int'
                $result['type'] | Should -BeExactly 'integer'
            }
        }

        It 'Maps int32 to { type = integer }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'int32'
                $result['type'] | Should -BeExactly 'integer'
            }
        }

        It 'Maps int64 to { type = integer }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'int64'
                $result['type'] | Should -BeExactly 'integer'
            }
        }

        It 'Maps long to { type = integer }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'long'
                $result['type'] | Should -BeExactly 'integer'
            }
        }
    }

    Context 'Number types' {

        It 'Maps double to { type = number }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'double'
                $result['type'] | Should -BeExactly 'number'
            }
        }

        It 'Maps float to { type = number }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'float'
                $result['type'] | Should -BeExactly 'number'
            }
        }
    }

    Context 'Boolean types' {

        It 'Maps bool to { type = boolean }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'bool'
                $result['type'] | Should -BeExactly 'boolean'
            }
        }

        It 'Maps boolean to { type = boolean }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'boolean'
                $result['type'] | Should -BeExactly 'boolean'
            }
        }

        It 'Maps switch to { type = boolean }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'switch'
                $result['type'] | Should -BeExactly 'boolean'
            }
        }
    }

    Context 'Object types' {

        It 'Maps hashtable to { type = object }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'hashtable'
                $result['type'] | Should -BeExactly 'object'
            }
        }
    }

    Context 'Array types' {

        It 'Maps string[] to { type = array; items = { type = string } }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'string[]'
                $result['type'] | Should -BeExactly 'array'
                $result['items']['type'] | Should -BeExactly 'string'
            }
        }

        It 'Maps int[] to { type = array; items = { type = integer } }' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'int[]'
                $result['type'] | Should -BeExactly 'array'
                $result['items']['type'] | Should -BeExactly 'integer'
            }
        }
    }

    Context 'Unknown types' {

        It 'Falls back to { type = string } for unknown type names' {
            InModuleScope 'DscResource.Authoring' {
                $result = ConvertTo-JsonSchemaType -TypeName 'SomeCustomClass'
                $result['type'] | Should -BeExactly 'string'
            }
        }
    }
}
