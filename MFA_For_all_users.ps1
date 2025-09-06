Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Beta.Reports


# Pobierz datę dzisiejszą
$dataDzisiaj = (Get-Date).Date
$formatowanaData = $dataDzisiaj.ToString("yyyyMMdd")
$retryDelay = 10  # Czas oczekiwania przed ponownym spróbą w sekundach
$maxRetries = 3   # Maksymalna liczba prób przed zgłoszeniem błędu

# Ścieżki do plików logów
$logFile = "C:\MFA\Raporty\log_$formatowanaData.txt"
# Export path for CSV file
$csvPath = "C:\MFA\Raporty\MFA_audyt$formatowanaData.csv" 

# Funkcja do zapisywania do pliku log.txt
function Write-Log {
    param (
            [string]$message
        )
    $message | Out-File -FilePath $logFile -Append
}

function Get-AccessToken {
    param (
        [string]$tenantId,
        [string]$clientId,
        [string]$clientSecret
    )

    $body = @{
        grant_type    = "client_credentials"
        scope         = "https://graph.microsoft.com/.default"
        client_id     = $clientId
        client_secret = $clientSecret
    }

 $response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body
    
    $accessToken = $response.access_token
    $secureString = ConvertTo-SecureString -String $accessToken -AsPlainText -Force
    return [pscustomobject]@{
        AccessToken = $accessToken
        SecureString = $secureString
    }
}

# Parametry logowania
$tenantId = "yourtenantID"
$clientId = "yourclientID"
$clientSecret = "yourclientSecret"

# Pobierz token dostępu do Microsoft Graph
$tokens = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret

# Dostęp do zmiennych
$graphAccessToken = $tokens.AccessToken
$tokendlamggraph = $tokens.SecureString

#----------------------------------------------------------------Logowanie do Exchange-------------------------------------------
# Used to connect to Exchange Online using Access Token
$AADOrganization = 'tenantname.onmicrosoft.com'
$AADTenantId = "yourtenantID"
$AADAppID = "yourclientID"
$AADAppSecret = "yourclientSecret"

    $baseUri = "https://login.microsoftonline.com/"
    $authUri = $baseUri + "$AADTenantId/oauth2/token"
  
    $body = @{
        grant_type    = "client_credentials"
        client_id     = "$AADAppID"
        client_secret = "$AADAppSecret"
        resource      = "https://outlook.office365.com"
    }
  
    $Response = Invoke-RestMethod -Method POST -Uri $authUri -Body $body -ContentType 'application/x-www-form-urlencoded'
    $accessToken = $Response.access_token

    # Connect to Exchange Online in an unattended scripting scenario using Access Token.
    $exchangeSessionParams = @{
        Organization     = $AADOrganization
        AppID            = $AADAppID
        AccessToken      = $accessToken
        ShowBanner       = $false
        ShowProgress     = $false
        TrackPerformance = $false
        ErrorAction      = 'Stop'
    }
    $exchangeSession = Connect-ExchangeOnline @exchangeSessionParams
