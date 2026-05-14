BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'New-EmbeddedJsonSchema' {

    Context 'Schema structure with minimal properties' {

        BeforeAll {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name              = 'Name'
                    TypeName          = 'String'
                    IsMandatory       = $true
                    IsNotConfigurable = $false
                    EnumValues        = $null
                })
                $properties.Add(@{
                    Name              = 'Enabled'
                    TypeName          = 'Boolean'
                    IsMandatory       = $false
                    IsNotConfigurable = $false
                    EnumValues        = $null
                })
                $script:result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' `
                    -Properties $properties
            }
        }

        It 'Includes the $schema key' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Contains('$schema') | Should -BeTrue
            }
        }

        It 'Sets title to the resource name' {
            InModuleScope 'DscResource.Authoring' {
                $script:result['title'] | Should -BeExactly 'TestModule/TestResource'
            }
        }

        It 'Sets type to object' {
            InModuleScope 'DscResource.Authoring' {
                $script:result['type'] | Should -BeExactly 'object'
            }
        }

        It 'Includes the required array' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Contains('required') | Should -BeTrue
            }
        }

        It 'Sets additionalProperties to false' {
            InModuleScope 'DscResource.Authoring' {
                $script:result['additionalProperties'] | Should -BeFalse
            }
        }

        It 'Includes a properties map' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Contains('properties') | Should -BeTrue
                $script:result['properties'].Contains('Name') | Should -BeTrue
                $script:result['properties'].Contains('Enabled') | Should -BeTrue
            }
        }

        It 'Adds mandatory properties to the required list' {
            InModuleScope 'DscResource.Authoring' {
                $script:result['required'] | Should -Contain 'Name'
            }
        }

        It 'Does not add non-mandatory properties to the required list' {
            InModuleScope 'DscResource.Authoring' {
                $script:result['required'] | Should -Not -Contain 'Enabled'
            }
        }

        It 'Maps Boolean type to JSON schema type' {
            InModuleScope 'DscResource.Authoring' {
                $enabledProp = $script:result['properties']['Enabled']
                $enabledProp.Contains('type') | Should -BeTrue
                $enabledProp['type'] | Should -BeExactly 'boolean'
            }
        }
    }

    Context 'Schema with enum values' {

        It 'Adds enum and type string for enum properties' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name        = 'Ensure'
                    TypeName    = 'String'
                    IsMandatory = $false
                    EnumValues  = @('Present', 'Absent')
                })
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' `
                    -Properties $properties
                $ensureProp = $result['properties']['Ensure']
                $ensureProp['type'] | Should -BeExactly 'string'
                $ensureProp['enum'] | Should -Contain 'Present'
                $ensureProp['enum'] | Should -Contain 'Absent'
            }
        }
    }

    Context 'Schema with Description parameter' {

        It 'Includes description in the schema when provided' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' `
                    -Properties $properties -Description 'Manages a test resource.'
                $result.Contains('description') | Should -BeTrue
                $result['description'] | Should -BeExactly 'Manages a test resource.'
            }
        }

        It 'Does not include description key when omitted' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' `
                    -Properties $properties
                $result.Contains('description') | Should -BeFalse
            }
        }
    }

    Context 'Schema with ClassHelp parameter descriptions' {

        It 'Uses ClassHelp parameter description when available' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name        = 'Name'
                    TypeName    = 'String'
                    IsMandatory = $true
                    EnumValues  = $null
                })
                $classHelp = @{
                    Synopsis    = 'A resource.'
                    Description = 'Does stuff.'
                    Parameters  = @{ Name = 'The unique name of the resource.' }
                }
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' `
                    -Properties $properties -ClassHelp $classHelp
                $result['properties']['Name']['description'] | Should -BeExactly 'The unique name of the resource.'
            }
        }

        It 'Falls back to default description when ClassHelp has no entry for a property' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name        = 'Value'
                    TypeName    = 'String'
                    IsMandatory = $false
                    EnumValues  = $null
                })
                $classHelp = @{
                    Synopsis    = 'A resource.'
                    Description = 'Does stuff.'
                    Parameters  = @{}
                }
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' `
                    -Properties $properties -ClassHelp $classHelp
                $result['properties']['Value']['description'] | Should -BeExactly 'The Value property.'
            }
        }
    }

    Context 'Schema with NotConfigurable property' {

        It 'Sets readOnly to true for a NotConfigurable property' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name              = 'ComputedStatus'
                    TypeName          = 'String'
                    IsMandatory       = $false
                    IsNotConfigurable = $true
                    EnumValues        = $null
                })
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' `
                    -Properties $properties
                $result['properties']['ComputedStatus']['readOnly'] | Should -BeTrue
            }
        }

        It 'Does not set readOnly for a normal property' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name              = 'Name'
                    TypeName          = 'String'
                    IsMandatory       = $true
                    IsNotConfigurable = $false
                    EnumValues        = $null
                })
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' `
                    -Properties $properties
                $result['properties']['Name'].Contains('readOnly') | Should -BeFalse
            }
        }

        It 'Does not add a NotConfigurable property to the required list' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name              = 'ComputedStatus'
                    TypeName          = 'String'
                    IsMandatory       = $false
                    IsNotConfigurable = $true
                    EnumValues        = $null
                })
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' `
                    -Properties $properties
                $result['required'] | Should -Not -Contain 'ComputedStatus'
            }
        }
    }

    Context 'ValidatePattern handling' {

        It 'Emits pattern keyword for an ECMA-compatible pattern' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name              = 'AuditGuid'
                    TypeName          = 'String'
                    IsMandatory       = $false
                    IsNotConfigurable = $false
                    EnumValues        = $null
                    PatternValue      = '^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$'
                })
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' -Properties $properties
                $result['properties']['AuditGuid']['pattern'] | Should -Be '^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$'
            }
        }

        It 'Suppresses pattern and writes a warning for a .NET-specific pattern' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name              = 'Value'
                    TypeName          = 'String'
                    IsMandatory       = $false
                    IsNotConfigurable = $false
                    EnumValues        = $null
                    PatternValue      = '\Afoo\Z'
                })
                $result = $null
                { $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' -Properties $properties -WarningAction Stop } |
                    Should -Throw
            }
        }

        It 'Emits pattern for a .NET-specific pattern when -AllowNonEcmaPattern is set' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name              = 'Value'
                    TypeName          = 'String'
                    IsMandatory       = $false
                    IsNotConfigurable = $false
                    EnumValues        = $null
                    PatternValue      = '\Afoo\Z'
                })
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' -Properties $properties -AllowNonEcmaPattern
                $result['properties']['Value']['pattern'] | Should -Be '\Afoo\Z'
            }
        }

        It 'Does not emit pattern when EnumValues is also set' {
            InModuleScope 'DscResource.Authoring' {
                $properties = [System.Collections.Generic.List[hashtable]]::new()
                $properties.Add(@{
                    Name              = 'Ensure'
                    TypeName          = 'String'
                    IsMandatory       = $false
                    IsNotConfigurable = $false
                    EnumValues        = @('Present', 'Absent')
                    PatternValue      = '^(Present|Absent)$'
                })
                $result = New-EmbeddedJsonSchema -ResourceName 'TestModule/TestResource' -Properties $properties
                $result['properties']['Ensure'].ContainsKey('pattern') | Should -BeFalse
                $result['properties']['Ensure']['enum'] | Should -Be @('Present', 'Absent')
            }
        }
    }
}
