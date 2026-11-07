extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    var online = level.get_node("Online")
    await create_timer(0.2).timeout
    online._apply_state({"finished": true, "boss": true, "collected": 20})
    var title = level.get_node("UI/Finale/VictoryTitle")
    var art = level.get_node("UI/Finale/VictoryArt")
    if not level.finale.visible or not art.visible or title.text != "LEVEL PASSED!":
        push_error("Guest did not show victory")
        quit(1)
        return
    online._apply_state({"finished": true, "boss": true, "collected": 20, "ending": "return"})
    if not art.visible or title.text != "LEVEL PASSED!" or not level.get_node("UI/Finale/Result").text.contains("return"):
        push_error("Guest did not preserve victory and display the host's ending")
        quit(1)
        return
    print("PASS: guest sees victory and host ending")
    quit(0)
