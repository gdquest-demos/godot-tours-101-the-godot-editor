@tool
extends VBoxContainer

@export_multiline var quote_text: String = "":
	set = set_quote_text
@export var quote_author: String = "":
	set = set_quote_author
@export var quote_author_icon: Texture2D = null:
	set = set_quote_author_icon
@export var quote_author_title: String = "":
	set = set_quote_author_title

@onready var _quote_content_label: RichTextLabel = %QuoteContent
@onready var _tail_icon: TextureRect = %Tail

@onready var _author_name_label: Label = %AuthorName
@onready var _author_title_label: Label = %AuthorTitle
@onready var _author_icon: TextureRect = %AuthorIcon
@onready var _author_icon_panel: Control = %AuthorIconPanel


func _notification(what: int) -> void:
	# NOTE: When instantiated from a scene, these nodes can be resolved immediately,
	# without the need to wait for ready. But the engine does not provide nice hooks
	# for that.
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		_quote_content_label = %QuoteContent
		_tail_icon = %Tail

		_author_name_label = %AuthorName
		_author_title_label = %AuthorTitle
		_author_icon = %AuthorIcon
		_author_icon_panel = %AuthorIconPanel


func _ready() -> void:
	_update_quote()
	_update_author()

	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	var editor_scale := EditorInterface.get_editor_scale()
	_tail_icon.custom_minimum_size *= editor_scale
	_author_icon_panel.custom_minimum_size *= editor_scale


# Properties.

func set_quote_text(value: String) -> void:
	if quote_text == value:
		return

	quote_text = value
	_update_quote()


func set_quote_author(value: String) -> void:
	if quote_author == value:
		return

	quote_author = value
	_update_author()


func set_quote_author_icon(value: Texture2D) -> void:
	if quote_author_icon == value:
		return

	quote_author_icon = value
	_update_author()


func set_quote_author_title(value: String) -> void:
	if quote_author_title == value:
		return

	quote_author_title = value
	_update_author()


# Helpers.

func _update_quote() -> void:
	_quote_content_label.text = quote_text


func _update_author() -> void:
	_author_name_label.text = quote_author
	_author_title_label.text = quote_author_title
	_author_icon.texture = quote_author_icon
