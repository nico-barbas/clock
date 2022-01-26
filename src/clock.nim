import std/times
import std/httpClient
import std/json
import nimraylib_now/raylib
import button

const
  vec2Zero = Vector2(x: 0, y: 0)
  windowWidth = 300
  windowHeight = 400
  fontSize = 48
  smallFontSize = 24
  textOrigin = Vector2(x: 52, y: 200)
  textPadding = 5
  sunWidth = 100
  sunHeight = 100
  moonWidth = 50
  moonHeight = 50
  spriteFrameTime = 0.15
  nightfallHour = 19

var
  font: Font

type
  ClockText = object
    pos: Vector2
    width: float32
    height: float32
    text: string

proc initClockText(c: var ClockText, pos: Vector2) =
  c.pos = pos
  let dummyTextSize = measureTextEx(font, "00", fontSize, 0)
  c.width = dummyTextSize.x
  c.height = dummyTextSize.y

proc initClockText(c: var ClockText, text: string, pos: Vector2) =
  c.pos = pos
  let textSize = measureTextEx(font, text.cstring, fontSize, 0)
  c.width = textSize.x
  c.height = textSize.y
  c.text = text

type
  DayState = enum
    Day,
    Night,

var
  isRunning: bool
  time: DateTime
  hours: ClockText
  hoursHelper: ClockText
  minutes: ClockText
  minutesHelper: ClockText
  seconds: ClockText
  secondsHelper: ClockText
  colons: array[2, ClockText]
  closeBtn: Button

  spriteIndex: int
  spriteTimer: float
  dayState: DayState
  sun: Texture
  moon: Texture
  bg: Texture

  forecastClient: HttpClient

proc close()

proc init() =
  font = loadFontEx("assets/monogram.ttf", fontSize, nil, 250)
  setTextureFilter(font.texture, TextureFilter.BILINEAR.cint);
  sun = loadTexture("assets/sun.png")
  moon = loadTexture("assets/moon.png")
  bg = loadTexture("assets/bg.png")

  var textEnd = textOrigin
  hours.initClockText(textEnd)
  textEnd.x += hours.width + textPadding
  colons[0].initClockText(":", textEnd)
  textEnd.x += colons[0].width + textPadding
  minutes.initClockText(textEnd)
  textEnd.x += minutes.width + textPadding
  colons[1].initClockText(":", textEnd)
  textEnd.x += colons[1].width + textPadding
  seconds.initClockText(textEnd)
  textEnd.x += seconds.width
  # Set the small helper text under each number
  hoursHelper.initClockText("h", Vector2(
    x: hours.pos.x + (hours.width/2),
    y: hours.pos.y + hours.height,
  ))
  minutesHelper.initClockText("m", Vector2(
    x: minutes.pos.x + (minutes.width/2),
    y: minutes.pos.y + minutes.height,
  ))
  secondsHelper.initClockText("s", Vector2(
    x: seconds.pos.x + (seconds.width/2),
    y: seconds.pos.y + seconds.height,
  ))

  closeBtn = Button(
    rect: Rectangle(x: 100, y: 300, width: 100, height: 50),
    color: Color(r: 28, g: 11, b: 20, a: 255),
    highlightColor: Color(r: 48, g: 31, b: 40, a: 255),
    pressedColor: Color(r: 28, g: 11, b: 20, a: 255),
    pressCallback: close,
    displayText: true,
    text: "Close",
    textColor: Raywhite,
    font: font,
    fontSize: 24,
  )
  closeBtn.initButton()

  # http client
  forecastClient = newHttpClient()
  let response = forecastClient.get("https://api.openweathermap.org/data/2.5/onecall?lat=48.864716&lon=2.349014&exclude=minutely,hourly,alerts&appid=0e6f5398c15d486c091b9db6d8238f4f")
  echo(response.status)
  let jsonNode = parseJson(response.body)
#   echo jsonNode
  let current = jsonNode["current"]
  echo current
  let sunrise = current["sunrise"].getInt
  var sunriseTime = fromUnix(sunrise)
  echo sunriseTime.format("HH-mm-ss")



proc update() =
  spriteTimer += getFrameTime().float
  if spriteTimer >= spriteFrameTime:
    spriteTimer = 0
    spriteIndex += 1

  time = now()
  if time.hour >= nightfallHour:
    dayState = Night
  hours.text = time.format("HH")
  minutes.text = time.format("mm")
  seconds.text = time.format("ss")

  closeBtn.updateButton(
     getMousePosition(),
     isMouseButtonDown(MouseButton.LEFT_BUTTON.cint),
    )

proc draw() =
  beginDrawing()

  block:
    clearBackground(Raywhite)
    drawTexturePro(
      bg,
      Rectangle(x: 0, y: 0, width: bg.width.float32, height: bg.height.float32),
      Rectangle(x: 0, y: 0, width: bg.width.float32, height: bg.height.float32),
      vec2Zero, 0,
      White,
    )

    var planet: Texture
    var spriteBounds: Vector2
    case dayState:
    of Day:
      planet = sun
      spriteBounds = Vector2(x: sunWidth, y: sunHeight)
    of Night:
      planet = moon
      spriteBounds = Vector2(x: moonWidth, y: moonHeight)
    drawTexturePro(
      planet,
      Rectangle(
        x: float32(spriteIndex)*spriteBounds.x,
        width: spriteBounds.x,
        height: spriteBounds.y,
      ),
      Rectangle(x: 0, y: 0, width: spriteBounds.x, height: spriteBounds.y),
      vec2Zero, 0,
      White,
    )
    drawTextEx(font, hours.text.cstring, hours.pos, fontSize, 0, Black)
    drawTextEx(font, colons[0].text.cstring, colons[0].pos, fontSize, 0, Black)
    drawTextEx(font, minutes.text.cstring, minutes.pos, fontSize, 0, Black)
    drawTextEx(font, colons[1].text.cstring, colons[1].pos, fontSize, 0, Black)
    drawTextEx(font, seconds.text.cstring, seconds.pos, fontSize, 0, Black)
    # Draw helper text
    drawTextEx(
      font, hoursHelper.text.cstring,
      hoursHelper.pos, smallFontSize,
      0, Black,
    )
    drawTextEx(
      font, minutesHelper.text.cstring,
      minutesHelper.pos, smallFontSize,
      0, Black,
    )
    drawTextEx(
      font, secondsHelper.text.cstring,
      secondsHelper.pos, smallFontSize,
      0, Black,
    )
    closeBtn.drawButton()

  endDrawing()

proc close() =
  isRunning = false

proc main() =
  setConfigFlags(WINDOW_UNDECORATED.cuint)
  setConfigFlags(VSYNC_HINT.cuint)
  initWindow(300, 400, "Simple Clock")
  setTargetFPS(60)
  init()
  isRunning = true
  while isRunning:
    isRunning = not windowShouldClose()
    update()
    draw()
  closeWindow()

main()
