# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

[DscResource()]
class ValidateSetResource {
    [DscProperty(Key)]
    [string] $Name

    [DscProperty()]
    [ValidateSet('Present', 'Absent')]
    [string] $Ensure

    [DscProperty()]
    [ValidateSet('Low', 'Medium', 'High')]
    [string] $Priority

    [ValidateSetResource] Get() {
        return $this
    }

    [bool] Test() {
        return $true
    }

    [void] Set() {
    }
}
