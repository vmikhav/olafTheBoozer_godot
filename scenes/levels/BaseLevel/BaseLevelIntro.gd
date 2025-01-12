class_name BaseLevelIntro
extends Node2D

signal finished

var defs = LevelDefinitions

var splash_scene: PackedScene = preload("res://scenes/sprites/Splash/Splash.tscn")
var puff_scene: PackedScene = preload("res://scenes/sprites/Puff/Puff.tscn")

func play(init: bool = false):
	pass
