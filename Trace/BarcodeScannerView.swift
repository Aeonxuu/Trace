// visionkit data scanner, wrapped for swiftui

import SwiftUI
import VisionKit
import Vision

// whether the scanner can run, and why not
enum ScannerAvailability {
    case ready
    case unsupportedDevice
    case cameraUnavailable

    static func current() -> ScannerAvailability {
        guard DataScannerViewController.isSupported else { return .unsupportedDevice }
        guard DataScannerViewController.isAvailable else { return .cameraUnavailable }
        return .ready
    }

    var message: String? {
        switch self {
        case .ready:
            return nil
        case .unsupportedDevice:
            return "This device can't scan barcodes."
        case .cameraUnavailable:
            return "Trace needs camera access to scan. Turn it on in Settings."
        }
    }
}

// hosts the scanner as a child controller, so scanning can start in viewDidAppear
final class ScannerHostViewController: UIViewController {

    private let scanner: DataScannerViewController

    // cleared once a barcode is captured
    private var wantsScanning = true

    init(scanner: DataScannerViewController) {
        self.scanner = scanner
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(scanner)
        scanner.view.frame = view.bounds
        scanner.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scanner.view)
        scanner.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScanningIfNeeded()
    }

    func startScanningIfNeeded() {
        guard wantsScanning, isViewLoaded, view.window != nil, !scanner.isScanning else { return }

        do {
            try scanner.startScanning()
            print("Trace: scanner started, isScanning=\(scanner.isScanning)")
        } catch {
            print("Trace: startScanning failed — \(error)")
        }
    }

    // stops until resumeScanning()
    func pauseScanning() {
        wantsScanning = false
        scanner.stopScanning()
    }

    func resumeScanning() {
        wantsScanning = true
        startScanningIfNeeded()
    }

    func stopScanning() {
        scanner.stopScanning()
    }
}

struct BarcodeScannerView: UIViewControllerRepresentable {

    // holds the camera still during a lookup
    let isPaused: Bool

    // returns whether the scan was taken, a declined one keeps the camera running
    let onScan: (String) -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIViewController(context: Context) -> ScannerHostViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator

        let host = ScannerHostViewController(scanner: scanner)
        context.coordinator.host = host
        return host
    }

    func updateUIViewController(_ host: ScannerHostViewController, context: Context) {
        if isPaused {
            host.pauseScanning()
        } else {
            context.coordinator.prepareForNextScan()
            host.resumeScanning()
        }
    }

    static func dismantleUIViewController(
        _ host: ScannerHostViewController,
        coordinator: Coordinator
    ) {
        host.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {

        weak var host: ScannerHostViewController?

        private let onScan: (String) -> Bool
        private var hasScanned = false

        init(onScan: @escaping (String) -> Bool) {
            self.onScan = onScan
        }

        // re-arms the latch
        func prepareForNextScan() {
            hasScanned = false
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !hasScanned else { return }

            for case let .barcode(barcode) in addedItems {
                guard let payload = barcode.payloadStringValue else {
                    print("Trace: barcode recognized but payload was nil")
                    continue
                }

                // latch and stop only once the screen has taken the scan
                guard onScan(payload) else { continue }

                hasScanned = true
                host?.pauseScanning()
                return
            }
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable
        ) {
            print("Trace: scanner became unavailable — \(error)")
        }
    }
}
