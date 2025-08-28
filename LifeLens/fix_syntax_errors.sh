#!/bin/bash

echo "Fixing syntax errors in Swift files..."

# Files with known extra closing braces
files=(
    "LifeLens/Managers/LocationManager.swift"
    "LifeLens/Views/EnhancedProfileView.swift"
    "LifeLens/View/ProfileSetupView.swift"
    "LifeLens/ML/CloudMLResponseHandler.swift"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing $file..."
        # Count opening and closing braces
        open_count=$(grep -o '{' "$file" | wc -l)
        close_count=$(grep -o '}' "$file" | wc -l)
        
        if [ $close_count -gt $open_count ]; then
            diff=$((close_count - open_count))
            echo "  Found $diff extra closing braces"
            
            # Remove trailing closing braces from end of file
            for ((i=1; i<=$diff; i++)); do
                # Find last non-empty line with just }
                last_brace_line=$(grep -n '^}$' "$file" | tail -1 | cut -d: -f1)
                if [ -n "$last_brace_line" ]; then
                    sed -i '' "${last_brace_line}d" "$file"
                    echo "  Removed closing brace at line $last_brace_line"
                fi
            done
        fi
    fi
done

echo "Syntax fixes completed!"
