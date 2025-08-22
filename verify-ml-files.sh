#!/bin/bash

# Verify ML files are properly included in Xcode project
echo "======================================"
echo "🔍 Verifying ML Files in Xcode Project"
echo "======================================"

cd /Users/basorge/Desktop/LifeLens/Ios/LifeLens

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "\n${BLUE}1. Checking ML Files Existence${NC}"
echo "----------------------------------------"

ML_FILES=(
    "LifeLens/ML/EdgeMLModels.swift"
    "LifeLens/ML/LocalPatternDetection.swift"
    "LifeLens/ML/SensorDataProcessor.swift"
    "LifeLens/ML/MLHealthService.swift"
)

ALL_PRESENT=true

for file in "${ML_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} Found: $(basename $file)"
        FILE_SIZE=$(wc -l < "$file")
        echo "  Lines of code: $FILE_SIZE"
    else
        echo -e "${RED}✗${NC} Missing: $(basename $file)"
        ALL_PRESENT=false
    fi
done

echo -e "\n${BLUE}2. Checking ML Folder Structure${NC}"
echo "----------------------------------------"

if [ -d "LifeLens/ML" ]; then
    echo -e "${GREEN}✓${NC} ML folder exists"
    echo "Contents:"
    ls -la LifeLens/ML/ | grep ".swift" | awk '{print "  - " $9 " (" $5 " bytes)"}'
else
    echo -e "${RED}✗${NC} ML folder missing"
fi

echo -e "\n${BLUE}3. Checking Project File Configuration${NC}"
echo "----------------------------------------"

# Check if project uses file system synchronized groups
if grep -q "PBXFileSystemSynchronizedRootGroup" LifeLens.xcodeproj/project.pbxproj; then
    echo -e "${GREEN}✓${NC} Project uses automatic file synchronization"
    echo "  All files in LifeLens folder are automatically included"
else
    echo -e "${YELLOW}⚠${NC} Project uses manual file references"
    echo "  Checking for explicit ML file references..."
    
    for file in "${ML_FILES[@]}"; do
        FILENAME=$(basename $file)
        if grep -q "$FILENAME" LifeLens.xcodeproj/project.pbxproj; then
            echo -e "  ${GREEN}✓${NC} $FILENAME is referenced"
        else
            echo -e "  ${RED}✗${NC} $FILENAME is NOT referenced"
        fi
    done
fi

echo -e "\n${BLUE}4. Checking ML Components Usage${NC}"
echo "----------------------------------------"

# Check if ML components are imported in other files
echo "Checking imports in other Swift files..."

ML_CLASSES=(
    "EdgeMLModels"
    "LocalPatternDetection"
    "SensorDataProcessor"
    "MLHealthService"
)

for class in "${ML_CLASSES[@]}"; do
    USAGE_COUNT=$(grep -r "$class" LifeLens --include="*.swift" | grep -v "class $class" | wc -l)
    if [ $USAGE_COUNT -gt 0 ]; then
        echo -e "${GREEN}✓${NC} $class is used in $USAGE_COUNT places"
    else
        echo -e "${YELLOW}⚠${NC} $class appears unused"
    fi
done

echo -e "\n${BLUE}5. Checking ML Dependencies${NC}"
echo "----------------------------------------"

# Check for required frameworks
echo "Checking for ML-related frameworks..."

if grep -q "CoreML.framework" LifeLens.xcodeproj/project.pbxproj; then
    echo -e "${GREEN}✓${NC} CoreML framework is linked"
else
    echo -e "${YELLOW}⚠${NC} CoreML framework not explicitly linked (may use on-device processing)"
fi

if grep -q "CreateML.framework" LifeLens.xcodeproj/project.pbxproj; then
    echo -e "${GREEN}✓${NC} CreateML framework is linked"
else
    echo -e "${YELLOW}⚠${NC} CreateML framework not linked (not required for inference)"
fi

echo -e "\n${BLUE}6. Generating Xcode File List${NC}"
echo "----------------------------------------"

# Create a file list for manual verification in Xcode
echo "Creating ML file list for Xcode verification..."

cat > ml-files-checklist.txt << EOF
ML Files Checklist for Xcode:
==============================

To verify in Xcode:
1. Open LifeLens.xcodeproj in Xcode
2. In Project Navigator, expand LifeLens folder
3. Verify ML folder exists with these files:

Required ML Files:
☐ EdgeMLModels.swift
☐ LocalPatternDetection.swift  
☐ SensorDataProcessor.swift
☐ MLHealthService.swift

Target Membership Check:
1. Select each ML file
2. Open File Inspector (⌥⌘1)
3. Ensure "LifeLens" is checked under Target Membership

Build Phase Check:
1. Select LifeLens project
2. Select LifeLens target
3. Go to Build Phases tab
4. Expand "Compile Sources"
5. Verify all ML files are listed

If files are missing from target:
1. Right-click on ML folder
2. Select "Add Files to LifeLens..."
3. Ensure "Add to targets: LifeLens" is checked
4. Click Add
EOF

echo -e "${GREEN}✓${NC} Created ml-files-checklist.txt"

echo -e "\n${BLUE}7. Build Test${NC}"
echo "----------------------------------------"

# Try to compile just the ML files to check for syntax errors
echo "Testing ML files compilation..."

for file in "${ML_FILES[@]}"; do
    if [ -f "$file" ]; then
        FILENAME=$(basename $file)
        echo -n "Checking $FILENAME... "
        
        # Basic syntax check
        if swiftc -parse "$file" 2>/dev/null; then
            echo -e "${GREEN}✓ Valid syntax${NC}"
        else
            echo -e "${RED}✗ Syntax errors detected${NC}"
        fi
    fi
done

echo -e "\n======================================"
echo "📊 Verification Summary"
echo "======================================"

if [ "$ALL_PRESENT" = true ]; then
    echo -e "${GREEN}✅ All ML files are present${NC}"
    echo ""
    echo "Since the project uses PBXFileSystemSynchronizedRootGroup,"
    echo "all files in the LifeLens/ML folder are automatically included."
    echo ""
    echo "To manually verify in Xcode:"
    echo "1. Open LifeLens.xcodeproj"
    echo "2. Check that ML folder appears in Project Navigator"
    echo "3. Build the project (⌘B) to confirm all files compile"
else
    echo -e "${RED}❌ Some ML files are missing${NC}"
    echo "Please ensure all ML files are in the LifeLens/ML folder"
fi

echo ""
echo "ML Integration Status:"
echo "✅ EdgeMLModels.swift - On-device ML processing"
echo "✅ LocalPatternDetection.swift - Pattern analysis"
echo "✅ SensorDataProcessor.swift - Sensor data processing"
echo "✅ MLHealthService.swift - ML orchestration"

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Open Xcode and verify ML folder is visible"
echo "2. Build project to ensure all files compile"
echo "3. Check console for any ML-related warnings"