<#
.SYNOPSIS
    Comprehensive test suite for ConvertFrom-JsonAsHashtable module.
.DESCRIPTION
    Tests the iterative JSON parser in PowerShell 5.1 for correctness, edge cases, and performance.
    Run with: pwsh -File test\Comprehensive-Test.ps1  OR  powershell -File test\Comprehensive-Test.ps1
#>

$ErrorActionPreference = 'Stop'
$script:PassCount = 0
$script:FailCount = 0
$script:Tests = @()

function Assert-Equal {
    param(
        [string]$Name,
        [object]$Expected,
        [object]$Actual,
        [string]$Note = ''
    )
    $equal = $false
    if ($null -eq $Expected -and $null -eq $Actual) {
        $equal = $true
    }
    elseif ($null -eq $Expected -or $null -eq $Actual) {
        $equal = $false
    }
    elseif ($Expected -is [hashtable] -and $Actual -is [hashtable]) {
        $equal = $true
        if ($Expected.Count -ne $Actual.Count) { $equal = $false }
        else {
            foreach ($k in $Expected.Keys) {
                if (-not $Actual.ContainsKey($k)) { $equal = $false; break }
                # Deep compare for nested hashtables
                if ($Expected[$k] -is [hashtable] -and $Actual[$k] -is [hashtable]) {
                    if (-not (Compare-HashtableDeep $Expected[$k] $Actual[$k])) { $equal = $false; break }
                }
                elseif ($Expected[$k] -ne $Actual[$k]) { $equal = $false; break }
            }
        }
    }
    elseif ($Expected -is [object[]] -and $Actual -is [object[]]) {
        if ($Expected.Count -ne $Actual.Count) { $equal = $false }
        else {
            $equal = $true
            for ($i = 0; $i -lt $Expected.Count; $i++) {
                if ($Expected[$i] -ne $Actual[$i]) { $equal = $false; break }
            }
        }
    }
    else {
        $equal = $Expected -eq $Actual
    }

    $script:Tests += [PSCustomObject]@{
        Name   = $Name
        Result = if ($equal) { 'PASS' } else { 'FAIL' }
        Note   = $Note
    }

    if ($equal) {
        $script:PassCount++
        Write-Host "  [PASS] $Name" -ForegroundColor Green
    }
    else {
        $script:FailCount++
        $expStr = if ($null -eq $Expected) { '<null>' } elseif ($Expected -is [hashtable]) { '@{...}' } else { $Expected.ToString() }
        $actStr = if ($null -eq $Actual) { '<null>' } elseif ($Actual -is [hashtable]) { '@{...}' } else { $Actual.ToString() }
        Write-Host "  [FAIL] $Name  Expected: $expStr  Got: $actStr" -ForegroundColor Red
        if ($Note) { Write-Host "         $Note" -ForegroundColor Yellow }
    }
}

function Compare-HashtableDeep {
    param([object]$a, [object]$b)
    if ($null -eq $a -and $null -eq $b) { return $true }
    if ($null -eq $a -or $null -eq $b) { return $false }
    if ($a -is [array] -and $b -is [array]) {
        if ($a.Count -ne $b.Count) { return $false }
        for ($i = 0; $i -lt $a.Count; $i++) {
            if (-not (Compare-HashtableDeep $a[$i] $b[$i])) { return $false }
        }
        return $true
    }
    if ($a -is [hashtable] -and $b -is [hashtable]) {
        if ($a.Count -ne $b.Count) { return $false }
        foreach ($k in $a.Keys) {
            if (-not $b.ContainsKey($k)) { return $false }
            if (-not (Compare-HashtableDeep $a[$k] $b[$k])) { return $false }
        }
        return $true
    }
    # For scalars, compare values (ignore type differences between PS versions)
    return $a -eq $b
}

function Assert-Throws {
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock,
        [string]$ExpectedMessage = ''
    )
    try {
        & $ScriptBlock
        $script:Tests += [PSCustomObject]@{ Name = $Name; Result = 'FAIL'; Note = 'Expected exception but none thrown' }
        $script:FailCount++
        Write-Host "  [FAIL] $Name  Expected exception but none thrown" -ForegroundColor Red
    }
    catch {
        $script:Tests += [PSCustomObject]@{ Name = $Name; Result = 'PASS'; Note = '' }
        $script:PassCount++
        Write-Host "  [PASS] $Name  (threw: $($_.Exception.Message))" -ForegroundColor Green
    }
}

function Measure-Perf {
    param(
        [string]$Name,
        [scriptblock]$ScriptBlock,
        [int]$Iterations = 1
    )
    # Warmup
    & $ScriptBlock | Out-Null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i = 0; $i -lt $Iterations; $i++) {
        & $ScriptBlock | Out-Null
    }
    $sw.Stop()
    $avg = [math]::Round($sw.ElapsedMilliseconds / $Iterations, 2)
    Write-Host "  [PERF] $Name  Avg: ${avg}ms  ($Iterations iterations)" -ForegroundColor Cyan
    return $avg
}

# Import module
$modulePath = Join-Path $PSScriptRoot '..\module\ConvertFrom-JsonAsHashtable\ConvertFrom-JsonAsHashtable.psm1'
Import-Module $modulePath -Force

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host ' ConvertFrom-JsonAsHashtable Test Suite' -ForegroundColor Cyan
Write-Host " PS Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ============================================================
# SECTION 1: Basic Types
# ============================================================
Write-Host '--- Section 1: Basic Types ---' -ForegroundColor Yellow

$result = '{"name":"Tom","age":25}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Simple object' @{name = 'Tom'; age = 25 } $result

