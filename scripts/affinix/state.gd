extends Node
## Persistent game rules. UI and world communicate through signals.
signal changed
signal message(text: String)
signal quest_completed(title: String)

const SAVE_PATH := "user://affinix_save_v1.json"
const ITEM_NAMES := {"wood":"Wood", "stone":"Stone", "branch":"Branches", "leaves":"Leaves", "berry":"Berries", "mushroom":"Mushrooms", "herb":"Herbs", "fish":"Fish", "crystal":"Crystals", "mineral":"Minerals", "meal":"Cooked meal", "axe":"Axe", "pickaxe":"Pickaxe", "rod":"Fishing rod", "lantern":"Lantern", "backpack":"Backpack"}
const RECIPES := [
	{"id":"axe", "name":"Axe", "category":"Tools", "cost":{"wood":3,"stone":2}},
	{"id":"pickaxe", "name":"Pickaxe", "category":"Tools", "cost":{"wood":2,"stone":4}},
	{"id":"rod", "name":"Fishing rod", "category":"Tools", "cost":{"wood":3,"leaves":2}},
	{"id":"lantern", "name":"Lantern", "category":"Equipment", "cost":{"wood":2,"crystal":1}},
	{"id":"backpack", "name":"Better backpack", "category":"Equipment", "cost":{"leaves":5,"wood":2}},
	{"id":"meal", "name":"Cooked meal", "category":"Food", "cost":{"berry":2,"mushroom":1}, "requires":"campfire"},
	{"id":"meal", "name":"Cooked fish", "category":"Food", "cost":{"fish":1,"branch":1}, "requires":"campfire"},
]
const BUILDINGS := [
	{"id":"campfire", "name":"Campfire", "cost":{"wood":3,"stone":2}},
	{"id":"tent", "name":"Tent", "cost":{"wood":5,"leaves":4}},
	{"id":"chest", "name":"Chest", "cost":{"wood":5}},
	{"id":"fence", "name":"Fence", "cost":{"wood":2}},
	{"id":"lamp", "name":"Lantern post", "cost":{"wood":2,"crystal":1}},
]
const QUESTS := [
	{"title":"A Quiet Beginning", "detail":"Read the notebook at the cabin.", "flag":"notebook"},
	{"title":"Things to Keep", "detail":"Gather three wood and two stone.", "flag":"gathered"},
	{"title":"A Small Fire", "detail":"Place a campfire on open ground.", "flag":"campfire"},
	{"title":"By the Water", "detail":"Meet Rowan at Crystal Lake.", "flag":"rowan"},
	{"title":"Still Water", "detail":"Make a fishing rod and catch a fish.", "flag":"fished"},
	{"title":"Golden Leaves", "detail":"Visit Autumn Valley.", "flag":"autumn"},
	{"title":"The Village Path", "detail":"Meet Ada in Forgotten Village.", "flag":"ada"},
	{"title":"A Familiar Hand", "detail":"Read the abandoned village note.", "flag":"village_note"},
	{"title":"The Cold Ridge", "detail":"Make a pickaxe and collect a mineral.", "flag":"mineral"},
	{"title":"Beneath the Forest", "detail":"Explore the underground and collect a crystal.", "flag":"crystal"},
	{"title":"A Place to Stay", "detail":"Place a tent somewhere safe.", "flag":"tent"},
	{"title":"A Light in the Window", "detail":"Help restore the village notice board.", "flag":"restored"},
	{"title":"What Remains", "detail":"Return to the cabin and read the final notebook page.", "flag":"ending"},
]
var data: Dictionary = {}
var can_save := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	new_game()

func _setup_input() -> void:
	_action("aff_up", [KEY_W, KEY_UP])
	_action("aff_down", [KEY_S, KEY_DOWN])
	_action("aff_left", [KEY_A, KEY_LEFT])
	_action("aff_right", [KEY_D, KEY_RIGHT])
	_action("aff_run", [KEY_SHIFT])
	_action("aff_interact", [KEY_E])
	_action("aff_inventory", [KEY_I])
	_action("aff_craft", [KEY_C])
	_action("aff_map", [KEY_M])
	_action("aff_journal", [KEY_J])
	_action("aff_pause", [KEY_ESCAPE])

func _action(name: String, codes: Array) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name)
	for code in codes:
		var event := InputEventKey.new()
		event.physical_keycode = code
		if not InputMap.action_has_event(name, event):
			InputMap.action_add_event(name, event)

