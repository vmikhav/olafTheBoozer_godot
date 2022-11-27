extends WorkerState

func enter(_msg := {}) -> void:
	worker.sprite.play('idle')
