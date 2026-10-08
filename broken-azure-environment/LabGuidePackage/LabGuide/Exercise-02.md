# Exercise 2: Create the Completion File on labvm

### Estimated Duration: 20 Minutes

## Scenario

The Windows virtual machine `labvm` is the local work area for Scenario 2. You will connect through the CloudLabs RDP experience and create a plain-text completion file in the Desktop folder of the connected learner profile. The validator checks the file name, location, encoding-compatible text content, and exact characters; it does not award credit for a similarly named file in another folder.

## Overview

You will connect to `labvm`, create `scenario1.txt` with Notepad, save it directly to your Desktop, and reopen it to verify the result. File Explorer is used to confirm the visible file name and location. A PowerShell alternative is provided if Notepad or File Explorer is unavailable.

> [!Important]
> The required file is **`Desktop\\scenario1.txt`** for the Windows profile in your active RDP session. Its single line must be exactly `scenario 1 is completed.` including the final period. Do not add quotation marks, leading or trailing spaces, extra lines, or different capitalization.

## Objectives

- Task 1: Connect to `labvm` through CloudLabs RDP and identify the connected learner Desktop.
- Task 2: Create and save the exact plain-text file.
- Task 3: Reopen and verify the file name, path, and content.

## Task 1: Connect to labvm

In this task, you will open the prepared Windows session and make sure you are working in the profile that the validator will inspect.

1. In the CloudLabs console, open the RDP connection for the VM named **`labvm`**. Wait for the Windows desktop and taskbar to finish loading before creating the file.
2. If the RDP experience asks you to authenticate to the lab identity, use the credentials supplied for this lab. If an Azure portal sign-in is presented, use **<inject key="AzureAdUserEmail"></inject>** and the corresponding password **<inject key="AzureAdUserPassword"></inject>**. Do not use a different personal or local Windows profile.
3. Select the Windows desktop inside the RDP session. The Desktop folder you use must belong to the connected learner profile, not the local computer from which you launched RDP.
4. Open File Explorer from the taskbar, select **Home** or **This PC**, and then open **Desktop**. Confirm that the address bar identifies the current profile's Desktop folder. Leave this window available for the verification task.

> [!Tip]
> If you cannot see a Desktop shortcut, press **Windows+E**, select **Home**, and choose **Desktop** from the navigation pane. The validator uses the Desktop folder associated with the active Windows user.

## Task 2: Create and save scenario1.txt

In this task, you will create a plain-text file with the required name and content.

1. On the `labvm` desktop, right-click an empty area and select **New > Text Document**. Open the new text document in Notepad. If Windows immediately names it `New Text Document.txt`, that temporary name is acceptable; you will set the required name when saving.
2. In Notepad, remove any starter text and type this one line exactly:

   `scenario 1 is completed.`

3. Select **File > Save As**. In the Save As dialog, browse to the connected profile's **Desktop** folder. Do not save to Documents, Downloads, OneDrive, or the desktop of your local computer.
4. In **File name**, enter `scenario1.txt`.
5. Set **Save as type** to **Text Documents (*.txt)** or **All files (*.*)**. If you choose **All files**, keep the `.txt` extension in the file name. Leave the encoding at the default text/UTF-8-compatible setting, and select **Save**.
6. If Windows asks whether to replace an existing `scenario1.txt`, replace it only after confirming that it is in the current learner Desktop. If a format confirmation appears, choose the option that keeps the file as plain text.
7. Close Notepad after the save completes.

> [!Important]
> If File Explorer hides known extensions, typing `scenario1.txt` while using **Text Documents (*.txt)** can produce `scenario1.txt.txt`. To prevent this, in File Explorer select **View > Show > File name extensions** before checking the result. The required visible name is `scenario1.txt`, not `scenario1.txt.txt`.

### PowerShell alternative

Use this only in a PowerShell window on `labvm` and only for the active learner profile. It writes the required text as UTF-8 and avoids saving to the wrong machine:

```powershell
$path = Join-Path ([Environment]::GetFolderPath('Desktop')) 'scenario1.txt'
[System.IO.File]::WriteAllText($path, 'scenario 1 is completed.', [System.Text.UTF8Encoding]::new($false))
```

Do not run the command on your local computer outside the RDP session. The validator checks the VM's active learner Desktop.

## Task 3: Verify the completion criteria

In this task, you will verify the exact state before finishing the exercise.

1. In File Explorer, open the connected learner's **Desktop** and turn on **View > Show > File name extensions**.
2. Confirm that exactly one required file is visible with the name `scenario1.txt`. Confirm that there is no `scenario1.txt.txt` file.
3. Double-click `scenario1.txt` to reopen it in Notepad. Confirm that the file contains exactly one line with these characters:

   `scenario 1 is completed.`

4. Check carefully for the final period, capitalization, leading or trailing spaces, and blank lines. Correct the file and save again if any of these differ.
5. Close Notepad, return to File Explorer, and right-click the file to select **Properties**. Confirm that its location is the current learner Desktop and its file name is `scenario1.txt`.
6. Leave the corrected file in place on `labvm` for the VM-side validation. The expected final path is `Desktop\\scenario1.txt` relative to the connected learner profile.

> [!Note]
> The exact text requirement is stricter than visual similarity. `Scenario 1 is completed.`, `scenario 1 is completed` (without the period), and a line with extra spaces are all different values and fail validation.

## Completion criteria

This exercise is complete when all of the following are true:

- The connected VM is `labvm`.
- The file exists in the active learner profile's Desktop folder.
- The file name is exactly `scenario1.txt` with one `.txt` extension.
- The file is plain text and contains exactly `scenario 1 is completed.`.
- You reopened the saved file and verified the content and path.

## Troubleshooting

- **The file is not on the Desktop:** Make sure Save As was performed inside the RDP session and that the dialog's location was the active profile's Desktop. Use File Explorer's address bar and Properties to confirm the location.
- **The name is `scenario1.txt.txt`:** Turn on **View > Show > File name extensions**, right-click the file, choose **Rename**, and change the full name to `scenario1.txt`. Confirm the extension-change prompt. Reopen it and verify the content.
- **The file opens but validation fails:** Check the final period, lowercase `scenario`, single spaces, absence of quotation marks, and absence of blank lines. Delete and recreate the file if necessary.
- **Notepad saved rich formatting or a different type:** Use **File > Save As**, choose **Text Documents (*.txt)** or **All files (*.*)** with the `.txt` name, and save in the Desktop folder. Then reopen the file in Notepad.
- **RDP disconnects:** Reconnect to `labvm` through CloudLabs and continue in the same learner profile. Do not create the file on the local device or a different VM.
- **PowerShell reports access denied:** Close any application holding the file open, confirm that the PowerShell window is running inside `labvm`, and retry. Do not elevate or change permissions; the learner Desktop should be writable.

## Summary

You created and verified the exact plain-text completion file on `labvm`. The VM-side validator will inspect the active learner profile for `Desktop\\scenario1.txt` and require the exact UTF-8 text `scenario 1 is completed.` with no additional characters.