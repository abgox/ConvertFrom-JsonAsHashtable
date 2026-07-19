<#
.SYNOPSIS
    JSON to Hashtable Conversion for Windows PowerShell 5+, providing functionality similar to 'ConvertFrom-Json -AsHashtable' in PowerShell 7+.

.DESCRIPTION
    Converts JSON text into PowerShell Hashtable.
    Provides functionality similar to 'ConvertFrom-Json -AsHashtable' in PowerShell 7+.

    On PowerShell 7+, this simply delegates to the built-in 'ConvertFrom-Json -AsHashtable'.

    On PowerShell 5.1, this uses a hand-written, ITERATIVE JSON parser.

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

.NOTES
    Number handling: integers that fit in Int32/Int64 are returned as such; anything with a
    decimal point/exponent, or too large for Int64, is returned as Double. This matches the
    general behavior of 'ConvertFrom-Json -AsHashtable' and shares the same precision limits
    for numbers larger than Int64.MaxValue (they become Double and may lose precision).

    Trailing commas and other lenient JSON features are tolerated to match PS7 behavior.

.LINK
    GitHub : https://github.com/abgox/ConvertFrom-JsonAsHashtable
    Gitee  : https://gitee.com/abgox/ConvertFrom-JsonAsHashtable
#>

# Frame type constants — integer comparison is faster than string
$_FT_OBJECT = 0
$_FT_ARRAY = 1

class JsonParserState {
    [string]$Text
    [int]$Pos
    [int]$Len

    JsonParserState([string]$text) {
        $this.Text = $text
        $this.Pos = 0
        $this.Len = $text.Length
    }

    [void] SkipWs() {
        while ($this.Pos -lt $this.Len) {
            $c = $this.Text[$this.Pos]
            if ($c -eq ' ' -or $c -eq "`t" -or $c -eq "`r" -or $c -eq "`n") {
                $this.Pos++
            }
            else { break }
        }
    }

    [char] Peek() {
        if ($this.Pos -ge $this.Len) { throw 'Unexpected end of JSON input.' }
        return $this.Text[$this.Pos]
    }

    [void] Expect([char]$Char) {
        $this.SkipWs()
        if ($this.Pos -ge $this.Len -or $this.Text[$this.Pos] -ne $Char) {
            throw "Expected '$Char' at position $($this.Pos)."
        }
        $this.Pos++
    }

    [string] ParseString() {
        $this.Expect('"')
        $sb = [System.Text.StringBuilder]::new(32)
        while ($true) {
            if ($this.Pos -ge $this.Len) { throw 'Unterminated string in JSON input.' }
            $c = $this.Text[$this.Pos]
            if ($c -eq '"') { $this.Pos++; break }
            elseif ($c -eq '\') {
                $this.Pos++
                if ($this.Pos -ge $this.Len) { throw 'Unterminated escape sequence in JSON string.' }
                $esc = $this.Text[$this.Pos]
                switch ($esc) {
                    '"' { [void]$sb.Append('"'); $this.Pos++ }
                    '\' { [void]$sb.Append('\'); $this.Pos++ }
                    '/' { [void]$sb.Append('/'); $this.Pos++ }
                    'b' { [void]$sb.Append([char]8); $this.Pos++ }
                    'f' { [void]$sb.Append([char]12); $this.Pos++ }
                    'n' { [void]$sb.Append("`n"); $this.Pos++ }
                    'r' { [void]$sb.Append("`r"); $this.Pos++ }
                    't' { [void]$sb.Append("`t"); $this.Pos++ }
                    'u' {
                        if ($this.Pos + 4 -ge $this.Len) { throw 'Invalid unicode escape in JSON string.' }
                        $hex = $this.Text.Substring($this.Pos + 1, 4)
                        $code = [Convert]::ToInt32($hex, 16)
                        [void]$sb.Append([char]$code)
                        $this.Pos += 5
                    }
                    default { throw "Invalid escape sequence '\$esc' in JSON string." }
                }
            }
            else { [void]$sb.Append($c); $this.Pos++ }
        }
        return $sb.ToString()
    }

