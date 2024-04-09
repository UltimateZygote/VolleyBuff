extends CharacterBody2D

@export var player_num = 1
@onready var state_machine = $AnimationTree["parameters/playback"]
@export var dont_move = false
@export var stop_all_movement = false

const SPEED = 150
const slide_speed = 200
const slide_deceleration = 5
const COMBO_TIMEOUT = 0.2 # Timeout between key presses
const MAX_COMBO_CHAIN = 2 # Maximum key presses in a combo

var last_key_delta = 0    # Time since last keypress
var key_combo = []        # Current combo

var player_keys = []

func _ready():
	if player_num == 1:
		player_keys = [65, 68, 87, 83] # a, d, w, s / slide, slide, block, receive
	else:
		player_keys = [4194319, 4194321, 4194320, 4194322] # left, right, up, down / slide, slide, block, receive
	dont_move = false

func _physics_process(delta):
	last_key_delta += delta
	var input = Input.get_vector("left" + str(player_num), "right" + str(player_num), "up"  + str(player_num), "down"  + str(player_num))
	
	if stop_all_movement:
		velocity = Vector2(0, 0)
		
	elif not dont_move:
		velocity = input * SPEED
		
		if velocity.x != 0:
			transform.x.x = sign(velocity.x)
	
	
	deal_with_states(delta)
	#print(dont_move)
	
	move_and_slide()

func deal_with_states(delta):
	$Label.set_text(state_machine.get_current_node())
	
	if state_machine.get_current_node() == "run" and velocity.length() == 0: # start idling
		state_machine.travel("idle")
	
	if state_machine.get_current_node() == "idle" and velocity.length() != 0:
		print("running")
		state_machine.travel("run")
		
	if state_machine.get_current_node() in ["run", "idle"] and Input.is_action_just_pressed("smash" + str(player_num)):
		smash()
	
	if state_machine.get_current_node() == "slide":
		velocity.x = lerp(velocity.x, 0.0, slide_deceleration * delta)
	

func _input(event):
	if event is InputEventKey and event.pressed and !event.echo:
		print(event.keycode)
	
	if event is InputEventKey and event.pressed and !event.echo and event.keycode in player_keys: # If distinct key press down
		if event.keycode in player_keys:
			$doubletap.start()
			dont_move = true
			#pass
		
		if last_key_delta > COMBO_TIMEOUT:                   # Reset combo if stale
			key_combo = []
		
		key_combo.append(event.keycode)                     # Otherwise add it to combo
		if key_combo.size() > MAX_COMBO_CHAIN:               # Prune if necessary
			key_combo.pop_front()
											# Log the combo (could pass to combo evaluator)
		last_key_delta = 0
		
		if key_combo in [[player_keys[0], player_keys[0]], [player_keys[1], player_keys[1]]]: # slide
			slide()
		
		if key_combo == [player_keys[2], player_keys[2]]: # block
			block()
		
		if key_combo == [player_keys[3], player_keys[3]]: # receive
			recieve()


func _on_doubletap_timeout():
	if not state_machine.get_current_node() in ["smash", "reception", "block", "slide"]:
		dont_move = false

func slide():
	var current_state = state_machine.get_current_node()
	
	print("slide")
	state_machine.travel("slide")
	
	await get_tree().create_timer(0.05).timeout
	
	if not current_state == "slide":
		velocity.y = 0
		if key_combo == [player_keys[0], player_keys[0]]: #left
			velocity.x = -slide_speed
			transform.x.x = -1
		if key_combo == [player_keys[1], player_keys[1]]: #right
			velocity.x = slide_speed
			transform.x.x = 1

func block():
	state_machine.travel("block")
	
	await get_tree().create_timer(0.05).timeout
	
	transform.x.x = (player_num - 1) * -2 + 1

func recieve():
	state_machine.travel("reception")
	
	await get_tree().create_timer(0.05).timeout
	
	transform.x.x = (player_num - 1) * -2 + 1

func smash():
	state_machine.travel("smash")
	
	await get_tree().create_timer(0.05).timeout
	
	transform.x.x = (player_num - 1) * -2 + 1
