import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/tap_master_models.dart';

class TapMasterBoard extends StatefulWidget {
  final TapMasterPuzzle puzzle;
  final Function(TapBlock) onBlockTap;
  final Set<TapBlock> tappableBlocks;

  const TapMasterBoard({
    super.key,
    required this.puzzle,
    required this.onBlockTap,
    required this.tappableBlocks,
  });

  @override
  State<TapMasterBoard> createState() => _TapMasterBoardState();
}

class _TapMasterBoardState extends State<TapMasterBoard>
    with TickerProviderStateMixin {
  final Map<TapBlock, AnimationController> _removeAnimations = {};
  final Set<TapBlock> _bouncingBlocks = {};
  TapBlock? _animatingBlock;

  // 3D rotation angles
  double _rotationY = 0.4; // Initial horizontal rotation
  double _rotationX = 0.5; // Initial vertical rotation (looking from above)

  // For detecting tap vs drag
  Offset? _dragStart;
  bool _isDragging = false;

  @override
  void dispose() {
    for (final controller in _removeAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Check if there's a block in the flight path
  bool _isPathBlocked(TapBlock block) {
    final activeBlocks = widget.puzzle.blocks
        .where((b) => !b.isRemoved && b != block)
        .toList();

    for (final other in activeBlocks) {
      switch (block.direction) {
        case ArrowDirection.north: // -X direction
          if (other.y == block.y && other.z == block.z && other.x < block.x) return true;
          break;
        case ArrowDirection.south: // +X direction
          if (other.y == block.y && other.z == block.z && other.x > block.x) return true;
          break;
        case ArrowDirection.west: // +Z direction
          if (other.y == block.y && other.x == block.x && other.z > block.z) return true;
          break;
        case ArrowDirection.east: // -Z direction
          if (other.y == block.y && other.x == block.x && other.z < block.z) return true;
          break;
        case ArrowDirection.skyward: // +Y direction
          if (other.x == block.x && other.z == block.z && other.y > block.y) return true;
          break;
        case ArrowDirection.groundward: // -Y direction
          if (other.x == block.x && other.z == block.z && other.y < block.y) return true;
          break;
      }
    }
    return false;
  }

  void _handleBlockTap(TapBlock block) {
    if (_animatingBlock != null) return;

    final isBlocked = _isPathBlocked(block);

    final controller = AnimationController(
      duration: Duration(milliseconds: isBlocked ? 300 : 600),
      vsync: this,
    );

    _removeAnimations[block] = controller;
    _animatingBlock = block;

    if (isBlocked) {
      _bouncingBlocks.add(block);
    }

    // Trigger rebuild on every frame for smooth animation
    controller.addListener(() {
      if (mounted) setState(() {});
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (isBlocked) {
          // Bounce back
          controller.reverse();
        } else {
          // Fly away complete: remove the block
          widget.onBlockTap(block);
          _animatingBlock = null;
          controller.dispose();
          _removeAnimations.remove(block);
        }
      } else if (status == AnimationStatus.dismissed) {
        // Bounce back complete
        _animatingBlock = null;
        _bouncingBlocks.remove(block);
        controller.dispose();
        _removeAnimations.remove(block);
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            _dragStart = details.localPosition;
            _isDragging = false;
          },
          onPanUpdate: (details) {
            final delta = details.localPosition - (_dragStart ?? details.localPosition);
            if (delta.distance > 10) {
              _isDragging = true;
            }

            if (_isDragging) {
              setState(() {
                _rotationY += details.delta.dx * 0.01;
                _rotationX -= details.delta.dy * 0.01;
              });
            }
          },
          onPanEnd: (details) {
            // If not dragging (small movement), treat as tap
            if (!_isDragging && _dragStart != null) {
              _onTapDown(_dragStart!, constraints);
            }
            _dragStart = null;
            _isDragging = false;
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _TapMasterPainter(
              puzzle: widget.puzzle,
              tappableBlocks: widget.tappableBlocks,
              removeAnimations: _removeAnimations,
              bouncingBlocks: _bouncingBlocks,
              rotationX: _rotationX,
              rotationY: _rotationY,
            ),
          ),
        );
      },
    );
  }

  void _onTapDown(Offset tapPos, BoxConstraints constraints) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);
    final metrics = _BoardMetrics.calculate(size, widget.puzzle, _rotationX, _rotationY);

    final activeBlocks = widget.puzzle.blocks
        .where((b) => !b.isRemoved)
        .toList();

    // Sort for hit testing: closer blocks first
    activeBlocks.sort((a, b) {
      final centerA = _getBlockCenter3D(a, widget.puzzle);
      final centerB = _getBlockCenter3D(b, widget.puzzle);
      final rotatedA = _rotate3D(centerA, _rotationX, _rotationY);
      final rotatedB = _rotate3D(centerB, _rotationX, _rotationY);
      return rotatedB.$3.compareTo(rotatedA.$3); // Higher z = closer
    });

    for (final block in activeBlocks) {
      final screenPos = _getBlockScreenCenter(block, metrics);
      final dx = tapPos.dx - screenPos.dx;
      final dy = tapPos.dy - screenPos.dy;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist < metrics.cubeSize * 0.8) {
        _handleBlockTap(block);
        return;
      }
    }
  }

  (double, double, double) _getBlockCenter3D(TapBlock block, TapMasterPuzzle puzzle) {
    final cx = puzzle.gridWidth / 2.0;
    final cy = puzzle.maxHeight / 2.0;
    final cz = puzzle.gridDepth / 2.0;
    return (block.x + 0.5 - cx, block.y + 0.5 - cy, block.z + 0.5 - cz);
  }

  (double, double, double) _rotate3D((double, double, double) point, double rotX, double rotY) {
    var (x, y, z) = point;

    // Rotate around Y axis
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    // Rotate around X axis
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);
    final y1 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    return (x1, y1, z2);
  }

  Offset _getBlockScreenCenter(TapBlock block, _BoardMetrics metrics) {
    final center3D = _getBlockCenter3D(block, widget.puzzle);
    final rotated = _rotate3D(center3D, _rotationX, _rotationY);
    return Offset(
      metrics.centerX + rotated.$1 * metrics.cubeSize,
      metrics.centerY - rotated.$2 * metrics.cubeSize,
    );
  }
}

