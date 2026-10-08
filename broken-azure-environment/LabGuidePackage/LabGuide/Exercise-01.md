# Exercise 1: Troubleshoot and Secure the Azure Storage Account

### Estimated Duration: 40 Minutes

## Scenario

A storage account in your CloudLabs deployment was intentionally released with an insecure configuration. Your task is to investigate the account in the Azure portal, determine which security and networking settings explain the risk, and remediate the account without changing unrelated settings. The required final state is **Secure transfer required = Enabled** and **Public network access = Disabled**.

## Overview

You will sign in to the Azure portal, locate the storage account associated with this deployment, inspect its configuration, and correct two seeded faults. First, you will use the account's **Configuration** page to review secure transfer. Next, you will use **Networking** to review public endpoint access. You will then save both changes and verify the exact end state in the portal.

The account is a standard Azure Storage account resource (`Microsoft.Storage/storageAccounts`). The validator checks the resource properties, not the sequence of portal clicks.

## Objectives

- Task 1: Sign in and locate the seeded storage account.
- Task 2: Investigate the account's security and networking symptoms.
- Task 3: Enable secure transfer and disable public network access.
- Task 4: Verify the exact corrected state.

## Task 1: Sign in and locate the storage account

In this task, you will open the Azure portal and identify the storage account deployed for your lab.

1. Connect to the Windows lab VM named `labvm` through the CloudLabs RDP experience.
2. On the VM desktop, open the Microsoft Edge shortcut for Azure portal. If you open the portal directly, use <https://portal.azure.com>.
3. Sign in with the lab identity:
   - **Username:** <inject key="AzureAdUserEmail"></inject>
   - **Password:** <inject key="AzureAdUserPassword"></inject>
4. If Azure asks you to select a directory or subscription, use the lab tenant and the subscription supplied for this deployment.
5. In the Azure portal search bar, search for **Storage accounts**, and open the **Storage accounts** service.
6. Locate the account in the resource group supplied by CloudLabs. Use the deployment identifier when comparing the deployed resource name: **Storage account for deployment <inject key="DeploymentID" enableCopy="false"/>**. Do not create a new storage account.
7. Open the account's **Overview** page and confirm that its resource type is `Microsoft.Storage/storageAccounts`. Record the account name and resource group for your own troubleshooting notes.

> [!Tip]
> If several storage accounts are listed, filter by the resource group created for this lab and choose the account deployed with the current deployment identifier. The validator evaluates the seeded account, not a newly created account.

## Task 2: Investigate the two seeded faults

In this task, you will inspect the settings before changing them. Use the symptoms and prompts below to form a diagnosis.

1. In the storage account service menu, under **Settings**, select **Configuration**.
2. Find **Secure transfer required**. Record whether it is currently enabled or disabled before making a change.
3. Consider the troubleshooting question: if this property is disabled, what kind of request could the account accept that a secure baseline should reject? The relevant Azure Storage property is exposed through the resource model as `supportsHttpsTrafficOnly` (also commonly represented by the API/CLI property `enableHttpsTrafficOnly`).
4. In the storage account service menu, under **Security + networking**, select **Networking**.
5. Find **Public network access** and inspect its current value. Record whether the public endpoint is available before making a change.
6. Consider the second troubleshooting question: does the current value leave the account reachable through its public endpoint, or does it require access through a private endpoint? This lab's required end state is to block the public endpoint; you are not asked to create a private endpoint.

> [!Important]
> Do not change firewall rules, virtual networks, private endpoints, access keys, containers, or other settings. The two seeded faults are the secure-transfer setting and public network access.

## Task 3: Remediate the storage account

In this task, you will apply the two required corrections in the Azure portal.

1. Return to **Configuration** under **Settings** if necessary.
2. Set **Secure transfer required** to **Enabled**.
3. Select **Save** and wait for the portal confirmation that the update completed.
4. Select **Networking** under **Security + networking**.
5. Under **Public network access**, select **Manage**.
6. Select **Disable**, and then select **Proceed** when the confirmation prompt appears.
7. Select **Save** and wait for the portal confirmation that the network configuration was updated.

These portal locations follow Microsoft Learn's current guidance: secure transfer for an existing storage account is changed under **Settings > Configuration**, while disabling public network access is changed under **Security + networking > Networking > Public network access > Manage**.

> [!Note]
> Requiring secure transfer rejects insecure HTTP requests to Azure Storage REST endpoints. Disabling public network access prevents clients from connecting through the public endpoint; private-endpoint access can still be used when a private endpoint exists. This lab intentionally validates the setting itself and does not require you to create a private endpoint.

## Task 4: Verify completion

In this task, you will confirm that both changes were saved on the intended account.

1. On **Configuration**, verify that **Secure transfer required** displays **Enabled**.
2. On **Networking**, verify that **Public network access** displays **Disabled**. If the portal shows a **Manage** control, open it and confirm the selected state is **Disabled**, then close the dialog without making another change.
3. Confirm that you are still viewing the storage account in the lab resource group and that you did not modify a different account.
4. Allow a short time for the portal to refresh the resource properties.
5. When both settings match the required state, submit the exercise for validation.

> [!Important]
> Partial remediation does not pass. The validator requires both values: `supportsHttpsTrafficOnly` must be `true`, and `publicNetworkAccess` must be `Disabled`.

<validation step="00d4752c-bd91-442c-b4c9-d928d0985376" />

## Completion criteria

This exercise is complete when all of the following are true:

- The seeded storage account, rather than a replacement account, was updated.
- **Secure transfer required** is **Enabled** (`supportsHttpsTrafficOnly = true`).
- **Public network access** is **Disabled** (`publicNetworkAccess = Disabled`).
- The portal shows successful saves for both configuration areas.
- You can explain that the first setting enforces HTTPS for REST traffic and the second removes exposure through the public endpoint.

## Summary

You diagnosed two independent storage-account weaknesses and corrected them in the Azure portal. The final configuration requires secure transfer and disables public network access, reducing exposure to insecure transport and unintended internet-based access. The CloudLabs validator checks both resource properties on the deployed `Microsoft.Storage/storageAccounts` resource and awards credit only when both are correct.
