extends ByNodeScript

## If set on [member Player.holding_item], the default "press attack to throw" path is skipped
## (e.g. [code]grabbing_ungrab_on_attack_release[/code] in [res://engine/node_modifiers/grabbable_modifier/grabbable_modifier.gd]).
const GRAB_SKIP_ATTACK_INPUT_THROW: StringName = &"grabbing_skip_attack_input_throw"

var player: Player
var suit: PlayerSuit

func _ready() -> void:
	player = node as Player
	suit = node.suit
	if !player.died.is_connected(_drop_on_death):
		player.died.connect(_drop_on_death)


func _physics_process(delta: float) -> void:
	if !player || player.warp > Player.Warp.NONE || player.is_climbing: return
	
	var item = player.holding_item
	var is_holding = player.is_holding
	
	if !player.attacked:
		return
	
	if player.has_stuck: return
	
	if is_holding && is_instance_valid(item):
		if item.get_meta(GRAB_SKIP_ATTACK_INPUT_THROW, false):
			return
		if item.has_signal(&"grabbing_got_thrown"):
			item.emit_signal(&"grabbing_got_thrown", false)
		player.threw.emit()
	elif !is_holding:
		var space_state := player.get_world_2d().direct_space_state
		
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = player.collision_shape.shape
		query.collision_mask = player.collision_mask
		
		# Side grabbing
		query.transform = player.collision_shape.global_transform.translated(Vector2(player.direction, 0))
		var side_results := space_state.intersect_shape(query)
		
		for result: Dictionary in side_results:
			if !result.get("collider"):
				continue
			var collider: Node2D = result.collider
			if !is_instance_valid(collider) || collider.is_queued_for_deletion():
				continue
			
			var _has_grabbed: bool = _check_group_and_emit(collider,
				&"#side_grabbable",
				&"grabbing_got_side_grabbed"
			)
			if _has_grabbed:
				player.emit_signal(&"grabbed", true)
				return
		
		# Top grabbing
		query.transform = player.collision_shape.global_transform.translated(Vector2.DOWN)
		var top_results := space_state.intersect_shape(query)
		
		for result: Dictionary in top_results:
			if !result.get("collider"):
				continue
			var collider: Node2D = result.collider
			if !is_instance_valid(collider) || collider.is_queued_for_deletion():
				continue
			
			var _has_grabbed: bool = _check_group_and_emit(collider,
				&"#top_grabbable",
				&"grabbing_got_top_grabbed"
			)
			if !_has_grabbed:
				continue
			player.emit_signal(&"grabbed", false)
			return
		
		#for i in player.get_slide_collision_count():
			#var collision: KinematicCollision2D = player.get_slide_collision(i)
		##for i in 2:
			##var collision: KinematicCollision2D
			##if i == 0:
				##collision = player.move_and_collide(Vector2(player.direction, 0).rotated(player.global_rotation), true, 0.08, true)
			##else:
				##collision = player.move_and_collide(Vector2.DOWN.rotated(player.global_rotation), true, 0.08, true)
			##if !collision: continue
			#var collider: Node2D = collision.get_collider() as Node2D
			#var normal = collision.get_normal().rotated(player.global_rotation)
			#if !is_instance_valid(collider):
				#continue
			#var _has_grabbed: bool
			#var _was_on_floor: bool
			#if is_zero_approx(normal.x):
				#_has_grabbed = _check_group_and_emit(collider,
					#&"#top_grabbable",
					#&"grabbing_got_top_grabbed"
				#)
				#_was_on_floor = true
			#if !_has_grabbed:
				#_has_grabbed = _check_group_and_emit(collider,
					#&"#side_grabbable",
					#&"grabbing_got_side_grabbed"
				#)
				#_was_on_floor = false
			#if !_has_grabbed:
				#continue
			#player.emit_signal(&"grabbed", !_was_on_floor)
			#return


func _check_group_and_emit(collider: Node2D, group: StringName, signal_name: StringName) -> bool:
	if !collider.is_in_group(group):
		return false
	if collider.has_signal(signal_name):
		collider.emit_signal(signal_name)
		return true
	else:
		var colparent = collider.get_parent()
		if colparent.has_signal(signal_name):
			colparent.emit_signal(signal_name)
			return true
		else:
			var colparparent = colparent.get_parent()
			if colparparent.has_signal(signal_name):
				colparparent.emit_signal(signal_name)
				return true
	return false


func _drop_on_death() -> void:
	var item = player.holding_item
	if is_instance_valid(item):
		item.emit_signal(&"grabbing_got_thrown", true)
		player.threw.emit()


func _accept_grabbable(_node: Node2D) -> void:
	print('Accepting grab')
	print(_node)
	pass
