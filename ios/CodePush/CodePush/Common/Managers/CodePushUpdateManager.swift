//
//  CodePushUpdateManager.swift
//  CodePush
//
//  Copyright © 2018 MSFT. All rights reserved.
//

import Foundation


/**
 * Manager responsible for update read/write actions.
 */
class CodePushUpdateManager {

    /**
     * Platform-specific utils implementation.
     */
    var platformUtils: CodePushPlatformUtils

    /**
     * Instance of ```FileUtils``` to work with.
     */
    var fileUtils: FileUtils

    /**
     * Instance of ```CodePushUpdateUtils``` to work with.
     */
    var codePushUpdateUtils: CodePushUpdateUtils

    /**
     * Instance of ```CodePushUtils``` to work with.
     */
    var codePushUtils: CodePushUtils

    /**
     * General path for storing files.
     */
    var documentsDirectory: URL

    /**
     * CodePush configuration for instance.
     */
    var codePushConfiguration: CodePushConfiguration?

    /**
     * Byte signature designating a compressed folder
     */
    let zipHeader = [0x50, 0x4b, 0x03, 0x04]

    /**
     * Creates instance of CodePushUpdateManager.
     *
     * Parameter documentsDirectory  path for storing files.
     * Parameter platformUtils       instance of ```CodePushPlatformUtils``` to work with.
     * Parameter fileUtils           instance of ```FileUtils``` to work with.
     * Parameter codePushUtils       instance of ```CodePushUtils``` to work with.
     * Parameter codePushUpdateUtils instance of ```CodePushUpdateUtils``` to work with.
     * Parameter codePushConfiguration instance of ```CodePushConfiguration``` to work with.
     */
    init(_ documentsDirectory: URL, _ platformUtils: CodePushPlatformUtils, _ fileUtils: FileUtils,
         _ codePushUtils: CodePushUtils, _ codePushUpdateUtils: CodePushUpdateUtils,
         _ codePushConfiguration: CodePushConfiguration?) {
        self.platformUtils = platformUtils
        self.fileUtils = fileUtils
        self.codePushUpdateUtils = codePushUpdateUtils
        self.codePushUtils = codePushUtils
        self.documentsDirectory = documentsDirectory
        self.codePushConfiguration = codePushConfiguration
    }

    /**
     * Gets path to json file containing information about the available packages.
     *
     * Returns: path to json file containing information about the available packages.
     */
    func getStatusFilePath() -> URL {
        return fileUtils.appendPathComponent(atBasePath: getCodePushPath(),
                                             withComponent: CodePushConstants.StatusFileName)
    }

    /**
     * Gets folder for the package by the package hash.
     *
     * Parameter packageHash current package identifier (hash).
     * Returns: path to package folder.
     */
    func getPackageFolderPath(withHash packageHash: String) -> URL {
        return fileUtils.appendPathComponent(atBasePath: getCodePushPath(), withComponent: packageHash)
    }

    /**
     * Gets application-specific folder.
     *
     * Returns: application-specific folder.
     */
    private func getCodePushPath() -> URL {
        return fileUtils.appendPathComponent(atBasePath: self.documentsDirectory,
                                             withComponent: (codePushConfiguration?.appName)!)
    }

    /**
     * Gets current package json object.
     *
     * Returns: current package json object.
     * Throws: Error if fails to retrieve the current package hash, or the subsequent package
     */
    func getCurrentPackage() throws -> CodePushLocalPackage? {
        let packageHash = try getCurrentPackageHash()
        if packageHash == nil {
            return nil
        } else {
            return try getPackage(withHash: packageHash!)
        }
    }

    /**
     * Gets the identifier of the previous installed package (hash).
     *
     * Returns: the identifier of the previous installed package.
     * Throws: Error if fails to resolve the local package metadata
     **/
    func getPreviousPackageHash() throws -> String? {
        let info = try getCurrentPackageInfo()
        return info.previousPackage
    }

    /**
     * Gets previous installed package json object.
     *
     * Returns: previous installed package json object or ```nil```
     * Throws: Error if fails to retrieve the previous package hash, or the subsequent package
     */
    func getPreviousPackage() throws -> CodePushLocalPackage? {

        let packageHash = try getPreviousPackageHash()
        if packageHash != nil {
            return try getPackage(withHash: packageHash!)
        } else {
            return nil
        }
    }

