<p align="center">
    <h1 align="center">✨ConvertFrom-JsonAsHashtable✨</h1>
</p>

<p align="center">
    <a href="readme.md">English</a> |
    <a href="readme.zh-CN.md">简体中文</a> |
    <a href="https://www.powershellgallery.com/packages/ConvertFrom-JsonAsHashtable">Powershell Gallery</a> |
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable">Github</a> |
    <a href="https://gitee.com/abgox/ConvertFrom-JsonAsHashtable">Gitee</a>
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
  <strong>喜欢这个项目？请给它一个 Star ⭐️ 或 <a href="https://abgox.com/donate">赞赏 💰</a></strong>
</p>

## 介绍

适用于 [Windows PowerShell 5.0+](https://learn.microsoft.com/powershell/scripting/what-is-windows-powershell) 的 JSON 到哈希表的转换，类似于 [PowerShell 7.0+](https://learn.microsoft.com/powershell/scripting/overview) 的 `ConvertFrom-Json -AsHashtable`

## 安装

- 使用 `Install-Module`

  ```powershell
  Install-Module ConvertFrom-JsonAsHashtable
  ```

- 使用 `Install-PSResource`

  ```powershell
  Install-PSResource ConvertFrom-JsonAsHashtable
  ```

- 使用 [Scoop](https://scoop.sh/)

  - 添加 [abyss](https://abyss.abgox.com) bucket ([Github](https://github.com/abgox/abyss) 或 [Gitee](https://gitee.com/abgox/abyss))
  - 安装它

    ```shell
    scoop install abyss/abgox.ConvertFrom-JsonAsHashtable
    ```

## 使用

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
