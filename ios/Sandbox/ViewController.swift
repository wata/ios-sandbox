//
//  ViewController.swift
//  Sandbox
//
//  Created by Wataru Nagasawa on 11/1/18.
//  Copyright © 2018 junkapp. All rights reserved.
//

import UIKit
import Speech
import Pulsator
import PermissionAccess

class ViewController: UIViewController {
    @IBOutlet private var recordButton : RecordButton!
    @IBOutlet private var collectionView: UICollectionView!

    private lazy var pulsator: Pulsator = {
        let pulsator = Pulsator()
        pulsator.numPulse = 6
        pulsator.animationDuration = 8
        pulsator.backgroundColor = UIColor.blue.cgColor
        pulsator.radius = UIScreen.main.bounds.width / 2.0
        pulsator.fromValueForRadius = Float((recordButton.frame.width / 2.0) / pulsator.radius)
        pulsator.position = CGPoint(x: recordButton.frame.midX, y: recordButton.frame.midY)
        view.layer.insertSublayer(pulsator, at: 0)
        return pulsator
    }()

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()

        UIApplication.shared.isIdleTimerDisabled = true

        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = collectionView.frame.size

        // Disable the record buttons until authorization has been granted.
        recordButton.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        speechRecognizer.delegate = self

        PermissionAccess.request(.speechRecognizer, presentDeniedAlert: true) { (isAuthorized) in
            if isAuthorized {
                self.recordButton.isEnabled = true
            } else {
                self.recordButton.isEnabled = false
                self.recordButton.setTitle("User denied access to speech recognition.", for: .disabled)
            }
        }
    }

    private func startRecording() throws {
        // Cancel the previous task if it's running.
        if let task = recognitionTask {
            task.cancel()
            self.recognitionTask = nil
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record)
        try audioSession.setMode(.measurement)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
        }

        // Configure request so that results are returned before audio recording is finished
        recognitionRequest.shouldReportPartialResults = true

        // A recognition task represents a speech recognition session.
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result = result {
                self.handle(transcription: result.bestTranscription)
                isFinal = result.isFinal
            }

            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.recordButton.isEnabled = true
                self.recordButton.setTitle("開始", for: [])
            }
        }

        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }

    private var currentTranscription: SFTranscription?

    private func handle(transcription: SFTranscription) {
        guard
            transcription.formattedString != currentTranscription?.formattedString,
            collectionView.visibleCells.count == 1,
            let visibleItem = collectionView.indexPathsForVisibleItems.first?.item
            else { return }

        currentTranscription = transcription

        if transcription.formattedString.last == "次", visibleItem < (collectionView.numberOfItems(inSection: 0) - 1) {
            collectionView.scrollToItem(at: .init(item: visibleItem + 1, section: 0), at: .centeredHorizontally, animated: true)
            return
        }
        if transcription.formattedString.last == "前", visibleItem > 0 {
            collectionView.scrollToItem(at: .init(item: visibleItem - 1, section: 0), at: .centeredHorizontally, animated: true)
            return
        }
    }

    @IBAction func recordButtonTapped() {
        if audioEngine.isRunning {
            pulsator.stop()
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("停止中", for: .disabled)
        } else {
            pulsator.start()
            try! startRecording()
            recordButton.setTitle("停止", for: [])
        }
    }
}

extension ViewController: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("開始", for: [])
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("Recognition not available", for: .disabled)
        }
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: (indexPath.item + 1).description, for: indexPath)
    }
}

extension ViewController: UICollectionViewDelegate {
}
