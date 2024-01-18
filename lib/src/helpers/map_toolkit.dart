import 'dart:collection';
import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Port of PolyUtil from android-maps-utils (https://github.com/googlemaps/android-maps-utils)
class PolygonUtil {
  static const num earthRadius = 6371009.0;

  /// Returns tan(latitude-at-lng3) on the great circle (lat1, lng1) to
  /// (lat2, lng2). lng1==0.
  /// See http://williams.best.vwh.net/avform.htm .
  static num _tanLatGC(num lat1, num lat2, num lng2, num lng3) =>
      (tan(lat1) * sin(lng2 - lng3) + tan(lat2) * sin(lng3)) / sin(lng2);

  /// Returns mercator(latitude-at-lng3) on the Rhumb line (lat1, lng1) to
  /// (lat2, lng2). lng1==0.
  static num _mercatorLatRhumb(num lat1, num lat2, num lng2, num lng3) =>
      (MathUtil.mercator(lat1) * (lng2 - lng3) +
          MathUtil.mercator(lat2) * lng3) /
      lng2;

  /// Computes whether the vertical segment (lat3, lng3) to South Pole
  /// intersects the segment (lat1, lng1) to (lat2, lng2).
  /// Longitudes are offset by -lng1; the implicit lng1 becomes 0.
  static bool _intersects(
      num lat1, num lat2, num lng2, num lat3, num lng3, bool geodesic) {
    // Both ends on the same side of lng3.
    if ((lng3 >= 0 && lng3 >= lng2) || (lng3 < 0 && lng3 < lng2)) {
      return false;
    }
    // Point is South Pole.
    if (lat3 <= -pi / 2) {
      return false;
    }
    // Any segment end is a pole.
    if (lat1 <= -pi / 2 ||
        lat2 <= -pi / 2 ||
        lat1 >= pi / 2 ||
        lat2 >= pi / 2) {
      return false;
    }
    if (lng2 <= -pi) {
      return false;
    }

    final linearLat = (lat1 * (lng2 - lng3) + lat2 * lng3) / lng2;
    // Northern hemisphere and point under lat-lng line.
    if (lat1 >= 0 && lat2 >= 0 && lat3 < linearLat) {
      return false;
    }
    // Southern hemisphere and point above lat-lng line.
    if (lat1 <= 0 && lat2 <= 0 && lat3 >= linearLat) {
      return true;
    }
    // North Pole.
    if (lat3 >= pi / 2) {
      return true;
    }

    // Compare lat3 with latitude on the GC/Rhumb segment corresponding to lng3.
    // Compare through a strictly-increasing function (tan() or
    // MathUtil.mercator()) as convenient.
    return geodesic
        ? tan(lat3) >= _tanLatGC(lat1, lat2, lng2, lng3)
        : MathUtil.mercator(lat3) >= _mercatorLatRhumb(lat1, lat2, lng2, lng3);
  }

  static bool containsLocation(
      LatLng point, List<LatLng> polygon, bool geodesic,
      {bool debug = false}) {
    if (debug) {
      print(
          'checkingcontains location (${point.longitude},${point.latitude}) for polygon');
      var op = '';
      for (var point in polygon) {
        op += '${point.longitude},${point.latitude},';
      }
      print(op);
    }
    return containsLocationAtLatLng(
        point.latitude, point.longitude, polygon, geodesic);
  }

  /// Computes whether the given point lies inside the specified polygon.
  /// The polygon is always considered closed, regardless of whether the last
  /// point equals the first or not.
  /// Inside is defined as not containing the South Pole -- the South Pole is
  /// always outside. The polygon is formed of great circle segments if geodesic
  /// is true, and of rhumb (loxodromic) segments otherwise.
  static bool containsLocationAtLatLng(
      num latitude, num longitude, List<LatLng> polygon, bool geodesic) {
    if (polygon.isEmpty) {
      return false;
    }

    final lat3 = MathUtil.toRadians(latitude);
    final lng3 = MathUtil.toRadians(longitude);
    final prev = polygon.last;
    var lat1 = MathUtil.toRadians(prev.latitude);
    var lng1 = MathUtil.toRadians(prev.longitude);
    var nIntersect = 0;

    for (final point2 in polygon) {
      final dLng3 = MathUtil.wrap(lng3 - lng1, -pi, pi);
      // Special case: point equal to vertex is inside.
      if (lat3 == lat1 && dLng3 == 0) {
        return true;
      }
      final lat2 = MathUtil.toRadians(point2.latitude);
      final lng2 = MathUtil.toRadians(point2.longitude);
      // Offset longitudes by -lng1.
      if (_intersects(lat1, lat2, MathUtil.wrap(lng2 - lng1, -pi, pi), lat3,
          dLng3, geodesic)) {
        ++nIntersect;
      }
      lat1 = lat2;
      lng1 = lng2;
    }
    return (nIntersect & 1) != 0;
  }

  static const num defaultTolerance = 0.1; // meters.

  /// Computes whether the given point lies on or near the edge of a polygon,
  /// within a specified tolerance in meters. The polygon edge is composed of
  /// great circle segments if geodesic is true, and of Rhumb segments
  /// otherwise. The polygon edge is implicitly closed - the closing segment
  /// between the first point and the last point is included.
  static bool isLocationOnEdge(
          LatLng point, List<LatLng> polygon, bool geodesic,
          {num tolerance = defaultTolerance}) =>
      _isLocationOnEdgeOrPath(point, polygon, true, geodesic, tolerance);

  /// Computes whether the given point lies on or near a polyline, within a
  /// specified tolerance in meters. The polyline is composed of great circle
  /// segments if geodesic is true, and of Rhumb segments otherwise.
  /// The polyline is not closed -- the closing segment between the first point
  /// and the last point is not included.
  static bool isLocationOnPath(
          LatLng point, List<LatLng> polyline, bool geodesic,
          {num tolerance = defaultTolerance}) =>
      _isLocationOnEdgeOrPath(point, polyline, false, geodesic, tolerance);

  static bool _isLocationOnEdgeOrPath(LatLng point, List<LatLng> poly,
      bool closed, bool geodesic, num toleranceEarth) {
    final idx = locationIndexOnEdgeOrPath(
        point, poly, closed, geodesic, toleranceEarth);

    return idx >= 0;
  }

  /// Computes whether (and where) a given point lies on or near a polyline,
  /// within a specified tolerance. The polyline is not closed -- the closing
  /// segment between the first point and the last point is not included.
  ///
  /// @param point     our needle
  /// @param poly      our haystack
  /// @param geodesic  the polyline is composed of great circle segments if
  ///                  geodesic is true, and of Rhumb segments otherwise
  /// @param tolerance tolerance (in meters)
  /// @return -1 if point does not lie on or near the polyline.
  /// 0 if point is between poly[0] and poly[1] (inclusive),
  /// 1 if between poly[1] and poly[2],
  /// ...,
  /// poly.size()-2 if between poly[poly.size() - 2] and poly[poly.size() - 1]
  static int locationIndexOnPath(LatLng point, List<LatLng> poly, bool geodesic,
          {num tolerance = defaultTolerance}) =>
      locationIndexOnEdgeOrPath(point, poly, false, geodesic, tolerance);

  /// Computes whether (and where) a given point lies on or near a polyline,
  /// within a specified tolerance. If closed, the closing segment between the
  /// last and first points of the polyline is not considered.
  ///
  /// @param point          our needle
  /// @param poly           our haystack
  /// @param closed         whether the polyline should be considered closed by
  ///                       a segment connecting the last point back to the
  ///                       first one
  /// @param geodesic       the polyline is composed of great circle segments if
  ///                       geodesic is true, and of Rhumb segments otherwise
  /// @param toleranceEarth tolerance (in meters)
  /// @return -1 if point does not lie on or near the polyline.
  /// 0 if point is between poly[0] and poly[1] (inclusive),
  /// 1 if between poly[1] and poly[2],
  /// ...,
  /// poly.size()-2 if between poly[poly.size() - 2] and poly[poly.size() - 1]
  static int locationIndexOnEdgeOrPath(LatLng point, List<LatLng> poly,
      bool closed, bool geodesic, num toleranceEarth) {
    if (poly.isEmpty) {
      return -1;
    }
    final tolerance = toleranceEarth / earthRadius;
    final havTolerance = MathUtil.hav(tolerance);
    final lat3 = MathUtil.toRadians(point.latitude);
    final lng3 = MathUtil.toRadians(point.longitude);
    final prev = closed ? poly.last : poly.first;
    var lat1 = MathUtil.toRadians(prev.latitude);
    var lng1 = MathUtil.toRadians(prev.longitude);
    var idx = 0;
    if (geodesic) {
      for (final point2 in poly) {
        final lat2 = MathUtil.toRadians(point2.latitude);
        final lng2 = MathUtil.toRadians(point2.longitude);
        if (_isOnSegmentGC(lat1, lng1, lat2, lng2, lat3, lng3, havTolerance)) {
          return max(0, idx - 1);
        }
        lat1 = lat2;
        lng1 = lng2;
        idx++;
      }
    } else {
      // We project the points to mercator space, where the Rhumb segment is a
      // straight line, and compute the geodesic distance between point3 and the
      // closest point on the segment. This method is an approximation, because
      // it uses "closest" in mercator space which is not "closest" on the
      // sphere -- but the error is small because "tolerance" is small.
      final minAcceptable = lat3 - tolerance;
      final maxAcceptable = lat3 + tolerance;
      var y1 = MathUtil.mercator(lat1);
      final y3 = MathUtil.mercator(lat3);
      final xTry = List<num?>.generate(3, (index) => null);

      for (final point2 in poly) {
        final lat2 = MathUtil.toRadians(point2.latitude);
        final y2 = MathUtil.mercator(lat2);
        final lng2 = MathUtil.toRadians(point2.longitude);
        if (max(lat1, lat2) >= minAcceptable &&
            min(lat1, lat2) <= maxAcceptable) {
          // We offset longitudes by -lng1; the implicit x1 is 0.
          final x2 = MathUtil.wrap(lng2 - lng1, -pi, pi);
          final x3Base = MathUtil.wrap(lng3 - lng1, -pi, pi);
          xTry[0] = x3Base;
          // Also explore MathUtil.wrapping of x3Base around the world in both
          // directions.
          xTry[1] = x3Base + 2 * pi;
          xTry[2] = x3Base - 2 * pi;
          for (final x3 in xTry) {
            final dy = y2 - y1;
            final len2 = x2 * x2 + dy * dy;
            final t = len2 <= 0
                ? 0
                : MathUtil.clamp((x3! * x2 + (y3 - y1) * dy) / len2, 0, 1);
            final xClosest = t * x2;
            final yClosest = y1 + t * dy;
            final latClosest = MathUtil.inverseMercator(yClosest);
            final havDist =
                MathUtil.havDistance(lat3, latClosest, x3! - xClosest);
            if (havDist < havTolerance) {
              return max(0, idx - 1);
            }
          }
        }
        lat1 = lat2;
        lng1 = lng2;
        y1 = y2;
        idx++;
      }
    }
    return -1;
  }

  /// Returns sin(initial bearing from (lat1,lng1) to (lat3,lng3) minus initial
  /// bearing from (lat1, lng1) to (lat2,lng2)).
  static num _sinDeltaBearing(
      num lat1, num lng1, num lat2, num lng2, num lat3, num lng3) {
    final sinLat1 = sin(lat1);
    final cosLat2 = cos(lat2);
    final cosLat3 = cos(lat3);
    final lat31 = lat3 - lat1;
    final lng31 = lng3 - lng1;
    final lat21 = lat2 - lat1;
    final lng21 = lng2 - lng1;
    final a = sin(lng31) * cosLat3;
    final c = sin(lng21) * cosLat2;
    final b = sin(lat31) + 2 * sinLat1 * cosLat3 * MathUtil.hav(lng31);
    final d = sin(lat21) + 2 * sinLat1 * cosLat2 * MathUtil.hav(lng21);
    final denom = (a * a + b * b) * (c * c + d * d);
    return denom <= 0 ? 1 : (a * d - b * c) / sqrt(denom);
  }

  static bool _isOnSegmentGC(num lat1, num lng1, num lat2, num lng2, num lat3,
      num lng3, num havTolerance) {
    final havDist13 = MathUtil.havDistance(lat1, lat3, lng1 - lng3);
    if (havDist13 <= havTolerance) {
      return true;
    }
    final havDist23 = MathUtil.havDistance(lat2, lat3, lng2 - lng3);
    if (havDist23 <= havTolerance) {
      return true;
    }
    final sinBearing = _sinDeltaBearing(lat1, lng1, lat2, lng2, lat3, lng3);
    final sinDist13 = MathUtil.sinFromHav(havDist13);
    final havCrossTrack = MathUtil.havFromSin(sinDist13 * sinBearing);
    if (havCrossTrack > havTolerance) {
      return false;
    }
    final havDist12 = MathUtil.havDistance(lat1, lat2, lng1 - lng2);
    final term = havDist12 + havCrossTrack * (1 - 2 * havDist12);
    if (havDist13 > term || havDist23 > term) {
      return false;
    }
    if (havDist12 < 0.74) {
      return true;
    }
    final cosCrossTrack = 1 - 2 * havCrossTrack;
    final havAlongTrack13 = (havDist13 - havCrossTrack) / cosCrossTrack;
    final havAlongTrack23 = (havDist23 - havCrossTrack) / cosCrossTrack;
    final sinSumAlongTrack =
        MathUtil.sinSumFromHav(havAlongTrack13, havAlongTrack23);
    return sinSumAlongTrack >
        0; // Compare with half-circle == pi using sign of sin().
  }

  /// Simplifies the given poly (polyline or polygon) using the Douglas-Peucker
  /// decimation algorithm. Increasing the tolerance will result in fewer points
  /// in the simplified polyline or polygon.
  /// When the providing a polygon as input, the first and last point of the
  /// list MUST have the same latitude and longitude (i.e., the polygon must be
  /// closed).  If the input polygon is not closed, the resulting polygon may
  /// not be fully simplified.
  /// The time complexity of Douglas-Peucker is O(n^2), so take care that you do
  /// not call this algorithm too frequently in your code.
  ///
  /// @param poly      polyline or polygon to be simplified. Polygon should be
  ///                  closed (i.e., first and last points should have the same
  ///                  latitude and longitude).
  /// @param tolerance in meters. Increasing the tolerance will result in fewer
  ///                  points in the simplified poly.
  /// @return a simplified poly produced by the Douglas-Peucker algorithm
  static List<LatLng> simplify(List<LatLng> poly, num tolerance) {
    final n = poly.length;
    if (n < 1) {
      throw const FormatException('Polyline must have at least 1 point');
    }
    if (tolerance <= 0) {
      throw const FormatException('Tolerance must be greater than zero');
    }

    final closedPolygon = isClosedPolygon(poly);
    late final LatLng lastPoint;

    // Check if the provided poly is a closed polygon
    if (closedPolygon) {
      // Add a small offset to the last point for Douglas-Peucker on polygons
      // (see #201)
      const offset = 0.00000000001;
      lastPoint = poly.last;
      // LatLng.latitude and .longitude are immutable, so replace the last point
      poly.removeLast();
      poly.add(
          LatLng(lastPoint.latitude + offset, lastPoint.longitude + offset));
    }

    int idx;
    var maxIdx = 0;
    final stack = Queue<List<int>>();
    final dists = List<num>.filled(n, 0);
    dists[0] = 1;
    dists[n - 1] = 1;
    num maxDist;
    num dist = 0.0;
    List<int> current;

    if (n > 2) {
      final stackVal = [0, (n - 1)];
      stack.add(stackVal);
      while (stack.isNotEmpty) {
        current = stack.removeLast();
        maxDist = 0;
        for (idx = current[0] + 1; idx < current[1]; ++idx) {
          dist = distanceToLine(poly[idx], poly[current[0]], poly[current[1]]);
          if (dist > maxDist) {
            maxDist = dist;
            maxIdx = idx;
          }
        }
        if (maxDist > tolerance) {
          dists[maxIdx] = maxDist;
          final stackValCurMax = [current[0], maxIdx];
          stack.add(stackValCurMax);
          final stackValMaxCur = [maxIdx, current[1]];
          stack.add(stackValMaxCur);
        }
      }
    }

    if (closedPolygon) {
      // Replace last point w/ offset with the original last point to re-close
      // the polygon
      poly.removeLast();
      poly.add(lastPoint);
    }

    // Generate the simplified line
    idx = 0;
    final simplifiedLine = <LatLng>[];
    for (final l in poly) {
      if (dists[idx] != 0) {
        simplifiedLine.add(l);
      }
      idx++;
    }

    return simplifiedLine;
  }

  /// Returns true if the provided list of points is a closed polygon (i.e., the
  /// first and last points are the same), and false if it is not
  ///
  /// @param poly polyline or polygon
  /// @return true if the provided list of points is a closed polygon (i.e., the
  /// first and last points are the same), and false if it is not
  static bool isClosedPolygon(List<LatLng> poly) => poly.first == poly.last;

  /// Computes the distance on the sphere between the point p and the line
  /// segment start to end.
  ///
  /// @param p     the point to be measured
  /// @param start the beginning of the line segment
  /// @param end   the end of the line segment
  /// @return the distance in meters (assuming spherical earth)
  static num distanceToLine(
      final LatLng p, final LatLng start, final LatLng end) {
    if (start == end) {
      return SphericalUtil.computeDistanceBetween(end, p);
    }

    final s0lat = MathUtil.toRadians(p.latitude);
    final s0lng = MathUtil.toRadians(p.longitude);
    final s1lat = MathUtil.toRadians(start.latitude);
    final s1lng = MathUtil.toRadians(start.longitude);
    final s2lat = MathUtil.toRadians(end.latitude);
    final s2lng = MathUtil.toRadians(end.longitude);

    final s2s1lat = s2lat - s1lat;
    final s2s1lng = s2lng - s1lng;
    final u = ((s0lat - s1lat) * s2s1lat + (s0lng - s1lng) * s2s1lng) /
        (s2s1lat * s2s1lat + s2s1lng * s2s1lng);
    if (u <= 0) {
      return SphericalUtil.computeDistanceBetween(p, start);
    }
    if (u >= 1) {
      return SphericalUtil.computeDistanceBetween(p, end);
    }
    final su = LatLng(start.latitude + u * (end.latitude - start.latitude),
        start.longitude + u * (end.longitude - start.longitude));
    return SphericalUtil.computeDistanceBetween(p, su);
  }

  /// Decodes an encoded path string into a sequence of LatLngs.
  static List<LatLng> decode(final String encodedPath) {
    final len = encodedPath.length;

    // For speed we preallocate to an upper bound on the final length, then
    // truncate the array before returning.
    final path = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < len) {
      var result = 1;
      var shift = 0;
      int b1;
      do {
        b1 = encodedPath.codeUnitAt(index++) - 63 - 1;
        result += b1 << shift;
        shift += 5;
      } while (b1 >= 0x1f);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      result = 1;
      shift = 0;
      int b2;
      do {
        b2 = encodedPath.codeUnitAt(index++) - 63 - 1;
        result += b2 << shift;
        shift += 5;
      } while (b2 >= 0x1f);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      path.add(LatLng(lat * 1e-5, lng * 1e-5));
    }

    return path;
  }

  /// Encodes a sequence of LatLngs into an encoded path string.
  static String encode(final List<LatLng> path) {
    var lastLat = 0;
    var lastLng = 0;

    final result = StringBuffer();

    for (final point in path) {
      final lat = (point.latitude * 1e5).round();
      final lng = (point.longitude * 1e5).round();

      _encode(lat - lastLat, result);
      _encode(lng - lastLng, result);

      lastLat = lat;
      lastLng = lng;
    }
    return result.toString();
  }

  static void _encode(int v, StringBuffer result) {
    v = v < 0 ? ~(v << 1) : v << 1;
    while (v >= 0x20) {
      result.write(String.fromCharCode((0x20 | (v & 0x1f)) + 63));
      v >>= 5;
    }
    result.write(String.fromCharCode(v + 63));
  }
}

