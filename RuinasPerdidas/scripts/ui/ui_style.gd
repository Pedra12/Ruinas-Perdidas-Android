class_name UiStyle
extends RefCounted
## Estilos de interface criados por código (botões grandes para toque, barras).


static func box(color: Color, radius: int = 12, border: Color = Color(0, 0, 0, 0), border_w: int = 0) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = color
    sb.set_corner_radius_all(radius)
    sb.border_color = border
    sb.set_border_width_all(border_w)
    sb.content_margin_left = 20
    sb.content_margin_right = 20
    sb.content_margin_top = 12
    sb.content_margin_bottom = 12
    return sb


static func button(text: String, min_size: Vector2 = Vector2(420, 84), font_size: int = 34) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = min_size
    b.add_theme_font_size_override("font_size", font_size)
    b.add_theme_stylebox_override("normal", box(Color(0.16, 0.2, 0.17, 0.92), 16, Color(0.8, 0.75, 0.5, 0.9), 3))
    b.add_theme_stylebox_override("hover", box(Color(0.24, 0.3, 0.25, 0.95), 16, Color(1, 0.9, 0.6), 3))
    b.add_theme_stylebox_override("pressed", box(Color(0.35, 0.42, 0.3, 1.0), 16, Color(1, 1, 0.8), 3))
    b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
    b.add_theme_color_override("font_color", Color(0.96, 0.93, 0.8))
    return b


static func label(text: String, font_size: int = 28, color: Color = Color(1, 1, 1)) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
    l.add_theme_constant_override("outline_size", 6)
    return l


static func bar(fill: Color, size: Vector2) -> ProgressBar:
    var p := ProgressBar.new()
    p.custom_minimum_size = size
    p.show_percentage = false
    p.min_value = 0.0
    p.max_value = 1.0
    p.value = 1.0
    var bg := box(Color(0, 0, 0, 0.55), 8, Color(1, 1, 1, 0.35), 2)
    bg.content_margin_top = 0
    bg.content_margin_bottom = 0
    var fg := box(fill, 8)
    fg.content_margin_top = 0
    fg.content_margin_bottom = 0
    p.add_theme_stylebox_override("background", bg)
    p.add_theme_stylebox_override("fill", fg)
    return p
