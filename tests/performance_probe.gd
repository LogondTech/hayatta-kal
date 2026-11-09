extends SceneTree

const ENEMY_COUNT := 150
const QUERY_COUNT := 2500
const HIT_RADIUS := 0.35


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	for i in ENEMY_COUNT:
		var radius := 0.75 if i % 5 == 0 else 0.4
		var body := StaticBody3D.new()
		body.collision_layer = 8
		body.collision_mask = 0
		body.add_to_group(&"enemies")
		body.set_meta("radius", radius)
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = radius
		collision.shape = sphere
		body.add_child(collision)
		var angle := float(i) * TAU / float(ENEMY_COUNT)
		body.position = Vector3(cos(angle) * 22.0, 0.0, sin(angle) * 22.0)
		world.add_child(body)

	await process_frame
	await physics_frame
	var space := world.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var query_shape := SphereShape3D.new()
	query_shape.radius = HIT_RADIUS
	query.shape = query_shape
	query.collision_mask = 8
	query.collide_with_bodies = true
	query.collide_with_areas = false

	# Warm both paths to exclude most one-time engine setup.
	for i in 100:
		_probe_linear(i)
		_probe_physics(i, query, space)

	await physics_frame
	var linear_start := Time.get_ticks_usec()
	var linear_hits := 0
	for i in QUERY_COUNT:
		linear_hits += _probe_linear(i)
	var linear_usec := Time.get_ticks_usec() - linear_start

	await physics_frame
	var physics_start := Time.get_ticks_usec()
	var physics_hits := 0
	for i in QUERY_COUNT:
		physics_hits += _probe_physics(i, query, space)
	var physics_usec := Time.get_ticks_usec() - physics_start

	print("PROBE enemies=%d queries=%d" % [ENEMY_COUNT, QUERY_COUNT])
	print("LINEAR total_us=%d avg_us=%.3f hits=%d" % [linear_usec, float(linear_usec) / QUERY_COUNT, linear_hits])
	print("PHYSICS total_us=%d avg_us=%.3f hits=%d" % [physics_usec, float(physics_usec) / QUERY_COUNT, physics_hits])
	print("RATIO physics_over_linear=%.3f" % (float(physics_usec) / maxf(float(linear_usec), 1.0)))
	world.free()
	quit(0)


func _probe_linear(index: int) -> int:
	var point := _probe_point(index)
	var hits := 0
	for target in get_nodes_in_group(&"enemies"):
		var enemy := target as Node3D
		var radius: float = float(enemy.get_meta("radius"))
		var dx := enemy.global_position.x - point.x
		var dz := enemy.global_position.z - point.z
		if dx * dx + dz * dz < (radius + HIT_RADIUS) * (radius + HIT_RADIUS):
			hits += 1
	return hits


func _probe_physics(index: int, query: PhysicsShapeQueryParameters3D, space: PhysicsDirectSpaceState3D) -> int:
	var point := _probe_point(index)
	query.transform = Transform3D(Basis.IDENTITY, point)
	var hits := 0
	for result in space.intersect_shape(query, 32):
		var enemy := result.get("collider") as Node3D
		var radius: float = float(enemy.get_meta("radius"))
		var dx := enemy.global_position.x - point.x
		var dz := enemy.global_position.z - point.z
		if dx * dx + dz * dz < (radius + HIT_RADIUS) * (radius + HIT_RADIUS):
			hits += 1
	return hits


func _probe_point(index: int) -> Vector3:
	var angle := float(index % 360) * TAU / 360.0
	var radius := 15.0 + float((index * 13) % 100) * 0.1
	return Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
