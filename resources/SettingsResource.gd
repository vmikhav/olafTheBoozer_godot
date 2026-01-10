class_name SettingsResource
extends JsonResource

const _filename: String = "user://settings.json"

var sfx_volume: float = -6
var sfx_muted: bool = false
var burps_muted: bool = false
var voice_volume: float = -6
var voice_muted: bool = false
var music_volume: float = -6
var music_muted: bool = false
var touch_control: bool = false
var language: String = "en"
var dialogue_mode: int = 0
var uid: String = "1"
