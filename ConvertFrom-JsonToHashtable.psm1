function ConvertFrom-JsonToHashtable {
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$json
    )
    $matches = [regex]::Matches($json, '\s*"\s*"\s*:')
    foreach ($match in $matches) {
        $json = $json -replace $match.Value, "`"empty_key_$([System.Guid]::NewGuid().Guid)`":"
    }
    $json = [regex]::Replace($json, ",`n?(\s*`n)?\}", "}")

    function ProcessArray {
        param($array)
        $nestedArr = @()
        foreach ($item in $array) {
            if ($item -is [System.Collections.IEnumerable] -and $item -isnot [string]) {
                $nestedArr += , (ProcessArray $item)
            }
            elseif ($item -is [System.Management.Automation.PSCustomObject]) {
                $nestedArr += ConvertToHashtable $item
            }
            else { $nestedArr += $item }
        }
        return , $nestedArr
    }

    function ConvertToHashtable {
        param($obj)
        $hash = @{}
        if ($obj -is [System.Management.Automation.PSCustomObject]) {
            foreach ($_ in $obj | Get-Member -MemberType Properties) {
                $k = $_.Name # Key
                $v = $obj.$k # Value
                if ($v -is [System.Collections.IEnumerable] -and $v -isnot [string]) {
                    # Handle array (preserve nested structure)
                    $hash[$k] = ProcessArray $v
                }
                elseif ($v -is [System.Management.Automation.PSCustomObject]) {
                    # Handle object
                    $hash[$k] = ConvertToHashtable $v
                }
                else { $hash[$k] = $v }
            }
        }
        else { $hash = $obj }
        $hash
    }
    # Recurse
    ConvertToHashtable ($json | ConvertFrom-Json)
}
