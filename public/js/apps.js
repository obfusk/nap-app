$(function () {
  // TODO: handle AJAX errors

  var f = function (e) {
    var x = $(this);
    var i = $('i', x);
    var s = $('span', x);

    if (x.hasClass ('disabled')) { return false; }

    $('.app-mod, .app-all').addClass ('disabled');

    s.text (x.attr ('data-action') + ' ...');
    i.removeClass ('icon-play icon-stop');

    $.post (this.href, function () { location.reload (); });
    return false;
  };

  $('.app-mod, .app-all').click (f);
});
