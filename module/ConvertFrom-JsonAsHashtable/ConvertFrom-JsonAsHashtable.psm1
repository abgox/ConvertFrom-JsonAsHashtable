Set-StrictMode -Off

<#
.SYNOPSIS
    JSON to Hashtable Conversion for Windows PowerShell 5.0+, providing functionality similar to 'ConvertFrom-Json -AsHashtable' in PowerShell 7+.

.DESCRIPTION
    Converts JSON text into PowerShell hashtables.
    Provides functionality similar to 'ConvertFrom-Json -AsHashtable' in PowerShell 7+.

.PARAMETER InputObject
    The JSON input to convert.
    Can be a string, an array of strings, or input from the pipeline.

.EXAMPLE
    # Convert JSON from a file into a hashtable
    Get-Content "data.json" | ConvertFrom-JsonAsHashtable

.EXAMPLE
    # Convert a JSON string directly
    '{"name":"Tom","age":25}' | ConvertFrom-JsonAsHashtable

.EXAMPLE
    # Assign JSON from a file to a variable as hashtable
    $ht = Get-Content "data.json" | ConvertFrom-JsonAsHashtable

.LINK
    GitHub : https://github.com/abgox/ConvertFrom-JsonAsHashtable
    Gitee  : https://gitee.com/abgox/ConvertFrom-JsonAsHashtable
#>
function ConvertFrom-JsonAsHashtable {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    begin {
        $buffer = [System.Text.StringBuilder]::new()
    }

    process {
        if ($InputObject -is [array]) {
            [void]$buffer.AppendLine(($InputObject -join "`n"))
        }
        else {
            [void]$buffer.AppendLine($InputObject)
        }
    }

    end {
        $jsonString = $buffer.ToString().Trim()
        if (-not $jsonString) { return $null }

        if ($PSVersionTable.PSVersion.Major -ge 7) {
            return ConvertFrom-Json $jsonString -AsHashtable
        }

        $jsonString = [regex]::Replace($jsonString, '(?<!\\)""\s*:', { '"emptyKey_' + [Guid]::NewGuid() + '":' })

        $jsonString = [regex]::Replace($jsonString, ',\s*(?=[}\]]\s*$)', '')

        $parsed = ConvertFrom-Json $jsonString

        function ConvertRecursively {
            param($obj)

            if ($null -eq $obj) { return $null }

            # IDictionary (Hashtable, Dictionary<,>) -> @{ }
            if ($obj -is [System.Collections.IDictionary]) {
                $ht = @{}
                foreach ($k in $obj.Keys) {
                    $ht[$k] = ConvertRecursively $obj[$k]
                }
                return $ht
            }

            # PSCustomObject -> @{ }
            if ($obj -is [System.Management.Automation.PSCustomObject]) {
                $ht = @{}
                foreach ($p in $obj.PSObject.Properties) {
                    $ht[$p.Name] = ConvertRecursively $p.Value
                }
                return $ht
            }

            # IEnumerable (array、ArrayList), exclude string and byte[]
            if ($obj -is [System.Collections.IEnumerable] -and -not ($obj -is [string]) -and -not ($obj -is [byte[]])) {
                $list = [System.Collections.Generic.List[object]]::new()
                foreach ($item in $obj) {
                    $list.Add((ConvertRecursively $item))
                }
                return , $list.ToArray()
            }

            # ohter types (string, int, bool, datetime...)
            return $obj
        }

        return ConvertRecursively $parsed
    }
}

Export-ModuleMember -Function ConvertFrom-JsonAsHashtable
