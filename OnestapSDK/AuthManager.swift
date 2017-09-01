//
//  TokenManager.swift
//  OnestapSDK
//
//  Created by Munir Wanis on 21/08/17.
//  Copyright © 2017 Stone Payments. All rights reserved.
//

import Foundation
import SafariServices

protocol AuthManager {
    func refreshToken(completion: @escaping (_ tokens: Result<Token>) -> Void)
    func accessToken(completion: @escaping (_ tokens: Result<Token>) -> Void)
    func verifyToken(completion: @escaping (_ tokens: Result<Token>) -> Void)
    func revokeToken(completion: @escaping (_ tokens: Result<GenericResponse>) -> Void)
    func handleRedirect(fromUrl url: URL, completion: @escaping (_ tokens: Result<Token>) -> Void)
    func loadAuthPage(viewController: UIViewController?)
}

public class AuthManagerImplementation: AuthManager {
    let apiClient: ApiClient
    
    static var safariViewController: SFSafariViewController?
    
    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }
    
    func refreshToken(completion: @escaping (_ result: Result<Token>) -> Void) {
        let tokenApiRequest = RefreshTokenApiRequest()
        
        apiClient.execute(request: tokenApiRequest) { (result: Result<ApiResponse<ApiToken>>) in
            switch result {
            case let .success(response):
                let token = response.entity.token
                UserDefaults.standard.accessToken = token.accessToken
                UserDefaults.standard.refreshToken = token.refreshToken
                completion(.success(token))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func accessToken(completion: @escaping (_ result: Result<Token>) -> Void) {
        let tokenApiRequest = AccessTokenApiRequest()
        
        apiClient.execute(request: tokenApiRequest) { (result: Result<ApiResponse<ApiToken>>) in
            switch result {
            case let .success(response):
                let token = response.entity.token
                UserDefaults.standard.accessToken = token.accessToken
                UserDefaults.standard.refreshToken = token.refreshToken
                UserDefaults.standard.userKey = token.userKey
                
                OST.shared.fingerPrint.sendFingerPrint()
                
                completion(.success(token))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func handleRedirect(fromUrl url: URL, completion: @escaping (_ result: Result<Token>) -> Void) {
        do {
            let redirectHandler = try RedirectHandlerImplementation(bundle: Bundle.main.infoDictionary)
            try redirectHandler.handleUri(open: url)
        } catch let error {
            completion(.failure(error))
        }
        
        accessToken { result in
            AuthManagerImplementation.safariViewController?.dismiss(animated: true, completion: nil)
            completion(result)
        }
    }
    
    func verifyToken(completion: @escaping (_ result: Result<Token>) -> Void) {
        let tokenApiRequest = VerifyTokenApiRequest()
        
        apiClient.execute(request: tokenApiRequest) { (result: Result<ApiResponse<ApiToken>>) in
            switch result {
            case let .success(response):
                let token = response.entity.token
                UserDefaults.standard.accessToken = token.accessToken
                completion(.success(token))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func revokeToken(completion: @escaping (_ result: Result<GenericResponse>) -> Void) {
        let tokenApiRequest = RevokeTokenApiRequest()
        
        apiClient.execute(request: tokenApiRequest) { (result: Result<ApiResponse<ApiToken>>) in
            UserDefaults.standard.accessToken = nil
            UserDefaults.standard.refreshToken = nil
            UserDefaults.standard.userKey = nil
            
            switch result {
            case let .success(response):
                let genericResponse = GenericResponse(success: response.success, operationReport: response.operationReport)
                completion(.success(genericResponse))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func loadAuthPage(viewController: UIViewController? = nil) {
        let url = RedirectHandlerImplementation.getLoginUrl(dataKey: OST.configuration.temporaryProfileDataKey)
        if let vc = viewController {
            openAuthPageOnSafariViewController(url: url, viewController: vc)
        } else {
            openAuthPageOnBrowser(url: url)
        }
    }
    
    private func openAuthPageOnBrowser(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    private func openAuthPageOnSafariViewController(url: URL, viewController: UIViewController) {
        AuthManagerImplementation.safariViewController = SFSafariViewController(url: url)
        
        if let primaryColor = OST.configuration.primaryColor {
            AuthManagerImplementation.safariViewController?.preferredBarTintColor = primaryColor
        }
        if let secondaryColor = OST.configuration.secondaryColor {
          AuthManagerImplementation.safariViewController?.preferredControlTintColor = secondaryColor
        }
        viewController.present(AuthManagerImplementation.safariViewController!, animated: true, completion: nil)
    }
}