    /**
     * Gets package object by its hash.
     *
     * Parameter packageHash package identifier (hash).
     * Returns: package object.
     * Throws: Error if fails to resolve the package from the file system
     */
    func getPackage(withHash packageHash: String) throws -> CodePushLocalPackage {
        let folderPath = getPackageFolderPath(withHash: packageHash)
        let packageFilePath = fileUtils.appendPathComponent(atBasePath: folderPath, withComponent:
            CodePushConstants.PackageFileName)

        var localPackage: CodePushLocalPackage
        localPackage = try codePushUtils.getObjectFromJsonFile(packageFilePath)
        return localPackage
    }

    /**
     * Gets the identifier of the current package (hash).
     *
     * Returns: the identifier of the current package or ```nil```
     * Throws: Error if fails to resolve the current package
     */
    func getCurrentPackageHash() throws -> String? {
        let info = try getCurrentPackageInfo()
        return info.currentPackage
    }

    /**
     * Gets metadata about the current update.
     *
     * Returns: metadata about the current update.
     * Throws: Error if fails to resolve the current package
     */
    func getCurrentPackageInfo() throws -> CodePushPackageInfo {
        let statusFilePath = getStatusFilePath()
        if !fileUtils.fileExists(atPath: statusFilePath) {
            return CodePushPackageInfo()
        }

        var currentPackage: CodePushPackageInfo
        currentPackage = try codePushUtils.getObjectFromJsonFile(statusFilePath)
        return currentPackage
    }

    /**
     * Gets folder for storing current package files.
     *
     * Returns: folder for storing current package files or ```nil```
     * Throws: Error if fails to resolve the current package
     */
    func getCurrentPackagePath() throws -> URL? {
        let packageHash = try getCurrentPackageHash()
        if packageHash == nil {
            return nil
        } else {
            return getPackageFolderPath(withHash: packageHash!)
        }
    }

    /**
     * Gets folder for storing current package files.
     *
     * Returns: folder for storing previous package files.
     * Throws: Error if fails to resolve the local package metadata
     */
    func getPreviousPackagePath() throws -> URL? {
        let packageHash = try getPreviousPackageHash()
        if packageHash == nil {
            return nil
        } else {
            return getPackageFolderPath(withHash: packageHash!)
        }
    }

    /**
     * Deletes the current package and installs the previous one.
     *
     * Throws: Error if can't resolve the current package, delete the directory
     * of the current package, or write the subsequent changes to the file system
     * fails to retrieve
     */
    func rollbackPackage() throws {
        do {
            let info = try getCurrentPackageInfo()
            let currentPackageFolderPath = try getCurrentPackagePath()

            try fileUtils.deleteEntityAtPath(path: currentPackageFolderPath!)

            info.currentPackage = info.previousPackage
            info.previousPackage = nil
            try updateCurrentPackageInfo(package: info)
        } catch {
            throw CodePushPackageErrors.failedRollback(cause: error)
        }
    }

    /**
     * Updates file containing information about the available packages.
     *
     * Parameter packageInfo new information.
     * Throws: Error if fails to write the package info to the file system
     */
    func updateCurrentPackageInfo(package packageInfo: CodePushPackageInfo) throws {
        try codePushUtils.writeObjectToJsonFile(withObject: packageInfo, atPath: getStatusFilePath())
    }

    /**
     * Downloads the update package.
     *
     * Parameter packageHash            update package hash.
     * Parameter url to download the update from.
     * Parameter completion completion handler
     * Returns: downloaded package.
     */
    func downloadPackage(withHash packageHash: String, atUrl url: URL,
                         callback completion: @escaping (Result<CodePushDownloadPackageResult>) -> Void) {
        let newUpdateFolderPath = getPackageFolderPath(withHash: packageHash)

        if fileUtils.fileExists(atPath: newUpdateFolderPath) {

            /* This removes any stale data in ```newPackageFolderPath``` that could have been left
             * uncleared due to a crash or error during the download or install process. */
            do {
                try fileUtils.deleteEntityAtPath(path: newUpdateFolderPath)
            } catch {
                completion(Result { throw CodePushPackageErrors.failedDownload(cause: error) })
                return
            }
        }

        // Examine the byte signature to see if the package is a zip
        let api = ApiRequest(url)
        api.downloadUpdate(completion: { result in
            completion( Result {
                let downloadPath = try result.resolve()
                let fileSignature = try Data(contentsOf: downloadPath)[...(self.zipHeader.count - 1)]
                var isZip = true
                for (index, element) in self.zipHeader.enumerated() where element != fileSignature[index] {
                    isZip = false
                    break
                }
                return CodePushDownloadPackageResult(downloadPath, isZip)
            })
        })
    }

