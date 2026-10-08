# Facilitator Solution Guide — Broken Azure Environment

## Scope and scoring

This is an outcome-based assessment. Do not require a particular click sequence, but the learner-facing path is Azure portal for Scenario 1 and the graphical Windows workflow for Scenario 2. Award full credit only when both validators pass; partial remediation is not a passing end state.

The deployment intentionally creates one storage account in this broken state:

| Setting | Seeded value | Required value |
|---|---:|---:|
| **Secure transfer required** (`supportsHttpsTrafficOnly`) | `false` | `true` |
| **Public network access** (`publicNetworkAccess`) | `Enabled` | `Disabled` |

The VM is `labvm`. The required learner-profile file is `Desktop\scenario1.txt`, containing exactly `scenario 1 is completed.` (lowercase, one period, no leading/trailing whitespace, and no extra line required).

## Scenario 1 — Troubleshoot and secure the storage account

### Expected diagnosis

The learner should recognize two independent findings:

1. Secure transfer is not required. Storage service requests can therefore use a non-TLS endpoint, exposing traffic to interception or alteration. The desired control is **Secure transfer required = Enabled**.
2. Public network access is enabled. The account remains reachable through public endpoints subject to authentication and other controls. The desired network posture is **Public network access = Disabled**, so access must use an approved private/network path appropriate to the lab.

Do not accept “HTTPS is available” as remediation: availability of HTTPS is not the same as requiring HTTPS. Do not accept firewall restrictions alone as the required final state.

### Portal procedure and expected end state

The current Microsoft Learn storage-account properties guidance places these controls under the account's **Configuration** blade. Facilitators should use the portal UI labels, which may vary slightly by portal rollout:

1. In Azure portal, open **Storage accounts**, select the deployed account, and open **Configuration** under **Settings**.
2. Inspect **Secure transfer required**. Confirm the seeded value is **Disabled**, set it to **Enabled**, and select **Save**.
3. Return to **Configuration** if necessary. Inspect **Public network access**. Set it to **Disabled** and select **Save**. Confirm any warning dialog.
4. Refresh the blade and verify both values remain correct. A learner may use the account **Overview** and **Properties** blades to identify the resource, but the authoritative checks are the Configuration values and the validator.

