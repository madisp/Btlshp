module GamesHelper
  def log(who, x, y, result)
    "<b>#{h who}</b> fired at #{h x}, #{h y} and <b>#{h result}</b>".html_safe
  end
end
