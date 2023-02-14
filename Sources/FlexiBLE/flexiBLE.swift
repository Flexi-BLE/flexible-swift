import CoreBluetooth
import GRDB

public final class FlexiBLE: ObservableObject {
    
    @Published public var profile: FlexiBLEProfile? = nil
    
    public var appDataPath: URL {
        return FlexiBLEAppData.FlexiBLEBasePath
    }
    
    public init() { }
    
    public var profiles: [FlexiBLEProfile] {
        return FlexiBLEAppData.shared.profiles
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
    
        self.profile = profile
    }
}