$result = '"hello"' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Bare string' 'hello' $result

$result = '42' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Integer' 42 $result

$result = '3.14' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Float' 3.14 $result

$result = 'true' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Boolean true' $true $result

$result = 'false' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Boolean false' $false $result

$result = 'null' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Null literal' $null $result

$result = '-5' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Negative integer' -5 $result

$result = '-3.14' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Negative float' -3.14 $result

$result = '0' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Zero integer' 0 $result

# ============================================================
# SECTION 2: Number Handling
# ============================================================
Write-Host "`n--- Section 2: Number Handling ---" -ForegroundColor Yellow

$result = '1e3' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Scientific notation 1e3' 1000.0 $result

$result = '6.022e23' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Scientific notation 6.022e23' 6.022e23 $result

$result = '1.5e-3' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Scientific notation 1.5e-3' 0.0015 $result

$result = '1E+2' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Scientific notation 1E+2' 100.0 $result

# Test integer vs float distinction
$r1 = '100' | ConvertFrom-JsonAsHashtable
$r2 = '100.0' | ConvertFrom-JsonAsHashtable
# PS7 returns Int64 for all integers, PS5.1 returns Int32 for small ones
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Assert-Equal 'Integer 100 is int type' 'Int64' $r1.GetType().Name
}
else {
    Assert-Equal 'Integer 100 is int type' 'Int32' $r1.GetType().Name
}
Assert-Equal 'Float 100.0 is double type' 'Double' $r2.GetType().Name

# Large integers
$result = '9007199254740992' | ConvertFrom-JsonAsHashtable
# This exceeds Int32, should be Int64 or Double
Write-Host "  [INFO] Large int type: $($result.GetType().Name) = $result" -ForegroundColor Cyan

# ============================================================
# SECTION 3: Strings and Escape Sequences
# ============================================================
Write-Host "`n--- Section 3: Strings and Escape Sequences ---" -ForegroundColor Yellow

$result = '{"s":"hello \"world\""}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Escaped quotes' 'hello "world"' $result.s

$result = '{"s":"line1\nline2"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Escaped newline' "line1`nline2" $result.s

$result = '{"s":"tab\there"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Escaped tab' "tab`there" $result.s

$result = '{"s":"back\\slash"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Escaped backslash' 'back\slash' $result.s

$result = '{"s":"slash/here"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Escaped forward slash' 'slash/here' $result.s

$result = '{"s":"\b\f\r"}' | ConvertFrom-JsonAsHashtable
$expected = [char]8 + [char]12 + "`r"
Assert-Equal 'Escaped \\b \\f \\r' $expected $result.s

# Unicode escape
$result = '{"s":"\u0041\u0042\u0043"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Unicode \\u escape' 'ABC' $result.s

# Unicode Chinese via escape
$result = '{"s":"\u4e2d\u6587"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Unicode Chinese \\u4e2d\\u6587' '中文' $result.s

# Literal Chinese in string
$result = '{"s":"中文测试"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Literal Chinese characters' '中文测试' $result.s

# Empty string
$result = '{"key":""}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Empty string value' '' $result.key

# String with spaces
$result = '{"key":"  hello  "}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'String with leading/trailing spaces' '  hello  ' $result.key

# ============================================================
# SECTION 4: Objects
# ============================================================
Write-Host "`n--- Section 4: Objects ---" -ForegroundColor Yellow

# Empty object
$result = '{}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Empty object is hashtable' $true ($result -is [hashtable])
Assert-Equal 'Empty object count 0' 0 $result.Count

# Single key
$result = '{"a":1}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Single key object' @{a = 1 } $result

# Multiple keys
$result = '{"a":1,"b":"two","c":true}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Multi-key object' @{a = 1; b = 'two'; c = $true } $result

# Empty key
$result = '{"":"value"}' | ConvertFrom-JsonAsHashtable
$hasEmptyKey = $result.ContainsKey('')
Assert-Equal 'Empty string key' $true $hasEmptyKey

# Special character keys
$result = '{"key with spaces":1,"key-with-dashes":2,"key.with.dots":3}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Special char keys' 1 $result.'key with spaces'
Assert-Equal 'Dash key' 2 $result.'key-with-dashes'
Assert-Equal 'Dot key' 3 $result.'key.with.dots'

# Unicode keys
$result = '{"键":"值","キー":"バリュー"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Unicode keys' '值' $result.'键'
Assert-Equal 'Japanese keys' 'バリュー' $result.'キー'

# ============================================================
# SECTION 5: Arrays
# ============================================================
Write-Host "`n--- Section 5: Arrays ---" -ForegroundColor Yellow

# Empty array
# Note: PowerShell pipeline unwraps empty arrays, so result may be $null.
# This is a known PowerShell pipeline behavior, not a parser bug.
$result = '[]' | ConvertFrom-JsonAsHashtable
$isNullOrEmptyArray = ($null -eq $result) -or ($result -is [object[]])
Assert-Equal 'Empty array (null or empty object[])' $true $isNullOrEmptyArray
Assert-Equal 'Empty array count 0' 0 $(if ($null -eq $result) { 0 } else { $result.Count })

# Simple array
$result = '[1,2,3]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Simple array' @(1, 2, 3) $result

# Mixed type array
$result = '[1,"two",true,null,3.14]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Mixed array' @(1, 'two', $true, $null, 3.14) $result

