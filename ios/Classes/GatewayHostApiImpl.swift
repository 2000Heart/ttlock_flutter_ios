import Foundation
import TTLockSDK

final class GatewayHostApiImpl: NSObject, TTGatewayHostApi {

  private let context: EventContextStore
  init(context: EventContextStore) { self.context = context }

  func setGatewayGetNearbyWifiParam(gatewayMac: String) throws {
    context.gatewayGetNearbyWifi.gatewayMac = gatewayMac
  }

  func initGateway(
    params: TTGatewayInitParams,
    completion: @escaping (Result<GatewayDeviceInfo, any Error>) -> Void
  ) {
    let gatewayType = gatewayTypeConvert(params.type)
    var payload: [String: Any] = [
      "SSID": params.wifi,
      "wifiPwd": params.wifiPassword,
      "uid": params.ttlockUid,
      "userPwd": params.ttlockLoginPassword,
      "serverAddress": params.serverIp,
      "portNumber": params.serverPort,
      "gatewayVersion": gatewayType,
      "companyId": params.companyId,
      "gatewayName": params.gatewayName,
      "branchId": params.branchId,
    ]
    // G2 / G5 / G6 使用真实 WiFi 与密码；G3 / G4 使用占位值（与 Android initGateway 一致）
    if params.type == .g3 || params.type == .g4 {
      payload["SSID"] = "1"
      payload["wifiPwd"] = "1"
    }
    TTGateway.initializeGateway(withInfoDic: payload) { systemInfoModel, status in
      if status == .success {
        completion(
          .success(
            GatewayDeviceInfo(
              modelNum: systemInfoModel?.modelNum ?? "",
              hardwareRevision: systemInfoModel?.hardwareRevision ?? "",
              firmwareRevision: systemInfoModel?.firmwareRevision ?? "",
              networkMac: TTGateway.getNetworkMac()
            )))
      } else {
        completion(.failure(makeGatewayApiError(operation: "gateway.init", error: status)))
      }
    }
  }

  func connect(mac: String, completion: @escaping (Result<TTGatewayConnectStatus, Error>) -> Void) {
    TTGateway.connectGateway(withGatewayMac: mac) { nativeStatus in
        completion(.success(gatewayConnectStatusConvert(nativeStatus)))
    }
  }

  func disconnect(mac: String) throws {
    TTGateway.disconnectGateway(withGatewayMac: mac) { nativeStatus in

    }
  }

  func configIp(
    mac: String, ipSetting: TTIpSetting, completion: @escaping (Result<Void, Error>) -> Void
  ) {
    let dict: [String: Any] = [
      "ipType": ipSetting.type,
      "ipAddress": ipSetting.ipAddress,
      "netMask": ipSetting.subnetMask,
      "gateway": ipSetting.router,
      "dns": ipSetting.preferredDns,
      "dns2": ipSetting.alternateDns,
    ]
    TTGateway.configIp(withInfo: dict) { status in
      if status == .success {
        completion(.success(()))
      } else {
        completion(.failure(makeGatewayApiError(operation: "gateway.configIp", error: status)))
      }
    }
  }

  func configApn(mac: String, apn: String, completion: @escaping (Result<Void, Error>) -> Void) {
    TTGateway.configApn(apn) { status in
      if status == .success {
        completion(.success(()))
      } else {
        completion(.failure(makeGatewayApiError(operation: "gateway.configApn", error: status)))
      }
    }
  }

  func getNetworkMac(completion: @escaping (Result<String?, Error>) -> Void) {
    completion(.success(TTGateway.getNetworkMac()))
  }

  func enterUpgradeMode(mac: String) throws {
    TTGateway.connectGateway(withGatewayMac: mac) { connectStatus in
      guard connectStatus == .success else { return }
      TTGateway.upgradeGateway(withGatewayMac: mac) { _ in }
    }
  }

}
