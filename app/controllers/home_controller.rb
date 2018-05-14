require 'simplex/simplex'

class HomeController < ApplicationController
  def index
  end

  def gerar_simplex
    @matriz = Simplex::Simplex.executar(params[:acao], params[:expr], params[:restr], Integer(params[:maxvoltas]))

    render 'simplex'
  end
end
