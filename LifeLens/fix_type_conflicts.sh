#!/bin/bash

echo "🔧 Fixing Swift type-checking issues..."

# Find files with complex nested views and add type annotations
find . -name "*.swift" -type f | while read -r file; do
    # Skip backup files
    if [[ "$file" == *"_Original.swift"* ]] || [[ "$file" == *".backup"* ]]; then
        continue
    fi
    
    # Check for complex view bodies
    if grep -q "var body: some View {" "$file"; then
        # Count nested braces to identify complex structures
        nested_count=$(awk '/var body: some View {/,/^    }$/ {print}' "$file" | grep -o '{' | wc -l)
        
        if [ "$nested_count" -gt 10 ]; then
            echo "⚠️  Complex view found: $file (Nested level: $nested_count)"
            
            # Add explicit return type hints for computed properties
            sed -i '' 's/private var \([a-zA-Z]*\) {/private var \1: some View {/g' "$file" 2>/dev/null || true
            
            # Break complex modifiers into separate lines
            sed -i '' 's/\.padding()\.background/\.padding()\n            \.background/g' "$file" 2>/dev/null || true
            sed -i '' 's/\.foregroundColor/\n            \.foregroundColor/g' "$file" 2>/dev/null || true
        fi
    fi
done

echo "✅ Type conflict fixes applied"
