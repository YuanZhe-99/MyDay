import 'package:flutter_test/flutter_test.dart';
import 'package:my_day/features/intimacy/services/body_metrics.dart';

void main() {
  group('EU / EN 13402', () {
    BraSizeEstimate? eu(double bust, double underbust) => estimateBraSize(
      bustCm: bust,
      underbustCm: underbust,
      standard: BraStandard.eu,
    );

    test('band rounds to the nearest 5 cm', () {
      expect(eu(75, 58)!.band, 60);
      expect(eu(75, 62)!.band, 60);
      expect(eu(78, 63)!.band, 65);
      expect(eu(80, 67)!.band, 65);
      expect(eu(85, 68)!.band, 70);
      expect(eu(90, 77)!.band, 75);
    });

    test('cup boundaries follow the 2 cm table', () {
      expect(eu(79.9, 70), isNull); // 9.9 cm difference
      expect(eu(80, 70)!.cup, 'AA');
      expect(eu(81.99, 70)!.cup, 'AA');
      expect(eu(82, 70)!.cup, 'A');
      expect(eu(84, 70)!.cup, 'B');
      expect(eu(86, 70)!.cup, 'C');
      expect(eu(88, 70)!.cup, 'D');
      expect(eu(90, 70)!.cup, 'E');
      expect(eu(92, 70)!.cup, 'F');
      expect(eu(94, 70)!.cup, 'G');
      expect(eu(97.99, 70)!.cup, 'H');
      expect(eu(98, 70), isNull); // 28 cm difference
    });

    test('display is band-first', () {
      expect(eu(90, 74)!.display, '75C'); // 16 cm difference -> C
    });

    test('invalid inputs return null', () {
      expect(eu(0, 70), isNull);
      expect(eu(80, 0), isNull);
      expect(eu(70, 80), isNull); // bust below underbust
      expect(eu(50, 40), isNull); // band below supported range
    });
  });

  group('FR / ES', () {
    test('band is EU + 15 with EU cups', () {
      final size = estimateBraSize(
        bustCm: 87,
        underbustCm: 71,
        standard: BraStandard.frEs,
      )!;
      expect(size.band, 85); // EU 70 -> FR/ES 85
      expect(size.cup, 'C');
      expect(size.display, '85C');
      expect(
        estimateBraSize(
          bustCm: 91,
          underbustCm: 76,
          standard: BraStandard.frEs,
        )!.band,
        90, // EU 75 -> FR/ES 90
      );
    });
  });

  group('JP / JIS', () {
    BraSizeEstimate? jp(double bust, double underbust) => estimateBraSize(
      bustCm: bust,
      underbustCm: underbust,
      standard: BraStandard.jp,
    );

    test('cups sit on 2.5 cm centers with half-open +-1.25 bands', () {
      expect(jp(73.7, 70), isNull); // 3.7 cm difference
      expect(jp(73.75, 70)!.cup, 'AAA');
      expect(jp(76.24, 70)!.cup, 'AAA');
      expect(jp(76.25, 70)!.cup, 'AA');
      expect(jp(80, 70)!.cup, 'A'); // 10.0 center
      expect(jp(82.5, 70)!.cup, 'B');
      expect(jp(85, 70)!.cup, 'C');
      expect(jp(97.5, 70)!.cup, 'H'); // 27.5 center
      expect(jp(98.75, 70), isNull); // beyond H band
    });

    test('display is cup-first', () {
      expect(jp(90, 74)!.display, 'C75');
    });
  });

  group('UK', () {
    BraSizeEstimate? uk(double bust, double underbust) => estimateBraSize(
      bustCm: bust,
      underbustCm: underbust,
      standard: BraStandard.uk,
    );

    test('band conversion from EU', () {
      expect(uk(65.08, 60)!.band, 28); // EU 60
      expect(uk(70.08, 65)!.band, 30);
      expect(uk(75.08, 70)!.band, 32);
      expect(uk(80.08, 75)!.band, 34);
      expect(uk(85.08, 80)!.band, 36); // EU 80
    });

    test('one cup per inch of difference', () {
      expect(uk(72.54, 70)!.cup, 'A'); // 1 inch
      expect(uk(75.08, 70)!.cup, 'B');
      expect(uk(77.62, 70)!.cup, 'C');
      expect(uk(80.16, 70)!.cup, 'D');
      expect(uk(82.7, 70)!.cup, 'DD'); // 5 inches
      expect(uk(85.24, 70)!.cup, 'E');
      expect(uk(87.78, 70)!.cup, 'F');
      expect(uk(90.32, 70)!.cup, 'FF');
      expect(uk(92.86, 70)!.cup, 'G');
      expect(uk(95.4, 70)!.cup, 'GG'); // 10 inches
      expect(uk(97.94, 70)!.cup, 'H'); // 11 inches
      expect(uk(101, 70), isNull); // ~12.2 inches
      expect(uk(71, 70), isNull); // below 1 inch after rounding
    });
  });

  group('US', () {
    test('uses UK bands with the US cup sequence', () {
      final five = estimateBraSize(
        bustCm: 82.7,
        underbustCm: 70,
        standard: BraStandard.us,
      )!;
      expect(five.band, 32);
      expect(five.cup, 'DD/E');
      final six = estimateBraSize(
        bustCm: 85.24,
        underbustCm: 70,
        standard: BraStandard.us,
      )!;
      expect(six.cup, 'DDD/F');
      final eleven = estimateBraSize(
        bustCm: 97.94,
        underbustCm: 70,
        standard: BraStandard.us,
      )!;
      expect(eleven.cup, 'K');
    });
  });

  group('AU / NZ', () {
    test('band maps from UK and cups follow UK letters', () {
      BraSizeEstimate? au(double bust, double underbust) => estimateBraSize(
        bustCm: bust,
        underbustCm: underbust,
        standard: BraStandard.auNz,
      );
      expect(au(72.62, 65)!.band, 8); // UK 30
      expect(au(77.62, 70)!.band, 10); // UK 32
      expect(au(82.62, 75)!.band, 12); // UK 34
      expect(au(87.62, 80)!.band, 14); // UK 36
      expect(au(77.62, 70)!.cup, 'C');
      expect(au(77.62, 70)!.display, '10C');
    });
  });

  group('standard codes', () {
    test('round-trip through persisted codes', () {
      for (final standard in BraStandard.values) {
        expect(braStandardFromCode(braStandardCode(standard)), standard);
      }
      expect(braStandardFromCode(null), BraStandard.eu);
      expect(braStandardFromCode('unknown'), BraStandard.eu);
    });
  });

  group('PSI', () {
    test('two circumferences use the truncated-cone formula', () {
      // h=15cm, C=12cm, c=10cm -> 1.5 * (1.44 + 1.0 + 1.2) = 5.46
      final psi = calculatePsi(
        lengthCm: 15,
        baseCircumferenceCm: 12,
        frontCircumferenceCm: 10,
      );
      expect(psi, closeTo(5.46, 1e-9));
    });

    test('single circumference reduces to 3hC^2', () {
      // h=15cm, C=12cm -> 3 * 1.5 * 1.44 = 6.48
      final baseOnly = calculatePsi(lengthCm: 15, baseCircumferenceCm: 12);
      expect(baseOnly, closeTo(6.48, 1e-9));
      final frontOnly = calculatePsi(lengthCm: 15, frontCircumferenceCm: 12);
      expect(frontOnly, closeTo(6.48, 1e-9));
    });

    test('missing or non-positive inputs return null', () {
      expect(calculatePsi(lengthCm: null, baseCircumferenceCm: 12), isNull);
      expect(calculatePsi(lengthCm: 15), isNull);
      expect(calculatePsi(lengthCm: 0, baseCircumferenceCm: 12), isNull);
      expect(calculatePsi(lengthCm: 15, baseCircumferenceCm: -1), isNull);
    });
  });
}
