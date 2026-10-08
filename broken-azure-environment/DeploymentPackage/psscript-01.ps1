Param(
    [string]$AzureUserName,
    [string]$AzurePassword,
    [string]$AzureTenantID,
    [string]$AzureSubscriptionID,
    [string]$ODLID,
    [string]$InstallCloudLabsShadow,
    [string]$DeploymentID,
    [string]$vmAdminUsername,
    [string]$vmAdminPassword,
    [string]$trainerUserName,
    [string]$trainerUserPassword
)

$logDirectory = 'C:\WindowsAzure\Logs'
New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
Start-Transcript -Path (Join-Path $logDirectory 'CloudLabsCustomScriptExtension.txt') -Append

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ErrorActionPreference = 'Stop'

    $commonBaseUri = 'https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/'
    $labFiles = 'C:\LabFiles'
    New-Item -Path $labFiles -ItemType Directory -Force | Out-Null

    function CreateCredFile {
        param(
            [string]$UserName,
            [string]$Password,
            [string]$TenantId,
            [string]$SubscriptionId,
            [string]$DeploymentId,
            [string]$OutputDirectory = 'C:\LabFiles'
        )

        $credentialFiles = @('AzureCreds.txt', 'AzureCreds.ps1')
        foreach ($fileName in $credentialFiles) {
            $downloadPath = Join-Path $env:TEMP $fileName
            Invoke-WebRequest -Uri ($commonBaseUri + $fileName) -OutFile $downloadPath -UseBasicParsing
            $content = Get-Content -Path $downloadPath -Raw
            $replacements = @{
                '<AzureUserName>' = $UserName
                '<AzurePassword>' = $Password
                '<AzureTenantID>' = $TenantId
                '<AzureSubscriptionID>' = $SubscriptionId
                '<ODLID>' = $ODLID
                '<DeploymentID>' = $DeploymentId
                'GET-AZUSER-UPN' = $UserName
                'GET-AZUSER-PASSWORD' = $Password
                'GET-ODL-ID' = $ODLID
                'GET-DEPLOYMENT-ID' = $DeploymentId
            }
            foreach ($placeholder in $replacements.Keys) {
                $content = $content.Replace($placeholder, [string]$replacements[$placeholder])
            }
            $destination = Join-Path $OutputDirectory $fileName
            Set-Content -Path $destination -Value $content -Encoding UTF8
            Copy-Item -Path $destination -Destination (Join-Path 'C:\Users\Public\Desktop' $fileName) -Force
            Remove-Item -Path $downloadPath -Force -ErrorAction SilentlyContinue
        }
    }

    CreateCredFile -UserName $AzureUserName -Password $AzurePassword -TenantId $AzureTenantID `
        -SubscriptionId $AzureSubscriptionID -DeploymentId $DeploymentID -OutputDirectory $labFiles

    # CloudLabs Shadow uses the instructor account for the RDP session. Do not add it
    # to Administrators: Remote Desktop Users is sufficient for this workstation lab.
    if ($InstallCloudLabsShadow -ne 'false' -and
        -not [string]::IsNullOrWhiteSpace($trainerUserName) -and
        -not [string]::IsNullOrWhiteSpace($trainerUserPassword)) {
        $trainerSecurePassword = ConvertTo-SecureString $trainerUserPassword -AsPlainText -Force
        $existingTrainer = Get-LocalUser -Name $trainerUserName -ErrorAction SilentlyContinue
        if ($null -eq $existingTrainer) {
            New-LocalUser -Name $trainerUserName -Password $trainerSecurePassword `
                -PasswordNeverExpires -AccountNeverExpires -UserMayNotChangePassword `
                -Description 'CloudLabs instructor VM Shadow account' | Out-Null
        } else {
            Set-LocalUser -Name $trainerUserName -Password $trainerSecurePassword
        }
        $rdpMembers = Get-LocalGroupMember -Group 'Remote Desktop Users' -ErrorAction SilentlyContinue
        if (-not ($rdpMembers | Where-Object { $_.Name -match ('\\' + [regex]::Escape($trainerUserName) + '$') })) {
            Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $trainerUserName
        }
    }

    # Keep the VM available to the CloudLabs RDP experience. Azure NSG rules remain
    # the deployment's network boundary; this enables the guest service and firewall.
    Set-Service -Name TermService -StartupType Automatic
    Start-Service -Name TermService -ErrorAction SilentlyContinue
    Enable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue

    # Create a shortcut on the shared desktop so it is visible to the connected learner
    # profile even when that profile has not yet been materialized on the VM.
    $publicDesktop = 'C:\Users\Public\Desktop'
    New-Item -Path $publicDesktop -ItemType Directory -Force | Out-Null
    $edgeCandidates = @(
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
        (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe')
    )
    $edgePath = $edgeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    $shortcutPath = Join-Path $publicDesktop 'Azure Portal.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    if ($edgePath) {
        $shortcut.TargetPath = $edgePath
        $shortcut.Arguments = 'https://portal.azure.com'
        $shortcut.WorkingDirectory = Split-Path $edgePath
    } else {
        $shortcut.TargetPath = 'https://portal.azure.com'
    }
    $shortcut.Description = 'Open the Microsoft Azure portal'
    $shortcut.Save()
    [Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null

    # Also provide a URL shortcut for environments where Edge is installed after the
    # extension completes. Both files open the same approved portal URL.
    @('[InternetShortcut]','URL=https://portal.azure.com','IconIndex=0') |
        Set-Content -Path (Join-Path $publicDesktop 'Azure Portal.url') -Encoding ASCII

    Set-Content -Path (Join-Path $labFiles 'LabVmBootstrap.txt') -Value @(
        'CloudLabs Windows lab VM bootstrap completed.',
        'VM name: labvm',
        'Portal shortcut: https://portal.azure.com',
        ('UTC completion: ' + [DateTime]::UtcNow.ToString('o'))
    ) -Encoding UTF8
}
catch {
    Write-Error ('CloudLabs lab VM bootstrap failed: ' + $_.Exception.Message)
    throw
}
finally {
    Stop-Transcript
}
