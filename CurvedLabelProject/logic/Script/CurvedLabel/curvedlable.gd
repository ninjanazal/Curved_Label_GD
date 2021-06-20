tool
extends Control
class_name CurvedLabel

# PRIVATE ------------------------------>
var isReady = false;
var percentRange : float = 0.1;

var textChars : PoolStringArray;
var stringSize : Vector2 = Vector2.ZERO;
var startPos : Vector2 = Vector2.ZERO;
var rectSize : Vector2 = Vector2.ZERO;

var path : Path2D = null;
var curve : Curve2D												setget set_curve,		get_curve;


# EXPORT ------------------------------->
export(String, MULTILINE) var text = ""							setget set_text ,		get_text;
export(int, 'H_Left', 'H_Center', 'H_Right') var hAlign = 0		setget set_hAlign,		get_hAlign
export(int, 'V_Top', 'V_Center', 'V_Bottom') var vAlign = 0		setget set_vAlign,		get_vAlign;
export(float, 0.0, 50.0, 0.05) var pxSpacing = 0.0				setget set_pxSpacing,	get_pxSpacing;
export(Font) var font = null									setget set_font,		get_fontCurve;
export(bool) var useCurve = false								setget set_useCurve,	get_useCurve;
export(float, -1000.0, 1000.0, 0.05) var offset = 0.0			setget set_offset,		get_offset;

# SET ----------------------------------->
func set_text(value):
	text = value;
	self._updateNode();

func set_hAlign(value):
	hAlign = value;
	self._updateNode();

func set_vAlign(value):
	vAlign = value;
	self._regenerateCurve();
	self._updateNode();

func set_pxSpacing(value):
	pxSpacing = value;
	self._updateNode();

func set_curve(value):
	curve = value;
	self._updateNode();

func set_font(value):
	font = value;
	self._updateNode();

func set_useCurve(value):
	useCurve = value;
	if(useCurve):
		self._createCurve();
	else: 
		self._destroyCurve();
	self._updateNode();

func set_offset(value):
	offset = value;
	self._updateNode();

# GET ----------------------------------->
func get_text():		return text;
func get_hAlign():		return hAlign;
func get_vAlign():		return vAlign
func get_pxSpacing():	return pxSpacing;
func get_useCurve():	return useCurve;
func get_curve():		return curve;
func get_fontCurve():	return font;
func get_offset():		return offset;

# CORE ----------------------------------->
func _ready():
	self._validateChilds();
	if self.connect('resized', self, '_updateNode') != OK:
		print("Connection Error");
		return;
	self.isReady = true;
	self._updateNode();

func _draw():
	self._drawString();


# PRIVATE -------------------------------->
func _validateChilds():
	var childs = self.get_children()
	if useCurve:
		if childs.size() == 0:
			useCurve = false;
		else:
			self.path = childs[0];
			self.curve = self.path.get_curve();
			if self.curve.connect('changed', self, '_onCurveChanged') != OK:
				print("Failed to connect to curve");
	else:
		for child in childs:
			self.remove_child(child);
			child.queue_free();

func _updateNode():
	if !self._validateProperties() || !isReady:
		return;
	self.set_clip_contents(true);
	
	self._decomposeString();
	self._getStringInfo();

	self.update();

# STRING CONSTRUCTION ------------------->
func _validateProperties() ->bool:
	return self.font != null;

func _decomposeString():
	self.textChars = PoolStringArray([]);
	var chars : Array = [];
	for i in range(text.length()):
		self.textChars.push_back(text[i]);

func _getStringInfo():
	self.stringSize = self.font.get_string_size(text);
	self.stringSize.y = self.font.get_ascent();

	self.stringSize.x += pxSpacing * (self.text.length() - 1);
	self.rectSize = self.get_size();


func _drawString():
	var cPosition = Vector2.ZERO;
	if (!useCurve):
		cPosition.x = ((self.rectSize.x / 2.0) - (self.stringSize.x / 2.0)) * self.hAlign;
		cPosition.y = (((self.rectSize.y / 2.0) - (self.stringSize.y / 2.0) ) * self.vAlign) + self.stringSize.y ;
	else:

		cPosition.x =  ((self.rectSize.x / 2.0) - (self.stringSize.x / 2.0)) * self.hAlign;
		cPosition.y = (((self.rectSize.y / 2.0) - (self.stringSize.y / 2.0) ) * self.vAlign) + self.stringSize.y ;
	
	cPosition.x += self.get_offset()
	self.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE);

	for i in textChars.size():
		if (useCurve):
			var percentBox = cPosition.x / self.rectSize.x;
			var xOnLine = self.curve.interpolate_baked(percentBox * self.curve.get_baked_length());

			var tangPoints : Array = [];
			tangPoints.append(self.curve.interpolate_baked((percentBox - self.percentRange) * self.curve.get_baked_length()));
			tangPoints.append(self.curve.interpolate_baked((percentBox + self.percentRange) * self.curve.get_baked_length()));
			
			var posNormal = (tangPoints[1] - tangPoints[0]).normalized().tangent();
			var angleTo = Vector2.UP.angle_to(posNormal);
			self.draw_set_transform(xOnLine, angleTo, Vector2.ONE);
			cPosition.x += self.draw_char(self.font, Vector2.ZERO, textChars[i],"") + self.get_pxSpacing();
		else:
			cPosition.x += self.draw_char(self.font, cPosition, textChars[i],"") + self.get_pxSpacing();


# CURVE CONSTRUCTION ---------------------------->
func _createCurve():
	if (!isReady): return;
	
	if (self.path == null):
		self.path = Path2D.new();
	if (self.curve == null):
		self.curve = Curve2D.new();
	
	if self.curve.get_point_count() <= 2:
		self._regenerateCurve();
	self.path.set_curve(self.curve);

	self.add_child(self.path);
	if self.curve.connect('changed', self, '_onCurveChanged') != OK:
		print("Failed to connect to curve");
	
	if self.get_owner() != null:
		self.path.set_owner(self.get_owner());


func _destroyCurve():
	if (self.path != null):
		self.remove_child(self.path);
		self.path.queue_free();
	self.path = null;
	self.curve.disconnect('changed',self, '_onCurveChanged');


func _regenerateCurve():
	if (!isReady): return;
	
	self.curve.clear_points();
	self.curve.add_point(Vector2(0.0, (((self.rectSize.y / 2.0) - (self.stringSize.y / 2.0) ) * self.vAlign) + self.stringSize.y));
	self.curve.add_point(Vector2(self.rectSize.x, (((self.rectSize.y / 2.0) - (self.stringSize.y / 2.0) ) * self.vAlign) + self.stringSize.y));


func _onCurveChanged():
	self._updateNode();
