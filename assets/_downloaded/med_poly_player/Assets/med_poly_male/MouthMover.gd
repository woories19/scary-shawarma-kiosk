extends AudioStreamPlayer3D

var spectrum
export (NodePath) var path_to_skeleton
onready var mouth_rig:Skeleton = get_node(path_to_skeleton)
export var blip = 2
export var tlip = 1
export var target_hz = 3000.0
export var sensitivity = 0.004
export var speed = 0.2
export var audio_bus = 0
export var max_angle = 0.1
export var closed_angle = -0.2
onready var top_lip = mouth_rig.get_bone_pose(tlip).rotated(Vector3(1,0,0),0.15)
onready var bottom_lip = mouth_rig.get_bone_pose(blip).rotated(Vector3(1,0,0),closed_angle)

var movement_modifier = 0.5
func _ready():
	mouth_rig.set_bone_pose(blip,bottom_lip)
	AudioServer.add_bus()
	audio_bus=AudioServer.bus_count-1
	var bus_name = "mouth_rig"+str(audio_bus)
	AudioServer.set_bus_name(audio_bus,bus_name)
	AudioServer.set_bus_send(audio_bus,"Voices")
	AudioServer.add_bus_effect(audio_bus,AudioEffectSpectrumAnalyzer.new())
	bus=bus_name
	spectrum = AudioServer.get_bus_effect_instance(audio_bus,0)

func _exit_tree():
	if audio_bus > 0:
		AudioServer.remove_bus(audio_bus)

var waiter = 0.0

func get_lip(lip):
	var rig:Skeleton = mouth_rig
	for bi in range(0,rig.get_bone_count()-1):
		var bone = rig.get_bone_name(bi)
		if bone == lip:
			return bi

var wait_til = 0.15

var last_ang = 0.0
func _process(delta):
	wait_til = 0.1
	
	waiter+=delta
	var cpose = mouth_rig.get_bone_pose(blip)
	if waiter >= wait_til:
		waiter=0
		if playing:
			var magnitude: float = spectrum.get_magnitude_for_frequency_range(0.0, target_hz).length()
			#print(magnitude)
			if magnitude > sensitivity:
				mouth_rig.set_bone_pose(blip,bottom_lip.interpolate_with(bottom_lip.rotated(Vector3(1,0,0),0.35),clamp(magnitude*70,closed_angle,max_angle)))
				return
	if cpose.basis != bottom_lip.basis:
		mouth_rig.set_bone_pose(blip,cpose.interpolate_with(bottom_lip,speed))

