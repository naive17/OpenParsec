import UIKit

class ParsecBackgroundManager {
	static let shared = ParsecBackgroundManager()
	
	// Track active Parsec connections
	private(set) var hasActiveConnection = false
	private var lastPeerId: String?
	private var didDisconnectDueToBackground = false
	
	var onShouldReconnect: ((String) -> Void)?
	
	private init() {
	}
	
	
	func connectionDidStart(peerId: String) {
		hasActiveConnection = true
		lastPeerId = peerId
		didDisconnectDueToBackground = false
	}
	
	func connectionDidEnd() {
		hasActiveConnection = false
	}
	
	
	func sceneWillResignActive() {
		
	}
	
	func sceneDidBecomeActive() {
		
		if didDisconnectDueToBackground, let peerId = lastPeerId {
			didDisconnectDueToBackground = false
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
				self?.onShouldReconnect?(peerId)
			}
		}
	}
	
	func sceneWillEnterForeground() {
	}
	
	func sceneDidEnterBackground() {
		
		if hasActiveConnection {
			didDisconnectDueToBackground = true
		}
	}
	
	func disableAutoReconnect() {
		didDisconnectDueToBackground = false
		lastPeerId = nil
	}
}
