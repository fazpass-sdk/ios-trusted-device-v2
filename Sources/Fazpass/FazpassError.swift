
import Foundation

public enum FazpassError : Error {
    case biometricNoneEnrolled
    case biometricAuthFailed
    case biometricNotAvailable
    case biometricNotInteractive
    case encryptionError(String)
    case publicKeyNotExist
    case uninitialized
    case unknownError(Error)
}
