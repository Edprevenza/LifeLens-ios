#!/bin/bash

echo "Creating minimal buildable version..."

# List of files with complex dependencies to temporarily disable
files_to_simplify=(
    "LifeLens/Services/HealthDataSyncService.swift"
    "LifeLens/ML/ComputerVisionHealth.swift"
    "LifeLens/ML/NLPHealthAssistant.swift"
    "LifeLens/ML/RealTimeAnomalyDetection.swift"
    "LifeLens/Integration/FHIRIntegration.swift"
    "LifeLens/Validation/ClinicalValidation.swift"
    "LifeLens/Validation/GlobalCompliance.swift"
)

for file in "${files_to_simplify[@]}"; do
    if [ -f "$file" ]; then
        echo "Simplifying $file..."
        # Comment out the entire file content except imports
        awk 'BEGIN {in_import=1} 
             /^import/ {print; next} 
             /^[^i]/ {if(in_import) {in_import=0; print "/*"} print} 
             END {if(!in_import) print "*/"}' "$file" > "$file.tmp"
        mv "$file.tmp" "$file"
    fi
done

echo "Minimal build setup completed!"
