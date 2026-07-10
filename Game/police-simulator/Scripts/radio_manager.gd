extends Node

signal radio_message_sent(message_text: String)

func send_radio_message(message_text: String) -> void:
	print("RADIO: " + message_text)
	radio_message_sent.emit(message_text)
