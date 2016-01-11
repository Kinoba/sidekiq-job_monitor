@Sidekiq ?= {}

class Sidekiq.JobMonitor
  constructor: (markup, options = {}) ->
    @$el = $(markup)
    @monitorURL = @$el.data('monitor-url')
    @monitor()
    options.onStart?(@$el)
    @$el.on('stop', @stopMonitoring)
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

$.fn.sidekiqJobMonitor = (options = {}) ->
  @each (i, el) ->
    $(el).on 'ajax:success', (e, response) ->
      new Sidekiq.JobMonitor(response, options)
