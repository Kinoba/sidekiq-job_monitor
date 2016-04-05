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
    switch data.state
      when 'complete' then @jobComplete(data)
      when 'failed' then @jobFailed(data)
      else @monitor()

  monitor: ->
    @monitorTimer = setTimeout(@monitorProgress, 1000)

  jobComplete: (data) ->
    @$el.trigger('complete', [this, data])

  jobFailed: =>
    @$el.trigger('failed', [this])

  stopMonitoring: =>
    clearTimeout(@monitorTimer) if @monitorTimer

  # Canceling job will only work for queued jobs, and not for running ones
  #
  # If the job is running, cancelation will be ignored and no error raised
  #
  cancelJob: =>
    $.get(@remoteURL('cancel')).done(@jobCanceled)

  jobCanceled: =>
    @$el.trigger('canceled', [this])

  remoteURL: (action = null) ->
    return @monitorURL unless action
    urlParts = @monitorURL.split('?')
    url = [urlParts[0], action].join('/')
    queryParams = urlParts[1]
    if queryParams then [url, queryParams].join('?') else url

$.fn.sidekiqJobMonitor = (options = {}) ->
  @each (i, el) ->
    $(el).on 'ajax:success', (e, response) ->
      new Sidekiq.JobMonitor(response, options)
