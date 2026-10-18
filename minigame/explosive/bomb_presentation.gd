extends Node3D

@export var warning_seconds: float = 4.0
@export var blast_seconds: float = 0.5
var _deadline: float = 0.0
var _warning: bool = false
var _blast_tween: Tween = null
@onready var pulse: Timer = $WarningPulse
@onready var warning_audio: AudioStreamPlayer3D = $WarningAudio
@onready var blast_audio: AudioStreamPlayer3D = $BlastAudio
@onready var blast: MeshInstance3D = $Blast


func _ready() -> void:
	pulse.timeout.connect(_beep)
	blast.top_level = true
	blast.visible = false


func present(holder: Node3D, deadline: float, pass_ready: bool) -> void:
	for child_name: String in ["Mat", "Sang", "Dem", "VongTam"]:
		get_node(child_name).visible = holder != null
	if holder == null:
		_warning = false
		pulse.stop()
		return
	global_position = holder.global_position + Vector3.UP * 2.3
	_deadline = deadline
	_draw_fuse(pass_ready)


func _draw_fuse(pass_ready: bool) -> void:
	var remaining: float = maxf(_deadline - Fusion.get_network_time(), 0.0)
	var urgency: float = 1.0 - clampf(remaining / warning_seconds, 0.0, 1.0)
	var phase: float = Fusion.get_network_time() * TAU * lerpf(2.0, 9.0, urgency)
	$Mat.scale = Vector3.ONE * (1.0 + urgency * 0.35 + sin(phase) * 0.06)
	$Sang.light_energy = lerpf(3.0, 9.0, urgency)
	$Dem.text = "%.1f" % remaining
	$Dem.modulate = Color(1.0, 0.85, 0.5).lerp(Color(1.0, 0.25, 0.15), urgency)
	$VongTam.visible = pass_ready
	_warning = remaining > 0.0 and remaining <= warning_seconds
	if _warning and pulse.is_stopped():
		pulse.start(0.1)


func _beep() -> void:
	if not _warning:
		return
	var remaining: float = maxf(_deadline - Fusion.get_network_time(), 0.0)
	warning_audio.pitch_scale = lerpf(1.8, 0.9, clampf(remaining / warning_seconds, 0.0, 1.0))
	warning_audio.play()
	pulse.start(lerpf(0.08, 0.65, clampf(remaining / warning_seconds, 0.0, 1.0)))


func detonate(center: Vector3, radius: float) -> void:
	if _blast_tween != null:
		_blast_tween.kill()
	blast.global_position = center
	blast.scale = Vector3.ONE * 0.05
	blast.visible = true
	blast_audio.play()
	_blast_tween = create_tween()
	_blast_tween.tween_property(blast, "scale", Vector3.ONE * radius, blast_seconds)
	_blast_tween.tween_callback(func() -> void: blast.visible = false)
