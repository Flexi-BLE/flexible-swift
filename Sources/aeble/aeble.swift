import CoreBluetooth
import GRDB

public class AEBLE: ObservableObject {
    public static let shared = AEBLE()
    
    private let connMgr = AEBLEConnectionManager()
    
    // FIXME: the configuration setup is a bad pattern.
    public lazy var dbMgr: DBManager = {
        return DBManager(with: self.dbUrl!)
    }()
    
    private var dbUrl: URL?
    
    private var peripherals: [AEBLEPeripheral] = []
    private(set) var metadata: PeripheralMetadataPayload?
    
    public init() {
    
    }
    
    public func configure(dbName: String = "aeble") throws {
        self.dbUrl = try DBManager.dataDir(dbName: dbName)
        
        startScan()
    }
    
    public func configure(dbUrl: URL) {
        self.dbUrl = dbUrl
        
        startScan()
    }
    
    private func startScan() {
        loadDefaultMetadata()
        if let m = metadata {
            self.peripherals = connMgr.scan(with: m)
        }
    }
    
    private func loadDefaultMetadata() {
        let pl = Bundle.module.decode(
            PeripheralMetadataPayload.self,
            from: "default_peripheral_metadata.json"
        )
        
        self.metadata = pl
    }
}
