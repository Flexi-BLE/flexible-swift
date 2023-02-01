import CoreBluetooth
import GRDB

public final class FlexiBLE: ObservableObject {
    public static var shared = FlexiBLE()
    
    public let conn: FXBConnectionManager
    @Published public var profile: FlexiBLEProfile? = nil
    
    private var localDatabase: FXBDatabase?
    public var dbAccess: FXBLocalDataAccessor?
    
    public var appDataPath: URL {
        return FlexiBLEAppData.FlexiBLEBasePath
    }
    
    private init() {
        self.conn = FXBConnectionManager()
    }
    
    public func setLastProfile() {
        if let profile = FlexiBLEAppData.shared.lastProfile() {
            switchProfile(to: profile.id)
        }
    }
    
    public func createProfile(with spec: FXBSpec, name: String?=nil, setActive: Bool=true) {
        let profile = FlexiBLEProfile(
            name: name == nil ? spec.id : name!,
            spec: spec
        )
        
        FlexiBLEAppData.shared.add(profile)
        
        if setActive {
            switchProfile(to: profile.id)
        }
    }
    
    public func switchProfile(to id: UUID) {
        guard let profile = FlexiBLEAppData.shared.get(id: id) else {
            return
        }
        
        stopScan()
        conn.disconnectAll()
        startScan(with: profile.specification)
        
        self.profile = profile
        localDatabase = FXBDatabase(for: profile)
        dbAccess = FXBLocalDataAccessor(db: localDatabase!)
    }
    
    public func profiles() -> [FlexiBLEProfile] {
        return FlexiBLEAppData.shared.profiles
    }
    
    public func startScan(with spec: FXBSpec) {
        conn.scan(with: spec)
    }
    
    public func stopScan() {
        conn.stopScan()
    }
}
