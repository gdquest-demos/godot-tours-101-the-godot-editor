@tool
extends VBoxContainer

@export var course_cover: Texture2D = null:
	set = set_course_cover
@export var course_cta: String = "":
	set = set_course_cta
@export var course_link: String = "":
	set = set_course_link

@onready var _cover_texture: TextureRect = %CourseCover
@onready var _action_button: LinkButton = %CourseButton


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_cover_texture = %CourseCover
		_action_button = %CourseButton


func _ready() -> void:
	_update_cover()
	_update_link()


# Properties.

func set_course_cover(value: Texture2D) -> void:
	if course_cover == value:
		return

	course_cover = value
	_update_cover()


func set_course_cta(value: String) -> void:
	if course_cta == value:
		return

	course_cta = value
	_update_link()


func set_course_link(value: String) -> void:
	if course_link == value:
		return

	course_link = value
	_update_link()


# Helpers.

func _update_cover() -> void:
	_cover_texture.texture = course_cover


func _update_link() -> void:
	_action_button.text = course_cta
	_action_button.uri = course_link
	_action_button._update_text_buffer()
