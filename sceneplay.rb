require_relative 'scene'
require_relative 'world1'

class ScenePlay < Scene
    ENERGY_SUMMON_BASE = 25

    def can_use_energy?
        return PlayerMaster.PLAYER_1.energy > ENERGY_SUMMON_BASE
    end

    def button_down(bt)
        if bt == Gosu::MsLeft
            @world.unselect_all()
        elsif bt == Gosu::MsRight
            @world.selected.each {|u| u.travel(@world.camerax+@game.mouse_x, @world.cameray+@game.mouse_y)}
        elsif bt == Gosu::KbEscape
            @game.end_game
        elsif bt == Gosu::KbSpace
            @slowed = !@slowed
            @time_mult = @slowed? 0.5 : 1.0
        elsif bt == Gosu::KbS
            if @selected_summon == nil
                summ = @world.get_summon_by_pos(0)
                if summ != nil
                    @selected_summon = UnitMaster.get.bring(summ)
                    #@world.unselect_all()
                end
            else
                @selected_summon = nil
            end
        elsif bt == Gosu::KbH
            @world.swap_message()
        end

        if @selected_summon != nil
            if bt == Gosu::Kb1
                @selected_summon = UnitMaster.get.bring(@world.get_summon_by_pos(0))
            elsif bt == Gosu::Kb2
                @selected_summon = UnitMaster.get.bring(@world.get_summon_by_pos(1))
            end
        end
    end

    def update(dt)
        @world.update(dt * @time_mult)


        if @selected_summon != nil
            if !@world.can_summon?(@selected_summon.id)
                @selected_summon = nil
            elsif Gosu::button_down?(Gosu::MsLeft)
                res = true
                @world.units.each do |un|
                    if un.contains?(@game.mouse_x + @world.camerax, @game.mouse_y + @world.cameray)
                        res = false
                        break
                    end
                end

                if res && @world.summonable_pos?(@game.mouse_x + @world.camerax, @game.mouse_y + @world.cameray) && PlayerMaster.PLAYER_1.energy >= @selected_summon.energy_cost+ENERGY_SUMMON_BASE && PlayerMaster.PLAYER_1.corpses >= @selected_summon.corpses_cost
                    newun = @world.create_unit(@game.mouse_x + @world.camerax, @game.mouse_y + @world.cameray, @selected_summon, PlayerMaster::P1)
                    PlayerMaster.PLAYER_1.energy -= @selected_summon.energy_cost
                    PlayerMaster.PLAYER_1.corpses -= @selected_summon.corpses_cost
                    @world.select(newun)
                end
            end
        else
            if Gosu::button_down?(Gosu::MsLeft)
                @world.units.each do |u|
                    if u.player.pid == PlayerMaster::P1 && u.rect.contains?( @world.camerax+@game.mouse_x, @world.cameray+@game.mouse_y )
                        @world.select( u )
                    end
                end
            end
        end

        @world.restart() if @world.lost?
    end

    def draw
        ener = PlayerMaster.PLAYER_1.energy
        corp = PlayerMaster.PLAYER_1.corpses
        @world.draw()

        if ener > ENERGY_SUMMON_BASE
            @scenefont.draw_rel( "Energy: #{ener}", @game.width*0.2, 4, ZOrder::UI, 0.5, 0 )
        else
            @scenefont.draw_rel( "Energy: #{ener}", @game.width*0.2, 4, ZOrder::UI, 0.5, 0, 1, 1, Gosu::Color::RED )
        end

        @scenefont.draw_rel( "Corpses: #{corp}", @game.width*0.8, 4, ZOrder::UI, 0.5, 0 )

        if @selected_summon != nil
            @world.unit_texture[ @selected_summon.graphid ].draw_rot( @game.mouse_x, @game.mouse_y, ZOrder::SUMMONS, 0, 0.5, 0.5, @world.zoom_x, @world.zoom_y )
        end

    end

    def initialize(game)
        super "PLAY", game

        PlayerMaster.get.setup()
        UnitMaster.get.setup()
        
        @world = World1.new("Coward's Reign", "map1.json", "map1.txt", self)
        @world.load()
        @time_mult = 1.00
        @slowed = false
        @selected_summon = nil

        @scenefont = Gosu::Font.new(24)
    end

end
