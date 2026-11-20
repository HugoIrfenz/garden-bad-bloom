extends Node2D

const Art = preload("res://scripts/garden_art.gd")
const Roster = preload("res://scripts/guest_roster.gd")

var roster: Array = []
var width := 440.0
var elapsed := 0.0

func _ready() -> void:
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
 elapsed += delta
 queue_redraw()

func _draw() -> void:
 var count := roster.size()
 if count == 0:
  draw_string(Art.DISPLAY_FONT, Vector2(0, 50), "Friends will gather here", HORIZONTAL_ALIGNMENT_CENTER, width, 17, Color("#e2cbb8"))
  return
 var spacing := width / float(maxi(count, 2))
 for i in range(count):
  var row: Dictionary = roster[i]
  var hero := int(row.get("hero", -1))
  var x := roundf(spacing * (i + 0.5))
  var feet := Vector2(x, 69.0 + roundf(sin(elapsed * 2.1 + i * 0.8)))
  if hero >= 0 and hero < Roster.NAMES.size():
   Art.shadow(self, feet, 13.0)
   Art.walk(self, hero, feet, 52.0, 0.0, Vector2.DOWN, false, Color.WHITE if row.get("connected", true) else Color(0.6, 0.6, 0.65, 0.8))
  else:
   draw_string(Art.DISPLAY_FONT, Vector2(x - 25, 48), "?", HORIZONTAL_ALIGNMENT_CENTER, 50, 25, Color("#f6e2c2"))
  var name := str(row.get("username", ""))
  var color := Color("#f9e8c8") if row.get("connected", true) else Color("#b3a7a2")
  draw_string(Art.DISPLAY_FONT, Vector2(x - spacing * 0.5, 85), name, HORIZONTAL_ALIGNMENT_CENTER, spacing, 12, color)
  if row.get("ready", false):
   draw_circle(Vector2(x + 20, 12), 3, Color("#a7d5a3"))
