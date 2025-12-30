class_name player extends CharacterBody2D


@export var acceleration:=150
@export var max_speed:=290
@export var friction:=200
@export var air_friction:=60
@export var up_gravity:=250
@export var down_gavity:=500
@export var jump_force:=180
@export var unjump_force:=25
@export var landing_acceleration:=2250.0
var target_tilt:=0.0
@onready var anchor: Node2D = $anchor
@onready var sprite_2d: Sprite2D = $anchor/Sprite2D
var air_jump:=true
@export var air_jump_speed_reduction:=1500
var coyote_time:=0.0
@export var coyote_time_amount:=0.15
var finish_x:=-1
signal level_finished()
@onready var camera_2d: Camera2D = $Camera2D
@export var min_zoom_amount:=0.9
@export var max_zoom_amount:=1.5
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var air_jump_sound: AudioStreamPlayer2D = $AirJumpSound
@onready var slidesound: AudioStreamPlayer2D = $slidesound
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound


func _ready() -> void:
	camera_2d.zoom=Vector2(max_zoom_amount,max_zoom_amount)


func _physics_process(delta: float) -> void:
	coyote_time+=delta
	
	check_for_finish_line.call_deferred()
	
	if is_on_floor() or coyote_time<=coyote_time_amount: 
		gpu_particles_2d.emitting=true
		air_jump=true
		target_tilt=0
		if velocity.x <= max_speed:
			velocity.x=move_toward(velocity.x,max_speed,acceleration*delta)
		else :
			velocity.x=move_toward(velocity.x, max_speed, friction*delta)
		
		if Input.is_action_just_pressed("jump"):
			velocity.y=-jump_force
			jump_sound.play()
	else:
		gpu_particles_2d.emitting=false
		target_tilt=clamp(velocity.y/4,-30,30)
		
		velocity.x=move_toward(velocity.x, 0, air_friction*delta)
		
		if Input.is_action_just_pressed("jump")and air_jump:
			velocity.y=-jump_force
			velocity.x-=air_jump_speed_reduction*delta
			air_jump=false
			air_jump_sound.play()
			var tween=create_tween()
			tween.tween_property(sprite_2d,"rotation_degrees",0,0.4).from(360+sprite_2d.rotation_degrees)
		
		if Input.is_action_just_released("jump"):
			velocity.y=unjump_force
		
		if velocity.y >0:
			velocity.y+=down_gavity*delta
		else:
			velocity.y+=up_gravity*delta
	
	var previous_velocity=velocity
	
	var was_on_floor=is_on_floor()
	
	move_and_slide()
	if velocity.length() > 0 and is_on_floor():
		if !$SlideSound.playing:
			$SlideSound.play()
	else:
		$SlideSound.stop()
	
	var just_laft_ledge=was_on_floor and not is_on_floor()and velocity.y>=0
	
	if just_laft_ledge:
		coyote_time=0
	
	if velocity.y==0 and previous_velocity.y>5:
		anchor.scale=Vector2(1.2,0.8)
		velocity.x+=landing_acceleration*delta
	
	
	anchor.scale=anchor.scale.lerp(Vector2.ONE,0.05)
	sprite_2d.rotation_degrees=lerp(sprite_2d.rotation_degrees,target_tilt,0.2)
	
	var y_offset_target:float=clamp(ray_cast_2d.get_collision_point().y-global_position.y,-16,100)
	camera_2d.offset.y=lerp(camera_2d.offset.y,y_offset_target,0.01)
	
	var x_offset_target:float=clamp(velocity.x,64,100)
	camera_2d.offset.x=lerp(camera_2d.offset.x,x_offset_target,0.01)
	
	
	var zoom_target_amount:float=clamp(max_zoom_amount-(velocity.x/150),min_zoom_amount,max_zoom_amount)
	var zoom_target:=Vector2(zoom_target_amount,zoom_target_amount)
	
	camera_2d.zoom=camera_2d.zoom.lerp(zoom_target,0.02)
	

func check_for_finish_line()-> void:
	if global_position.x >finish_x and finish_x!=-1:
		level_finished.emit()
		process_mode=Node.PROCESS_MODE_DISABLED
		gpu_particles_2d.emitting=false
