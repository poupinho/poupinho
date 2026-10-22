require "test_helper"

class Sharing::QrCodeTest < ActiveSupport::TestCase
  test "returns one string per row, all the same length, only zeros and ones" do
    rows = Sharing::QrCode.call("https://poupinho.com.br/qr").split(" ")

    assert rows.size >= 21, "matriz menor que o menor QR possível"
    assert_equal [ rows.size ], rows.map(&:length).uniq, "a matriz precisa ser quadrada"
    assert_equal [ "0", "1" ], rows.join.chars.uniq.sort
  end

  test "draws the three finder patterns, which is what the camera looks for" do
    rows = Sharing::QrCode.call("https://poupinho.com.br/qr").split(" ")
    size = rows.size

    # O olho do QR é um quadrado 7x7 com borda preta em cada canto menos o inferior direito.
    [ [ 0, 0 ], [ 0, size - 7 ], [ size - 7, 0 ] ].each do |row, col|
      assert_equal "1" * 7, rows[row][col, 7], "olho faltando em (#{row}, #{col})"
      assert_equal "1", rows[row + 3][col + 3], "centro do olho em (#{row}, #{col})"
      assert_equal "0", rows[row + 1][col + 1], "anel branco do olho em (#{row}, #{col})"
    end
  end

  test "a longer url needs a denser matrix" do
    short = Sharing::QrCode.call("https://poupinho.com.br/qr").split(" ").size
    long = Sharing::QrCode.call("https://poupinho.com.br/?utm_source=share_card&utm_medium=qrcode&utm_campaign=poupinho").split(" ").size

    assert long > short, "a URL curta existe justamente para manter o QR simples"
  end
end
