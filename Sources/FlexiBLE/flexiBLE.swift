import CoreBluetooth
import GRDB

public final class FlexiBLE: ObservableObject {
    public static var shared = FlexiBLE()
    
    public let conn: FXBConnectionManager
    @Published public var profile: FlexiBLEProfile? = nil
    
    private var localDatabase: FXBDatabase?
    public var dbAccess: FXBLocalDataAccessor?
    
    private init() {
        self.conn = FXBConnectionManager()
    }
    
    public func setLastProfile() {
        self.profile = FlexiBLEAppData.shared.lastProfile()
    }
    
    public func createProfile(with spec: FXBSpec, name: String?=nil) {
        let profile = FlexiBLEProfile(
            name: name == nil ? spec.id : name!,
            spec: spec
        )
        
        FlexiBLEAppData.shared.add(profile)
        switchProfile(to: profile.id)
    }
    
    public func switchProfile(to id: UUID) {
        guard let profile = FlexiBLEAppData.shared.get(id: id) else {
            return
        }
        
        self.profile = profile
        localDatabase = FXBDatabase(for: profile)
        dbAccess = FXBLocalDataAccessor(db: localDatabase!)
    }
    
    public func profiles() -> [FlexiBLEProfile] {
        return FlexiBLEAppData.shared.profiles
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
