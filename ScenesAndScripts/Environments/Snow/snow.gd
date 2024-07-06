extends GPUParticles3D

#@onready var body: StaticBody3D = $StaticBody3D
var body;
# Called when the node enters the scene tree for the first time.
func _ready():
	#print("DÅ")
	body = get_parent().find_child("StaticBody3D");

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):

	print("Hej")
	var pos = body.global_transform.origin
	#print(pos);
	#set_instance_shader_parameter("player_pos", pos);
	#self.material_override.set_shader_parameter("player_pos", pos);
	#draw passes shader
	
	#print(self.material_override.get_shader_parameter("player_pos"));
	
	self.position = pos;
	
	#self.process_material.set_shader_parameter("wind_dir", pos);
	#draw passes shader
	
	#print(self.process_material.get_shader_parameter("wind_dir"));
	
	#self.position = pos;
	

