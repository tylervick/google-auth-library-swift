// Copyright 2019 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif
import Dispatch
import CryptoSwift

public class Connection {
  public var provider: TokenProvider
  private var urlSession: URLSession?

  public init(provider: TokenProvider, urlSession: URLSession?) {
    self.provider = provider
    self.urlSession = urlSession
  }

  convenience public init(provider: TokenProvider) {
    self.init(provider: provider, urlSession: nil)
  }
  
  public class func performRequest(
    method: String,
    urlString: String,
    parameters: [String: String],
    body: Data!,
    authorization: String,
    urlSession: URLSession?,
    callback: @escaping (Data?, URLResponse?, Error?) -> Void) {
    
    var urlComponents = URLComponents(string: urlString)!
    
    var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
    for (key, value) in parameters {
      queryItems.append(URLQueryItem(name: key, value: value))
    }
    if method == "GET" || body != nil {
      urlComponents.queryItems = queryItems
    }
    
    var request = URLRequest(url: urlComponents.url!)
    request.setValue(authorization, forHTTPHeaderField: "Authorization")
    request.httpMethod = method
    if method == "POST" || method == "PUT" {
      if let body = body {
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      } else {
        var postComponents = URLComponents(string: "")!
        postComponents.queryItems = queryItems
        let string = postComponents.url!.query!
        request.httpBody = string.data(using: .utf8)
      }
    }
    
    let session = urlSession ?? URLSession(configuration: URLSessionConfiguration.default)
    
    let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) -> Void in
      callback(data, response, error)
    }
    task.resume()
  }
  
  public func performRequest(
    method: String,
    urlString: String,
    parameters: [String: String],
    body: Data!,
    callback: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
    
    try provider.withToken {token, err in
      guard let token = token else {
        return
      }
      guard let accessToken = token.AccessToken else {
        return
      }
      Connection.performRequest(
        method: method,
        urlString: urlString,
        parameters: parameters,
        body: body,
        authorization: "Bearer " + accessToken,
        urlSession: self.urlSession,
        callback: callback)
    }
  }
  
  public func performRequest(
    method: String,
    urlString: String,
    callback: @escaping (Data?, URLResponse?, Error?) -> Void) throws {
    
    let parameters: [String: String] = [:]
    try performRequest(
      method: method,
      urlString: urlString,
      parameters: parameters,
      body: nil,
      callback: callback)
  }
}
