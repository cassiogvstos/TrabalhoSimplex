module Simplex

    class Simplex

        def self.executar(acao, expressao, restricoes = [], maxvoltas = 0)
            matrizes = []
            voltas = 0

            matrizes << matriz(acao, expressao, restricoes)

            while condicao_parada(matrizes[-1][-1])
                if matrizes[-1][-1][-1] == nil
                    return matrizes
                end

                voltas += 1

                if voltas > maxvoltas
                    return matrizes
                end

                m = copiar_matriz(matrizes[-1])

                matrizes << simplex(m)
            end

            ultima_matriz = copiar_matriz(matrizes[-1])

            valores_restricao = []

            ultima_matriz[1...-1].each do |array|
                if array[0] =~ /f.*/
                    valores_restricao[array[0].gsub(/\D/, '').to_i - 1] = array[-1]
                end
            end

            folga_idxs = []
            folga_valores  = []

            @folgas.each do |valor|
                folga_idxs << ultima_matriz[0].find_index(valor)
                folga_valores << ultima_matriz[-1][ultima_matriz[0].find_index(valor)].round(3)
            end

            folga_idxs << -1

            variaveis_limite_restricao = []

            folga_idxs.each_with_index do |br_val, br_idx|
                variaveis_limite_restricao << []

                ultima_matriz[1...-1].each_with_index do |array, idx|
                    variaveis_limite_restricao[br_idx] << array[br_val].round(3)
                end
            end

            matrizes << sensibilidade(ultima_matriz, valores_restricao, folga_valores, variaveis_limite_restricao)

            matrizes << variaveis_basicas(ultima_matriz)
            matrizes << variaveis_nao_basicas(ultima_matriz)

            return matrizes
        end

        def self.matriz(acao, expressao, restricoes = [])
            restricoes = restricoes.compact.reject(&:blank?)

            expressao = expressao.gsub(/[\s\*]/, '').strip

            restricoes.map do |r|
                r.gsub!(/[\s\*]/, '').strip!
            end

            valores = expressao.scan(/\-*\w*\,*\.*\w+/)
            variaveis = expressao.scan(/[a-zA-Z]\d*/)

            folgas = []
            restricoes.each_with_index do |restricao, i|
                folgas << "f#{i + 1}"
            end

            @folgas = folgas.clone
            @variaveis = variaveis.clone

            matriz = []
            matriz << ['Linha'] + variaveis + folgas + ['b']

            (folgas.size + 1).times do |i|
                matriz << Array.new(matriz[0].size) { |el| 0.to_f }
            end

            folgas.each_with_index do |folga, i|
                matriz[i + 1][0] = folga
            end

            if acao == 'max'
                matriz.last[0] = 'z'
            else
                matriz.last[0] = '-z'
            end

            valores.each_with_index do |valor, i|
                val = valor.match(/(^*-*\d*\,*\.*\d*)[a-zA-Z].*/)[1]

                val.gsub!(/\,/, '.')

                if val.empty?
                    val = 1.0
                elsif val == '-'
                    val = -1.0
                else
                    val = val.to_f
                end

                if acao == 'max'
                    matriz.last[i + 1] = val * -1
                else
                    matriz.last[i + 1] = val
                end
            end

            @valores_ultima_col = []

            restricoes.each_with_index do |restricao, i|
                posicao = matriz[0].find_index("f#{i + 1}")
                matriz[i + 1][posicao] = 1.to_f

                valor_restricao = restricao.match(/\d+$/)[0].to_f

                matriz[i+1][-1] = valor_restricao
                @valores_ultima_col << valor_restricao

                variaveis.each do |variavel|
                    if restricao.match(/.*#{variavel}.*/)
                        posicao = matriz[0].find_index(variavel)
                        elemento = restricao.match(/(^*-*\d*\,*\.*\d*)#{variavel}.*/)[1]

                        elemento.gsub!(/\,/, '.')

                        if elemento.empty?
                            matriz[i+1][posicao] = 1.to_f
                        elsif elemento == '-'
                            matriz[i+1][posicao] = -1.to_f
                        else
                            matriz[i+1][posicao] = elemento.to_f
                        end
                    end

                end
            end

            matriz
        end

        def self.condicao_parada(linha_z = [])
            linha_z[1..-1].each do |z|
                if z < 0
                    return true
                end
            end

            false
        end

        def self.copiar_matriz(matriz)
            copy = matriz.map do |elemento|
                elemento.map do |e|
                    if e.class == Float
                        e
                    else
                        e.dup
                    end
                end
            end
        end

        def self.simplex(matriz = [])
            entrada = matriz.last[1..-1].min
            entrada_idx = matriz.last.find_index(entrada)

            entrada_coluna = matriz[1..-1].map do |linha|
                linha[entrada_idx] if linha[entrada_idx] > 0
            end

            if condicao_parada_coluna(entrada_coluna.clone)
                matriz[-1][-1] = nil

                return matriz
            end

            saida = nil
            saida_idx = nil

            matriz[1..-1].each_with_index do |linha, idx|
                if entrada_coluna[idx] != nil
                    saida ||= linha[-1] / entrada_coluna[idx]
                    saida_idx ||= idx + 1

                    if saida > linha[-1] / entrada_coluna[idx]
                        saida = linha[-1] / entrada_coluna[idx]
                        saida_idx = idx + 1
                    end
                end
            end

            matriz[saida_idx][0] = matriz[0][entrada_idx]

            pivo = matriz[saida_idx][entrada_idx]

            matriz[saida_idx][1..-1].each_with_index do |valor, i|
                matriz[saida_idx][i + 1] = valor / pivo
            end

            matriz[1..-1].each_with_index do |linha, i|
                if i != saida_idx -1
                    virar_zero = linha[entrada_idx]

                    matriz[saida_idx][1..-1].each_with_index do |elemento, j|
                        linha[j + 1] = elemento * (virar_zero * - 1) + linha[j + 1]
                    end
                end
            end

            matriz
        end

        def self.condicao_parada_coluna(coluna = [])
            coluna.each_with_index do |col, i|
                if col != nil
                    if col <= 0
                        coluna[i] = nil
                    end
                end
            end

            coluna.compact!
            coluna.empty?
        end

        def self.sensibilidade(matriz = [], valores_restricao = [], folga_valores = [], variaveis_limite_restricao = [])
            sensibilidade = []
            sensibilidade << ['Sensibilidade', 'Preço sombra', 'Limite', 'Valor']

            matriz[1...-1].size.times do |idx|
                sensibilidade << Array.new(4) { |el| "r#{idx+1}" }
            end

            limites = []

            variaveis_limite_restricao[0...-1].each_with_index do |array, idx|
                limites << []
                limites_valores = []

                array.each_with_index do |valor, valor_idx|
                    if valor != 0
                        limites_valores << (variaveis_limite_restricao[-1][valor_idx] * -1 / valor).round(0)
                    end
                end

                limites[idx] << limites_valores.max
                limites[idx] << limites_valores.min
            end

            sensibilidade[1..-1].each_with_index do |array, idx|
                array[1] = folga_valores[idx]

                if valores_restricao[idx] == nil
                    array[-1] = @valores_ultima_col[idx]
                else
                    array[-1] = @valores_ultima_col[idx] - valores_restricao[idx]
                end

                if array[1] != 0
                    array[2] = "#{array[-1] + limites[idx].min} - #{array[-1] + limites[idx].max}"
                else
                    array[2] = '-'
                end
            end

            sensibilidade
        end

        def self.variaveis_basicas(matriz = [])
            basicas = []

            basicas << ['Variável', 'Valor']

            matriz[1...-1].each_with_index do |linha, idx|
                basicas << [linha[0], linha[-1]]
            end

            basicas
        end

        def self.variaveis_nao_basicas(matriz = [])
            basicas = variaveis_basicas(matriz)[1..-1]
            nao_basicas = []

            nao_basicas << ['Variável', 'Valor']

            variaveis = @variaveis.clone
            folgas = @folgas.clone

            dentro = []

            basicas.each_with_index do |basica, idx|
                dentro << basica[0]
            end

            (variaveis + folgas).each do |el|
                if ! dentro.include?(el)
                    nao_basicas << [el, 0.to_f]
                end
            end

            nao_basicas
        end
    end

end
