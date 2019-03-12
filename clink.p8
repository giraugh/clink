pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
gs = 5
crpx, crpy, crpp = 16, 8, 0
crppx,crppy,crpxo,crpyo = 0, 0, crpx, crpy
r_text_tim = 0

psx, psy = 0, 0

version = "v0.8a"

power_test_red,power_test_blu,power_test_com = false,false,false

p_blu_tri = 1
p_red_tri = 2
p_bombs = 3
p_raft = 4
p_num = 0

button_count = 0
puzzle_stage = 1
puzzle_order = {
 1, 3, 1, 2
}

parts = {}

-- to do
--   final boss
--   red. bullet hitboxs

-- | ents |
--
-- 0 - player
-- 1 - 🐱 (or) - walky run thin'
-- 2 - coin
-- 3 - big bad or
-- 4 - big bad gr
-- 5 - spitty enemy
-- 6 - pickups
-- 7 - bombs
-- 8 - entrances
-- 9 - buttons
-- 10 - heart
-- 11 - bullet

entities = {}

----------------------------
--
--        events
--
----------------------------

function _init()
	camera(0, -128 / 4)
	entities = {
	 new_player(0, 0)
	}
	entities = proc_map_ents(entities)

 menuitem(1, "suicide", function()
  local p = entities[1]
  p.health = 0
 end)
end

function _update()
 local p = entities[1]

 if gs == 5 then
  if btn(❎) and btn(🅾️) then
   sfx(3)
   gs = 2
   crpp = 0.5
   crppx = p.x
   crppy = p.y
   crpx,crpy = flr(crppx/(8*16))*16,flr(crppy/(8*8))*8
  end
 end

 if gs == 0 then
  if (btn(⬆️)) move( 0, -1)
  if (btn(⬇️)) move( 0,  1)
  if (btn(⬅️)) move(-1,  0)
  if (btn(➡️)) move( 1,  0)
 end
 
 if gs == 0 then
  -- attacking
  if btn(❎) and not btn(🅾️) then
   if not p.ia then
    sfx(1)
   end
   attack()
  else
   p.ia = false
  end
  
  -- change pickup
  if btnp(❎) and btn(🅾️) then
   for i = 1, 4 do
    local ii = p.act_pickup+i
    if ii > 4 then ii = ii - 4 end
    if p.pickups[ii] then
     if ii ~= p.act_pickup then
      sfx(4 + p.act_pickup - 1)
     end
     p.act_pickup = ii
     break
    end
   end
   if p.act_pickup > 4 then
    p.act_pickup = 1
   end 
  end
  
  -- use pickup
  if p.pickups[p.act_pickup] then
   if btn(🅾️) then
    if not p.use_pickup then
     sfx(8)
     p.use_pickup = true
    else
     holding(p, p.act_pickup)
    end
   elseif p.use_pickup then
    sfx(9)
    p.use_pickup = false
    use(p, p.act_pickup)
   end
  end
  
 end
 
 -- power test
 power_test()
 
 -- get heart upgrade
 heart_upgrade()
 
 -- entities
 update_entities()
 
 -- particles
 upd_parts()
end

function _draw()
 cls()
	
 if gs == 0 then
  local sw, sh = 16 * 8, 8 * 8
  local p = entities[1]
 	local rx,ry = sw * flr(p.x/sw),
 	              sh * flr(p.y/sh)
 
  -- draw map
  draw_map(rx/8,ry/8)
  
  -- special text
  draw_text()
  
  -- draw entities
  draw_entities(rx, ry)
  
  -- do transition?
  if not (rx/8 == crpx and ry/8 == crpy) then
   gs = 1
   crpx = rx/8
   crpy = ry/8
  end
 end
 
 -- transition to new room
 if gs == 1 then
  draw_transition()
 end
 
 -- dungeon transition (fade)
 if gs == 2 then
  if crpp >= .5 then
   local p = entities[1]
   p.x,p.y = crppx, crppy
  end
  draw_fade_transition()
 end
 
 if gs == 3 or gs == 4 then
  draw_tri_cel(gs == 4)
 end
 
 -- particles
 draw_parts()
 
 -- post box t + b
 local sw, sh = 16 * 8, 8 * 8
 rectfill(0, sh, sw, sh+32, 0)
 rectfill(0, -32, sw, -1, 0)
 
 -- ui
 if gs != 2 and gs != 3 and gs != 4 and gs != 5 then
  draw_ui()
 end
 
 -- title screen
 if gs == 5 then
  print("a game by giraugh", 30, 64, 5)
  print("karinku", 50, 22, 7)
  print("press ❎ + 🅾️", 38, 38, 7)
 end
end

-----------------------------
--
--       particles
--
-----------------------------

function make_bur_dirt(x,y)
 for i = 1, 1 do
  local a = rnd(1)
  local vx,vy = .1 * cos(a), .1 * sin(a)
  create_part(
   x + 3 + (rnd(2)-1), y + 4 + (rnd(2)-1),
   flr(rnd(2) + 1),
   rnd(1) < .7 and 4 or 9,
   vx, vy
  )
 end
end

function make_blood_splash(x,y,gr)
 for i = 1, 40 do
  local a = rnd(1)
  local b = .5 + (rnd(1) / 2)
  local vx = .5 * cos(a)
  local vy = .4 * sin(b)
  local oc = rnd(1) < .3 and 8 or 2
  local gc = rnd(1) < .3 and 11 or 3
  create_part(
   x + 4, y + 4,
   5,
   gr and gc or oc,
   vx, vy
  )
 end
end

function make_blood(x,y,gr)
 for i = 1, 15 do
  local a = rnd(1)
  local b = .5 + (rnd(1) / 2)
  create_part(
   x + 4, y + 4,
   2,
   gr and 11 or 8,
   .3 * cos(a), .3 * sin(b)
  )
 end
end

function make_vortex(x, y)
 local r = 20 + ((sin(time()/4)/2)-1) * 8
 for i = 1, 10 do
  local ox,oy = get_offset()
  local a = sin(time() / 7) / 5 + (0.1) * i
  create_part(
   x + cos(a) * r,
   y + sin(a) * r,
   3,
   pget(xx-ox, yy-oy),
   cos(a),
   sin(a)
  )
 end
end

function make_vortex_b(x, y, red)
 for i = 1, 5 do
  local ox, oy = get_offset()
  create_part(
   x,
   y,
   2,
   red and 8 or 12,
   rnd(2) - 1,
   rnd(2) - 1
  )
 end
end

function make_explosion(x,y)
 -- parts
  for i = 1, 10 do
   create_part(
    x,
    y,
    6,
    2,
    rnd(1) - .5,
    rnd(1) - .5
   )
  end
  for i = 1, 40 do
   create_part(
    x,
    y,
    3,
    rnd(1) < .5 and 8 or 9,
    rnd(2) - 1,
    rnd(2) - 1
   )
  end
end

function create_part(x,y,r,c,vx,vy)
 add(parts, {
  x = x,
  y = y,
  c = c,
  vx = vx,
  vy = vy,
  r = rnd(r),
 })
end

function draw_parts()
 local ox, oy = get_offset()
 for p in all(parts) do
  circfill(p.x - ox,p.y - oy,p.r,p.c)
 end
end

