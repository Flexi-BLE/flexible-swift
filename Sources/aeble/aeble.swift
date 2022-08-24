import CoreBluetooth
import GRDB

public final class AEBLE: ObservableObject {
    public let conn: AEBLEConnectionManager
    public let db: AEBLEDBManager
    public let exp: AEBLEExperiment
    public let settings: AEBLESettingsStore
    
    public let read: LocalQueryReadOnly
    public let write: LocalQueryWrite
    
    public init() throws {
        self.db = AEBLEDBManager.shared
        self.settings = AEBLESettingsStore(dbQueue: db.dbQueue)
        self.conn = AEBLEConnectionManager(db: db)
        self.exp = AEBLEExperiment(db: db)
        
        self.read = LocalQueryReadOnly()
        self.write = LocalQueryWrite()
        
        self.startScan()
    }
    
    private func startScan() {
        Task {
            let config = await self.settings.peripheralConfig()
            conn.scan(with: config)
        }
    }
}
        
