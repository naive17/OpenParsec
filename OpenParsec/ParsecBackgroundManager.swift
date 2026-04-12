import UIKit
import AVFoundation

class ParsecBackgroundManager {
	static let shared = ParsecBackgroundManager()

	private(set) var hasActiveConnection = false
	private var lastPeerId: String?
	private var didDisconnectDueToBackground = false
	private(set) var isReconnecting = false

	var onShouldReconnect: ((String) -> Void)?

	var isMarkedForReconnect: Bool {
		return didDisconnectDueToBackground || isReconnecting
	}

	var isPiPActive: Bool {
		if #available(iOS 15.0, *) {
			return PictureInPictureManager.shared.isPiPActive
		}
		return false
	}

	private init() {
	}

	func connectionDidStart(peerId: String) {
		hasActiveConnection = true
		lastPeerId = peerId
		didDisconnectDueToBackground = false
		isReconnecting = false
		print("[ParsecBackgroundManager] Connection started to peer: \(peerId)")
	}

	func connectionDidEnd() {
		hasActiveConnection = false
		print("[ParsecBackgroundManager] Connection ended")
	}

	func sceneWillResignActive() {
		print("[ParsecBackgroundManager] Scene will resign active, hasActiveConnection: \(hasActiveConnection)")

		if hasActiveConnection {
			if isPiPActive {
				print("[ParsecBackgroundManager] PiP active — connection will be maintained")
			} else {
				print("[ParsecBackgroundManager] App is being backgrounded during active session")
			}
		}
	}

	func sceneDidBecomeActive() {
		print("[ParsecBackgroundManager] Scene did become active")

		// Takes priority over isPiPActive check because stopPiP() is async
		if didDisconnectDueToBackground, let peerId = lastPeerId {
			print("[ParsecBackgroundManager] Auto-reconnecting to peer: \(peerId)")
			didDisconnectDueToBackground = false
			isReconnecting = true

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
				self?.onShouldReconnect?(peerId)
			}
			return
		}

		if isPiPActive {
			print("[ParsecBackgroundManager] PiP was active — connection still alive")
		}
	}

	func sceneWillEnterForeground() {
		print("[ParsecBackgroundManager] Scene will enter foreground")
	}

	func sceneDidEnterBackground() {
		print("[ParsecBackgroundManager] Scene entered background, hasActiveConnection: \(hasActiveConnection)")

		if hasActiveConnection {
			var pipAttempted = false
			if #available(iOS 15.0, *) {
				pipAttempted = isPiPActive || PictureInPictureManager.shared.isStarting
			}
			if pipAttempted {
				print("[ParsecBackgroundManager] PiP active/starting — skipping disconnect marking")
				return
			}

			didDisconnectDueToBackground = true
			print("[ParsecBackgroundManager] Marked for auto-reconnect when returning to foreground")
		}
	}

	func markForReconnect() {
		guard lastPeerId != nil else { return }
		didDisconnectDueToBackground = true
		print("[ParsecBackgroundManager] Marked for auto-reconnect (PiP stopped/failed)")
	}

	func disableAutoReconnect() {
		didDisconnectDueToBackground = false
		isReconnecting = false
		lastPeerId = nil
		print("[ParsecBackgroundManager] Auto-reconnect disabled")
	}
}
