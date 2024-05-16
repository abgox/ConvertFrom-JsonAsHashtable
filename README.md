<p align="center">
    <h1 align="center">✨ConvertFrom-JsonToHashtable✨</h1>
</p>

<p align="center">
    <a href="README.md">English</a> |
    <a href="README-CN.md">简体中文</a> |
    <a href="https://github.com/abgox/ConvertFrom-JsonToHashtable">Github</a> |
    <a href="https://gitee.com/abgox/ConvertFrom-JsonToHashtable">
    Gitee</a>
</p>

<p align="center">
    <a href="https://github.com/abgox/ConvertFrom-JsonToHashtable/blob/main/LICENSE">
        <img src="https://img.shields.io/github/license/abgox/ConvertFrom-JsonToHashtable" alt="license" />
    </a>
    <a href="https://img.shields.io/github/languages/code-size/abgox/ConvertFrom-JsonToHashtable.svg">
        <img src="https://img.shields.io/github/languages/code-size/abgox/ConvertFrom-JsonToHashtable.svg" alt="code size" />
    </a>
    <a href="https://img.shields.io/github/repo-size/abgox/ConvertFrom-JsonToHashtable.svg">
        <img src="https://img.shields.io/github/repo-size/abgox/ConvertFrom-JsonToHashtable.svg" alt="repo size" />
    </a>
    <a href="https://github.com/abgox/ConvertFrom-JsonToHashtable">
        <img src="https://img.shields.io/badge/created-2024--5--16-blue" alt="created" />
    </a>
</p>

---

## Introduce

-   The `ConvertFrom-Json` method does not have the `-AsHashtable` switch in `Windows PowerShell`, which makes it inconvenient to convert json to hashtable.
-   This module is used to solve this problem.

-   It will export a `ConvertFrom-JsonToHashtable` function.
-   It's like `ConvertFrom-Json`, but it converts json directly into a hash table

## How to Use

1. Install: `Install-Module ConvertFrom-JsonToHashtable`
2. Import: `Import-Module ConvertFrom-JsonToHashtable`
3. Example:

    - ```powershell
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

      $jsonString | ConvertFrom-JsonToHashtable
      ```