# Nested arrays
$result = '[[1,2],[3,4]]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Nested arrays - count' 2 $result.Count
Assert-Equal 'Nested arrays - [0] count' 2 $result[0].Count
Assert-Equal 'Nested arrays - [0][0]' 1 $result[0][0]
Assert-Equal 'Nested arrays - [0][1]' 2 $result[0][1]
Assert-Equal 'Nested arrays - [1][0]' 3 $result[1][0]
Assert-Equal 'Nested arrays - [1][1]' 4 $result[1][1]

# Single element array
$result = '[42]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Single element array' @(42) $result

# ============================================================
# SECTION 6: Nested Structures
# ============================================================
Write-Host "`n--- Section 6: Nested Structures ---" -ForegroundColor Yellow

# Object in array
$result = '[{"a":1},{"b":2}]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Object in array' 1 $result[0].a
Assert-Equal 'Object in array 2' 2 $result[1].b

# Array in object
$result = '{"arr":[1,2,3]}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Array in object' @(1, 2, 3) $result.arr

# Deep nesting
$deepJson = '{"a":{"b":{"c":{"d":{"e":"deep"}}}}}'
$result = $deepJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'Deep nesting 5 levels' 'deep' $result.a.b.c.d.e

# Complex nested structure
$complexJson = '{"users":[{"name":"Alice","tags":["admin","user"]},{"name":"Bob","tags":["user"]}]}'
$result = $complexJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'Complex nested - first user' 'Alice' $result.users[0].name
Assert-Equal 'Complex nested - tags' @('admin', 'user') $result.users[0].tags
Assert-Equal 'Complex nested - second user' 'Bob' $result.users[1].name

# ============================================================
# SECTION 7: Trailing Commas
# ============================================================
Write-Host "`n--- Section 7: Trailing Commas ---" -ForegroundColor Yellow

$result = '{"a":1,}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Trailing comma in object' @{a = 1 } $result

$result = '[1,2,]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Trailing comma in array' @(1, 2) $result

$result = '{"a":{"b":2,},}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Nested trailing commas' @{a = @{b = 2 } } $result

$result = '[1,[2,3,],]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Trailing comma nested arrays - count' 2 $result.Count
Assert-Equal 'Trailing comma nested arrays - [0]' 1 $result[0]
Assert-Equal 'Trailing comma nested arrays - [1] count' 2 $result[1].Count
Assert-Equal 'Trailing comma nested arrays - [1][0]' 2 $result[1][0]
Assert-Equal 'Trailing comma nested arrays - [1][1]' 3 $result[1][1]

# Multiple trailing commas? No, JSON doesn't support that
# '{"a":1,,}'  should fail

# ============================================================
# SECTION 8: Whitespace Handling
# ============================================================
Write-Host "`n--- Section 8: Whitespace Handling ---" -ForegroundColor Yellow

$spacedJson = '  {  "a"  :  1  ,  "b"  :  2  }  '
$result = $spacedJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'Heavy whitespace' @{a = 1; b = 2 } $result

$tabJson = "`t{`t`"a`":`t1`n,`n`"b`":`r2`r}`t"
$result = $tabJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'Tabs and newlines' @{a = 1; b = 2 } $result

# ============================================================
# SECTION 9: BOM Handling
# ============================================================
Write-Host "`n--- Section 9: BOM Handling ---" -ForegroundColor Yellow

# BOM character constructed dynamically
$bomChar = [string][char]0xFEFF
$bomJson = $bomChar + '{"a":1}'

if ($PSVersionTable.PSVersion.Major -ge 7) {
    # PS7: BOM is rejected (consistent with native ConvertFrom-Json)
    Assert-Throws 'BOM rejected on PS7' { $bomJson | ConvertFrom-JsonAsHashtable }
}
else {
    # PS5.1: BOM is stripped and parsed (our parser handles it)
    $result = $bomJson | ConvertFrom-JsonAsHashtable
    Assert-Equal 'BOM stripped on PS5.1' @{a = 1 } $result
}

# ============================================================
# SECTION 10: Error Cases
# ============================================================
Write-Host "`n--- Section 10: Error Cases ---" -ForegroundColor Yellow

# Empty/whitespace input returns null (graceful, not an error)
$result = '' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Empty string returns null' $null $result

$result = $null | ConvertFrom-JsonAsHashtable
Assert-Equal 'Null input returns null' $null $result

$result = '   ' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Whitespace only returns null' $null $result

