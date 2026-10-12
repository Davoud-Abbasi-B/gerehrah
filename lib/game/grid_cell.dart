class GridCell {
  const GridCell(this.row, this.column);

  factory GridCell.fromJson(Map<String, dynamic> json) {
    final row = json['row'];
    final column = json['column'];
    if (row is! int || column is! int) {
      throw const FormatException(
        'Grid cells require integer "row" and "column" values.',
      );
    }
    return GridCell(row, column);
  }

  final int row;
  final int column;

  bool isAdjacentTo(GridCell other) {
    return (row - other.row).abs() + (column - other.column).abs() == 1;
  }

  @override
  bool operator ==(Object other) {
    return other is GridCell && row == other.row && column == other.column;
  }

  @override
  int get hashCode => Object.hash(row, column);
}
