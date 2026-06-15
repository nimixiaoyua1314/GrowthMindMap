import AVFoundation
import SwiftUI

/// 全景背景音乐 — music.mp3 循环 + 50% 音量 + 最后5秒渐隐
final class AmbientSoundEngine: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false

    private var player: AVAudioPlayer?
    private var fadeTimer: Timer?
    private let fadeDuration: Double = 5.0
    private let baseVolume: Float = 0.25   // 50% of normal

    func start() {
        guard !isPlaying else { return }

        // 尝试多种路径加载 music.mp3
        let candidateURLs: [URL] = [
            Bundle.main.url(forResource: "music", withExtension: "mp3"),
            URL(fileURLWithPath: "/Volumes/拓展空间/成长心图/music.mp3"),
            URL(fileURLWithPath: "/Volumes/拓展空间/成长心图/成长心图/Resources/music.mp3"),
        ].compactMap { $0 }.filter { FileManager.default.fileExists(atPath: $0.path) }

        guard let musicURL = candidateURLs.first else {
            print("Music file not found")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: musicURL)
        } catch {
            print("Failed to load music: \(error)")
            return
        }

        guard let player else { return }

        player.delegate = self
        player.volume = baseVolume
        player.numberOfLoops = 0
        player.prepareToPlay()
        player.play()
        isPlaying = true
        startFadeMonitoring()
    }

    func stop() {
        isPlaying = false
        fadeTimer?.invalidate()
        fadeTimer = nil
        player?.setVolume(0, fadeDuration: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.player?.stop()
            self?.player = nil
        }
    }

    // MARK: - 渐隐循环

    private var isFadingOut = false

    private func startFadeMonitoring() {
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.checkFade()
        }
    }

    private func checkFade() {
        guard let p = player, isPlaying else { return }
        let remaining = p.duration - p.currentTime

        if remaining < fadeDuration && !isFadingOut && p.duration > 0 {
            isFadingOut = true
            p.setVolume(0, fadeDuration: fadeDuration)
        }

        if !p.isPlaying && isPlaying {
            restartLoop()
        }
    }

    private func restartLoop() {
        guard isPlaying else { return }
        isFadingOut = false
        player?.currentTime = 0
        player?.volume = baseVolume
        player?.play()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in self?.restartLoop() }
    }
}
