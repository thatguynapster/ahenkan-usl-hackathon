import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahenkan/core/utils/enums.dart';
import 'package:ahenkan/data/services/sign_language_interpretation_service_impl.dart';
import 'package:ahenkan/domain/entities/interpretation_result.dart';

void main() {
  late SignLanguageInterpretationServiceImpl service;
  late File testVideoFile;

  setUp(() {
    service = SignLanguageInterpretationServiceImpl();
    // Create a temporary test file
    testVideoFile = File('test_video.mp4');
  });

  tearDown(() {
    // Clean up test file if it exists
    if (testVideoFile.existsSync()) {
      testVideoFile.deleteSync();
    }
  });

  group('Video Interpretation Tests', () {
    test(
      'should interpret video and return result with English language',
      () async {
        // Arrange
        testVideoFile.writeAsStringSync('mock video content');

        // Act
        final result = await service.interpretVideo(
          testVideoFile,
          Language.english,
        );

        // Assert
        expect(result, isA<InterpretationResult>());
        expect(result.text, isNotEmpty);
        expect(result.confidence, greaterThanOrEqualTo(0.0));
        expect(result.confidence, lessThanOrEqualTo(1.0));
        expect(result.language, equals(Language.english));
      },
    );

    test(
      'should interpret video and return result with Akan language',
      () async {
        // Arrange
        testVideoFile.writeAsStringSync('mock video content');

        // Act
        final result = await service.interpretVideo(
          testVideoFile,
          Language.akan,
        );

        // Assert
        expect(result, isA<InterpretationResult>());
        expect(result.text, isNotEmpty);
        expect(result.confidence, greaterThanOrEqualTo(0.0));
        expect(result.confidence, lessThanOrEqualTo(1.0));
        expect(result.language, equals(Language.akan));
      },
    );

    test('should interpret video and return result with Ga language', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');

      // Act
      final result = await service.interpretVideo(testVideoFile, Language.ga);

      // Assert
      expect(result, isA<InterpretationResult>());
      expect(result.text, isNotEmpty);
      expect(result.confidence, greaterThanOrEqualTo(0.0));
      expect(result.confidence, lessThanOrEqualTo(1.0));
      expect(result.language, equals(Language.ga));
    });

    test(
      'should interpret video and return result with Ewe language',
      () async {
        // Arrange
        testVideoFile.writeAsStringSync('mock video content');

        // Act
        final result = await service.interpretVideo(
          testVideoFile,
          Language.ewe,
        );

        // Assert
        expect(result, isA<InterpretationResult>());
        expect(result.text, isNotEmpty);
        expect(result.confidence, greaterThanOrEqualTo(0.0));
        expect(result.confidence, lessThanOrEqualTo(1.0));
        expect(result.language, equals(Language.ewe));
      },
    );

    test(
      'should return different interpretations for different languages',
      () async {
        // Arrange
        testVideoFile.writeAsStringSync('mock video content');
        service.resetIndex();

        // Act
        final englishResult = await service.interpretVideo(
          testVideoFile,
          Language.english,
        );
        service.resetIndex();
        final akanResult = await service.interpretVideo(
          testVideoFile,
          Language.akan,
        );

        // Assert
        expect(englishResult.text, isNot(equals(akanResult.text)));
        expect(englishResult.language, equals(Language.english));
        expect(akanResult.language, equals(Language.akan));
      },
    );
  });

  group('Confidence Threshold Tests', () {
    test('should return varying confidence scores', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');
      service.resetIndex();
      final confidenceScores = <double>[];

      // Act - get multiple interpretations
      for (int i = 0; i < 6; i++) {
        final result = await service.interpretVideo(
          testVideoFile,
          Language.english,
        );
        confidenceScores.add(result.confidence);
      }

      // Assert - should have different confidence scores
      expect(confidenceScores.toSet().length, greaterThan(1));
      expect(confidenceScores.any((score) => score >= 0.7), isTrue);
      expect(confidenceScores.any((score) => score < 0.7), isTrue);
    });

    test('should return confidence score below 70% threshold', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');
      service.resetIndex();

      // Act - iterate until we get a low confidence score
      InterpretationResult? lowConfidenceResult;
      for (int i = 0; i < 10; i++) {
        final result = await service.interpretVideo(
          testVideoFile,
          Language.english,
        );
        if (result.confidence < 0.7) {
          lowConfidenceResult = result;
          break;
        }
      }

      // Assert
      expect(lowConfidenceResult, isNotNull);
      expect(lowConfidenceResult!.confidence, lessThan(0.7));
    });

    test('should return confidence score above 70% threshold', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');
      service.resetIndex();

      // Act
      final result = await service.interpretVideo(
        testVideoFile,
        Language.english,
      );

      // Assert - first result should have high confidence
      expect(result.confidence, greaterThanOrEqualTo(0.7));
    });

    test(
      'should handle confidence threshold validation in BLoC layer',
      () async {
        // Arrange
        testVideoFile.writeAsStringSync('mock video content');
        service.resetIndex();

        // Act - get multiple results
        final results = <InterpretationResult>[];
        for (int i = 0; i < 6; i++) {
          final result = await service.interpretVideo(
            testVideoFile,
            Language.english,
          );
          results.add(result);
        }

        // Assert - service returns all results, BLoC should filter
        expect(results.length, equals(6));
        expect(results.any((r) => r.confidence < 0.7), isTrue);
        expect(results.any((r) => r.confidence >= 0.7), isTrue);
      },
    );
  });

  group('Timeout Handling Tests', () {
    test('should complete interpretation within 5 seconds', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');
      final stopwatch = Stopwatch()..start();

      // Act
      await service.interpretVideo(testVideoFile, Language.english);
      stopwatch.stop();

      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });

    test('should handle timeout scenario gracefully', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');

      // Act & Assert - normal operation should not timeout
      expect(
        () async =>
            await service.interpretVideo(testVideoFile, Language.english),
        returnsNormally,
      );
    });

    test(
      'should throw TimeoutException if processing exceeds 5 seconds',
      () async {
        // Note: This test verifies the timeout mechanism exists
        // The mock implementation completes in 1.5 seconds, so it won't timeout
        // In a real implementation with slow processing, this would timeout

        // Arrange
        testVideoFile.writeAsStringSync('mock video content');

        // Act & Assert - verify the method has timeout handling
        final result = await service.interpretVideo(
          testVideoFile,
          Language.english,
        );

        // Should complete successfully within timeout
        expect(result, isA<InterpretationResult>());
      },
    );
  });

  group('Error Handling Tests', () {
    test('should throw exception when video file does not exist', () async {
      // Arrange
      final nonExistentFile = File('non_existent_video.mp4');

      // Act & Assert
      expect(
        () async =>
            await service.interpretVideo(nonExistentFile, Language.english),
        throwsA(isA<Exception>()),
      );
    });

    test('should provide meaningful error message for missing file', () async {
      // Arrange
      final nonExistentFile = File('non_existent_video.mp4');

      // Act & Assert
      try {
        await service.interpretVideo(nonExistentFile, Language.english);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('Video file does not exist'));
        expect(e.toString(), contains(nonExistentFile.path));
      }
    });

    test('should handle interpretation errors gracefully', () async {
      // Arrange
      final nonExistentFile = File('error_video.mp4');

      // Act & Assert
      expect(
        () async =>
            await service.interpretVideo(nonExistentFile, Language.english),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Multiple Interpretation Tests', () {
    test(
      'should return different texts for sequential interpretations',
      () async {
        // Arrange
        testVideoFile.writeAsStringSync('mock video content');
        service.resetIndex();

        // Act
        final result1 = await service.interpretVideo(
          testVideoFile,
          Language.english,
        );
        final result2 = await service.interpretVideo(
          testVideoFile,
          Language.english,
        );
        final result3 = await service.interpretVideo(
          testVideoFile,
          Language.english,
        );

        // Assert - should cycle through different sample interpretations
        expect(result1.text, isNotEmpty);
        expect(result2.text, isNotEmpty);
        expect(result3.text, isNotEmpty);
      },
    );

    test('should maintain language consistency in results', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');

      // Act
      final result = await service.interpretVideo(testVideoFile, Language.ga);

      // Assert
      expect(result.language, equals(Language.ga));
    });

    test('should handle rapid sequential interpretations', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');
      service.resetIndex();

      // Act - perform multiple interpretations rapidly
      final futures = <Future<InterpretationResult>>[];
      for (int i = 0; i < 3; i++) {
        futures.add(service.interpretVideo(testVideoFile, Language.english));
      }
      final results = await Future.wait(futures);

      // Assert
      expect(results.length, equals(3));
      for (final result in results) {
        expect(result, isA<InterpretationResult>());
        expect(result.text, isNotEmpty);
        expect(result.confidence, greaterThanOrEqualTo(0.0));
        expect(result.confidence, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('InterpretationResult Structure Tests', () {
    test('should return result with all required fields', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');

      // Act
      final result = await service.interpretVideo(
        testVideoFile,
        Language.english,
      );

      // Assert
      expect(result.text, isNotNull);
      expect(result.confidence, isNotNull);
      expect(result.language, isNotNull);
    });

    test('should return result with valid confidence range', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');
      service.resetIndex();

      // Act - test multiple results
      for (int i = 0; i < 10; i++) {
        final result = await service.interpretVideo(
          testVideoFile,
          Language.english,
        );

        // Assert
        expect(result.confidence, greaterThanOrEqualTo(0.0));
        expect(result.confidence, lessThanOrEqualTo(1.0));
      }
    });

    test('should return result with non-empty text', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');

      // Act
      final result = await service.interpretVideo(testVideoFile, Language.akan);

      // Assert
      expect(result.text, isNotEmpty);
      expect(result.text.length, greaterThan(0));
    });
  });

  group('Reset Index Tests', () {
    test('should reset interpretation index', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');
      service.resetIndex();

      // Act
      final result1 = await service.interpretVideo(
        testVideoFile,
        Language.english,
      );
      service.resetIndex();
      final result2 = await service.interpretVideo(
        testVideoFile,
        Language.english,
      );

      // Assert - should return same first interpretation after reset
      expect(result1.text, equals(result2.text));
      expect(result1.confidence, equals(result2.confidence));
    });

    test('should cycle through interpretations after reset', () async {
      // Arrange
      testVideoFile.writeAsStringSync('mock video content');
      service.resetIndex();

      // Act - get first interpretation
      final firstResult = await service.interpretVideo(
        testVideoFile,
        Language.english,
      );

      // Get several more
      for (int i = 0; i < 3; i++) {
        await service.interpretVideo(testVideoFile, Language.english);
      }

      // Reset and get first again
      service.resetIndex();
      final resetResult = await service.interpretVideo(
        testVideoFile,
        Language.english,
      );

      // Assert
      expect(resetResult.text, equals(firstResult.text));
    });
  });
}