Assert-Throws 'Invalid JSON - bare word' { 'abc' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Invalid JSON - missing close brace' { '{"a":1' | ConvertFrom-JsonAsHashtable }
# PS7 accepts missing close bracket (returns partial array), PS5.1 rejects
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $result = '[1,2' | ConvertFrom-JsonAsHashtable
    Assert-Equal 'Invalid JSON - missing close bracket (PS7 lenient)' 2 $result.Count
}
else {
    Assert-Throws 'Invalid JSON - missing close bracket' { '[1,2' | ConvertFrom-JsonAsHashtable }
}
Assert-Throws 'Invalid JSON - trailing content' { '{} extra' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Invalid JSON - unexpected comma' { '{,}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Invalid JSON - missing colon' { '{"a" 1}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Invalid JSON - unmatched brace' { '{' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Invalid JSON - unmatched bracket' { '[' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 11: Type Preservation
# ============================================================
Write-Host "`n--- Section 11: Type Preservation ---" -ForegroundColor Yellow

$result = '{"a":1,"b":2.5,"c":true,"d":false,"e":null,"f":"str"}' | ConvertFrom-JsonAsHashtable
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Assert-Equal 'Int type' 'Int64' $result.a.GetType().Name
}
else {
    Assert-Equal 'Int type' 'Int32' $result.a.GetType().Name
}
Assert-Equal 'Double type' 'Double' $result.b.GetType().Name
Assert-Equal 'Bool true type' 'Boolean' $result.c.GetType().Name
Assert-Equal 'Null type' $null $result.e
Assert-Equal 'String type' 'String' $result.f.GetType().Name

# ============================================================
# SECTION 12: Case Sensitivity
# ============================================================
Write-Host "`n--- Section 12: Case Sensitivity ---" -ForegroundColor Yellow

$result = '{"Key":"value","key":"other","KEY":"third"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Case sensitive keys - Count 3' 3 $result.Count
Assert-Equal "Case sensitive - 'Key'" 'value' $result.Key
Assert-Equal "Case sensitive - 'key'" 'other' $result.key
Assert-Equal "Case sensitive - 'KEY'" 'third' $result.KEY

# ============================================================
# SECTION 13: Pipeline Usage
# ============================================================
Write-Host "`n--- Section 13: Pipeline Usage ---" -ForegroundColor Yellow

# Pipeline with multiple lines forming a single JSON structure
$lines = @('{', '"a":1,', '"b":2', '}')
$result = $lines | ConvertFrom-JsonAsHashtable
Assert-Equal 'Pipeline array input (single JSON)' @{a = 1; b = 2 } $result

# Multiple separate JSON objects in pipeline are invalid (joined by newline)
# This tests that the parser correctly rejects concatenated JSON
$separate = @('{"a":1}', '{"b":2}')
Assert-Throws 'Separate JSON objects in pipeline' { $separate | ConvertFrom-JsonAsHashtable }

# Single pipeline string
$result = '{"x":10}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Pipeline string' @{x = 10 } $result

# ============================================================
# SECTION 14: Real-world JSON Test Cases
# ============================================================
Write-Host "`n--- Section 14: Real-world JSON ---" -ForegroundColor Yellow

# API response
$apiJson = '{"status":200,"data":{"users":[{"id":1,"name":"Alice","active":true},{"id":2,"name":"Bob","active":false}],"total":2},"message":"ok"}'
$result = $apiJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'API response - status' 200 $result.status
Assert-Equal 'API response - user count' 2 $result.data.users.Count
Assert-Equal 'API response - first user' 'Alice' $result.data.users[0].name
Assert-Equal 'API response - active' $true $result.data.users[0].active
Assert-Equal 'API response - inactive' $false $result.data.users[1].active

# Config file
$configJson = '{"server":{"host":"localhost","port":8080,"ssl":false},"database":{"host":"db.example.com","port":5432,"name":"mydb","credentials":{"user":"admin","password":"s3cret"}},"features":["logging","caching","auth"]}'
$result = $configJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'Config - server host' 'localhost' $result.server.host
Assert-Equal 'Config - server port' 8080 $result.server.port
Assert-Equal 'Config - db port' 5432 $result.database.port
Assert-Equal 'Config - deep nested' 'admin' $result.database.credentials.user
Assert-Equal 'Config - features' @('logging', 'caching', 'auth') $result.features

# ============================================================
# SECTION 15: Duplicate Keys
# ============================================================
Write-Host "`n--- Section 15: Duplicate Keys ---" -ForegroundColor Yellow

$result = '{"key":"first","key":"last"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Duplicate key - last wins' 'last' $result.key

# ============================================================
# SECTION 16: Large Input Test
# ============================================================
Write-Host "`n--- Section 16: Large Input ---" -ForegroundColor Yellow

# Generate large JSON with many keys
$largeObj = @{}
for ($i = 0; $i -lt 1000; $i++) {
    $largeObj["key_$i"] = $i
}
$largeJson = $largeObj | ConvertTo-Json -Compress
$result = $largeJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'Large object - key count' 1000 $result.Count
Assert-Equal 'Large object - last key value' 999 $result.key_999

# Large array
$largeArr = @(1..1000) | ForEach-Object { @{ id = $_; value = "item_$_" } }
$largeArrJson = $largeArr | ConvertTo-Json -Compress -Depth 3
$result = $largeArrJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'Large array - count' 1000 $result.Count
Assert-Equal 'Large array - last item' 1000 $result[999].id

# ============================================================
# SECTION 17: Deeply Nested (Stack Overflow Test)
# ============================================================
Write-Host "`n--- Section 17: Deeply Nested ---" -ForegroundColor Yellow

# Build deeply nested JSON (100 levels)
$depth = 100
$deepJson = ''
for ($i = 0; $i -lt $depth; $i++) { $deepJson += '{"a":' }
$deepJson += '"deep"'
for ($i = 0; $i -lt $depth; $i++) { $deepJson += '}' }

$result = $deepJson | ConvertFrom-JsonAsHashtable
# Navigate to the deepest level
$current = $result
for ($i = 0; $i -lt $depth; $i++) { $current = $current.a }
Assert-Equal '100 levels deep' 'deep' $current

# ============================================================
# SECTION 18: Edge Cases with Empty Containers
# ============================================================
Write-Host "`n--- Section 18: Empty Container Edge Cases ---" -ForegroundColor Yellow

$result = '{"a":{},"b":[],"c":""}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Empty object value' $true ($result.a -is [hashtable])
Assert-Equal 'Empty object count' 0 $result.a.Count
Assert-Equal 'Empty array value' $true ($result.b -is [object[]])
Assert-Equal 'Empty array count' 0 $result.b.Count
Assert-Equal 'Empty string value' '' $result.c

$result = '[{},[],"",null]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Array with empty containers - obj' 0 $result[0].Count
Assert-Equal 'Array with empty containers - arr' 0 $result[1].Count
Assert-Equal 'Array with empty containers - str' '' $result[2]
Assert-Equal 'Array with empty containers - null' $null $result[3]

# ============================================================
# SECTION 19: JSON Null vs Missing
# ============================================================
Write-Host "`n--- Section 19: JSON Null Handling ---" -ForegroundColor Yellow

$result = '{"a":null,"b":1}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Null value exists in hashtable' $true $result.ContainsKey('a')
Assert-Equal 'Null value is null' $null $result.a
Assert-Equal 'Non-null value' 1 $result.b

# ============================================================
# SECTION 20: String Boundary Cases
# ============================================================
Write-Host "`n--- Section 20: String Edge Cases ---" -ForegroundColor Yellow

# Very long string
$longStr = 'x' * 10000
$longJson = '{"s":"' + $longStr + '"}'
$result = $longJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'Long string length' 10000 $result.s.Length

# String with all escape types
$escJson = '{"s":"\\\"\b\f\n\r\t\u0041"}'
$result = $escJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'All escapes' ([char]92 + '"' + [char]8 + [char]12 + "`n`r`tA") $result.s

# ============================================================
# SECTION 21: Invalid Escape Sequences
# ============================================================
Write-Host "`n--- Section 21: Invalid Escape Sequences ---" -ForegroundColor Yellow

Assert-Throws 'Invalid escape \x' { '{"s":"\x41"}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Invalid escape \a' { '{"s":"\a"}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Invalid escape \c' { '{"s":"\c"}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Invalid escape \0' { '{"s":"\0"}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Invalid escape \p' { '{"s":"\p"}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Backslash at end of string' { '{"s":"\"}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Backslash at end of input' { '"\' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 22: Invalid Number Formats
# ============================================================
Write-Host "`n--- Section 22: Invalid Number Formats ---" -ForegroundColor Yellow

# Leading zeros - invalid JSON but parser accepts silently (matches PS7 behavior)
$result = '01' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Leading zero 01' 1 $result

$result = '007' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Leading zeros 007' 7 $result

# Negative zero
$result = '-0' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Negative zero -0' 0 $result

# Numbers with trailing dot - accepted as float 1.0 (lenient behavior)
$result = '1.' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Trailing dot 1.' 'Double' $result.GetType().Name

# Numbers with leading dot (no integer part) - accepted in lenient mode (matches PS7)
$result = '.5' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Leading dot .5 value' 0.5 $result
Assert-Equal 'Leading dot .5 type' 'Double' $result.GetType().Name

# Exponent without digits
Assert-Throws 'Exponent no digits 1e' { '1e' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Exponent no digits 1e+' { '1e+' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Exponent no digits 1E-' { '1E-' | ConvertFrom-JsonAsHashtable }

# Just a minus sign
Assert-Throws 'Just minus -' { '-' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 23: Unicode Surrogate Pairs and Edge Cases
# ============================================================
Write-Host "`n--- Section 23: Unicode Edge Cases ---" -ForegroundColor Yellow

# Emoji via literal character
$result = '{"s":"hello 😊"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Emoji in string' 'hello 😊' $result.s

# Unicode escapes with non-hex characters
Assert-Throws 'Unicode escape non-hex \uGGGG' { '{"s":"\uGGGG"}' | ConvertFrom-JsonAsHashtable }

# Valid unicode escapes at boundary values
$result = '{"s":"\u0000"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Unicode null \u0000' ([char]0) $result.s

$result = '{"s":"\uffff"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Unicode \uFFFF' ([char]0xFFFF) $result.s

# ============================================================
# SECTION 24: Invalid Object/Array Syntax
# ============================================================
Write-Host "`n--- Section 24: Invalid Object/Array Syntax ---" -ForegroundColor Yellow

# Non-string keys accepted in lenient mode (matches PS7)
$result = '{1:"val"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Non-string key {1:val}' 'val' $result.'1'
Assert-Throws 'Double colon {a::1}' { '{"a"::1}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Multiple commas {a:1,,b:2}' { '{"a":1,,"b":2}' | ConvertFrom-JsonAsHashtable }
# Array holes accepted in lenient mode - empty slots become null (matches PS7)
$result = '[1,,3]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Array holes [1,,3] count' 3 $result.Count
Assert-Throws 'Colon without key {:1}' { '{:1}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Missing value {a:}' { '{"a":}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Extra close {}}' { '{}}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Extra close {]}' { '{]}' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 25: Escaped Characters in Keys
# ============================================================
Write-Host "`n--- Section 25: Escaped Characters in Keys ---" -ForegroundColor Yellow

$result = '{"key\nwith\nnewlines": 1}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Newline in key' 1 $result."key`nwith`nnewlines"

$result = '{"key\twith\ttabs": 2}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Tab in key' 2 $result."key`twith`ttabs"

$result = '{"key\"with\"quotes": 3}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Quotes in key' 3 $result.'key"with"quotes'

# ============================================================
# SECTION 26: Deeply Nested Empty Containers
# ============================================================
Write-Host "`n--- Section 26: Deeply Nested Empty Containers ---" -ForegroundColor Yellow

$result = '[{},[],[[]]]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Nested empty - [0] count' 0 $result[0].Count
Assert-Equal 'Nested empty - [1] count' 0 $result[1].Count
# [2] is [[]] - an array containing an empty array; pipeline may unwrap inner empty array
Assert-Equal 'Nested empty - [2] is array' $true ($result[2] -is [object[]])

$result = '{"a":{"b":{"c":{}}}}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Nested empty objects depth 3' 0 $result.a.b.c.Count

# ============================================================
# SECTION 27: Complex Mixed Nesting
# ============================================================
Write-Host "`n--- Section 27: Complex Mixed Nesting ---" -ForegroundColor Yellow

$complex = '{"a":[{"b":1},[2,3],{"c":{"d":[4,5]}}]}'
$result = $complex | ConvertFrom-JsonAsHashtable
Assert-Equal 'Complex mixed - a[0].b' 1 $result.a[0].b
Assert-Equal 'Complex mixed - a[1][0]' 2 $result.a[1][0]
Assert-Equal 'Complex mixed - a[1][1]' 3 $result.a[1][1]
Assert-Equal 'Complex mixed - a[2].c.d[0]' 4 $result.a[2].c.d[0]
Assert-Equal 'Complex mixed - a[2].c.d[1]' 5 $result.a[2].c.d[1]

# ============================================================
# SECTION 28: Input Variations
# ============================================================
Write-Host "`n--- Section 28: Input Variations ---" -ForegroundColor Yellow

# Direct parameter (not pipeline)
$result = ConvertFrom-JsonAsHashtable -InputObject '{"direct":true}'
Assert-Equal 'Direct parameter' $true $result.direct

# Empty pipeline (no input)
$result = @() | ConvertFrom-JsonAsHashtable
Assert-Equal 'Empty pipeline' $null $result

# Single-line JSON with no newlines
$result = '{"compact":1}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Compact JSON' 1 $result.compact

# JSON with only whitespace and content
$result = "`n  `r  `t{`n  `t`"a`": 1`n  `t}`n  " | ConvertFrom-JsonAsHashtable
Assert-Equal 'JSON with all whitespace types' @{a = 1 } $result

# ============================================================
# SECTION 29: Large Number Edge Cases
# ============================================================
Write-Host "`n--- Section 29: Large Number Edge Cases ---" -ForegroundColor Yellow

# Int32 max
$result = '2147483647' | ConvertFrom-JsonAsHashtable
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Assert-Equal 'Int32 max' 'Int64' $result.GetType().Name
}
else {
    Assert-Equal 'Int32 max' 'Int32' $result.GetType().Name
}

# Int32 overflow -> Int64
$result = '2147483648' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Int32 overflow -> Int64' 'Int64' $result.GetType().Name

# Int64 max
$result = '9223372036854775807' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Int64 max' 'Int64' $result.GetType().Name

# Int64 overflow -> Double (PS5.1) or BigInteger (PS7)
$result = '9223372036854775808' | ConvertFrom-JsonAsHashtable
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Assert-Equal 'Int64 overflow -> BigInteger' 'BigInteger' $result.GetType().Name
}
else {
    Assert-Equal 'Int64 overflow -> Double' 'Double' $result.GetType().Name
}

# Int32 min
$result = '-2147483648' | ConvertFrom-JsonAsHashtable
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Assert-Equal 'Int32 min' 'Int64' $result.GetType().Name
}
else {
    Assert-Equal 'Int32 min' 'Int32' $result.GetType().Name
}

# Int64 min
$result = '-9223372036854775808' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Int64 min' 'Int64' $result.GetType().Name

# Zero with exponent
$result = '0e0' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Zero with exponent 0e0' 0.0 $result

# ============================================================
# SECTION 30: String with Only Whitespace
# ============================================================
Write-Host "`n--- Section 30: Whitespace-Only Strings ---" -ForegroundColor Yellow

$result = '{"s":""}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Empty string' '' $result.s

$result = '{"s":" "}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Space string' ' ' $result.s

$result = '{"s":"  "}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Multiple spaces' '  ' $result.s

# ============================================================
# SECTION 31: Literal Case Sensitivity
# ============================================================
Write-Host "`n--- Section 31: Literal Case Sensitivity ---" -ForegroundColor Yellow

# JSON literals must be lowercase per RFC 8259 / PS7 behavior
Assert-Throws 'True (capital T)' { 'True' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'False (capital F)' { 'False' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Null (capital N)' { 'Null' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'TRUE (all caps)' { 'TRUE' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'FALSE (all caps)' { 'FALSE' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'NULL (all caps)' { 'NULL' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 32: Partial Literals
# ============================================================
Write-Host "`n--- Section 32: Partial Literals ---" -ForegroundColor Yellow

Assert-Throws 'tru (incomplete true)' { 'tru' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'fals (incomplete false)' { 'fals' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'nul (incomplete null)' { 'nul' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'truth (extra chars)' { 'truth' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'falsehood (extra chars)' { 'falsehood' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'nullable (extra chars)' { 'nullable' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 33: Missing Commas
# ============================================================
Write-Host "`n--- Section 33: Missing Commas ---" -ForegroundColor Yellow

Assert-Throws 'Missing comma between object props' { '{"a":1 "b":2}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Missing comma between array elements' { '[1 "two"]' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Missing comma between array and object' { '[1 {"a":1}]' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Missing comma between objects in array' { '[{} {}]' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 34: Trailing Comma then EOF
# ============================================================
Write-Host "`n--- Section 34: Trailing Comma Then EOF ---" -ForegroundColor Yellow

Assert-Throws 'Array trailing comma then EOF [1,' { '[1,' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Object trailing comma then EOF {a:1,' { '{"a":1,' | ConvertFrom-JsonAsHashtable }
# Nested trailing comma then EOF - accepted in lenient mode (matches PS7)
# PS7 returns [1] (single-element array), not scalar 1
$result = '[[1],' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Nested trailing comma then EOF count' 1 $result.Count

# ============================================================
# SECTION 35: Leading Commas
# ============================================================
Write-Host "`n--- Section 35: Leading Commas ---" -ForegroundColor Yellow

Assert-Throws 'Leading comma in object' { '{,"a":1}' | ConvertFrom-JsonAsHashtable }

# Leading comma in array - accepted, creates null element (matches PS7)
$result = '[,1]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Leading comma in array count' 2 $result.Count

# ============================================================
# SECTION 36: Unicode Escapes Producing Special Characters
# ============================================================
Write-Host "`n--- Section 36: Unicode Escapes Producing Special Characters ---" -ForegroundColor Yellow

$result = '{"s":"\u0022"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Unicode escape produces quote' '"' $result.s

$result = '{"s":"\u005C"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Unicode escape produces backslash' '\' $result.s

$result = '{"s":"\u000A"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Unicode escape produces newline' "`n" $result.s

$result = '{"s":"\u0009"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Unicode escape produces tab' "`t" $result.s

# ============================================================
# SECTION 37: Number with Exponent and Decimal Combined
# ============================================================
Write-Host "`n--- Section 37: Number with Exponent + Decimal ---" -ForegroundColor Yellow

$result = '1.5e2' | ConvertFrom-JsonAsHashtable
Assert-Equal '1.5e2 = 150.0' 150.0 $result

$result = '1.5E2' | ConvertFrom-JsonAsHashtable
Assert-Equal '1.5E2 = 150.0' 150.0 $result

$result = '3.14e-2' | ConvertFrom-JsonAsHashtable
Assert-Equal '3.14e-2 = 0.0314' 0.0314 $result

$result = '2.5e+3' | ConvertFrom-JsonAsHashtable
Assert-Equal '2.5e+3 = 2500.0' 2500.0 $result

$result = '-1.5e2' | ConvertFrom-JsonAsHashtable
Assert-Equal '-1.5e2 value' -150 $result
Assert-Equal '-1.5e2 is float' 'Double' $result.GetType().Name

# ============================================================
# SECTION 38: Trailing Content After Valid JSON
# ============================================================
Write-Host "`n--- Section 38: Trailing Content After Valid JSON ---" -ForegroundColor Yellow

Assert-Throws 'Trailing after null' { 'null extra' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Trailing after true' { 'true extra' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Trailing after false' { 'false extra' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Trailing after number' { '42 extra' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Trailing after string' { '"hello" extra' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Trailing after array' { '[1,2] extra' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Trailing after object' { '{"a":1} extra' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 39: Pipeline with Non-String Input
# ============================================================
Write-Host "`n--- Section 39: Pipeline with Non-String Input ---" -ForegroundColor Yellow

$result = 42 | ConvertFrom-JsonAsHashtable
Assert-Equal 'Integer in pipeline' 42 $result

# Boolean $true converts to string "True" (capital T) which is not valid JSON
Assert-Throws 'Boolean in pipeline (invalid JSON)' { $true | ConvertFrom-JsonAsHashtable }

$result = $null | ConvertFrom-JsonAsHashtable
Assert-Equal 'Null in pipeline' $null $result

# Pipeline with array of integers - PowerShell expands array, each element goes through process separately
# Buffer becomes "1\n2\n3" which is not valid JSON
Assert-Throws 'Array of integers in pipeline (invalid JSON)' { @(1, 2, 3) | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 40: BOM Edge Cases
# ============================================================
Write-Host "`n--- Section 40: BOM Edge Cases ---" -ForegroundColor Yellow

$bomChar = [string][char]0xFEFF

if ($PSVersionTable.PSVersion.Major -ge 7) {
    # PS7: BOM is rejected (consistent with native ConvertFrom-Json)
    Assert-Throws 'BOM + whitespace rejected on PS7' { ($bomChar + '  {"a":1}  ') | ConvertFrom-JsonAsHashtable }
    Assert-Throws 'BOM + null rejected on PS7' { ($bomChar + 'null') | ConvertFrom-JsonAsHashtable }
}
else {
    # PS5.1: BOM is stripped and parsed
    $bomWsJson = $bomChar + '  {"a":1}  '
    $result = $bomWsJson | ConvertFrom-JsonAsHashtable
    Assert-Equal 'BOM + whitespace' @{a = 1 } $result

    $bomNullJson = $bomChar + 'null'
    $result = $bomNullJson | ConvertFrom-JsonAsHashtable
    Assert-Equal 'BOM + null' $null $result
}

# ============================================================
# SECTION 41: Strings with Escape Sequences Only
# ============================================================
Write-Host "`n--- Section 41: Strings with Only Escapes ---" -ForegroundColor Yellow

$result = '{"s":"\n"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'String with only newline' "`n" $result.s

$result = '{"s":"\t"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'String with only tab' "`t" $result.s

$result = '{"s":"\r"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'String with only CR' "`r" $result.s

$result = '{"s":"\\\\"}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'String with only backslash' '\\' $result.s

$result = '{"s":"\""}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'String with only quote' '"' $result.s

# ============================================================
# SECTION 42: Multiple Top-Level Values (should fail)
# ============================================================
Write-Host "`n--- Section 42: Multiple Top-Level Values ---" -ForegroundColor Yellow

Assert-Throws 'Two nulls' { 'null null' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Two objects' { '{"a":1} {"b":2}' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Two arrays' { '[1] [2]' | ConvertFrom-JsonAsHashtable }
Assert-Throws 'Null then object' { 'null {"a":1}' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 43: Object with Missing Value for Key
# ============================================================
Write-Host "`n--- Section 43: Object Edge Cases ---" -ForegroundColor Yellow

Assert-Throws 'Key then nothing {a:}' { '{"a":}' | ConvertFrom-JsonAsHashtable }

# Key then comma - accepted, value becomes null (matches PS7)
$result = '{"a":,}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Key then comma {a:,}' $null $result.a

Assert-Throws 'Key then close {a:}}' { '{"a":}}' | ConvertFrom-JsonAsHashtable }

# ============================================================
# SECTION 44: Array Edge Cases
# ============================================================
Write-Host "`n--- Section 44: Array Edge Cases ---" -ForegroundColor Yellow

# Consecutive commas - accepted, empty slots become null (matches PS7)
$result = '[1,,]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Double comma in array [1,,] count' 2 $result.Count

# Leading double comma - accepted (matches PS7)
$result = '[,1]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Leading double comma [,1] count' 2 $result.Count

# Triple comma - accepted (matches PS7)
$result = '[1,,,]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Triple comma [1,,,] count' 3 $result.Count

# ============================================================
# SECTION 45: Mixed Line Endings
# ============================================================
Write-Host "`n--- Section 45: Mixed Line Endings ---" -ForegroundColor Yellow

# JSON with only CR (no LF)
$crJson = "{`r`"a`":1,`r`"b`":2}"
$result = $crJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'CR only line endings' @{a = 1; b = 2 } $result

# JSON with mixed CR+LF
$crlfJson = "{`r`n`"a`":1,`r`n`"b`":2}"
$result = $crlfJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'CRLF line endings' @{a = 1; b = 2 } $result

# JSON with LF only
$lfJson = "{`n`"a`":1,`n`"b`":2}"
$result = $lfJson | ConvertFrom-JsonAsHashtable
Assert-Equal 'LF only line endings' @{a = 1; b = 2 } $result

# ============================================================
# SECTION 46: Whitespace in Significant Positions
# ============================================================
Write-Host "`n--- Section 46: Whitespace in Significant Positions ---" -ForegroundColor Yellow

# Whitespace between key and colon
$result = '{"a" :1}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Whitespace before colon' 1 $result.a

# Whitespace between colon and value
$result = '{"a": 1}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Whitespace after colon' 1 $result.a

# Whitespace around comma
$result = '{"a": 1 , "b": 2}' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Whitespace around comma' @{a = 1; b = 2 } $result

# Whitespace inside empty object
$result = '{  }' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Whitespace in empty object' @{} $result

# Whitespace inside empty array
$result = '[  ]' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Whitespace in empty array' $true (($null -eq $result) -or ($result -is [object[]]))

# ============================================================
# SECTION 47: Single Values (not wrapped in container)
# ============================================================
Write-Host "`n--- Section 47: Single Values ---" -ForegroundColor Yellow

$result = 'null' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Top-level null' $null $result

$result = 'true' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Top-level true' $true $result

$result = 'false' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Top-level false' $false $result

$result = '42' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Top-level number' 42 $result

$result = '-3.14' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Top-level negative float' -3.14 $result

$result = '"hello"' | ConvertFrom-JsonAsHashtable
Assert-Equal 'Top-level string' 'hello' $result

# ============================================================
# SECTION 22: Performance Benchmarks
# ============================================================
Write-Host "`n--- Section 22: Performance Benchmarks ---" -ForegroundColor Yellow

# Small JSON
$smallJson = '{"name":"test","value":42}'
Measure-Perf 'Small JSON (30 bytes)' { $smallJson | ConvertFrom-JsonAsHashtable } -Iterations 1000 | Out-Null

# Medium JSON
$mediumObj = @{}
for ($i = 0; $i -lt 100; $i++) { $mediumObj["key_$i"] = "value_$i" }
$mediumJson = $mediumObj | ConvertTo-Json -Compress
$mediumSize = $mediumJson.Length
Measure-Perf "Medium JSON (~$mediumSize bytes, 100 keys)" { $mediumJson | ConvertFrom-JsonAsHashtable } -Iterations 100 | Out-Null

# Large JSON
$largePerfObj = @{}
for ($i = 0; $i -lt 1000; $i++) { $largePerfObj["key_$i"] = "value_$i" }
$largePerfJson = $largePerfObj | ConvertTo-Json -Compress
$largePerfSize = $largePerfJson.Length
Measure-Perf "Large JSON (~$largePerfSize bytes, 1000 keys)" { $largePerfJson | ConvertFrom-JsonAsHashtable } -Iterations 10 | Out-Null

# Deep nesting
$deepPerfJson = ''
for ($i = 0; $i -lt 50; $i++) { $deepPerfJson += '{"a":' }
$deepPerfJson += '"leaf"'
for ($i = 0; $i -lt 50; $i++) { $deepPerfJson += '}' }
Measure-Perf 'Deep nesting (50 levels)' { $deepPerfJson | ConvertFrom-JsonAsHashtable } -Iterations 100 | Out-Null

# Wide array
$wideArrJson = '[' + ((1..5000) -join ',') + ']'
Measure-Perf 'Wide array (5000 elements)' { $wideArrJson | ConvertFrom-JsonAsHashtable } -Iterations 10 | Out-Null

# ============================================================
# SUMMARY
# ============================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host ' Test Summary' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "  Total:  $($script:PassCount + $script:FailCount)" -ForegroundColor White
Write-Host "  Passed: $($script:PassCount)" -ForegroundColor Green
Write-Host "  Failed: $($script:FailCount)" -ForegroundColor $(if ($script:FailCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "========================================`n" -ForegroundColor Cyan

if ($script:FailCount -gt 0) {
    Write-Host 'Failed tests:' -ForegroundColor Red
    $script:Tests | Where-Object { $_.Result -eq 'FAIL' } | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Red
    }
    exit 1
}
else {
    Write-Host 'All tests passed!' -ForegroundColor Green
    exit 0
}
