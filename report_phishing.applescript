-- Report Phishing Quick Action for Apple Mail
-- Sends one report email per selected phishing message, each with a single .eml attachment
-- Preserves full original headers (Received, DKIM, SPF, Return-Path etc.)
-- Setup: Automator > New Quick Action > Run AppleScript > paste this script

on run {input, parameters}

    -- === CONFIGURATION ===
    set reportAddresses to {"reportphishing@apwg.org", "scam@netcraft.com", "phishing@verbraucherzentrale.nrw"}
    set tempFolder to (POSIX path of (path to temporary items folder))
    -- === END CONFIGURATION ===

    tell application "Mail"
        set selectedMessages to selection

        if (count of selectedMessages) is 0 then
            display dialog "Please select one or more emails in Mail first." buttons {"OK"} default button "OK" with icon caution
            return
        end if

        -- ISO 8601 timestamp for subject line and filenames
        set timeStamp to do shell script "date +%Y-%m-%dT%H:%M:%S"
        set fileStamp to do shell script "date +%Y%m%d_%H%M%S"

        set totalMessages to count of selectedMessages
        set msgCount to 0
        set skippedCount to 0
        set sentCount to 0
        set attachedFiles to {}

        repeat with theMessage in selectedMessages
            set msgCount to msgCount + 1

            try
                -- Get the raw source (preserves all headers)
                set rawSource to source of theMessage

                -- Guard: skip messages not fully downloaded (IMAP)
                if rawSource is missing value or rawSource is "" then
                    set skippedCount to skippedCount + 1
                    display dialog "Email " & msgCount & " of " & totalMessages & " is not fully downloaded — skipped." buttons {"OK"} default button "OK" with icon caution
                else
                    -- Extract metadata for analyst-friendly body
                    set msgSender to sender of theMessage
                    set msgSubject to subject of theMessage
                    set msgDate to date received of theMessage

                    -- Build subject: [Phishing Report] 2026-04-03T14:32:05 #1
                    set reportSubject to "[Phishing Report] " & timeStamp & " #" & msgCount

                    -- Build structured body for analyst triage
                    set reportBody to "=== PHISHING REPORT ===" & return & return
                    set reportBody to reportBody & "This email was reported as a suspected phishing/scam message." & return
                    set reportBody to reportBody & "The original message is attached as a .eml file with full headers" & return
                    set reportBody to reportBody & "preserved (Received chain, DKIM, SPF, Return-Path, Authentication-Results)." & return & return
                    set reportBody to reportBody & "Report:    " & msgCount & " of " & totalMessages & return
                    set reportBody to reportBody & "Reported:  " & timeStamp & return & return
                    set reportBody to reportBody & "From:      " & msgSender & return
                    set reportBody to reportBody & "Subject:   " & msgSubject & return
                    set reportBody to reportBody & "Received:  " & (msgDate as string) & return & return
                    set reportBody to reportBody & "---" & return
                    set reportBody to reportBody & "Reported using applescript-phishing-report" & return
                    set reportBody to reportBody & "https://github.com/kyannik/applescript-phishing-report" & return

                    -- Create one outgoing message for this email
                    set newMessage to make new outgoing message with properties {subject:reportSubject, content:reportBody}

                    -- Add all reporting recipients
                    tell newMessage
                        repeat with addr in reportAddresses
                            make new to recipient at end of to recipients with properties {address:addr}
                        end repeat
                    end tell

                    -- Write .eml to temp file
                    set emlFileName to "phishing_" & fileStamp & "_" & msgCount & ".eml"
                    set emlPath to tempFolder & emlFileName

                    set fileRef to open for access POSIX file emlPath with write permission
                    set eof of fileRef to 0
                    write rawSource to fileRef as «class utf8»
                    close access fileRef

                    -- Track for cleanup
                    set end of attachedFiles to emlPath

                    -- Attach the .eml file
                    tell newMessage
                        make new attachment with properties {file name:POSIX file emlPath} at after the last paragraph
                    end tell

                    -- Wait for Mail to finish loading the attachment (known async bug)
                    delay 2

                    -- Send this report
                    send newMessage
                    set sentCount to sentCount + 1
                end if

            on error errMsg
                try
                    close access POSIX file emlPath
                end try
                display dialog "Error processing email " & msgCount & " of " & totalMessages & ": " & errMsg buttons {"OK", "Continue"} default button "Continue" with icon caution
            end try

        end repeat

        -- Cleanup: delete temp .eml files
        repeat with filePath in attachedFiles
            try
                do shell script "rm -f " & quoted form of filePath
            end try
        end repeat

    end tell

    return input
end run
