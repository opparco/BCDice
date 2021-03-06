# frozen_string_literal: true

module BCDice
  module GameSystem
    class Nechronica_Korean < Base
      # ゲームシステムの識別子
      ID = 'Nechronica:Korean'

      # ゲームシステム名
      NAME = '네크로니카'

      # ゲームシステム名の読みがな
      SORT_KEY = '国際化:Korean:네크로니카'

      # ダイスボットの使い方
      HELP_MESSAGE = <<~INFO_MESSAGE_TEXT
        ・판정　(nNC+m)
        　주사위 수n、수정치m으로 판정굴림을 행합니다.
        　주사위 수가 2개 이상일 때에 파츠파손 수도 표시합니다.
        ・공격판정　(nNA+m)
        　주사위 수n、수정치m으로 공격판정굴림을 행합니다.
        　명중부위와 주사위 수가 2개 이상일 때에 파츠파손 수도 표시합니다.
      INFO_MESSAGE_TEXT

      register_prefix(['\d+NC.*', '\d+NA.*', '\d+R10.*'])

      def initialize
        super

        @sort_add_dice = true
        @sort_barabara_dice = true
        @default_target_number = 6 # 목표치가 딱히 없을때의 난이도
      end

      def replace_text(string)
        string = string.gsub(/(\d+)NC(10)?([\+\-][\+\-\d]+)/i) { "#{Regexp.last_match(1)}R10#{Regexp.last_match(3)}[0]" }
        string = string.gsub(/(\d+)NC(10)?/i) { "#{Regexp.last_match(1)}R10[0]" }
        string = string.gsub(/(\d+)NA(10)?([\+\-][\+\-\d]+)/i) { "#{Regexp.last_match(1)}R10#{Regexp.last_match(3)}[1]" }
        string = string.gsub(/(\d+)NA(10)?/i) { "#{Regexp.last_match(1)}R10[1]" }

        return string
      end

      def check_nD10(total, _dice_total, dice_list, cmp_op, target)
        return '' if target == '?'
        return '' unless cmp_op == :>=

        if total >= 11
          " ＞ 대성공"
        elsif total >= target
          " ＞ 성공"
        elsif dice_list.count { |i| i <= 1 } == 0
          " ＞ 실패"
        elsif dice_list.size > 1
          " ＞ 대실패 ＞ 사용파츠 전부 손실"
        else
          " ＞ 대실패"
        end
      end

      def rollDiceCommand(string)
        string = replace_text(string)

        debug("nechronica_check string", string)

        unless /(^|\s)S?((\d+)[rR]10([\+\-\d]+)?(\[(\d+)\])?)(\s|$)/i =~ string
          debug("nechronica_check unmuched")
          return nil
        end

        string = Regexp.last_match(2)

        dice_n = 1
        dice_n = Regexp.last_match(3).to_i if Regexp.last_match(3)

        battleMode = Regexp.last_match(6).to_i

        modText = Regexp.last_match(4)
        mod = ArithmeticEvaluator.eval(modText)

        # 0=판정모드, 1=전투모드
        isBattleMode = (battleMode == 1)
        debug("nechronica_check string", string)
        debug("isBattleMode", isBattleMode)

        diff = 6

        dice = @randomizer.roll_barabara(dice_n, 10).sort
        n_max = dice.max

        total_n = n_max + mod

        output = "(#{string}) ＞ [#{dice.join(',')}]"
        if mod < 0
          output += mod.to_s
        elsif mod > 0
          output += "+#{mod}"
        end

        n1 = 0
        cnt_max = 0

        dice.length.times do |i|
          dice[i] += mod
          n1 += 1 if dice[i] <= 1
          cnt_max += 1 if dice[i] >= 10
        end

        dice_str = dice.join(",")
        output += "  ＞ #{total_n}[#{dice_str}]"

        dice_total = dice.inject(&:+)
        output += check_nD10(total_n, dice_total, dice, :>=, diff)

        debug("dice_n, n1, total_n diff", dice_n, n1, total_n, diff)

        # β판의 실장
        #    if( (dice_n > 1) and (n1 >= 1) and (total_n <= diff) )
        #      output += " ＞ 파손#{n1}"
        #    end

        if isBattleMode
          hit_loc = getHitLocation(total_n)
          if hit_loc != '1'
            output += " ＞ #{hit_loc}"
          end
        end

        return output
      end

      def getHitLocation(dice)
        output = '1'

        debug("getHitLocation dice", dice)
        return output if dice <= 5

        table = [
          '방어측 임의',
          '다리（없으면 공격측 임의）',
          '몸통（없으면 공격측 임의）',
          '팔（없으면 공격측 임의）',
          '머리（없으면 공격측 임의）',
          '공격측 임의',
        ]
        index = dice - 6

        addDamage = ""
        if dice > 10
          index = 5
          addDamage = "(추가 데미지#{dice - 10})"
        end

        output = table[index] + addDamage

        return output
      end
    end
  end
end