Microsoft Learn reference used for the procedure: [Storage account properties](https://learn.microsoft.com/azure/storage/common/storage-account-properties). The setting names and Configuration navigation are the expected current portal experience; portal UI changes do not alter the required API properties.

### Rubric

- **Full credit:** `supportsHttpsTrafficOnly` is `true` and `publicNetworkAccess` is exactly `Disabled`; the learner can explain that TLS is required and public endpoint access is disabled.
- **Partial credit:** only one setting is corrected; a setting appears corrected but is not saved; or the learner changes a firewall/IP rule while leaving public network access enabled. Partial credit is diagnostic only and fails the storage validation.
- **No credit:** the learner changes an unrelated account property, edits a different storage account, or reports success without verifying the saved values.

### Manual verification

Use the deployment's resource group and storage-account name. Set local variables before running these checks:

```azurecli
az storage account show \
  --resource-group $RESOURCE_GROUP \
  --name $STORAGE_ACCOUNT_NAME \
  --query "{secureTransfer: supportsHttpsTrafficOnly, publicNetworkAccess: publicNetworkAccess}" \
  --output table
```

Expected output is `true` and `Disabled`. With Az PowerShell:

```powershell
$sa = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName
[pscustomobject]@{
    Name                = $sa.StorageAccountName
    SecureTransfer      = $sa.EnableHttpsTrafficOnly
    PublicNetworkAccess = $sa.PublicNetworkAccess
}
```

If the installed Az.Storage version exposes the properties differently, query the ARM resource directly:

```powershell
$r = Get-AzResource -ResourceGroupName $resourceGroup -ResourceType 'Microsoft.Storage/storageAccounts' -Name $storageAccountName -ExpandProperties
$r.Properties.supportsHttpsTrafficOnly
$r.Properties.publicNetworkAccess
```

### Common Azure troubleshooting pitfalls

- **Wrong account or region:** resource names can be similar. Confirm the subscription, resource group, location, and resource ID before changing settings.
- **Save not completed:** the portal can leave the old value visible until refresh. Reopen Configuration and verify after saving.
- **Public access terminology:** `Public network access = Disabled` is not equivalent to setting selected networks or adding a firewall rule.
- **Transient portal/API behavior:** retry a read after a short delay if a value appears stale; do not award credit from a pending operation.
- **RBAC propagation:** a newly assigned Contributor or Storage Account Contributor role may take several minutes to become effective. Confirm the learner is editing the intended subscription/resource group before escalating.
- **Policy effects:** an existing policy may deny an insecure update or automatically remediate it. Record the final resource state; do not treat a policy-compliant deployment as proof that the learner performed both corrections.
- **Related but out of scope controls:** encryption, blob anonymous access, shared-key access, and firewall rules are not substitutes for the two required properties.
- **Other Azure provisioning issues:** wrong region, a missing system-assigned identity, soft-deleted resources blocking re-creation, storage SKU throttling, or deployment throttling can affect unrelated setup/recovery work. These are not learner scoring criteria for this lab; preserve the seeded resource and escalate rather than re-create it.

## Scenario 2 — Create the completion file on `labvm`

### Expected workflow

The learner connects to `labvm` through CloudLabs RDP and works in the connected learner profile:

1. Open **File Explorer**, select **Desktop**, and launch **Notepad** (or right-click the desktop and create/open a text document).
2. Enter exactly:

   ```text
   scenario 1 is completed.
   ```

3. Use **File > Save As**, browse to the connected profile's Desktop, and set the filename to `scenario1.txt`.
4. Select **Save as type: Text Documents (*.txt)** and use UTF-8 encoding when the option is shown. If Notepad appends `.txt`, type `scenario1` as the filename or confirm the resulting name is exactly `scenario1.txt`.
5. Reopen the file from Desktop and verify the exact text. Do not create `scenario1.txt.txt`.

### Rubric

- **Full credit:** the connected learner profile has `Desktop\scenario1.txt`, and its content is exactly `scenario 1 is completed.`. The file is plain text and the learner can reopen it.
- **Partial credit:** correct sentence in the wrong folder; correct path with altered capitalization, punctuation, or whitespace; or a file named `scenario1.txt.txt`. These fail validation.
- **No credit:** file is missing, saved under another user profile, is an RTF/Word document, or contains explanatory text in addition to the required sentence.

### Manual verification on the VM

Run in PowerShell as the connected learner, not as an administrator with a different profile:

```powershell
$p = Join-Path ([Environment]::GetFolderPath('Desktop')) 'scenario1.txt'
[pscustomobject]@{
    PathExists = Test-Path -LiteralPath $p -PathType Leaf
    Path       = $p
    Content    = if (Test-Path -LiteralPath $p) { Get-Content -LiteralPath $p -Raw } else { $null }
}
```

A strict check matching the validator's intent is:

```powershell
$p = Join-Path ([Environment]::GetFolderPath('Desktop')) 'scenario1.txt'
$expected = 'scenario 1 is completed.'
(Test-Path -LiteralPath $p -PathType Leaf) -and ((Get-Content -LiteralPath $p -Raw) -eq $expected)
```

`Get-Content -Raw` is used so hidden trailing characters are not overlooked. The assessment requirement is the exact configured content, not a visually similar sentence.

### Common Windows pitfalls

- Saving to the administrator desktop rather than the connected learner's Desktop.
- File Explorer hiding extensions, producing `scenario1.txt.txt`.
- Selecting **All files** and creating an extensionless file, or saving as RTF.
- Typing a capital `S`, changing the period, adding quotes, or adding a second line.
- Copying the sentence from a formatted document that introduces nonbreaking spaces.
- Using a cloud-synced or redirected Desktop when the validator expects the local connected profile's Desktop.

## Scenario 3 — Inline knowledge checks

The expected answer key is below. Explanations are suitable for facilitator review; candidate-facing files should retain only the configured single-choice presentation and concise rationale.

| Question | Correct answer | Rationale |
|---|---|---|
| 1 | The account does not require secure transfer and allows public network access. | The seeded configuration permits a non-TLS path and exposes a public endpoint; both are security findings. |
| 2 | Set **Secure transfer required** to **Enabled**. | This requires requests to use HTTPS/TLS; merely allowing HTTPS is insufficient. |
| 3 | Set **Public network access** to **Disabled**. | The required end state removes public endpoint access; selected networks/firewall rules still represent public access. |
| 4 | In the connected user's Desktop, save a plain-text Notepad file as `scenario1.txt`. | The path is profile-specific and the file must be plain text with the exact filename. |
| 5 | The file must reopen with exactly `scenario 1 is completed.`. | Case, punctuation, whitespace, path, and accidental double extensions matter to validation. |

### Question scoring

- **Full credit:** one unambiguous choice selected for each question; expected key is 1–5 as shown above.
- **Partial credit:** a conceptually related distractor (for example, firewall restrictions instead of disabling public access) demonstrates incomplete understanding but does not change the answer key.
- **No credit:** multiple selections, no selection, or a choice that conflicts with the exact target state.

## Validation expectations

### Validation 1 — Storage account

The external PowerShell validator locates the deployed account from the implicit subscription and deployment/resource identifiers, retries discovery as needed, and returns the CloudLabs response shape through `Push-OutputBinding -Name Response`. It must pass only when both conditions are true:

```text
supportsHttpsTrafficOnly == true
publicNetworkAccess == 'Disabled'
```

Expected pass: a clear `Status: Succeeded` response stating both settings match. Expected failure: `Status: Failed` with the mismatched property or missing-resource diagnostic. A single correct property is not a pass.

### Validation 2 — VM file

The VM-side PowerShell validator must inspect the connected learner profile and require:

```text
learner Desktop\scenario1.txt
content: scenario 1 is completed.
```

Expected pass: `Status: Succeeded` only when the exact file exists and exact text matches. Expected failures include missing file, wrong profile/path, `scenario1.txt.txt`, altered wording/casing/punctuation, and extra whitespace/content. The response should identify the actionable failure without exposing secrets.

## Facilitator closeout

Confirm the learner has completed both hands-on outcomes, then run or refresh both validations. Record the validator results rather than relying on screenshots. If a validation fails, first check subscription/resource identity, saved portal values, learner profile, filename extensions, and literal file content. Do not repair the learner's resource or file before recording the attempt unless the lab's operational policy explicitly permits facilitator intervention.
