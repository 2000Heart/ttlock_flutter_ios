import Foundation
import TTLockSDK

final class AccessoryHostApiImpl: NSObject, TTAccessoryHostApi {

  private let context: EventContextStore
  init(context: EventContextStore) { self.context = context }

  func setAccessoryAddKeypadFingerprintParam(param: TTKeypadCredentialEventParam) throws {
    context.accessoryAddKeypadFingerprint.apply(param)
  }

  func setAccessoryAddKeypadCardParam(param: TTKeypadCredentialEventParam) throws {
    context.accessoryAddKeypadCard.apply(param)
  }

  func initRemoteKey(
    mac: String, lockData: String, completion: @escaping (Result<TTLockSystemModel, Error>) -> Void
  ) {
    TTWirelessKeyFob.newInitialize(withKeyFobMac: mac, lockData: lockData) {
      status, electricQuantity, systemModel in
      if status == TTKeyFobSuccess {
        completion(
          .success(
            TTLockSystemModel(
              modelNum: systemModel?.modelNum ?? "",
              hardwareRevision: systemModel?.hardwareRevision ?? "",
              firmwareRevision: systemModel?.firmwareRevision ?? "",
              electricQuantity: Int64(electricQuantity),
              nbOperator: nil,
              nbNodeId: nil,
              nbCardNumber: nil,
              nbRssi: nil,
              lockData: lockData
            )))
      } else {
        completion(
          .failure(makeRemoteAccessoryApiError(operation: "accessory.initRemoteKey", error: status))
        )
      }
    }
  }

  func initRemoteKeypad(
    mac: String, lockMac: String,
    completion: @escaping (Result<RemoteKeypadInitResult, Error>) -> Void
  ) {
    TTWirelessKeypad.initializeKeypad(withKeypadMac: mac, lockMac: lockMac) {
      wirelessKeypadFeatureValue, status, electricQuantity in
      if status == TTKeypadSuccess {
        completion(
          .success(
            RemoteKeypadInitResult(
              electricQuantity: Int64(electricQuantity),
              wirelessKeypadFeatureValue: wirelessKeypadFeatureValue ?? ""
            )))
      } else {
        completion(
          .failure(
            makeKeypadAccessoryApiError(operation: "accessory.initRemoteKeypad", error: status)))
      }
    }
  }

  func initMultifunctionalKeypad(
    mac: String, lockData: String,
    completion: @escaping (Result<MultifunctionalKeypadInitResult, Error>) -> Void
  ) {
    TTWirelessKeypad.initializeMultifunctionalKeypad(withKeypadMac: mac, lockData: lockData) {
      featureValue, electricQuantity, slotNumber, slotLimit, systemInfoModel in
      completion(
        .success(
          MultifunctionalKeypadInitResult(
            electricQuantity: Int64(electricQuantity),
            wirelessKeypadFeatureValue: featureValue ?? "",
            slotNumber: Int64(slotNumber),
            slotLimit: Int64(slotLimit),
            modelNum: systemInfoModel?.modelNum ?? "",
            hardwareRevision: systemInfoModel?.hardwareRevision ?? "",
            firmwareRevision: systemInfoModel?.firmwareRevision ?? "",
          )))
    } lockFailure: { errorCode, errorMsg in
      completion(
        .failure(
          makeLockApiError(
            operation: "accessory.initMultifunctionalKeypad.lockFailure", error: errorCode,
            message: errorMsg)))
    } keypadFailure: { status in
      completion(
        .failure(
          makeMultifunctionalKeypadApiError(
            operation: "accessory.initMultifunctionalKeypad.keypadFailure", error: status)))
    }
  }
  func getStoredLocks(mac: String, completion: @escaping (Result<[String], any Error>) -> Void) {
    TTWirelessKeypad.getAllStoredLocks(withKeypadMac: mac) { lockMacs in
      completion(.success(lockMacs ?? []))
    } failure: { status in
      completion(
        .failure(makeKeypadAccessoryApiError(operation: "accessory.getStoredLocks", error: status)))
    }
  }

