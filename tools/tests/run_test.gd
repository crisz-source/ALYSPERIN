extends SceneTree
## Lançador de testes. Uso: godot --headless --path <proj> --script run_test.gd -- <teste.gd> [args]
##
## Por que existe: no modo --script a Godot compila o script principal ANTES de
## criar os autoloads. Um teste que cita a classe Player por tipo puxaria a
## compilação de player.gd, que usa o autoload Hitstop -> "Identifier not found".
## Este lançador não cita classe nenhuma: carrega o teste já com os autoloads prontos.

func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("uso: --script run_test.gd -- <caminho/do/teste.gd>")
		quit(2)
		return
	var path: String = args[0]
	if not FileAccess.file_exists(path):
		path = get_script().resource_path.get_base_dir().path_join(args[0])
	var script: GDScript = load(path)
	if script == null or not script.can_instantiate():
		printerr("teste nao compilou: ", path)
		quit(3)
		return
	root.add_child(script.new())
