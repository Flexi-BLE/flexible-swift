import CoreBluetooth
import GRDB

public final class AEBLE: ObservableObject {
    private(set) var config: AEBLEConfig
    
    public let conn: AEBLEConnectionManager
    public let db: AEBLEDBManager
    
    public init(config: AEBLEConfig) {
        self.config = config
        self.conn = AEBLEConnectionManager()
        self.db = AEBLEDBManager(with: config.dbURL)
        
        self.startScan()
    }
    
    private func startScan() {
        conn.scan(with: config.metadata)
    }
}
