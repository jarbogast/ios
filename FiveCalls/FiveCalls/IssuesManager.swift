//
//  IssuesManager.swift
//  FiveCalls
//
//  Created by Ben Scheirman on 2/2/17.
//  Copyright © 2017 5calls. All rights reserved.
//

import Foundation

enum IssuesLoadResult {
    case success
    case serverError(Error)
    case offline
}

class IssuesManager {

    enum Query {
        case active
        case inactive
    }

    var issuesList: IssuesList?
    
    var issues: [Issue] {
        return issuesList?.issues ?? []
    }
    
    var isSplitDistrict: Bool { return self.issuesList?.splitDistrict == true }
    
    func issue(withId id: String) -> Issue? {
        return issuesList?.issues.filter { $0.id == id }.first
    }
    
    func fetchIssues(forQuery query: Query, location: UserLocation?, completion: @escaping (IssuesLoadResult) -> Void) {
        
        let operation = FetchIssuesOperation(query: query, location: location)
        
        operation.completionBlock = { [weak self, weak operation] in
            if let issuesList = operation?.issuesList {
                self?.issuesList = issuesList
                // notification!
                DispatchQueue.main.async {
                    completion(.success)
                }
            } else {
                let error = operation?.error
                print("Could not load issues..")
                
                DispatchQueue.main.async {
                    if let e = error {
                        print(e.localizedDescription)
                        
                        if self?.isOfflineError(error: e) == true {
                            completion(.offline)
                        } else {
                            completion(.serverError(e))
                        }
                        
                    } else {
                        // souldn't happen, but let's just assume connection error
                        completion(.offline)
                    }
                }
                
            }
        }
        OperationQueue.main.addOperation(operation)
    }
    
    private func isOfflineError(error: Error) -> Bool {
        let e = error as NSError
        guard e.domain == NSURLErrorDomain else { return false }
        
        return e.code == NSURLErrorNetworkConnectionLost ||
            e.code == NSURLErrorNotConnectedToInternet ||
            e.code == NSURLErrorSecureConnectionFailed
    }
}