class MathUtil {
  static num toRadians(num degrees) => degrees / 180.0 * pi;

  static num toDegrees(num rad) => rad * (180.0 / pi);

  /// Restrict x to the range [low, high].
  static num clamp(num x, num low, num high) =>
      x < low ? low : (x > high ? high : x);

  /// Wraps the given value into the inclusive-exclusive interval between min
  /// and max.
  /// @param n   The value to wrap.
  /// @param min The minimum.
  /// @param max The maximum.
  static num wrap(num n, num min, num max) =>
      (n >= min && n < max) ? n : (mod(n - min, max - min) + min);

  /// Returns the non-negative remainder of x / m.
  /// @param x The operand.
  /// @param m The modulus.
  static num mod(num x, num m) => ((x % m) + m) % m;

  /// Returns mercator Y corresponding to latitude.
  /// See http://en.wikipedia.org/wiki/Mercator_projection .
  static num mercator(num lat) => log(tan(lat * 0.5 + pi / 4));

  /// Returns latitude from mercator Y.
  static num inverseMercator(num y) => 2 * atan(exp(y)) - pi / 2;

  /// Returns haversine(angle-in-radians).
  /// hav(x) == (1 - cos(x)) / 2 == sin(x / 2)^2.
  static num hav(num x) => sin(x * 0.5) * sin(x * 0.5);

