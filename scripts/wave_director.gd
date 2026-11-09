class_name WaveDirector
extends Node
## Spawns enemies in waves from the arena edges. Each wave is bigger,
## tougher and faster than the last; there is no final wave.

signal wave_started(n: int)

const WAVE_TIME := 20.0
const MAX_ALIVE := 150
const SPAWN_EDGE := 27.0
const SPAWN_WINDOW := 16.0

var player: Player
var enemy_parent: Node
var gem_parent: Node
var wave := 0

var _wave_t := 0.0
var _to_spawn := 0
var _spawn_t := 0.0
var _interval := 1.0
var _side := 0


static func bounded_cluster_size(remaining: int, requested: int, alive: int) -> int:
	return maxi(0, mini(mini(remaining, requested), MAX_ALIVE - alive))


static func wave_spawn_budget(wave_number: int) -> int:
	var w := maxi(wave_number, 1)
	return 4 + w * 4 + int(w * w * 0.15)


static func hp_multiplier(wave_number: int) -> float:
	var w := float(maxi(wave_number - 1, 0))
	return 1.0 + 0.12 * w + 0.004 * w * w


static func speed_multiplier(wave_number: int) -> float:
	var w := float(maxi(wave_number - 1, 0))
	return 1.0 + minf(0.025 * w, 0.45)


static func damage_multiplier(wave_number: int) -> float:
	var w := float(maxi(wave_number - 1, 0))
	return minf(1.0 + 0.05 * w, 2.0)


static func brute_chance(wave_number: int) -> float:
	return 0.0 if wave_number < 2 else minf(0.06 + 0.035 * wave_number, 0.4)


static func can_advance_wave(remaining: int, alive: int, elapsed: float) -> bool:
	return remaining == 0 and (elapsed >= WAVE_TIME or (alive == 0 and elapsed > 3.0))


func start() -> void:
	_next_wave()


func _next_wave() -> void:
	wave += 1
	_wave_t = 0.0
	_to_spawn = wave_spawn_budget(wave)
	_interval = SPAWN_WINDOW / float(maxi(_to_spawn, 1))
	_spawn_t = 0.0
	_side = randi() % 4
	wave_started.emit(wave)


func _physics_process(delta: float) -> void:
	if wave == 0 or player.dead:
		return
	_wave_t += delta
	_spawn_t -= delta
	var alive := get_tree().get_node_count_in_group(&"enemies")
	if _to_spawn > 0 and _spawn_t <= 0.0 and alive < MAX_ALIVE:
		var cluster := bounded_cluster_size(_to_spawn, randi_range(2, 5), alive)
		_spawn_cluster(cluster)
		_to_spawn -= cluster
		_spawn_t = _interval * cluster
	if can_advance_wave(_to_spawn, alive, _wave_t):
		_next_wave()


func _spawn_cluster(n: int) -> void:
	# Most clusters come from this wave's main side, the rest from anywhere.
	var side := _side if randf() < 0.6 else randi() % 4
	var along := randf_range(-SPAWN_EDGE + 4, SPAWN_EDGE - 4)
	var base: Vector3
	match side:
		0: base = Vector3(along, 0, -SPAWN_EDGE)
		1: base = Vector3(SPAWN_EDGE, 0, along)
		2: base = Vector3(along, 0, SPAWN_EDGE)
		_: base = Vector3(-SPAWN_EDGE, 0, along)
	var hp_mult := hp_multiplier(wave)
	var speed_mult := speed_multiplier(wave)
	var dmg_mult := damage_multiplier(wave)
	var brute_probability := brute_chance(wave)
	for i in n:
		var e := Enemy.new()
		var k := Enemy.Kind.BRUTE if randf() < brute_probability else Enemy.Kind.FAST
		e.setup(k, hp_mult, speed_mult, dmg_mult)
		e.player = player
		e.gem_parent = gem_parent
		enemy_parent.add_child(e)
		e.global_position = base + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
