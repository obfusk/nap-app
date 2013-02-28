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

    $.post this.href, -> location.reload()
    false

  $('.app-mod, .app-all').click f
