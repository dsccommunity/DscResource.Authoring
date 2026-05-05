class DscResourceManifestList
{
    [System.Collections.Generic.List[hashtable]] $AdaptedResources
    [System.Collections.Generic.List[hashtable]] $Resources
    [System.Collections.Generic.List[hashtable]] $Extensions

    DscResourceManifestList()
    {
        $this.AdaptedResources = [System.Collections.Generic.List[hashtable]]::new()
        $this.Resources = [System.Collections.Generic.List[hashtable]]::new()
        $this.Extensions = [System.Collections.Generic.List[hashtable]]::new()
    }

    [void] AddAdaptedResource([DscAdaptedResourceManifest]$Manifest)
    {
        $this.AdaptedResources.Add($Manifest.ToHashtable())
    }

    [void] AddResource([hashtable]$Resource)
    {
        $this.Resources.Add($Resource)
    }

    [void] AddExtension([hashtable]$Extension)
    {
        $this.Extensions.Add($Extension)
    }

    [string] ToJson()
    {
        $result = [ordered]@{}

        if ($this.AdaptedResources.Count -gt 0)
        {
            $result['adaptedResources'] = @($this.AdaptedResources)
        }

        if ($this.Resources.Count -gt 0)
        {
            $result['resources'] = @($this.Resources)
        }

        if ($this.Extensions.Count -gt 0)
        {
            $result['extensions'] = @($this.Extensions)
        }

        return $result | ConvertTo-Json -Depth 15
    }
}
