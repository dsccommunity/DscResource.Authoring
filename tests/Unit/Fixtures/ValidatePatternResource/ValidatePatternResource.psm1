# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

[DscResource()]
class ValidatePatternResource {
    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [ValidatePattern('^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$')]
    [string] $AuditGuid

    [DscProperty()]
    [ValidateSet('Present', 'Absent')]
    [ValidatePattern('^(Present|Absent)$')]
    [string] $Ensure

    [ValidatePatternResource] Get() {
        return $this
    }

    [bool] Test() {
        return $true
    }

    [void] Set() {
    }
}
