extends VBoxContainer

func set_state(title: String, online: bool, status: String, condition: String):
	$Name.text = title
	$Status.text = status
	$Status.modulate = Color.GREEN if online else Color.RED
	$Condition.text = condition
