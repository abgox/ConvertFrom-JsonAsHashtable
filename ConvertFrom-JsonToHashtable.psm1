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

    function ConvertToHashtable($obj) {
        $hash = @{}
        if ($obj -is [System.Management.Automation.PSCustomObject]) {
            $obj | Get-Member -MemberType Properties | ForEach-Object {
                $k = $_.Name # Key
                $v = $obj.$k # Value
                if ($v -is [System.Collections.IEnumerable] -and $v -isnot [string]) {
                    # Handle array
                    $arr = @()
                    foreach ($item in $v) {
                        $arr += if ($item -is [System.Management.Automation.PSCustomObject]) { ConvertToHashtable($item) }else { $item }
                    }
                    $hash[$k] = $arr
                }
                elseif ($v -is [System.Management.Automation.PSCustomObject]) {
                    # Handle object
                    $hash[$k] = ConvertToHashtable($v)
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
