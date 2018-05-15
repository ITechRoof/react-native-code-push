//
//  CodePushUpdateManager.swift
//  CodePush
//
//  Copyright © 2018 MSFT. All rights reserved.
//

import Foundation


class CodePushUpdateManager {
    
    /**
     * Platform-specific utils implementation.
     */
    var platformUtils: CodePushPlatformUtils
    
    /**
     * Instance of {@link FileUtils} to work with.
     */
    var fileUtils: FileUtils
    
    /**
     * Instance of {@link CodePushUpdateUtils} to work with.
     */
    var codePushUpdateUtils: CodePushUpdateUtils
    
    /**
     * Instance of {@link CodePushUtils} to work with.
     */
    var codePushUtils: CodePushUtils
    
    /**
     * General path for storing files.
     */
    var documentsDirectory: String
    
    /**
     * CodePush configuration for instance.
     */
    var codePushConfiguration: CodePushConfiguration
    
    /**
     * Creates instance of CodePushUpdateManager.
     *
     * @param documentsDirectory  path for storing files.
     * @param platformUtils       instance of {@link CodePushPlatformUtils} to work with.
     * @param fileUtils           instance of {@link FileUtils} to work with.
     * @param codePushUtils       instance of {@link CodePushUtils} to work with.
     * @param codePushUpdateUtils instance of {@link CodePushUpdateUtils} to work with.
     * @param codePushConfiguration instance of {@link CodePushConfiguration} to work with.
     */
    init(_ documentsDirectory: String, _ platformUtils: CodePushPlatformUtils, _ fileUtils: FileUtils,
         _ codePushUtils: CodePushUtils, _ codePushUpdateUtils: CodePushUpdateUtils,
         _ codePushConfiguration: CodePushConfiguration) {
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
     * @return path to json file containing information about the available packages.
     */
    func getStatusFilePath() -> String {
        return fileUtils.appendPathComponent(atBasePath: getCodePushPath(), withComponent: CodePushConstants.STATUS_FILE_NAME)
    }
    
    /**
     * Gets folder for the package by the package hash.
     *
     * @param packageHash current package identifier (hash).
     * @return path to package folder.
     */
    func getPackageFolderPath(withHash packageHash: String) -> String {
        return fileUtils.appendPathComponent(atBasePath: getCodePushPath(), withComponent: packageHash);
    }
    
    /**
     * Gets application-specific folder.
     *
     * @return application-specific folder.
     */
    func getCodePushPath() -> String {
        let codePushPath = fileUtils.appendPathComponent(atBasePath: self.documentsDirectory, withComponent: codePushConfiguration.appName!);
        return codePushPath
    }
    
    /**
     * Gets current package json object.
     *
     * @return current package json object.
     * @throws CodePushGetPackageException exception occurred when obtaining a package.
     */
    func getCurrentPackage() -> CodePushLocalPackage? {
        let packageHash = getCurrentPackageHash()
        if (packageHash == nil) {
            return nil
        } else {
            return getPackage(withHash: packageHash!);
        }
    }
    
    /**
     * Gets the identifier of the previous installed package (hash).
     *
     * @return the identifier of the previous installed package.
     * @throws IOException                    read/write error occurred while accessing the file system.
     * @throws CodePushMalformedDataException error thrown when actual data is broken (i .e. different from the expected).
     **/
    func getPreviousPackageHash() -> String? {
        let info = getCurrentPackageInfo()
        return info.previousPackage
    }
    
    /**
     * Gets previous installed package json object.
     *
     * @return previous installed package json object.
     * @throws CodePushGetPackageException exception occurred when obtaining a package.
     */
    func getPreviousPackage() -> CodePushLocalPackage? {
        let packageHash = getPreviousPackageHash();

        if (packageHash == nil) {
            return nil
        } else {
            return getPackage(withHash: packageHash!)
        }
    }
    
    /**
     * Gets package object by its hash.
     *
     * @param packageHash package identifier (hash).
     * @return package object.
     * @throws CodePushGetPackageException exception occurred when obtaining a package.
     */
    func getPackage(withHash packageHash: String) -> CodePushLocalPackage {
        let folderPath = getPackageFolderPath(withHash: packageHash);
        let packageFilePath = fileUtils.appendPathComponent(atBasePath: folderPath, withComponent:
            CodePushConstants.PACKAGE_FILE_NAME);
        do {
            return codePushUtils.getObjectFromJsonFile(packageFilePath, CodePushLocalPackage.class);
        } catch {
            
        }
    }
    
    /**
     * Gets the identifier of the current package (hash).
     *
     * @return the identifier of the current package.
     * @throws IOException                    read/write error occurred while accessing the file system.
     * @throws CodePushMalformedDataException error thrown when actual data is broken (i .e. different from the expected).
     */
    func getCurrentPackageHash() -> String? {
        let info = getCurrentPackageInfo();
        return info.currentPackage
    }
    
    /**
     * Gets metadata about the current update.
     *
     * @return metadata about the current update.
     * @throws IOException                    read/write error occurred while accessing the file system.
     * @throws CodePushMalformedDataException error thrown when actual data is broken (i .e. different from the expected).
     */
    func getCurrentPackageInfo() -> CodePushPackageInfo {
        let statusFilePath = getStatusFilePath();
        if (!fileUtils.fileExists(atPath: statusFilePath)) {
            return CodePushPackageInfo();
        }
        
        return codePushUtils.getObjectFromJsonFile(statusFilePath, CodePushPackageInfo.class);
    }
}
