require File.join(File.dirname(__FILE__),'test_helper.rb')

class TestBancoBanespa < Test::Unit::TestCase #:nodoc:[all]

  def setup
    @boleto_novo = BancoBanespa.new
    @boleto_novo.cedente = "Kivanio Barbosa"
    @boleto_novo.documento_cedente = "12345678912"
    @boleto_novo.sacado = "Claudio Pozzebom"
    @boleto_novo.sacado_documento = "12345678900"
    @boleto_novo.aceite = "S"
    @boleto_novo.agencia = "400"
    @boleto_novo.conta_corrente = "61900"
  end

  def boleto_1
    @boleto_novo.agencia = "400"
    @boleto_novo.conta_corrente = "0403005"
    @boleto_novo.moeda = "9"
    @boleto_novo.valor = 103.58
    @boleto_novo.numero_documento = "0004952"
    @boleto_novo.data_documento = Date.parse("2001-08-01")
    @boleto_novo.dias_vencimento = 0
    @boleto_novo.codigo_do_cedente = 14813026478
  end

  def boleto_nil
    @boleto_novo.banco = ""
    @boleto_novo.carteira = ""
    @boleto_novo.moeda = ""
    @boleto_novo.valor = 0
    @boleto_novo.convenio = ""
    @boleto_novo.numero_documento = ""
    @boleto_novo.data_documento = Date.parse("2008-02-01")
    @boleto_novo.dias_vencimento = 0
  end

  def test_should_initialize_correctly
    assert_equal '033', @boleto_novo.banco
    assert_equal 'COB', @boleto_novo.carteira
    assert_equal "DM", @boleto_novo.especie_documento
    assert_equal "R$", @boleto_novo.especie
    assert_equal "9", @boleto_novo.moeda
    assert_equal Date.today, @boleto_novo.data_documento
    assert_equal 1, @boleto_novo.dias_vencimento
    assert_equal((Date.today + 1), @boleto_novo.data_vencimento)
    assert_equal "S", @boleto_novo.aceite
    assert_equal 1, @boleto_novo.quantidade
    assert_equal 0.0, @boleto_novo.valor
    assert_equal 0.0, @boleto_novo.valor_documento
    assert_equal "QUALQUER BANCO ATÉ O VENCIMENTO", @boleto_novo.local_pagamento
  end

  def test_should_verify_nosso_numero_dv_calculation
    @boleto_novo.agencia = "400"
    @boleto_novo.numero_documento = "0403005"
    assert_equal 6, @boleto_novo.nosso_numero_dv
    @boleto_novo.numero_documento = "403005"
    assert_equal 6, @boleto_novo.nosso_numero_dv
    @boleto_novo.numero_documento = "1234567"
    assert_equal 8, @boleto_novo.nosso_numero_dv
    @boleto_novo.agencia = "123"
    assert_equal 0, @boleto_novo.nosso_numero_dv
  end

  def test_should_mont_correct_campo_livre_com_dv1_e_dv2
    @boleto_novo.codigo_do_cedente = "40013012168"
    @boleto_novo.numero_documento = "7469108"
    assert_equal "4001301216874691080003384", @boleto_novo.campo_livre_com_dv1_e_dv2
  end

  def test_should_mont_correct_codigo_barras
    boleto_1
    assert_equal "0339139400000103581481302647800049520003306", @boleto_novo.monta_codigo_43_digitos
    assert_equal "03398139400000103581481302647800049520003306", @boleto_novo.codigo_barras
    boleto_nil
    assert_equal nil, @boleto_novo.codigo_barras
    assert_raise RuntimeError do
      boleto_nil
      raise 'Verifique as informações do boleto!!!'
    end
  end

  def test_should_mont_correct_linha_digitalvel
    boleto_1
    assert_equal("03391.48132 02647.800040 95200.033066 8 13940000010358", @boleto_novo.codigo_barras.linha_digitavel)
  end

end

