require_relative 'pieces'

class Board
  def initialize(fill_board = true)
    make_starting_grid(fill_board)
  end

  def [](pos)
    raise 'invalid pos' unless valid_pos?(pos)

    i, j = pos
    @rows[i][j]
  end

  def []=(pos, piece)
    raise 'invalid pos' unless valid_pos?(pos)

    i, j = pos
    @rows[i][j] = piece
  end

  def add_piece(piece, pos)
    raise 'position not empty' unless empty?(pos)

    self[pos] = piece
  end

  def checkmate?(color)
    return false unless in_check?(color)

    pieces.select { |p| p.color == color }.all? do |piece|
      piece.valid_moves.empty?
    end
  end

  def dup
    new_board = Board.new(false)

    pieces.each do |piece|
      piece.class.new(piece.color, new_board, piece.pos)
    end

    new_board
  end

  def empty?(pos)
    self[pos].nil?
  end

  def in_check?(color)
    king_pos = find_king(color).pos
    pieces.any? do |p|
      p.color != color && p.moves.include?(king_pos)
    end
  end

  def move_piece(turn_color, from_pos, to_pos)
    raise 'from position is empty' if empty?(from_pos)

    piece = self[from_pos]
    if piece.color != turn_color
      raise 'move your own piece'
    elsif !piece.moves.include?(to_pos)
      raise 'piece does not move like that'
    elsif !piece.valid_moves.include?(to_pos)
      raise 'cannot move into check'
    end

    move_piece!(from_pos, to_pos)
  end

  # move without performing checks
  def move_piece!(from_pos, to_pos)
    piece = self[from_pos]
    raise 'piece cannot move like that' unless piece.moves.include?(to_pos)

    self[to_pos] = piece
    self[from_pos] = nil
    piece.pos = to_pos

    nil
  end

  def pieces
    @rows.flatten.compact
  end

  def render
    @rows.map do |row|
      row.map do |piece|
        piece.nil? ? '.' : piece.render
      end.join
    end.join('\n')
  end

  def valid_pos?(pos)
    pos.all? { |coord| coord.between?(0, 7) }
  end

  protected

  def fill_back_row(color)
    back_pieces = [
      Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook
    ]

    i = (color == :white) ? 7 : 0
    back_pieces.each_with_index do |piece_class, j|
      piece_class.new(color, self, [i, j])
    end
  end

  def fill_pawns_row(color)
    i = (color == :white) ? 6 : 1
    8.times { |j| Pawn.new(color, self, [i, j]) }
  end

  def find_king(color)
    king_pos = pieces.find { |p| p.color == color && p.is_a?(King) }
    king_pos || (raise 'king not found?')
  end

  def make_starting_grid(fill_board)
    @rows = Array.new(8) { Array.new(8) }
    return unless fill_board
    [:white, :black].each do |color|
      fill_back_row(color)
      fill_pawns_row(color)
    end
  end
end
