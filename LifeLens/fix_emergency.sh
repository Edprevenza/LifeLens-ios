#!/bin/bash

# Fix EmergencyResponseSystem properly
if [ -f "LifeLens/Emergency/EmergencyResponseSystem.swift" ]; then
    echo "Fixing EmergencyResponseSystem UIApplication calls..."
    
    # First remove the incorrect fixes
    sed -i '' 's/#if canImport(UIKit)//g' LifeLens/Emergency/EmergencyResponseSystem.swift
    sed -i '' 's/#endif//g' LifeLens/Emergency/EmergencyResponseSystem.swift
    
    # Now fix line 369-373
    sed -i '' '369,373d' LifeLens/Emergency/EmergencyResponseSystem.swift
    sed -i '' '369i\
        if let url = URL(string: "tel://\\(number)") {\
            #if canImport(UIKit)\
            if UIApplication.shared.canOpenURL(url) {\
                UIApplication.shared.open(url)\
            }\
            #endif\
        }' LifeLens/Emergency/EmergencyResponseSystem.swift
    
    # Fix line 682-686
    sed -i '' '682,686d' LifeLens/Emergency/EmergencyResponseSystem.swift
    sed -i '' '682i\
            if let url = URL(string: "tel://\\(number)") {\
                #if canImport(UIKit)\
                if UIApplication.shared.canOpenURL(url) {\
                    UIApplication.shared.open(url)\
                    break\
                }\
                #endif\
            }' LifeLens/Emergency/EmergencyResponseSystem.swift
fi

echo "Emergency fixes completed!"