func new_game() -> void:
	can_save = true
	data = {"version":1, "position":[288.0,320.0], "inventory":{"wood":0,"stone":0,"branch":2,"leaves":2,"berry":3,"mushroom":0,"herb":0,"fish":0,"crystal":0,"mineral":0,"meal":0}, "storage":{}, "health":100.0, "hunger":100.0, "energy":100.0, "temperature":100.0, "day":1, "minute":420.0, "weather":"Sunny", "flags":{}, "stats":{"wood":0,"stone":0}, "depleted":{}, "side":{}, "buildings":[], "quest":0}
	changed.emit()

func amount(item: String) -> int:
	return maxi(0, int(data["inventory"].get(item, 0)))

func add_item(item: String, amount_to_add: int = 1) -> void:
	data["inventory"][item] = amount(item) + amount_to_add
	if item in ["wood", "stone"]:
		data["stats"][item] = int(data["stats"].get(item, 0)) + amount_to_add
	if item == "mineral":
		set_flag("mineral")
	if item == "crystal":
		set_flag("crystal")
	if item == "fish":
		set_flag("fished")
	if int(data["stats"].get("wood", 0)) >= 3 and int(data["stats"].get("stone", 0)) >= 2:
		set_flag("gathered")
	changed.emit()

func can_afford(cost: Dictionary) -> bool:
	for id in cost:
		if amount(str(id)) < int(cost[id]):
			return false
	return true

func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for id in cost:
		data["inventory"][id] = amount(str(id)) - int(cost[id])
	changed.emit()
	return true

func craft(index: int) -> void:
	if index < 0 or index >= RECIPES.size():
		return
	var recipe: Dictionary = RECIPES[index]
	var id: String = recipe["id"]
	if id != "meal" and amount(id) > 0:
		message.emit("You already have this item.")
		return
	if recipe.has("requires") and not has_building(str(recipe["requires"])):
		message.emit("Place a campfire first.")
		return
	if not spend(recipe["cost"]):
		message.emit("Not enough resources.")
		return
	add_item(id)
	AffAudio.play("craft")
	message.emit("Made " + str(recipe["name"]) + ".")

func eat(id: String) -> void:
	var food := {"berry":12.0, "mushroom":10.0, "fish":18.0, "meal":40.0}
	if not food.has(id) or amount(id) <= 0:
		return
	if float(data["hunger"]) >= 100.0:
		message.emit("You are not hungry.")
		return
	data["inventory"][id] = amount(id) - 1
	data["hunger"] = minf(100.0, float(data["hunger"]) + float(food[id]))
	changed.emit()
	message.emit("That was comforting.")

func has_building(id: String) -> bool:
	for entry in data["buildings"]:
		if entry is Dictionary and entry.get("id", "") == id:
			return true
	return false

func add_building(index: int, pos: Vector2, angle: int) -> bool:
	if index < 0 or index >= BUILDINGS.size():
		return false
	var item: Dictionary = BUILDINGS[index]
	if not spend(item["cost"]):
		message.emit("Not enough resources.")
		return false
	data["buildings"].append({"id":item["id"], "x":pos.x, "y":pos.y, "rotation":angle})
	set_flag(str(item["id"]))
	AffAudio.play("craft")
	message.emit("Placed " + str(item["name"]) + ".")
	changed.emit()
	return true

func set_flag(flag: String) -> void:
	if data["flags"].get(flag, false):
		return
	data["flags"][flag] = true
	while int(data["quest"]) < QUESTS.size():
		var q: Dictionary = QUESTS[int(data["quest"])]
		if not bool(data["flags"].get(q["flag"], false)):
			break
		data["quest"] = int(data["quest"]) + 1
		quest_completed.emit(str(q["title"]))
	changed.emit()

func sleep() -> void:
	data["day"] = int(data["day"]) + 1
	data["minute"] = 420.0
	data["energy"] = 100.0
	data["health"] = minf(100.0, float(data["health"]) + 25.0)
	data["hunger"] = maxf(15.0, float(data["hunger"]) - 10.0)
	var cycle := ["Sunny", "Wind", "Rain", "Fog", "Sunny"]
	data["weather"] = cycle[(int(data["day"]) - 1) % cycle.size()]
	changed.emit()
	message.emit("A new morning. Day " + str(data["day"]) + ".")

func save_game() -> bool:
	if not can_save:
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	return file.get_error() == OK

func load_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var saved = JSON.parse_string(file.get_as_text())
	if not saved is Dictionary or int(saved.get("version", 0)) != 1:
		return false
	for field in ["inventory", "flags", "stats", "depleted", "storage"]:
		if not saved.get(field, null) is Dictionary:
			return false
	if not saved.get("buildings", null) is Array or not saved.get("position", null) is Array:
		return false
	data = saved
	if not data.has("side"):
		data["side"] = {}
	can_save = true
	changed.emit()
	return true
