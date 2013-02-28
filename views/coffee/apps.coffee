$ ->
  # TODO: handle AJAX errors

  f = (e) ->
    x = $ this
    i = $ 'i', x
    s = $ 'span', x

    return false if x.hasClass 'disabled'

    $('.app-mod, .app-all').addClass 'disabled'

    s.text x.attr('data-action') + ' ...'
    i.removeClass 'icon-play icon-stop'

    $.ajax
      type: 'POST', url: this.href
      success: -> location.reload()
      error: -> alert 'AJAX error'

    false

  $('.app-mod, .app-all').click f