  /// Computes inverse haversine. Has good numerical stability around 0.
  /// arcHav(x) == acos(1 - 2 * x) == 2 * asin(sqrt(x)).
  /// The argument must be in [0, 1], and the result is positive.
  static num arcHav(num x) => 2 * asin(sqrt(x));

  // Given h==hav(x), returns sin(abs(x)).
  static num sinFromHav(num h) => 2 * sqrt(h * (1 - h));

  // Returns hav(asin(x)).
  static num havFromSin(num x) => (x * x) / (1 + sqrt(1 - (x * x))) * .5;

  // Returns sin(arcHav(x) + arcHav(y)).
  static num sinSumFromHav(num x, num y) {
    final a = sqrt(x * (1 - x));
    final b = sqrt(y * (1 - y));
    return 2 * (a + b - 2 * (a * y + b * x));
  }

  /// Returns hav() of distance from (lat1, lng1) to (lat2, lng2) on the unit
  /// sphere.
  static num havDistance(num lat1, num lat2, num dLng) =>
      hav(lat1 - lat2) + hav(dLng) * cos(lat1) * cos(lat2);
}

/// Port of SphericalUtil from android-maps-utils (https://github.com/googlemaps/android-maps-utils)
class SphericalUtil {
  static const num earthRadius = 6371009.0;

