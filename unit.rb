require_relative 'entity'
require_relative 'unittype'
require_relative 'player'

require_relative 'draworder'


class Unit < CollisionEntity
    attr_reader :player, :kind, :stats, :order, :target, :home

    STAY = 0
    MOVE = 1
    ATTACK = 2

    CHECK_TIME = 0.15

    def is_moving?
        return @order == MOVE
    end

    def movement(dt)
        angle = Gosu::angle(@x, @y, @nodex, @nodey) #Math.atan2( y-@y, x-@x )

        if angle > -45 && angle < 45
            @anim = 1
        elsif angle > 45 && angle < 135
            @anim = 2
        elsif angle > 135 && angle < 225
            @anim = 0
        else
            @anim = 3
        end

        if self.move_towards( @nodex, @nodey, @stats.move_speed*dt )
            self.stop()
        end

    end

    def sqdist(other)
        return (other.x - self.x) * (other.x - self.x)  + (other.y - self.y) * (other.y - self.y)
    end

    def check_enemies(dt)
        min = nil
        mindis = 0

        @home.units.each do |un|
            if @player.is_enemy?(un.player) then
                dis = (un.x - self.x) * (un.x - self.x)  + (un.y - self.y) * (un.y - self.y) #self.sqdist(un) 
                if dis < @sight_range_squared

                    if min == nil || dis < mindis
                        min = un
                        mindis = dis
                    end
                end
            end
        end

        @target = min if min != nil
    end


    def set_order(ord)
        @order = ord
    end

    def die(killer)
        @stats.health = 0.0
        @home.unselect(self)
        @show_rect = false
        killer.player.energy += (@kind.energy_cost/2).to_i
        killer.player.corpses += @kind.corpses_cost
    end

    def is_dead?
        return @stats.health < 0.025
    end

    def is_alive?
        return @stats.health >= 0.025
    end

    def use_armor?(who)
        false
    end

    def damage_target(who, dmg)

        if use_armor?(who)
            who.stats.armor -= dmg
            dmg = who.stats.armor < 0 ? -who.stats.armor : 0
        end

        who.stats.health -= dmg

        if who.is_dead?
            who.die(self)
            self.stop(true)
        end
    end

    def target_check(dt)
        dis = self.sqdist(@target)

        if @target.is_alive? && dis < @sight_range_squared

            if dis < @range_squared
                self.set_order(ATTACK) if @order != ATTACK

                @attack_time -= dt

                if @attack_time <= 0 then
                    @attack_time = @stats.attack_speed
                    self.damage_target( @target, @stats.damage )
                end
            else
                self.travel(@target.x, @target.y, @acquire)
            end
        else
            self.stop(true)
        end
    end

    def combat(dt)
        if @order != ATTACK && @check_time <= 0.0
            @check_time = CHECK_TIME
            self.check_enemies(dt)
        end

        self.target_check(dt) if @target != nil
    end


    DEGTORAD = Math::PI/180.0

    def do_collisions(dt)
        force = 16.0

        px = 0
        py = 0

        fx = @x
        fy = @y

        collided = self.collides_group?(@home.units)

        c_cant = 0
        p_ang = 0

        collided.each do |u|
            if @player.pid == u.player.pid
                ang = ( Gosu::angle(@x, @y, u.x, u.y) + 90 ) * DEGTORAD
                c_cant += 1
                px += -force*dt*Math.cos(ang)
                py += -force*dt*Math.sin(ang)
            end
        end

        if c_cant > 0
            px /= c_cant
            py /= c_cant

            self.move_pos(-px, -py)
        end

        if !@home.walkable?( @x, @y)
            self.set_pos(fx,fy)
        end

    end

    def update(dt)
        @check_time -= dt

        self.do_collisions(dt) #if self.order != ATTACK

        self.movement(dt) if self.is_moving?

        self.combat(dt) if @acquire
    end

    def main_travel
        if @hasmain
            self.travel(@mainx, @mainy)
        end
    end

    def stop(forget=false)
        if forget
            @target = nil
            @attack_time = @stats.attack_speed
        end

        self.set_order(STAY)
        @acquire = true
        
        @nodex = @x
        @nodey = @y

        self.main_travel()
    end

    def set_main_path(x,y)
        if @home.walkable?(x,y)
            @hasmain = true
            @mainx = x
            @mainy = y
        else
            @hasmain = false
        end
    end

    def travel(x,y,acq=true)

        if @home.walkable?(x,y)
            @nodex = x
            @nodey = y
            @order = MOVE
        else
            @order = STAY
            @nodex = @x
            @nodey = @y
            self.main_travel()
        end
        
        @acquire = acq
    end

    def draw
        super @player.color

        @home.unit_texture[ @kind.graphid+@anim ].draw_rot(@x, @y, @z, @angle, 0.5, 0.5, @home.zoom_x, @home.zoom_y)
    end

    #def drawBase()
        #@home.unit_texture[ @drawid ].draw_rot(@x, @y, @z, @angle, 0.5, 0.5, @home.zoomx, @home.zoomy)
    #end

    def tile_xy
        return [ @x/@home.tile_sx, @y/@home.tile_sy ]
    end

    def tile_x
        return @x/@home.tile_sx
    end

    def tile_y
        return @y/@home.tile_sy
    end



    def initialize(x,y,gid,playerid,properties,home)
        super x, y, 5, home.tile_sx, home.tile_sy

        @home = home
        @id = gid

        @properties = properties

        @target = nil
        @acquire = true

        @check_time = CHECK_TIME

        @anim = 0

        @player = playerid.instance_of?(Player) ? playerid : PlayerMaster.get.bring(playerid)

        @kind = gid.instance_of?(UnitType) ? gid : UnitMaster.get.bring(gid)

        @nodex = @x
        @nodey = @y

        @hasmain = false
        @mainx = x
        @mainy = y

        @z = ZOrder::UNITS

        @stats = UnitStats.new(@kind.stats)
        @stats.move_speed *= home.tile_prom
        @stats.sight_range *= home.tile_prom
        @stats.range *= home.tile_prom

        @sight_range_squared = @stats.sight_range*@stats.sight_range
        @range_squared = @stats.range*@stats.range

        @attack_time = @stats.attack_speed

        @show_rect = playerid != PlayerMaster::P1

        self.set_order(STAY)
    end

end
