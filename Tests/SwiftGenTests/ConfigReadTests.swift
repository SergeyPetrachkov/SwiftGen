//
// SwiftGen
// Copyright (c) 2015 Olivier Halligon
// MIT Licence
//

import PathKit
#if canImport(SwiftGen)
@testable import SwiftGen
#endif
import XCTest

class ConfigReadTests: XCTestCase {

  func testReadConfigWithParams() throws {
    guard let path = Bundle(for: type(of: self)).path(forResource: "config-with-params", ofType: "yml") else {
      fatalError("Fixture not found")
    }
    let file = Path(path)
    do {
      let config = try Config(file: file)

      XCTAssertNil(config.inputDir)
      XCTAssertEqual(config.outputDir, "Common/Generated")

      XCTAssertEqual(Array(config.commands.keys), ["strings"])
      let stringEntries = config.commands["strings"]
      XCTAssertEqual(stringEntries?.count, 1)
      guard let entry = stringEntries?.first else {
        return XCTFail("Expected a single strings entry")
      }

      XCTAssertEqual(entry.paths, ["Sources1/Folder"])
      XCTAssertEqualDict(entry.parameters, [
        "foo": 5,
        "bar": ["bar1": 1, "bar2": 2, "bar3": [3, 4, ["bar3a": 50]]],
        "baz": ["hello", "world"]
      ])

      XCTAssertEqual(entry.outputs.count, 1)
      guard let output = entry.outputs.first else {
        return XCTFail("Expected a single strings entry output")
      }
      XCTAssertEqual(output.template, .name("structured-swift3"))
      XCTAssertEqual(output.output, "strings.swift")
    } catch let error {
      XCTFail("Error: \(error)")
    }
  }

  func testReadConfigWithMultiEntries() throws {
    guard let path = Bundle(for: type(of: self)).path(forResource: "config-with-multi-entries", ofType: "yml") else {
      fatalError("Fixture not found")
    }
    let file = Path(path)
    do {
      let config = try Config(file: file)

      XCTAssertEqual(config.inputDir, "Fixtures/")
      XCTAssertEqual(config.outputDir, "Generated/")

      XCTAssertEqual(Array(config.commands.keys), ["strings", "xcassets"])

      // strings
      guard let stringsEntries = config.commands["strings"] else {
        return XCTFail("Expected a config entry for strings")
      }
      XCTAssertEqual(stringsEntries.count, 1)

      XCTAssertEqual(stringsEntries[0].paths, ["Strings/Localizable.strings"])
      XCTAssertEqualDict(stringsEntries[0].parameters, ["enumName": "Loc"])
      XCTAssertEqual(stringsEntries[0].outputs.count, 1)
      XCTAssertEqual(stringsEntries[0].outputs[0].template, .path("templates/custom-swift3"))
      XCTAssertEqual(stringsEntries[0].outputs[0].output, "strings.swift")

      // xcassets
      guard let xcassetsEntries = config.commands["xcassets"] else {
        return XCTFail("Expected a config entry for xcassets")
      }
      XCTAssertEqual(xcassetsEntries.count, 3)

      // > xcassets[0]
      XCTAssertEqual(xcassetsEntries[0].paths, ["XCAssets/Colors.xcassets"])
      XCTAssertEqualDict(xcassetsEntries[0].parameters, [:])
      XCTAssertEqual(xcassetsEntries[0].outputs.count, 1)
      XCTAssertEqual(xcassetsEntries[0].outputs[0].template, .name("swift3"))
      XCTAssertEqual(xcassetsEntries[0].outputs[0].output, "assets-colors.swift")
      // > xcassets[1]
      XCTAssertEqual(xcassetsEntries[1].paths, ["XCAssets/Images.xcassets"])
      XCTAssertEqualDict(xcassetsEntries[1].parameters, ["enumName": "Pics"])
      XCTAssertEqual(xcassetsEntries[1].outputs.count, 1)
      XCTAssertEqual(xcassetsEntries[1].outputs[0].template, .name("swift3"))
      XCTAssertEqual(xcassetsEntries[1].outputs[0].output, "assets-images.swift")
      // > xcassets[2]
      XCTAssertEqual(xcassetsEntries[2].paths, ["XCAssets/Colors.xcassets", "XCAssets/Images.xcassets"])
      XCTAssertEqualDict(xcassetsEntries[2].parameters, [:])
      XCTAssertEqual(xcassetsEntries[2].outputs.count, 1)
      XCTAssertEqual(xcassetsEntries[2].outputs[0].template, .name("swift4"))
      XCTAssertEqual(xcassetsEntries[2].outputs[0].output, "assets-all.swift")
    } catch let error {
      XCTFail("Error: \(error)")
    }
  }

  func testReadConfigWithMultiOutputs() throws {
    guard let path = Bundle(for: type(of: self)).path(forResource: "config-with-multi-outputs", ofType: "yml") else {
      fatalError("Fixture not found")
    }
    let file = Path(path)
    do {
      let config = try Config(file: file)

      XCTAssertEqual(config.inputDir, "Fixtures/")
      XCTAssertEqual(config.outputDir, "Generated/")

      XCTAssertEqual(Array(config.commands.keys), ["ib"])

      // ib
      guard let ibEntries = config.commands["ib"] else {
        return XCTFail("Expected a config entry for ib")
      }
      XCTAssertEqual(ibEntries.count, 1)

      XCTAssertEqual(ibEntries[0].paths, ["IB-iOS"])
      XCTAssertEqualDict(ibEntries[0].parameters, [:])
      XCTAssertEqual(ibEntries[0].outputs.count, 2)
      XCTAssertEqual(ibEntries[0].outputs[0].template, .name("scenes-swift4"))
      XCTAssertEqual(ibEntries[0].outputs[0].output, "ib-scenes.swift")
      XCTAssertEqual(ibEntries[0].outputs[1].template, .name("segues-swift4"))
      XCTAssertEqual(ibEntries[0].outputs[1].output, "ib-segues.swift")
    } catch let error {
      XCTFail("Error: \(error)")
    }
  }

  func testReadInvalidConfigThrows() {
    let badConfigs = [
      "config-missing-paths": "Missing entry for key strings.paths.",
      "config-missing-template": """
        You must specify a template name (-t) or path (-p).

        To list all the available named templates, use 'swiftgen templates list'.
        """,
      "config-both-templates": """
        You need to choose EITHER a named template OR a template path. \
        Found name 'template' and path 'template.swift'
        """,
      "config-missing-output": "Missing entry for key strings.outputs.",
      "config-invalid-structure": "Wrong type for key strings.paths: expected Path or array of Paths, got Array<Any>.",
      "config-invalid-template": "Wrong type for key strings.templateName: expected String, got Array<Any>.",
      "config-invalid-output": "Wrong type for key strings.output: expected String, got Array<Any>."
    ]
    for (configFile, expectedError) in badConfigs {
      do {
        guard let path = Bundle(for: type(of: self)).path(forResource: configFile, ofType: "yml") else {
          fatalError("Fixture not found")
        }
        _ = try Config(file: Path(path))
        XCTFail("""
          Trying to parse config file \(configFile) should have thrown \
          error \(expectedError) but didn't throw at all
          """)
      } catch let error {
        XCTAssertEqual(
          String(describing: error),
          expectedError,
          """
          Trying to parse config file \(configFile) should have thrown \
          error \(expectedError) but threw \(error) instead.
          """
        )
      }
    }
  }
}
