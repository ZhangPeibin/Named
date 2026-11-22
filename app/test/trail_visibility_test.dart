import 'package:flutter_test/flutter_test.dart';
import 'package:named/features/timeline/presentation/trail_visibility.dart';

void main() {
  test('always shows the trail when the list cannot scroll', () {
    expect(
      shouldShowTrail(currentlyVisible: false, maxScrollExtent: 0, pixels: 0),
      isTrue,
    );
  });

  test('shows only near the end when hidden', () {
    expect(
      shouldShowTrail(
        currentlyVisible: false,
        maxScrollExtent: 1000,
        pixels: 995,
      ),
      isTrue,
    );
    expect(
      shouldShowTrail(
        currentlyVisible: false,
        maxScrollExtent: 1000,
        pixels: 900,
      ),
      isFalse,
    );
  });

  test('stays visible through the layout shift it causes', () {
    // Visible at the end, then the card collapses and the extent grows by its
    // own height; the trail must not immediately hide and re-show.
    expect(
      shouldShowTrail(
        currentlyVisible: true,
        maxScrollExtent: 1000,
        pixels: 1000,
      ),
      isTrue,
    );
    expect(
      shouldShowTrail(
        currentlyVisible: true,
        maxScrollExtent: 1056,
        pixels: 1000,
      ),
      isTrue,
    );
  });

  test('hides once clearly scrolled away', () {
    expect(
      shouldShowTrail(
        currentlyVisible: true,
        maxScrollExtent: 1000,
        pixels: 800,
      ),
      isFalse,
    );
  });
}