class _BoardMetrics {
  final double cubeSize;
  final double centerX;
  final double centerY;

  _BoardMetrics({
    required this.cubeSize,
    required this.centerX,
    required this.centerY,
  });

  static _BoardMetrics calculate(Size size, TapMasterPuzzle puzzle, double rotX, double rotY) {
    final gridW = puzzle.gridWidth.toDouble();
    final gridD = puzzle.gridDepth.toDouble();
    final gridH = puzzle.maxHeight.toDouble();

    // Calculate the maximum extent of the 3D structure when rotated
    // Use diagonal of the bounding box for worst case rotation
    final diagonalXZ = math.sqrt(gridW * gridW + gridD * gridD);
    final maxHorizontalExtent = diagonalXZ;
    final maxVerticalExtent = math.sqrt(diagonalXZ * diagonalXZ + gridH * gridH);

    // Use more screen space - 85% of available area
    final availableWidth = size.width * 0.85;
    final availableHeight = size.height * 0.85;

    // Calculate cube size that fits in both dimensions
    final cubeSizeByWidth = availableWidth / (maxHorizontalExtent * 1.2);
    final cubeSizeByHeight = availableHeight / (maxVerticalExtent * 1.2);

    // Use the smaller to ensure fit, but don't go too small
    final cubeSize = math.min(cubeSizeByWidth, cubeSizeByHeight);

    return _BoardMetrics(
      cubeSize: cubeSize,
      centerX: size.width / 2,
      centerY: size.height / 2,
    );
  }
}

class _TapMasterPainter extends CustomPainter {
  final TapMasterPuzzle puzzle;
  final Set<TapBlock> tappableBlocks;
  final Map<TapBlock, AnimationController> removeAnimations;
  final Set<TapBlock> bouncingBlocks;
  final double rotationX;
  final double rotationY;

