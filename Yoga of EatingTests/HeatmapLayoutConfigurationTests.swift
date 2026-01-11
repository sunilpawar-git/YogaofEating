#if canImport(XCTest)
    import XCTest
    @testable import Yoga_of_Eating

    final class HeatmapLayoutConfigurationTests: XCTestCase {
        // MARK: - Cell Size Calculation Tests

        func test_cellSize_inPortrait_calculatesFittingSevenColumns() {
            // Given: iPhone SE width (375pt) in portrait, with some horizontal padding
            let screenWidth: CGFloat = 375
            let horizontalPadding: CGFloat = 32 // 16 on each side
            let availableWidth = screenWidth - horizontalPadding

            // When
            let config = HeatmapLayoutConfiguration(
                screenWidth: screenWidth,
                screenHeight: 667,
                isPortrait: true,
                horizontalPadding: horizontalPadding
            )

            // Then: Cell size should fit 7 columns with spacing
            // Available width = 343, need to fit 7 cells + 6 spacing gaps
            let expectedMaxCellSize = (availableWidth - (config.spacing * 6)) / 7
            XCTAssertEqual(config.cellSize, expectedMaxCellSize, accuracy: 0.1)
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

            // Then: In landscape, 7 rows with weeks as columns
            // Cell size should be clamped to minimum if calculated value is too small
            let availableHeight = screenHeight - 150 // Account for header, legend, etc.
            let calculatedSize = (availableHeight - (config.spacing * 6)) / 7
            let expectedSize = max(config.minimumCellSize, min(calculatedSize, config.maximumCellSize))
            XCTAssertEqual(config.cellSize, expectedSize, accuracy: 0.1)
            // Should be at minimum since calculated is below minimum
            XCTAssertEqual(config.cellSize, config.minimumCellSize)
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

        func test_minimumCellSize_is32Points() {
            // Given/When
            let config = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true
            )

            // Then: Minimum cell size should be 32pt for thumb-friendly tapping
            XCTAssertEqual(config.minimumCellSize, 32)
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

            // Then: Spacing should be consistent
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

            // Then: Should calculate appropriate size for smallest iPhone
            XCTAssertGreaterThanOrEqual(config.cellSize, 32)
            XCTAssertLessThanOrEqual(config.cellSize, 50)
        }

        func test_cellSize_foriPhone15ProMax() {
            // Given: iPhone 15 Pro Max dimensions
            let config = HeatmapLayoutConfiguration(
                screenWidth: 430,
                screenHeight: 932,
                isPortrait: true
            )

            // Then: Should calculate appropriate size for largest iPhone
            XCTAssertGreaterThanOrEqual(config.cellSize, 32)
            XCTAssertLessThanOrEqual(config.cellSize, 60)
        }

        func test_cellSize_foriPad() {
            // Given: iPad dimensions
            let config = HeatmapLayoutConfiguration(
                screenWidth: 768,
                screenHeight: 1024,
                isPortrait: true
            )

            // Then: iPad can have larger cells, capped at max
            XCTAssertGreaterThanOrEqual(config.cellSize, 32)
            XCTAssertLessThanOrEqual(config.cellSize, config.maximumCellSize)
        }

        // MARK: - Corner Radius Tests

        func test_cornerRadius_isProportionalToCellSize() {
            // Given
            let config = HeatmapLayoutConfiguration(
                screenWidth: 375,
                screenHeight: 667,
                isPortrait: true
            )

            // Then: Corner radius should be about 10% of cell size, with min of 3
            let expectedRadius = max(3, config.cellSize * 0.1)
            XCTAssertEqual(config.cornerRadius, expectedRadius, accuracy: 0.1)
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
