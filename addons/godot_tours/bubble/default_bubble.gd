## Text bubble used to display instructions to the user.
@tool
extends "bubble.gd"

const Utils := preload("../utils.gd")

const CodeEditPackedScene := preload("code_edit.tscn")
const TextureRectPackedScene := preload("texture_rect.tscn")
const VideoStreamPlayerPackedScene := preload("video_stream_player.tscn")
const RichTextLabelPackedScene := preload("rich_text_label/rich_text_label.tscn")

const CLASS_IMG := r"[img=%dx%d]res://addons/godot_tours/bubble/assets/icons/$1.svg[/img] [b]$1[/b]"
const COMMIT_MESSAGE := """It seems you're not done with this step! [color=#FF8A00]You may get stuck later on in the Tour if you skip ahead without completing all the tasks.[/color] You can try going back one step before skipping.

If you decide to skip the step, note down the tasks and do them before you start the following steps."""
const LOG_MESSAGE := """[color=#FF8A00][b]GDTour[/b] is an experimental Edtech that evolves with the Godot engine and requires ongoing testing. It's not uncommon to encounter bugs.[/color]
Please be patient and try the following:

[indent]1. Check that you're using the recommended version of Godot. For this tour it’s Godot 4.3.[/indent]

[indent]2. Go back one step in the Tour.[/indent]

[indent]3. Note down the tasks then try skipping the step and doing them before you start the following steps.[/indent]

[indent]4. Let GDQuest know by writing to [color=#FF8A00]support@gdquest.com[/color].[/indent]

[ul]  Describe the problem
  Download and attach the Godot file [color=#FFD500]tour.log[/color].
  If possible, attach a screenshot.[/ul]

[indent]5. There are video fall backs available for these tours. You can watch them and follow along in your editor.[/indent]
"""


## Separation between paragraphs of text and elements in the main content in pixels.
@export var paragraph_separation := 12:
	set(new_value):
		paragraph_separation = new_value
		if main_v_box_container == null:
			await ready
		main_v_box_container.add_theme_constant_override("separation", paragraph_separation * EditorInterface.get_editor_scale())

var img_size := 24 * EditorInterface.get_editor_scale()
var regex_class := RegEx.new()

@onready var background_texture_rect: TextureRect = %BackgroundTextureRect
@onready var title_label: Label = %TitleLabel
@onready var header_rich_text_label: RichTextLabel = %HeaderRichTextLabel
@onready var footer_rich_text_label: RichTextLabel = %FooterRichTextLabel
@onready var footer_spacer: Control = %FooterSpacer
@onready var main_v_box_container: VBoxContainer = %MainVBoxContainer
@onready var tasks_margin_container: MarginContainer = %TasksMarginContainer
@onready var tasks_v_box_container: VBoxContainer = %TasksVBoxContainer

@onready var buttons_panel_container: PanelContainer = %ButtonsPanelContainer
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton
@onready var finish_button: Button = %FinishButton

@onready var view_content: VBoxContainer = %ViewContent
@onready var view_close: VBoxContainer = %ViewClose
@onready var button_close: Button = %ButtonClose
@onready var close_texture_rect: TextureRect = %CloseTextureRect
@onready var button_close_no: Button = %ButtonCloseNo
@onready var button_close_yes: Button = %ButtonCloseYes

@onready var label_close_tour: Label = %LabelCloseTour
@onready var label_progress_lost: Label = %LabelProgressLost

@onready var bottom_panel_container: PanelContainer = %BottomPanelContainer
@onready var step_count_label: Label = %StepCountLabel
@onready var info_v_box_container: VBoxContainer = %InfoVBoxContainer
@onready var info_texture_rect: TextureRect = %InfoTextureRect
@onready var info_rich_text_label: RichTextLabel = %InfoRichTextLabel

@onready var bottom_h_box_container: HBoxContainer = %BottomHBoxContainer
@onready var help_button: Button = %HelpButton
@onready var help_rich_text_label: RichTextLabel = %HelpRichTextLabel
@onready var skip_button: Button = %SkipButton
@onready var skip_rich_text_label: RichTextLabel = %SkipRichTextLabel

@onready var commit_h_box_container: HBoxContainer = %CommitHBoxContainer
@onready var skip_step_button: Button = %SkipStepButton
@onready var try_again_button: Button = %TryAgainButton

@onready var logs_h_box_container: HBoxContainer = %LogsHBoxContainer
@onready var close_info_button: Button = %CloseInfoButton
@onready var find_log_button: Button = %FindLogButton


