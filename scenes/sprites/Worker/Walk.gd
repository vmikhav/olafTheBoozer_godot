extends WorkerState

func enter(_msg := {}) -> void:
	if worker.sprite.animation != 'walk':
		worker.sprite.play('walk')
