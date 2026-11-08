extends Node
## Autoload ToonStyle: visual de anime (cel shading) em TODO modelo do jogo.
##
## - Luz em faixas chapadas (diffuse/specular "toon" do StandardMaterial3D).
## - Contorno escuro (casca invertida: cópia um pouco inflada, só as costas
##   desenhadas) nos personagens e objetos; blocos grandes (chão, paredes) ficam
##   sem contorno para não engrossar as arestas do mapa.
## Funciona sozinho: todo MeshInstance3D que entra na cena é convertido. Materiais
## transparentes ou sem luz (avisos no chão, efeitos, camadas de cor) não mudam.

## Espessura do contorno no mundo (m).
const OUTLINE_WIDTH: float = 0.022
const OUTLINE_COLOR := Color(0.06, 0.04, 0.08)
## Objetos maiores que isto (maior lado, m) não ganham contorno (blocos do mapa).
const OUTLINE_MAX_SIZE: float = 9.0
## Desligado = visual normal (comparações, testes).
var enabled: bool = true

var _toon_cache: Dictionary = {}      # material original -> material toon
var _outline_cache: Dictionary = {}   # espessura local (arredondada) -> material de contorno


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if enabled and node is MeshInstance3D:
		# Adiado: o modelo importado termina de montar (materiais, escala) no mesmo quadro.
		_apply.call_deferred(node)


## Converte um modelo já na cena (também usado por testes).
func apply_to(mesh_instance: MeshInstance3D) -> void:
	_apply(mesh_instance)


func _apply(mi: MeshInstance3D) -> void:
	if not is_instance_valid(mi) or mi.mesh == null or not mi.is_inside_tree() or mi.has_meta(&"toon_done"):
		return
	mi.set_meta(&"toon_done", true)
	var outline: Material = _outline_for(mi)
	if mi.material_override:
		var converted: Material = _toon(mi.material_override, outline)
		if converted:
			mi.material_override = converted
		return
	for i in mi.mesh.get_surface_count():
		var source: Material = mi.get_active_material(i)
		var converted: Material = _toon(source, outline)
		if converted:
			mi.set_surface_override_material(i, converted)


## Versão toon do material (null = não converte: transparente, sem luz, shader próprio).
func _toon(source: Material, outline: Material) -> Material:
	var base := source as BaseMaterial3D
	if base == null or base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED \
			or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		return null
	var key: Array = [base, outline]
	if _toon_cache.has(key):
		return _toon_cache[key]
	var toon := base.duplicate() as BaseMaterial3D
	toon.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	toon.specular_mode = BaseMaterial3D.SPECULAR_TOON
	toon.roughness = maxf(toon.roughness, 0.7)
	if outline:
		toon.next_pass = outline
	_toon_cache[key] = toon
	return toon


## Material de contorno com espessura em unidades locais (desfaz a escala do modelo).
func _outline_for(mi: MeshInstance3D) -> Material:
	var world_aabb: AABB = mi.global_transform * mi.get_aabb()
	var longest: float = maxf(world_aabb.size.x, maxf(world_aabb.size.y, world_aabb.size.z))
	if longest > OUTLINE_MAX_SIZE or longest < 0.05:
		return null
	var scale: float = maxf(mi.global_transform.basis.get_scale().x, 0.001)
	var local_width: float = snappedf(OUTLINE_WIDTH / scale, 0.001)
	if _outline_cache.has(local_width):
		return _outline_cache[local_width]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = OUTLINE_COLOR
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	m.grow = true
	m.grow_amount = local_width
	_outline_cache[local_width] = m
	return m