func setup(interface: EditorInterfaceAccess, log: Log, translation_service: TranslationService, step_count: int) -> void:
	super(interface, log, translation_service, step_count)
	var classes := Array(ClassDB.get_class_list())
	classes.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	regex_class.compile(r"\[b\](%s)\[\/b\]" % "|".join(classes))


func _ready() -> void:
	super()
	if not Engine.is_editor_hint() or EditorInterface.get_edited_scene_root() == self:
		return

	update_step_count_display(0)
	Utils.update_locale(translation_service, {
		back_button: {text = "BACK"},
		next_button: {text = "NEXT"},
		finish_button: {text = "END TOUR AND CONTINUE LEARNING"},
		button_close_no: {text = "NO"},
		button_close_yes: {text = "YES"},
		label_close_tour: {text = "Close the tour?"},
		label_progress_lost: {text = "Your progress will be lost."},
		help_rich_text_label: {text = "[u]Help[u]"},
		skip_rich_text_label: {text = "[right][u]Skip[/u][/right]"},
		skip_step_button: {text = "SKIP STEP"},
		try_again_button: {text = "TRY AGAIN"},
		info_rich_text_label: {text = COMMIT_MESSAGE},
	})

	# Clear tasks etc. in case we have some for testing in the scene.
	clear_elements_and_tasks()

	back_button.pressed.connect(back_button_pressed.emit)
	next_button.pressed.connect(_on_next_button_pressed)
	skip_button.pressed.connect(_on_next_button_pressed)
	help_button.pressed.connect(_on_help_button_pressed)
	skip_step_button.pressed.connect(_on_skip_step_button_pressed)
	try_again_button.pressed.connect(_close_info)
	close_info_button.pressed.connect(_close_info)
	find_log_button.pressed.connect(_on_find_log_button_pressed)
	button_close.pressed.connect(func() -> void:
		view_content.hide()
		view_close.show()
	)
	button_close_no.pressed.connect(func() -> void:
		view_content.show()
		view_close.hide()
	)
	button_close_yes.pressed.connect(close_requested.emit)
	finish_button.pressed.connect(finish_requested.emit)
	info_rich_text_label.finished.connect(_on_info_rich_text_label_finished)

	for node in [header_rich_text_label, main_v_box_container, tasks_margin_container, footer_rich_text_label, footer_spacer]:
		node.visible = false

	paragraph_separation *= editor_scale
	button_close.custom_minimum_size *= editor_scale
	info_texture_rect.custom_minimum_size.x *= editor_scale


func _on_next_button_pressed() -> void:
	if next_button.theme_type_variation == "GrayButton":
		Utils.update_locale(translation_service, {info_rich_text_label: {text = COMMIT_MESSAGE}})
		buttons_panel_container.visible = false
		bottom_h_box_container.visible = false

		info_v_box_container.visible = true
		commit_h_box_container.visible = true
		logs_h_box_container.visible = false

		if info_v_box_container.visible:
			was_moved = false
			move_and_anchor(interface.base_control, At.CENTER, margin, _get_offset_vector())
			info_rich_text_label.finished.emit()
	else:
		next_button_pressed.emit()


func _on_help_button_pressed() -> void:
	Utils.update_locale(translation_service, {info_rich_text_label: {text = LOG_MESSAGE}})
	buttons_panel_container.visible = false
	bottom_h_box_container.visible = false

	info_v_box_container.visible = true
	commit_h_box_container.visible = false
	logs_h_box_container.visible = true

	if info_v_box_container.visible:
		was_moved = false
		move_and_anchor(interface.base_control, At.CENTER, margin, _get_offset_vector())
		info_rich_text_label.finished.emit()


func _on_skip_step_button_pressed() -> void:
	_close_info()
	next_button_pressed.emit()


func _on_find_log_button_pressed() -> void:
	log.clean_up()
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Log.LOG_FILE_PATH))


func _on_info_rich_text_label_finished() -> void:
	while not info_rich_text_label.is_finished():
		pass

	var margin := 0.0 if editor_scale < 1 else 300.0 / editor_scale
	info_rich_text_label.custom_minimum_size.y = info_rich_text_label.get_content_height()
	if panel_container.size.y + info_rich_text_label.custom_minimum_size.y > interface.base_control.size.y - margin:
		info_rich_text_label.custom_minimum_size.y = interface.base_control.size.y - panel_container.size.y - margin


func _close_info() -> void:
	buttons_panel_container.visible = true
	bottom_h_box_container.visible = true
	info_v_box_container.visible = false


func _get_offset_vector() -> Vector2:
	return (panel_container.global_position.x + (panel_container.size.x - interface.base_control.size.x) / 2.0) * Vector2.RIGHT


