## MetaData
Question Type : Single Choice

## Question
Which result confirms that Scenario 2 is complete and the VM-side validator should pass?

## Options
Option 1 : A file named `scenario1.txt` exists anywhere on `labvm` and contains a similar completion message.
Option 2 : The connected learner profile has `Desktop\scenario1.txt` containing exactly `scenario 1 is completed.` with the same casing, punctuation, and spacing.
Option 3 : The connected learner profile has `Desktop\scenario1.txt.txt` containing `scenario 1 is completed.`.
Option 4 : The file is saved as a Word document on the desktop with the completion sentence displayed correctly.

## Answers
Option 2

## Correct Answer Feedback
Option 2 is correct answer, because Scenario 2 requires the exact path `Desktop\scenario1.txt` and the exact UTF-8 text `scenario 1 is completed.`; reopening the file helps verify the content before submission.

## Incorrect Answer Feedback
Selected Option is not correct Option 2 is the correct answer. The validator does not accept a different location, an accidental `.txt.txt` extension, a different file type, or altered text.

## Number of Retries
1