  /// Returns the heading from one LatLng to another LatLng. Headings are
  /// expressed in degrees clockwise from North within the range [-180,180).
  /// @return The heading in degrees clockwise from north.
  static num computeHeading(LatLng from, LatLng to) {
    // http://williams.best.vwh.net/avform.htm#Crs
    final fromLat = MathUtil.toRadians(from.latitude);
    final fromLng = MathUtil.toRadians(from.longitude);
    final toLat = MathUtil.toRadians(to.latitude);
    final toLng = MathUtil.toRadians(to.longitude);
    final dLng = toLng - fromLng;
    final heading = atan2(sin(dLng) * cos(toLat),
        cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(dLng));

    return MathUtil.wrap(MathUtil.toDegrees(heading), -180, 180);
  }

  /// Returns the LatLng resulting from moving a distance from an origin
  /// in the specified heading (expressed in degrees clockwise from north).
  /// @param from     The LatLng from which to start.
  /// @param distance The distance to travel.
  /// @param heading  The heading in degrees clockwise from north.
  static LatLng computeOffset(LatLng from, num distance, num heading) {
    distance /= earthRadius;
    heading = MathUtil.toRadians(heading);
    // http://williams.best.vwh.net/avform.htm#LL
    final fromLat = MathUtil.toRadians(from.latitude);
    final fromLng = MathUtil.toRadians(from.longitude);
    final cosDistance = cos(distance);
    final sinDistance = sin(distance);
    final sinFromLat = sin(fromLat);
    final cosFromLat = cos(fromLat);
    final sinLat =
        cosDistance * sinFromLat + sinDistance * cosFromLat * cos(heading);
    final dLng = atan2(sinDistance * cosFromLat * sin(heading),
        cosDistance - sinFromLat * sinLat);

    return LatLng(MathUtil.toDegrees(asin(sinLat)).toDouble(),
        MathUtil.toDegrees(fromLng + dLng).toDouble());
  }

