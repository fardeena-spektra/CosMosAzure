## MetaData
Question Type : Single Choice

## Question
A seeded Azure Storage account has **Secure transfer required** disabled and **Public network access** enabled. What security concern best explains this broken configuration?

## Options
Option 1 : Clients may connect without HTTPS, and the storage account remains reachable over its public network endpoint unless other controls restrict access.
Option 2 : Azure automatically deletes data because secure transfer is disabled, but public network access prevents deletion.
Option 3 : The storage account can only be accessed from the Azure portal because public network access is enabled.
Option 4 : Enabling public network access forces all clients to use private endpoints and HTTPS.

## Answers
Option 1

## Correct Answer Feedback
Option 1 is correct answer, disabling Secure transfer required permits non-HTTPS requests, while enabling Public network access permits access through the public endpoint subject to authentication and other network controls.

## Incorrect Answer Feedback
Selected Option is not correct Option 1 is the correct answer. The broken state allows non-HTTPS requests and leaves the public network endpoint enabled; it does not by itself delete data, require portal access, or force private endpoints.

## Number of Retries
1