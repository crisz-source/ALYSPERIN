extends Node
## Autoload WorldText: deixa NÍTIDOS os textos do mundo 3D (Label3D: números de
## dano, nome de efeitos, avisos, placas, nome do portal...).
##
## Por quê: o 3D é desenhado em 1/3 da resolução (visual pixelado escolhido pelo
## proprietário) e um Label3D sairia borrado junto. Aqui cada Label3D continua
## existindo (a lógica e os testes leem dele), mas fica invisível no 3D; uma cópia
## é desenhada na camada 2D, que é renderizada na resolução cheia da tela.
## Mesmo ponto na tela, mesmo tamanho (fixed_size), cor, transparência e contorno.

## Camada 2D: acima do mundo e do HUD, abaixo dos menus (inventário, morte...).
const LAYER: int = 3
## Menor tamanho de letra (em pixels da base 640x360) para continuar legível.
const MIN_FONT: int = 6
## Camada de desenho 3D dos Label3D originais: a câmera não a enxerga (só a cópia 2D aparece).
## (Transparência não basta: o contorno da letra ainda era desenhado.)
const HIDDEN_RENDER_LAYER: int = 20

var _layer: CanvasLayer
var _labels: Dictionary = {}   # Label3D -> Label


func _ready() -> void:
	# Atualiza por último no quadro: depois que câmera e textos já se moveram
	# (senão a cópia ficaria um quadro atrasada e "nadaria" ao girar a câmera).
	process_priority = 1000
	_layer = CanvasLayer.new()
	_layer.name = "WorldTextLayer"
	_layer.layer = LAYER
	add_child(_layer)
	get_tree().node_added.connect(_on_node_added)


## Cópia 2D de um Label3D (null se ainda não registrado). Usado por testes.
func overlay_for(label3d: Label3D) -> Label:
	return _labels.get(label3d)


func _on_node_added(node: Node) -> void:
	var l3 := node as Label3D
	if l3 == null or _labels.has(l3):
		return
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	_layer.add_child(label)
	_labels[l3] = label
	# Esconde só o desenho 3D (visible/text/modulate continuam valendo).
	l3.layers = 1 << (HIDDEN_RENDER_LAYER - 1)
	l3.tree_exiting.connect(_forget.bind(l3), CONNECT_ONE_SHOT)


func _forget(l3: Label3D) -> void:
	var label: Label = _labels.get(l3)
	if label:
		label.queue_free()
	_labels.erase(l3)


func _process(_delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam and cam.get_cull_mask_value(HIDDEN_RENDER_LAYER):
		cam.set_cull_mask_value(HIDDEN_RENDER_LAYER, false)
	for l3: Label3D in _labels.keys():
		var label: Label = _labels[l3]
		if not is_instance_valid(l3):
			continue
		var pos: Vector3 = l3.global_position
		if cam == null or not l3.is_visible_in_tree() or l3.text.is_empty() or cam.is_position_behind(pos):
			label.visible = false
			continue
		label.visible = true
		label.text = l3.text
		var size: int = maxi(roundi(screen_font_size(l3, cam)), MIN_FONT)
		label.add_theme_font_size_override("font_size", size)
		label.add_theme_color_override("font_color", l3.modulate)
		if l3.outline_size > 0:
			var outline: Color = l3.outline_modulate
			outline.a = minf(outline.a, l3.modulate.a)
			label.add_theme_color_override("font_outline_color", outline)
			label.add_theme_constant_override("outline_size", maxi(roundi(l3.outline_size * size / float(maxi(l3.font_size, 1))), 1))
		# Tamanho medido direto na fonte: o tamanho automático do Label só se
		# atualiza no quadro seguinte e o centro tremeria ao mudar a letra.
		var font: Font = label.get_theme_font("font")
		var box: Vector2 = font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
		label.size = box
		# O Label não fica menor que o próprio mínimo (espaçamento de linha):
		# centraliza pelo tamanho que ele realmente ficou.
		label.position = cam.unproject_position(pos) - label.size / 2.0


## Altura da letra na tela (pixels da base 640x360) que o Label3D teria com
## fixed_size: font_size x pixel_size, projetado pela abertura da câmera.
static func screen_font_size(l3: Label3D, cam: Camera3D) -> float:
	var view_h: float = cam.get_viewport().get_visible_rect().size.y
	var world_units: float = l3.font_size * l3.pixel_size
	if not l3.fixed_size:
		var depth: float = maxf(cam.global_position.distance_to(l3.global_position), 0.1)
		world_units /= depth
	return world_units / tan(deg_to_rad(cam.fov) / 2.0) * view_h / 2.0