function typed(s,ct,tt)
 return sub(s, 1, lr(0, #s, min(1, max(0, ct) / tt)))
end

function draw_text()
 local p = entities[1]
 local rx, ry = get_room(p.x,p.y)
 
 r_text_tim += 1
 
 -- shop 1
 if rx == 2 and ry == 0 then
  if mget(35, 2) != 1 then
   print(typed("$25", r_text_tim, 10), (3 * 8)- 2, 3 * 8 + 2, 9)
  end
  if mget(44,2) != 1 then
   print(typed("$80", r_text_tim-10, 10), (12 * 8) - 2, 3 * 8 + 2, 9)
  end
 end
 
 -- shop 2
 if rx == 3 and ry == 0 then
  if mget(55,3) != 1 then
   print(typed("$99", rtt, 10), (5 * 8) - 2, 2 * 8 + 2, 9)
  end
 end
 
 -- miniboss (or) warning
 if rx == 3 and ry == 1 then
  if not p.pickups[p_bombs] then
   print(
    typed("you dare approach me?", rtt - 5, 20),
    28,
    50,
    9
   )
  end
 end
 
 -- miniboss (gr) warning
 if rx == 1 and ry == 6 then
  if not p.pickups[p_raft] then
   print(
    typed("you dare approach me?", rtt - 5, 20),
    26,
    42,
    4
   )
  end
 end
 
 -- dungeon puzzle hint
 if rx == 4 and ry == 2 then
  print(
   typed("read between the lines", rtt - 5, 20),
   1 * 8 - 4,
   6 * 8 - 4,
   12
  )
 end
 
 -- power test
 if rx == 3 and ry == 6 then
  local s = "show us your power."
  if power_test_complete then
   s = "proceed."
  end
  print(
   typed(s, rtt - 5, 20),
    3 * 8,
    3 * 8 - 4,
    4
  )
 end
 
 -- final boss
 if rx == 5 and ry == 0 then
  print(
   typed("you win!", rtt - 5, 20),
    4 * 8 - 4,
    5 * 8 - 4,
    2
  )
 end
 
end

function upd_parts()
 for p in all(parts) do
  p.x += p.vx
  p.y += p.vy
  if rnd(1) < .25 then
   p.r -= .5
   if p.r <= 0 then
    del(parts, p)
   end
  end
 end
end


-----------------------------
--
--       instantiation
--
-----------------------------

function new_pickup(x, y, kind)
 return {
  t = 6,
  x = x,
  y = y,
  kind = kind,
  collected = false
 }
end

function new_or_big_bad(x,y)
 return {
  t = 3,
  x = x,
  y = y,
  ox = x,
  oy = y,
  tim = -20,
  tim_max = 30,
  st = 0,
  vx = 0,
  vy = 0,
  health = 10,
  health_max = 10,
  invinc = 0,
  invinc_max = 10,
  gates = {47, 63},
  ghost = false,
 }
end

function new_gr_big_bad(x,y)
 return {
  t = 4,
  x = x,
  y = y,
  ox = x,
  oy = y,
  vx = 0,
  vy = 0,
  health = 10,
  health_max = 10,
  invinc = 0,
  invinc_max = 10,
  gates = {46, 62},
  ghost = false,
  tim = -20,
  tim_max = 20,
  st = 0,
  green = true,
 }
end

function new_heart(x, y)
 return {
  t = 10,
  x = x,
  y = y,
  amount = 2,
  collected = false,
 }
end

function shoot_bullet(x,y,dr,sp,i)
 add(entities,
  new_bullet(x,y,dr,sp or .3,i)
 )
end

function new_bullet(x, y, dr, spd,i)
 return {
  t = 11,
  x = x,
  y = y,
  dr = dr,
  spd = spd,
  invinc = i,
  remove = false
 }
end

function new_coin(x, y, v)
 local upgrd = rnd(1) < .25
 return {
  t = 2,
  x = x,
  y = y,
  value = v or (upgrd and 5 or 1), -- 1|5|25|50
  collected = false
 }
end

function new_spitty(x, y, green)
 return {
  t = 5,
  x = x,
  y = y,
  ox = x,
  oy = y,
  spd = green and .15 or .1,
  f = 0,
  st = 0,
  tim = 0,
  tim_max = 50,
  vx = 0,
  vy = 0,
  health = green and 3 or 2,
  health_max = green and 3 or 2,
  invinc = 0,
	 invinc_max = 10,
	 green = green
 }
end

function new_bomb(x, y)
 return {
  t = 7,
  x = x,
  y = y,
  tim = 50,
  exploded = false
 }
end

function new_entrance(x,y,w,h,k)
 return {
  t = 8,
  x = x,
  y = y,
  w = w,
  h = h,
  k = k,
  disabled = false,
 }
end

function new_button(x, y)
 button_count += 1
 return {
  t = 9,
  x = x,
  y = y,
  i = button_count,
  pressed = false
 }
end

function new_player(x, y)
 return {
	 t = 0,
	 x = x,
	 y = y,
	 vx = 0,
	 vy = 0,
	 ia = false,
	 at = 0,
	 wf = 0,
	 wft = 0,
	 idl = 0,
	 wft_max = 5,
	 atm = 30,
	 fac = 0,
	 health = 6,
	 health_max = 6,
	 money = 0,
	 pickups = {},
	 invinc = 0,
	 invinc_max = 10,
	 act_pickup = 1,
	 use_pickup = false,
	 on_raft = false
 }
end

function new_or_enemy(x,y,green)
 return {
  t = 1,
  x = x,
  y = y,
  ox = x,
  oy = y,
  spd = green and .11 or .1,
  f = 0,
  ft = 0,
  ftm = 12,
  vx = 0,
  vy = 0,
  health = green and 3 or 2,
  health_max = green and 3 or 2,
  invinc = 0,
  invinc_max = 5,
  green = green,
 }
end

-----------------------------
--
--       auxiliary
--
-----------------------------

function heart_upgrade()
 local p = entities[1]
 local rx, ry = get_room(p.x,p.y)
 if rx == 1 and ry == 0 and gs == 0 then
  if mget(flr(p.x/8),flr(p.y/8)) == 28 then
   mset(22, 3, 1)
   sfx(3)
   p.health_max += 2
   p.health = p.health_max
  end
 end
end

function power_test()
local p = entities[1]
local ih,uh = p.act_pickup, p.use_pickup
local rx, ry = get_room(p.x,p.y)
 
if rx == 3 and ry == 6 and gs == 0 then
 if uh and ih == p_red_tri then
  mset(51, 53, 48)
  power_test_red = true
 end
 
 if uh and ih == p_blu_tri then
  mset(59, 53, 49)
  power_test_blu = true
 end
 
 if power_test_red and power_test_blu then
  if not power_test_complete then
   power_test_complete = true
   mset(53, 55, 70)
   mset(54, 55, 65)
   mset(55, 55, 65)
   mset(56, 55, 65)
   mset(57, 55, 69)
   sfx(3)
  end
 end
 
 if power_test_red then
  make_vortex(
   51 * 8 + 4,
  	53 * 8 + 4
  )
  --[[make_vortex_b(
  	51 * 8 + 4,
  	53 * 8 + 4,
  	true
  )]]
 end
 
 if power_test_blu then
  make_vortex(
   59 * 8 + 4,
  	53 * 8 + 4
  )
  --[[make_vortex_b(
  	59 * 8 + 4,
  	53 * 8 + 4,
  	false
  )]]
 end
end
 
end

function e_in_rd(p)
 p = p or entities[1]
 local tx,ty = flr(p.x/8),flr(p.y/8)
 local id = tx > 48 and ty >= 32 and tx < 95 and ty <= 47
 local od = tx > 47 and ty > 40 and tx < 63 and ty < 46
 return id and not od
 -- (48,32 > 95,47) / (47,40 > 63, 47)
end

function e_in_bd(p)
 local p = p or entities[1]
 local tx,ty = flr(p.x/8),flr(p.y/8)
 local id = tx > 48 and ty > 16 and tx < 95 and ty < 31
 local od = tx > 48 and ty > 16 and tx < 63 and ty < 23
 return id and not od
 -- (48, 16 > 95, 31) / (48, 16 > 63, 23)
end

function proc_map_ents(entities)
 -- reset button counter
 button_count = 0
 
 for x = 0, 128 do
  for y = 0, 64 do
   local s = mget(x, y)
   
   -- orange-red thing
   if s == 34 or s == 37 then
    local e = new_or_enemy(
     x * 8,
     y * 8,
     s == 37
    )
    
    add(entities, e)
     
    mset(x, y, mget(x-1, y))
   end
   
   -- player loc
   if s == 18 then
    entities[1].x = x * 8
    entities[1].y = y * 8
    psx = x * 8
    psy = y * 8
    crpx, crpy = x, y
    mset(x, y, 1)
   end
   
   -- coins
   if s == 59 or s == 60 or s == 43 or s == 44 then
    local v = 1
    if s == 44 then v = 5 end
    if s == 43 then v = 25 end
    if s == 60 then v = 50 end
    add(entities,
     new_coin(x * 8, y * 8, v)
    )
    mset(x,y,mget(x,y-1))
   end
   
   -- big bad (or)
   if s == 99 then
    add(entities,
     new_or_big_bad(x * 8,y * 8)
    )
    mset(x  ,y  ,1)
    mset(x+1,y  ,1)
    mset(x,  y+1,1)
    mset(x+1,y+1,1)
   end
   
   -- big bad (gr)
   if s == 101 then
    add(entities,
     new_gr_big_bad(x * 8,y * 8)
    )
    mset(x  ,y  ,65)
    mset(x+1,y  ,65)
    mset(x,  y+1,65)
    mset(x+1,y+1,65)
   end
   
   -- spitty
   if s == 50 or s == 54 then
    add(entities,
     new_spitty(x * 8,y * 8, s == 54)
    )
    mset(x,y,mget(x-1,y))
   end
   
   -- hearts
   if s == 27 then
    add(entities,
     new_heart(x * 8, y * 8)
    )
    mset(x, y, mget(x-1,y))
   end
   
   --pickups
   if s == 40 or s == 55 or s == 38 or s == 39 then
    local k = 0
    if (s == 38) k = p_blu_tri 
    if (s == 39) k = p_red_tri
    if (s == 55) k = p_bombs
    if (s == 40) k = p_raft
    add(entities,
     new_pickup(x * 8, y * 8, k)
    )
    mset(x, y, mget(x-1,y))
   end
   
   -- buttons
   if s == 97 then
    add(entities, new_button(
     x * 8,
     y * 8
    ))
    mset(x, y, mget(x, y + 1))
   end
   
   -- dungeon entrances
   if s == 45 or s == 61 or s == 96 then
    local w = 8
    local h = 8
    local k = 1
    if (s == 61) k = 2
    if (s == 96) then
     k = 3
     h = 16
    end
    
    add(entities, new_entrance(
     x*8,
     y*8,
     w,h,k
    ))
    
    --no chng map coz not drawn
   end
  end
 end
 
 return entities
end

function get_room(x,y)
 local sw, sh = 16 * 8, 8 * 8
 return flr(x/sw),
        flr(y/sh)
end

function in_rm_with(e1,e2)
 local mrx,mry = get_room(e1.x,e1.y)
 local trx,try = get_room(e2.x,e2.y)
 return mrx == trx and mry == try
end

function get_offset()
 local sw, sh = 16 * 8, 8 * 8
 local p = entities[1]
 local rx,ry = get_room(p.x,p.y)
 return rx * sw, ry * sh
end

function update_entities()
 -- update
 local fs = {
  upd_player,
  upd_or_enemy,
  upd_coin,
  upd_or_bb,
  upd_gr_bb,
  upd_spitty,
  upd_pickup,
  upd_bomb,
  upd_entrance,
  upd_button,
  upd_heart,
  upd_bullet
 }
 for i,e in pairs(entities) do
  fs[e.t+1](e)
 end
 
 -- remove those that need
 for i = #entities,1,-1 do
  local e = entities[i]
  if do_remove_ent(e) then
   if e.t == 1 or e.t == 5 then
    basic_dead(e)
   end
   if e.t == 3 or e.t == 4 then
    boss_dead(e)
    make_blood_splash(e.x, e.y, e.green)
   end
   del(entities, e)
  end
 end
end

function do_remove_ent(e)

 -- or-enemy / spitty
 if e.t == 1 or e.t == 5 or e.t == 3 or e.t == 4 then
  return e.health <= 0
 end
 
 -- coins
 if e.t == 2 or e.t == 6 then
  return e.collected
 end
 
 -- hearts
 if e.t == 10 then
  return e.collected
 end
 
 if e.t == 8 then
  -- dont rem entrances 4 now
 end
 
 if e.t == 7 then
  return e.exploded
 end
 
 if e.t == 11 then
  return e.remove
 end

 return false
end

--------------------------
--
--        player
--
--------------------------

function get_hit(e, amount, x, y, k)
 if e.invinc <= 0 then
  e.invinc = e.invinc_max
  e.health -= amount
  e.vx -= (k or 1) * 3 * sign(x - e.x)
  e.vy -= (k or 1) * 3 * sign(y - e.y)
  make_blood(e.x,e.y,e.green)
  if e == entities[1] then
   sfx(19)
  end
  return true
 end
 return false
end

function attack()
 local p = entities[1]
 p.ia = true
 if p.on_raft then
  p.vx -= .2 * cos(p.fac)
  p.vy -= .2 * sin(p.fac)
 end
end

function button_pressed(i)
 local p = entities[1]
 
 -- shopping
 if i >= 1 and i <= 3 then
  if i == 1 then
   if mget(35, 2) != 1 then
    if p.money >= 25 then
     p.money -= 25
     p.health_max += 2
     p.health = p.health_max
     mset(35, 2, 1)
    end
   end
  end
  if i == 2 then
   if mget(44, 2) != 1 then
    if p.money >= 80 then
     p.money -= 80
     p.health_max += 2
     p.health = p.health_max
     mset(47, 3, 1)
     mset(47, 4, 1)
     sfx(3)
     mset(44, 2, 1)
    end
   end
  end
  if i == 3 then
   if mget(55, 3) != 1 then
    if p.money >= 99 then
     p.money -= 99
     p.health_max += 2
     p.health = p.health_max
     mset(55, 3, 1) 
    end
   end
  end
 end
 
 -- final dungeon
 if i == 4 or i == 5 then
  warp_to(p.x + 25 * 8, p.y)
 end
 
 -- red dungeon
 if i == 6 or i == 7 then
  warp_to(p.x + 8 * 8, p.y)
 end
 
 -- blue-puzzle buttons
 if i >= 8 and i <= 10 then
  i -= 7
  if not puzzle_solved then
   if i == puzzle_order[puzzle_stage] then
    puzzle_stage += 1
    sfx(5)
    if puzzle_stage == #puzzle_order + 1 then
     -- unlock the door
     
     puzzle_solved = true
     
     for xx = -16, 16 do
      for yy = -8, 8 do
       local p = entities[1]
       local px, py = flr(p.x/8), flr(p.y/8)
       local s = mget(px + xx, py + yy)
       local ts = -1
       if s == 77 then
        local ns = mget(px + xx - 1, py + yy)
        if ns == 119 or ns == 93 then
         ts = 122
        else
         ts = 87
        end
       end
       if (s == 109) ts = 120
       if (s == 93) ts = 119
       if ts != -1 then
        mset(px + xx, py + yy, ts)
       end
      end
     end
     
     sfx(3)
    end
   else
    sfx(17)
    puzzle_stage = 1
   end
  end
 end
end

function dead()
 local p = entities[1]
 p.x = psx
 p.y = psy
 p.health = p.health_max
 p.money -= 10
 p.money = max(0, p.money)
 
 sfx(20)
 
 -- remove red dungeon bosses
 for e in all(entities) do
  if e_in_rd(e) then
   if e.t == 3 or e.t == 4 then
    e.health = 0
   end
  end
 end
 
 -- fade to spawn
 gs = 2
 crpp = 0
 crppx = p.x
 crppy = p.y
 crpx,crpy = flr(crppx/(8*16))*16,flr(crppy/(8*8))*8
end

function holding(p, k)
 if gs == 0 then
  if k == p_red_tri or k == p_blu_tri then
   --make_vortex(p.x + 4, p.y - 5)
   make_vortex_b(p.x + 4, p.y - 5, k == p_red_tri)
   sfx(16)
  end
  if k == p_blu_tri then
   for e in all(entities) do
    if e.t == 1 or e.t == 3 or e.t == 4 or e.t == 5 then
     if in_rm_with(e,p) then
      e.vx = 0
      e.vy = 0
      make_vortex_b(e.x + 4, e.y, false)
     end
    end
   end
  end
 end
end

function use(p, k)
 if k == p_bombs then
  local n = 0
  for e in all(entities) do
   if e.t == 7 then n += 1 end
  end
  if n < 3 then
   add(entities, new_bomb(p.x, p.y))
  end
 end
 
 if k == p_raft then
  local tx = flr(p.x / 8)
  local ty = flr(p.y / 8)
  local iw = mget(tx, ty) == 12
  if (p.on_raft and iw) then
   sfx(17)
  else
   p.on_raft = not p.on_raft
   if p.on_raft then
    fset(12, 0, false)
   else
    fset(12, 0, true)
   end
  end
 end
end

function move(dx, dy)
 local p = entities[1]

 -- change dir if not attacking
 if not p.ia then
  p.fac = atan2(dx, dy)
 end

 if not p.on_raft then
  p.vx += dx * .5
  p.vy += dy * .5
 end
 
 -- anim
 p.wft += 1
 p.idl = 2
 if p.wft >= p.wft_max then
  p.wf = 1 - p.wf
  p.wft = 0
 end
end

function warp_to(x, y, p)
 if gs != 2 then
  gs = 2
  crppx = x
  crppy = y
  crpp = p or 0
  crpx,crpy = flr(crppx/(8*16))*16,flr(crppy/(8*8))*8
 end
end

function upd_entrance(e)
 local p = entities[1]
 
 if gs == 0 then
 if coll_with_pl(e, e.w, e.h) then
  local wx, wy = -1, -1
  
  -- blue
  if e.k == 1 then
   e.disabled = true
   wx, wy = 52 * 8, 28 * 8
  end
  
  -- red
  if e.k == 2 then
   if not p.pickups[p_red_tri] then
    wx, wy = 52 * 8, 35 * 8
    add(entities, new_or_big_bad(
     90 * 8, 35 * 8
    ))
    add(entities, new_gr_big_bad(
     90 * 8, 43 * 8
    ))
   end
  end
  
  -- final
  if e.k == 3 then
   wx, wy = 75 * 8, 4 * 8 - 4
  end
  
  -- fade to new pos
  if not (wx == -1 and wy == -1) then
   warp_to(wx, wy)
  end
 end
 end
end

function upd_player(p)
 -- attackg
 p.at += 1
 if p.at >= p.atm then
  p.at = 0
 end
 
 -- being on a raft
 if p.on_raft then
  p.vx = sign(p.vx) * min(abs(p.vx),1)
  p.vy = sign(p.vy) * min(abs(p.vy),1)
  make_bur_dirt(p.x,p.y)
 else
   -- apply friction
  p.vx,p.vy = lr(p.vx, 0, .35), lr(p.vy, 0, .35)
 end
 
 -- holding red tri
 if p.act_pickup == p_red_tri and p.use_pickup then
  p.vx,p.vy = lr(0, p.vx, 1.25), lr(0, p.vy, 1.25)
 end
 
 -- move (collision dependent)
 p.x, p.y, p.vx, p.vy = resolve_vel(p)

 -- stop being invinc
 p.invinc -= 1
 
 -- start being idle
 if p.idl > 0 then
  p.idl -= 1
 end
 
 -- am i dead?
 if p.health <= 0 then
  dead()
 end
end

------------------------------
--
--          enemies
--
------------------------------

function basic_dead(e)
 -- do somin if dead
 add(entities, new_coin(e.x, e.y))
end

function upd_spitty(e)
 local p = entities[1]

 -- moving in and out of ground
 if in_rm_with(e,p) then
  e.tim += 1
  if e.st == 0 then e.tim += 1 end
  if e.tim > e.tim_max then
   e.tim = 0
   if e.st == 0 then
    -- fire projectile
   end
   e.st = 1 - e.st
  end
  
  -- moving when hidden
  if e.f <= 4 then
   -- make parts
   if rnd(1) < .45 then
   	make_bur_dirt(e.x,e.y+4)
   end
  
   local spd = e.spd
   if p.x > e.x then
    e.vx += spd
   elseif p.x < e.x then
    e.vx -= spd
   end
   if p.y > e.y then
    e.vy += spd
   elseif p.y < e.y then
    e.vy -= spd
   end
  end
 else
  if gs == 1 and crpp >= .8 then
   -- go back to start point
   e.x = e.ox
   e.y = e.oy
   e.vx = 0
   e.vy = 0
  end
 end
 
 -- apply friction
 e.vx = lr(e.vx, 0, .25)
 e.vy = lr(e.vy, 0, .25)
 
 -- resolve vel
 e.x, e.y, e.vx, e.vy = resolve_vel(e)
 
 -- am up?
 if e.f >= 4 then
  -- get hit by pl?
  if check_hit_by_pl(e) then
   e.f = 0
   e.st = 0
   e.tim = 0
  end
  
  -- hit the pl
  check_hit_pl(e)
 end
 
 -- stop being invinc
 e.invinc -= 1
 
end

function boss_dead(e)
 -- make coins
 for i = 1, 5 do
  local c = new_coin(e.x, e.y)
  add(entities, c)
 end
 
 if e_in_rd(p) then
  if e.t == 3 then
   -- warp to next boss
   warp_to(82 * 8, 43 * 8)
  else
   -- warp to treasure 🐱
   warp_to(71 * 8, 43 * 8)
  end
 end
 
 -- open gate
 sfx(3)
 local xx = flr(e.x / 8)
 local yy = flr(e.y / 8)
 for g in all(e.gates) do
  for i = -32,32 do
   for j = -16, 16 do
    local nx = xx + i
    local ny = yy + j
    if mget(nx, ny) == g then
     mset(nx, ny, mget(nx-1, ny))
    end
   end
  end 
 end
end

function upd_bb(e,ch,cdh)

 -- get hit by pl
 if ch then
 	check_hit_by_pl(e, 16, 16, 4)
 end
 
 -- hit the pl
 if cdh then
  check_hit_pl(e, 8, 6, 4, 5)
 end
 
 -- apply friction
 e.vx = lr(e.vx, 0, .25)
 e.vy = lr(e.vy, 0, .25)
 
 -- resolve vel
 e.x, e.y, e.vx, e.vy = resolve_vel(e, 16, 17)
 
 -- stop being invinc
 e.invinc -= 1
 
end

function upd_or_bb(e)
 local p = entities[1]
 local spd = .08
 
 if in_rm_with(e,p) then
  e.tim += 1.3
  if not e.ghost and e.health / e.health_max < .6 then
   e.tim += 0.6
  end
  if e.tim > e.tim_max then
   e.tim = 0
   if e.st < 2 then 
    e.st = 1 - e.st
    if e.ghost then
     e.ghost = false
     e.tim = e.tim_max / 2
    end
   else
    e.st = 1
   end
   
   if rnd(1)<.45 then
    e.ghost = true
    e.st = 1
   end
   
  end
  
  if e.st == 0 then
   e.dr = (rnd(.05)-.025) + atan2(p.x - e.x, p.y - e.y)
   -- slowly back up
   local spd = .08
   e.vx -= cos(e.dr) * spd
   e.vy -= sin(e.dr) * spd
  elseif e.st == 1 then
   local spd = .6
   e.vx += cos(e.dr) * spd
   e.vy += sin(e.dr) * spd
  elseif e.st == 2 then
   e.dr = atan2(p.x - e.x, p.y - e.y)
   -- quickly back up / sideways
   local spd = .3
   e.vx -= cos(e.dr + rnd(.2)) * spd
   e.vy -= sin(e.dr + rnd(.2)) * spd
  end
 end
 
 -- get hit by pl
 if not e.ghost then
  if check_hit_by_pl(e, 16, 17, 4) then
   e.tim = e.tim_max
  end
 end

 upd_bb(e, false, not e.ghost)
end

function upd_gr_bb(e)
 local p = entities[1]
 
 if in_rm_with(e,p) then
  if e.st == 0 then
   e.tim += 1
   if e.tim == e.tim_max then
    e.tim = 0
    local a = atan2(p.x - e.x, p.y - e.y)
    a += (rnd(.1) - .05)
    shoot_bullet(
     e.x,
     e.y,
     a,
     1.1
    )
   end
   
   if rnd(1) < .2 then
    e.dr = rnd(1)
   end
   
   if rnd(1) < .01 then
    e.st = 1
   end
  end
  
  if e.st == 1 then
   e.tim += .25
   e.vx = 0
   e.vy = 0
   if e.tim >= e.tim_max then
    e.tim = 0
    e.st = 0
    local ii = flr(rnd(7)) + 1
    for i = 1, 8 do
     if i != ii then
     	local a = i / 8
      shoot_bullet(
       e.x + 2,
       e.y + 4,
       a,
       0.5,
       true
      )
     end
    end
    if e.health < e.health_max/3 then
     if rnd(1) < .1 then
      e.st = 1
      e.tim = 0
     end
    end
   end
  end
  
  e.vx += cos(e.dr) * .2
  e.vy += sin(e.dr) * .2
 
  upd_bb(e, true, true)
 end
end

function upd_bullet(e)
 local p = entities[1]

 e.x += cos(e.dr) * e.spd
 e.y += sin(e.dr) * e.spd
 
 -- hit the pl
 if check_hit_pl(e, 4, 4, 2, 2) then
  e.remove = true
 end
 
 -- get hit by pl
 if check_hit_by_pl_s(e) then
  if not e.invinc then
  	e.remove = true
  	sfx(2)
  end
 end
 
 -- die if not in rm
 if not in_rm_with(e, p) then
  e.remove = true
 end
 
end

function upd_or_enemy(e)
 -- move towards player
 local spd = e.spd
 local p = entities[1]
 local d = dist(e.x,e.y,p.x,p.y)
 if in_rm_with(e,p) then
  if d < 60 then
   if p.x > e.x then
    e.vx += spd
   else
    e.vx -= spd
   end
   if p.y > e.y then
    e.vy += spd
   else
    e.vy -= spd
   end
  end
 else
  if gs == 1 and crpp >= .8 then
   -- go back to start point
   e.x = e.ox
   e.y = e.oy
   e.vx = 0
   e.vy = 0
  end
 end

 -- apply friction
 e.vx = lr(e.vx, 0, .25)
 e.vy = lr(e.vy, 0, .25)
 
 -- move
 e.x, e.y, e.vx, e.vy = resolve_vel(e)

 -- get hit?
 check_hit_by_pl(e)
 
 -- hit the pl
 check_hit_pl(e)
 
 -- stop being invinc
 e.invinc -= 1
end

function coll_with_pl(e, w, h)
 local p = entities[1]
 local pcol = {
  x = p.x,
  y = p.y,
  w = 8,
  h = 8
 }
 local mcol = {
  x = e.x,
  y = e.y,
  w = w or 8,
  h = h or 8
 }
 return recs_overlap(pcol, mcol)
end

function check_hit_pl(e, w, h, xo, yo)
 local p = entities[1]
 local mcol = { 
  x = e.x + (xo or 0),
  y = e.y + (yo or 0),
  w = w or 8,
  h = h or 8
 }
 local pcol = {
  x = p.x,
  y = p.y,
  w = 8,
  h = 8
 }
 local h = recs_overlap(mcol,pcol)
 if h then
  return get_hit(p, 1, e.x, e.y)
 end
 return false
end

function check_hit_by_pl_s(e, w, h)
 -- get hit by pl attack
 local p = entities[1]
 if p.ia then
  local acol = {
   x = p.x + cos(p.fac) * 7,
   y = p.y + sin(p.fac) * 7,
   w = 7,
   h = 7
  }
  local mcol = {
   x = e.x,
   y = e.y,
   w = w or 8,
   h = h or 8
  }
  local ga = recs_overlap(acol, mcol)
  if ga then
   return true
  end
  return false
 end
end

function check_hit_by_pl(e, w, h)
 -- get hit by pl attack
 local p = entities[1]
 if p.ia then
  local acol = {
   x = p.x + cos(p.fac) * 7,
   y = p.y + sin(p.fac) * 7,
   w = 7,
   h = 7
  }
  local mcol = {
   x = e.x,
   y = e.y,
   w = w or 8,
   h = h or 8
  }
  local ga = recs_overlap(acol, mcol)
  if ga then
   if get_hit(e, 1, p.x, p.y, 1.5) then
    sfx(2)
    return true
   end
   return false
  end
 end
end


------------------------------
--
--    pickups / misc ents
--
------------------------------

function upd_bomb(e)
 local p = entities[1]
 e.tim -= 1
 if e.tim <= 0 then
  -- blow up
  e.exploded = true
  sfx(14)
  sfx(15)
  
  -- damage ents
  for en in all(entities) do
   if in_rm_with(en, p) then
    if en != p and en != e then
     local dx = (en.x - e.x)
     local dy = (en.y - e.y)
     local d = sqrt(dx^2 + dy^2)
     if d < 16 then
      if en.t == 3 or en.t == 1 or en.t == 4 or en.t == 5 then
       get_hit(en, 2, e.x, e.y)
      end
     end
    end
   end
  end
  
  -- fx and damage blocks
  for i = -3, 3 do
   for j = -3, 3 do
    if abs(i) != abs(j) or (i == 0 and j == 0) then
     if (abs(i) <= 1 and abs(j) <= 1) then
      make_explosion(e.x + 8 * i, e.y + 8 * j)
     end
    end
    local xx = flr(e.x/8) + i
    local yy = flr(e.y/8) + j
    local t = mget(xx, yy)
    if t == 75 or t == 82 then
     mset(xx, yy, t == 75 and 65 or 1)
    end
   end
  end
 end
end

function upd_button(b)
 local p = entities[1]
 if coll_with_pl(b) then
  if not b.pressed then
   sfx(18)
   button_pressed(b.i)
  end
  b.pressed = true
 else
  if b.pressed then
   sfx(18)
  end
  b.pressed = false
 end
end

function upd_heart(h)
 local p = entities[1]
 if coll_with_pl(h) then
  if p.health < p.max_health then
   h.collected = true
   p.health += 2
   p.health = min(p.health, p.health_max)
   sfx(0) --upd
  end
 end
end

function upd_coin(c)
 local p = entities[1]
 if coll_with_pl(c) then
  if p.money != 999 then
   c.collected = true
   p.money += c.value
   p.money = min(p.money, 999)
   sfx(0)
  end
 end
end

function upd_pickup(e)
 local p = entities[1]
 if coll_with_pl(e) then
  e.collected = true
  p.pickups[e.kind] = true
  p.act_pickup = e.kind
  p_num += 1
  
  if e.kind == p_red_tri then
   gs = 3
  end
  
  if e.kind == p_blu_tri then
   gs = 4
  end
  
  if e.kind == p_blu_tri or e.kind == p_red_tri then
   sfx(12)
  else
   sfx(3)
  end
  
  sfx(0)
 end
end

------------------------------
--
--    collisions / physics
--
------------------------------

function resolve_vel(e, w, h)
 w = w or 8
	h = h or 8 
 local cols = getcols(e.x, e.y, flr(w / 8), flr(h / 8))
	local x, y = e.x, e.y
	local vx, vy = e.vx, e.vy
	
	if not ent_will_collide(flr(x + vx), flr(y), w, h, cols) then
	 x = x + vx
	else
	 while (not ent_will_collide(flr(x + sign(vx)), flr(y), w, h, cols)) do
	  x = flr(x + sign(vx))
	 end
	 vx = 0
	end
	
	if not ent_will_collide(flr(x), flr(y + vy), w, h, cols) then
	 y = y + vy
	else
	 while (not ent_will_collide(flr(x), flr(y + sgn(vy)), w, h, cols)) do
	  y = y + sgn(vy)
	 end
	 vy = 0
	end

 return x,y,vx,vy

end

function ent_will_collide(tx,ty,tw,th,cols)
 -- target ent is made a bit smaller
 local tecol = {x=tx+2,y=ty+1,w=tw-2,h=th-1}
 for i, col in pairs(cols) do
  local ro = recs_overlap(
   {x=col.x,y=col.y,w=8,h=8},
   tecol
  )
  if ro then return true end
 end
 return false
end

function getcols(x, y, ex)
	-- find colliders
 local tx, ty = flr(x / 8), flr(y / 8)
 local cols = {}
 for i = -1-ex, 1+ex, 1 do
 	for j = -1-ex, 1+ex, 1 do
 		-- is this tile a collider?
 		local s = mget(tx+i, ty+j)
 		local ic = fget(s, 0)
 		if ic then
 		 add(cols, {
 				x = (tx+i) * 8,
 				y = (ty+j) * 8
 			})
 		end
 	end
 end
 return cols
end

----------------------------
--
--         drawing
--
----------------------------

function draw_map(x,y,res)
 res = res or true
 if e_in_bd() then
  pal(2, 1)
  pal(14,12)
 elseif e_in_rd() then
  --pal(2, 9)
  --pal(14,10)
 end
 map(x, y, 0, 0, 16, 8)
 if res then pal() end
end

function draw_ui()
 local p = entities[1]
 
 -- hearts
 local h = p.health/2
 local hm = p.health_max / 2
 local nh = flr(h)
 local hh = (h - nh) * 2
 
 local sep = 1
 local stx = 1
 local sty = -10
 
 for i = 1, hm do
  local xx = stx + (8 + sep) * (i-1)
  if h <= 1 and flr(time() * 3) % 2 == 0 then
   pal(8, 2)
  end
  
  if i <= nh then
   spr(24, xx, sty)
  elseif i <= nh+hh then
   spr(25, xx, sty)
  else
   spr(26, xx, sty)
  end
  
  pal(8, 8)
 end
 
 -- coins
 local stx = 128 - 17 - 5
 local sty = -9
 local tsep = 10
 local m = npad(p.money)
 if p.money > 9 then tsep -= 1 end
 spr(59, stx, sty)
 print(m, stx + tsep, sty + 1, 7)
 
 -- sep
 local ssx = 128 - 19 - 5
 local ssy = -2
 local ssh = 8
 line(ssx, ssy - ssh, ssx, ssy, 7)
 
 -- pickups
 local psprs = {
  [p_red_tri] = 85,
  [p_blu_tri] = 83,
  [p_bombs] = 57,
  [p_raft] = 41,
 }
 for i = 1, 4 do
  local ii = i + (p.act_pickup - 1)
  if (ii > 4) ii -= 4
  local s = psprs[ii]
  if not p.pickups[ii] then
   s += 1
   pal(7, 5)
  end
  spr(s, 128 - 25 - (5 - i) * 9, -10)
  pal(7,7)
 end
 
 -- button prompts
 if p_num == 0 then
  pal(6, 5)
 end
 print("🅾️", 10, 65, 6)
 pal(6,6)
 if btn(🅾️) and p_num == 1 then
  pal(6, 5)
 end
 print("❎", 1, 65, 6)
 pal(6,6)
 
 -- version
 print(version, 108, 65, 5) 
end

function draw_bomb(e, x, y)
 local so = 0
 if (e.tim/2) % 2 == 0 then
  so = 1
  sfx(13)
 end
 
 spr(55 + so, x, y)
end

function draw_button(b, x, y)
 local s = 97
 if (b.pressed) s += 1
 spr(s, x, y)
end

function draw_bullet(b, x, y)
 if b.invinc then
  pal(11,12)
  pal(3,1)
  if (time()*200)%2 == 0 then
   pal(11, 7)
  end
 end 
 spr(240, x, y)
 pal()
end

function draw_coin(c, x, y)
 local s = 59
 if c.value == 5 then
  s = 44
 elseif c.value == 25 then
  s = 43
 elseif c.value == 50 then
  s = 60
 end
 
 spr(s, x, y)
 
end

function draw_heart(e, x, y)
 spr(27, x, y + sin(time() % 1))
end

function draw_pickup(e, x, y)
 local k = e.kind
 
 y += sin(time() % 1)
 local s = 38

 if k == p_red_tri then
  s = 39
 elseif k == p_bombs then
  s = 55
 elseif k == p_raft then
  s = 40
 end
 
 spr(s, x, y)
end

function draw_player(p, x, y)
 -- raft?
 if p.on_raft then
  spr(40, x, y+4)
  p.idl = 0
 end
 
 -- sprite
 if p.invinc > 0 and (p.invinc/2)%2==0 then
  pal(8, 7)
  pal(2, 7)
 end
 
 if gs == 2 then
  local f = 1 - abs((crpp*2)-1)
  pal(8, fade(8, f))
  pal(2, fade(2, f))
 end
 
 if p.fac == 0 or p.fac == 0.5 then
  if p.idl == 0 then
   spr(19, x, y, 1, 1, p.fac == 0.5 ,false)
  else
   spr(16 + p.wf, x, y, 1, 1, p.fac == 0.5, false)
  end
 else
  if p.idl == 0 then
   spr(18, x, y)
  else
   spr(32 + p.wf, x, y)
  end
 end
 
 pal(8,8)
 pal(2,2)
 
 -- sword + shield
	local so = 0
	if flr(t()) % 2 == 0 then
		so = -1
	end
	if not p.ia then
	 spr(20, x + 2, y - so - 2)
	end
	spr(23, x - 2, y - 1)
	
	-- attack anim
	if p.ia then
	 local ax = x + flr(cos(p.fac) * 6)
	 local ay = y + flr(sin(p.fac) * 6)
	 if p.fac == 0 or p.fac == 0.5 then
	  spr(22, ax, ay, 1, 1, p.fac == 0.5, false)
	 else
	  spr(21, ax, ay, 1, 1, false, p.fac == 0.75)
	 end
	end
	
	-- using pickup
	local psprs = {
  [p_red_tri] = 39,
  [p_blu_tri] = 38,
  [p_bombs] = 55,
  [p_raft] = 40,
 }
	if p.use_pickup then
	 if p.pickups[p.act_pickup] then
	  local s = psprs[p.act_pickup]
	  spr(s, x, y - 10 + sin(time() % 1))
	 end
	end
end

function draw_spitty(e, x, y)
 if e.invinc > 0 and (e.invinc/2) % 2 == 0 then
  pal(8, 7)
  pal(9, 7)
 elseif e.green then
  pal(8, 11)
  pal(9, 3)
 end
 
 spr(53 - e.f/3, x, y)
 if e.st == 0 then
  if e.f < 9 then
   e.f += 1
  end
 else
  if e.f > 0 then
   e.f -= 1
  end
 end
 
 pal(8,8)
 pal(9,9)
end

function draw_or_enemy(e, x, y)
 
 if e.invinc > 0 and (e.invinc/2)%2==0 then
  pal(8, 7)
  pal(2, 7)
  pal(11, 7)
  pal(3, 7)
 elseif e.green then
  pal(8, 11)
  pal(9, 3)
 end
 
 if abs(e.vx) > 0.05 or abs(e.vy) > 0.05 then
  -- running anim
  e.ft += 1
  if e.ft >= e.ftm then
   e.f = 1 - e.f
   e.ft = 0
  end
  spr(34 + e.f, x, y)
 else
  -- standing still
  spr(36, x, y)
 end
 
 pal()
end

function draw_or_big_bad(e,x,y)
 if e.invinc > 0 and (e.invinc/2) % 2 == 0 then
  pal(8, 7)
  pal(9, 7)
 end
 local p = (flr(e.tim/4) % 2 == 0) and 2 or 0
 spr(113, x, y+10)
 spr(114, x+8,y+10)
 if not e.ghost then
  sspr(24 + p * 8, 48, 16, 16, x, y, 16, 16)
 end
end

function draw_gr_big_bad(e,x,y)
 if e.invinc > 0 and (e.invinc/2) % 2 == 0 then
  if e.st == 1 and flr(time()*100)%2 == 0 then
   pal(9, 12)
   pal(8, 1)
  else
   pal(8, 7)
   pal(9, 7)
  end
 else
  if e.st == 1 and flr(time()*100)%2 == 0 then
   pal(9, 12)
   pal(8, 1)
  else
   pal(9, 11)
   pal(8, 3)
  end
 end
 spr(113, x, y+10)
 spr(114, x+8,y+10)
 sspr(24, 48, 16, 16, x, y, 16, 16)
 pal()
end


function draw_entities(dx, dy)
 local p = entities[1]
 -- draw backwards to ensure
 -- player is always on top
 for i = #entities, 1, -1 do
  local e = entities[i]
  if gs == 1 or e == p or in_rm_with(e,p) then
   draw_entity(e, dx, dy)
  end
 end
end

function fade(c, st)
 local sx,sy = 96,32
 local fy,fx = -1, -1
 
 -- fnd right most point by col
 for yy = 0, 8 do
  for xx = 0, 1 do
   local xtes = xx == 0 and 3 or 7
   local cc = sget(sx+xtes, sy+yy)
   if cc == c then
    fy = yy
    fx = xtes
    yy = 8
    break
   end
  end
 end
 
 -- stage out of 1, 0 -> 1
 -- 1 is darkest
 st = flr(4 * st)
 if st >= 4 then
  return 1
 else
  return sget(sx + fx - st, sy + fy)
 end
end

function draw_tri_cel(red)

 crpp += 0.01
 crpp = min(crpp, 1)
 
 local p = crpp - .1
 
 local px = 64
 local py = 4 + lr(64, 32, p^.2)
 
 if btn(❎) or btn(🅾️) then
  crpp += .04
 end
 
 if crpp >= 1 then
  gs = 1
 end

 if p > 0 then
  -- lines
  local n = 100
  for i = 1, n do
   local a = sin(time() / 200) + (1 / n) * i
   local c = 15 * i+sin(time()/300)
   if (flr(c%16) >= 8 and flr(c%16) < 14) then
    line(px, py, px + 128 * cos(a), py + 128 * sin(a), c)
   end
  end
  
  circfill(px, py, 1 * sin(crpp * 2) + 5 + (min(1,p/.2)+.3) * 4, 7)
 
  spr(39 - (red and 1 or 0), px-4, py-4)
 else
  circfill(64, 64, (crpp/.1) * 128, 1)
 end
 
 if p < .1 then
  circfill(64, 64, (1 - abs(p)/.1) * 128, 1)
 end
 
 if crpp > .6 then
  for i = 1, 15 do
   pal(i, fade(i, 1 - (1 - crpp)/.4))
  end
 end
 
 if crpp >= 1 then
  warp_to(psx, psy, .5)
 end

end

function draw_fade_transition()
 local tx, ty = crpxo, crpyo
 if crpp > .5 then
  tx, ty = crpx, crpy
 end
 
 -- fade to blue
 local t = 5
 if crpp > .5 then t = 1 end
 for i = 1, 15 do
  pal(i, fade(i, 1 - abs((crpp * 2)-1)))
 end
 
 draw_map(tx,ty)
 draw_entities(tx * 8, ty * 8)
 
 crpp += 0.025
 if crpp >= 1 then
 	crpp = 0
 	crpxo = crpx
 	crpyo = crpy
 	gs = 0
 	r_text_tim = 0
 end
 
 pal()
 
 end

function draw_transition()
 -- draw transition
  local tx = flr(lr(crpxo, crpx, crpp))
  local ty = flr(lr(crpyo, crpy, crpp))
 	draw_map(tx,ty)
  
  -- draw transitioning entities
  draw_entities(tx * 8, ty * 8)
 
  -- keep transitioning
  crpp += 0.08
  if crpp >= 1 then
  	crpp = 0
  	crpxo = crpx
  	crpyo = crpy
  	gs = 0
  	r_text_tim = 0
  end
end

function draw_entity(e, dx, dy)
 local fs = {
  draw_player,
  draw_or_enemy,
  draw_coin,
  draw_or_big_bad,
  draw_gr_big_bad,
  draw_spitty,
  draw_pickup,
  draw_bomb,
  function()end,
  draw_button,
  draw_heart,
  draw_bullet,
 }
 
 fs[e.t+1](e, e.x - dx, e.y - dy)
end

-----------------------------
--
--           maths
--
-----------------------------

function lr(a, b, t)
 return a + (b - a) * t
end

function sign(x)
 if x > 0 then return 1 end
 if x < 0 then return -1 end
 return 0
end

function recs_overlap(a, b)
 -- {
 --   x, y, w, h
 -- }
 
 local ax1,bx1 = a.x,b.x
 local ax2,bx2 = a.x+a.w,b.x+b.w
 local ay1,by1 = a.y,b.y
 local ay2,by2 = a.y+a.h,b.y+b.h
 
 return ax1 < bx2 and
        ax2 > bx1 and
        ay1 < by2 and
        ay2 > by1
end

function dist(x1,y1,x2,y2)
 return sqrt((x1-x2)^2 + (y1-y2)^2)
end

function npad(x)
 if x < 10 then
  return "00" .. x
 elseif x < 100 then
  return "0" .. x
 else
  return x
 end
end
__gfx__
00000000ffffffff33bbb3333333333bbbbbb333ffffbb33bb3bbbffffffffffffffffffffffff3b33bfffffffffffffcccccccc44444444cccccc33bbbbb333
07000700ffffffff3bbbb3b3bb3bbbbbb3333bb3ffbbbbb33b3bbbbffffffffffffffffffffffffbb3fffffffbbbbbffc1cccccc44449944ccccbbb3b3333bb3
00707000ffffffff3bbb33bb3b33bbbbbbbbbbbbfb3b3bb33b333bbbffffffffffffffffffffffff3fffffffbb3bbbbfc1cc1ccc44444444cccb3bb3bbbbbbbc
00077770ffffffffbb33bbbb3bb33bb33b333bbbbb3b33333b3b3b3bffffffffffffffffffffffffffffffffbbbb3bbfcccc1ccc44444444cc3b33333b333bbc
00777000ffffffff33b3bbbbbbbbbbb33bbb3bbf3b333bb3333b3b3bfffffffffffffffbffffffffffffffffb3bbbbbfcccccccc49944444cb333bb33bbb3bcc
07000700ffffffff3bbbb3bbfbbbbbb33bb33bbf3bbbbbb3bb3b333bbfffffffffffffb3ffffffffffffffffbbb3bbbfcc1ccc1c444444443bbbbbb33bb33ccc
00070070ffffffff3bbb333bffbbb3bb3bbbbbff33333b33bb3b3bbb33fffffffffffb33fffffffffffffffffbbbbbffcc1ccc1c4444994433333b333bbbcccc
00000000ffffffff3bbbb3bbfffbbb333b3bbfff333bbb3bbb3bb333b3b3fffffffff3b3fffffffffffffffffff11fffcccccccc44444444333bbb3b3bcccccc
0e80e8000e80e8000e8008e00e80e8000000000000067000000000000000000000000000000000000000000000000000fffffffffccccccc3333333bbbcccccc
008888000088880000888800008888000000060000077000000000000000000007700770077007700770077000000000f77ff77fffcccc1cbb3bbbbb3b3ccccc
e08e8e0ee08e8e0ee0e88e0ee08e8e0e000006000006700000c00000000000007287788772877007700770070880088072877887fffccc1ccb33bbbb3b33cccc
88882288888822888882288888882288000006000007700001c676760c1c00007288888772880007700000070888888072888887ffffccccccb33bb33b3b3ccc
008888000088880000888800008888000000ccc00006700001c77777011100007288888772888007700000070888888072888887fffffccccccbbbb3333b3bcc
082222000822220000222200082222000000010000cccc0000c000000c1c000007288870072800700700007000888800f728887fffffffccccccbbb3bb3b33cc
02200200002022000020020000200200000000000001d000000000000010000000722700007287000070070000088000ff7227fffffffffcccccc3bbbb3b3bbc
000002000020000000200200002002000000000000000000000000000000000000077000000770000007700000000000fff77fffffffffffcccccc33bb3bb333
0e8008e00e8008e00900009009000090090000900b0000b0000000000000000000000000000000000000000000087000000b70006666666666666669fbbbbbbb
00888800008888000999999009999990099999900bbbbbb00001c000000820004444400000000000000000000088870000bbb700666666669d699d69fd6ffd6f
e0e88e0ee0e88e0e988888899888888998888889b333333b001ccc00008882004444440077777000777770000287287003b73b706dddddd69d699d69fd6ffd6f
8882288888822888980880899808808998088089b303303b001ccc00008882002444444074444700722227000287287003b73b706dddddd69d699d69fd6ffd6f
0088880000888800999999999999999999999999bbbbbbbb01ccccc0088888200244444472444470722222700287287003b73b70655555569d699d69fd6ffd6f
00222200002222000080008000800080008000800030003001ccccc00888882000244444072444470722222700287800003b7b00655555569d699d69fd6ffd6f
0020020000200200008000880088008000800080003000331ccccccc88888882000222220072222700722227000280000003b0006cccccc69d699d69fd6ffd6f
0000020000200000008000000000008000800080003000001ccccccc888888820000000000077777000777770000000000000000666666669d699d69fd6ffd6f
9999999999999999099999900000000000000000000000000333333000007000000070000000000000000000000a7000000c7000666666669d699d69fd6ffd6f
9992799999917999988888890000000000000000000000003bbbbbb30000070000000700000777000007770000aaa70000ccc700666666669d699d69fd6ffd6f
99288799991cc799988888890999999000000000000000003bbbbbb300000700000007000071cc700071117009a79a7001c71c706dddddd69d699d69fd6ffd6f
99288799991cc799980880899888888900000000000000003b0bb0b3001c700000287000071cccc70711111709a79a7001c71c706dddddd69d699d69fd6ffd6f
9288887991cccc79980880899888888900000000000000003b0bb0b301cccc0002888800071cccc70711111709a79a7001c71c70655555569d699d69fd6ffd6f
9288888991ccccc9988888899808808900000000000000003bbbbbb301cccc00028888000711cc1707111117009a7a00001c7c00655555569d699d69fd6ffd6f
288888881ccccccc988888899808808909999990000000003bbbbbb3011cc1000228820000711170007111700009a0000001c000622222269d699d69fd6ffd6f
2222222211111111988888899888888998888889090909093bbbbbb3001110000022200000077700000777000000000000000000666666666666ddddfbbb3333
ffffffff99999999dd666dddddddddd666666ddd999966dd66d666999999999999999999999999d6dd6999999999999910001111dddddddd0000000000000000
ffffffff99999999d6666d6d66d666666dddd66d9966666dd6d666699999999999999999999999966d9999999966669911221333dddddddd022fffffffffff22
ffffffff99999999d666dd66d6dd66666666666696d6d66dd6ddd666999999999999999999999999d99999999666666922445555dddddddd02fffffffffffff2
ffffffff9999999966dd6666d66dd66dd6ddd66666d6ddddd6d6d6d6999999999999999999999999999999999d66666955665667dddddddd0fffffffffffffff
ffff99f999999999dd6d66666666666dd666d669d6ddd66dddd6d6d699999999999999969999999999999999ddd6666922882499dddddddd0fffffffffffffff
99f9999999999999d6666d669666666dd66dd669d666666d66d6ddd6699999999999996d99999999999999995dddd669249a13bbdddddddd0fffffffffffffff
9999999999999999d666ddd699666d66d6666699ddddd6dd66d6d666dd999999999996dd999999999999999955dddd6911cc1ddddddddddd0fffffffffffffff
9999999999999999d6666d66999666ddd6d66999ddd666d666d66ddd6d6d999999999d6d99999999999999999555dd9922ee499fdddddddd0fffffffffffffff
ffffffff1cccccccffffffff0000000000000000000000000000000020000000dddddddddddddddddddddddd0eeeeeeeeeeeee22dddddddd0fffffffffffffff
ffffffff1c6666ccff6666ff0007700000077000000770000007700002222222ddddddddddddddddddddddddeddddddddddddd20dddddddd0fffffffffffffff
ffffffffc666666cf666666f0071c70000711700007287000072270002222222ddddddddddddddddddddddddeddddddddddddd22dddddddd0fffffffffffffff
ffffffffcd66666cfd66666f0071c70000711700007287000072270002222222ddddddddddddddddddddddddeddddddddddddd20dddddddd0fffffffffffffff
f999ffffddd6666cddd6666f071ccc7007111170072888700722227002222222ddddddddddddddddddddddddeddddddddddddd22dddddddd0fffffffffffffff
999999ff5dddd66c5dddd66f071ccc7007111170072888700722227002222222ddddddddddddddddddddddddeddddddddddddd20dddddddd0fffffffffffffff
9999999955dddd6155dddd6f71ccccc771111117728888877222222702222222ddddddddddddddd2edddddddeddddddddddddd22dddddddd02fffffffffffff2
99999999c555ddc1f555ddff7777777777777777777777777777777702222222dddddddddddddd20edddddddeddddddddddddd20dddddddd022fffffffffff22
6666666600000000000000000009999999999900000999999999990000000000ddddddddddddddeeedddddddeddddddddddddd22dddddddd0000000099999999
6055dd6606666666066666660098888888888900009888888888890000000000ddddddddddddddddddddddddeddddddddddddd20ddddddddffffffff999d7999
6055dd6606777776065555560098988888898900009898888889890000202020ddddddddddddddddddddddddeddddddddddddd22ddddddddffffffff99d66799
6055dd660677777606ddddd60098898888988900009889888898890002020202ddddddddddddddddddddddddeddddddddddddd20ddddddddffffffff99d66799
6055dd660677777606ddddd60098888888888900009888888888890000202020ddddddddddddddddddddddddeddddddddddddd22ddddddddffffffff9d666679
6055dd660677777606ddddd60099999999999900009999999999990002222222ddddddddddddddddddddddddeddddddddddddd20ddddddddffffffff9d666669
6055dd6606ddddd606ddddd6098888888888889009888888888888900222222222222222dddddddddddddddd2222222222222222ddddddddffffffffd6666666
6055dd660666666606666666988888888888888998888888888888890222222220202020dddddddddddddddd2020202020202020ddddddddffffffffdddddddd
6055dd66000000000000000092888888888888899288888888888889dddddd22edddddddeeeeeeee0000000000000000000000000eeeee220fffffff00000000
6055dd66000000000000000092288888888888899228888888888889dddddd20eddddddddddddddd002022220000000002022222eddddd200fffffff00000000
6055dd66005555555555550092222888888888899222288888888889dddddd22eddddddddddddddd020222220020202000202222eddddd220fffffff00000000
6055dd66055555555555555092222228888888899222222888888889dddddd20eddddddddddddddd002022220202020202022222eddddd200fffffff00000000
6055dd66555555555555555592222222222888899222222222288889dddddd22eddddddddddddddd020222220020202000222222eddddd220fffffff00000000
6055dd66555555555555555509999999999999900999999999999990dddddd20eddddddddddddddd002022220202222202222222eddddd200fffffff00000000
6055dd66055555555555555088220000000022000022000000002288dddddd22eddddddddddddddd020222220020222202222222222222220fffffff00000000
66666666005555555555550000000000000022888822000000000000dddddd20eddddddddddddddd002022220202222202222222202020200fffffff00000000
2424050405040405040504040504242424242424242424242424242424242424242424242424242424c0c0242424242485858585858585858585858585858585
95868686868686868686a585858585859586868686868686868686868686a5000000000000000000000000000000000000000000000000000000000000000000
24241414141414141414141414142424242444a4141414141414943424242424242424242424242424c0c024242424248595868686868686868686a585858585
77b77676767676767676b686a585858577b776767676767676767676767687000000000000000000000000000000000000000000000000000000000000000000
2424741414b41414141414141414342424a4141414141414521414149434242424242444a414141414c0c014149434248577b77676767676767676b686868686
c6a7d775b175b175d77576768785858577a7e4e6e6e6e6e6e6e6e6e6f47587000000000000000000000000000000000000000000000000000000000000000000
2424647414141414141414141414b434441414b4141414141414141414943424242444a41414141414c0c014141494248577a775757575757575757676767676
76c7757575757575757516758785858577a7e7101010101010101010107587000000000000000000000000000000000000000000000000000000000000000000
24242464741414141414141414b4b414141414141414b4d2b4141414b41494242444a4141414141414c0c014141414248577a775757575757575757575757575
7575757575757575757516758785858577a7e7101010101010101010107587000000000000000000000000000000000000000000000000000000000000000000
242424246474141414141414b4b41414141414141414b4b4b41414141414842424a414141484542424c0c064141414248577a77575757575757575b597979797
c5a7d775b175b175d77575758785858577a7e5101010101010101010f57587000000000000000000000000000000000000000000000000000000000000000000
2424242424246414141414546474141414141414141414141414141414845424241414141454242424c0c024141414248596979797979797979797a685858585
77a77575757575757575b597a685858577a775757575757575757575757587000000000000000000000000000000000000000000000000000000000000000000
2424242424244414141414342424242424242424242424242424242424242424241414141434242424c0c0241414142485858585858585858585858585858585
96979797979797979797a685858585859697979797979797979797979797a6000000000000000000000000000000000000000000000000000000000000000000
2424242444a41414141414141494342424242424242424242424242424242424241414141494242424c0c0241414142424242424242424242424242424242424
9586868686868686868686868686a5859586868686868686868686868686a5000000000000000000000000000000000000000000000000000000000000000000
24242444a4141414141414141414943424242424242424242424242424242424241414521414242424c0c0241414142424a41414141414141414141414149424
77b7767676767676767676767676878577b776767676767676767676767687000000000000000000000000000000000000000000000000000000000000000000
242424a414b414141414141414141414141414149434242444a4141414149434441414141414242424c0c0241414143444141452141414b2b214141414141424
77a7e4e6e6e6e6e6e6e6e6e6f475878577a7e4e6e6e6e6e6e6e6e6e6f47587000000000000000000000000000000000000000000000000000000000000000000
2424247414141414141414141414141414141414141414141414146314141414141414141484242424c0c0241414141414141414141414141414141414148424
77a7e71010101010101010101075878577a7e7101010101010101010107587000000000000000000000000000000000000000000000000000000000000000000
2424246474141414141414141414141414141414145214141414141414141414141414148454242424c0c0247414141414141414141414141414521414145424
77a7e7b010101072101010b01075878577a7e7101010101010101010107587000000000000000000000000000000000000000000000000000000000000000000
24242424246474141414141452141414141414141414141414b4141414148454242424242424242424c0c0246474141414141414141414141414141414842424
77a7e5101010101010101010f575878577a7e5101010101010101010f57587000000000000000000000000000000000000000000000000000000000000000000
2424242424242464741414141484542424242424246474141414141414845424242424242424242424c0c02424242424242424242424b4b4b424242424242424
77a7757575757575757575757575878577a775757575757575757575757587000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424641414141454242424242424242424242424c0c0242424242424242424242414141424242424242424
9697979797979797979797979797a6859697979797979797979797979797a6000000000000000000000000000000000000000000000000000000000000000000
242424242424242424242424242424242424242424242444141414143424242424242424a414141414c0c0242424242424242424244414141434242424242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24242424242424a41414141414943424242444a41414141414b4b414149434242424242414c214c214c0c024242424242424a414141414141414141494242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242414b4141414b41494342444a456661414141414141414149424242424241414141414c0c0242424242424241414141414141414141414242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24242424242424141414821414141414e21414576714141414141414141414242424242414c214c214c0c0242424242424241414141414141414141414242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242414b4141414b4141414e3141414141414141414141414141424242424247414141414c0c0242424242424241414141414141414141414242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242474141414141414845424647414141414141414141414148424242424242424242424c0c02424242424242414f614141414141414f614242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24242424242424242424242424242424242424242424242424242424242424242424242424242424241515242424242424247414141414141414141484242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424242424242424242424c0c0242424242424242424242424242424242424242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000242424242424242424c0c0242424242424242424441414141494242424242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000002424242444a4141414c0c01414149434242444a4141414141414242424242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000024242424a414061414d0d0141414141414141414141414141484242424242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000242424247414071414d0d0141414141414141414141414845424242424242424
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbb0000000000000000000000000000000000000000000000000000000000242424246474141414c0c0141484542424242424242424242424242424242424
0b3333b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b33bb33b00000000000000000000000000000000000000000000000000000000242424242424242424c0c0242424242424242424242424242424242424242424
b3bbbb3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b3bbbb3b00000000000000000000000000000000000000000000000000000000242424242424242424c0c0242424242424242424242424242424242424242424
b33bb33b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b3333b0000000000000000000000000000000000000000000000000000000002424242424242424241515242424242424242424242424242424242424242424
00bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb333
3bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b3
3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb
bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbb
33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb
3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb
3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b
3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb
33bbb33333bbb33333bbb33333bbb333bbbbb33333bfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3b33bbb333
3bbbb3b33bbbb3b33bbbb3b33bbbb3b3b3333bb3b3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb3bbbb3b3
3bbb33bb3bbb33bb3bbb33bb3bbb33bbbbbbbbbb3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3bbb33bb
bb33bbbbbb33bbbbbb33bbbbbb33bbbb3b333bbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb33bbbb
33b3bbbb33b3bbbb33b3bbbb33b3bbbb3bbb3bbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33b3bbbb
3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bb33bbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3bbbb3bb
3bbb333b3bbb333b3bbb333b3bbb333b3bbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3bbb333b
3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3b3bbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3bbbb3bb
33bbb33333bbb333bbbbb33333bfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33bbb333
3bbbb3b33bbbb3b3b3333bb3b3fffffffffffffffffffffffffffffffffffffffffffffffbbbbbffffffffffffffffffffffffffffffffffffffffff3bbbb3b3
3bbb33bb3bbb33bbbbbbbbbb3fffffffffffffffffffffffffffffffffffffffffffffffbb3bbbbfffffffffffffffffffffffffffffffffffffffff3bbb33bb
bb33bbbbbb33bbbb3b333bbbffffffffffffffffffffffffffffffffffffffffffffffffbbbb3bbfffffffffffffffffffffffffffffffffffffffffbb33bbbb
33b3bbbb33b3bbbb3bbb3bbfffffffffffffffffffffffffffffffffffffffffffffffffb3bbbbbfffffffffffffffffffffffffffffffffffffffff33b3bbbb
3bbbb3bb3bbbb3bb3bb33bbfffffffffffffffffffffffffffffffffffffffffffffffffbbb3bbbfffffffffffffffffffffffffffffffffffffffff3bbbb3bb
3bbb333b3bbb333b3bbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbffffffffffffffffffffffffffffffffffffffffff3bbb333b
3bbbb3bb3bbbb3bb3b3bbffffffffffffffffffffffffffffffffffffffffffffffffffffff11fffffffffffffffffffffffffffffffffffffffffff3bbbb3bb
33bbb333bbbbb33333bfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3333333b
3bbbb3b3b3333bb3b3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb3bbbbb
3bbb33bbbbbbbbbb3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3b33bbbb
bb33bbbb3b333bbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3bb33bb3
33b3bbbb3bbb3bbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbb3
3bbbb3bb3bb33bbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbb3
3bbb333b3bbbbbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbb3bb
3bbbb3bb3b3bbffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbb33
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffbbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffbb3bbbbfffffffffffffffffffffffffffffffffffffffffffffffffbb3bbbbfffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffbbbb3bbfffffffffffffffffffffffffffffffffffffffffffffffffbbbb3bbfffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffb3bbbbbfffffffffffffffffffffffffffffffffffffffffffffffffb3bbbbbfffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffbbb3bbbfffffffffffffffffffffffffffffffffffffffffffffffffbbb3bbbfffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffbbbbbfffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbffffffffffffffffffffffffff
fffffffffffffffffffffffffffffffffffffffffff11ffffffffffffffffffffffffffffffffffffffffffffffffffffff11fffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffff6fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffff6fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffff2f8888f6fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffff22e22ecccffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
fffffffffffffffffffffffffff2828f1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
bb3bbbfffffffffffffffffffc1c8282ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb3333bbb333
3b3bbbbffffffffffffffffff1112222ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbb33bbbb3b3
3b333bbbfffffffffffffffffc1c828ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb3b3bb33bbb33bb
3b3b3b3bffffffffffffffffff188f88ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbb3b3333bb33bbbb
333b3b3bfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb3b333bb333b3bbbb
bb3b333bbfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb33bbbbbb33bbbb3bb
bb3b3bbb33fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffb3333333b333bbb333b
bb3bb333b3b3fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3b3333bbb3b3bbbb3bb
33bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb33333bbb333
3bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b33bbbb3b3
3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb3bbb33bb
bb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbb
33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb33b3bbbb
3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb
3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b3bbb333b
3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb3bbbb3bb
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0000010101010100000000010100010100000000000000000000000000000101000000000000000000000000000001010000000000000000000000000000010100000101010101000000000100010000000101000000000001010101010100000000000000000000010101010101000000000000000000010101000000010000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020258585859686868686868686868585858585858585858585858585858585858580000000000000000000000000000000000000000000000000000000000000000
020202040a010101010903020202020202020204010101010903020202020202020a0101010101010101010101010902020101010101010101020202020202025859686c676767676767676767785858587b67676767676767676767676767580000000000000000000000000000000000000000000000000000000000000000
0202020a010101220101010101520101010101010101010101090302020202020201011c01010101010101011c0101020201010101010101010202020202020258777b677c7d571b571b577d57785858587a4e6e6e6e6e6e6e6e6e6e6e4f57580000000000000000000000000000000000000000000000000000000000000000
02020201010b010101010101015201010101010101011c01010109020202020202010101010101010101010101010102010101010161011c010202020202020258777a61575757575757575757785858587a7e010101010101010101010157580000000000000000000000000000000000000000000000000000000000000000
0202020101010101010132010152010101010122010101010101080202020202020101610101010101010101610101020101010101010101010202020202020258777a61575757575757575757785858587a7e010101010101010101010157580000000000000000000000000000000000000000000000000000000000000000
0202020101220101010101080502020206070101010101010108050202020202020101010101010101010101010101020201010101010101010202020202020258777a57577d571b571b577d57785858587a5e010101010101010101015f57580000000000000000000000000000000000000000000000000000000000000000
020202070101010101010105020202020202020202020202020202020202020202070101010101010101010101010802020202020202020202020202020202025858795c575757575757575757785858587a57575757575757575757575757580000000000000000000000000000000000000000000000000000000000000000
0202020601010101010101020202020202020202020202020202020202020202020202020206010105020202020202020202020202020202020202020202020258585869797979797979797979585858585858585858585858585858585858580000000000000000000000000000000000000000000000000000000000000000
0202020201010101010101020202020202020202020202020202020202020202020202020204010103020202020202020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020401010101010101030202020202020202040a0101010101010101090202040a01010101010109020a01090202040a010101010101010101010101090202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202040a010101010b010109030202020202040a010101010b01010101010102020a01010b0101010b0102012c0103040a01010101010101010101010122010202040a01010101010902020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020a0122010101010101010903020202040a010101010101010101010101030401010101010101010802010101010101010b0101010101016364010101012f0101010b0101010b0102020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020701010101010101220101010902020a01010b01010101010101120101010101010101220101080502070122010101010b0101010101017374010101013f01010101013701010102020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020206010b01012201010101010101020201010101010101010101010101010101010101010101080502020601010101010101010101010101010101010101020607010b0101010b0102020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020701010101010101010101080202070101010101010101010101080502060701010108050202020202010101050607010101010101010101010101080202060701010101010802020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020652520502020202020206010105020202020202020202020601010105020202020204010101020202020202020202020202020202020202020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
020202020202020202045252030202020202020201010202020202020202020202040101080202020202040a010101020202020202020202020202020202020259685a596868685a59685a5968685a5859686868686868686868686868685a000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020a010101090202020202023b3b02020202020202020202020a01010502020202040a0101010802040a0101010903020202020202020202777b78777b676778777b78777b677858777b67676767676767676767676778000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c510c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c1e02020201010102020202040a0101010805040a010101010101010101010903020202777a6b6c7a57576b6c7a6b6c7a577858777a577d7a57577d7a575757575778000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c0c0c510c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c020204010101030202040a0101010805040a01010122010101010101010109020202777a67677c575767677c67677c577858777a57677c2657677c575757575778000000000000000000000000000000000000000000000000000000000000000000
0202020202020202020101010101010202060701010101010101011d0c0c040a01010101010101010132010105040a01010101010101010b3d0b010108020202777a5757575757575757575757577858777a577d7a57577d7a575757575778000000000000000000000000000000000000000000000000000000000000000000
02020202020202020207013c3b0101020202020206070101010b01010d0d0101010101010101010101010108020a0101010101010101010b0b0b01080502020269797979797979797979795c7a577858777a57677c5757677c575757575778000000000000000000000000000000000000000000000000000000000000000000
020202020202020202060701010108020202020202020607010101010d0d010805060701010101010101080502010105020202060701010101010805020202025858585858585858585858777a57785869797979797979797979795c7a5778000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020202020202020202060101010c0c020202020202020202020202020202010102020202020202020202020202020202025858585858585858585858777a57785858585858585858585858585d4d4d6d000000000000000000000000000000000000000000000000000000000000000000
020202020202020202020202020202020202020202020202040101010c0c0202020202020202020202020202040101025858585858585858585858585858585859686868686868686868686c7a57785858585858585858585858585d4d4d6d000000000000000000000000000000000000000000000000000000000000000000
02040a0101010101010101010101090302020202020202040a0101010c0c020202020202020202040a0101010101080258596868686868685a58585858585858777b676767676767676767677c57785859686868686868685a58585d4d4d6d000000000000000000000000000000000000000000000000000000000000000000
020a01012201010101012201010101010101010101010101010101010c0c0202020202040a010101010101010108050258777b67676767676b686868686868686c7a5757575757255757575757577858777b676767676767785858777a5778000000000000000000000000000000000000000000000000000000000000000000
020101010101010101010101010101010101010101010101010101010c0c020202040a01010b012c010805020202020258777a57575757576767676767676767677c575757575757575b795c7a577858777a615761576157785858777a5778000000000000000000000000000000000000000000000000000000000000000000
0201010b0b0b0101010b0b0b010101010101220108050202020202020c0c1e02020a010101010101050202020202020258777a575757575757575757575757575757575757255757577858777a576b686c7a5757575757576b68686c7a5778000000000000000000000000000000000000000000000000000000000000000000
020101010101010101010101010101010101010805020202020202020c0c0c0c0c0c0c0c0c0c0c0c0c0c1e020202020258777a57575757575b797979797979795c7a575757575757577858777a576767677c575757575757676767677c5778000000000000000000000000000000000000000000000000000000000000000000
020701013201010101012201010108050202020202020202020202021f0c0c0c0c0c0c0c0c0c0c0c0c0c0c020202020258777a57575757577858585858585858777a575757575757577858777a575757575757575757575757575757575778000000000000000000000000000000000000000000000000000000000000000000
020601010101010101010101010105020202020202020202020202020202020202020202020202021f0c0c020202020258697979797979796a585858585858586979797979797979796a58697979797979797979797979797979797979796a000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200001e1201e1501e1501e1302610029130291502915029150291502914029130291302912029110171001510013100111000f1001510018100221002a1002d1002e100311003110031100001000010000100
010500000c1420c1320c7502330023300233002330022300223002330024600246002360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000111501815015150071000d1500d150031000d1000c1000b1000a1000d1001210014100181001b1001c1001d1001d1001d1001b1001910017100141000010000100001000010000100001000010000100
01140000181221a1321c142211522114221132211221b11322204202041e1031b2040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400000f7500f750007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000000000000000000000000000
010400001675016750000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001875018750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400001675016750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500000e1300f130180001a00218002160020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000c1300d130185051950500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000007305003050030600311073110030500301003110730100311003110030007305003050030400300073110030100300003000730000300003000031107300003000030000300073000030000304003
001000001b0501d0501d0501b0501805013050110500f0500c0500c0500c0500c0500c0500f0501305016050160501805018050160501305011050110500f0500f0500f0500f0500f0500f050130501605018050
0010000000000160501b0500a0500f040130300c02011030160301b030240300a0300f0301b0300c04011050160500a0400703003020030302403029050290102e04029010350500c0000f000000002700033000
010500000e33002300023000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
011000001066110661106411063104621106011060200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000013000130001200011000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
011000000e01210000000020000100002000010000200001000020000100002000010000200001000020000100002000010000200001000020000100002000010000200001000020000100002000010000200001
010a00000d3500c350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000e55100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601006010060100601
0102000010271103710c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011e00001734212342103420c34200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 0a0b4344

