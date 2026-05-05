BeforeAll {
    $script:dscModuleName = 'DscResource.Authoring'

    Import-Module -Name $script:dscModuleName -Force
}

AfterAll {
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'ConvertTo-AdaptedResourceManifest' {

    Context 'Full manifest hashtable' {

        BeforeAll {
            InModuleScope 'DscResource.Authoring' {
                $script:hashtable = [ordered]@{
                    '$schema'      = 'https://aka.ms/dsc/schemas/v3/bundled/adaptedresource/manifest.json'
                    type           = 'MyModule/MyResource'
                    kind           = 'resource'
                    version        = '1.2.3'
                    capabilities   = @('get', 'set', 'test')
                    description    = 'My resource description.'
                    author         = 'Test Author'
                    requireAdapter = 'Microsoft.Adapter/PowerShell'
                    path           = 'MyModule.psd1'
                    schema         = [ordered]@{
                        embedded = [ordered]@{
                            '$schema' = 'https://json-schema.org/draft/2020-12/schema'
                            type      = 'object'
                        }
                    }
                }
                $script:result = ConvertTo-AdaptedResourceManifest -Hashtable $script:hashtable
            }
        }

        It 'Returns a DscAdaptedResourceManifest object' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.GetType().Name | Should -BeExactly 'DscAdaptedResourceManifest'
            }
        }

        It 'Maps the schema URI' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Schema | Should -BeExactly 'https://aka.ms/dsc/schemas/v3/bundled/adaptedresource/manifest.json'
            }
        }

        It 'Maps the type' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Type | Should -BeExactly 'MyModule/MyResource'
            }
        }

        It 'Maps the version' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Version | Should -BeExactly '1.2.3'
            }
        }

        It 'Maps the capabilities' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Capabilities | Should -Contain 'get'
                $script:result.Capabilities | Should -Contain 'set'
                $script:result.Capabilities | Should -Contain 'test'
            }
        }

        It 'Maps the description' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Description | Should -BeExactly 'My resource description.'
            }
        }

        It 'Maps the author' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.Author | Should -BeExactly 'Test Author'
            }
        }

        It 'Maps the requireAdapter' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.RequireAdapter | Should -BeExactly 'Microsoft.Adapter/PowerShell'
            }
        }

        It 'Populates the embedded schema' {
            InModuleScope 'DscResource.Authoring' {
                $script:result.ManifestSchema | Should -Not -BeNullOrEmpty
                $script:result.ManifestSchema.Embedded | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Manifest hashtable without optional fields' {

        It 'Defaults kind to resource when absent' {
            InModuleScope 'DscResource.Authoring' {
                $hashtable = [ordered]@{
                    '$schema'      = 'https://aka.ms/dsc/schemas/v3/bundled/adaptedresource/manifest.json'
                    type           = 'MyModule/MyResource'
                    version        = '1.0.0'
                    requireAdapter = 'Microsoft.Adapter/PowerShell'
                    schema         = @{ embedded = @{} }
                }
                $result = ConvertTo-AdaptedResourceManifest -Hashtable $hashtable
                $result.Kind | Should -BeExactly 'resource'
            }
        }

        It 'Defaults capabilities to null or empty when absent' {
            InModuleScope 'DscResource.Authoring' {
                $hashtable = [ordered]@{
                    '$schema'      = 'https://aka.ms/dsc/schemas/v3/bundled/adaptedresource/manifest.json'
                    type           = 'MyModule/MyResource'
                    version        = '1.0.0'
                    requireAdapter = 'Microsoft.Adapter/PowerShell'
                    schema         = @{ embedded = @{} }
                }
                $result = ConvertTo-AdaptedResourceManifest -Hashtable $hashtable
                $result.Capabilities | Should -BeNullOrEmpty
            }
        }
    }
}