  _TapMasterPainter({
    required this.puzzle,
    required this.tappableBlocks,
    required this.removeAnimations,
    required this.bouncingBlocks,
    required this.rotationX,
    required this.rotationY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final metrics = _BoardMetrics.calculate(size, puzzle, rotationX, rotationY);

    final activeBlocks = puzzle.blocks.where((b) => !b.isRemoved).toList();

    // Sort blocks by depth for proper rendering (furthest first)
    activeBlocks.sort((a, b) {
      final centerA = _getBlockCenter3D(a);
      final centerB = _getBlockCenter3D(b);
      final rotatedA = _rotate3D(centerA);
      final rotatedB = _rotate3D(centerB);
      return rotatedA.$3.compareTo(rotatedB.$3); // Lower z = further = draw first
    });

    for (final block in activeBlocks) {
      final animController = removeAnimations[block];
      final animValue = animController?.value ?? 0.0;
      _drawCube(canvas, block, metrics, animValue);
    }
  }

  (double, double, double) _getBlockCenter3D(TapBlock block) {
    final cx = puzzle.gridWidth / 2.0;
    final cy = puzzle.maxHeight / 2.0;
    final cz = puzzle.gridDepth / 2.0;
    return (block.x + 0.5 - cx, block.y + 0.5 - cy, block.z + 0.5 - cz);
  }

  (double, double, double) _rotate3D((double, double, double) point) {
    var (x, y, z) = point;

    // Rotate around Y axis
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);
    final x1 = x * cosY - z * sinY;
    final z1 = x * sinY + z * cosY;

    // Rotate around X axis
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);
    final y1 = y * cosX - z1 * sinX;
    final z2 = y * sinX + z1 * cosX;

