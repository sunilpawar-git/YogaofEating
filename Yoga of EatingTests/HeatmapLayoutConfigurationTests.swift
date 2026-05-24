#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class HeatmapLayoutConfigurationTests: XCTestCase {
        // MARK: - Cell Size Calculation Tests

        func test_cellSize_inPortrait_calculatesFittingSevenColumns() {
            // Given: iPhone SE width (375pt) in portrait — formula gives ~47pt, clamped to maximumCellSize
            let config = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true,
                horizontalPadding: 32
            )

            // Then: On standard iPhone widths the formula exceeds maximumCellSize, so it clamps
            XCTAssertEqual(config.cellSize, config.maximumCellSize, accuracy: 0.1)
            XCTAssertGreaterThanOrEqual(config.cellSize, config.minimumCellSize)
        }

        func test_cellSize_inLandscape_calculatesFittingWeeksHorizontally() {
            // Given: iPhone in landscape (height becomes width-like constraint)
            let screenWidth: CGFloat = 812
            let screenHeight: CGFloat = 375

            // When
            let config = HeatmapLayoutConfiguration(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                isPortrait: false,
                horizontalPadding: 32
            )

            // Then: In landscape, 7 rows — formula gives ~30pt, within [min, max] bounds
            let availableHeight = screenHeight - 150 // Account for header, legend, etc.
            let calculatedSize = (availableHeight - (config.spacing * 6)) / 7
            let expectedSize = max(config.minimumCellSize, min(calculatedSize, config.maximumCellSize))
            XCTAssertEqual(config.cellSize, expectedSize, accuracy: 0.1)
            // Calculated (~30pt) is within bounds — no clamping occurs
            XCTAssertGreaterThanOrEqual(config.cellSize, config.minimumCellSize)
            XCTAssertLessThanOrEqual(config.cellSize, config.maximumCellSize)
        }

        func test_cellSize_neverGoesBelowMinimum() {
            // Given: Very small screen width that would calculate tiny cells
            let screenWidth: CGFloat = 200

            // When
            let config = HeatmapLayoutConfiguration(
                screenWidth: screenWidth,
                screenHeight: 400,
                isPortrait: true,
                horizontalPadding: 32
            )

            // Then: Cell size should never go below minimum tap target size
            XCTAssertGreaterThanOrEqual(config.cellSize, config.minimumCellSize)
        }

        func test_minimumCellSize_is14Points() {
            // Given/When
            let config = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true
            )

            // Then: Minimum cell size is 14pt (compact circle floor)
            XCTAssertEqual(config.minimumCellSize, 14)
        }

        // MARK: - Grid Direction Tests

        func test_gridDirection_isVerticalInPortrait() {
            // Given/When
            let config = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true
            )

            // Then
            XCTAssertEqual(config.gridDirection, .vertical)
        }

        func test_gridDirection_isHorizontalInLandscape() {
            // Given/When
            let config = HeatmapLayoutConfiguration(
                screenWidth: 812,
                screenHeight: 375,
                isPortrait: false
            )

            // Then
            XCTAssertEqual(config.gridDirection, .horizontal)
        }

        // MARK: - Spacing Tests

        func test_spacing_isProportionalToCellSize() {
            // Given
            let config1 = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true
            )

            let config2 = HeatmapLayoutConfiguration(
                screenWidth: 428,
                screenHeight: 926,
                isPortrait: true
            )

            // Then: Spacing should be consistent (4pt for breathing room)
            XCTAssertEqual(config1.spacing, 4)
            XCTAssertEqual(config2.spacing, 4)
        }

        // MARK: - Device Size Tests

        func test_cellSize_foriPhoneSE() {
            // Given: iPhone SE dimensions
            let config = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true
            )

            // Then: Should produce compact circle within defined bounds
            XCTAssertGreaterThanOrEqual(config.cellSize, config.minimumCellSize)
            XCTAssertLessThanOrEqual(config.cellSize, config.maximumCellSize)
        }

        func test_cellSize_foriPhone15ProMax() {
            // Given: iPhone 15 Pro Max dimensions
            let config = HeatmapLayoutConfiguration(
                screenWidth: 430,
                screenHeight: 932,
                isPortrait: true
            )

            // Then: Should produce compact circle within defined bounds
            XCTAssertGreaterThanOrEqual(config.cellSize, config.minimumCellSize)
            XCTAssertLessThanOrEqual(config.cellSize, config.maximumCellSize)
        }

        func test_cellSize_foriPad() {
            // Given: iPad dimensions
            let config = HeatmapLayoutConfiguration(
                screenWidth: 768,
                screenHeight: 1024,
                isPortrait: true
            )

            // Then: iPad cells are capped at maximumCellSize (compact circles)
            XCTAssertGreaterThanOrEqual(config.cellSize, config.minimumCellSize)
            XCTAssertLessThanOrEqual(config.cellSize, config.maximumCellSize)
        }

        // MARK: - Corner Radius Tests

        func test_cornerRadius_isHalfOfCellSize() {
            // Given
            let config = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true
            )

            // Then: Corner radius is half of cell size, producing perfect circles
            XCTAssertEqual(config.cornerRadius, config.cellSize / 2, accuracy: 0.1)
        }

        // MARK: - Total Grid Size Tests

        func test_totalGridWidth_inPortrait() {
            // Given
            let config = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true
            )

            // When: Portrait mode has 7 columns
            let expectedWidth = (config.cellSize * 7) + (config.spacing * 6)

            // Then
            XCTAssertEqual(config.totalGridWidth, expectedWidth, accuracy: 0.1)
        }

        func test_totalGridHeight_inPortrait() {
            // Given
            let config = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true
            )

            // When: Portrait mode has 53 rows (weeks)
            let expectedHeight = (config.cellSize * 53) + (config.spacing * 52)

            // Then
            XCTAssertEqual(config.totalGridHeight, expectedHeight, accuracy: 0.1)
        }
    }
#endif
