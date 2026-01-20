import 'dart:math';
import 'package:flutter/material.dart';
import 'models/parking_models.dart';

class ParkingGenerator {
  static final Random _random = Random();

  static final List<(VehicleColor, Color)> _vehicleColors = [
    (VehicleColor.red, Colors.red),
    (VehicleColor.blue, Colors.blue),
    (VehicleColor.green, Colors.green),
    (VehicleColor.yellow, Colors.yellow.shade700),
    (VehicleColor.purple, Colors.purple),
    (VehicleColor.orange, Colors.orange),
    (VehicleColor.cyan, Colors.cyan),
    (VehicleColor.pink, Colors.pink),
  ];

  static Future<ParkingPuzzle> generate(ParkingDifficulty difficulty) async {
    final gridSize = difficulty.gridSize;
    final (minCars, maxCars) = difficulty.carCountRange;
    final targetCarCount = minCars + _random.nextInt(maxCars - minCars + 1);

    return _generatePuzzle(gridSize, targetCarCount);
  }

  static Future<ParkingPuzzle> _generatePuzzle(
    int gridSize,
    int targetCarCount,
  ) async {
    List<Car> cars = [];
    Set<(int, int)> occupiedCells = {};
    int carId = 0;
    int attempts = 0;
    int consecutiveFailures = 0;
    final maxAttempts = targetCarCount * 100; // 목표 차량 수에 비례
    const maxConsecutiveFailures = 500; // 연속 실패 제한

    List<(VehicleColor, Color)> shuffledColors = List.from(_vehicleColors)
      ..shuffle(_random);

    while (cars.length < targetCarCount &&
           attempts < maxAttempts &&
           consecutiveFailures < maxConsecutiveFailures) {
      attempts++;
      final colorPair = shuffledColors[carId % shuffledColors.length];
      final car = _tryPlaceCar(
        gridSize,
        occupiedCells,
        carId,
        colorPair.$1,
        colorPair.$2,
        cars,
      );

      if (car != null) {
        cars.add(car);
        occupiedCells.addAll(car.occupiedCells);
        carId++;
        consecutiveFailures = 0; // 성공하면 리셋
      } else {
        consecutiveFailures++;
      }

      if (attempts % 100 == 0) {
        await Future.delayed(Duration.zero);
      }
    }

    cars = _ensureSolvable(cars, gridSize);

    return ParkingPuzzle(gridSize: gridSize, cars: cars);
  }

  static Car? _tryPlaceCar(
    int gridSize,
    Set<(int, int)> occupiedCells,
    int carId,
    VehicleColor vehicleColor,
    Color color,
    List<Car> existingCars,
  ) {
    final vehicleType = _random.nextDouble() < 0.6
        ? VehicleType.sedan
        : (_random.nextBool() ? VehicleType.bus : VehicleType.truck);
    final length = vehicleType.length;

    final direction = CarDirection.values[_random.nextInt(4)];
    final isHorizontal =
        direction == CarDirection.left || direction == CarDirection.right;

    int maxRow = isHorizontal ? gridSize : gridSize - length;
    int maxCol = isHorizontal ? gridSize - length : gridSize;

    if (maxRow <= 0 || maxCol <= 0) return null;

    int row = _random.nextInt(maxRow);
    int col = _random.nextInt(maxCol);

    CarDirection facing;
    if (isHorizontal) {
      facing = _random.nextBool() ? CarDirection.left : CarDirection.right;
    } else {
      facing = _random.nextBool() ? CarDirection.up : CarDirection.down;
    }

    final tempCar = Car(
      id: carId,
      row: row,
      col: col,
      length: length,
      facing: facing,
      color: color,
      vehicleType: vehicleType,
      vehicleColor: vehicleColor,
    );

    for (var cell in tempCar.occupiedCells) {
      if (cell.$1 < 0 ||
          cell.$1 >= gridSize ||
          cell.$2 < 0 ||
          cell.$2 >= gridSize) {
        return null;
      }
      if (occupiedCells.contains(cell)) {
        return null;
      }
    }

    return tempCar;
  }

  static List<Car> _ensureSolvable(List<Car> cars, int gridSize) {
    if (cars.isEmpty) return cars;

    List<Car> solvableCars = List.from(cars);
    List<int> exitOrder = [];
    Set<int> processed = {};

    while (exitOrder.length < solvableCars.length) {
      bool foundExitable = false;

      for (var car in solvableCars) {
        if (processed.contains(car.id)) continue;

        final tempPuzzle = ParkingPuzzle(
          gridSize: gridSize,
          cars: solvableCars.where((c) => !processed.contains(c.id)).toList(),
        );

        if (tempPuzzle.canCarExit(car)) {
          exitOrder.add(car.id);
          processed.add(car.id);
          foundExitable = true;
          break;
        }
      }

      if (!foundExitable) {
        _adjustForSolvability(solvableCars, processed, gridSize);
        if (solvableCars.isEmpty) break;
      }
    }

    return solvableCars;
  }

  static void _adjustForSolvability(
    List<Car> cars,
    Set<int> processed,
    int gridSize,
  ) {
    final unprocessed = cars.where((c) => !processed.contains(c.id)).toList();
    if (unprocessed.isEmpty) return;

    final carToAdjust = unprocessed[_random.nextInt(unprocessed.length)];
    final idx = cars.indexWhere((c) => c.id == carToAdjust.id);

    CarDirection newFacing;
    int newRow = carToAdjust.row;
    int newCol = carToAdjust.col;

    if (carToAdjust.isHorizontal) {
      if (carToAdjust.row == 0) {
        newFacing = CarDirection.up;
      } else if (carToAdjust.row == gridSize - 1) {
        newFacing = CarDirection.down;
      } else {
        newFacing = _random.nextBool() ? CarDirection.up : CarDirection.down;
      }
    } else {
      if (carToAdjust.col == 0) {
        newFacing = CarDirection.left;
      } else if (carToAdjust.col == gridSize - 1) {
        newFacing = CarDirection.right;
      } else {
        newFacing =
            _random.nextBool() ? CarDirection.left : CarDirection.right;
      }
    }

    switch (newFacing) {
      case CarDirection.up:
        newRow = 0;
        break;
      case CarDirection.down:
        newRow = gridSize - carToAdjust.length;
        break;
      case CarDirection.left:
        newCol = 0;
        break;
      case CarDirection.right:
        newCol = gridSize - carToAdjust.length;
        break;
    }

    final adjustedCar = Car(
      id: carToAdjust.id,
      row: newRow,
      col: newCol,
      length: carToAdjust.length,
      facing: newFacing,
      color: carToAdjust.color,
      vehicleType: carToAdjust.vehicleType,
      vehicleColor: carToAdjust.vehicleColor,
    );

    bool hasCollision = false;
    for (var cell in adjustedCar.occupiedCells) {
      for (var otherCar in cars) {
        if (otherCar.id != adjustedCar.id) {
          if (otherCar.occupiedCells.contains(cell)) {
            hasCollision = true;
            break;
          }
        }
      }
      if (hasCollision) break;
    }

    if (!hasCollision) {
      cars[idx] = adjustedCar;
    } else {
      cars.removeAt(idx);
    }
  }
}
