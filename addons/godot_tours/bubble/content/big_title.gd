@tool
extends RichTextLabel

@export var title_text: String = "":
	set = set_title_text
@export var subtitle_text: String = "":
	set = set_subtitle_text


func _ready() -> void:
	_update_text()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_update_text()


# Properties.

func set_title_text(value: String) -> void:
	if title_text == value:
		return

	title_text = value
	_update_text()


func set_subtitle_text(value: String) -> void:
	if subtitle_text == value:
		return

	subtitle_text = value
	_update_text()


func _update_text() -> void:
	var subtitle_color := get_theme_color("subtitle_color")
	var subtitle_size := get_theme_font_size("subtitle_font_size")

	var label_text := ""
	label_text += "[center]%s[/center]" % [ title_text ]
	if not subtitle_text.is_empty():
		label_text += "\n" + "[center][color=%s][font_size=%d]%s[/font_size][/color][/center]" % [ subtitle_color.to_html(false), subtitle_size, subtitle_text ]

	text = label_text
