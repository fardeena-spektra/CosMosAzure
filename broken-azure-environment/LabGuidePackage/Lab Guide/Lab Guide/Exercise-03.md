# Exercise 3: Knowledge checks

### Estimated Duration: 15 Minutes

## Scenario

You have investigated and remediated the seeded Azure Storage account and created the required text file on `labvm`. This exercise checks your understanding of the security decisions, the intended storage-account end state, and the exact Windows file requirements.

## Overview

Answer the five single-choice questions below. Questions 1–3 cover the Azure Storage troubleshooting and remediation task. Questions 4–5 cover creation and verification of `Desktop\\scenario1.txt` for the connected learner profile.

> [!Important]
> Select one answer for each question. The knowledge checks reinforce the required outcomes; the hands-on validations separately verify the storage-account settings and VM file.

## Objectives

- Task 1: Explain the risks in the seeded Storage account configuration.
- Task 2: Identify the correct secure-transfer and network end state.
- Task 3: Recognize the required Windows file workflow, path, and exact content.

## Task 1: Azure Storage troubleshooting and remediation

Answer the following Azure-focused questions.

### Question 1

A seeded Azure Storage account has **Secure transfer required** disabled and **Public network access** enabled. What security concern best explains this broken configuration?

<question id="question-01"/>

### Question 2

Which Azure Storage account setting should you enable to require clients to use HTTPS for data transfers?

<question id="question-02"/>

### Question 3

After remediation, which portal observation verifies the intended secure end state?

<question id="question-03"/>

## Task 2: Windows completion-file requirements

Answer the following Windows-focused questions about the file created on `labvm`.

### Question 4

Which workflow correctly creates the required completion file on `labvm`?

<question id="question-04"/>

### Question 5

Which result confirms that Scenario 2 is complete and the VM-side validator should pass?

<question id="question-05"/>

## Summary

These checks cover the two seeded Azure faults, the required secure state—secure transfer enabled and public network access disabled—and the exact Windows deliverable: `Desktop\\scenario1.txt` containing `scenario 1 is completed.` with matching casing, punctuation, and spacing. Continue only after answering all five questions.
