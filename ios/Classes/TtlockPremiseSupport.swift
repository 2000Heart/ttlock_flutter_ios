import Foundation
import TTLockSDK

enum TtlockPremiseNewArchError: Error {
  case notImplemented(String)
  case invalidValue(String)
}

func makeLockApiError(operation: String, error: TTLockSDK.TTError, message: String?)
  -> PigeonError
{
  let mapped = lockErrorConvert(error)
  let fallback = "\(operation) failed: \(error.rawValue)"
  return PigeonError(code: "\(mapped.rawValue)", message: message ?? fallback, details: operation)
}

func makeGatewayApiError(
  operation: String, error: TTLockSDK.TTGatewayStatus, message: String? = nil
) -> PigeonError {
  let mapped = gatewayErrorConvert(error)
  let fallback = "\(operation) failed: \(error.rawValue)"
  return PigeonError(code: "\(mapped.rawValue)", message: message ?? fallback, details: operation)
}

func makeRemoteAccessoryApiError(
  operation: String, error: TTLockSDK.TTKeyFobStatus, message: String? = nil
) -> PigeonError {
  let mapped = remoteErrorConvert(error)
  let fallback = "\(operation) failed: \(error.rawValue)"
  return PigeonError(code: "\(mapped.rawValue)", message: message ?? fallback, details: operation)
}

func makeKeypadAccessoryApiError(
  operation: String, error: TTLockSDK.TTKeypadStatus, message: String? = nil
) -> PigeonError {
  let mapped = keypadErrorConvert(error)
  let fallback = "\(operation) failed: \(error.rawValue)"
  return PigeonError(code: "\(mapped.rawValue)", message: message ?? fallback, details: operation)
}

func makeDoorSensorApiError(
  operation: String, error: TTLockSDK.TTDoorSensorError, message: String? = nil
) -> PigeonError {
  let mapped = doorSensorErrorConvert(error)
  let fallback = "\(operation) failed: \(error.rawValue)"
  return PigeonError(code: "\(mapped.rawValue)", message: message ?? fallback, details: operation)
}

func makeWaterMeterApiError(
  operation: String, error: TTLockSDK.TTWaterMeterError, message: String? = nil
) -> PigeonError {
  let mapped = waterMeterErrorConvert(error)
  let fallback = "\(operation) failed: \(error.rawValue)"
  return PigeonError(code: "\(mapped.rawValue)", message: message ?? fallback, details: operation)
}

func makeElectricMeterApiError(
  operation: String, error: TTLockSDK.TTElectricMeterError, message: String? = nil
) -> PigeonError {
  let mapped = electricMeterErrorConvert(error)
  let fallback = "\(operation) failed: \(error.rawValue)"
  return PigeonError(code: "\(mapped.rawValue)", message: message ?? fallback, details: operation)
}

func makeMultifunctionalKeypadApiError(
  operation: String, error: TTLockSDK.TTKeypadStatus, message: String? = nil
) -> PigeonError {
  let mapped = multifunctionalKeypadErrorConvert(error)
  let fallback = "\(operation) failed: \(error.rawValue)"
  return PigeonError(code: "\(mapped.rawValue)", message: message ?? fallback, details: operation)
}

/// 各 EventChannel 专用参数槽，由对应 HostApi `set*Param` 写入。
final class EventContextStore {
  static let shared = EventContextStore()
  private init() {}

  struct LockScanWifiSlot {
    var lockData: String?
  }

  struct LockCredentialSlot {
    var lockData: String?
    var cycleList: [[String: Any]]?
    var startDateMs: Int64 = 0
    var endDateMs: Int64 = 0

    mutating func apply(_ param: TTLockCredentialEventParam) {
      lockData = param.lockData
      startDateMs = param.startDate
      endDateMs = param.endDate
      cycleList = param.cycleList?.map { $0.toMap() }
    }

    func cyclicConfigForSdk() -> [[String: Any]] {
      cycleList ?? []
    }
  }

  struct GatewayNearbyWifiSlot {
    var gatewayMac: String?
  }

  struct KeypadCredentialSlot {
    var keypadMac: String?
    var lockData: String?
    var isMultifunctionalKeypad = false
    var cycleList: [[String: Any]]?
    var startDateMs: Int64 = 0
    var endDateMs: Int64 = 0

    mutating func apply(_ param: TTKeypadCredentialEventParam) {
      keypadMac = param.keypadMac
      lockData = param.lockData
      isMultifunctionalKeypad = param.isMultifunctional
      startDateMs = param.startDate
      endDateMs = param.endDate
      cycleList = param.cycleList?.map { $0.toMap() }
    }

    func cyclicConfigForSdk() -> [[String: Any]] {
      cycleList ?? []
    }
  }

  var lockScanWifi = LockScanWifiSlot()
  var lockAddCard = LockCredentialSlot()
  var lockAddFingerprint = LockCredentialSlot()
  var lockAddFace = LockCredentialSlot()
  var lockAddPalmVein = LockCredentialSlot()
  var gatewayGetNearbyWifi = GatewayNearbyWifiSlot()
  var accessoryAddKeypadFingerprint = KeypadCredentialSlot()
  var accessoryAddKeypadCard = KeypadCredentialSlot()
}

extension TTCycleModel {
  func toMap() -> [String: Any] {
    [
      "weekDay": weekDay,
      "startTime": startTime,
      "endTime": endTime,
    ]
  }
}
