import nimraylib_now/raylib

type
    Button* = object
        rect*: Rectangle
        currentColor: Color
        color*: Color
        highlightColor*: Color
        pressedColor*: Color
        pressCallback*: proc()
        previousLeft: bool
        pressed: bool

        displayText*: bool
        text*: string
        textColor*: Color
        textPos: Vector2
        font*: Font
        fontSize*: float

proc initButton*(btn: var Button) =
    btn.currentColor = btn.color
    if btn.displayText:
        var textSize = measureTextEx(btn.font, btn.text.cstring, btn.fontSize, 0)
        btn.textPos = Vector2(
            x: btn.rect.x + (btn.rect.width/2 - textSize.x/2),
            y: btn.rect.y + (btn.rect.height/2 - textSize.y*0.6),
        )

proc isInBounds(btn: var Button, p: Vector2): bool =
    var r = btn.rect
    result = (p.x >= r.x and p.x <= r.x+r.width) and (p.y >= r.y and p.y <= r.y+r.height)


proc updateButton*(btn: var Button, mPos: Vector2, mLeft: bool) =
    var released = (not mLeft) and (mLeft != btn.previousLeft)
    if btn.isInBounds(mPos):
        btn.currentColor = btn.highlightColor
        if released:
            if btn.pressCallback != nil:
                btn.pressCallback()
            else:
                echo "No callback attached to this button"
            btn.pressed = false
        elif mLeft:
            btn.pressed = true
    else:
        btn.currentColor = btn.color
        if released:
            btn.pressed = false

    if btn.pressed:
        btn.currentColor = btn.pressedColor
    elif released:
        btn.currentColor = btn.color
    btn.previousLeft = mLeft

proc drawButton*(btn: var Button) =
    drawRectangleRounded(btn.rect, 5, 4, btn.currentColor)
    if btn.displayText:
        drawTextEx(btn.font, btn.text.cstring, btn.textPos, btn.fontSize, 0, btn.textColor)
