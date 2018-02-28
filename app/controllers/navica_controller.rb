class NavicaController < ApplicationController

  def index
    @listings = Navica.where
  end
end
