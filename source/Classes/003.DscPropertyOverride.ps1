class DscPropertyOverride
{
    [string] $Name
    [string] $Description
    [string] $Title
    [hashtable] $JsonSchema
    [string[]] $RemoveKeys
    [object] $Required

    DscPropertyOverride()
    {
        $this.JsonSchema = @{}
        $this.RemoveKeys = @()
    }
}
