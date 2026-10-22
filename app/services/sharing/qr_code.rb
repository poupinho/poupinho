module Sharing
  # Matriz do QR code que vai impressa no card compartilhável.
  #
  # O desenho acontece no canvas do navegador, junto com o resto do card, então
  # aqui só geramos os módulos (os quadradinhos) e os entregamos numa string
  # compacta: uma linha por linha da matriz, "1" para módulo preto.
  class QrCode
    # Nível médio de correção de erro: aguenta o QR aparecer torto ou cortado na
    # foto do story sem inchar a matriz como o nível alto faria.
    LEVEL = :m

    attr_reader :url

    def self.call(url)
      new(url).call
    end

    def initialize(url)
      @url = url
    end

    def call
      rows.map { |row| row.map { |dark| dark ? "1" : "0" }.join }.join(" ")
    end

    private

    def rows
      qr = RQRCodeCore::QRCode.new(url, level: LEVEL)
      size = qr.module_count
      Array.new(size) { |row| Array.new(size) { |col| qr.checked?(row, col) } }
    end
  end
end
