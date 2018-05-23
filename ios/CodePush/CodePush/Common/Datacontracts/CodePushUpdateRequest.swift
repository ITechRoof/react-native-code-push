//
//  CodePushUpdateRequest.swift
//  CodePush
//
//  Copyright © 2018 MSFT. All rights reserved.
//

import Foundation


class CodePushUpdateRequest: Codable {
    
    /**
     * Specifies the deployment key you want to query for an update against.
     */
    var deploymentKey: String?
    
    /**
     * Specifies the current app version.
     */
    var appVersion: String?
    
    /**
     * Specifies the current local package hash.
     */
    var packageHash: String?
    
    /**
     * Whether to ignore the application version.
     */
    var isCompanion: Bool = false
    
    /**
     * Specifies the current package label.
     */
    var label: String?
    
    /**
     * Device id.
     */
    var clientUniqueId: String?
    
    /**
     * Creates an update request based on the current {@link CodePushLocalPackage}.
     *
     * Parameter deploymentKey   the deployment key you want to query for an update against.
     * Parameter codePushPackage currently installed local package.
     * Parameter clientUniqueId  id of the device.
     * Returns: instance of the ```CodePushUpdateRequest```.
     */
    static func createUpdateRequest(withKey deploymentKey: String,
                                    withLocalPackage codePushPackage: CodePushLocalPackage,
                                    withClientUniqueId clientUniqueId: String) -> CodePushUpdateRequest {
        let codePushUpdateRequest = CodePushUpdateRequest()
        codePushUpdateRequest.appVersion = codePushPackage.appVersion
        codePushUpdateRequest.deploymentKey = deploymentKey
        codePushUpdateRequest.packageHash = codePushPackage.packageHash
        codePushUpdateRequest.label = codePushPackage.label
        codePushUpdateRequest.clientUniqueId = clientUniqueId
        return codePushUpdateRequest
    }
    
    init() {}
}
