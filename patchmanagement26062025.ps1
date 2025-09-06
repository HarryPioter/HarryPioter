#KeePass URL https://sourceforge.net/projects/keepass/files/KeePass%202.x/2.58/KeePass-2.58.msi/download

# Importowanie listy aplikacji z pliku CSV
$app_list = Import-Csv -Path "C:\WINGET\App_Base.csv" -Delimiter ";"

#miejsce gdzie przechowywane są instalki 
$winget_path="C:\WINGET\"

#lista zaktualizowanych aplikacji 
$wynik = @()

# Funkcja normalizacji nazw aplikacji (możesz ją odkomentować, jeśli chcesz używać)
function Normalize-Name {
    param (
        [string]$name
    )
       # Usuwamy wszystkie niedozwolone znaki w nazwach plików/folderów
    return ($name -replace '[\\/:*?"<>|]', '_')
}

# Funkcja konwertująca wynik winget na obiekt PowerShell 
Function Convert-WingetTextToObject {

    [CmdletBinding()]
    Param(
        [Parameter(Position=0, ValueFromPipeline=$true)]
        [String[]]
        $WingetRawText
    )#PARAM

    BEGIN {
        $WingetAccumulatedText = @()
    }

    PROCESS {
        if ($WingetRawText) {$WingetAccumulatedText += $WingetRawText}
    }

    END {
        TRY {
            if (!$WingetAccumulatedText) {
                Throw "No input received."
            } else {
             # Usuwanie wierszy zawierających "<additional entries truncated due to result limit>"
                $WingetAccumulatedText = $WingetAccumulatedText | Where-Object { $_ -notmatch "<additional entries truncated due to result limit>" }

                $RowOfDashes = $WingetAccumulatedText | Where-Object {$_ -match "^-+$"}
                if ($RowOfDashes) {
                    $HeaderRowIndex = ($WingetAccumulatedText.IndexOf($RowOfDashes))[0] - 1
                } else {Throw "Couldn't find header row."}
                $HeaderRowText = $WingetAccumulatedText[$HeaderRowIndex]
                $DataRowsText = $WingetAccumulatedText[($HeaderRowIndex + 2)..($WingetAccumulatedText.Length - 1)]

                $ColumnNames = $HeaderRowText -Split '\s+'

                $i = 0
                $ColumnNames | ForEach-Object {
                    $i++
                    New-Variable -Name "Col$($i)CharLocation" -Value $HeaderRowText.IndexOf("$_")
                }

                $ColumnCharLocationVars = Get-Variable -Name "Col*CharLocation"

                $WingetObjects = $DataRowsText.Replace("ÔÇª"," ").Replace("┬«","r") | Where-Object {$_ -notlike "*upgrades available*"} | ForEach-Object {
                    $CurrentRow = $_
                    $ColumnCharLocationVars | Sort-Object Name -Descending | Select-Object -First ($ColumnCharLocationVars.Count - 1) | ForEach-Object {$CurrentRow = $CurrentRow.Insert($_.Value,'    v')}
                    $CurrentRow
                } | ConvertFrom-String -Delimiter '\s\s\s+' -PropertyNames $ColumnNames

                foreach ($CurrentObject in $WingetObjects) {
                    $ColumnNames | Select-Object -Last ($ColumnNames.Count - 1) | ForEach-Object {
                        if ($CurrentObject.$_.length -eq 1) {$CurrentObject.$_ = ""}
                        else {[string]$CurrentObject.$_ = $CurrentObject.$_.TrimStart('v')}
                    }
                }

                $WingetObjects
            }
        } Catch {
            $Error[0].Exception.Message
        }
    }# END
}# Function Convert-WingetTextToObject...

#------------------------------------------------------------------------Działanie WinGet--------------------------------------------------------

