<p align="center">
    <h1 align="center">✨ConvertFrom-JsonAsHashtable✨</h1>
</p>

<p align="center">
    <a href="readme.zh-CN.md">简体中文</a> |
    <a href="readme.md">English</a> |
    <a href="https://www.powershellgallery.com/packages/ConvertFrom-JsonAsHashtable">Powershell Gallery</a> |
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable">Github</a> |
    <a href="https://gitee.com/abgox/ConvertFrom-JsonAsHashtable">
    Gitee</a>
</p>

<p align="center">
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable/blob/main/license">
        <img src="https://img.shields.io/github/license/abgox/ConvertFrom-JsonAsHashtable" alt="license" />
    </a>
    <a href="https://www.powershellgallery.com/packages/ConvertFrom-JsonAsHashtable">
        <img src="https://img.shields.io/powershellgallery/v/ConvertFrom-JsonAsHashtable?label=version" alt="version" />
    </a>
    <a href="https://www.powershellgallery.com/packages/ConvertFrom-JsonAsHashtable">
        <img src="https://img.shields.io/powershellgallery/dt/ConvertFrom-JsonAsHashtable" alt="PowerShell Gallery" />
    </a>
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable">
        <img src="https://img.shields.io/github/languages/code-size/abgox/ConvertFrom-JsonAsHashtable" alt="code size" />
    </a>
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable">
        <img src="https://img.shields.io/github/repo-size/abgox/ConvertFrom-JsonAsHashtable" alt="repo size" />
    </a>
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable">
        <img src="https://img.shields.io/github/created-at/abgox/ConvertFrom-JsonAsHashtable" alt="created" />
    </a>
</p>

---

<p align="center">
  <strong>Star ⭐️ or <a href="https://abgox.com/donate">Donate 💰</a> if you like it!</strong>
</p>

## Introduce

JSON to Hashtable Conversion for [Windows PowerShell 5.0+](https://learn.microsoft.com/powershell/scripting/what-is-windows-powershell), similar to `ConvertFrom-Json -AsHashtable` in [PowerShell 7.0+](https://learn.microsoft.com/powershell/scripting/overview).

## Install

- [Install-Module](https://learn.microsoft.com/powershell/module/powershellget/install-module)

  ```powershell
  Install-Module ConvertFrom-JsonAsHashtable
  ```

- [Install-PSResource](https://learn.microsoft.com/powershell/module/microsoft.powershell.psresourceget/install-psresource)

  ```powershell
  Install-PSResource ConvertFrom-JsonAsHashtable
  ```

- [Scoop](https://scoop.sh/)

  - Add the [abyss](https://abyss.abgox.com) bucket via [Github](https://github.com/abgox/abyss) or [Gitee](https://gitee.com/abgox/abyss).

  - Install it.

  ```shell
  scoop install abyss/abgox.ConvertFrom-JsonAsHashtable
  ```

## Usage

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
