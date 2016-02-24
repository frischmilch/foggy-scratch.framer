bg = new BackgroundLayer backgroundColor: new Color s:0, l:.95

# VARIABLES, DEFAULTS
brushSize = 100
imageWidth = Screen.width # - 120
imageHeight = Screen.height # - 160

# pick a random image from unsplash.it, request one clear, one blurry version
randomImageNumber = Utils.round Utils.randomNumber 1, 1000
imageClear = "https://unsplash.it/#{imageWidth}/#{imageHeight}?image=#{randomImageNumber}"
imageBlurry = "https://unsplash.it/#{imageWidth}/#{imageHeight}?image=#{randomImageNumber}&blur"

# regular framer layer
backImage = new Layer
	width: imageWidth
	height: imageHeight
	image: imageClear
backImage.center()

# special layer that contains a <canvas> element
canvas = new Layer
	width: imageWidth
	height: imageHeight
	backgroundColor: null
	html: "<canvas id='canvas' width='#{imageWidth}' height='#{imageHeight}'></canvas>"
	# CSS filters to make frosted glass more realistic
	brightness: 140
	contrast: 50
canvas.center()

# get canvas HTML element and set context
canvasDOMElement = canvas.querySelector "#canvas" # access the DOMCanvasElement
context = canvasDOMElement.getContext "2d" # the context will be where we actually draw in

# draw blurry image into canvas
img = new Image()
img.src = imageBlurry
# after image has been loaded, draw into canvas
# this works best if image and canvas are the same size
img.addEventListener "load", -> context.drawImage img, 0, 0

# Helper: Find out where touch occured, relative to the canvas layer
getTouchCoordinates = (event) ->
	touch = {touchX: null, touchY: null, force: 1} # create a touch placeholder
	# on desktop, event.offsetX/Y gives coordinates relative to object touched
	# on mobile, we first extract touch event, then use event.clientX/Y and
	# offset by position of canvas layer (in case it's positioned inside screen)
	if Utils.isDesktop()
		touch.touchX = event.offsetX
		touch.touchY = event.offsetY
	else
		touchEvent = Events.touchEvent event
		touch.touchX = touchEvent.pageX - canvas.x # pageX is absolute touch on screen
		touch.touchY = touchEvent.pageY - canvas.y # pageY is absolute touch on screen
		touch.force = touchEvent.force if touchEvent.force isnt null # use force on an iPhone 6S, otherwise keep it at 1
	return touch

# handling touch events on canvas
canvas.onTouchStart -> draw event, true # start a new line when finger meets glass
canvas.onPan -> draw event # continue line when finger moves

# draw into canvas, then mask
draw = (event, freshLine = false) ->
	touch = getTouchCoordinates event # looking into the event, get coordinates where touch occured
	# ---- DRAWING BEGINS ----
	context.beginPath() if freshLine # begin a new line on Touch Start, otherwise continue
	# set brush settings
	context.lineWidth = Utils.modulate touch.force, [0,1], [30,brushSize]
	context.lineCap = context.lineJoin = "round"
	context.strokeStyle = "#ff0000" # any opaque color works
	# soft brush using shadows (comment this block for sharp edges)
	context.shadowColor = context.strokeStyle
	context.shadowBlur = 20
	context.shadowOffsetX = context.shadowOffsetY = 0
	# move imaginay pointer and draw a 'zero' length line so it works when just tapping
	context.moveTo touch.touchX, touch.touchY if freshLine
	context.lineTo touch.touchX+0.01, touch.touchY
	# set composition mode and draw stroke
	context.globalCompositeOperation = 'destination-out' # comment this line to see drawing
	context.stroke()
	# ---- DRAWING ENDS ----
