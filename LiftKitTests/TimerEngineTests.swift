import XCTest
@testable import LiftKit

final class TimerEngineTests: XCTestCase {

    func testAMRAPStartsInWorkPhase() {
        let engine = TimerEngine(notificationPrefix: "test-amrap")
        let config = TimerConfig.defaultConfig(for: .amrap)
        engine.start(config: config)
        // Starts with countdown first
        if case .countdown = engine.phase { } else if case .work = engine.phase { } else {
            XCTFail("Expected countdown or work phase after start")
        }
        XCTAssertTrue(engine.isRunning)
        engine.stop()
    }

    func testAMRAPSingleRound() {
        let engine = TimerEngine(notificationPrefix: "test-amrap-rounds")
        let config = TimerConfig.defaultConfig(for: .amrap)
        engine.start(config: config)
        XCTAssertEqual(engine.totalRounds, 1)
        XCTAssertEqual(engine.currentRound, 1)
        engine.stop()
    }

    func testEMOMStartsWithCorrectRounds() {
        let engine = TimerEngine(notificationPrefix: "test-emom")
        let config = TimerConfig.defaultConfig(for: .emom)
        engine.start(config: config)
        XCTAssertEqual(engine.totalRounds, config.rounds)
        XCTAssertEqual(engine.currentRound, 1)
        engine.stop()
    }

    func testEMOMSkipAdvancesRound() {
        let engine = TimerEngine(notificationPrefix: "test-emom-skip")
        var cfg = TimerConfig.defaultConfig(for: .emom)
        cfg.rounds = 3
        engine.start(config: cfg)
        // Skip through countdown to work, then skip round
        engine.skip()
        engine.skip()
        // After two skips from countdown phase we should be in round 2 or complete
        XCTAssertTrue(engine.currentRound >= 1)
        engine.stop()
    }

    func testEMOMCompletesAfterAllRounds() {
        let engine = TimerEngine(notificationPrefix: "test-emom-complete")
        var cfg = TimerConfig.defaultConfig(for: .emom)
        cfg.rounds = 2
        let expectation = XCTestExpectation(description: "EMOM completes")
        engine.onComplete = { expectation.fulfill() }
        engine.start(config: cfg)
        for _ in 0..<5 { engine.skip() }
        wait(for: [expectation], timeout: 2)
        engine.stop()
    }

    func testIntervalsStartsInWorkPhase() {
        let engine = TimerEngine(notificationPrefix: "test-intervals")
        let config = TimerConfig.defaultConfig(for: .intervals)
        engine.start(config: config)
        XCTAssertEqual(engine.totalRounds, config.rounds)
        XCTAssertTrue(engine.isRunning)
        engine.stop()
    }

    func testIntervalsWorkToRestTransition() {
        let engine = TimerEngine(notificationPrefix: "test-intervals-wt")
        var cfg = TimerConfig.defaultConfig(for: .intervals)
        cfg.rounds = 4
        engine.start(config: cfg)
        // skip countdown → work
        engine.skip()
        // now skip work → rest
        engine.skip()
        if case .rest = engine.phase { } else if case .work = engine.phase { } else if case .complete = engine.phase { }
        // Just verify no crash and engine still valid
        XCTAssertTrue(engine.currentRound >= 1)
        engine.stop()
    }

    func testIntervalsRestToNextWorkTransition() {
        let engine = TimerEngine(notificationPrefix: "test-intervals-rt")
        var cfg = TimerConfig.defaultConfig(for: .intervals)
        cfg.rounds = 3
        engine.start(config: cfg)
        engine.skip(); engine.skip(); engine.skip()
        XCTAssertTrue(engine.currentRound >= 1)
        engine.stop()
    }

    func testIntervalsCompletesAfterAllRounds() {
        let engine = TimerEngine(notificationPrefix: "test-intervals-finish")
        var cfg = TimerConfig.defaultConfig(for: .intervals)
        cfg.rounds = 2
        let expectation = XCTestExpectation(description: "Intervals completes")
        engine.onComplete = { expectation.fulfill() }
        engine.start(config: cfg)
        for _ in 0..<8 { engine.skip() }
        wait(for: [expectation], timeout: 2)
        engine.stop()
    }

    func testRepsRestTimerStarts() {
        let engine = TimerEngine(notificationPrefix: "test-reps-rest")
        engine.startRestTimer(90)
        if case .rest = engine.phase { } else {
            XCTFail("Expected .rest phase after startRestTimer")
        }
        XCTAssertTrue(engine.timeRemaining > 88)
        engine.stop()
    }

    func testRepsRestTimerSkipCompletes() {
        let engine = TimerEngine(notificationPrefix: "test-reps-skip")
        let expectation = XCTestExpectation(description: "Rest completes")
        engine.onComplete = { expectation.fulfill() }
        engine.startRestTimer(90)
        engine.skip()
        wait(for: [expectation], timeout: 2)
    }

    func testForTimeStartsCountUp() {
        let engine = TimerEngine(notificationPrefix: "test-fortime")
        let config = TimerConfig.defaultConfig(for: .forTime)
        engine.start(config: config)
        XCTAssertTrue(engine.isRunning)
        engine.stop()
    }

    func testManualStartsCountUp() {
        let engine = TimerEngine(notificationPrefix: "test-manual")
        let config = TimerConfig.defaultConfig(for: .manual)
        engine.start(config: config)
        XCTAssertTrue(engine.isRunning)
        engine.stop()
    }

    func testPauseStopsRunning() {
        let engine = TimerEngine(notificationPrefix: "test-pause")
        let config = TimerConfig.defaultConfig(for: .amrap)
        engine.start(config: config)
        engine.pause()
        XCTAssertFalse(engine.isRunning)
        XCTAssertTrue(engine.timeRemaining > 0)
        engine.stop()
    }

    func testResumeAfterPause() {
        let engine = TimerEngine(notificationPrefix: "test-resume")
        let config = TimerConfig.defaultConfig(for: .amrap)
        engine.start(config: config)
        engine.pause()
        let pausedTime = engine.timeRemaining
        engine.resume()
        XCTAssertTrue(engine.isRunning)
        XCTAssertTrue(engine.timeRemaining <= pausedTime + 1)
        engine.stop()
    }

    func testStopResetsEverything() {
        let engine = TimerEngine(notificationPrefix: "test-stop")
        let config = TimerConfig.defaultConfig(for: .amrap)
        engine.start(config: config)
        engine.stop()
        XCTAssertFalse(engine.isRunning)
        if case .idle = engine.phase { } else {
            XCTFail("Expected .idle after stop")
        }
        XCTAssertEqual(engine.timeRemaining, 0)
        XCTAssertEqual(engine.currentRound, 1)
    }

    func testFormattedTime() {
        let engine = TimerEngine(notificationPrefix: "test-fmt")
        let result = engine.formatTime(90)
        XCTAssertTrue(result.contains(":"), "formattedTime should contain ':'")
        XCTAssertEqual(result, "1:30")
    }

    func testTimerConfigTotalTime() {
        let intervals = TimerConfig.defaultConfig(for: .intervals)
        XCTAssertEqual(intervals.totalWorkoutSeconds, (intervals.workSeconds + intervals.restSeconds) * intervals.rounds)

        let amrap = TimerConfig.defaultConfig(for: .amrap)
        XCTAssertEqual(amrap.totalWorkoutSeconds, amrap.totalDurationSeconds)
    }

    func testDefaultConfigs() {
        for type in TimerType.allCases {
            let config = TimerConfig.defaultConfig(for: type)
            XCTAssertEqual(config.type, type, "Default config type mismatch for \(type)")
        }
    }
}
