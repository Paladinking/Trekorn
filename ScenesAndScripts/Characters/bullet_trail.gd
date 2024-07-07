extends Node3D

var trail: MeshInstance3D
var point_start : Vector3 = Vector3(0,0,0)
var point_end : Vector3 = Vector3(10, 10, 10)
var lifetime : float = 5;
var alpha : float = 1;
# Called when the node enters the scene tree for the first time.
func _ready():
	trail = get_child(0)
	trail.material_override.set_shader_parameter("Alpha", alpha)
	#trail.mesh.clear()
		
	trail.mesh.clear_surfaces()
	trail.mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	# Prepare attributes for add_vertex.
	trail.mesh.surface_set_normal(Vector3(0, 0, 1))
	trail.mesh.surface_set_uv(Vector2(0, 0))
	# Call last for each vertex, adds the above attributes.
	trail.mesh.surface_add_vertex(point_start)

	trail.mesh.surface_set_normal(Vector3(0, 0, 1))
	trail.mesh.surface_set_uv(Vector2(0, 1))
	trail.mesh.surface_add_vertex(point_end)

	#trail.mesh.surface_set_normal(Vector3(0, 0, 1))
	#trail.mesh.surface_set_uv(Vector2(1, 1))
	#trail.mesh.surface_add_vertex(Vector3(1, 1, 0))
	#
	#trail.mesh.surface_set_normal(Vector3(0, 0, 1))
	#trail.mesh.surface_set_uv(Vector2(1, 1))
	#trail.mesh.surface_add_vertex(Vector3(1, -1, 0))

	# End drawing.
	trail.mesh.surface_end()
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lifetime -= delta
	alpha -= delta/5
	trail.material_override.set_shader_parameter("Alpha", alpha)

	if lifetime < 0:
		self.queue_free()
