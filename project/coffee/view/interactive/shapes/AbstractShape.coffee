InteractiveBgConfig = require '../InteractiveBgConfig'
NumberUtils         = require '../../../utils/NumberUtils'

class AbstractShape

	g : null
	s : null

	width       : null
	speedMove   : null
	speedRotate : null
	blurValue   : null
	alphaValue  : null

	dead : false

	@triangleRatio = Math.cos(Math.PI/6)

	constructor : (@interactiveBg) ->

		_.extend @, Backbone.Events

		@width       = @_getWidth()
		@speedMove   = @_getSpeedMove()
		@speedRotate = @_getSpeedRotate()
		@blurValue   = @_getBlurValue()
		@alphaValue  = @_getAlphaValue()

		@g = new PIXI.Graphics

		@g.beginFill '0x'+InteractiveBgConfig.getRandomColor()

		shapeToDraw = InteractiveBgConfig.getRandomShape()
		@["_draw#{shapeToDraw}"]()

		@g.endFill()

		@g.boundsPadding = @width*1.2

		@s = new PIXI.Sprite @g.generateTexture()

		# @blurFilter = new PIXI.BlurFilter
		# @blurFilter.blur = @blurValue

		# @s.filters   = [@blurFilter]
		@s.blendMode = window.blend or PIXI.blendModes.ADD
		@s.alpha     = @alphaValue

		@s.anchor.x = @s.anchor.y = 0.5

		return null

	_drawTriangle : =>

		height = @width * AbstractShape.triangleRatio

		@g.moveTo 0, 0
		@g.lineTo -@width/2, height
		@g.lineTo @width/2, height

		null

	_drawCircle : =>

		@g.drawCircle 0, 0, @width/2

		null

	_drawSquare : =>

		@g.drawRect 0, 0, @width, @width

		null

	_getWidth : =>

		NumberUtils.getRandomFloat InteractiveBgConfig.shapes.MIN_WIDTH, InteractiveBgConfig.shapes.MAX_WIDTH

	_getSpeedMove : =>

		NumberUtils.getRandomFloat InteractiveBgConfig.shapes.MIN_SPEED_MOVE, InteractiveBgConfig.shapes.MAX_SPEED_MOVE

	_getSpeedRotate : =>

		NumberUtils.getRandomFloat InteractiveBgConfig.shapes.MIN_SPEED_ROTATE, InteractiveBgConfig.shapes.MAX_SPEED_ROTATE

	_getBlurValue : =>

		range = InteractiveBgConfig.shapes.MAX_BLUR - InteractiveBgConfig.shapes.MIN_BLUR
		blur  = ((@width / InteractiveBgConfig.shapes.MAX_WIDTH) * range) + InteractiveBgConfig.shapes.MIN_BLUR

		blur

	_getAlphaValue : =>

		range = InteractiveBgConfig.shapes.MAX_ALPHA - InteractiveBgConfig.shapes.MIN_ALPHA
		alpha = ((@width / InteractiveBgConfig.shapes.MAX_WIDTH) * range) + InteractiveBgConfig.shapes.MIN_ALPHA

		alpha

	callAnimate : =>

		return unless !@dead

		# @s.blendMode = if InteractiveBgConfig.filters.RGB then PIXI.blendModes.NORMAL else PIXI.blendModes.ADD
		@s.alpha = @alphaValue*InteractiveBgConfig.general.GLOBAL_ALPHA

		@s.position.x -= @speedMove*InteractiveBgConfig.general.GLOBAL_SPEED
		@s.position.y += @speedMove*InteractiveBgConfig.general.GLOBAL_SPEED
		@s.rotation += @speedRotate*InteractiveBgConfig.general.GLOBAL_SPEED

		# if (@s.position.x + (@width/2) < 0) then @s.position.x += @NC().appView.dims.w
		# if (@s.position.y - (@width/2) > @NC().appView.dims.h) then @s.position.y -= @NC().appView.dims.h

		if (@s.position.x + (@width/2) < 0) or (@s.position.y - (@width/2) > @NC().appView.dims.h) then @kill()

		null

	kill : =>

		@dead = true

		@interactiveBg.trigger @interactiveBg.EVENT_KILL_SHAPE, @

	getSprite : =>

		return @s

	getLayer : =>

		range = InteractiveBgConfig.shapes.MAX_WIDTH - InteractiveBgConfig.shapes.MIN_WIDTH

		layer = switch true
			when @width < (range / 3)+InteractiveBgConfig.shapes.MIN_WIDTH then InteractiveBgConfig.layers.BACKGROUND
			when @width < ((range / 3) * 2)+InteractiveBgConfig.shapes.MIN_WIDTH then InteractiveBgConfig.layers.MIDGROUND
			else InteractiveBgConfig.layers.FOREGROUND

		layer

	NC : =>

		return window.NC

module.exports = AbstractShape
