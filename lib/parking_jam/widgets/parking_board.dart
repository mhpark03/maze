import 'dart:math';
import 'package:flutter/material.dart';
import '../models/parking_models.dart';

class ParkingBoard extends StatefulWidget {
  final ParkingPuzzle puzzle;
  final Function(Car) onCarTap;
  final Function(Car) onCarExited;

  const ParkingBoard({
    super.key,
    required this.puzzle,
    required this.onCarTap,
    required this.onCarExited,
  });

  @override
  State<ParkingBoard> createState() => _ParkingBoardState();
}

class _ParkingBoardState extends State<ParkingBoard>
    with TickerProviderStateMixin {
  final Map<int, AnimationController> _exitControllers = {};
  final Map<int, Animation<Offset>> _exitAnimations = {};
  final Map<int, AnimationController> _shakeControllers = {};
  final Map<int, Animation<double>> _shakeAnimations = {};
  int? _highlightedBlockingCarId;

  @override
  void dispose() {
    for (var controller in _exitControllers.values) {
      controller.dispose();
    }
    for (var controller in _shakeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onCarTap(Car car) {
    if (_exitControllers.containsKey(car.id)) return;

    if (widget.puzzle.canCarExit(car)) {
      _startExitAnimation(car);
    } else {
      _startShakeAnimation(car);
    }
  }

  void _startExitAnimation(Car car) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    Offset endOffset;
    switch (car.facing) {
      case CarDirection.up:
        endOffset = Offset(0, -(car.row + car.length + 1).toDouble());
        break;
      case CarDirection.down:
        endOffset =
            Offset(0, (widget.puzzle.gridSize - car.row + 1).toDouble());
        break;
      case CarDirection.left:
        endOffset = Offset(-(car.col + car.length + 1).toDouble(), 0);
        break;
      case CarDirection.right:
        endOffset =
            Offset((widget.puzzle.gridSize - car.col + 1).toDouble(), 0);
        break;
    }

    final animation = Tween<Offset>(
      begin: Offset.zero,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInQuad,
    ));

    _exitControllers[car.id] = controller;
    _exitAnimations[car.id] = animation;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCarExited(car);
        _exitControllers.remove(car.id)?.dispose();
        _exitAnimations.remove(car.id);
        setState(() {});
      }
    });

    controller.forward();
    setState(() {});
    widget.onCarTap(car);
  }

  void _startShakeAnimation(Car car) {
    if (_shakeControllers.containsKey(car.id)) {
      _shakeControllers[car.id]?.reset();
      _shakeControllers[car.id]?.forward();
      return;
    }

    final blockingCar = widget.puzzle.getBlockingCar(car);
    if (blockingCar != null) {
      setState(() {
        _highlightedBlockingCarId = blockingCar.id;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _highlightedBlockingCarId = null;
          });
        }
      });
    }

    final controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    _shakeControllers[car.id] = controller;
    _shakeAnimations[car.id] = animation;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeControllers.remove(car.id)?.dispose();
        _shakeAnimations.remove(car.id);
        setState(() {});
      }
    });

    controller.forward();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 가장자리 차량이 짤리지 않도록 여백 추가
        const edgePadding = 16.0;
        final availableSize = min(constraints.maxWidth, constraints.maxHeight) - (edgePadding * 2);
        final boardSize = availableSize;
        final cellSize = boardSize / widget.puzzle.gridSize;

        return Center(
          child: Container(
            width: boardSize + (edgePadding * 2),
            height: boardSize + (edgePadding * 2),
            padding: const EdgeInsets.all(edgePadding),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildGrid(boardSize, cellSize),
                ...widget.puzzle.cars.map(
                  (car) => _buildCar(car, cellSize, boardSize),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(double boardSize, double cellSize) {
    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A5C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A4A6A), width: 2),
      ),
      child: CustomPaint(
        painter: _GridPainter(
          gridSize: widget.puzzle.gridSize,
          cellSize: cellSize,
        ),
      ),
    );
  }

  Widget _buildCar(Car car, double cellSize, double boardSize) {
    final isHorizontal = car.isHorizontal;
    final carWidth = isHorizontal ? cellSize * car.length : cellSize;
    final carHeight = isHorizontal ? cellSize : cellSize * car.length;

    double left = car.col * cellSize;
    double top = car.row * cellSize;

    final exitAnim = _exitAnimations[car.id];
    final shakeAnim = _shakeAnimations[car.id];
    final isHighlighted = _highlightedBlockingCarId == car.id;

    // 원본 이미지는 위(up)를 바라봄
    // quarterTurns: 시계방향 90도 회전 횟수
    int quarterTurns = 0;
    switch (car.facing) {
      case CarDirection.up:
        quarterTurns = 0; // 원본 그대로
        break;
      case CarDirection.right:
        quarterTurns = 1; // 90도 시계방향
        break;
      case CarDirection.down:
        quarterTurns = 2; // 180도
        break;
      case CarDirection.left:
        quarterTurns = 3; // 270도 (= -90도)
        break;
    }

    Widget carWidget = GestureDetector(
      onTap: () => _onCarTap(car),
      child: Container(
        width: carWidth,
        height: carHeight,
        padding: const EdgeInsets.all(2),
        child: Stack(
          children: [
            Positioned.fill(
              child: RotatedBox(
                quarterTurns: quarterTurns,
                child: Image.asset(
                  car.imagePath,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            if (isHighlighted)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    if (shakeAnim != null) {
      carWidget = AnimatedBuilder(
        animation: shakeAnim,
        builder: (context, child) {
          final offset = car.isHorizontal
              ? Offset(shakeAnim.value, 0)
              : Offset(0, shakeAnim.value);
          return Transform.translate(
            offset: offset,
            child: child,
          );
        },
        child: carWidget,
      );
    }

    if (exitAnim != null) {
      return AnimatedBuilder(
        animation: exitAnim,
        builder: (context, child) {
          final offset = exitAnim.value;
          return Positioned(
            left: left + offset.dx * cellSize,
            top: top + offset.dy * cellSize,
            child: Opacity(
              opacity: (1 - _exitControllers[car.id]!.value).clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: carWidget,
      );
    }

    return Positioned(
      left: left,
      top: top,
      child: carWidget,
    );
  }
}

class _GridPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;

  _GridPainter({required this.gridSize, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A4A6A)
      ..strokeWidth = 1;

    for (int i = 1; i < gridSize; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 1; i < gridSize; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
