import Foundation
import Network

class ConnectionManager: NSObject, NetServiceDelegate, NetServiceBrowserDelegate, ObservableObject {
    static let shared = ConnectionManager()

    private let serviceType = "_webcat._tcp"
    private let serviceDomain = "local."
    private let serviceName = "Teacher"

    private var service: NetService?
    private var browser: NetServiceBrowser?

    @Published var discoveredStudentHost: String?

    func publishTeacherService(port: Int32) {
        service = NetService(domain: serviceDomain, type: serviceType, name: serviceName, port: port)
        service?.delegate = self
        service?.publish()
        print("Published teacher service on port \(port)")
    }

    func startBrowsingForStudents() {
        browser = NetServiceBrowser()
        browser?.delegate = self
        browser?.searchForServices(ofType: serviceType, inDomain: serviceDomain)
        print("Browsing for student services...")
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        // Ignore our own service
        guard service.name != self.serviceName else { return }

        service.delegate = self
        service.resolve(withTimeout: 5)
    }

    func netService(_ sender: NetService, didResolveAddress addresses: [Data]) {
        guard let addressData = addresses.first else { return }

        addressData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            guard let sockaddrPtr = pointer.baseAddress?.assumingMemoryBound(to: sockaddr.self) else { return }

            if sockaddrPtr.pointee.sa_family == sa_family_t(AF_INET) {
                let sockaddrInPtr = UnsafeRawPointer(sockaddrPtr).assumingMemoryBound(to: sockaddr_in.self)
                let sinAddr = sockaddrInPtr.pointee.sin_addr

                var ipBuffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                _ = withUnsafePointer(to: sinAddr) { addrPtr in
                    inet_ntop(AF_INET, addrPtr, &ipBuffer, socklen_t(INET_ADDRSTRLEN))
                }

                let ip = String(cString: ipBuffer)
                DispatchQueue.main.async {
                    print("Student discovered at IP: \(ip)")
                    self.discoveredStudentHost = ip
                }
            }
        }
    }
}
