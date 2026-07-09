extends CPUParticles2D
class_name WalkingParticles
@export var target_tilemap: TileMapLayer

# Call this function passing the cell coordinate to change the particle texture dynamically
func match_particle_to_tile(tile_coords: Vector2i) -> void:
	if not target_tilemap:
		return

	# 1. Get the dynamic Source ID of the tile painted at this specific cell location
	var active_source_id: int = target_tilemap.get_cell_source_id(tile_coords)
	
	# -1 means the cell is empty/blank
	if active_source_id == -1:
		return 

	# 2. Extract the TileSet resource
	var tileset: TileSet = target_tilemap.tile_set
	if not tileset:
		return

	# 3. Fetch the exact source matching that cell (e.g., concrete.png, grass.png, etc.)
	var source: TileSetSource = tileset.get_source(active_source_id)

	if source is TileSetAtlasSource:
		var active_texture: Texture2D = source.texture
		if active_texture:
			# 4. Swap the texture dynamically to match the exact file
			self.texture = active_texture
			self.emitting = true