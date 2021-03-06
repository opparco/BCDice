# frozen_string_literal: true

module BCDice
  module GameSystem
    class Chill < Base
      # ゲームシステムの識別子
      ID = 'Chill'

      # ゲームシステム名
      NAME = 'Chill'

      # ゲームシステム名の読みがな
      SORT_KEY = 'ちる'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・ストライク・ランク　(SRx)
        　"SRストライク・ランク"の形で記入します。
        　ストライク・ランク・チャートに従って自動でダイスロールを行い、
        　負傷とスタミナロスを計算します。
        　ダイスロールと同様に、他のプレイヤーに隠れてロールすることも可能です。
        　例）SR7　　　sr13　　　SR(7+4)　　　Ssr10
      INFO_MESSAGE_TEXT

      register_prefix(['SR\d+.*'])

      def check_1D100(total, _dice_total, cmp_op, target)
        return '' if target == '?'
        return '' if cmp_op != :<=

        if total >= 100
          " ＞ ファンブル"
        elsif total > target
          " ＞ 失敗"
        elsif total >= (target * 0.9)
          " ＞ Ｌ成功"
        elsif total >= (target / 2)
          " ＞ Ｍ成功"
        elsif total >= (target / 10)
          " ＞ Ｈ成功"
        else
          " ＞ Ｃ成功"
        end
      end

      def rollDiceCommand(command)
        roll_strike_rank_result(command)
      end

      def roll_strike_rank_result(string)
        debug('strike_rank begin string', string)

        wounds = 0
        sta_loss = 0
        dice = ''
        dice_add = ""
        dice_str = ""

        unless /(^|\s)[sS]?(SR|sr)(\d+)($|\s)/ =~ string
          debug('invalid string', string)
          return "1"
        end

        strikeRank = Regexp.last_match(3).to_i

        if strikeRank < 14
          sta_loss, dice, dice_add, dice_str = check_strike_rank(strikeRank)
          wounds, dice_w, dice_wa, dice_ws = check_strike_rank(strikeRank - 3)
          dice = dice + ', ' + dice_w
          dice_add += ', ' + dice_wa
          dice_str = dice_str + ', ' + dice_ws
        else
          sta_loss, _dice, dice_add, dice_str = check_strike_rank(13)

          dice_list = @randomizer.roll_barabara(4, 10)
          wounds = dice_list.sum()
          dice_ws = dice_list.join(",")

          dice = '5d10*3, 4d10+' + ((strikeRank - 13) * 2).to_s + 'd10'
          dice_add += ', ' + wounds.to_s
          dice_str = "#{dice_str}, #{dice_ws}"

          dice_list = @randomizer.roll_barabara((strikeRank - 13) * 2, 10)
          wounds_wk = dice_list.sum()
          dice_ws = dice_list.join(",")

          dice_str += "+#{dice_ws}"
          dice_add += "+#{wounds_wk}"
          wounds += wounds_wk
        end

        output = "#{dice_str} ＞ #{dice_add} ＞ スタミナ損失#{sta_loss}, 負傷#{wounds}"

        string += ':' + dice

        if output.empty?
          return "1"
        end

        output = "(#{string}) ＞ #{output}"
        debug('strike_rank end output', output)

        return output
      end

      def check_strike_rank(strikeRank)
        strikeRank = strikeRank.to_i

        dice = ''
        dice_add = ''
        dice_str = ''
        damage = 0

        if strikeRank < 1
          damage = 0
          dice_str = '-'
          dice_add = '-'
          dice = '-'

        elsif strikeRank < 2
          dice = '0or1'
          damage = @randomizer.roll_once(2)
          dice_str = damage.to_s

          damage -= 1
          dice_add = damage.to_s
        elsif strikeRank < 3
          dice = '1or2'
          damage = @randomizer.roll_once(2)
          dice_str = damage.to_s
          dice_add = damage.to_s
        elsif strikeRank < 4
          dice = '1d5'
          damage = @randomizer.roll_once(5)
          dice_str = damage.to_s
          dice_add = damage.to_s
        elsif strikeRank < 10
          dice = (strikeRank - 3).to_s + 'd10'
          dice_list = @randomizer.roll_barabara(strikeRank - 3, 10)
          damage = dice_list.sum()
          dice_add = damage.to_s
          dice_str = dice_list.join(",")
        elsif strikeRank < 13
          dice = (strikeRank - 6).to_s + 'd10*2'
          dice_list = @randomizer.roll_barabara(strikeRank - 6, 10)
          total = dice_list.sum()
          dice_add = "#{total}*2"
          damage = total * 2
          dice_str = "(#{dice_list.join(',')})*2"
        else
          dice = '5d10*3'
          dice_list = @randomizer.roll_barabara(5, 10)
          total = dice_list.sum()
          dice_add = "#{total}*3"
          damage = total * 3
          dice_str = "(#{dice_list.join(',')})*3"
        end

        return damage, dice, dice_add, dice_str
      end
    end
  end
end
