import CoreNFC
import Combine

enum WriteState: Equatable {
    case idle
    case scanning
    case success
    case error(String)
}

class NFCWriterSession: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var writeState: WriteState = .idle

    private var session: NFCNDEFReaderSession?
    private let contact = ContactCard.default

    var isAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    func startWriteSession() {
        guard isAvailable else {
            DispatchQueue.main.async {
                self.writeState = .error("NFC is not available on this device.")
            }
            return
        }

        session = NFCNDEFReaderSession(
            delegate: self,
            queue: nil,
            invalidateAfterFirstRead: false
        )
        session?.alertMessage = "Hold the top of your iPhone against the NFC tag."
        session?.begin()

        DispatchQueue.main.async {
            self.writeState = .scanning
        }
    }

    // MARK: - NFCNDEFReaderSessionDelegate

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Not used for writing
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.alertMessage = "No NFC tag found. Try again."
            session.invalidate()
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                session.alertMessage = "Connection failed: \(error.localizedDescription)"
                session.invalidate()
                DispatchQueue.main.async { self.writeState = .error("Connection failed.") }
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    session.alertMessage = "Unable to query tag: \(error.localizedDescription)"
                    session.invalidate()
                    DispatchQueue.main.async { self.writeState = .error("Unable to read tag.") }
                    return
                }

                guard status == .readWrite else {
                    let msg = status == .notSupported
                        ? "This tag does not support NDEF."
                        : "This tag is read-only."
                    session.alertMessage = msg
                    session.invalidate()
                    DispatchQueue.main.async { self.writeState = .error(msg) }
                    return
                }

                let message = self.buildNDEFMessage()

                let messageSize = message.records.reduce(0) { $0 + $1.payload.count + $1.type.count + $1.identifier.count + 3 }
                guard capacity >= messageSize else {
                    session.alertMessage = "Tag too small. Use NTAG215 or larger (\(messageSize) bytes needed, \(capacity) available)."
                    session.invalidate()
                    DispatchQueue.main.async { self.writeState = .error("Tag too small (\(capacity) bytes). Need \(messageSize).") }
                    return
                }

                tag.writeNDEF(message) { error in
                    if let error = error {
                        session.alertMessage = "Write failed: \(error.localizedDescription)"
                        session.invalidate()
                        DispatchQueue.main.async { self.writeState = .error("Write failed.") }
                    } else {
                        session.alertMessage = "Tag written! Anyone who taps this tag will get your card."
                        session.invalidate()
                        DispatchQueue.main.async { self.writeState = .success }

                        // Auto-reset after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            if self.writeState == .success {
                                self.writeState = .idle
                            }
                        }
                    }
                }
            }
        }
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session is active, waiting for tag
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let nfcError = error as? NFCReaderError
        let isUserCancel = nfcError?.code == .readerSessionInvalidationErrorUserCanceled
        let isFirstRead = nfcError?.code == .readerSessionInvalidationErrorFirstNDEFTagRead

        DispatchQueue.main.async {
            if isUserCancel || isFirstRead {
                if self.writeState == .scanning {
                    self.writeState = .idle
                }
            } else if self.writeState == .scanning {
                self.writeState = .error("Session ended.")
            }
        }
        self.session = nil
    }

    // MARK: - NDEF Message Builder

    private func buildNDEFMessage() -> NFCNDEFMessage {
        var records: [NFCNDEFPayload] = []

        // Record 1: URL — universally supported, opens the digital card
        if let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: contact.websiteURL) {
            records.append(urlPayload)
        }

        // Record 2: vCard MIME record — contact-aware readers save directly to contacts
        let vcardData = contact.vCardString.data(using: .utf8) ?? Data()
        let vcardRecord = NFCNDEFPayload(
            format: .media,
            type: "text/vcard".data(using: .utf8)!,
            identifier: Data(),
            payload: vcardData
        )
        records.append(vcardRecord)

        return NFCNDEFMessage(records: records)
    }
}
