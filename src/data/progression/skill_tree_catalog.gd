class_name SkillTreeCatalog
extends Resource

@export var nodes: Array[SkillNodeData] = []


func get_node_data(node_id: StringName) -> SkillNodeData:
	for node: SkillNodeData in nodes:
		if node.id == node_id:
			return node
	return null

