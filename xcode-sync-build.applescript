#!/usr/bin/osascript

-- AppleScript to synchronize and build in Xcode
on run
    tell application "Xcode"
        activate
        
        -- Open the project if not already open
        try
            open "/Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens.xcodeproj"
            delay 2
        end try
        
        -- Get the workspace document
        set workspaceDocument to workspace document 1
        
        -- Get the scheme
        try
            set activeScheme to active scheme of workspaceDocument
            set name of activeScheme to "LifeLens"
        end try
        
        -- Wait for indexing to complete
        delay 3
        
        -- Build the project
        tell workspaceDocument
            -- Try to build
            try
                build
                delay 2
                
                -- Check build status
                set buildSuccessful to true
                return "Build initiated. Check Xcode for status."
            on error errMsg
                return "Build error: " & errMsg
            end try
        end tell
    end tell
end run