<p align="center">
    <h1 align="center">✨ConvertFrom-JsonToHashtable✨</h1>
</p>

<p align="center">
    <a href="README.md">English</a> |
    <a href="README-CN.md">简体中文</a> |
    <a href="https://github.com/abgox/ConvertFrom-JsonToHashtable">Github</a> |
    <a href="https://gitee.com/abgox/ConvertFrom-JsonToHashtable">Gitee</a>
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

## 介绍

-   在 `Windows PowerShell` 中, `ConvertFrom-Json` 方法没有 `-AsHashtable` 开关
-   这导致转换 json 内容为哈希表的操作变得不方便
-   这个模块解决了这个问题
-   它会导出一个 `ConvertFrom-JsonToHashtable` 函数
-   函数和 `ConvertFrom-Json` 使用方式一样，它会直接将 json 内容转换为哈希表

## 使用

1. 安装模块: `Install-Module ConvertFrom-JsonToHashtable`
2. 导入模块: `Import-Module ConvertFrom-JsonToHashtable`
3. 使用示例:

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
