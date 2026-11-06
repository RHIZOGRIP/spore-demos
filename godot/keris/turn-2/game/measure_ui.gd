extends SceneTree
func _initialize():
	var font=ThemeDB.fallback_font
	for sign_s in ["warm","wavering","hollow"]:
		for item in [[412,sign_s.capitalize()+" voice · +18 stone, +12 grain"],[394,sign_s.capitalize()+" voice · +18 S, +12 G"],[224,sign_s.capitalize()+" voice: gift?"],[224,"Accepted · "+sign_s]]:
			print(item[1]," actual width=",font.get_string_size(item[1],HORIZONTAL_ALIGNMENT_LEFT,-1,22).x," available=",item[0]-16)
	quit()
