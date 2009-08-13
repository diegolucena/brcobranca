# Banco BANESPA
class BancoBanespa < Brcobranca::Boleto::Base

  #Código do cedente (Somente 11 digitos) fornecido pela agência.
  attr_accessor :codigo_do_cedente

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
    campo_livre_com_dv1_e_dv2 = self.campo_livre_com_dv1_e_dv2
    "#{banco}#{self.moeda}#{fator}#{valor_documento}#{campo_livre_com_dv1_e_dv2}"
  end

  # Número sequencial utilizado para distinguir os boletos na agência
  def nosso_numero
    "#{self.agencia.zeros_esquerda(:tamanho => 3)} #{self.numero_documento.zeros_esquerda(:tamanho => 7)} #{self.nosso_numero_dv}"
  end

  # Retorna dígito verificador do nosso número calculado como contas na documentação
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


    #campo livre sem digitos verificadores formado pelo código do cedente, numero sequencial do documento
    # 00 (Zeros) e o banco (033)
  def campo_livre
    return "#{self.codigo_do_cedente.zeros_esquerda(:tamanho => 11)}#{self.numero_documento.zeros_esquerda(:tamanho => 7)}00#{self.banco}"
  end

  #restorna o código do cedente formatado como sera impresso no boleto_
  def codigo_cedente
    return "#{codigo_do_cedente[0..2]} #{codigo_do_cedente[3..4]} #{codigo_do_cedente[5..10]} #{codigo_do_cedente[11..11]}"
  end

  #campo livre com os digitos verificadores como conta na documentação do banco
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

