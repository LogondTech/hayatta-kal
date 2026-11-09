extends Node

var _failed := false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_saved_best_time_display()
	_test_enemy_cluster_capacity()
	await _test_overlapping_hit_flashes()
	await _test_main_scene_startup()
	await _cleanup_audio()
	await get_tree().process_frame
	if _failed:
		print("FAIL: regression smoke tests")
		get_tree().quit(1)
	else:
		print("PASS: regression smoke tests")
		get_tree().quit(0)


func _test_saved_best_time_display() -> void:
	var hud := Hud.new()
	add_child(hud)
	await get_tree().process_frame
	hud.set_time(30.0, 100.0)
	var best_label := hud.get("_best") as Label
	_check(best_label.text == "En iyi  01:40", "HUD must show saved best, not current run time")
	hud.set_time(120.0, 100.0)
	_check(best_label.text == "Rekor adayı  02:00", "HUD must mark an unsaved in-progress record as a candidate")
	hud.set_time(100.0, 100.0)
	_check(best_label.text == "En iyi  01:40", "HUD must show the persisted best when the run only ties it")
	hud.free()


func _test_enemy_cluster_capacity() -> void:
	_check(WaveDirector.bounded_cluster_size(10, 5, 149) == 1, "One free slot must spawn at most one enemy")
	_check(WaveDirector.bounded_cluster_size(10, 5, 150) == 0, "Full enemy capacity must spawn none")
	_check(WaveDirector.bounded_cluster_size(2, 5, 140) == 2, "Remaining wave budget must cap cluster size")


func _test_overlapping_hit_flashes() -> void:
	var visual := CharacterVisual.new()
	add_child(visual)
	await get_tree().process_frame
	var mesh := MeshInstance3D.new()
	visual.add_child(mesh)
	visual.meshes.append(mesh)
	visual.flash(0.2)
	await get_tree().create_timer(0.1).timeout
	visual.flash(0.2)
	await get_tree().create_timer(0.11).timeout
	_check(mesh.material_overlay != null, "Earlier flash timer must not clear a later flash")
	await get_tree().create_timer(0.12).timeout
	_check(mesh.material_overlay == null, "Latest flash must clear when its duration ends")
	visual.free()


func _test_main_scene_startup() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	_check(main_scene != null, "Main gameplay scene must load")
	if not main_scene:
		return
	var main := main_scene.instantiate()
	add_child(main)
	await get_tree().create_timer(0.2).timeout
	_check(main.get_node("Player") != null, "Main scene must create the player")
	_check(main.get_node("Enemies").get_child_count() > 0, "Wave director must begin spawning enemies")
	main.get_node("WaveDirector").set_physics_process(false)
	await _test_projectile_collision(main, Enemy.Kind.FAST, Vector3(0, 0, -3), 14.0)
	await _test_projectile_collision(main, Enemy.Kind.BRUTE, Vector3(4, 0, -3), 75.0)
	main.get_node("WaveDirector").set_physics_process(true)
	for _frame in 900:
		await get_tree().physics_frame
	_check(get_tree().get_node_count_in_group(&"enemies") <= 150, "Long run must respect the 150-enemy cap")
	main.free()
	await get_tree().process_frame
	await get_tree().process_frame


func _test_projectile_collision(main: Node, kind: Enemy.Kind, position: Vector3, expected_hp: float) -> void:
	var enemy := Enemy.new()
	enemy.setup(kind, 1.0, 1.0, 1.0)
	enemy.player = main.get_node("Player") as Player
	enemy.gem_parent = main.get_node("Gems")
	main.get_node("Enemies").add_child(enemy)
	enemy.global_position = position
	await get_tree().physics_frame
	enemy.set_physics_process(false)
	var projectile := Projectile.new()
	projectile.dir = Vector3(0, 0, -1)
	projectile.damage = 10.0
	main.get_node("Projectiles").add_child(projectile)
	projectile.global_position = Vector3(position.x, 1.1, position.z + 1.5)
	await get_tree().create_timer(0.12).timeout
	_check(enemy.hp < expected_hp, "Projectile broadphase query must hit fast and brute enemies")


func _cleanup_audio() -> void:
	var audio := get_node("/root/Audio")
	if audio._music_tween:
		audio._music_tween.kill()
	audio._music.stop()
	audio._music.stream = null
	for voice in audio._players:
		voice.stop()
		voice.stream = null
	audio._streams.clear()
	audio._last_played.clear()
	await get_tree().create_timer(0.5).timeout


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failed = true
		push_error(message)
