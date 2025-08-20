function ConvertFrom-JsonAsHashtable {
    param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    begin {
        $buffer = [System.Text.StringBuilder]::new()
    }

    process {
        if ($InputObject -is [array]) {
            $null = $buffer.Append(($InputObject -join "`n"))
        }
        else {
            $null = $buffer.Append($InputObject)
        }
    }

    end {
        $jsonString = $buffer.ToString()

        if ($PSVersionTable.PSVersion.Major -ge 7) {
            return $jsonString | ConvertFrom-Json -AsHashtable
        }

        $jsonString = [regex]::Replace($jsonString, '(?<!\\)"\s*"\s*:', {
                param($m)
                '"emptyKey_' + [Guid]::NewGuid() + '":'
            })

        $jsonString = [regex]::Replace($jsonString, ',\s*(?=[}\]]\s*$)', '')

        function ProcessArray {
            param($array)
            $nestedArr = [System.Collections.ArrayList]::new()
            foreach ($item in $array) {
                if ($item -is [System.Collections.IEnumerable] -and $item -isnot [string]) {
                    $null = $nestedArr.Add((ProcessArray $item))
                }
                elseif ($item -is [System.Management.Automation.PSCustomObject]) {
                    $null = $nestedArr.Add((ConvertToHashtable $item))
                }
                else {
                    $null = $nestedArr.Add($item)
                }
            }
            return $nestedArr
        }

        function ConvertToHashtable {
            param($obj)
            if ($obj -is [Array]) {
                return @($obj | ForEach-Object { ConvertToHashtable $_ })
            }
            elseif ($obj -is [PSCustomObject]) {
                $h = @{}
                foreach ($prop in $obj.PSObject.Properties) {
                    $h[$prop.Name] = ConvertToHashtable $prop.Value
                }
                return $h
            }
            else { return $obj }
        }

        ConvertToHashtable ($jsonString | ConvertFrom-Json)
    }
}

Export-ModuleMember -Function ConvertFrom-JsonAsHashtable
