
import Foundation

public enum FazpassError : Error {
    case biometricNoneEnrolled
    case biometricAuthFailed
    case biometricNotAvailable(message: String)
    case biometricNotInteractive
    case encryptionError(message: String)
    case publicKeyNotExist
    case uninitialized
}
