<#
    .SYNOPSIS
        Returns the comment-based help associated with each class in a script.

    .DESCRIPTION
        Tokenizes a PowerShell script and locates block comments that immediately
        precede class declarations (allowing for attributes and blank lines in
        between). Each matched class name is returned as a key in a hashtable
        whose value is the parsed comment-based help (Synopsis, Description and
        Parameters).

    .PARAMETER Path
        The full path to a .ps1 or .psm1 file to inspect.
#>
function Get-ClassCommentBasedHelp
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    [System.Management.Automation.Language.Token[]] $tokens = $null
    [System.Management.Automation.Language.ParseError[]] $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)

    $blockCommentTokens = @($tokens | Where-Object {
            $_.Kind -eq [System.Management.Automation.Language.TokenKind]::Comment -and
            $_.Text.StartsWith('<#')
        })

    $classDefinitions = $tokens | Where-Object {
        $_.Kind -eq [System.Management.Automation.Language.TokenKind]::Class
    }

    $result = @{}

    foreach ($classToken in $classDefinitions)
    {
        $classLine = $classToken.Extent.StartLineNumber

        # Walk backward from the class keyword to find the nearest block comment,
        # allowing for attributes and blank lines between the comment and class.
        $nearestComment = $null
        foreach ($commentToken in $blockCommentTokens)
        {
            $gap = $classLine - $commentToken.Extent.EndLineNumber
            if ($gap -ge 1 -and $gap -le 10)
            {
                # Verify no other class keyword exists between this comment and the current class
                $isValid = $true
                foreach ($otherClass in $classDefinitions)
                {
                    if ($otherClass -ne $classToken -and
                        $otherClass.Extent.StartLineNumber -gt $commentToken.Extent.EndLineNumber -and
                        $otherClass.Extent.StartLineNumber -lt $classLine)
                    {
                        $isValid = $false
                        break
                    }
                }
                if ($isValid -and ($null -eq $nearestComment -or
                        $commentToken.Extent.EndLineNumber -gt $nearestComment.Extent.EndLineNumber))
                {
                    $nearestComment = $commentToken
                }
            }
        }

        if ($null -eq $nearestComment)
        {
            continue
        }

        $parsed = ConvertFrom-CommentBasedHelp -CommentText $nearestComment.Text

        if ($parsed.Synopsis -or $parsed.Description -or $parsed.Parameters.Count -gt 0)
        {
            # Determine the class name from the token following 'class'
            $classIndex = [array]::IndexOf($tokens, $classToken)
            $className = $null
            for ($i = $classIndex + 1; $i -lt $tokens.Count; $i++)
            {
                if ($tokens[$i].Kind -eq [System.Management.Automation.Language.TokenKind]::Identifier)
                {
                    $className = $tokens[$i].Text
                    break
                }
            }
            if ($className)
            {
                $result[$className] = $parsed
            }
        }
    }

    return $result
}