#----------------------------------------------------------------Logowanie do Exchange-------------------------------------------
#----------------------------------------------------------------Zerowanie konfiguracji MFA-------------------------------------------
function Remove-UserAuthMethods {
    param (
        [Parameter(Mandatory=$true)]
        [string]$id,  # Identyfikator użytkownika

        [Parameter(Mandatory=$true)]
        [hashtable]$headers,  # Nagłówki do wywołań API Graph

        [Parameter(Mandatory=$true)]
        $authmethods  # Metody uwierzytelniania użytkownika
    )

    if ($authmethods -ne $null) {
        $authmethod = $null
        foreach ($authmethod in $authmethods.value) {
            if ($authmethod.'@odata.type' -eq "#microsoft.graph.emailAuthenticationMethod") {
                $emailAuthenticationMethod = $authmethod.id
                Invoke-RestMethod -Method DELETE "https://graph.microsoft.com/beta/users/$id/authentication/emailMethods/$emailAuthenticationMethod" -Headers $headers
            }
            if ($authmethod.'@odata.type' -eq "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod") {
                $microsoftAuthenticatorAuthenticationMethodId = $authmethod.id
                Invoke-RestMethod -Method DELETE "https://graph.microsoft.com/beta/users/$id/authentication/microsoftAuthenticatorMethods/$microsoftAuthenticatorAuthenticationMethodId" -Headers $headers 
            }       
            if ($authmethod.'@odata.type' -eq "#microsoft.graph.fido2AuthenticationMethod") {
                $fido2AuthenticationMethod = $authmethod.id
                Invoke-RestMethod -Method DELETE "https://graph.microsoft.com/beta/users/$id/authentication/fido2Methods/$fido2AuthenticationMethod" -Headers $headers 
            }
            if ($authmethod.'@odata.type' -eq "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod") {
                $windowsHelloForBusinessAuthenticationMethod = $authmethod.id
                Invoke-RestMethod -Method DELETE "https://graph.microsoft.com/beta/users/$id/authentication/windowsHelloForBusinessMethods/$windowsHelloForBusinessAuthenticationMethod" -Headers $headers
            }
            if ($authmethod.'@odata.type' -eq "#microsoft.graph.phoneAuthenticationMethod") {
                $phoneAuthenticationMethod = $authmethod.id
                Invoke-RestMethod -Method DELETE "https://graph.microsoft.com/beta/users/$id/authentication/phoneMethods/$phoneAuthenticationMethod" -Headers $headers
            }
            if ($authmethod.'@odata.type' -eq "#microsoft.graph.softwareOathAuthenticationMethod") {
                $softwareOathAuthenticationMethod = $authmethod.id
                Invoke-RestMethod -Method DELETE "https://graph.microsoft.com/beta/users/$id/authentication/softwareOathMethods/$softwareOathAuthenticationMethod" -Headers $headers
            }
            if ($authmethod.'@odata.type' -eq "#microsoft.graph.platformCredentialAuthenticationMethod") {
                $platformCredentialAuthenticationMethod = $authmethod.id
                Invoke-RestMethod -Method DELETE "https://graph.microsoft.com/beta/users/$id/authentication/platformCredentialMethods/$platformCredentialAuthenticationMethod" -Headers $headers
            }
            if ($authmethod.'@odata.type' -eq "#microsoft.graph.temporaryAccessPassAuthenticationMethod") {
                $temporaryAccessPassAuthenticationMethod = $authmethod.id
                Invoke-RestMethod -Method DELETE "https://graph.microsoft.com/beta/users/$id/authentication/temporaryAccessPassMethods/$temporaryAccessPassAuthenticationMethod" -Headers $headers
            }
        }

        # Logout dla usera, co wymusi na nim ponowną konfigurację MFA
        Invoke-RestMethod -Method POST "https://graph.microsoft.com/beta/users/$id/revokeSignInSessions" -Headers $headers -ContentType "application/json" 
    } else {
        # Logout dla usera, co wymusi na nim ponowną konfigurację MFA
        Invoke-RestMethod -Method POST "https://graph.microsoft.com/beta/users/$id/revokeSignInSessions" -Headers $headers -ContentType "application/json"
    }
}

