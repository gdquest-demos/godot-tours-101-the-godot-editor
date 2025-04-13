@tool
extends EditorTranslationParserPlugin

const PATTERNS := [
	r"""gtr\(\s*['"]+(.*?(?:\\")?)['"]+\s*(?:,\s*['"]+(.*?)['"]+\s*)?\)""",
	r"""gtr_n\(\s*['"]+(.*?(?:\\")?)['"]+\s*,\s*['"]+(.*?(?:\\")?)['"]+\s*,\s*(?:\d+)\s*(?:,\s*['"]+(.*?)['"]+\s*)?\)""",
]

var regex := RegEx.new()


func _parse_file(path: String) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	var source_code: String = load(path).source_code
	for pattern in PATTERNS:
		regex.compile(pattern)
		for regex_match in regex.search_all(source_code):
			var singular := _replace_quotes(regex_match.strings[1])
			var context := regex_match.strings[2]
			var plural := ""
			if regex_match.get_group_count() > 2:
				plural = _replace_quotes(regex_match.strings[2])
				context = regex_match.strings[3]
			result.push_back(PackedStringArray([singular, context, plural]))
	return result


func _get_recognized_extensions() -> PackedStringArray:
	return ["gd"]


func _replace_quotes(s: String) -> String:
	return s.replace(r"\'", "'").replace(r'\"', '"')
