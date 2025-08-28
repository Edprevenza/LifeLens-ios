#!/bin/bash

echo "Reverting ChartDataPoint references..."

# Revert back to just ChartDataPoint
find /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Views -name "*.swift" -type f | while read file; do
    if [[ "$file" == *".bak"* ]]; then
        continue
    fi
    
    # Replace APIService.ChartDataPoint back to ChartDataPoint
    sed -i '' 's/APIService\.ChartDataPoint/ChartDataPoint/g' "$file" 2>/dev/null || true
done

echo "✅ Reverted ChartDataPoint references"