# Iteracja po każdej aplikacji z listy CSV
foreach ($app in $app_list) {
    $app_name = $app.App_Name
    $app_version = $app.App_Version
Write-Output "Sprawdzam $app_name"
  if($app_name -like "*SimplySignDesktop*" )
    {
     # Adres URL strony
     $url = "https://www.files.certum.eu/software/SimplySignDesktop/Windows/"

    # Pobierz zawartość HTML strony
    $html = Invoke-WebRequest -Uri $url

    # Wyciągnij linki do folderów z HTML
    $folders = $html.Links | Where-Object { $_.href -match "^\d+\.\d+\.\d+\.\d+\/$" } | ForEach-Object {
    $_.href.TrimEnd("/")
    }
    # Jeśli są jakieś foldery
        if ($folders.Count -gt 0) 
        {
        # Posortuj jako wersje i wybierz najnowszy
        $latest = $folders | Sort-Object {[version]$_} -Descending | Select-Object -First 1
        #Write-Host "Najnowszy folder to: $latest"
         if([version]$app_version -lt [version]$latest)
         {
            if (-Not (Test-Path -Path "$winget_path\$app_name")) {
                New-Item -Path "$winget_path\$app_name" -ItemType Directory | Out-Null
                }
            $finalUrl = "$url"+"$latest/SimplySignDesktop-$latest-64-bit-pl.msi"
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile("$finalUrl", $winget_path + "\" + $app_name + "\SimplySignDesktop_$latest.msi")
            $app.App_Version = $latest
                         $wynik += [pscustomobject]@{
                            Aplikacja = $app_name
                            Wersja    = $latest
                            }
        }
        } 
            else 
            {
            Write-Host "Nie ma nowszych wersji."
            }
    }
    elseif($app_name -like "*proCertumCardManager*")
    {
     # Adres URL strony
     $url = "https://www.files.certum.eu/software/proCertumCardManager/Windows/"

    # Pobierz zawartość HTML strony
    $html = Invoke-WebRequest -Uri $url

    # Wyciągnij linki do folderów z HTML
    $folders = $html.Links | Where-Object { $_.href -match "^\d+\.\d+\.\d+\.\d+\/$" } | ForEach-Object {
    $_.href.TrimEnd("/")
    }
    # Jeśli są jakieś foldery
        if ($folders.Count -gt 0) 
        {
        # Posortuj jako wersje i wybierz najnowszy
        $latest = $folders | Sort-Object {[version]$_} -Descending | Select-Object -First 1
        #Write-Host "Najnowszy folder to: $latest"
         if([version]$app_version -lt [version]$latest)
         {
            if (-Not (Test-Path -Path "$winget_path\$app_name")) {
                New-Item -Path "$winget_path\$app_name" -ItemType Directory | Out-Null
                }
            $finalUrl = "$url"+"$latest/proCertumCardManager-$latest-64-bit-pl.msi"
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile("$finalUrl", $winget_path + "\" + $app_name + "\proCertumCardManager_$latest.msi")
            $app.App_Version = $latest
                         $wynik += [pscustomobject]@{
                            Aplikacja = $app_name
                            Wersja    = $latest
                            }
        }
        } 
            else 
            {
            Write-Host "Nie ma nowszych wersji."
            }
    }   
    else {        
    # Uruchom winget search dla każdej aplikacji
    $app_name ="Google Chrome" # Przykładowa nazwa aplikacji
    
        # Uruchom winget search dla każdej aplikacji
    $wingetOutput = winget search --name "$app_name" -n 1 -s winget
    # Usuwamy niepotrzebne linie (nagłówki) i parsujemy wynik
    $filteredOutput = $wingetOutput -split "`n" | Where-Object { $_ -match "^\s*\S" }

    # Sprawdzamy, czy wynik zawiera aplikację
    if ($filteredOutput) {
        # Przekształcamy wynik na obiekt
        $parsedOutput = $filteredOutput | Convert-WingetTextToObject
        if ($parsedOutput -match "Couldn't find header row.")
        {$winget_name = "Brak aplikacji $app_name w winget"
        $winget_Version = "Brak aplikacji $app_name w winget"}
            else{
            $winget_name = $parsedOutput.Name
            $winget_package = $parsedOutput.Id
            $wingetOutput_forversion = winget show --exact $winget_package --source winget
            $winget_Version = ($wingetOutput_forversion | Where-Object {$_ -match '^Version:\s*(.+)$'} `
                   | ForEach-Object { ($_ -split ':\s*')[1] }).Trim()            
            
            $cleanName = Normalize-Name -name $winget_name
            
                if (-Not (Test-Path -Path "$winget_path\$cleanName")) {
                New-Item -Path "$winget_path\$cleanName" -ItemType Directory | Out-Null
                }
        
                if($winget_name -like "*7-Zip*" -and [version]$app_version -lt [version]$winget_Version)
                {
                # Usuwamy kropkę z wersji
                $formattedVersion = $winget_Version -replace '\.', ''
                # Tworzymy pełny URL
                $baseUrl = "https://sourceforge.net/projects/sevenzip/files/7-Zip/$winget_Version/7z${formattedVersion}"
                $endUrl = "-x64.msi"
                $finalUrl = "$baseUrl$endUrl"
                $WebClient = New-Object System.Net.WebClient
                $WebClient.DownloadFile("$finalUrl", $winget_path + "\" + $winget_name + "\7zip_$formattedVersion.msi")
                }

                    elseif($winget_name -like "*WinSCP*" -and [version]$app_version -lt [version]$winget_Version)
                    {
                    # Usuwamy kropkę z wersji
                    #$formattedVersion = $winget_Version -replace '\.', ''
                    # Tworzymy pełny URL
                    $baseUrl = "https://winscp.net/download/WinSCP-"
                    $endUrl = ".msi/download"
                    $finalUrl = "$baseUrl$winget_Version$endUrl"
                    $WebClient = New-Object System.Net.WebClient
                    $WebClient.DownloadFile("$finalUrl", $winget_path + "\" + $winget_name + "\WinSCP_$winget_Version.msi")
                    $app.App_Version = $winget_Version
                         $wynik += [pscustomobject]@{
                            Aplikacja = $winget_name
                            Wersja    = $winget_Version
                            }
                    } 
                        elseif($winget_name -like "*Notepad++*" -and [version]$app_version -lt [version]$winget_Version)
                        {
                        #notepad https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.7.8/npp.8.7.8.Installer.x64.exe
                        # Tworzymy pełny URL
                        $baseUrl = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v$winget_Version/npp.$winget_Version.Installer.x64.exe"
                        $finalUrl = "$baseUrl"
                        $WebClient = New-Object System.Net.WebClient
                        $WebClient.DownloadFile("$finalUrl", $winget_path + "\" + $winget_name + "\Notepad_$winget_Version.exe")
                        $app.App_Version = $winget_Version
                         $wynik += [pscustomobject]@{
                            Aplikacja = $winget_name
                            Wersja    = $winget_Version
                            }
                            }
                                elseif($winget_name -like "*Mozilla Firefox (pl)*" -and [version]$app_version -lt [version]$winget_Version)
                                {
                                #Firefox https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=pl
                                # Tworzymy pełny URL
                                $baseUrl = "https://download.mozilla.org/?product=firefox-msi-latest-ssl&os=win64&lang=pl"
                                $finalUrl = "$baseUrl"
                                $WebClient = New-Object System.Net.WebClient
                                $WebClient.DownloadFile("$finalUrl", $winget_path + "\" + $winget_name + "\Mozilla_Firefox_$winget_Version.exe")
                                $app.App_Version = $winget_Version
                                $wynik += [pscustomobject]@{
                                Aplikacja = $winget_name
                                Wersja    = $winget_Version
                                }
                                }
                                    elseif($winget_name -like "*Microsoft Visual Studio Code*" -and [version]$app_version -lt [version]$winget_Version)
                                    {
                                    #VisualStudio https://code.visualstudio.com/docs/?dv=win64
                                    # Tworzymy pełny URL
                                    $baseUrl = "https://code.visualstudio.com/docs/?dv=win64"
                                    $finalUrl = "$baseUrl"
                                    $WebClient = New-Object System.Net.WebClient
                                    $WebClient.DownloadFile("$finalUrl", $winget_path + "\" + $winget_name + "\Microsoft_Visual_Studio_Code_$winget_Version.exe")
                                    $app.App_Version = $winget_Version
                                    $wynik += [pscustomobject]@{
                                    Aplikacja = $winget_name
                                    Wersja    = $winget_Version
                                    }
                                    } 
                                        elseif($winget_name -like "*KeePass*" -and [version]$app_version -lt [version]$winget_Version)
                                        {
                                        #KeePass URL https://sourceforge.net/projects/keepass/files/KeePass%202.x/2.58/KeePass-2.58.msi/download
                                        #Tworzymy pełny URL
                                        $baseUrl = "https://sourceforge.net/projects/keepass/files/KeePass%202.x/$winget_Version/KeePass-$winget_Version.msi/download"
                                        $finalUrl = "$baseUrl"
                                        $WebClient = New-Object System.Net.WebClient
                                        $WebClient.DownloadFile("$finalUrl", $winget_path + "\" + $winget_name + "\KeePass_$winget_Version.msi")
                                        $app.App_Version = $winget_Version
                                        $wynik += [pscustomobject]@{
                                        Aplikacja = $winget_name
                                        Wersja    = $winget_Version
                                        }
                                        }
                            
                                    elseif ([version]$app_version -lt [version]$winget_Version -and $app_name -notlike "*7-Zip*" -and $app_name -notlike "*WinSCP*" -and $app_name -notlike "*Notepad++*" -and $app_name -notlike "*Mozilla Firefox (pl)*" -and $app_name -notlike "*Microsoft Visual Studio Code*" -and $app_name -notlike "*KeePass*")
                                    {
                                    $path = $winget_path + $cleanName
                                    #jesli to możliwe to pobierz .msi
                                    winget download $winget_package -d $path --installer-type msi --skip-license
                                    #niezaleznie pobierz dostepna paczke
                                    winget download $winget_package -d $path --skip-license
                                    Write-Output "Pobieram $winget_package"
                                    $app.App_Version = $winget_Version
                                    $wynik +=  [pscustomobject]@{
                                    Aplikacja = $winget_name
                                    Wersja    = $winget_Version
                                    }
                                    }
          

            }
    } else {
        Write-Host "Nie znaleziono aplikacji dla: $app_name"
    }

    }
}
#------------------------------------------------------------------------Działanie WinGet--------------------------------------------------------
#-----------------------------------------------------------------------Mailer------------------------------------------------------------------
#$wynik
# Eksport zaktualizowanej listy do pliku CSV
$app_list | Export-Csv -Path "C:\WINGET\App_Base.csv" -Delimiter ";" -NoTypeInformation -Encoding UTF8
$line1 = "Poniżej znajdziesz informacje o nowych wersjach aplikacji, które należy zaktualizować w MDM"
$line2 = ($wynik | ForEach-Object {
    "<p style='font-size:12pt'>$($_.Aplikacja), Nowa Wersja: $($_.Wersja)</p>"
}) -join "`n"
Write-host $line1;
Write-host $line2;