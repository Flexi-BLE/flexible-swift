//
//  SpecificationTests.swift
//  
//
//  Created by Blaine Rothrock on 12/15/22.
//

import XCTest
@testable import flexiBLE_Core

final class SpecificationTests: XCTestCase {

    func testSimpleSpecificationDecoding() {
        guard let url = Bundle.module.url(forResource: "valid_spec", withExtension: "json") else {
            XCTFail("unable to find valid specification mock JSON")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let spec = try SpecCoding.Decoder.decode(FXBSpecification.self, from: data)
            
            XCTAssert(spec.schemaVersion == "0.4.0", "Version does not match")
        } catch DecodingError.dataCorrupted(let context) {
            XCTFail("Unable to decode JSON, data corrupted: \(context.debugDescription)")
        } catch DecodingError.keyNotFound(let key, let context) {
            XCTFail("Unable to decode JSON, key not found: (\(key)) \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let t, let context) {
            XCTFail("Unable to decode JSON, type mismatch: (\(t)) \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let t, let context) {
            XCTFail("Unable to decode JSON, value not found: (\(t)) \(context.debugDescription)")
        } catch {
            XCTFail("Unable to decode JSON, other error: \(error.localizedDescription)")
        }
    }
    
    func testSpecContents() {
        let spec = SpecMock.valid
        
        XCTAssert(!spec.name.isEmpty, "specification should have a name")
        XCTAssert(spec.customDevices.count > 0, "spec should have custom devices")
        XCTAssert(spec.gattDevices.count > 0, "spec should have gatt devices")
    }
    
    func testCreateSpec() {
        let author = FXBSpecAuthor(name: "jane doe", organization: "apple", email: "jane.doe@apple.com")
        let spec = FXBSpecification(name: "test", author: author)
        
        XCTAssert(spec.createdAt <= Date(), "spec should have a current created date")
        XCTAssert(spec.updatedAt <= Date(), "spec should have a current updated date")
        XCTAssert(spec.version == 1, "should be the first version")
        XCTAssert(spec.schemaVersion == "0.4.0", "should be the current version")
        
        do {
            let _ = try SpecCoding.Encoder.encode(spec)
        } catch {
            XCTFail("unable to encode json spec")
        }
    }

}
