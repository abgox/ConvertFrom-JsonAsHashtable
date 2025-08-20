<p align="center">
    <h1 align="center">✨ConvertFrom-JsonAsHashtable✨</h1>
</p>

<p align="center">
    <a href="readme.md">English</a> |
    <a href="readme.zh-CN.md">简体中文</a> |
    <a href="https://github.com/abgox/ConvertFrom-JsonAsHashtable">Github</a> |
    <a href="https://gitee.com/abgox/ConvertFrom-JsonAsHashtable">Gitee</a>
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
  <strong>喜欢这个项目？请给它一个 ⭐️ 或 <a href="https://abgox.com/donate">赞赏 💰</a></strong>
</p>

## 介绍

-   在 `Windows PowerShell 5.1` 中, `ConvertFrom-Json` 方法没有 `-AsHashtable` 开关
-   这导致转换 json 内容为哈希表的操作变得不方便
-   这个模块用来解决这个问题
-   它会导出一个 `ConvertFrom-JsonAsHashtable` 函数，类似 `ConvertFrom-Json -AsHashtable`

## 使用

1. 安装模块: `Install-Module ConvertFrom-JsonAsHashtable`
2. 导入模块: `Import-Module ConvertFrom-JsonAsHashtable`
3. 使用示例:

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
