import CoreBluetooth
import GRDB

public final class AEBLE: ObservableObject {
    public let config: AEBLEConfig
    public let conn: AEBLEConnectionManager
    public let db: AEBLEDBManager
    public let exp: AEBLEExperiment
    
    public init(config: AEBLEConfig) throws {
        self.config = config
        self.db = try AEBLEDBManager(config: config)
        self.conn = AEBLEConnectionManager(db: db)
        self.exp = AEBLEExperiment(db: db)
        
        self.startScan()
    }
    
    private func startScan() {
        conn.scan(with: config.metadata)
    }
}
