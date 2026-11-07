class_name ProjectileSpellData
extends AbilityData
## Magia que dispara um projétil na direção do mouse.

@export var damage: int = 14
@export var speed: float = 240.0
## Distância máxima antes de sumir (px).
@export var max_distance: float = 220.0
@export var knockback: float = 120.0
## Tempo "conjurando" antes do disparo (s).
@export var cast_time: float = 0.12
@export var projectile_color: Color = Color(0.6, 0.5, 1.0)
