@tool
extends EditorPlugin

var exportador: EditorExportPlugin

func _enter_tree() -> void:
	exportador = Exportador.new()
	add_export_plugin(exportador)

func _exit_tree() -> void:
	remove_export_plugin(exportador)

class Exportador extends EditorExportPlugin:
	func _get_name() -> String:
		return "SketchBladePlayUpdate"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["res://addons/play_update/bin/play-update.aar"])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.google.android.play:app-update:2.1.0"])
