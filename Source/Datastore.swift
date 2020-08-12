//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  DataStore.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import Foundation
import CoreML
import NMSSH


struct DatastoreSettings: Codable {
    public var remoteHost: String = "172.22.167.12:22" //"mbp2015:22"
    public var remoteUsername: String = "username"
    public var remotePassword: String = "password"
    public var remoteDirectory: String = "/Users/fuehner/git/af/ASV/model/training-data"
    public var remoteMlModelName: String = "autodriver.mlmodel"
    public var localMlModelName: String = "autodriver.mlmodel"
}


class Datastore: ObservableObject {
    static let sharedInstance = Datastore()
    var settings = DatastoreSettings()

    private let dispatchQueue = DispatchQueue(label: "DataStoreQueue")
    private let fileManager = FileManager.default


    // ***** UI-observable properties *****

    private(set) var numberOfTrainingDatasets: Int = 0 {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private(set) var currentCompletionPercent: Double = 0 {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private(set) var currentStatus: String = "" {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }


    // ***** Init *****
    
    init() {
        determineNumberOfTrainingDatasets()
    }


    // ***** Helper *****

    private func docUrl(filename: String) -> URL? {
        if let baseUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return baseUrl.appendingPathComponent(filename)
        } else {
            return nil
        }
    }


    private func addPathNameTo(baseName: String, addName: String) -> String {
        if !baseName.isEmpty && !baseName.hasSuffix("/") {
            return baseName + "/" + addName
        } else {
            return baseName + addName
        }
    }


    func determineNumberOfTrainingDatasets() {
        if let baseUrl = docUrl(filename: "") {
            if let entries = try? fileManager.contentsOfDirectory(atPath: baseUrl.path) {
                let trainingImages = entries.filter() { $0.hasPrefix("train-") && $0.hasSuffix(".jpg") }
                numberOfTrainingDatasets = trainingImages.count
            }
        }
        // fall-through for errors
        numberOfTrainingDatasets = 0
    }


    // ***** Manage local training data storage *****

    func recordTrainingData(cgImage: CGImage, steering: Float, throttle: Float, timestampInMs: UInt64) {
        // create filename
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let dateStr = formatter.string(from: now)
        let imgFnStr = "train-\(dateStr).jpg"
        let jsonFnStr = "train-\(dateStr).json"

        // save image
        let uiImage = UIImage(cgImage: cgImage)
        guard let imageData = uiImage.jpegData(compressionQuality: 0.9), let imgUrl = docUrl(filename: imgFnStr) else {
            return
        }
        do { try imageData.write(to: imgUrl) } catch {
            return
        }

        // save json
        struct TrainingDataPoint : Codable {
            let steering: Float
            let throttle: Float
            let image: String
            let timestamp: UInt64?
        }
        let trainingDataPoint = TrainingDataPoint(steering: steering, throttle: throttle, image: imgFnStr, timestamp: timestampInMs)
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(trainingDataPoint),
              let jsonUrl = docUrl(filename: jsonFnStr) else {
            try? fileManager.removeItem(atPath: imgUrl.path)
            return
        }
        do {
            try jsonData.write(to: jsonUrl)
            numberOfTrainingDatasets += 1
        } catch {
            try? fileManager.removeItem(atPath: imgUrl.path)
            return
        }
    }


    func deleteAllTrainingDataSync() {
        if let baseUrl = docUrl(filename: "") {
            if let entries = try? fileManager.contentsOfDirectory(atPath: baseUrl.path) {
                let trainingFiles = entries.filter() { $0.hasPrefix("train-") }
                for entry in trainingFiles {
                    if let url = docUrl(filename: entry) {
                        try? fileManager.removeItem(at: url)
                    }
                }
            }
        }
        determineNumberOfTrainingDatasets()
    }

    func deleteAllTrainingDataAsync(completionHandler: @escaping ()->Void) {
        dispatchQueue.async {
            self.deleteAllTrainingDataSync()
            completionHandler()
        }
    }


    // ***** Manage training data SSH storage *****

    func moveTrainingDataToHostSync() {
        currentStatus = "Connecting"
        let session = NMSSHSession(host: settings.remoteHost, andUsername: settings.remoteUsername)
        if !session.connect() {
            print("DataStore::sync: cannot connect to \(settings.remoteHost)")
            return
        }
        currentStatus = "Authenticating"
        if !session.authenticate(byPassword: settings.remotePassword) {
            print("DataStore::sync: cannot authenticate \(settings.remoteUsername)@\(settings.remoteHost)")
            return
        }
        currentStatus = "Uploading"
        if let baseUrl = docUrl(filename: "") {
            if let entries = try? fileManager.contentsOfDirectory(atPath: baseUrl.path) {
                let trainingFiles = entries.filter() { $0.hasPrefix("train-") }
                let ofFiles = trainingFiles.count
                for (no, filename) in trainingFiles.enumerated() {
                    let localUrl = docUrl(filename: filename)!
                    let localRelativePathname = localUrl.path
                    let remotePathname = addPathNameTo(baseName: settings.remoteDirectory, addName: filename)
                    let success = session.channel.uploadFile(localRelativePathname, to: remotePathname)
                    if success {
                        try? fileManager.removeItem(at: localUrl)
                    }
                    currentCompletionPercent = Double(no) / Double(ofFiles)
                    currentStatus = "Uploading \(no)/\(ofFiles): \(filename)"
                }
            }
        }
        currentStatus = "Upload finished"
        determineNumberOfTrainingDatasets()
    }


    func moveTrainingDataToHostAsync(completionHandler: @escaping ()->Void) {
        dispatchQueue.async {
            self.moveTrainingDataToHostSync()
            completionHandler()
        }
    }

    
    // ***** Manage ML model storage *****

    func downloadMlModelSync() -> MLModel? {
        currentStatus = "Connecting"
        let session = NMSSHSession(host: settings.remoteHost, andUsername: settings.remoteUsername)
        if !session.connect() {
            print("DataStore::sync: cannot connect to \(settings.remoteHost)")
            return nil
        }
        currentStatus = "Authenticating"
        if !session.authenticate(byPassword: settings.remotePassword) {
            print("DataStore::sync: cannot authenticate \(settings.remoteUsername)@\(settings.remoteHost)")
            return nil
        }
        currentStatus = "Downloading"
        if let localFilenameUrl = docUrl(filename: settings.localMlModelName) {
            let remotePathname = addPathNameTo(baseName: settings.remoteDirectory, addName: settings.remoteMlModelName)
            let localPathname = localFilenameUrl.path
            let success = session.channel.downloadFile(remotePathname, to: localPathname)
            if success {
                currentStatus = "Compiling model"
                do {
                    let compiledModelURL = try MLModel.compileModel(at: localFilenameUrl)
                    currentStatus = "Loading model"
                    let model = try MLModel(contentsOf: compiledModelURL)
                    currentStatus = "Download Finished"
                    return model
                } catch {
                    print("Error compiling/loading MLModel from \(settings.remoteUsername)@\(settings.remoteHost)/\(remotePathname)")
                    currentStatus = "Error compiling/loading model"
                }
            }
        }
        // when this location is reached, an error has occured
        return nil
    }

    func downloadMlModelAsync(completionHandler: @escaping (_ model: MLModel?)->Void) {
        dispatchQueue.async {
            let model = self.downloadMlModelSync()
            completionHandler(model)
        }
    }

}
