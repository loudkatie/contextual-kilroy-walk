import Foundation
import AVFoundation

@MainActor
final class AudioWhisperService {
    enum AudioError: Error {
        case missingClip
    }

    private let audioSession = AVAudioSession.sharedInstance()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var routeObserver: NSObjectProtocol?

    private(set) var currentRouteDescription: String {
        didSet {
            routeDescriptionDidChange?(currentRouteDescription)
        }
    }

    var routeDescriptionDidChange: ((String) -> Void)?

    init() {
        currentRouteDescription = AudioWhisperService.describeCurrentRoute(using: AVAudioSession.sharedInstance())
        configureAudioSession()
        observeRouteChanges()
    }

    deinit {
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
    }

    func playWelcome() {
        playClip(named: "psst_welcome_frontier", fallbackText: "Welcome to Frontier Tower.")
    }

    func playDropHere() {
        playClip(named: "psst_drop_here", fallbackText: "There's a drop here.")
    }

    func playWantToOpen() {
        playClip(named: "psst_want_to_open", fallbackText: "Want to open it?")
    }

    private func playClip(named clip: String, fallbackText: String) {
        do {
            try configureAudioSession()
            guard let url = Bundle.main.url(forResource: clip, withExtension: "m4a") else {
                throw AudioError.missingClip
            }
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            fallbackSpeak(text: fallbackText)
        }
    }

    private func configureAudioSession() {
        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP, .duckOthers]
            )
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
            currentRouteDescription = AudioWhisperService.describeCurrentRoute(using: audioSession)
        } catch {
            // Silent failure; fallback speech still works.
        }
    }

    private func observeRouteChanges() {
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            currentRouteDescription = AudioWhisperService.describeCurrentRoute(using: audioSession)
        }
    }

    private func fallbackSpeak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.volume = 0.2
        speechSynthesizer.speak(utterance)
    }

    private static func describeCurrentRoute(using session: AVAudioSession) -> String {
        guard let output = session.currentRoute.outputs.first else {
            return "Speaker"
        }
        switch output.portType {
        case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
            return "Bluetooth"
        case .headphones, .headsetMic:
            return "Headphones"
        case .airPlay:
            return "AirPlay"
        default:
            return "Speaker"
        }
    }
}
