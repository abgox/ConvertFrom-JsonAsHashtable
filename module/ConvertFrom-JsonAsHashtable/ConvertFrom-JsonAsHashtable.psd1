
@{

    RootModule        = 'ConvertFrom-JsonAsHashtable.psm1'

    ModuleVersion     = '2.0.1'

    GUID              = 'abcd032a-8e73-4968-8c20-6f86c080086c'

    Author            = 'abgox'

    Copyright         = '(c) abgox. All rights reserved.'

    Description       = @'
JSON to Hashtable Conversion for Windows PowerShell 5+.
Similar to 'ConvertFrom-Json -AsHashtable' in PowerShell 7+.
  - Website: https://convertfrom-jsonashashtable.abgox.com
  - Github: https://github.com/abgox/ConvertFrom-JsonAsHashtable
  - Gitee: https://gitee.com/abgox/ConvertFrom-JsonAsHashtable
'@

    PowerShellVersion = '5.0'

    FunctionsToExport = 'ConvertFrom-JsonAsHashtable'

    PrivateData       = @{

        PSData = @{

            Tags       = @('PowerShell', 'json', 'ConvertFrom-Json' , 'ConvertFrom-JsonAsHashtable', 'ConvertFrom-JsonToHashtable', 'Windows')

            LicenseUri = 'https://github.com/abgox/ConvertFrom-JsonAsHashtable/blob/main/license'

            ProjectUri = 'https://github.com/abgox/ConvertFrom-JsonAsHashtable'

        }

    }
}
