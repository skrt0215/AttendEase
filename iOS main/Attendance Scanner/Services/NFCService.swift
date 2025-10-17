//
//  NFCService.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import CoreNFC

class NFCService: NSObject, NFCNDEFReaderSessionDelegate {
    static let shared = NFCService()
    
    private var session: NFCNDEFReaderSession?
    private var completion: ((Result<String, Error>) -> Void)?
    
    private override init() {
        super.init()
    }
    
    var isNFCAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }
    
    func scanTag(completion: @escaping (Result<String, Error>) -> Void) {
        guard isNFCAvailable else {
            completion(.failure(AppError.nfcNotSupported))
            return
        }
        
        self.completion = completion
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near the NFC tag"
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first,
              let tagID = String(data: record.payload, encoding: .utf8) else {
            completion?(.failure(AppError.nfcReadFailed))
            return
        }
        
        completion?(.success(tagID))
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError {
            if nfcError.code != .readerSessionInvalidationErrorUserCanceled {
                completion?(.failure(AppError.nfcReadFailed))
            }
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
    }
}
