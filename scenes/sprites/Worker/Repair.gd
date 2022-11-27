extends WorkerState

func enter(_msg := {}) -> void:
	worker.sprite.play('repair')
	await worker.sprite.animation_finished
	state_machine.transition_to('Idle', {})
