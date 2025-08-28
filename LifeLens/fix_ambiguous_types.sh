#!/bin/bash

echo "Fixing ambiguous type references..."

# Fix ChartDataPoint references
find /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/Views -name "*.swift" -type f | while read file; do
    if [[ "$file" == *"_Original"* ]]; then
        continue
    fi
    
    # Replace [ChartDataPoint] with [APIService.ChartDataPoint]
    sed -i '' 's/\[ChartDataPoint\]/[APIService.ChartDataPoint]/g' "$file" 2>/dev/null || true
    
    # Replace : ChartDataPoint with : APIService.ChartDataPoint
    sed -i '' 's/: ChartDataPoint/: APIService.ChartDataPoint/g' "$file" 2>/dev/null || true
    
    # Replace -> [ChartDataPoint] with -> [APIService.ChartDataPoint]
    sed -i '' 's/-> \[ChartDataPoint\]/-> [APIService.ChartDataPoint]/g' "$file" 2>/dev/null || true
done

echo "✅ Fixed ambiguous type references"