  /// Returns the location of origin when provided with a LatLng destination,
  /// meters travelled and original heading. Headings are expressed in degrees
  /// clockwise from North. This function returns null when no solution is
  /// available.
  /// @param to       The destination LatLng.
  /// @param distance The distance travelled, in meters.
  /// @param heading  The heading in degrees clockwise from north.
  static LatLng? computeOffsetOrigin(LatLng to, num distance, num heading) {
    heading = MathUtil.toRadians(heading);
    distance /= earthRadius;
    // http://lists.maptools.org/pipermail/proj/2008-October/003939.html
    final n1 = cos(distance);
    final n2 = sin(distance) * cos(heading);
    final n3 = sin(distance) * sin(heading);
    final n4 = sin(MathUtil.toRadians(to.latitude));
    // There are two solutions for b. b = n2 * n4 +/- sqrt(), one solution
    // results in the latitude outside the [-90, 90] range. We first try one
    // solution and back off to the other if we are outside that range.
    final n12 = n1 * n1;
    final discriminant = n2 * n2 * n12 + n12 * n12 - n12 * n4 * n4;
    if (discriminant < 0) {
      // No real solution which would make sense in LatLng-space.
      return null;
    }
    num b = n2 * n4 + sqrt(discriminant);
    b /= n1 * n1 + n2 * n2;
    final a = (n4 - n2 * b) / n1;
    num fromLatRadians = atan2(a, b);
    if (fromLatRadians < -pi / 2 || fromLatRadians > pi / 2) {
      b = n2 * n4 - sqrt(discriminant);
      b /= n1 * n1 + n2 * n2;
      fromLatRadians = atan2(a, b);
    }
    if (fromLatRadians < -pi / 2 || fromLatRadians > pi / 2) {
      // No solution which would make sense in LatLng-space.
      return null;
    }
    final fromLngRadians = MathUtil.toRadians(to.longitude) -
        atan2(n3, n1 * cos(fromLatRadians) - n2 * sin(fromLatRadians));
    return LatLng(MathUtil.toDegrees(fromLatRadians).toDouble(),
        MathUtil.toDegrees(fromLngRadians).toDouble());
  }

