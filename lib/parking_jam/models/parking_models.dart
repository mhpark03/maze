import 'package:flutter/material.dart';

enum CarDirection { up, down, left, right }

enum VehicleType { sedan, bus, truck }

enum VehicleColor { red, blue, green, yellow, purple, orange, cyan, pink }

extension VehicleTypeExtension on VehicleType {
  int get length {
    switch (this) {
      case VehicleType.sedan:
        return 2;
      case VehicleType.bus:
      case VehicleType.truck:
        return 3;
    }
  }

  String get name {
    switch (this) {
      case VehicleType.sedan:
        return 'sedan';
      case VehicleType.bus:
        return 'bus';
      case VehicleType.truck:
        return 'truck';
    }
  }
}

extension VehicleColorExtension on VehicleColor {
  String get name {
    switch (this) {
      case VehicleColor.red:
        return 'red';
      case VehicleColor.blue:
        return 'blue';
      case VehicleColor.green:
        return 'green';
      case VehicleColor.yellow:
        return 'yellow';
      case VehicleColor.purple:
        return 'purple';
      case VehicleColor.orange:
        return 'orange';
      case VehicleColor.cyan:
        return 'cyan';
      case VehicleColor.pink:
        return 'pink';
    }
  }
}

class Car {
  final int id;
  final int row;
  final int col;
  final int length;
  final CarDirection facing;
  final Color color;
  final VehicleType vehicleType;
  final VehicleColor vehicleColor;
  bool isExiting = false;

  Car({
    required this.id,
    required this.row,
    required this.col,
    required this.length,
    required this.facing,
    required this.color,
    required this.vehicleType,
    required this.vehicleColor,
  });

  String get imagePath =>
      'assets/images/cars/${vehicleType.name}_${vehicleColor.name}.png';

  Car copyWith({
    int? id,
    int? row,
    int? col,
    int? length,
    CarDirection? facing,
    Color? color,
    VehicleType? vehicleType,
    VehicleColor? vehicleColor,
  }) {
    return Car(
      id: id ?? this.id,
      row: row ?? this.row,
      col: col ?? this.col,
      length: length ?? this.length,
      facing: facing ?? this.facing,
      color: color ?? this.color,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleColor: vehicleColor ?? this.vehicleColor,
    );
  }

  bool get isHorizontal =>
      facing == CarDirection.left || facing == CarDirection.right;

  bool get isVertical =>
      facing == CarDirection.up || facing == CarDirection.down;

  List<(int, int)> get occupiedCells {
    List<(int, int)> cells = [];
    if (isHorizontal) {
      for (int i = 0; i < length; i++) {
        cells.add((row, col + i));
      }
    } else {
      for (int i = 0; i < length; i++) {
        cells.add((row + i, col));
      }
    }
    return cells;
  }

  List<(int, int)> getExitPath(int gridSize) {
    List<(int, int)> path = [];
    switch (facing) {
      case CarDirection.up:
        for (int r = row - 1; r >= -length; r--) {
          path.add((r, col));
        }
        break;
      case CarDirection.down:
        int startRow = row + length;
        for (int r = startRow; r <= gridSize + length; r++) {
          path.add((r, col));
        }
        break;
      case CarDirection.left:
        for (int c = col - 1; c >= -length; c--) {
          path.add((row, c));
        }
        break;
      case CarDirection.right:
        int startCol = col + length;
        for (int c = startCol; c <= gridSize + length; c++) {
          path.add((row, c));
        }
        break;
    }
    return path;
  }

  (int, int) get frontCell {
    switch (facing) {
      case CarDirection.up:
        return (row - 1, col);
      case CarDirection.down:
        return (row + length, col);
      case CarDirection.left:
        return (row, col - 1);
      case CarDirection.right:
        return (row, col + length);
    }
  }
}

class ParkingPuzzle {
  final int gridSize;
  final List<Car> cars;
  int clearedCount = 0;

  ParkingPuzzle({
    required this.gridSize,
    required this.cars,
  });

