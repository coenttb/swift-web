import EmailAddress
import Foundation
import Tagged


public struct AccessToken: Codable {
  public var accessToken: String
  
  public init(accessToken: String) {
    self.accessToken = accessToken
  }
  
  private enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
  }
}


public struct OAuthError: Codable {
  public var description: String
  public var error: Error
  public var errorUri: String
  
  public init(description: String, error: Error, errorUri: String) {
    self.description = description
    self.error = error
    self.errorUri = errorUri
  }
  
  public enum Error: String, Codable {
    /// <https://developer.github.com/apps/managing-oauth-apps/troubleshooting-oauth-app-access-token-request-errors/#bad-verification-code>
    case badVerificationCode = "bad_verification_code"
  }
  
  private enum CodingKeys: String, CodingKey {
    case description
    case error
    case errorUri = "error_uri"
  }
}


public struct GitHubUser: Codable, Identifiable {
  public var createdAt: Date
  public var id: Tagged<Self, Int>
  public var name: String?
  
  public init(createdAt: Date, id: Tagged<Self, Int>, name: String? = nil) {
    self.createdAt = createdAt
    self.id = id
    self.name = name
  }
  
  
  public struct Email: Codable {
    public var email: EmailAddress
    public var primary: Bool
    
    public init(email: EmailAddress, primary: Bool) {
      self.email = email
      self.primary = primary
    }
  }
  
  private enum CodingKeys: String, CodingKey {
    case createdAt = "created_at"
    case id
    case name
  }
}


public struct GitHubUserEnvelope: Codable {
  public var accessToken: AccessToken
  public var gitHubUser: GitHubUser
  
  public init(accessToken: AccessToken, gitHubUser: GitHubUser) {
    self.accessToken = accessToken
    self.gitHubUser = gitHubUser
  }
}