  /// Returns the LatLng which lies the given fraction of the way between the
  /// origin LatLng and the destination LatLng.
  /// @param from     The LatLng from which to start.
  /// @param to       The LatLng toward which to travel.
  /// @param fraction A fraction of the distance to travel.
  /// @return The interpolated LatLng.
  static LatLng interpolate(LatLng from, LatLng to, num fraction) {
    // http://en.wikipedia.org/wiki/Slerp
    final fromLat = MathUtil.toRadians(from.latitude);
    final fromLng = MathUtil.toRadians(from.longitude);
    final toLat = MathUtil.toRadians(to.latitude);
    final toLng = MathUtil.toRadians(to.longitude);
    final cosFromLat = cos(fromLat);
    final cosToLat = cos(toLat);

    // Computes Spherical interpolation coefficients.
    final angle = computeAngleBetween(from, to);
    final sinAngle = sin(angle);
    if (sinAngle < 1E-6) {
      return LatLng(from.latitude + fraction * (to.latitude - from.latitude),
          from.longitude + fraction * (to.longitude - from.longitude));
    }
    final a = sin((1 - fraction) * angle) / sinAngle;
    final b = sin(fraction * angle) / sinAngle;

    // Converts from polar to vector and interpolate.
    final x = a * cosFromLat * cos(fromLng) + b * cosToLat * cos(toLng);
    final y = a * cosFromLat * sin(fromLng) + b * cosToLat * sin(toLng);
    final z = a * sin(fromLat) + b * sin(toLat);

    // Converts interpolated vector back to polar.
    final lat = atan2(z, sqrt(x * x + y * y));
    final lng = atan2(y, x);

    return LatLng(
        MathUtil.toDegrees(lat).toDouble(), MathUtil.toDegrees(lng).toDouble());
  }

