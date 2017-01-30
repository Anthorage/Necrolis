require_relative 'world'


class World1 < World

    def update(dt) 
        super(dt)
        game_logic(dt)

        @wavesys.update(dt)

        if @state == 0 || @state == 1 || @state == 3
            self.next_text() if @adv_timer.update(dt)
        elsif @state == 2
            if @units.size > 0
                self.next_text()
            end
        elsif @state == 4
            if @units.size > 2
                self.next_text()
            end
        elsif @state == 5
        end
    end

    def next_text()
        @state += 1
    
        if @state == 1
            self.set_message("Base")
        elsif @state == 2
            PlayerMaster.PLAYER_1.energy += UnitMaster.get.bring(UnitMaster::SKELETON).energy_cost
            PlayerMaster.PLAYER_1.corpses += UnitMaster.get.bring(UnitMaster::SKELETON).corpses_cost
            self.add_summon( UnitMaster::SKELETON )
            self.set_message("Summon")
        elsif @state == 3
            self.set_message("Orders")
        elsif @state == 4
            self.set_message("MoreSummoning")
            PlayerMaster.PLAYER_1.energy += UnitMaster.get.bring(UnitMaster::SKELETON).energy_cost*2
            PlayerMaster.PLAYER_1.corpses += UnitMaster.get.bring(UnitMaster::SKELETON).corpses_cost*2
        else
            self.set_message("Enemies")
            @wavesys.summon!
        end
    end

    def load
        super

        reg = @regions["hstart"]
        targ = @regions["target"]
        @wavesys = self.create_wave_system(reg, PlayerMaster::P2, 1.0, targ.centerx, targ.centery)
        #@wavesys.summon!

        @state = 0
        @adv_timer = SimpleTimer.new(2, true)

        self.set_message("Start")
    end

end
