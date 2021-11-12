# PS Menu
function DrawMenu {
    param ($menuItems, $menuPosition, $Multiselect, $selection)
    $l = $menuItems.length
    for ($i = 0; $i -le $l;$i++) {
        if ($menuItems[$i] -ne $null){
            $item = $menuItems[$i]
            if ($Multiselect)
            {
                if ($selection -contains $i){
                    $item = '[x] ' + $item
                }
                else {
                    $item = '[ ] ' + $item
                }
            }
            if ($i -eq $menuPosition) {
                Write-Host "> $($item)" -ForegroundColor Green
            } else {
                Write-Host "  $($item)"
            }
        }
    }
}

function Toggle-Selection {
    param ($pos, [array]$selection)
    if ($selection -contains $pos){ 
        $result = $selection | where {$_ -ne $pos}
    }
    else {
        $selection += $pos
        $result = $selection
    }
    $result
}
$selected = 0;
function Menu {
    param ([array]$menuItems, [switch]$ReturnIndex=$false, [switch]$Multiselect)
    $vkeycode = 0
    $pos = 0
    $selection = @()
    if ($menuItems.Length -gt 0)
    {
        try {
            [console]::CursorVisible=$false
            DrawMenu $menuItems $pos $Multiselect $selection
            While ($vkeycode -ne 13 -and $vkeycode -ne 27) {
                $press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
                $vkeycode = $press.virtualkeycode
                If ($vkeycode -eq 38 -or $press.Character -eq 'k') {$pos--}
                If ($vkeycode -eq 40 -or $press.Character -eq 'j') {$pos++}
                If ($vkeycode -eq 36) { $pos = 0 }
                If ($vkeycode -eq 35) { $pos = $menuItems.length - 1 }
                If ($press.Character -eq ' ') { $selection = Toggle-Selection $pos $selection }
                if ($pos -lt 0) {$pos = 0}
                If ($vkeycode -eq 27) {$pos = $null }
                if ($pos -ge $menuItems.length) {$pos = $menuItems.length -1}
                if ($vkeycode -ne 27)
                {
                    $startPos = [System.Console]::CursorTop - $menuItems.Length
                    [System.Console]::SetCursorPosition(0, $startPos)
                    DrawMenu $menuItems $pos $Multiselect $selection
                }
            }
        }
        finally {
            [System.Console]::SetCursorPosition(0, $startPos + $menuItems.Length)
            [console]::CursorVisible = $true
        }
    }
    else {
        $pos = $null
    }

    if ($ReturnIndex -eq $false -and $pos -ne $null)
    {
        if ($Multiselect){
            return $menuItems[$selection]
        }
        else {
            $script:selected=$pos
            return $menuItems[$pos]
        }
    }
    else 
    {
        if ($Multiselect){
            return $selection
        }
        else {
            return $pos
        }
    }
}


function Is-Numeric ($Value) {
    return $Value -match "^[\d\.]+$"
}

Set-Location $PSScriptRoot

$dirs = @()
$ports = @{}

echo "Searching for projects..."

dir -dir | ForEach-Object -Process {

    $path = "./" + $_.Name + "/artisan"

    $if_exist = Test-Path $path -PathType Leaf

    if ($if_exist){
        $path_env = "./" + $_.Name + "/.env"
        $if_exist_env = Test-Path $path_env -PathType Leaf

        if($if_exist_env){
            $port = Get-Content $path_env | % { if($_ -match "APP_URL=") {
                $_.split(":")[-1]
            }}
        }else{
            $port = 8000
        }

        if(Is-Numeric($port)){
            $ports[$_]=$port
        }else{
            $ports[$_]=8000
        }

        $dirs += $_
    }
}

echo "Select project to start:"
$dir = menu($dirs)

Set-Location $dir

$default = $ports[$dir]

if (!($port = Read-Host "Port [$default]")) { $port = $default }

echo "Opening another powershell window..."
Start-Process -FilePath "powershell"

echo "Starting server..."
php artisan serve --port=$port

# Compile command
# Invoke-ps2exe -inputFile '.\src\start_laravels.ps1'  -outputFile '..\dist\Start Laravels.exe' -iconFile '.\src\laravel.ico'