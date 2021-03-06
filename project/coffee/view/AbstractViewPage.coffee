AbstractView = require './AbstractView'
MediaQueries = require '../utils/MediaQueries'

class AbstractViewPage extends AbstractView

	_shown         : false
	_listening     : false

	area           : null
	sub            : null

	getContentDfd  : null

	pageTitle      : null
	animatedHeader : null

	$transitionEls   : null
	transitionConfig :
		elOffset   : 15
		elDelay    : 0.15
		elDuration : 0.2

	# use this in progress events, we can't get actual size from HTML in XHR2, so this will do instead
	# use {pageSize} on per-page basis, or avPageSize will be used as default
	avPageSize : 12000
	pageSize   : null

	constructor : (@area, @sub) ->

		super

		return null

	getViewContent : =>

		url =  if @sub then "#{@NC().BASE_URL}/#{@area}/#{@sub}/" else "#{@NC().BASE_URL}/#{@area}/"

		# manually manage deferred here, as 404 is technically failing, we still want to show the page correctly
		@getContentDfd = $.Deferred()

		r = $.ajax
			type : 'GET'
			url  : url
			xhr  : =>
                xhr = new window.XMLHttpRequest()
                xhr.addEventListener "progress", (evt) =>
                	@_onLoadProgress evt
                , false
                return xhr

		r.done @_onLoadComplete
		r.fail @_onLoadFail

		@getContentDfd

	_onLoadProgress : (evt) =>

		percentComplete = (evt.loaded / (@pageSize or @avPageSize)) * 100
		@NC().appView.preloader.goTo percentComplete

		# console.log "percentComplete - #{percentComplete}% for page #{@area}, #{@sub}"

		null

	_onLoadComplete : (res) =>

		# console.log "!!! GET VIEW CONTENT DONE !!!"

		$res       = $(res)
		@pageTitle = $res.filter('title').eq(0).text()
		@$tmpl      = $res.filter('#main').find("[data-template=\"#{@template}\"]")

		@getContentDfd.resolve res

		null

	_onLoadFail : (res) =>

		console.error "_onLoadFail : =>", res

		if res and res.status is 404 then return @_onLoadComplete res.responseText

		@getContentDfd.reject res

		null

	###
	`force` - if both views are artist view, we have to force re-intitialisation
	###
	show : (force=false, cb) =>

		return unless !@_shown
		@_shown = true

		@NC().appView.wrapper.$el.append @$tmpl
		@initialize force

		@NC().appView.wrapper.addChild @

		@callChildrenAndSelf 'setListeners', 'on'

		@_animateIn cb

		null

	_animateIn : (cb) =>

		@$transitionEls = @$el.find('[data-page-transition]')

		@$el.css 'visibility' : 'visible'
		# @$transitionEls.css 'opacity' : 0

		@$transitionEls.each (i, el) =>
			do (i, el) =>

				delay      = i*@transitionConfig.elDelay
				fromParams = opacity : 0, y : @transitionConfig.elOffset
				toParams   = delay : delay, opacity : 1, y : 0, ease : Circ.easeOut
				if i is @$transitionEls.length-1
					toParams.onComplete       = @_animateInDone
					toParams.onCompleteParams = [cb]

				TweenLite.fromTo $(el), @transitionConfig.elDuration, fromParams, toParams

		null

	_animateInDone : (cb) =>

		@$transitionEls.attr "style", ""

		cb?()

		null

	hide : (cb) =>

		return unless @_shown
		@_shown = false

		@_animateOut cb

		null

	_animateOut : (cb) =>

		len = @$transitionEls.length

		@$transitionEls.each (i, el) =>
			do (i, el) =>

				delay      = (len-(i+1))*@transitionConfig.elDelay
				fromParams = opacity : 1, y : 0
				toParams   = delay : delay, opacity : 0, y : @transitionConfig.elOffset, ease : Circ.easeOut
				if i is 0
					toParams.onComplete       = @_animateOutDone
					toParams.onCompleteParams = [cb]

				TweenLite.fromTo $(el), @transitionConfig.elDuration, fromParams, toParams

		null

	_animateOutDone : (cb) =>

		@NC().appView.wrapper.remove @

		### replace with some proper transition if we can ###
		@$el.css 'visibility' : 'hidden'
		cb?()

		null

	dispose : =>

		@callChildrenAndSelf 'setListeners', 'off'

		super()

		null

	setListeners : (setting) =>

		return unless setting isnt @_listening
		@_listening = setting

		null

module.exports = AbstractViewPage
