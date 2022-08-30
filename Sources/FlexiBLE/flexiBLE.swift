import CoreBluetooth
import GRDB

public final class FlexiBLE: ObservableObject {
    public let conn: FXBConnectionManager
    public let db: FXBDBManager
    public let exp: FXBExp
    
    public let read: FXBRead
    public let write: FXBWrite
    
    public init() throws {
        self.db = FXBDBManager.shared
        self.conn = FXBConnectionManager(db: db)
        self.exp = FXBExp(db: db)
        
        self.read = FXBRead()
        self.write = FXBWrite()
    }
    
    public func startScan(with spec: FXBSpec) {
        Task {
            conn.scan(with: spec)
        }
    }
}
        