  /// Returns distance on the unit sphere; the arguments are in radians.
  static num distanceRadians(num lat1, num lng1, num lat2, num lng2) =>
      MathUtil.arcHav(MathUtil.havDistance(lat1, lat2, lng1 - lng2));

  /// Returns the angle between two LatLngs, in radians. This is the same as the
  /// distance on the unit sphere.
  static num computeAngleBetween(LatLng from, LatLng to) => distanceRadians(
      MathUtil.toRadians(from.latitude),
      MathUtil.toRadians(from.longitude),
      MathUtil.toRadians(to.latitude),
      MathUtil.toRadians(to.longitude));

  /// Returns the distance between two LatLngs, in meters.
  static num computeDistanceBetween(LatLng from, LatLng to) =>
      computeAngleBetween(from, to) * earthRadius;

  /// Returns the length of the given path, in meters, on Earth.
  static num computeLength(List<LatLng> path) {
    if (path.length < 2) {
      return 0;
    }

    final prev = path.first;
    var prevLat = MathUtil.toRadians(prev.latitude);
    var prevLng = MathUtil.toRadians(prev.longitude);

    final length = path.fold<num>(0.0, (value, point) {
      final lat = MathUtil.toRadians(point.latitude);
      final lng = MathUtil.toRadians(point.longitude);
      value += distanceRadians(prevLat, prevLng, lat, lng);
      prevLat = lat;
      prevLng = lng;

      return value;
    });

    return length * earthRadius;
  }