    /**
     * Installs the new package.
     *
     * Parameter packageHash         package hash to install.
     * Parameter removeCurrent whether to remove pending updates data.
     * Throws: Failed Install Error if an error occurs during the install process
     */
    func installPackage(packageHash hash: String?,
                        removeCurrentUpdate removeCurrent: Bool) throws {
        do {
            let info = try getCurrentPackageInfo()
            let currentPackageHash = try getCurrentPackageHash()
            if hash != nil && hash == currentPackageHash {
                /* The current package is already the one being installed, so we should no-op. */
                return
            }
            if removeCurrent {
                let currentPackageFolderPath = try getCurrentPackagePath()
                if currentPackageFolderPath != nil {
                    try fileUtils.deleteEntityAtPath(path: currentPackageFolderPath!)
                }
            } else {
                let previousPackageHash = try getPreviousPackageHash()
                if previousPackageHash != nil && previousPackageHash != hash {
                    try fileUtils.deleteEntityAtPath(path: getPackageFolderPath(withHash: previousPackageHash!))
                }
                info.previousPackage = info.currentPackage
            }
            info.currentPackage = hash
            try updateCurrentPackageInfo(package: info)
        } catch {
            throw CodePushPackageErrors.failedInstall(cause: error)
        }
    }

    /**
     * Merges contents with the current update based on the manifest.
     *
     * Parameter newUpdateFolderPath        directory for new update.
     * Parameter newUpdateMetadataPath      path to update metadata file for new update.
     * Parameter expectedEntryPointFileName file name of the entry app point.
     * Returns: actual new app entry point.
     * Throws: Error if an exception occurred during merging.
     */
    func mergeDiff(newUpdate newUpdateFolderPath: URL, entryPoint expectedEntryPoint: String,
                   withApp appName: String) throws -> String {

        let diffManifestFilePath = fileUtils.appendPathComponent(atBasePath: newUpdateFolderPath,
                                                                 withComponent: CodePushConstants.DiffManifestFileName)
        let unzippedPath = fileUtils.appendPathComponent(atBasePath: newUpdateFolderPath,
                                                         withComponent: CodePushConstants.UnzippedFolderName)

        /* If this is a diff, not full update, copy the new files to the package directory. */
        let isDiffUpdate = fileUtils.fileExists(atPath: diffManifestFilePath)

        let newPackageFolder = fileUtils.appendPathComponent(atBasePath: newUpdateFolderPath,
                                                             withComponent: appName)
        if isDiffUpdate {
            let currentPackageFolderPath = try getCurrentPackagePath()
            if currentPackageFolderPath != nil {
                let currentPackageFolder = fileUtils.appendPathComponent(atBasePath: currentPackageFolderPath!,
                                                                         withComponent: appName)

                try codePushUpdateUtils.copyNecessaryFilesFromCurrentPackage(diffFile: diffManifestFilePath,
                                                                             currentPackagePath: currentPackageFolder,
                                                                             newPackagePath: newPackageFolder)
            }
            try fileUtils.deleteEntityAtPath(path: diffManifestFilePath)
        }

        // Copy the new package contents over
        try fileUtils.copyDirectoryContents(fromSource: unzippedPath, toDest: newPackageFolder)
        try fileUtils.deleteEntityAtPath(path: unzippedPath)

        let appEntryPoint = try codePushUpdateUtils.findEntryPointInUpdateContents(atOrigin: newUpdateFolderPath,
                                                                                   targetFile: expectedEntryPoint)
        if appEntryPoint == nil {
            throw CodePushErrors
                .merge(cause: String(format: """
                                             Update is invalid - An entry point file named '%@' could
                                             not be found within the downloaded contents. Please check
                                             that you are releasing your CodePush updates using the exact
                                             same JS entry point file name that was shipped with your
                                             app's binary.
                                             """, expectedEntryPoint))
        } else {
            return appEntryPoint!.absoluteString
        }
    }

    /**
     * Unzips the following package file and renames it to ```CodePushConstants.UnzippedFolderName```
     *
     * Parameter downloadFile package file.
     * Throws: CodePushUnzipException an exception occurred during unzipping.
     */
    func unzipPackage(withPackage package: URL, toDestination destination: URL) throws {

        do {
            try fileUtils.unzipDirectory(source: package, destination: destination)

            // Locate the newly unzipped folder and rename it
            let unzippedFolder = try FileManager.default.contentsOfDirectory(atPath: destination.path)[0]
            var resourceValues = URLResourceValues()
            resourceValues.name = CodePushConstants.UnzippedFolderName

            var renamedDirectory = fileUtils.appendPathComponent(atBasePath: destination,
                                                                 withComponent: unzippedFolder)

            try renamedDirectory.setResourceValues(resourceValues)
        } catch {
            throw CodePushErrors.unzip(cause: error)
        }
    }
}
