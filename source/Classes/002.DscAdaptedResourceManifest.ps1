class DscAdaptedResourceManifest
{
    [string] $Schema
    [string] $Type
    [string] $Kind
    [string] $Version
    [string[]] $Capabilities
    [string] $Description
    [string] $Author
    [string] $RequireAdapter
    [string] $Path
    [DscAdaptedResourceManifestSchema] $ManifestSchema

    [string] ToJson()
    {
        $manifest = [ordered]@{
            '$schema'      = $this.Schema
            type           = $this.Type
            kind           = $this.Kind
            version        = $this.Version
            capabilities   = $this.Capabilities
            description    = $this.Description
            author         = $this.Author
            requireAdapter = $this.RequireAdapter
            path           = $this.Path
            schema         = [ordered]@{
                embedded = $this.ManifestSchema.Embedded
            }
        }
        return $manifest | ConvertTo-Json -Depth 10
    }

    [hashtable] ToHashtable()
    {
        return [ordered]@{
            '$schema'      = $this.Schema
            type           = $this.Type
            kind           = $this.Kind
            version        = $this.Version
            capabilities   = $this.Capabilities
            description    = $this.Description
            author         = $this.Author
            requireAdapter = $this.RequireAdapter
            path           = $this.Path
            schema         = [ordered]@{
                embedded = $this.ManifestSchema.Embedded
            }
        }
    }
}
