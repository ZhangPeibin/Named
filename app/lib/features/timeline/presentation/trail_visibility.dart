/// Distance from the end where the trail card may appear.
const trailShowDistance = 12.0;

/// Distance from the end where a visible trail card hides again.
///
/// The card changes the scroll extent when it animates, so a single threshold
/// makes it flicker while scrolling slowly near the bottom. The gap between
/// these two thresholds keeps the current state stable.
const trailHideDistance = 96.0;

bool shouldShowTrail({
  required bool currentlyVisible,
  required double maxScrollExtent,
  required double pixels,
}) {
  if (maxScrollExtent <= 0) {
    return true;
  }
  final distance = maxScrollExtent - pixels;
  return currentlyVisible
      ? distance <= trailHideDistance
      : distance <= trailShowDistance;
}
