using namespace System.Net

# Note: $sub (subscription id) and $DID (deployment id) are injected by the platform.
# This validator is read-only. It discovers the lab storage account from the
# subscription, preferring resources whose name, resource group, or tags contain $DID.
$count = 0
$found = $false
$storageAccountName = $null
$resourceGroupName = $null

function Send-ValidationResponse {
    param(
        [string]$Status,
        [string]$Message
    )

    $body = @{
        Status  = $Status
        Message = $Message
    } | ConvertTo-Json -Compress

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    })
}

do {
    $count = $count + 1
    try {
        Set-AzContext -Subscription $sub -ErrorAction Stop | Out-Null

        # The lab has one seeded Microsoft.Storage/storageAccounts resource. Use
        # deployment-ID metadata when available, and otherwise accept a single
        # storage account rather than guessing among unrelated accounts.
        $resources = @(Get-AzResource -ResourceType 'Microsoft.Storage/storageAccounts' -ErrorAction Stop)
        if ($resources.Count -eq 0) {
            throw "No Microsoft.Storage/storageAccounts resources were found in subscription '$sub'."
        }

        $didText = [string]$DID
        $preferred = @($resources | Where-Object {
            $rgMatch = $_.ResourceGroupName -like "*$didText*"
            $nameMatch = $_.Name -like "*$didText*"
            $tagMatch = $false
            if ($null -ne $_.Tags) {
                $tagMatch = @($_.Tags.Values | ForEach-Object { [string]$_ }) -contains $didText
            }
            $rgMatch -or $nameMatch -or $tagMatch
        })

        if ($preferred.Count -eq 1) {
            $candidate = $preferred[0]
        } elseif ($resources.Count -eq 1) {
            $candidate = $resources[0]
        } elseif ($preferred.Count -gt 1) {
            throw "Multiple storage accounts matched deployment ID '$DID': $(@($preferred | ForEach-Object { $_.ResourceId }) -join ', ')."
        } else {
            throw "Multiple storage accounts exist in subscription '$sub', but none matched deployment ID '$DID'."
        }

        $storageAccountName = $candidate.Name
        $resourceGroupName = $candidate.ResourceGroupName
        $account = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -ErrorAction Stop

        # Az.Storage exposes secure transfer as EnableHttpsTrafficOnly. The
        # underlying ARM property is supportsHttpsTrafficOnly.
        $httpsOnly = $account.EnableHttpsTrafficOnly
        if ($null -eq $httpsOnly -and $null -ne $account.SupportsHttpsTrafficOnly) {
            $httpsOnly = $account.SupportsHttpsTrafficOnly
        }
        $publicAccess = [string]$account.PublicNetworkAccess

        $httpsPass = ($httpsOnly -is [bool] -and $httpsOnly -eq $true)
        $networkPass = ($publicAccess -ieq 'Disabled')
        $found = $true

        if ($httpsPass -and $networkPass) {
            Send-ValidationResponse -Status 'Succeeded' -Message "Storage account '$storageAccountName' in resource group '$resourceGroupName' is compliant: secure transfer required is Enabled (supportsHttpsTrafficOnly=True) and public network access is Disabled."
        } else {
            $issues = [System.Collections.Generic.List[string]]::new()
            if (-not $httpsPass) {
                $httpsValue = if ($null -eq $httpsOnly) { '<not returned>' } else { [string]$httpsOnly }
                [void]$issues.Add("Secure transfer required is '$httpsValue'; enable it so supportsHttpsTrafficOnly is True")
            }
            if (-not $networkPass) {
                $networkValue = if ([string]::IsNullOrWhiteSpace($publicAccess)) { '<not returned>' } else { $publicAccess }
                [void]$issues.Add("Public network access is '$networkValue'; set it to Disabled")
            }
            Send-ValidationResponse -Status 'Failed' -Message "Storage account '$storageAccountName' in resource group '$resourceGroupName' failed validation: $($issues -join '; '). Both settings are required; partial remediation does not pass."
        }
    }
    catch {
        Send-ValidationResponse -Status 'Failed' -Message "Storage security validation could not complete on attempt $count of 3 for subscription '$sub'. The account is located by deployment ID '$DID'. Error: $($_.Exception.Message)"
        Start-Sleep -Seconds 10
    }
} while ($count -lt 3 -and -not $found)

# If discovery/API access failed on all attempts, always return a final structured result.
if (-not $found) {
    $message = @{
        Status  = 'Failed'
        Message = "Storage account for deployment '$DID' was not located or read in subscription '$sub' after 3 attempts. Confirm the ARM deployment completed and that the validator identity can read Microsoft.Storage/storageAccounts."
    } | ConvertTo-Json -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $message
    })
}
