@tool
class_name Road extends Node

@export var distance: float
@export var inner_path: Path3D:
	set(value):
		inner_path = value
		if inner_path:
			inner_path.curve_changed.connect(_on_curve_changed)
@export var outer_path: Path3D:
	set(value):
		outer_path = value
		if outer_path:
			outer_path.curve_changed.connect(_on_curve_changed)
@export var tiles: MultiMeshInstance3D
@export_tool_button("Build", "Callable") var build_action: Callable = build

func build() -> void:
	var outer_points: = uniq_snapped_points(outer_path.curve)
	var inner_points: = uniq_snapped_points(inner_path.curve)

	var index_offset: int = 0
	var outer_row: Array = Array()
	var inner_row: Array = Array()
	var points: PackedVector3Array = PackedVector3Array()

	for outer_point: Vector3 in outer_points:
		if outer_row.is_empty() or outer_row[0].x == outer_point.x:
			outer_row.append(outer_point)
		else:
			var x = outer_row[0].x

			# find inner row
			for i in range(index_offset, inner_points.size()):
				var inner_point = inner_points[i]
				if inner_point.x == x:
					inner_row.append(inner_point)
				else:
					index_offset = i
					break

			var segments = []
			if inner_row.is_empty():
				segments.append([outer_row[0], outer_row[-1]])
			else:
				segments.append([outer_row[0], inner_row[0]])
				segments.append([inner_row[-1], outer_row[-1]])

			# generate points in segment
			for segment in segments:
				for i in round((segment[1].z - segment[0].z) / distance):
					points.append(Vector3(segment[0].x, 0.0, segment[0].z + (i * distance)))

			# next row
			outer_row.clear()
			inner_row.clear()
			outer_row.append(outer_point)

	# build multimesh
	var multimesh: MultiMesh = tiles.multimesh
	var basis: Basis = Basis.IDENTITY
	multimesh.instance_count = points.size()

	for i in points.size():
		var point = points[i]
		var transform: Transform3D = Transform3D(basis, point)
		multimesh.set_instance_transform(i, transform)


func _on_curve_changed():
	build()

func uniq_snapped_points(curve: Curve3D) -> PackedVector3Array:
	var points: PackedVector3Array
	for point in curve.get_baked_points():
		point = _snap(point)
		if not points.has(point):
			points.append(point)
	points.sort()

	return points


func _snap(vector: Vector3) -> Vector3:
	return Vector3(
		round(vector.x / distance) * distance,
		0.0,
		round(vector.z / distance) * distance,
	)
