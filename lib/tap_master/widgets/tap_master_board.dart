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
  final Set<TapBlock> _bouncingBlocks = {}; // Blocks that are bouncing back
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

  /// Check if there's a block blocking the path or on top of this block
  bool _isPathBlocked(TapBlock block) {
    final activeBlocks = widget.puzzle.blocks.where((b) => !b.isRemoved && b != block).toList();

    for (final other in activeBlocks) {
      // Check if there's a block directly on top (can't move if supporting another block)
      if (other.x == block.x && other.z == block.z && other.y > block.y) {
        return true;
      }

      // Check if there's a block in the flight path (same Y level)
      bool isInPath = false;
      switch (block.direction) {
        case ArrowDirection.up:
          // Up direction: negative X direction
          if (other.x < block.x && other.y == block.y && other.z == block.z) {
            isInPath = true;
          }
          break;
        case ArrowDirection.down:
          // Down direction: positive X direction
          if (other.x > block.x && other.y == block.y && other.z == block.z) {
            isInPath = true;
          }
          break;
        case ArrowDirection.left:
          // Left direction: positive Z direction
          if (other.z > block.z && other.y == block.y && other.x == block.x) {
            isInPath = true;
          }
          break;
        case ArrowDirection.right:
          // Right direction: negative Z direction
          if (other.z < block.z && other.y == block.y && other.x == block.x) {
            isInPath = true;
          }
          break;
      }

      if (isInPath) return true;
    }

    return false;
  }

  void _handleBlockTap(TapBlock block) {
    // Allow tapping any block - if path is blocked, it will bounce back
    if (_animatingBlock != null) return;

    final isBlocked = _isPathBlocked(block);

    final controller = AnimationController(
      duration: Duration(milliseconds: isBlocked ? 400 : 800),
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
          // Bounce back: reverse the animation
          controller.reverse();
        } else {
          // Fly away: remove the block
          widget.onBlockTap(block);
          _animatingBlock = null;
          controller.dispose();
          _removeAnimations.remove(block);
        }
      } else if (status == AnimationStatus.dismissed) {
        // Bounce animation completed (returned to original position)
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
            if (delta.distance > 5) {
              _isDragging = true;
            }

            setState(() {
              _rotationY -= details.delta.dx * 0.01;
              _rotationX += details.delta.dy * 0.01;
              // 360도 회전 가능 (제한 없음)
            });
          },
          onPanEnd: (details) {
            _dragStart = null;
          },
          onTapUp: (details) {
            if (!_isDragging) {
              _onTapDown(details.localPosition, constraints);
            }
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
    final maxDim = math.max(puzzle.gridWidth, math.max(puzzle.gridDepth, puzzle.maxHeight)).toDouble();

    final availableSize = math.min(size.width, size.height) * 0.7;
    final cubeSize = availableSize / (maxDim * 1.8);

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

      // Apply different curves for bouncing vs flying
      final curvedValue = isBouncing
          ? Curves.easeOutQuad.transform(animValue) // Decelerate when bouncing
          : Curves.easeInQuad.transform(animValue); // Accelerate when flying away

      // Bounce: short distance (0.5 block), Fly: full grid + 1 block
      final moveDistance = isBouncing ? 0.5 : 1.0;
      final gridSizeX = isBouncing ? moveDistance : (puzzle.gridWidth + 1.0);
      final gridSizeZ = isBouncing ? moveDistance : (puzzle.gridDepth + 1.0);

      switch (block.direction) {
        case ArrowDirection.up:
          bx -= gridSizeX * curvedValue;
          break;
        case ArrowDirection.down:
          bx += gridSizeX * curvedValue;
          break;
        case ArrowDirection.left:
          bz += gridSizeZ * curvedValue;
          break;
        case ArrowDirection.right:
          bz -= gridSizeZ * curvedValue;
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
      ([4, 5, 6, 7], (0.0, 1.0, 0.0)),  // Top face
      ([0, 3, 2, 1], (0.0, -1.0, 0.0)), // Bottom face
      ([0, 1, 5, 4], (0.0, 0.0, -1.0)), // Back face
      ([2, 3, 7, 6], (0.0, 0.0, 1.0)),  // Front face
      ([0, 4, 7, 3], (-1.0, 0.0, 0.0)), // Left face
      ([1, 2, 6, 5], (1.0, 0.0, 0.0)),  // Right face
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
      // Each block shows arrow on ONE face type only:
      // - left/right arrows: TOP face only
      // - up/down arrows: SIDE faces only (front/back)
      bool shouldDrawArrow = false;
      if (i == 0 && (block.direction == ArrowDirection.left || block.direction == ArrowDirection.right)) {
        // Top face shows left/right arrows only
        shouldDrawArrow = true;
      } else if ((i == 2 || i == 3) && (block.direction == ArrowDirection.up || block.direction == ArrowDirection.down)) {
        // Front/Back faces show up/down arrows only
        shouldDrawArrow = true;
      }

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

    Offset tip, tail;

    if (faceIndex == 0) {
      // Top face [4,5,6,7]: 4=back-left, 5=back-right, 6=front-right, 7=front-left
      // mid01 = back edge, mid12 = right edge, mid23 = front edge, mid30 = left edge
      switch (direction) {
        case ArrowDirection.up:    // Move -X (towards back-left)
          tip = mid30;  // left edge
          tail = mid12; // right edge
          break;
        case ArrowDirection.down:  // Move +X (towards front-right)
          tip = mid12;  // right edge
          tail = mid30; // left edge
          break;
        case ArrowDirection.left:  // Move +Z (towards front)
          tip = mid23;  // front edge
          tail = mid01; // back edge
          break;
        case ArrowDirection.right: // Move -Z (towards back)
          tip = mid01;  // back edge
          tail = mid23; // front edge
          break;
      }
    } else if (faceIndex == 2 || faceIndex == 3) {
      // Front face [2,3,7,6] or Back face [0,1,5,4]: show up/down arrows
      // These faces are perpendicular to Z, arrows point in X direction

      // Front face [2,3,7,6]: mid12 connects (3,7) at X=bx (left), mid30 connects (6,2) at X=bx+1 (right)
      // Back face [0,1,5,4]: mid12 connects (1,5) at X=bx+1 (right), mid30 connects (4,0) at X=bx (left)
      Offset leftEdge, rightEdge;
      if (faceIndex == 3) {
        // Front face: mid12 is left, mid30 is right
        leftEdge = mid12;
        rightEdge = mid30;
      } else {
        // Back face: mid12 is right, mid30 is left
        leftEdge = mid30;
        rightEdge = mid12;
      }

      switch (direction) {
        case ArrowDirection.up:    // Move -X (towards left in 3D)
          tip = leftEdge;
          tail = rightEdge;
          break;
        case ArrowDirection.down:  // Move +X (towards right in 3D)
          tip = rightEdge;
          tail = leftEdge;
          break;
        default:
          return;
      }
    } else {
      // Left face [0,4,7,3] or Right face [1,2,6,5]: show left/right arrows
      // These faces are perpendicular to X, arrows point in Z direction

      // Left face [0,4,7,3]: back edge = mid01, front edge = mid23
      // Right face [1,2,6,5]: back edge = mid30, front edge = mid12
      Offset frontEdge, backEdge;
      if (faceIndex == 4) {
        // Left face
        frontEdge = mid23;
        backEdge = mid01;
      } else {
        // Right face
        frontEdge = mid12;
        backEdge = mid30;
      }

      switch (direction) {
        case ArrowDirection.left:  // Move +Z (towards front)
          tip = frontEdge;
          tail = backEdge;
          break;
        case ArrowDirection.right: // Move -Z (towards back)
          tip = backEdge;
          tail = frontEdge;
          break;
        default:
          return;
      }
    }

    // Scale arrow to fit inside face
    final arrowTip = Offset(
      center.dx + (tip.dx - center.dx) * 0.6,
      center.dy + (tip.dy - center.dy) * 0.6,
    );
    final arrowTail = Offset(
      center.dx + (tail.dx - center.dx) * 0.4,
      center.dy + (tail.dy - center.dy) * 0.4,
    );

    final arrowColor = isTappable
        ? Colors.black.withValues(alpha: 0.8 * (1.0 - animValue))
        : Colors.black.withValues(alpha: 0.5 * (1.0 - animValue));

    // Calculate arrow dimensions based on face size
    final faceSize = (p0 - p2).distance;
    final headSize = faceSize * 0.15;
    final bodyWidth = faceSize * 0.05;

    final arrowPath = _createArrowPath(arrowTail, arrowTip, headSize, bodyWidth);
    canvas.drawPath(arrowPath, Paint()..color = arrowColor..style = PaintingStyle.fill);
  }

  Path _createArrowPath(Offset tail, Offset tip, double headSize, double bodyWidth) {
    final dx = tip.dx - tail.dx;
    final dy = tip.dy - tail.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return Path();

    final nx = dx / len;
    final ny = dy / len;
    final px = -ny;
    final py = nx;

    final headBaseX = tip.dx - nx * headSize;
    final headBaseY = tip.dy - ny * headSize;

    final path = Path();
    path.moveTo(tail.dx + px * bodyWidth, tail.dy + py * bodyWidth);
    path.lineTo(headBaseX + px * bodyWidth, headBaseY + py * bodyWidth);
    path.lineTo(headBaseX + px * headSize * 0.5, headBaseY + py * headSize * 0.5);
    path.lineTo(tip.dx, tip.dy);
    path.lineTo(headBaseX - px * headSize * 0.5, headBaseY - py * headSize * 0.5);
    path.lineTo(headBaseX - px * bodyWidth, headBaseY - py * bodyWidth);
    path.lineTo(tail.dx - px * bodyWidth, tail.dy - py * bodyWidth);
    path.close();

    return path;
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
