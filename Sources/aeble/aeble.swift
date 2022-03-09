import CoreBluetooth
import GRDB

public final class AEBLE: ObservableObject {
    public let conn: AEBLEConnectionManager
    public let db: AEBLEDBManager
    public let exp: AEBLEExperiment
    public let settings: AEBLESettingsStore
    
    public init() throws {
        self.db = try AEBLEDBManager()
        self.settings = AEBLESettingsStore(dbQueue: db.dbQueue)
        self.conn = AEBLEConnectionManager(db: db)
        self.exp = AEBLEExperiment(db: db)
        
        self.startScan()
    }
    
    private func startScan() {
        conn.scan(with: self.settings.peripheralConfig)
    }
}
