extends WorkerState


func enter(_msg := {}) -> void:
	worker.sprite.play('hit')
	await worker.sprite.animation_finished
	state_machine.transition_to('Idle', {})