    return (x1, y1, z2);
  }

  Offset _project((double, double, double) point3D, _BoardMetrics metrics) {
    return Offset(
      metrics.centerX + point3D.$1 * metrics.cubeSize,
      metrics.centerY - point3D.$2 * metrics.cubeSize,
    );
  }

  void _drawCube(Canvas canvas, TapBlock block, _BoardMetrics metrics, double animValue) {
    final cx = puzzle.gridWidth / 2.0;
    final cy = puzzle.maxHeight / 2.0;
    final cz = puzzle.gridDepth / 2.0;

    // Block position (corner)
    double bx = block.x - cx;
    double by = block.y - cy;
    double bz = block.z - cz;

    // Apply fly-away or bounce animation based on arrow direction
    if (animValue > 0) {
      final isBouncing = bouncingBlocks.contains(block);

      // Different curves and distances for bouncing vs flying
      final curvedValue = isBouncing
          ? Curves.easeOutQuad.transform(animValue)
          : Curves.easeInQuad.transform(animValue);

      // Bounce: 0.5 block distance, Fly: full grid + 1 block
      final bounceDistance = 0.5;
      final gridSizeX = isBouncing ? bounceDistance : (puzzle.gridWidth + 1.0);
      final gridSizeZ = isBouncing ? bounceDistance : (puzzle.gridDepth + 1.0);
      final gridSizeY = isBouncing ? bounceDistance : (puzzle.maxHeight + 1.0);

      switch (block.direction) {
        case ArrowDirection.north: // -X
          bx -= gridSizeX * curvedValue;
          break;
        case ArrowDirection.south: // +X
          bx += gridSizeX * curvedValue;
          break;
        case ArrowDirection.west: // +Z
          bz += gridSizeZ * curvedValue;
          break;
        case ArrowDirection.east: // -Z
          bz -= gridSizeZ * curvedValue;
          break;
        case ArrowDirection.skyward: // +Y
          by += gridSizeY * curvedValue;
          break;
        case ArrowDirection.groundward: // -Y
          by -= gridSizeY * curvedValue;
          break;
      }
    }

    // 8 vertices of the cube (unit cube at block position)
    final vertices3D = [
      (bx, by, bz),           // 0: bottom-back-left
      (bx + 1, by, bz),       // 1: bottom-back-right
      (bx + 1, by, bz + 1),   // 2: bottom-front-right
      (bx, by, bz + 1),       // 3: bottom-front-left
      (bx, by + 1, bz),       // 4: top-back-left
      (bx + 1, by + 1, bz),   // 5: top-back-right
      (bx + 1, by + 1, bz + 1), // 6: top-front-right
      (bx, by + 1, bz + 1),   // 7: top-front-left
    ];

    // Rotate all vertices
    final rotatedVertices = vertices3D.map((v) => _rotate3D(v)).toList();

    // Project to 2D
    final projected = rotatedVertices.map((v) => _project(v, metrics)).toList();

    final isTappable = tappableBlocks.contains(block);

    // Define faces with vertex indices and their normals for visibility check
    // Face: [v0, v1, v2, v3], normal direction
    final faces = [
      ([4, 5, 6, 7], (0.0, 1.0, 0.0)),  // 0: Top face
      ([0, 3, 2, 1], (0.0, -1.0, 0.0)), // 1: Bottom face
      ([0, 1, 5, 4], (0.0, 0.0, -1.0)), // 2: Back face (-Z)
      ([2, 3, 7, 6], (0.0, 0.0, 1.0)),  // 3: Front face (+Z)
      ([0, 4, 7, 3], (-1.0, 0.0, 0.0)), // 4: Left face (-X)
      ([1, 2, 6, 5], (1.0, 0.0, 0.0)),  // 5: Right face (+X)
    ];

    final faceColors = [
      _adjustBrightness(block.color, 1.0),  // Top - brightest
      _adjustBrightness(block.color, 0.4),  // Bottom - darkest
      _adjustBrightness(block.color, 0.6),  // Back
      _adjustBrightness(block.color, 0.8),  // Front
      _adjustBrightness(block.color, 0.7),  // Left
      _adjustBrightness(block.color, 0.5),  // Right
    ];

    // Draw visible faces
    for (int i = 0; i < faces.length; i++) {
      final (indices, normal) = faces[i];

      // Check if face is visible (facing camera)
      final rotatedNormal = _rotate3D(normal);
      if (rotatedNormal.$3 <= 0) continue; // Face is pointing away

      final path = Path();
      path.moveTo(projected[indices[0]].dx, projected[indices[0]].dy);
      for (int j = 1; j < indices.length; j++) {
        path.lineTo(projected[indices[j]].dx, projected[indices[j]].dy);
      }
      path.close();

      // Fill face
      final fillPaint = Paint()
        ..color = faceColors[i].withValues(alpha: 1.0 - animValue)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Draw edges
      final edgePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6 * (1.0 - animValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, edgePaint);

      // Determine which faces should show arrows based on direction
      bool shouldDrawArrow = _shouldDrawArrowOnFace(block.direction, i);

      if (shouldDrawArrow) {
        _drawArrowOnFace(canvas, projected, indices, block.direction, isTappable, animValue, i);
      }

      // Highlight tappable blocks on all visible faces
      if (isTappable && animValue == 0) {
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, highlightPaint);
      }
    }
  }

  bool _shouldDrawArrowOnFace(ArrowDirection direction, int faceIndex) {
    // faceIndex: 0=Top, 1=Bottom, 2=Back, 3=Front, 4=Left, 5=Right
    // Show arrow on both opposite faces so it's visible from any angle
    switch (direction) {
      case ArrowDirection.north: // -X: show on top and bottom faces
        return faceIndex == 0 || faceIndex == 1;
      case ArrowDirection.south: // +X: show on top and bottom faces
        return faceIndex == 0 || faceIndex == 1;
      case ArrowDirection.east: // -Z: show on top and bottom faces
        return faceIndex == 0 || faceIndex == 1;
      case ArrowDirection.west: // +Z: show on top and bottom faces
        return faceIndex == 0 || faceIndex == 1;
      case ArrowDirection.skyward: // +Y: show on front and back faces
        return faceIndex == 2 || faceIndex == 3;
      case ArrowDirection.groundward: // -Y: show on front and back faces
        return faceIndex == 2 || faceIndex == 3;
    }
  }

  void _drawArrowOnFace(Canvas canvas, List<Offset> projected, List<int> indices,
      ArrowDirection direction, bool isTappable, double animValue, int faceIndex) {

    // Get the 4 corners of the face
    final p0 = projected[indices[0]];
    final p1 = projected[indices[1]];
    final p2 = projected[indices[2]];
    final p3 = projected[indices[3]];

    // Center of the face
    final center = Offset(
      (p0.dx + p1.dx + p2.dx + p3.dx) / 4,
      (p0.dy + p1.dy + p2.dy + p3.dy) / 4,
    );

    // All 4 edge midpoints
    final mid01 = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    final mid12 = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final mid23 = Offset((p2.dx + p3.dx) / 2, (p2.dy + p3.dy) / 2);
    final mid30 = Offset((p3.dx + p0.dx) / 2, (p3.dy + p0.dy) / 2);

    Offset? tipMid, tailMid, perpMid1, perpMid2;

    // Determine arrow direction and perpendicular based on face and direction
    switch (faceIndex) {
      case 0: // Top face [4,5,6,7]: mid01=back, mid12=right, mid23=front, mid30=left
        if (direction == ArrowDirection.east) { // -Z (back)
          tipMid = mid01; tailMid = mid23; perpMid1 = mid30; perpMid2 = mid12;
        } else if (direction == ArrowDirection.west) { // +Z (front)
          tipMid = mid23; tailMid = mid01; perpMid1 = mid30; perpMid2 = mid12;
        } else if (direction == ArrowDirection.north) { // -X (left)
          tipMid = mid30; tailMid = mid12; perpMid1 = mid01; perpMid2 = mid23;
        } else if (direction == ArrowDirection.south) { // +X (right)
          tipMid = mid12; tailMid = mid30; perpMid1 = mid01; perpMid2 = mid23;
        }
        break;

      case 1: // Bottom face [0,3,2,1]: mid01=left, mid12=front, mid23=right, mid30=back
        if (direction == ArrowDirection.east) { // -Z (back)
          tipMid = mid30; tailMid = mid12; perpMid1 = mid01; perpMid2 = mid23;
        } else if (direction == ArrowDirection.west) { // +Z (front)
          tipMid = mid12; tailMid = mid30; perpMid1 = mid01; perpMid2 = mid23;
        } else if (direction == ArrowDirection.north) { // -X (left)
          tipMid = mid01; tailMid = mid23; perpMid1 = mid12; perpMid2 = mid30;
        } else if (direction == ArrowDirection.south) { // +X (right)
          tipMid = mid23; tailMid = mid01; perpMid1 = mid12; perpMid2 = mid30;
        }
        break;

      case 2: // Back face [0,1,5,4]: mid01=bottom, mid12=right, mid23=top, mid30=left
        if (direction == ArrowDirection.north) { // -X (left)
          tipMid = mid30; tailMid = mid12; perpMid1 = mid01; perpMid2 = mid23;
        } else if (direction == ArrowDirection.south) { // +X (right)
          tipMid = mid12; tailMid = mid30; perpMid1 = mid01; perpMid2 = mid23;
        } else if (direction == ArrowDirection.skyward) { // +Y (up)
          tipMid = mid23; tailMid = mid01; perpMid1 = mid30; perpMid2 = mid12;
        } else if (direction == ArrowDirection.groundward) { // -Y (down)
          tipMid = mid01; tailMid = mid23; perpMid1 = mid30; perpMid2 = mid12;
        }
        break;

      case 3: // Front face [2,3,7,6]: mid01=bottom, mid12=left, mid23=top, mid30=right
        if (direction == ArrowDirection.north) { // -X (left)
          tipMid = mid12; tailMid = mid30; perpMid1 = mid01; perpMid2 = mid23;
        } else if (direction == ArrowDirection.south) { // +X (right)
          tipMid = mid30; tailMid = mid12; perpMid1 = mid01; perpMid2 = mid23;
        } else if (direction == ArrowDirection.skyward) { // +Y (up)
          tipMid = mid23; tailMid = mid01; perpMid1 = mid12; perpMid2 = mid30;
        } else if (direction == ArrowDirection.groundward) { // -Y (down)
          tipMid = mid01; tailMid = mid23; perpMid1 = mid12; perpMid2 = mid30;
        }
        break;

      case 4: // Left face [0,4,7,3]: mid01=back, mid12=top, mid23=front, mid30=bottom
        if (direction == ArrowDirection.east) { // -Z (back)
          tipMid = mid01; tailMid = mid23; perpMid1 = mid30; perpMid2 = mid12;
        } else if (direction == ArrowDirection.west) { // +Z (front)
          tipMid = mid23; tailMid = mid01; perpMid1 = mid30; perpMid2 = mid12;
        } else if (direction == ArrowDirection.skyward) { // +Y (up)
          tipMid = mid12; tailMid = mid30; perpMid1 = mid01; perpMid2 = mid23;
        } else if (direction == ArrowDirection.groundward) { // -Y (down)
          tipMid = mid30; tailMid = mid12; perpMid1 = mid01; perpMid2 = mid23;
        }
        break;

      case 5: // Right face [1,2,6,5]: mid01=front, mid12=top, mid23=back, mid30=bottom
        if (direction == ArrowDirection.east) { // -Z (back)
          tipMid = mid23; tailMid = mid01; perpMid1 = mid30; perpMid2 = mid12;
        } else if (direction == ArrowDirection.west) { // +Z (front)
          tipMid = mid01; tailMid = mid23; perpMid1 = mid30; perpMid2 = mid12;
        } else if (direction == ArrowDirection.skyward) { // +Y (up)
          tipMid = mid12; tailMid = mid30; perpMid1 = mid01; perpMid2 = mid23;
        } else if (direction == ArrowDirection.groundward) { // -Y (down)
          tipMid = mid30; tailMid = mid12; perpMid1 = mid01; perpMid2 = mid23;
        }
        break;
    }

    if (tipMid == null || tailMid == null || perpMid1 == null || perpMid2 == null) return;

    // Scale positions relative to center
    final tip = Offset(
      center.dx + (tipMid.dx - center.dx) * 0.75,
      center.dy + (tipMid.dy - center.dy) * 0.75,
    );
    final tail = Offset(
      center.dx + (tailMid.dx - center.dx) * 0.3,
      center.dy + (tailMid.dy - center.dy) * 0.3,
    );

    // Calculate perpendicular direction using face's actual edge (perspective-correct)
    final perpDir = Offset(
      (perpMid2.dx - perpMid1.dx),
      (perpMid2.dy - perpMid1.dy),
    );
    final perpLen = math.sqrt(perpDir.dx * perpDir.dx + perpDir.dy * perpDir.dy);
    if (perpLen == 0) return;
    final perpUnit = Offset(perpDir.dx / perpLen, perpDir.dy / perpLen);

    final arrowColor = isTappable
        ? Colors.black.withValues(alpha: 0.85 * (1.0 - animValue))
        : Colors.black.withValues(alpha: 0.6 * (1.0 - animValue));

    // Arrow dimensions relative to face
    final bodyWidth = perpLen * 0.12;
    final headWidth = perpLen * 0.25;
    final headLength = (tip - tail).distance * 0.35;

    // Calculate arrow points
    final arrowDir = Offset(tip.dx - tail.dx, tip.dy - tail.dy);
    final arrowLen = math.sqrt(arrowDir.dx * arrowDir.dx + arrowDir.dy * arrowDir.dy);
    if (arrowLen == 0) return;
    final arrowUnit = Offset(arrowDir.dx / arrowLen, arrowDir.dy / arrowLen);

    final headBase = Offset(
      tip.dx - arrowUnit.dx * headLength,
      tip.dy - arrowUnit.dy * headLength,
    );

    // Build arrow path using perspective-correct perpendicular
    final path = Path();
    path.moveTo(tail.dx + perpUnit.dx * bodyWidth, tail.dy + perpUnit.dy * bodyWidth);
    path.lineTo(headBase.dx + perpUnit.dx * bodyWidth, headBase.dy + perpUnit.dy * bodyWidth);
    path.lineTo(headBase.dx + perpUnit.dx * headWidth, headBase.dy + perpUnit.dy * headWidth);
    path.lineTo(tip.dx, tip.dy);
    path.lineTo(headBase.dx - perpUnit.dx * headWidth, headBase.dy - perpUnit.dy * headWidth);
    path.lineTo(headBase.dx - perpUnit.dx * bodyWidth, headBase.dy - perpUnit.dy * bodyWidth);
    path.lineTo(tail.dx - perpUnit.dx * bodyWidth, tail.dy - perpUnit.dy * bodyWidth);
    path.close();

    canvas.drawPath(path, Paint()..color = arrowColor..style = PaintingStyle.fill);
  }

  Color _adjustBrightness(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * factor).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant _TapMasterPainter oldDelegate) {
    return oldDelegate.puzzle != puzzle ||
        oldDelegate.tappableBlocks != tappableBlocks ||
        oldDelegate.removeAnimations.length != removeAnimations.length ||
        oldDelegate.bouncingBlocks.length != bouncingBlocks.length ||
        oldDelegate.rotationX != rotationX ||
        oldDelegate.rotationY != rotationY ||
        removeAnimations.values.any((c) => c.isAnimating);
  }
}
