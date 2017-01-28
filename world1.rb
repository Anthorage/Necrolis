require_relative 'world'


class World1 < World

    def update(dt) 
        super(dt)
        game_logic(dt)

        @wavesys.update(dt)
    end

    def load
        super

        reg = @regions["hstart"]
        targ = @regions["target"]
        @wavesys = self.create_wave_system(reg, PlayerMaster::P2, 1.0, targ.centerx, targ.centery)
        @wavesys.summon!

        self.set_message("Start")
    end

end
