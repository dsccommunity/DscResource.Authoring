<#
    .SYNOPSIS
        Parses a comment-based help block into a structured hashtable.

    .DESCRIPTION
        Extracts the .SYNOPSIS, .DESCRIPTION and .PARAMETER content from a
        PowerShell block comment and returns the values as a hashtable with
        Synopsis, Description and Parameters keys.

    .PARAMETER CommentText
        The raw text of a PowerShell block comment, including the surrounding
        `<#` and `#>` delimiters.
#>
function ConvertFrom-CommentBasedHelp
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $CommentText
    )

    # Strip the <# and #> delimiters
    $text = $CommentText -replace '^\s*<#', '' -replace '#>\s*$', ''

    $result = @{
        Synopsis    = ''
        Description = ''
        Parameters  = @{}
    }

    $keywordPattern = '(?mi)^\s*\.(?<keyword>SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|NOTES|OUTPUTS|INPUTS|LINK|COMPONENT|ROLE|FUNCTIONALITY)[^\S\r\n]*(?<arg>.*)$'

    $keywordMatches = [regex]::Matches($text, $keywordPattern)

    if ($keywordMatches.Count -eq 0)
    {
        return $result
    }

    for ($i = 0; $i -lt $keywordMatches.Count; $i++)
    {
        $keyword = $keywordMatches[$i].Groups['keyword'].Value.ToUpper()
        $arg = $keywordMatches[$i].Groups['arg'].Value.Trim()

        $startIndex = $keywordMatches[$i].Index + $keywordMatches[$i].Length
        $endIndex = if ($i + 1 -lt $keywordMatches.Count) { $keywordMatches[$i + 1].Index } else { $text.Length }
        $content = $text.Substring($startIndex, $endIndex - $startIndex).Trim()

        switch ($keyword)
        {
            'SYNOPSIS'
            {
                $result.Synopsis = $content
            }
            'DESCRIPTION'
            {
                $result.Description = $content
            }
            'PARAMETER'
            {
                if (-not [string]::IsNullOrWhiteSpace($arg))
                {
                    $result.Parameters[$arg] = $content
                }
            }
        }
    }

    return $result
}
