import CoreBluetooth
import GRDB

public final class FlexiBLE: ObservableObject {
    public static var shared = FlexiBLE()
    
    public let conn: FXBConnectionManager
    public let db: FXBDBManager
    public let exp: FXBExp
    
    public let read: FXBRead
    public let write: FXBWrite
    
    @Published public var specId: Int64 = -1
    @Published public var spec: FXBSpec? = nil
    
    private init() {
        self.db = FXBDBManager.shared
        self.conn = FXBConnectionManager(db: db)
        self.exp = FXBExp(db: db)
        
        self.read = FXBRead()
        self.write = FXBWrite()
    }
    
    public func setSpec(_ spec: FXBSpec) async throws {
        self.specId = try await self.write.recordSpec(spec)
        self.spec = spec
    }
    
    public func setArchive(bytes: UInt64, keepInterval: TimeInterval) {
        db.archiveSizeThresholdBytes = bytes
        db.activeKeepTimeInterval = keepInterval
    }
    
    public func startScan(with spec: FXBSpec) {
        Task {
            conn.scan(with: spec)
        }
    }
    
    public func stopScan() {
        Task {
            conn.stopScan()
        }
    }
}
        
