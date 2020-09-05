module BCDice
  module DiceTable
    # D66を振って出目を昇順/降順にして表を参照する
    class D66Table
      # @param [String] name 表の名前
      # @param [Symbol] sort_type 出目入れ替えの方式 :asc or :desc
      # @param [Hash] items 表の項目 Key は数値
      def initialize(name, sort_type, items)
        @name = name
        @sort_type = sort_type
        @items = items.freeze
      end

      # 表を振る
      # @param randomizer [#roll_barabara] ランダマイザ
      # @return [String] 結果
      def roll(randomizer)
        dice = randomizer.roll_barabara(2, 6)

        dice.sort!
        if @sort_type == :desc
          dice.reverse!
        end

        key = dice[0] * 10 + dice[1]
        return "#{@name}(#{key}) ＞ #{@items[key]}"
      end
    end
  end
end