  func deleteStoredLock(
    mac: String, slotNumber: Int64, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTWirelessKeypad.deleteLockAtSpecifiedSlot(withKeypadMac: mac, slotNumber: Int32(slotNumber)) {
      completion(.success(()))
    } failure: { status in
      completion(
        .failure(
          makeKeypadAccessoryApiError(operation: "accessory.deleteStoredLock", error: status)))
    }
  }

  func initDoorSensor(
    mac: String, lockData: String, completion: @escaping (Result<TTLockSystemModel, Error>) -> Void
  ) {
    TTDoorSensor.initialize(withDoorSensorMac: mac, lockData: lockData) {
      electricQuantity, systemModel in
      completion(
        .success(
          TTLockSystemModel(
            modelNum: systemModel.modelNum,
            hardwareRevision: systemModel.hardwareRevision,
            firmwareRevision: systemModel.firmwareRevision,
            electricQuantity: Int64(electricQuantity),
            nbOperator: nil,
            nbNodeId: nil,
            nbCardNumber: nil,
            nbRssi: nil,
            lockData: lockData,
          )))
    } failure: { error in
      completion(
        .failure(makeDoorSensorApiError(operation: "accessory.initDoorSensor", error: error)))
    }
  }

  func standaloneDoorSensorInit(
    mac: String, info: [String: Any?],
    completion: @escaping (Result<TTStandaloneDoorSensorInfo, Error>) -> Void
  ) {
    TTStandaloneDoorSensor.initWithInfo(info, mac: mac) { initModel in
      completion(.success(TTStandaloneDoorSensorInfo(
        doorSensorData: initModel.doorSensorData,
        electricQuantity: Int64(initModel.electricQuantity),
        featureValue: initModel.featureValue,
        wifiMac: initModel.wifiMac,
        modelNum: initModel.modelNum,
        hardwareRevision: initModel.hardwareRevision,
        firmwareRevision: initModel.firmwareRevision
      )))
    } failure: { error, errorMsg in
      completion(.failure(PigeonError(
        code: "STANDALONE_DOOR_SENSOR_ERROR",
        message: errorMsg,
        details: "\(error.rawValue)"
      )))
    }
  }

  func standaloneDoorSensorReadFeatureValue(
    mac: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    TTStandaloneDoorSensor.getFeatureValue(withMac: mac) { featureValue in
      completion(.success(featureValue))
    } failure: { error, errorMsg in
      completion(.failure(PigeonError(
        code: "STANDALONE_DOOR_SENSOR_ERROR",
        message: errorMsg,
        details: "\(error.rawValue)"
      )))
    }
  }

  func standaloneDoorSensorIsSupportFunction(featureValue: String, lockFunction: Int64) throws -> Bool {
    guard let feature = TTStandaloneDoorSensorFeature(rawValue: Int(truncatingIfNeeded: lockFunction)) else {
      return false
    }
    return TTStandaloneDoorSensor.supportFunction(feature, featureValue: featureValue)
  }

  func waterMeterConfigServer(url: String, clientId: String, accessToken: String) throws {
    TTWaterMeter.setClientParamWithUrl(url, clientId: clientId, accessToken: accessToken)
  }

