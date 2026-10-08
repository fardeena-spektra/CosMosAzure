using namespace System.Net

# $sub (subscription id) and $DID (deployment id) are injected by CloudLabs.
# Azure Run Command performs the filesystem check inside labvm; an Azure Function
# cannot inspect the VM disk directly.
$count = 0
$found = $false
$lastFailure = ""
$remoteScript = @'
$ErrorActionPreference = 'Stop'
$expected = 'scenario 1 is completed.'

# Run Command executes as System, so identify the interactive learner profile
# from the Explorer process instead of assuming a username.
$profilePath = $null
$explorer = Get-CimInstance -ClassName Win32_Process -Filter "Name = 'explorer.exe'" | Select-Object -First 1
if ($null -ne $explorer) {
    $owner = Invoke-CimMethod -InputObject $explorer -MethodName GetOwner
    if ($owner.ReturnValue -eq 0 -and -not [string]::IsNullOrWhiteSpace($owner.User)) {
        $profilePath = (Get-CimInstance -ClassName Win32_UserProfile | Where-Object {
            -not $_.Special -and $_.LocalPath -and $_.LocalPath.EndsWith(('\' + $owner.User), [System.StringComparison]::OrdinalIgnoreCase)
        } | Select-Object -First 1).LocalPath
    }
}
if ([string]::IsNullOrWhiteSpace($profilePath)) {
    $profilePath = (Get-CimInstance -ClassName Win32_UserProfile | Where-Object {
        $_.Loaded -and -not $_.Special -and $_.LocalPath
    } | Select-Object -First 1).LocalPath
}
if ([string]::IsNullOrWhiteSpace($profilePath)) {
    [pscustomobject]@{ Passed = $false; Code = 'ProfileNotFound'; Detail = 'No connected or loaded non-system Windows profile was found.' } | ConvertTo-Json -Compress
    exit 0
}

$filePath = Join-Path (Join-Path $profilePath 'Desktop') 'scenario1.txt'
if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) {
    $doubleExtensionPath = Join-Path (Join-Path $profilePath 'Desktop') 'scenario1.txt.txt'
    if (Test-Path -LiteralPath $doubleExtensionPath -PathType Leaf) {
        [pscustomobject]@{ Passed = $false; Code = 'DoubleExtension'; Detail = "Expected Desktop\scenario1.txt, but found scenario1.txt.txt. Turn on file-name extensions and save with the single .txt extension." } | ConvertTo-Json -Compress
    } else {
        [pscustomobject]@{ Passed = $false; Code = 'MissingFile'; Detail = "Desktop\scenario1.txt was not found for the connected learner profile." } | ConvertTo-Json -Compress
    }
    exit 0
}

# Read as UTF-8 and use an ordinal, case-sensitive comparison. This rejects
# altered wording, casing, trailing spaces, and extra line breaks.
$actual = [System.IO.File]::ReadAllText($filePath, [System.Text.UTF8Encoding]::new($false))
if ($actual -ceq $expected) {
    [pscustomobject]@{ Passed = $true; Code = 'ExactMatch'; Detail = 'Desktop\scenario1.txt exists and contains the exact required UTF-8 text.' } | ConvertTo-Json -Compress
} else {
    [pscustomobject]@{ Passed = $false; Code = 'ContentMismatch'; Detail = 'Desktop\scenario1.txt exists, but its content is not exactly: scenario 1 is completed. Remove extra spaces or line breaks and verify the sentence.' } | ConvertTo-Json -Compress
}
'@

try {
    do {
        $count++
        try {
            Set-AzContext -Subscription $sub -ErrorAction Stop | Out-Null
            $vm = Get-AzVM -Name 'labvm' -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -eq $vm) {
                $lastFailure = "VM 'labvm' was not found in subscription '$sub'."
                $message = @{ Status = 'Failed'; Message = "$lastFailure Attempt $count of 3." } | ConvertTo-Json
            } else {
                # RunPowerShellScript is the documented Windows Run Command action.
                $run = Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -CommandId 'RunPowerShellScript' -ScriptString $remoteScript -ErrorAction Stop
                $output = ($run.Value | ForEach-Object { $_.Message }) -join "`n"
                $result = $output | ConvertFrom-Json -ErrorAction Stop
                if ($result.Passed -eq $true) {
                    $found = $true
                    $message = @{ Status = 'Succeeded'; Message = "VM '$($vm.Name)' in resource group '$($vm.ResourceGroupName)' passed: $($result.Detail)" } | ConvertTo-Json
                } else {
                    $lastFailure = "VM '$($vm.Name)' in resource group '$($vm.ResourceGroupName)' failed [$($result.Code)]: $($result.Detail)"
                    $message = @{ Status = 'Failed'; Message = "$lastFailure Attempt $count of 3." } | ConvertTo-Json
                }
            }
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = $message
            })
        }
        catch {
            $lastFailure = "Error checking Desktop\scenario1.txt on VM 'labvm'. Attempt $count of 3. Error: $($_.Exception.Message)"
            $message = @{ Status = 'Failed'; Message = $lastFailure } | ConvertTo-Json
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [HttpStatusCode]::OK
                Body = $message
            })
            if ($count -lt 3) { Start-Sleep -Seconds 10 }
        }
    } while ($count -lt 3 -and -not $found)
}
finally {
    # No local VM filesystem is accessed by the function; Run Command performed
    # the check remotely through the Azure Compute control plane.
}

if (-not $found) {
    $message = @{ Status = 'Failed'; Message = "VM 'labvm' file validation failed after 3 attempts. Last diagnostic: $lastFailure" } | ConvertTo-Json
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = $message
    })
}