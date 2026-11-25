@tool
class_name WaveData
extends Resource

@export var angle: float:
    set(value):
        angle = value
        emit_changed()
@export var amplitude: float:
    set(value):
        amplitude = value
        emit_changed()
@export var wavelength: float:
   set(value):
        wavelength = value
        emit_changed()
@export var speed: float:
   set(value):
        speed = value
        emit_changed()
@export var steepness: float:
   set(value):
        steepness = value
        emit_changed()
