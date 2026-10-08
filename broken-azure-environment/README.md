# Broken Azure Environment

## Package summary

This is an intermediate, 90-minute Azure assessment lab. The learner troubleshoots a seeded Azure Storage account configuration in the Azure portal, remediates the required security and networking settings, connects to the Windows lab VM, creates a completion file, and completes five single-choice knowledge checks.

## Azure resource and portal field checklist

The deployment creates one CloudLabs subscription/resource group environment with the following resources:

- **Storage account:** the seeded assessment target. The learner must inspect and remediate these fields:
  - **Secure transfer required:** seeded **Disabled**; target **Enabled** (`supportsHttpsTrafficOnly = true`).
  - **Public network access:** seeded **Enabled**; target **Disabled** (`publicNetworkAccess = Disabled`).
  - The storage account name and resource-group reference are exposed through deployment outputs for guides and validators; no secrets are embedded in the package.
- **Windows virtual machine:** `labvm`, reachable through the CloudLabs RDP experience.
- **Supporting VM resources:** virtual network, subnet, network security group, network interface, and public IP address as required by the canonical CloudLabs VM deployment.
- **VM bootstrap:** Custom Script Extension prepares the desktop and creates or exposes a Microsoft Edge shortcut to `https://portal.azure.com`.

### Learner portal checklist

1. Open Microsoft Edge from the `labvm` desktop shortcut, or browse directly to `https://portal.azure.com`.
2. Use the supplied lab identity and the supplied subscription/resource group to locate the deployed storage account.
3. In the storage account, inspect **Configuration** and verify the **Secure transfer required** field.
4. Inspect **Networking** and verify **Public network access**.
5. Set **Secure transfer required** to **Enabled** and **Public network access** to **Disabled**, then save each change.
6. Reopen or refresh the relevant pages and confirm the final values. The validator requires both settings; partial remediation does not pass.

Portal labels can vary slightly as the Azure portal evolves. The intended fields are the storage account Configuration secure-transfer control and Networking public-network-access control, not an equivalent policy-only change.

## Canonical lab VM shape

The package uses the canonical CloudLabs Azure Windows lab VM shape: a single Windows GUI VM named `labvm`, provisioned with the standard CloudLabs supporting network resources, reachable through the CloudLabs RDP experience, and prepared by CSE for learner use. The desktop includes Microsoft Edge with the Azure portal shortcut. The deployment profile supplies the approved Microsoft-supported Windows image, VM size, credentials, and network values through ARM parameters; secrets are represented by CloudLabs `GET-`/`GEN-` placeholders rather than hard-coded in this summary.

The VM is used for the local task only; Azure portal remediation is the primary workflow for the storage-account task. The connected learner profile is the validation context for the desktop file.

## Seeded state and target state

| Setting | Seeded broken state | Required target state | Validation mapping |
|---|---|---|---|
| Secure transfer required | Disabled | Enabled; `supportsHttpsTrafficOnly = true` | Validation 1: Azure Storage account final state |
| Public network access | Enabled | Disabled; `publicNetworkAccess = Disabled` | Validation 1: Azure Storage account final state |
| Completion file | Missing or not assessed at deployment | `Desktop\\scenario1.txt` on the connected learner profile | Validation 2: VM file final state |
| File content | Missing or not assessed at deployment | Exact UTF-8 text: `scenario 1 is completed.` | Validation 2: VM file final state |

## Learner access assumptions

- CloudLabs supplies an Azure subscription, resource group, and lab identity with portal access.
- ARM deployment completes before the exercises begin.
- The learner can connect to `labvm` through CloudLabs RDP.
- The VM bootstrap leaves the Windows desktop ready and provides the Edge shortcut.
- The learner creates the file with File Explorer and Notepad for the connected profile.
- The file must be saved as plain text at `Desktop\\scenario1.txt`; an accidental `scenario1.txt.txt`, changed casing, altered wording, or extra whitespace fails validation.

## Validation mapping

- **Validation 1 — Storage account final state:** locates the deployed storage account using CloudLabs subscription/deployment context and requires both `supportsHttpsTrafficOnly`/secure transfer required to be `true` and `publicNetworkAccess` to be `Disabled`.
- **Validation 2 — VM file final state:** checks the connected learner profile for the exact desktop path and exact UTF-8 content. Missing files and accidental double extensions produce a failure with actionable diagnostics.
- The assessment validates outcomes rather than the learner's click sequence. RBAC and Azure Policy artifacts are supporting package deliverables; the learner-facing remediation remains an Azure portal task.

## Attached portal reference citation

The attached portal reference establishes Azure portal as the target learner experience. The field names and navigation are aligned with the following Microsoft Learn references:

- Microsoft Learn, **Require secure transfer in Azure Storage**: https://learn.microsoft.com/en-us/azure/storage/common/storage-require-secure-transfer
- Microsoft Learn, **Configure Azure Storage firewalls and virtual networks**: https://learn.microsoft.com/en-us/azure/storage/common/storage-network-security
- Microsoft Learn, **Create and manage a storage account**: https://learn.microsoft.com/en-us/azure/storage/common/storage-account-create

These references support the Configuration → Secure transfer required and Networking → Public network access checks used by Exercise 1. The portal UI may present minor label or layout changes while preserving those controls.

## Package contents

- ARM deployment template and parameters for the broken Azure environment.
- CSE/bootstrap script for the Windows VM and Edge portal shortcut.
- Getting Started page and three exercise pages.
- Five inline single-choice questions: three Azure-focused and two Windows-focused.
- Two PowerShell validations.
- Facilitator solution guide.
- Supporting custom RBAC role and Azure Policy artifacts.
- `Spec.md` inventory sheet.