#-------------------------------------------------------------------------Dla każdego usera potrzebuje jego ID--------------------------------------------------------------------------
Connect-MgGraph -AccessToken $tokendlamggraph
try {
# Pobieram wszystko z tenantu aby przejść obiekt po obiekcie
    $Users = Get-MgBetaUser -All

#Nagłówek do Invoke-RestMethod wszędzie będzie taki sam bo odpowiada za autoryzację. Dlatego deklaruje go na początku   
    $headers = @{
        Authorization = "Bearer $graphAccessToken"
        }
#Paramtery dla wymuszenia MFA        
$url = "https://graph.microsoft.com/beta/users/$id/authentication/requirements"
$params = @{"perUserMfaState" = "enforced"}
$body = ConvertTo-Json -InputObject $params

    #Przypisuje wyniki do zmiennej z uwagi na to że chce mieć raport po wykonanych akcjach. Nie wpływa to na zakres działania.
    $Report = foreach ($User in $Users) 
    {

        #Po każdym przejściu pętli foreach potrzebuje zresetowanie tych wartości ponieważ czasem nie mogła ona zaktualizować swojej wartości przez co przypisywana była wartość z poprzedniej skrzynki.
        $mailbox             = $null
        $state               = $null
        $authmethods         = $null
        $MFA_Report_Per_user = $null
        $MailboxType         = $null
        $DefaultMfaMethod    = $null
        $MFA_wlaczone        = $null
        $MFA_Zarejestrowane  = $null
        $id                  = $User.Id
        $mailbox = Get-Mailbox -Identity $id 
        if ($mailbox -eq $null)
        {
            $MailboxType = "Gość"
        }
        Else{
       # $mailbox = Get-Mailbox -Identity $id |  Select-Object -ExpandProperty RecipientTypeDetails
        $MailboxType         = $mailbox.RecipientTypeDetails # Assuming MailboxType is the correct property
        }
        #Czy skrzynka jest typu user mailbox
        if ($MailboxType -eq "UserMailbox")
        {  
            $retryCount = 0
            $success = $false
            while (-not $success -and $retryCount -lt $maxRetries) {
            try{
                $MFA_Report_Per_user = Invoke-RestMethod -Method GET "https://graph.microsoft.com/beta/reports/authenticationMethods/userRegistrationDetails/$id" -Headers $headers -ContentType "application/json"
                $DefaultMfaMethod                             = $MFA_Report_Per_user.DefaultMfaMethod
                $MFA_wlaczone                                 = $MFA_Report_Per_user.IsMfaCapable
                $MFA_Zarejestrowane                           = $MFA_Report_Per_user.IsMfaRegistered
                 # Ustaw flagę sukcesu
                $success = $true
            }
            catch{  
                $mozliwebledy = $_.ErrorDetails.Message | ConvertFrom-Json
                if($mozliwebledy.error.code -eq 404)
                {
                    $DefaultMfaMethod    = "none"
                    $MFA_wlaczone        = $false
                    $MFA_Zarejestrowane  = $false
                    $state = "Wymuszono MFA, wymuszono ponowne logowanie"
                     # Ustaw flagę sukcesu
                    $success = $true
                }
                elseif ($mozliwebledy.error.message -like "*This request is throttled*")
                {
                    Start-Sleep -Seconds $retryDelay
                    $retryCount++
                }
                else{

                    Write-Log $mozliwebledy.error.message "||" $mozliwebledy.error.code
                    break
                }
            }
        }
            if($DefaultMfaMethod -eq "none" -and $MFA_wlaczone -eq $false -and $MFA_Zarejestrowane -eq $false)
            {
                #Ustawiam MFA Enforced tylko dla spełniających warunki
                try {
                Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -Body $body -ContentType "application/json" 
                Invoke-RestMethod -Method POST "https://graph.microsoft.com/beta/users/$id/revokeSignInSessions"  -Headers $headers -ContentType "application/json" 
                $state = "Wymuszono MFA, wymuszono ponowne logowanie"
                }
                catch {
                Write-Log "Wystąpił błąd podczas aktualizacji stanu MFA: $_"
                }
            }
            elseif ($DefaultMfaMethod -ne "none" -and $MFA_wlaczone -eq $false -and $MFA_Zarejestrowane -eq $false)
            {
                try {
                $authmethods = Invoke-RestMethod -Method GET https://graph.microsoft.com/beta/users/$id/authentication/methods -Headers $headers 
                Remove-UserAuthMethods -id $id -headers $headers -authmethods $authmethods
                Invoke-RestMethod -Method POST "https://graph.microsoft.com/beta/users/$id/revokeSignInSessions"  -Headers $headers -ContentType "application/json" 
                $state = "Zresetowano stan MFA, wymuszono ponowne logowanie"
                }
                catch {
                    Write-Log "Wystąpił błąd podczas aktualizacji stanu MFA: $_"
                    }
            } 
            elseif ($DefaultMfaMethod -eq "none" -and $MFA_wlaczone -eq $true)
            {
                try{
                Invoke-RestMethod -Method Patch -Uri $url -Headers $headers -Body $body -ContentType "application/json" 
                #Invoke-RestMethod -Method POST "https://graph.microsoft.com/beta/users/$id/revokeSignInSessions"  -Headers $headers -ContentType "application/json" 
                Invoke-RestMethod -Method POST "https://graph.microsoft.com/beta/users/$id/revokeSignInSessions"  -Headers $headers -ContentType "application/json" 
                $state = "Wymuszono MFA, wymuszono ponowne logowanie"  
                }
                catch {
                    Write-Log "Wystąpił błąd podczas aktualizacji stanu MFA: $_"
                    }
            }   
            elseif ($DefaultMfaMethod -ne "none" -and $MFA_wlaczone -eq $false)
            {
                try {
                   $authmethods = Invoke-RestMethod -Method GET https://graph.microsoft.com/beta/users/$id/authentication/methods -Headers $headers 
                    Remove-UserAuthMethods -id $id -headers $headers -authmethods $authmethods
                    Invoke-RestMethod -Method POST "https://graph.microsoft.com/beta/users/$id/revokeSignInSessions"  -Headers $headers -ContentType "application/json" 
                    $state = "Zresetowano stan MFA, wymuszono ponowne logowanie"
                    }
                    catch {
                        Write-Log "Wystąpił błąd podczas aktualizacji stanu MFA: $_"
                        }
            }
            else {
                $state = "Użytkownik ma prawidłowo skonfigurowane MFA"
            }
#Jeśli użytkownik nie ma ustawionego MFA to muszę sprawdzić również czy nie ma zarejestrowanych metod (jeśli ma to nie wymusi mu ponownego ustawienia konfiguracji)
        }
        else{
            $state = "Nie usermailbox"
        }
        
        [pscustomobject]@{
            Id                                           = $id
            UserPrincipalName                            = $User.UserPrincipalName
           # UserDisplayName                              = $mailbox.UserDisplayName
           # IsAdmin                                      = $MFA_Report_Per_user.IsAdmin
            DefaultMfaMethod                             = $DefaultMfaMethod
            #MethodsRegistered                            = $MFA_Report_Per_user.MethodsRegistered -join ','
            MFA_wlaczone                                 = $MFA_wlaczone
            MFA_Zarejestrowane                           = $MFA_Zarejestrowane
            #LastUpdatedDateTime                          = $MFA_Report_Per_user.LastUpdatedDateTime
            MailboxType                                  = $MailboxType # Assuming MailboxType is the correct property
            Stan                                         = $state
        }
    }
}   
    catch {
        # Catch errors
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
    # Export custom object to CSV file
    $Report | Export-Csv -Path $csvPath -Encoding utf-8 -Delimiter ";" -NoTypeInformation
    Write-Host "Script completed. Report exported successfully to $csvPath" -ForegroundColor Green
Disconnect-MgGraph
Disconnect-ExchangeOnline -Confirm:$false