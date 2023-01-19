import CoreBluetooth
import GRDB

public final class FlexiBLE: ObservableObject {
    public static var shared = FlexiBLE()
    
    public let conn: FXBConnectionManager
    @Published public var spec: FXBSpec? = nil
    
    private var newDB: FXBDatabase?
    public var dbAccess: FXBLocalDataAccessor?
    
    private init() {
        self.conn = FXBConnectionManager()
    }
    
    public func setSpec(_ spec: FXBSpec) async throws {
        self.spec = spec
        
        newDB = FXBDatabase(for: spec)
        dbAccess = FXBLocalDataAccessor(db: newDB!)
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
        
