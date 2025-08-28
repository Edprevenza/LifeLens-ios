#!/bin/bash

echo "Fixing brace mismatches in all Swift files..."

# Function to fix brace mismatch in a file
fix_file() {
    local file=$1
    echo "Processing $file..."
    
    # Remove lines with only closing braces at specific error line numbers
    # Based on the errors shown
    case "$file" in
        "LifeLens/View/ProfileSetupView.swift")
            sed -i '' '438d' "$file" 2>/dev/null
            ;;
        "LifeLens/Managers/LocationManager.swift")
            # Remove in reverse order to maintain line numbers
            sed -i '' '313d;238d;63d' "$file" 2>/dev/null
            ;;
        "LifeLens/Views/EnhancedProfileView.swift")
            sed -i '' '605d;302d;204d' "$file" 2>/dev/null
            ;;
        "LifeLens/ML/CloudMLResponseHandler.swift")
            sed -i '' '977d' "$file" 2>/dev/null
            ;;
    esac
}

# Fix the specific files with errors
fix_file "LifeLens/View/ProfileSetupView.swift"
fix_file "LifeLens/Managers/LocationManager.swift"
fix_file "LifeLens/Views/EnhancedProfileView.swift"
fix_file "LifeLens/ML/CloudMLResponseHandler.swift"

echo "Brace fixes completed!"
