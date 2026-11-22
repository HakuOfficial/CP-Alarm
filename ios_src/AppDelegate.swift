import UIKit
import Flutter
import UserNotifications
import AVFoundation
import AlarmKit
import AppIntents
import SwiftUI
import CryptoKit

@available(iOS 26.0, *)
struct CPMetadata: AlarmMetadata {}

@available(iOS 26.0, *)
struct RepeatCPAlarm: LiveActivityIntent {
    static var title: LocalizedStringResource = "Nhắc lại sau 5 phút"
    @Parameter(title: "Mã báo thức") var key: String
    @Parameter(title: "Tiêu đề") var label: String
    @Parameter(title: "Âm") var tone: String
    init() {}
    init(key: String, label: String, tone: String) {
        self.key = key
        self.label = label
        self.tone = tone
    }
    func perform() async throws -> some IntentResult {
        try await NativeAlarm.repeatAfterFive(key: key, label: label, tone: tone)
        return .result()
    }
}

@available(iOS 26.0, *)
@MainActor
enum NativeAlarm {
    static func id(_ key: String) -> UUID {
        let b = Array(SHA256.hash(data: Data(key.utf8)))
        return UUID(uuid: (b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15]))
    }
    static let defaults = UserDefaults.standard
    static var records: [String:String] { defaults.dictionary(forKey: "CPAlarmRecords") as? [String:String] ?? [:] }
    static func cancel(_ key: String) throws {
        let uuid = id(key)
        if try AlarmManager.shared.alarms.contains(where: { $0.id == uuid }) {
            try AlarmManager.shared.cancel(id: uuid)
        }
        var book = records
        book.removeValue(forKey: key)
        defaults.set(book, forKey: "CPAlarmRecords")
    }
    static func repeatAfterFive(key: String, label: String, tone: String) async throws {
        let newKey = "native-repeat/" + UUID().uuidString
        try await schedule(newKey, label, Date().addingTimeInterval(300), tone)
        try cancel(key)
    }
    static func schedule(_ key: String, _ label: String, _ at: Date, _ tone: String) async throws {
        let uuid = id(key)
        let signature = "\(Int(at.timeIntervalSince1970))|\(label)|\(tone)"
        if try AlarmManager.shared.alarms.contains(where: { $0.id == uuid }) {
            if records[key] == signature { return }
            try cancel(key)
        }
        let alert = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: label),
            stopButton: AlarmButton(text: "Tắt", textColor: .white, systemImageName: "stop.fill"),
            secondaryButton: AlarmButton(text: "Nhắc lại sau 5 phút", textColor: .white, systemImageName: "clock.arrow.circlepath"),
            secondaryButtonBehavior: .custom)
        let attrs = AlarmAttributes(presentation: AlarmPresentation(alert: alert), metadata: CPMetadata(), tintColor: .orange)
        let config = AlarmManager.AlarmConfiguration<CPMetadata>(
            countdownDuration: nil, schedule: .fixed(at), attributes: attrs,
            stopIntent: nil, secondaryIntent: RepeatCPAlarm(key: key, label: label, tone: tone),
            sound: .named(tone + ".wav"))
        _ = try await AlarmManager.shared.schedule(id: uuid, configuration: config)
        var book = records
        book[key] = signature
        defaults.set(book, forKey: "CPAlarmRecords")
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    var player: AVAudioPlayer?
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return super.application(application, didFinishLaunchingWithOptions: options)
    }
    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        let channel = FlutterMethodChannel(name: "cp_alarm/system", binaryMessenger: engineBridge.applicationRegistrar.messenger())
        channel.setMethodCallHandler { [weak self] call, result in
            Task { @MainActor in
                let a = call.arguments as? [String:Any] ?? [:]
                do {
                    switch call.method {
                    case "settings":
                        if let url = URL(string: UIApplication.openSettingsURLString) { await UIApplication.shared.open(url) }
                        result(nil)
                    case "sound":
                        guard let url = Bundle.main.url(forResource: a["sound"] as? String ?? "Radar", withExtension: "wav") else { throw CocoaError(.fileNoSuchFile) }
                        try AVAudioSession.sharedInstance().setCategory(.playback)
                        try AVAudioSession.sharedInstance().setActive(true)
                        self?.player = try AVAudioPlayer(contentsOf: url)
                        self?.player?.numberOfLoops = -1
                        self?.player?.play()
                        result(nil)
                    case "silence":
                        self?.player?.stop()
                        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                        result(nil)
                    default:
                        guard #available(iOS 26.0, *) else {
                            if call.method == "keys" { result([String]()) }
                            else if ["authorize","authorized"].contains(call.method) { result(false) }
                            else { result(nil) }
                            return
                        }
                        let manager = AlarmManager.shared
                        switch call.method {
                        case "authorize": result(try await manager.requestAuthorization() == .authorized)
                        case "authorized": result(manager.authorizationState == .authorized)
                        case "keys": result(Array(NativeAlarm.records.keys.filter { !$0.hasPrefix("native-repeat/") }))
                        case "cancel":
                            if let k = a["key"] as? String { try NativeAlarm.cancel(k) }
                            result(nil)
                        case "schedule", "snooze":
                            guard let key = a["key"] as? String, let label = a["title"] as? String, let stamp = a["at"] as? NSNumber else { throw CocoaError(.coderInvalidValue) }
                            let tone = a["sound"] as? String ?? "Radar"
                            if call.method == "snooze" { try await NativeAlarm.repeatAfterFive(key: key, label: label, tone: tone) }
                            else { try await NativeAlarm.schedule(key, label, Date(timeIntervalSince1970: stamp.doubleValue), tone) }
                            result(nil)
                        default: result(FlutterMethodNotImplemented)
                        }
                    }
                } catch { result(FlutterError(code: "CP_ALARM", message: error.localizedDescription, details: nil)) }
            }
        }
    }
}