  func waterMeterConnect(mac: String, completion: @escaping (Result<Void, Error>) -> Void) {
    TTWaterMeter.connect(withMac: mac) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeWaterMeterApiError(
            operation: "accessory.waterMeterConnect", error: error, message: errorMsg)))
    }
  }

  func waterMeterDisconnect(mac: String) throws {
    TTWaterMeter.cancelConnect(withMac: mac)
  }

  func waterMeterInit(
    params: TTWaterMeterInitParam, completion: @escaping (Result<TTWaterMeterInitResult, Error>) -> Void
  ) {
    let info: [String: String] = [
      "mac": params.mac,
      "number": params.name,
      "payMode": params.payMode == .postpaid ? "0" : "1",
      "price": "\(params.price)",
    ]
    TTWaterMeter.add(withInfo: info) { result in
      completion(.success(TTWaterMeterInitResult(
        waterMeterId: Int64(result.waterMeterId),
        featureValue: result.featureValue
      )))
    } failure: { error, errorMsg in
      completion(.failure(makeWaterMeterApiError(operation: "accessory.waterMeterInit", error: error, message: errorMsg)))
    }
  }

  func waterMeterDelete(mac: String, completion: @escaping (Result<Void, Error>) -> Void) {
    TTWaterMeter.delete(withMac: mac) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeWaterMeterApiError(
            operation: "accessory.waterMeterDelete", error: error, message: errorMsg)))
    }
  }

  func waterMeterSetPowerOnOff(
    mac: String, isOn: Bool, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTWaterMeter.setWaterOnOffWithMac(mac, onOff: isOn ? 1 : 0) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeWaterMeterApiError(
            operation: "accessory.waterMeterSetPowerOnOff", error: error, message: errorMsg)))
    }
  }

  func waterMeterSetRemainderM3(
    mac: String, remainderM3: Double, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTWaterMeter.setRemainingWaterWithMac(mac, remainderM3: "\(remainderM3)") {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeWaterMeterApiError(
            operation: "accessory.waterMeterSetRemainderM3", error: error, message: errorMsg)))
    }
  }

  func waterMeterClearRemainderM3(
    mac: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTWaterMeter.clearRemainingWater(withMac: mac) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeWaterMeterApiError(
            operation: "accessory.waterMeterClearRemainderM3", error: error, message: errorMsg)))
    }
  }

  func waterMeterReadData(
    mac: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTWaterMeter.readData(withMac: mac) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeWaterMeterApiError(
            operation: "accessory.waterMeterReadData", error: error, message: errorMsg)))
    }
  }

  func waterMeterSetPayMode(
    mac: String, payMode: TTMeterPayMode, price: Double, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTWaterMeter.setPayModeWithMac(mac, payMode: payModeConvert(payMode), price: "\(price)") {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeWaterMeterApiError(
            operation: "accessory.waterMeterSetPayMode", error: error, message: errorMsg)))
    }
  }

  func waterMeterCharge(
    mac: String, amount: Double, m3: Double, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTWaterMeter.recharge(
      withMac: mac, rechargeAmount: "\(amount)", rechargeM3: "\(m3)"
    ) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeWaterMeterApiError(
            operation: "accessory.waterMeterCharge", error: error, message: errorMsg)))
    }
  }

  func waterMeterSetTotalUsage(
    mac: String, totalM3: Double, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTWaterMeter.setTotalUsageWithMac(mac, totalM3: "\(totalM3)") {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeWaterMeterApiError(
            operation: "accessory.waterMeterSetTotalUsage", error: error, message: errorMsg)))
    }
  }

  func waterMeterGetFeatureValue(
    mac: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    TTWaterMeter.getFeatureValue(withMac: mac) {
      completion(.success(""))
    } failure: { error, errorMsg in
      completion(.failure(makeWaterMeterApiError(operation: "accessory.waterMeterGetFeatureValue", error: error, message: errorMsg)))
    }
  }

  func waterMeterGetDeviceInfo(
    mac: String, completion: @escaping (Result<WaterMeterDeviceInfo, Error>) -> Void
  ) {
    TTWaterMeter.getDeviceInfo(withMac: mac) { model in
      completion(.success(WaterMeterDeviceInfo(
        catOneCardNumber: model.catOneCardNumber,
        catOneImsi: model.catOneImsi,
        catOneNodeId: model.catOneNodeId,
        catOneOperator: model.catOneOperator,
        catOneRssi: Int64(model.catOneRssi) ?? 0
      )))
    } failure: { error, errorMsg in
      completion(.failure(makeWaterMeterApiError(operation: "accessory.waterMeterGetDeviceInfo", error: error, message: errorMsg)))
    }
  }

  func waterMeterIsSupportFunction(featureValue: String, lockFunction: TTWaterMeterFeature) throws -> Bool {
    return TTWaterMeter.supportFunction(waterMeterFeatureConvert(lockFunction), featureValue: featureValue)
  }

  func waterMeterConfigApn(mac: String, apn: String, completion: @escaping (Result<Void, Error>) -> Void) {
    TTWaterMeter.configApn(withMac: mac, apn: apn) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(.failure(makeWaterMeterApiError(operation: "accessory.waterMeterConfigApn", error: error, message: errorMsg)))
    }
  }

  func waterMeterConfigMeterServer(
    mac: String, ip: String, port: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTWaterMeter.configServer(withMac: mac, serverAddress: ip, portNumber: port) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(.failure(makeWaterMeterApiError(operation: "accessory.waterMeterConfigMeterServer", error: error, message: errorMsg)))
    }
  }

  func waterMeterReset(mac: String, completion: @escaping (Result<Void, Error>) -> Void) {
    TTWaterMeter.reset(withMac: mac) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(.failure(makeWaterMeterApiError(operation: "accessory.waterMeterReset", error: error, message: errorMsg)))
    }
  }

  func electricMeterConfigServer(url: String, clientId: String, accessToken: String) throws {
    TTElectricMeter.setClientParamWithUrl(url, clientId: clientId, accessToken: accessToken)
  }

  func electricMeterConnect(mac: String, completion: @escaping (Result<Void, Error>) -> Void) {
    TTElectricMeter.connect(withMac: mac) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeElectricMeterApiError(
            operation: "accessory.electricMeterConnect", error: error, message: errorMsg)))
    }
  }

  func electricMeterDisconnect(mac: String) throws {
    TTElectricMeter.cancelConnect(withMac: mac)
  }

  func electricMeterInit(
    params: TTElectricMeterInitParam, completion: @escaping (Result<TTElectricMeterInitResult, Error>) -> Void
  ) {
    let info: [String: String] = [
      "mac": params.mac,
      "number": params.name,
      "payMode": params.payMode == .postpaid ? "0" : "1",
      "price": "\(params.price)",
    ]
//    TTElectricMeter.add(withInfo: info) { addResult in
//      completion(.success(TTElectricMeterInitResult(
//        electricMeterId: Int64(addResult.electricMeterId),
//        featureValue: addResult.featureValue
//      )))
//    } failure: { error, errorMsg in
//      completion(.failure(makeElectricMeterApiError(operation: "accessory.electricMeterInit", error: error, message: errorMsg)))
//    }
  }

  func electricMeterDelete(
    mac: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTElectricMeter.delete(withMac: mac) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeElectricMeterApiError(
            operation: "accessory.electricMeterDelete", error: error, message: errorMsg)))
    }
  }

  func electricMeterSetPowerOnOff(
    mac: String, isOn: Bool, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTElectricMeter.setPowerOnOffWithMac(mac, powerOn: isOn) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeElectricMeterApiError(
            operation: "accessory.electricMeterSetPowerOnOff", error: error, message: errorMsg)))
    }
  }

  func electricMeterSetRemainderKwh(
    mac: String, remainderKwh: Double,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTElectricMeter.setRemainingElectricityWithMac(mac, remainderKwh: "\(remainderKwh)")
    {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeElectricMeterApiError(
            operation: "accessory.electricMeterSetRemainderKwh", error: error, message: errorMsg)))
    }
  }

  func electricMeterClearRemainderKwh(
    mac: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTElectricMeter.clearRemainingElectricity(withMac: mac) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeElectricMeterApiError(
            operation: "accessory.electricMeterClearRemainderKwh", error: error, message: errorMsg))
      )
    }
  }

  func electricMeterReadData(
    mac: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTElectricMeter.readData(withMac: mac) {
        completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeElectricMeterApiError(
            operation: "accessory.electricMeterReadData", error: error, message: errorMsg)))
    }
  }

  func electricMeterSetPayMode(
    mac: String, payMode: TTMeterPayMode, price: Double, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTElectricMeter.setPayModeWithMac(mac, payMode: payModeConvert(payMode), price: "\(price)") {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeElectricMeterApiError(
            operation: "accessory.electricMeterSetPayMode", error: error, message: errorMsg)))
    }
  }

  func electricMeterCharge(
    mac: String, amount: Double, kwh: Double, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTElectricMeter.recharge(
      withMac: mac, rechargeAmount: "\(amount)", rechargeKwh: "\(kwh)"
    ) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeElectricMeterApiError(
            operation: "accessory.electricMeterCharge", error: error, message: errorMsg)))
    }
  }

  func electricMeterSetMaxPower(
    mac: String, maxPower: Double, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    TTElectricMeter.setMaxPowerWithMac(mac, maxPower: Int(maxPower)) {
      completion(.success(()))
    } failure: { error, errorMsg in
      completion(
        .failure(
          makeElectricMeterApiError(
            operation: "accessory.electricMeterSetMaxPower", error: error, message: errorMsg)))
    }
  }

  func electricMeterGetFeatureValue(
    mac: String, completion: @escaping (Result<String, Error>) -> Void
  ) {
    TTElectricMeter.getFeatureValue(withMac: mac) {
      completion(.success(""))
    } failure: { error, errorMsg in
      completion(.failure(makeElectricMeterApiError(operation: "accessory.electricMeterGetFeatureValue", error: error, message: errorMsg)))
    }
  }

  func electricMeterIsSupportFunction(featureValue: String, lockFunction: TTElectricMeterFeature) throws -> Bool {
      return false
//    return TTElectricMeter.supportFunction(electricMeterFeatureConvert(lockFunction), featureValue: featureValue)
  }

  func electricMeterGetDeviceInfo(
    mac: String, completion: @escaping (Result<ElectricMeterDeviceInfo, Error>) -> Void
  ) {
//    TTElectricMeter.getDeviceInfo(withMac: mac) { model in
//      completion(.success(ElectricMeterDeviceInfo(
//        catOneCardNumber: model.catOneCardNumber,
//        catOneImsi: model.catOneImsi,
//        catOneNodeId: model.catOneNodeId,
//        catOneOperator: model.catOneOperator,
//        catOneRssi: Int64(model.catOneRssi) ?? 0
//      )))
//    } failure: { error, errorMsg in
//      completion(.failure(makeElectricMeterApiError(operation: "accessory.electricMeterGetDeviceInfo", error: error, message: errorMsg)))
//    }
  }

  func electricMeterConfigApn(
    mac: String, apn: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
//    TTElectricMeter.configApn(withMac: mac, apn: apn) {
//      completion(.success(()))
//    } failure: { error, errorMsg in
//      completion(.failure(makeElectricMeterApiError(operation: "accessory.electricMeterConfigApn", error: error, message: errorMsg)))
//    }
  }

  func electricMeterConfigMeterServer(
    mac: String, ip: String, port: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
//    TTElectricMeter.configServer(withMac: mac, serverAddress: ip, portNumber: port) {
//      completion(.success(()))
//    } failure: { error, errorMsg in
//      completion(.failure(makeElectricMeterApiError(operation: "accessory.electricMeterConfigMeterServer", error: error, message: errorMsg)))
//    }
  }

  func electricMeterReset(
    mac: String, completion: @escaping (Result<Void, Error>) -> Void
  ) {
//    TTElectricMeter.reset(withMac: mac) {
//      completion(.success(()))
//    } failure: { error, errorMsg in
//      completion(.failure(makeElectricMeterApiError(operation: "accessory.electricMeterReset", error: error, message: errorMsg)))
//    }
  }
}
