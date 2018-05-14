require 'mochila/mochila'

class MochilaController < ApplicationController
  def index
    render 'index'
  end

  def gerar_mochila
    @resultado, @tabela = Mochila::Mochila.tabela(params[:capacidade], params[:pesos], params[:valores])

    render 'mochila'
  end
end
