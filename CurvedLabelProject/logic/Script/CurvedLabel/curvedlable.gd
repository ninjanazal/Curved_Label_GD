tool
extends Control
class_name CurvedLabel

# PRIVATE ------------------------------>


# EXPORT ------------------------------->
export(String) var text = "" setget set_text ,get_text;
export(int, 'H_Left', 'H_Center', 'H_Right') var HAlign = 0;
export(int, 'V_Top', 'V_Center', 'V_Bottom') var VAlign = 0;
export(int) var PxSpacing = 0;
export(Curve2D) var Curve = null;
export(Font) var Font = null;
export(float) var Offset = 0.0;

# SET ----------------------------------->
func set_text(value):
    text = value;

# GET ----------------------------------->
func get_text(): return text;


func _ready():
	pass;



# CORE ----------------------------------->
func _draw():
    pass;