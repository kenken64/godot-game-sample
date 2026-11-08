extends RefCounted

# Explicit neighbors keep focus inside a menu, including off-screen binding rows.
static func configure(rows: Array) -> void:
    var controls: Array[Control] = []
    for row in rows:
        for control in row:
            control.focus_mode = Control.FOCUS_ALL
            if control is BaseButton:
                control.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
            controls.append(control)
    if controls.is_empty():
        return
    for row_index in range(rows.size()):
        var row: Array = rows[row_index]
        var above: Array = rows[posmod(row_index - 1, rows.size())]
        var below: Array = rows[(row_index + 1) % rows.size()]
        for column in range(row.size()):
            var control: Control = row[column]
            control.focus_neighbor_top = control.get_path_to(above[mini(column, above.size() - 1)])
            control.focus_neighbor_bottom = control.get_path_to(below[mini(column, below.size() - 1)])
            control.focus_neighbor_left = control.get_path_to(row[maxi(column - 1, 0)])
            control.focus_neighbor_right = control.get_path_to(row[mini(column + 1, row.size() - 1)])
    for index in range(controls.size()):
        controls[index].focus_previous = controls[index].get_path_to(controls[posmod(index - 1, controls.size())])
        controls[index].focus_next = controls[index].get_path_to(controls[(index + 1) % controls.size()])
