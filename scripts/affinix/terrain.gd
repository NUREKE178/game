extends Node2D
## Layered corner-autotiled terrain. Each layer uses the same four-corner atlas
## and matching Godot terrain metadata; shared vertex samples guarantee seams agree.
const ATLAS = preload("res://assets/affinix/terrain_v2.png")
const LAKE_ATLAS = preload("res://assets/affinix/lake_edges_v2.png")
const CELL := 16
const WIDTH := 120
const HEIGHT := 80
const LAYER_NAMES := ["Grass", "Autumn", "Village", "Cave", "Mountain", "Shore", "Dirt", "Water", "Stone"]
const BITS := [TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER, TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER, TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER]
var layers: Array[TileMapLayer] = []
var tileset: TileSet
var elapsed := 0.0
var ripple_refresh := 0.0
var shore_detail: TileMapLayer
var water_detail: TileMapLayer

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_tileset()
	for row in range(LAYER_NAMES.size()):
		var layer := TileMapLayer.new()
		layer.name = LAYER_NAMES[row]
		layer.tile_set = tileset
		layer.position = Vector2(8, 8)
		add_child(layer)
		layers.append(layer)
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var cell := Vector2i(x, y)
			var v := posmod(x * 13 + y * 7 + int(x / 4) * 3, 4)
			layers[0].set_cell(cell, 0, Vector2i(16 + v, 0))
			for row in range(1, LAYER_NAMES.size()):
				if row in [5, 7]:
					continue
				var mask := _mask(row, x, y)
				if mask == 0:
					continue
				var tile := 16 + v if mask == 15 else mask
				layers[row].set_cell(cell, 0, Vector2i(tile, row))
	_build_lake_layers()
	var water_fx := Node2D.new()
	water_fx.name = "WaterRipples"
	water_fx.set_script(load("res://scripts/affinix/water_fx.gd"))
	add_child(water_fx)

func _build_lake_layers() -> void:
	var lake_set := TileSet.new()
	lake_set.tile_size = Vector2i(4, 4)
	var source := TileSetAtlasSource.new()
	source.texture = LAKE_ATLAS
	source.texture_region_size = Vector2i(4, 4)
	lake_set.add_source(source, 0)
	for row in range(2):
		lake_set.add_terrain_set()
		lake_set.set_terrain_set_mode(row, TileSet.TERRAIN_MODE_MATCH_CORNERS)
		lake_set.add_terrain(row)
		lake_set.set_terrain_name(row, 0, "Sand" if row == 0 else "Water")
		for col in range(1, 16):
			var coords := Vector2i(col, row)
			source.create_tile(coords)
			var data := source.get_tile_data(coords, 0)
			data.terrain_set = row
			data.terrain = 0 if _bit_count(col) >= 2 else -1
			for i in range(4):
				data.set_terrain_peering_bit(BITS[i], 0 if col & (1 << i) else -1)
	shore_detail = TileMapLayer.new()
	shore_detail.name = "ShoreDetail"
	shore_detail.tile_set = lake_set
	shore_detail.position = Vector2(2,2)
	add_child(shore_detail)
	water_detail = TileMapLayer.new()
	water_detail.name = "LakeDetail"
	water_detail.tile_set = lake_set
	water_detail.position = Vector2(2,2)
	add_child(water_detail)
	for y in range(38, 123):
		for x in range(198, 299):
			for row in range(2):
				var mask := _lake_mask(x, y, 1.16 if row == 0 else 1.0)
				if mask != 0:
					(shore_detail if row == 0 else water_detail).set_cell(Vector2i(x,y), 0, Vector2i(mask,row))

func _lake_mask(x: int, y: int, radius: float) -> int:
	var corners := [Vector2(x, y), Vector2(x + 1, y), Vector2(x + 1, y + 1), Vector2(x, y + 1)]
	var result := 0
	for i in range(4):
		var p: Vector2 = corners[i] * 4.0
		if Vector2((p.x - 992) / 160.0, (p.y - 320) / 128.0).length() < radius:
			result |= 1 << i
	return result

func _build_tileset() -> void:
	tileset = TileSet.new()
	tileset.tile_size = Vector2i(CELL, CELL)
	var source := TileSetAtlasSource.new()
	source.texture = ATLAS
	source.texture_region_size = Vector2i(CELL, CELL)
	tileset.add_source(source, 0)
	for row in range(LAYER_NAMES.size()):
		tileset.add_terrain_set()
		tileset.set_terrain_set_mode(row, TileSet.TERRAIN_MODE_MATCH_CORNERS)
		tileset.add_terrain(row)
		tileset.set_terrain_name(row, 0, LAYER_NAMES[row])
		for col in range(1, 20):
			var atlas_coords := Vector2i(col, row)
			source.create_tile(atlas_coords)
			var tile := source.get_tile_data(atlas_coords, 0)
			var mask := 15 if col >= 16 else col
			tile.terrain_set = row
			tile.terrain = 0 if _bit_count(mask) >= 2 else -1
			for i in range(4):
				tile.set_terrain_peering_bit(BITS[i], 0 if mask & (1 << i) else -1)

func _bit_count(mask: int) -> int:
	var count := 0
	for i in range(4):
		if mask & (1 << i):
			count += 1
	return count

func _mask(row: int, x: int, y: int) -> int:
	var result := 0
	var corners := [Vector2(x, y), Vector2(x + 1, y), Vector2(x + 1, y + 1), Vector2(x, y + 1)]
	for i in range(4):
		if _terrain_at(row, corners[i] * CELL):
			result |= 1 << i
	return result

func _terrain_at(row: int, p: Vector2) -> bool:
	# Broad bands follow the original region layout but meander at their edges.
	var x1 := 640.0 + sin(p.y / 91.0) * 16.0
	var x2 := 1280.0 + sin(p.y / 105.0 + 1.2) * 17.0
	var y1 := 640.0 + sin(p.x / 115.0) * 17.0
	var lake := Vector2((p.x - 992.0) / 160.0, (p.y - 320.0) / 128.0).length()
	match row:
		1: return p.x >= x2 and p.y < y1
		2: return p.x < x1 and p.y >= y1
		3: return p.x >= x1 and p.x < x2 and p.y >= y1
		4: return p.x >= x2 and p.y >= y1
		5: return lake < 1.16
		6:
			var horiz1 := absf(p.y - (320.0 + 9.0 * sin(p.x / 140.0))) < 18.0
			var horiz2 := absf(p.y - (960.0 + 9.0 * sin(p.x / 125.0 + 1.0))) < 18.0
			var vert1 := absf(p.x - (320.0 + 8.0 * sin(p.y / 120.0))) < 17.0
			var vert2 := absf(p.x - (960.0 + 8.0 * sin(p.y / 130.0))) < 17.0
			var vert3 := absf(p.x - (1600.0 + 8.0 * sin(p.y / 110.0))) < 17.0
			var patch := false
			for center in [Vector2(230,430), Vector2(480,160), Vector2(510,510), Vector2(1420,480), Vector2(330,850), Vector2(1650,1080)]:
				var d: Vector2 = (p - center) / Vector2(35.0, 24.0)
				if d.length_squared() < 1.0:
					patch = true
					break
			return (horiz1 or horiz2 or vert1 or vert2 or vert3 or patch) and lake >= 1.16
		7: return lake < 1.0
		8: return p.x > x2 and p.y > y1 and sin(p.x / 47.0) + cos(p.y / 61.0) > 1.2
	return false
