//
//  UserManager.swift
//  OnestapSDK
//
//  Created by Munir Wanis on 22/08/17.
//  Copyright © 2017 Stone Payments. All rights reserved.
//

import Foundation

protocol UserManager {
    func temporaryProfile()
}

public class UserManagerImplementation: UserManager {
    let apiClient: ApiClient
    
    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
    
    func temporaryProfile() {
        guard OST.configuration.temporaryProfile != nil else {
            return
        }
        
        let temporaryProfileApiRequest = TemporaryProfileApiRequest()
        
        apiClient.execute(request: temporaryProfileApiRequest) { (result: Result<ApiResponse<ApiTemporaryProfile>>) in
            switch result {
            case let .success(response):
                OST.configuration.temporaryProfileDataKey = response.entity.dataKey
            case .failure(_): break
            }
        }
    }
}