  /// Returns the area of a closed path on Earth.
  /// @param path A closed path.
  /// @return The path's area in square meters.
  static num computeArea(List<LatLng> path) => computeSignedArea(path).abs();

  /// Returns the signed area of a closed path on Earth. The sign of the area
  /// may be used to determine the orientation of the path.
  /// "inside" is the surface that does not contain the South Pole.
  /// @param path A closed path.
  /// @return The loop's area in square meters.
  static num computeSignedArea(List<LatLng> path) =>
      _computeSignedArea(path, earthRadius);

  /// Returns the signed area of a closed path on a sphere of given radius.
  /// The computed area uses the same units as the radius squared.
  /// Used by SphericalUtilTest.
  static num _computeSignedArea(List<LatLng> path, num radius) {
    if (path.length < 3) {
      return 0;
    }

    final prev = path.last;
    var prevTanLat = tan((pi / 2 - MathUtil.toRadians(prev.latitude)) / 2);
    var prevLng = MathUtil.toRadians(prev.longitude);

    // For each edge, accumulate the signed area of the triangle formed by the
    // North Pole and that edge ("polar triangle").
    final total = path.fold<num>(0.0, (value, point) {
      final tanLat = tan((pi / 2 - MathUtil.toRadians(point.latitude)) / 2);
      final lng = MathUtil.toRadians(point.longitude);

      value += _polarTriangleArea(tanLat, lng, prevTanLat, prevLng);

      prevTanLat = tanLat;
      prevLng = lng;

      return value;
    });

    return total * (radius * radius);
  }

  /// Returns the signed area of a triangle which has North Pole as a vertex.
  /// Formula derived from "Area of a spherical triangle given two edges and
  /// the included angle" as per "Spherical Trigonometry" by Todhunter, page 71,
  /// section 103, point 2.
  /// See http://books.google.com/books?id=3uBHAAAAIAAJ&pg=PA71
  /// The arguments named "tan" are tan((pi/2 - latitude)/2).
  static num _polarTriangleArea(num tan1, num lng1, num tan2, num lng2) {
    final deltaLng = lng1 - lng2;
    final t = tan1 * tan2;
    return 2 * atan2(t * sin(deltaLng), 1 + t * cos(deltaLng));
  }
}
