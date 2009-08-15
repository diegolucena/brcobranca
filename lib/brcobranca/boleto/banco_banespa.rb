# Banco BANESPA
class BancoBanespa < Brcobranca::Boleto::Base

  def initialize(campos={})
    padrao = {:carteira => "COB", :banco => "033"}
    campos = padrao.merge!(campos)
    super(campos)
  end


  # Responsável por montar uma String com 43 caracteres que será usado na criação do código de barras.
  def monta_codigo_43_digitos
    banco = self.banco.zeros_esquerda(:tamanho => 3)
    fator = self.data_vencimento.fator_vencimento.zeros_esquerda(:tamanho => 4)
    valor_documento = self.valor_documento.limpa_valor_moeda.zeros_esquerda(:tamanho => 10)
    campo_livre = "#{self.convenio.zeros_esquerda(:tamanho => 11)}#{self.numero_documento.zeros_esquerda(:tamanho => 7)}00#{self.banco}"
    "#{banco}#{self.moeda}#{fator}#{valor_documento}#{campo_livre}#{campo_livre.modulo11_2to7_banespa}"
  end

  # Número sequencial utilizado para distinguir os boletos na agência
  def nosso_numero
    "#{self.agencia.zeros_esquerda(:tamanho => 3)} #{self.numero_documento.zeros_esquerda(:tamanho => 7)} #{self.nosso_numero_dv}"
  end

  # Retorna dígito verificador do nosso número calculado como contas na documentação
  def nosso_numero_dv
    #Os algarismos do Número Bancário são multiplicados pelos fatores:
    #7, 3, 1, 9, 7, 3, 1, 9, 7, 3, nessa ordem
    #Somam-se os algarismos (unidades) resultantes da operação de multiplicação
    #Despreza-se a dezena do total
    #O DÍGITO VERIFICADOR será o complemento numérico para a base adotada pelo BANESPA (10).
    #Quando o resultado da soma for 10 ou múltiplo de 10, o dígito verificador será 0 (zero).
    fatores = [7,3,1,9,7,3,1,9,7,3]
    nosso_numero_sem_dv = "#{self.agencia.zeros_esquerda(:tamanho => 3)}#{self.numero_documento.zeros_esquerda(:tamanho => 7)}"
    total = 0
    posicao = 0
    nosso_numero_sem_dv.split(//).each do |digito|
      total += (digito.to_i * fatores[posicao]).to_s[-1,1].to_i
      posicao += 1
    end
    if total % 10 == 0
      return 0
    else
      return 10 - total.to_s[-1,1].to_i
    end
  end

  def agencia_codigo_cedente
    convenio = self.convenio.zeros_esquerda(:tamanho => 11)
    "#{convenio[0..2]} #{convenio[3..9]} #{convenio[10..10]}"
  end
end