    [object] ParseNumber() {
        $start = $this.Pos
        $isFloat = $false
        $txt = $this.Text
        $end = $this.Len

        if ($this.Pos -lt $end -and $txt[$this.Pos] -eq '-') { $this.Pos++ }
        if ($this.Pos -lt $end -and $txt[$this.Pos] -eq '.') {
            $isFloat = $true; $this.Pos++
            while ($this.Pos -lt $end -and $txt[$this.Pos] -ge '0' -and $txt[$this.Pos] -le '9') { $this.Pos++ }
        }
        while ($this.Pos -lt $end -and $txt[$this.Pos] -ge '0' -and $txt[$this.Pos] -le '9') { $this.Pos++ }
        if ($this.Pos -lt $end -and $txt[$this.Pos] -eq '.') {
            $isFloat = $true; $this.Pos++
            while ($this.Pos -lt $end -and $txt[$this.Pos] -ge '0' -and $txt[$this.Pos] -le '9') { $this.Pos++ }
        }
        if ($this.Pos -lt $end -and ($txt[$this.Pos] -eq 'e' -or $txt[$this.Pos] -eq 'E')) {
            $isFloat = $true; $this.Pos++
            if ($this.Pos -lt $end -and ($txt[$this.Pos] -eq '+' -or $txt[$this.Pos] -eq '-')) { $this.Pos++ }
            while ($this.Pos -lt $end -and $txt[$this.Pos] -ge '0' -and $txt[$this.Pos] -le '9') { $this.Pos++ }
        }

        $numStr = $txt.Substring($start, $this.Pos - $start)
        if ($numStr.Length -eq 0 -or ($numStr.Length -eq 1 -and $numStr[0] -eq '-')) {
            throw "Invalid number in JSON input near position $start."
        }

        if ($isFloat) {
            return [double]::Parse($numStr, [System.Globalization.CultureInfo]::InvariantCulture)
        }

        $intVal = 0
        if ([int]::TryParse($numStr, [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$intVal)) {
            return $intVal
        }
        $longVal = 0L
        if ([long]::TryParse($numStr, [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$longVal)) {
            return $longVal
        }
        return [double]::Parse($numStr, [System.Globalization.CultureInfo]::InvariantCulture)
    }

    [object] ParseLiteral([string]$Literal, [object]$Value) {
        if ($this.Pos + $Literal.Length -gt $this.Len -or
            $this.Text.Substring($this.Pos, $Literal.Length) -cne $Literal) {
            throw "Invalid literal near position $($this.Pos), expected '$Literal'."
        }
        $this.Pos += $Literal.Length
        return $Value
    }
}

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

        # ---- PowerShell 5.1 path: iterative JSON parser ----

        if ($jsonString.Length -gt 0 -and $jsonString[0] -eq [char]0xFEFF) {
            $jsonString = $jsonString.Substring(1).Trim()
            if (-not $jsonString) { return $null }
        }

        $parser = [JsonParserState]::new($jsonString)
        $stkType = [System.Collections.Generic.List[int]]::new()
        $stkCont = [System.Collections.Generic.List[object]]::new()
        $stkKey = [System.Collections.Generic.List[object]]::new()
        $root = $null
        $haveRoot = $false
        $pLen = $parser.Len

        while (-not $haveRoot) {
            $parser.SkipWs()
            $top = $stkType.Count - 1

            # ---- EOF inside structures (lenient) ----
            if ($parser.Pos -ge $pLen -and $top -ge 0) {
                $topType = $stkType[$top]
                $topCont = $stkCont[$top]
                $hasContent = $topCont.Count -gt 0
                $lastIsComplex = $false
                if ($topType -eq $_FT_ARRAY -and $hasContent) {
                    $le = $topCont[$topCont.Count - 1]
                    $lastIsComplex = $le -is [array] -or $le -is [System.Collections.IList] -or
                    $le -is [hashtable] -or $le -is [System.Collections.IDictionary]
                }
                if ($hasContent -and $lastIsComplex) {
                    while ($stkType.Count -gt 0) {
                        $si = $stkType.Count - 1
                        $sType = $stkType[$si]
                        $sCont = $stkCont[$si]
                        if ($sType -eq $_FT_OBJECT -and $null -ne $stkKey[$si]) {
                            $sCont[$stkKey[$si]] = $null
                        }
                        $stkType.RemoveAt($si); $stkCont.RemoveAt($si); $stkKey.RemoveAt($si)
                        if ($sType -eq $_FT_ARRAY) { $completed = $sCont.ToArray() }
                        else { $completed = $sCont }
                        if ($stkType.Count -gt 0) {
                            $psi = $stkType.Count - 1
                            if ($stkType[$psi] -eq $_FT_ARRAY) { $stkCont[$psi].Add($completed) }
                            else { $stkCont[$psi][$stkKey[$psi]] = $completed; $stkKey[$psi] = $null }
                        }
                        else { $root = $completed; $haveRoot = $true }
                    }
                    break
                }
                else { throw 'Unterminated JSON structure.' }
            }

            # ---- Close bracket/brace or key parsing ----
            if ($top -ge 0) {
                $sType = $stkType[$top]
                $sCont = $stkCont[$top]

                if ($sType -eq $_FT_OBJECT -and $null -eq $stkKey[$top]) {
                    $ch = $parser.Peek()
                    if ($ch -eq '}') {
                        $parser.Pos++
                        $completed = $sCont
                        $stkType.RemoveAt($top); $stkCont.RemoveAt($top); $stkKey.RemoveAt($top)
                        # Inline attach
                        $attaching = $true
                        while ($attaching) {
                            $ai = $stkType.Count - 1
                            if ($ai -lt 0) { $root = $completed; $haveRoot = $true; break }
                            $aType = $stkType[$ai]
                            if ($aType -eq $_FT_ARRAY) { $stkCont[$ai].Add($completed) }
                            else { $stkCont[$ai][$stkKey[$ai]] = $completed; $stkKey[$ai] = $null }
                            $parser.SkipWs()
                            if ($parser.Pos -ge $pLen) {
                                if ($completed -is [array] -or $completed -is [System.Collections.IList] -or
                                    $completed -is [hashtable] -or $completed -is [System.Collections.IDictionary]) {
                                    $root = $completed; $haveRoot = $true; break
                                }
                                throw 'Unterminated JSON structure.'
                            }
                            $cc = if ($aType -eq $_FT_ARRAY) { [char]']' } else { [char]'}' }
                            $pch = $parser.Text[$parser.Pos]
                            if ($pch -eq $cc) {
                                $parser.Pos++
                                $savedCont = $stkCont[$ai]
                                $stkType.RemoveAt($ai); $stkCont.RemoveAt($ai); $stkKey.RemoveAt($ai)
                                if ($aType -eq $_FT_ARRAY) { $completed = $savedCont.ToArray() }
                                else { $completed = $savedCont }
                            }
                            elseif ($pch -eq ',') {
                                $parser.Pos++
                                $parser.SkipWs()
                                if ($parser.Pos -lt $pLen -and $parser.Text[$parser.Pos] -eq $cc) {
                                    $parser.Pos++
                                    $savedCont = $stkCont[$ai]
                                    $stkType.RemoveAt($ai); $stkCont.RemoveAt($ai); $stkKey.RemoveAt($ai)
                                    if ($aType -eq $_FT_ARRAY) { $completed = $savedCont.ToArray() }
                                    else { $completed = $savedCont }
                                }
                                else { $attaching = $false }
                            }
                            else { throw "Expected ',' or '$cc' at position $($parser.Pos)." }
                        }
                        continue
                    }
                    else {
                        if ($ch -eq '"') { $key = $parser.ParseString() }
                        elseif ($ch -eq '-' -or ($ch -ge '0' -and $ch -le '9')) {
                            $key = [string]$parser.ParseNumber()
                        }
                        elseif ($ch -eq 't') { $parser.ParseLiteral('true', $true); $key = 'true' }
                        elseif ($ch -eq 'f') { $parser.ParseLiteral('false', $false); $key = 'false' }
                        elseif ($ch -eq 'n') { $parser.ParseLiteral('null', $null); $key = 'null' }
                        else { throw "Expected string or number key at position $($parser.Pos)." }
                        $parser.SkipWs()
                        $parser.Expect(':')
                        $stkKey[$top] = $key
                    }
                    continue
                }

                if ($sType -eq $_FT_ARRAY) {
                    $ch = $parser.Peek()
                    if ($ch -eq ']') {
                        $parser.Pos++
                        $completed = $sCont.ToArray()
                        $stkType.RemoveAt($top); $stkCont.RemoveAt($top); $stkKey.RemoveAt($top)
                        # Inline attach
                        $attaching = $true
                        while ($attaching) {
                            $ai = $stkType.Count - 1
                            if ($ai -lt 0) { $root = $completed; $haveRoot = $true; break }
                            $aType = $stkType[$ai]
                            if ($aType -eq $_FT_ARRAY) { $stkCont[$ai].Add($completed) }
                            else { $stkCont[$ai][$stkKey[$ai]] = $completed; $stkKey[$ai] = $null }
                            $parser.SkipWs()
                            if ($parser.Pos -ge $pLen) {
                                if ($completed -is [array] -or $completed -is [System.Collections.IList] -or
                                    $completed -is [hashtable] -or $completed -is [System.Collections.IDictionary]) {
                                    $root = $completed; $haveRoot = $true; break
                                }
                                throw 'Unterminated JSON structure.'
                            }
                            $cc = if ($aType -eq $_FT_ARRAY) { [char]']' } else { [char]'}' }
                            $pch = $parser.Text[$parser.Pos]
                            if ($pch -eq $cc) {
                                $parser.Pos++
                                $savedCont = $stkCont[$ai]
                                $stkType.RemoveAt($ai); $stkCont.RemoveAt($ai); $stkKey.RemoveAt($ai)
                                if ($aType -eq $_FT_ARRAY) { $completed = $savedCont.ToArray() }
                                else { $completed = $savedCont }
                            }
                            elseif ($pch -eq ',') {
                                $parser.Pos++
                                $parser.SkipWs()
                                if ($parser.Pos -lt $pLen -and $parser.Text[$parser.Pos] -eq $cc) {
                                    $parser.Pos++
                                    $savedCont = $stkCont[$ai]
                                    $stkType.RemoveAt($ai); $stkCont.RemoveAt($ai); $stkKey.RemoveAt($ai)
                                    if ($aType -eq $_FT_ARRAY) { $completed = $savedCont.ToArray() }
                                    else { $completed = $savedCont }
                                }
                                else { $attaching = $false }
                            }
                            else { throw "Expected ',' or '$cc' at position $($parser.Pos)." }
                        }
                        continue
                    }
                }
            }

            # ---- Parse new value ----
            $ch = $parser.Peek()

            if ($ch -eq '{') {
                $parser.Pos++
                $ht = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
                $stkType.Add($_FT_OBJECT); $stkCont.Add($ht); $stkKey.Add($null)
                continue
            }
            elseif ($ch -eq '[') {
                $parser.Pos++
                $list = [System.Collections.Generic.List[object]]::new()
                $stkType.Add($_FT_ARRAY); $stkCont.Add($list); $stkKey.Add($null)
                continue
            }
            else {
                $inContainer = $top -ge 0
                $isComma = $ch -eq ','
                $isArrayClose = $ch -eq ']' -and $inContainer -and $stkType[$top] -eq $_FT_ARRAY

                if ($isComma -or $isArrayClose) {
                    $value = $null
                }
                else {
                    $value = switch ($ch) {
                        '"' { $parser.ParseString() }
                        't' { $parser.ParseLiteral('true', $true) }
                        'f' { $parser.ParseLiteral('false', $false) }
                        'n' { $parser.ParseLiteral('null', $null) }
                        default {
                            if ($ch -eq '-' -or $ch -eq '.' -or ($ch -ge '0' -and $ch -le '9')) {
                                $parser.ParseNumber()
                            }
                            else { throw "Unexpected character '$ch' at position $($parser.Pos)." }
                        }
                    }
                }

                if (-not $inContainer) {
                    $root = $value
                    $haveRoot = $true
                }
                else {
                    # Inline attach
                    $current = $value
                    $attaching = $true
                    while ($attaching) {
                        $ai = $stkType.Count - 1
                        if ($ai -lt 0) { $root = $current; $haveRoot = $true; break }
                        $aType = $stkType[$ai]
                        if ($aType -eq $_FT_ARRAY) { $stkCont[$ai].Add($current) }
                        else { $stkCont[$ai][$stkKey[$ai]] = $current; $stkKey[$ai] = $null }
                        $parser.SkipWs()
                        if ($parser.Pos -ge $pLen) {
                            if ($current -is [array] -or $current -is [System.Collections.IList] -or
                                $current -is [hashtable] -or $current -is [System.Collections.IDictionary]) { break }
                            throw 'Unterminated JSON structure.'
                        }
                        $cc = if ($aType -eq $_FT_ARRAY) { [char]']' } else { [char]'}' }
                        $pch = $parser.Text[$parser.Pos]
                        if ($pch -eq $cc) {
                            $parser.Pos++
                            $savedCont = $stkCont[$ai]
                            $stkType.RemoveAt($ai); $stkCont.RemoveAt($ai); $stkKey.RemoveAt($ai)
                            if ($aType -eq $_FT_ARRAY) { $current = $savedCont.ToArray() }
                            else { $current = $savedCont }
                        }
                        elseif ($pch -eq ',') {
                            $parser.Pos++
                            $parser.SkipWs()
                            if ($parser.Pos -lt $pLen -and $parser.Text[$parser.Pos] -eq $cc) {
                                $parser.Pos++
                                $savedCont = $stkCont[$ai]
                                $stkType.RemoveAt($ai); $stkCont.RemoveAt($ai); $stkKey.RemoveAt($ai)
                                if ($aType -eq $_FT_ARRAY) { $current = $savedCont.ToArray() }
                                else { $current = $savedCont }
                            }
                            else { $attaching = $false }
                        }
                        else { throw "Expected ',' or '$cc' at position $($parser.Pos)." }
                    }
                }
            }
        }

        if ($stkType.Count -eq 0) {
            $parser.SkipWs()
            if ($parser.Pos -ne $pLen) {
                throw "Unexpected trailing content in JSON input at position $($parser.Pos)."
            }
        }

        return $root
    }
}

Export-ModuleMember -Function ConvertFrom-JsonAsHashtable
