@Sidekiq ?= {}

class Sidekiq.JobMonitor
  constructor: (markup, options = {}) ->
    @$el = $(markup)
    @monitorURL = @$el.data('monitor-url')
    @monitor()
    options.onStart?(this)
    @$el.on('stop', @stopMonitoring)
    @$el.on('cancel', @cancelJob)
    $('body').trigger('start', [this])

  monitorProgress: =>
    $.getJSON(@monitorURL)
      .done(@onMonitorProgressData)
      .fail(@jobFailed)

  onMonitorProgressData: (data) =>
    if data.state is 'complete'
      @jobComplete(data)
    else
      @monitor()

  monitor: ->
    @monitorTimer = setTimeout(@monitorProgress, 1000)

  jobComplete: (data) ->
    console.log "trigger completion : ", this, data
    @$el.trigger('complete', [this, data])

  jobFailed: =>
    @$el.trigger('failed', [this])

  stopMonitoring: =>
    clearTimeout(@monitorTimer) if @monitorTimer

  cancelJob: =>
    $.get([@monitorURL, 'cancel'].join('/')).done(@jobCanceled)

  jobCanceled: =>
    @$el.trigger('canceled', [this])

$.fn.sidekiqJobMonitor = (options = {}) ->
  @each (i, el) ->
    $(el).on 'ajax:success', (e, response) ->
      new Sidekiq.JobMonitor(response, options)
