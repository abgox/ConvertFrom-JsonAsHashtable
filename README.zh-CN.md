<p align="center">
    <h1 align="center">✨ConvertFrom-JsonAsHashtable✨</h1>
</p>

<p align="center">
    <a href="README.md">English</a> |
    <a href="https://www.powershellgallery.com/packages/ConvertFrom-JsonAsHashtable">Powershell Gallery</a> |
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable">GitHub</a> |
    <a href="https://gitee.com/abgox/ConvertFrom-JsonAsHashtable">Gitee</a> |
    <a href="https://gitcode.com/abgox/ConvertFrom-JsonAsHashtable">GitCode</a>
</p>

<p align="center">
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable/blob/main/LICENSE">
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
  <strong>喜欢这个项目？请给它 Star ⭐️ 或 <a href="https://me.abgox.com/donate">赞赏 💰</a></strong>
</p>

## 介绍

适用于 [Windows PowerShell 5+ (Desktop)](https://learn.microsoft.com/powershell/scripting/what-is-windows-powershell) 的 JSON 到哈希表的转换，类似于 [PowerShell 7+ (Core)](https://learn.microsoft.com/powershell/scripting/overview) 的 `ConvertFrom-Json -AsHashtable`

- **PowerShell 7+**：直接委托给原生的 `ConvertFrom-Json -AsHashtable`
- **PowerShell 5+**：使用手写的迭代 JSON 解析器

## 安装

- [Install-Module](https://learn.microsoft.com/powershell/module/powershellget/install-module)

  ```powershell
  Install-Module ConvertFrom-JsonAsHashtable
  ```

- [Install-PSResource](https://learn.microsoft.com/powershell/module/microsoft.powershell.psresourceget/install-psresource)

  ```powershell
  Install-PSResource ConvertFrom-JsonAsHashtable
  ```

- [Scoop](https://scoop.sh)
  - 添加 [abyss](https://abyss.abgox.com) bucket ([GitHub](https://github.com/abgox/abyss) 或 [Gitee](https://gitee.com/abgox/abyss))
  - 安装它

    ```shell
    scoop install abyss/abgox.ConvertFrom-JsonAsHashtable
    ```

## 使用

```powershell
$jsonString = '{
       "key1": "value1",
       "key2": {
           "subKey1": "subValue1",
           "subKey2": ["item1", "item2"]
       },
       "key3": [
           {"nestedKey1": "nestedValue1"},
           {"nestedKey2": "nestedValue2"}
       ]
   }'

$jsonString | ConvertFrom-JsonAsHashtable
```

## License

[MIT](./LICENSE) © [abgox](https://me.abgox.com)
