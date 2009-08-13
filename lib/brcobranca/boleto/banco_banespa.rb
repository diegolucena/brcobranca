# Banco BANESPA
class BancoBanespa < Brcobranca::Boleto::Base

  #Código do cedente (Somente 11 digitos) fornecido pela agência.
  attr_accessor :codigo_do_cedente

  def initialize(campos={})
    padrao = {:carteira => "COB", :banco => "033"}
    campos = padrao.merge!(campos)
    super(campos)
  end


  # Posição 	Conteúdo
	# 1 a 3    Número do banco
	# 4        Código da Moeda - 9 para Real ou 8 - outras moedas
	# 5 		Dígito de auto-conferência
	# 6 a 9    Fator vencimento
	# 10 a 19  Valor do título (10 posições)
	# 20 a 30  Código do cedente
	# 31 a 37  Nosso numero (7 digitos)
	# 38 a 39  Zeros
	# 40 a 42  033 (Código do banco)
	# 43		1º Dígito verificador
	# 44		2º Dígito verificador
  def monta_codigo_43_digitos

    banco = self.banco.zeros_esquerda(:tamanho => 3)
    fator = self.data_vencimento.fator_vencimento.zeros_esquerda(:tamanho => 4)
    valor_documento = self.valor_documento.limpa_valor_moeda.zeros_esquerda(:tamanho => 10)
    campo_livre_com_dv1_e_dv2 = self.campo_livre_com_dv1_e_dv2

    "#{banco}#{self.moeda}#{fator}#{valor_documento}#{campo_livre_com_dv1_e_dv2}"
  end

  def nosso_numero
    "#{self.agencia.zeros_esquerda(:tamanho => 3)} #{self.numero_documento.zeros_esquerda(:tamanho => 7)} #{self.nosso_numero_dv}"
  end

  def nosso_numero_dv
    fatores = [7,3,1,9,7,3,1,9,7,3]
    nosso_numero_sem_dv = "#{self.agencia.zeros_esquerda(:tamanho => 3)}#{self.numero_documento.zeros_esquerda(:tamanho => 7)}"
    total = 0
    posicao = 0
    nosso_numero_sem_dv.split(//).each do |digito|
      total += (digito.to_i * fatores[posicao]).to_s.split(//)[-1].to_i
      posicao += 1
    end
    dv = 10 - total.to_s.split(//)[-1].to_i
    dv == 10 ? 0 : dv
  end

    #campo livre sem digitos verificadores formado por
    #Código do cedente,
    #Numero sequencial do documento
    #(Zeros)
    #banco (033)
  def campo_livre
    return "#{self.codigo_do_cedente.zeros_esquerda(:tamanho => 11)}#{self.numero_documento.zeros_esquerda(:tamanho => 7)}00#{self.banco}"
  end


  def campo_livre_com_dv1_e_dv2
   dv1 = self.campo_livre.modulo10 #dv 1 inicial
    dv2 = nil
    multiplicadores = [2,3,4,5,6,7]
    begin
      recalcular_dv2 = false
      valor_inicial = "#{self.campo_livre}#{dv1}"
      total = 0
      multiplicador_posicao = 0

      valor_inicial.split(//).reverse!.each do |caracter|
        multiplicador_posicao = 0 if (multiplicador_posicao == 6)
        total += (caracter.to_i * multiplicadores[multiplicador_posicao])
        multiplicador_posicao += 1
      end

      case total % 11
      when 0 then
          dv2 = 0
      when 1 then
          if dv1 == 9
            dv1 = 0
          else
            dv1 += 1
          end
          recalcular_dv2 = true
      else
          dv2 = 11 - (total % 11)
      end
    end while(recalcular_dv2)

    return "#{self.campo_livre}#{dv1}#{dv2}"
  end

end

