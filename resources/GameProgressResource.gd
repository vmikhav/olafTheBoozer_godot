class_name GameProgressResource
extends JsonResource

const _filename: String = "user://progress.json"
const _highscore_stub = {score = 0, time = 1000*60*60*24, steps = 200000}

var levels: Dictionary = {}