  ParkingPuzzle copyWith({
    int? gridSize,
    List<Car>? cars,
  }) {
    return ParkingPuzzle(
      gridSize: gridSize ?? this.gridSize,
      cars: cars ?? this.cars.map((c) => c.copyWith()).toList(),
    );
  }

  Set<(int, int)> get allOccupiedCells {
    Set<(int, int)> cells = {};
    for (var car in cars) {
      cells.addAll(car.occupiedCells);
    }
    return cells;
  }

  bool canCarExit(Car car) {
    return !isPathBlocked(car);
  }

  bool isPathBlocked(Car car) {
    final occupiedCells = allOccupiedCells;
    final carCells = car.occupiedCells.toSet();

    switch (car.facing) {
      case CarDirection.up:
        for (int r = car.row - 1; r >= 0; r--) {
          final cell = (r, car.col);
          if (occupiedCells.contains(cell) && !carCells.contains(cell)) {
            return true;
          }
        }
        break;
      case CarDirection.down:
        for (int r = car.row + car.length; r < gridSize; r++) {
          final cell = (r, car.col);
          if (occupiedCells.contains(cell) && !carCells.contains(cell)) {
            return true;
          }
        }
        break;
      case CarDirection.left:
        for (int c = car.col - 1; c >= 0; c--) {
          final cell = (car.row, c);
          if (occupiedCells.contains(cell) && !carCells.contains(cell)) {
            return true;
          }
        }
        break;
      case CarDirection.right:
        for (int c = car.col + car.length; c < gridSize; c++) {
          final cell = (car.row, c);
          if (occupiedCells.contains(cell) && !carCells.contains(cell)) {
            return true;
          }
        }
        break;
    }
    return false;
  }

  Car? getBlockingCar(Car car) {
    switch (car.facing) {
      case CarDirection.up:
        for (int r = car.row - 1; r >= 0; r--) {
          for (var otherCar in cars) {
            if (otherCar.id != car.id) {
              for (var cell in otherCar.occupiedCells) {
                if (cell.$1 == r && cell.$2 == car.col) {
                  return otherCar;
                }
              }
            }
          }
        }
        break;
      case CarDirection.down:
        for (int r = car.row + car.length; r < gridSize; r++) {
          for (var otherCar in cars) {
            if (otherCar.id != car.id) {
              for (var cell in otherCar.occupiedCells) {
                if (cell.$1 == r && cell.$2 == car.col) {
                  return otherCar;
                }
              }
            }
          }
        }
        break;
      case CarDirection.left:
        for (int c = car.col - 1; c >= 0; c--) {
          for (var otherCar in cars) {
            if (otherCar.id != car.id) {
              for (var cell in otherCar.occupiedCells) {
                if (cell.$1 == car.row && cell.$2 == c) {
                  return otherCar;
                }
              }
            }
          }
        }
        break;
      case CarDirection.right:
        for (int c = car.col + car.length; c < gridSize; c++) {
          for (var otherCar in cars) {
            if (otherCar.id != car.id) {
              for (var cell in otherCar.occupiedCells) {
                if (cell.$1 == car.row && cell.$2 == c) {
                  return otherCar;
                }
              }
            }
          }
        }
        break;
    }
    return null;
  }

  void removeCar(int carId) {
    cars.removeWhere((car) => car.id == carId);
    clearedCount++;
  }

  bool get isComplete => cars.isEmpty;
}

enum ParkingDifficulty { easy, medium, hard }

extension ParkingDifficultyExtension on ParkingDifficulty {
  int get gridSize {
    switch (this) {
      case ParkingDifficulty.easy:
        return 10;
      case ParkingDifficulty.medium:
        return 15;
      case ParkingDifficulty.hard:
        return 20;
    }
  }

  (int, int) get carCountRange {
    switch (this) {
      case ParkingDifficulty.easy:
        return (25, 30);
      case ParkingDifficulty.medium:
        return (50, 60);
      case ParkingDifficulty.hard:
        return (85, 100);
    }
  }
}
