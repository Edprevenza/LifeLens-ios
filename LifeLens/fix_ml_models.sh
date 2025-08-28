#!/bin/bash

echo "Fixing all MLModel configuration issues..."

# Fix lines 128, 136, 144, 152, 160
sed -i '' '125,165s/self?.bpModel = try? MLModel(contentsOf: bpURL,[[:space:]]*configuration: self?.getNeuralEngineConfig())/if let config = self?.getNeuralEngineConfig() { self?.bpModel = try? MLModel(contentsOf: bpURL, configuration: config) }/' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/CoreMLEdgeModels.swift

sed -i '' '125,165s/self?.glucoseModel = try? MLModel(contentsOf: glucoseURL,[[:space:]]*configuration: self?.getNeuralEngineConfig())/if let config = self?.getNeuralEngineConfig() { self?.glucoseModel = try? MLModel(contentsOf: glucoseURL, configuration: config) }/' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/CoreMLEdgeModels.swift

sed -i '' '125,165s/self?.spo2Model = try? MLModel(contentsOf: spo2URL,[[:space:]]*configuration: self?.getNeuralEngineConfig())/if let config = self?.getNeuralEngineConfig() { self?.spo2Model = try? MLModel(contentsOf: spo2URL, configuration: config) }/' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/CoreMLEdgeModels.swift

sed -i '' '125,165s/self?.stressModel = try? MLModel(contentsOf: stressURL,[[:space:]]*configuration: self?.getNeuralEngineConfig())/if let config = self?.getNeuralEngineConfig() { self?.stressModel = try? MLModel(contentsOf: stressURL, configuration: config) }/' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/CoreMLEdgeModels.swift

sed -i '' '125,165s/self?.respiratoryModel = try? MLModel(contentsOf: respiratoryURL,[[:space:]]*configuration: self?.getNeuralEngineConfig())/if let config = self?.getNeuralEngineConfig() { self?.respiratoryModel = try? MLModel(contentsOf: respiratoryURL, configuration: config) }/' /Users/basorge/Desktop/LifeLens/Ios/LifeLens/LifeLens/ML/CoreMLEdgeModels.swift

echo "Fixed!"