func on_tour_step_changed(index: int) -> void:
	super(index)
	back_button.visible = true
	next_button.visible = true
	finish_button.visible = false
	bottom_panel_container.visible = false
	close_texture_rect.modulate = Color.WHITE
	if index == 0:
		back_button.visible = false
		next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER | Control.SIZE_EXPAND
		next_button.theme_type_variation = "BoxButton"
	elif index == step_count - 1:
		next_button.visible = false
		finish_button.visible = true
	else:
		back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		next_button.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
		next_button.theme_type_variation = "NextButton" if check_tasks() else "GrayButton"
		close_texture_rect.modulate = Color("567099")
		bottom_panel_container.visible = true
	update_step_count_display(index)


func clear() -> void:
	# next_button.visible = true
	set_header("")
	set_footer("")
	set_background(null)
	clear_elements_and_tasks()


func clear_elements_and_tasks() -> void:
	for control in [main_v_box_container, tasks_v_box_container]:
		for node in control.get_children():
			node.queue_free()

	for control in [main_v_box_container, tasks_margin_container]:
		control.visible = false


func add_element(element: Control, data: Variant) -> void:
	main_v_box_container.visible = true
	main_v_box_container.add_child(element)
	if element is RichTextLabel or element is CodeEdit:
		element.text = data
	elif element is TextureRect:
		element.texture = data.texture
		if "max_height" in data:
			element.max_height = data.max_height
	elif element is VideoStreamPlayer:
		element.stream = data
		element.finished.connect(element.play)
		element.play()
		var texture: Texture2D = element.get_video_texture()
		element.custom_minimum_size.x = main_v_box_container.size.x
		element.custom_minimum_size.y = element.custom_minimum_size.x * texture.get_height() / texture.get_width()


func set_title(title_text: String) -> void:
	title_label.text = title_text


func add_text(text: Array[String]) -> void:
	for line in text:
		line = regex_class.sub(line, CLASS_IMG % [img_size, img_size], true)
		add_element(RichTextLabelPackedScene.instantiate(), line)


func add_code(code: Array[String]) -> void:
	for snippet in code:
		add_element(CodeEditPackedScene.instantiate(), snippet)


func add_texture(texture: Texture2D, max_height := 0.0) -> void:
	if texture == null:
		return
	var texture_rect := TextureRectPackedScene.instantiate()
	var data := {"texture": texture}
	if max_height > 0.0:
		data["max_height"] = max_height
	add_element(texture_rect, data)


func add_video(stream: VideoStream) -> void:
	if stream == null or not stream is VideoStream:
		return
	add_element(VideoStreamPlayerPackedScene.instantiate(), stream)


func add_task(description: String, repeat: int, repeat_callable: Callable, error_predicate: Callable) -> void:
	tasks_margin_container.visible = true
	var task := TaskPackedScene.instantiate()
	tasks_v_box_container.add_child(task)
	task.status_changed.connect(check_tasks)
	task.setup(description, repeat, repeat_callable, error_predicate)
	check_tasks()


func set_header(text: String) -> void:
	header_rich_text_label.text = text
	header_rich_text_label.visible = not text.is_empty()


func set_footer(text: String) -> void:
	footer_rich_text_label.text = text
	footer_rich_text_label.visible = not text.is_empty()
	footer_spacer.visible = footer_rich_text_label.visible


func set_background(texture: Texture2D) -> void:
	background_texture_rect.texture = texture
	background_texture_rect.visible = texture != null


func check_tasks() -> bool:
	var tasks := tasks_v_box_container.get_children().filter(func(task: Task) -> bool: return not task.is_queued_for_deletion())
	var are_tasks_done := tasks.all(func(task: Task) -> bool: return task.is_done())
	next_button.theme_type_variation = "GrayButton"
	if are_tasks_done:
		next_button.theme_type_variation = "NextButton"
		if not tasks.is_empty():
			avatar.do_wink()

	if are_tasks_done:
		_close_info()
	return are_tasks_done


func update_step_count_display(current_step_index: int) -> void:
	step_count_label.text = "%s / %s" % [current_step_index, step_count - 2]
	step_count_label.visible = current_step_index != 0 and current_step_index != step_count - 1


func _add_debug_shortcuts() -> void:
	next_button.shortcut = load("res://addons/godot_tours/bubble/shortcut_debug_button_next.tres")
	back_button.shortcut = load("res://addons/godot_tours/bubble/shortcut_debug_button_back.tres")
	button_close_yes.shortcut = load("res://addons/godot_tours/bubble/shortcut_debug_button_close.tres")


## [b]Virtual[/b] method to change the text of the next button.
func set_finish_button_text(text: String) -> void:
	finish_button.text = text
