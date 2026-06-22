[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Flash-Token {
    # 1. 定義目標檔案名稱
    $FilePath = "files/setup_aquar.sh"

    # 取得腳本當前所在的目錄路徑，並結合檔名
    # $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    # $FilePath = Join-Path $ScriptDir $FileName

    # 2. 檢查檔案是否存在
    if (Test-Path $FilePath) {
        # 讀取檔案內容
        $Content = Get-Content $FilePath -Raw -Encoding utf8

        $Content = $Content -replace '(?m)(TS_AUTHKEY=).*$', '${1}114514'
        $Content = $Content -replace '(?m)(CF_DNS_API_TOKEN=).*$', '${1}1919810'

        # 4. 將修改後的內容寫回檔案
        $Utf8NoBom = New-Object System.Text.UTF8Encoding($false) # $false 代表不使用 BOM
        [System.IO.File]::WriteAllText($FilePath, $Content, $Utf8NoBom)

        exit 0
    }
    else {
        exit 1
    }
}


function Main {
    Flash-Token
}


main