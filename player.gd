extends CharacterBody3D

const WALK_SPEED = 5.0
const CROUCH_SPEED = 2.5
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Track the current speed based on whether we are walking or crouching
var current_speed = WALK_SPEED

# Grab references to our nodes so we can change their heights
@onready var head = $Head
@onready var collision_shape = $CollisionShape3D

func _ready():
	# Hide and capture the mouse cursor when the game starts
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Helps the player stay grounded while walking over small stair-step height changes.
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(50.0)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Crouch and Speed
	if Input.is_action_pressed("crouch"):
		current_speed = CROUCH_SPEED
		# Smoothly lower the head and shrink the collision capsule
		head.position.y = lerp(head.position.y, 0.0, 10.0 * delta)
		collision_shape.shape.height = lerp(collision_shape.shape.height, 1.0, 10.0 * delta)
	else:
		current_speed = WALK_SPEED
		# Smoothly raise the head and restore the collision capsule
		head.position.y = lerp(head.position.y, 0.6, 10.0 * delta)
		collision_shape.shape.height = lerp(collision_shape.shape.height, 2.0, 10.0 * delta)

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

func _input(event):
	# Read physical mouse movements to rotate the Head and Camera
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		$Head.rotate_x(-event.relative.y * 0.005)
		# Clamp the up/down rotation so you can't flip your neck backwards
		$Head.rotation.x = clamp($Head.rotation.x, -PI/2, PI/2)
