<p align="center">
    <h1 align="center">✨ConvertFrom-JsonAsHashtable✨</h1>
</p>

<p align="center">
    <a href="readme.md">English</a> |
    <a href="readme.zh-CN.md">简体中文</a> |
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable">Github</a> |
    <a href="https://gitee.com/abgox/ConvertFrom-JsonAsHashtable">
    Gitee</a>
</p>

<p align="center">
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable/blob/main/license">
        <img src="https://img.shields.io/github/license/abgox/ConvertFrom-JsonAsHashtable" alt="license" />
    </a>
    <a href="https://img.shields.io/github/languages/code-size/abgox/ConvertFrom-JsonAsHashtable.svg">
        <img src="https://img.shields.io/github/languages/code-size/abgox/ConvertFrom-JsonAsHashtable.svg" alt="code size" />
    </a>
    <a href="https://img.shields.io/github/repo-size/abgox/ConvertFrom-JsonAsHashtable.svg">
        <img src="https://img.shields.io/github/repo-size/abgox/ConvertFrom-JsonAsHashtable.svg" alt="repo size" />
    </a>
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable">
        <img src="https://img.shields.io/badge/created-2024--5--16-blue" alt="created" />
    </a>
</p>

---
<p align="center">
  <strong>Star ⭐️ or <a href="https://abgox.com/donate">Donate 💰</a> if you like it!</strong>
</p>

## Introduce

- The `ConvertFrom-Json` method does not have the `-AsHashtable` switch in `Windows PowerShell 5.1`, which makes it inconvenient to convert json to hashtable.
- This module is used to solve this problem.
- It will export a `ConvertFrom-JsonAsHashtable` function, like `ConvertFrom-Json -AsHashtable`

## How to Use

1. Install: `Install-Module ConvertFrom-JsonAsHashtable`
2. Import: `Import-Module ConvertFrom-JsonAsHashtable`
3. Example:

   ```powershell
    $jsonString = '{
        "key1": "value1",
        "key2": {
            "subkey1": "subvalue1",
            "subkey2": ["item1", "item2"]
        },
        "key3": [
            {"nestedkey1": "nestedvalue1"},
            {"nestedkey2": "nestedvalue2"}
        ]
    }'

    $jsonString | ConvertFrom-JsonAsHashtable
    ```
