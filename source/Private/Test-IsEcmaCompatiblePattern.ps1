<#
    .SYNOPSIS
        Tests whether a regex pattern is compatible with the ECMA 262 dialect
        used by JSON Schema validators.

    .DESCRIPTION
        Inspects a regex string for .NET-specific constructs that have no
        equivalent in ECMA 262. When any such construct is found the function
        returns $false so callers can decide whether to emit the pattern as a
        JSON Schema `pattern` keyword.

        The following .NET-only constructs are detected:

        * `\A`, `\Z`, `\z` - .NET position anchors (ECMA uses `^`/`$` only).
        * `(?>...)` - atomic (possessive) groups.
        * `(?#...)` - inline comments.
        * `(?imnsx)` / `(?i:...)` - inline option flags.
        * `(?<name-name>...)` - balancing groups.

        Note: positive/negative lookbehind (`(?<=`, `(?<!`) and Unicode property
        escapes (`\p{L}`) are intentionally *not* flagged because ECMA 2018
        (supported by most modern JSON Schema validators) includes them.

    .PARAMETER Pattern
        The regex pattern string to evaluate.

    .EXAMPLE
        Test-IsEcmaCompatiblePattern -Pattern '^[a-z]+$'

        Returns $true — the pattern uses only portable syntax.

    .EXAMPLE
        Test-IsEcmaCompatiblePattern -Pattern '^\A[a-z]+\Z$'

        Returns $false — `\A` and `\Z` are .NET-only anchors.
#>
function Test-IsEcmaCompatiblePattern
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Pattern
    )

    # Each entry is a regex that matches a .NET-specific construct.
    $dotNetConstructs = @(
        '\\[AZz]'            # .NET anchors: \A, \Z, \z
        '\(\?>'              # atomic groups: (?>...)
        '\(\?#'              # inline comments: (?#...)
        '\(\?[imnsx]+'       # inline option flags: (?i), (?ix:...) etc.
        '\(\?<\w+-\w+>'      # balancing groups: (?<open-close>...)
    )

    foreach ($construct in $dotNetConstructs)
    {
        if ($Pattern -match $construct)
        {
            return $false
        }
    }

    return $true
}
