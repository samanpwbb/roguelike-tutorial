pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
 function _init()
 t=0

 dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}

 dirx={-1,1,0,0,1,1,-1,-1}
 diry={0,0,-1,1,-1,1,1,-1}

 crv_sig={0b11111111,0b11010110,0b01111100,0b10110011,0b11101001}
 crv_msk={0,0b00001001,0b00000011,0b00001100,0b00000110}

 mob_ani={240,192}
 mob_atk={1,    1}
 mob_hp ={5,    1}
 mob_los={4,    4}

 itm_name={"wooden sword","heavy armor","hot peppers","rock","big hammer"}
 itm_type={"wep","arm","fud","thr","wep"}
 itm_stat1={1,0,1,1,2}
 itm_stat2={0,2,0,0,0}

 startgame()
end

function _update60()
 t+=1
 _upd()
 dofloats()
 dohpwind()
end

function _draw()
 _drw()
 drawind()
 fadeperc=0
 --checkfade()
end

function startgame()
 fadeperc=1
 btnbuff=-1
 skipai=false
 win=false
 winfloor=9

 thrdx,thrdy=2,0,-1

 mob={}
 dmob={}
 p_mob=addmob(1,1,1)

 p_t=0

 inv,eqp={},{}

 wind={}
 float={}
 fog=blankmap(0)
 talkwind=nil

 hpwind=addwind(5,5,28,13,{})
 _upd=update_game
 _drw=draw_game
 genfloor(0)
 unfog()
 calcdist(p_mob.x,p_mob.y)

end

-->8
--updates
function update_game()
 if talkwind then
  if getbtn()==5 then
   talkwind.dur=0
   talkwind=nil
  end
 else
  dobtnbuff()
 	dobtn(btnbuff)
  btnbuff=-1
 end
end

function update_inv()
 move_mnu(curwind)
 if btnp(4) then
  if curwind==invwind then
   _upd=update_game
   invwind.dur=0
   statwind.dur=0
  elseif curwind==usewind then
   usewind.dur=0
   curwind=invwind
  end
 elseif btnp(5) then
  if curwind==invwind and invwind.cur!=3 then
   showuse()
  elseif curwind==usewind then
   triguse()
  end
 end
end

function update_throw()
 local b=getbtn()
 if b>=0 and b<=3 then
  thrdir=b
 end
 thrdx=dirx[thrdir+1]
 thrdy=diry[thrdir+1]
 if b==4 then
  _upd=update_game
 elseif b==5 then
  throw()
 end

end

function move_mnu(wnd)
 if btnp(2) then
  wnd.cur-=1
 elseif btnp(3) then
  wnd.cur+=1
 end
 wnd.cur=(wnd.cur-1)%#wnd.txt+1
end

function update_pturn()
 dobtnbuff()
 p_t=min(p_t+0.2,1)

 if p_mob.mov then
  p_mob:mov()
 end

 if p_t==1 then
 	_upd=update_game
  if trig_step() then return end
 	if checkend() and not skipai then
   doai()
 	end
  skipai=false
 end
end

function update_aiturn()
 dobtnbuff()
 p_t=min(p_t+0.2,1)
 for m in all(mob) do
  if m!=p_mob and m.mov then
   	m:mov(m)
  end
 end
 if p_t==1 then
 	_upd=update_game
  checkend()
 end
end

function update_gover()
 if btnp(❎) then
  fadeout()
  startgame()
 end
end

function dobtnbuff()
 if btnbuff==-1 then
	 btnbuff=getbtn()
	end
end

function getbtn()
 for i=0,5 do
	 if btnp(i) then
	 	return i
 	end
 end
 return -1
end

function dobtn(bt)
 if bt<0 then return end
 if bt<4 then
	 moveplayer(dirx[bt+1],diry[bt+1])
 elseif bt==5 then
  showinv()
 elseif bt==4 then
  genfloor(floor)
 end
end

-->8
--draw
function draw_game()
 cls(0)
 -- short circuit if blank
 if fadeperc==1 then return end
 map()

 --death sequence
 for m in all(dmob) do
  if sin(time()*8)>0 then
   drawmob(m)
  end
  m.dur-=1
  if m.dur<=0 then
   del(dmob,m)
  end
 end

 --mobs
 for i=#mob,1,-1 do
  drawmob(mob[i])
 end
 drawmob(p_mob)

 --throw
 if _upd==update_throw then
  local tx,ty=throwtile()
  local lx1,ly1,lx2,ly2=p_mob.x*8+3+thrdx*4,p_mob.y*8+3+thrdy*4,mid(0,tx*8+3,127),mid(0,ty*8+3,127)

  rectfill(lx1+thrdy,ly1+thrdx,lx2-thrdy,ly2-thrdx,0)
  local thrani=flr(t/7)%2==0

  local pat=thrani and 0b1010010110100101 or 0b0101101001011010
  fillp(pat)

  line(lx1,ly1,lx2,ly2,14)
  fillp()
  oprint8("+",lx2-1,ly2-2,14,0)

  local mb=getmob(tx,ty)
  if mb and thrani then
   mb.flash=1
  end
 end

 --fog
 visbrd(function(x,y)
  if fog[x][y]==1 then
   rectfill2(x*8,y*8,8,8,0)
  end
 end)

 --floating text
 for f in all(float) do
  oprint8(f.txt,f.x,f.y,f.c,0)
 end
end

function drawmob(m)
 local col=12
 if m.flash>0 then
  m.flash-=1
  col=7
 end
 drawspr(getframe(m.ani),m.x*8+m.ox,m.y*8+m.oy,col,m.flp)
end

function draw_gover()
 cls(0)
 print("you died",50,50,14)
end

function draw_win()
 cls(0)
 print("you won",50,50,14)
end
-->8
--tools

function getframe(ani)
 return ani[flr(t/15)%#ani+1]
end

function drawspr(_spr,_x,_y,_c, _flip)
	palt(0,false)
	pal(12,_c)
	pal(12,_c)
	spr(_spr,_x - (_flip and 1 or 0),_y,1,1,_flip)
	pal()
end

function rectfill2(_x,_y,_w,_h,_c)
 --★
 rectfill(_x,_y,_x+max(_w-1,0),max(_y+_h-1,0),_c)
end

function oprint8(_t,_x,_y,_c,_c2)
 for i=1,8 do
  print(_t,_x+dirx[i],_y+diry[i],_c2)
 end
 print(_t,_x,_y,_c)
end

function dist(fx,fy,tx,ty)
 return sqrt((fx-tx)^2+(fy-ty)^2)
end

function dofade()
 local p,kmax,col,k=flr(mid(0,fadeperc,1)*100)
 for j=1,15 do
  col=j
  kmax=flr((p+j*1.5)/20)
  for k=1,kmax do
   col=dpal[col]
  end
  pal(j,col,1)
 end
end

function checkfade()
 if fadeperc>0 then
  fadeperc=max(fadeperc-0.04,0)
  dofade()
 end
end

function wait(_wait)
 repeat
  _wait-=1
  flip()
 until _wait<0
end

function fadeout(spd,_wait)
 if (spd==nil) spd=0.04
 if (_wait==nil) _wait=0
 repeat
  fadeperc=min(fadeperc+spd,1)
  dofade()
  flip()
 until fadeperc==1
 wait(_wait)
end

function blankmap(_dflt)
 local ret={}
 if(_dflt==nil) _dflt=0

 for x=0,15 do
  ret[x]={}
  for y=0,15 do
   ret[x][y]=_dflt
  end
 end
 return ret
end

function getrnd(arr)
 return arr[1+flr(rnd(#arr))]
end

function visit(cb,xmin,xmax,ymin,ymax)
 for x=xmin,xmax do
  for y=ymin,ymax do
   cb(x,y)
  end
 end
end

function visbrd(cb)
 return visit(cb,0,15,0,15)
end

function copymap(x,y)
 local tle
 visbrd(function(_x,_y)
  tle=mget(x+_x,_y+y)
  mset(_x,_y,tle)
  if tle==15 then
   p_mob.x,p_mob.y=_x,_y
  end
 end)
end
-->8
--gameplay

function moveplayer(dx,dy)
 local destx,desty=p_mob.x+dx,p_mob.y+dy
 local tle=mget(destx,desty)

 if iswalkable(destx,desty,"checkmobs") then
  sfx(63)
  mobwalk(p_mob,dx,dy)
  p_t=0
 	_upd=update_pturn
 else
  --not walkable
  mobbump(p_mob,dx,dy)
  p_t=0
  _upd=update_pturn

  local mob=getmob(destx,desty)
  if mob then
   sfx(58)
	  hitmob(p_mob,mob)
 	else
  	if fget(tle,1) then
	   trig_bump(tle,destx,desty)
	  else
	   skipai=true
     mset(destx,desty,1)
  	end
 	end
 end
 unfog()
end

function trig_bump(tle, destx, desty)
 if tle==7 or tle==8 then
 	--vase
 	sfx(59)
 	mset(destx,desty,1)

 	if rnd(3)<1 then
  	local itm=flr(rnd(#itm_name))+1
  	takeitem(itm)
   showmsg(itm_name[itm],100)
 	end
 elseif tle==6 then
  --tablet
  if floor==winfloor then
   win=true
  elseif floor==0 then
   showtalk({"do not disturb!","this is a sanctuary","for peaceful monsters"})
  end
 elseif tle==10 or tle==12 then
 	--chest
 	sfx(61)
 	mset(destx,desty,tle-1)
 	local itm=flr(rnd(#itm_name))+1
 	takeitem(itm)
  showmsg(itm_name[itm])
 elseif tle==13 then
	 --door
 	sfx(62)
 	mset(destx,desty,1)
 end
end

function trig_step()
 local tle=mget(p_mob.x,p_mob.y)

 if tle==14 then
  fadeout()
  genfloor(floor+1)
  floormsg()
  return true
 end
 return false
end

function getmob(x,y)
 for m in all(mob) do
  if m.x==x and m.y==y then
   return m
  end
 end
 return false
end

function iswalkable(x,y,mode)
 local mode=mode or ""
 if inbounds(x,y) then
  local tle=mget(x,y)
  if mode=="sight" then
   return not fget(tle,2)
  end
  if not fget(tle,0) then
   if mode=="checkmobs" then
    return not getmob(x,y)
   end
   return true
  end
 end
 return false
end

function inbounds(x,y)
 return not (x<0 or y<0 or x>15 or y>15)
end

function hitmob(atkm,defm)
 local dmg=atkm.atk

 dmg-=defm.defmin+flr(rnd(defm.defmax-defm.defmin+1))
 dmg=max(0,dmg)
 defm.hp-=dmg
 defm.flash=10

 addfloat("-"..dmg,defm.x*8,defm.y*8,14)

 if defm.hp<=0 then
  defm.dur=15
  add(dmob,defm)
  del(mob,defm)
 end
end

function healmob(mb,hp)
 hp=min(mb.hpmax-mb.hp,hp)
 mb.hp+=hp
 mb.flash=10

 addfloat("+"..hp,mb.x*8,mb.y*8,14)
end

function checkend()
 if win then
  wind={}
  _upd=update_gover
  _drw=draw_gover
  fadeout(0.02)
  return false
 elseif p_mob.hp<=0 then
  wind={}
  _upd=update_gover
  _drw=draw_gover
  fadeout(0.02)
  return false
 end
 return true
end

function los(x1,y1,x2,y2)
 local frst,sx,sy,dx,dy=true
 if dist(x1,y1,x2,y2)==1 then
  return true
 end
 if x1<x2 then
  sx,dx=1,x2-x1
 else
  sx,dx=-1,x1-x2
 end
 if y1<y2 then
  sy,dy=1,y2-y1
 else
  sy,dy=-1,y1-y2
 end
 local err,e2=dx-dy

 while not(x1==x2 and y1==y2) do
  if not frst and iswalkable(x1,y1,"sight")==false then
   return false
  end
  frst=false
  e2=err+err
  if e2>-dy then
   err-=dy
   x1+=sx
  end
  if e2<dx then
   err+=dx
   y1=y1+sy
  end
 end
 return true
end

function unfog()
 local px,py=p_mob.x,p_mob.y
 for x=0,15 do
  for y=0,15 do

   if fog[x][y]==1 and dist(px,py,x,y)<=p_mob.los and los(px,py,x,y) then
    unfogtile(x,y)
   end
  end
 end
end

function unfogtile(x,y)
 fog[x][y]=0
 --note:can be out of p_mob.los
 if iswalkable(x,y,"sight") then
  for i=1,4 do
   local tx,ty=x+dirx[i],y+diry[i]
   if inbounds(tx,ty) and not iswalkable(tx,ty,"sight") then
    fog[tx][ty]=0
   end
  end
 end
end

function calcdist(tx,ty)
 local cand,step,candnew={},0
 distmap=blankmap(-1)
 add(cand, {x=tx,y=ty})
 distmap[tx][ty]=0
 repeat
  step+=1
	 candnew={}
	 for c in all(cand) do
	  for d=1,4 do
	   local dx=c.x+dirx[d]
	   local dy=c.y+diry[d]
	   if inbounds(dx,dy) and distmap[dx][dy]==-1 then
  	  distmap[dx][dy]=step
     if iswalkable(dx,dy) then
 	    add(candnew,{x=dx,y=dy})
	    end
	   end
	  end
	 end
  cand=candnew
 until #cand==0
end

function updatestats()
 if eqp[1] then
  p_mob.atk=1+itm_stat1[eqp[1]]
 end
 if eqp[2] then
  p_mob.defmin=0+itm_stat1[eqp[2]]
  p_mob.defmax=0+itm_stat2[eqp[2]]
 end
end

function eat(itm,mb)
 local effect=itm_stat1[itm]

 if effect==1 then
  --heal
  healmob(mb,1)
 end
end

function throw()
 local itm,tx,ty=inv[thrslt],throwtile()

 if inbounds(tx,ty) then
  local mb=getmob(tx,ty)
  if mb then
   if itm_type[thrslt]=="fud" then
    eat(itm,mb)
   else
    hitmob({atk=itm_stat1[thrslt]},mb)
    sfx(58)
   end
  end
 end

 mobbump(p_mob,thrdx,thrdy)

 inv[thrslt]=nil
 p_t=0
 _upd=update_pturn
end

function throwtile()
 local tx,ty=p_mob.x,p_mob.y
 repeat
  tx+=thrdx
  ty+=thrdy
 until not iswalkable(tx,ty,"checkmobs")
 return tx,ty
end
-->8
--ui

function addwind(_x,_y,_w,_h,_txt)
 return add(wind,{x=_x,
                  y=_y,
                  w=_w,
                  h=_h,
                  txt=_txt})
end

function drawind()
 for w in all(wind) do
  local wx,wy,ww,wh=w.x,w.y,w.w,w.h
  rectfill2(wx,wy,ww,wh,0)
  rect(wx+1,wy+1,wx+ww-2,wy+wh-2,14)
  wx+=4
  wy+=4
  clip(wx,wy,ww-8,wh-8)

  if w.cur then
   wx+=6
  end

  for i=1,#w.txt do
   local t,c=w.txt[i],14
   if w.col and w.col[i] then
    c=w.col[i]
   end

   print(t,wx,wy,c)
   if i==w.cur then
    spr(255,wx-5+(sin(time())/2),wy)
   end
   wy+=6
  end

  -- clear clip to draw btn outside
  clip()

  if w.dur then
   w.dur-=1
   if w.dur<=0 then
    local dif=w.h/4
    w.y+=dif/2
    w.h-=dif
    if w.h<3 then
     del(wind,w)
    end
   end
  else
   if w.btn then
    oprint8("❎",wx+ww-15,wy-0.5+sin(time()),14,0)
   end
  end
 end
end

function showmsg(txt,dur)
 local wid=(#txt+2)*4+7
 local w=addwind(63-wid/2,50,wid,13,{" "..txt})
 w.dur=dur
end

function showtalk(txt)
 talkwind=addwind(16,50,94,#txt*6+7,txt)
 talkwind.btn=true
end

function addfloat(_txt,_x,_y,_c)
 add(float, {txt=_txt,x=_x,y=_y,c=_c,ty=_y-7,t=0})
end

function dofloats()
 for f in all(float) do
  f.y+=(f.ty-f.y)/10
  f.t+=1
  if f.t>50 then
   del(float,f)
  end
 end
end

function dohpwind()
  hpwind.txt[1]="♥"..p_mob.hp.."/"..p_mob.hpmax
  local hpy=5
  if p_mob.y<8 then
   hpy=110
  end
  hpwind.y+=(hpy-hpwind.y)/5
end

function showinv()
 local txt,col,itm,eqt={},{}
 _upd=update_inv

 for i=1,2 do
  itm,eqt=eqp[i]
  if itm then
   eqt=itm_name[itm]
   add(col,7)
  else
   eqt=i==1 and "[weapon]" or "[armor]"
   add(col,2)
  end
  add(txt,eqt)
 end

 add(txt,"………………")
 add(col,14)

 for i=1,6 do
  itm=inv[i]
  if itm then
   add(txt,itm_name[itm])
   add(col,7)
  else
   add(txt,"...")
   add(col,2)
  end
 end

 invwind=addwind(5,17,84,62,txt)
 invwind.cur=1
 invwind.col=col

 statwind=addwind(5,5,84,13,{"atk:"..p_mob.atk.." def:"..p_mob.defmin.."-"..p_mob.defmax})
 curwind=invwind
end

function showuse()
 local itm=invwind.cur<3 and eqp[invwind.cur] or inv[invwind.cur-3]
 if itm==nil then return end
 local typ,txt=itm_type[itm],{}

 if invwind.cur>3 and (typ=="wep" or typ=="arm") then
  add(txt,"equip")
 end

 if typ=="fud" then
  add(txt,"eat")
 end

 if typ=="thr" or typ=="fud" then
  add(txt,"throw")
 end
 add(txt,"trash")

 usewind=addwind(84,invwind.cur*6+11,36,7+#txt*6,txt)
 usewind.cur=1
 curwind=usewind
end

function triguse()
 local verb,i,back=usewind.txt[usewind.cur],invwind.cur,true
 local itm=i<3 and eqp[i] or inv[i-3]

 if verb=="trash" then
  if i<3 then
   eqp[i]=nil
  else
   inv[i-3]=nil
  end
 elseif verb=="equip" then
  local slot=itm_type[itm]=="wep" and 1 or 2
  inv[i-3]=eqp[slot]
  eqp[slot]=itm
 elseif verb=="eat" then
  eat(itm,p_mob)
  inv[i-3]=nil
  p_mob.mov=nil
  p_t=0
  _upd=update_pturn
  back=false
 elseif verb=="throw" then
  _upd,thrslt,back=update_throw,inv[i-3],false
 end

 updatestats()
 usewind.dur=0

 if back then
  del(wind,invwind)
  del(wind,statwind)
  showinv()
  invwind.cur=i
 else
  invwind.dur=0
  statwind.dur=0
  p_t=0
 end
end

function floormsg()
 showmsg("floor "..floor,120)
end
-->8
--mobs
function addmob(typ,mx,my)
 local m={
  x=mx,
  y=my,
  ox=0,
  oy=0,
  flp=false,
  ani={},
  flash=0,
  defmin=0,
  defmax=0,
  hp=mob_hp[typ],
  hpmax=mob_hp[typ],
  atk=mob_atk[typ],
  los=mob_los[typ],
  task=ai_wait
 }

 for i=0,3 do
  add(m.ani,mob_ani[typ]+i)
 end
 add(mob,m)
 return m
end

function mobwalk(mb,dx,dy)
 mb.x+=dx
 mb.y+=dy

 mobflip(mb,dx)
 mb.sox,mb.soy=-dx*8,-dy*8
 mb.ox,mb.oy=mb.sox,mb.soy
 mb.mov=mov_walk
end

function mobbump(mb,dx,dy)
 mobflip(mb,dx)
 mb.sox,mb.soy=dx*8,dy*8
 mb.ox,mb.oy=0,0
 mb.mov=mov_bump
end

function mobflip(mb,dx)
 mb.flp=dx==0 and mb.flp or dx<0
end

function mov_walk(self)
 local tme=1-p_t
 self.ox=self.sox*tme
 self.oy=self.soy*tme
end

function mov_bump(self)
 local tme=p_t>0.5 and 1-p_t or p_t
 self.ox=self.sox*tme
 self.oy=self.soy*tme
end

function doai()
 local moving=false
 for m in all(mob) do
  if m!=p_mob then
   m.mov=nil
   moving=m.task(m) or moving
  end
 end
 if moving then
  _upd=update_aiturn
  p_t=0
 end
end

function ai_wait(m)
 if cansee(m,p_mob) then
  --aggro
  m.task=ai_atk
  m.tx,m.ty=p_mob.x,p_mob.y
  addfloat("!",m.x*8+2,m.y*8,10)
  return true
 end
 return false
end

function ai_atk(m)
 if dist(m.x,m.y,p_mob.x,p_mob.y)==1 then
  --attack
  dx,dy=p_mob.x-m.x,p_mob.y-m.y
  mobbump(m,dx,dy)
  hitmob(m,p_mob)
  sfx(57)
  return true
 else
  --move
  --update los
  if cansee(m,p_mob) then
   m.tx,m.ty=p_mob.x,p_mob.y
  end

  if m.x==m.tx and m.y==m.ty then
   --drop aggro
   --TODO: seems buggy
   m.task=ai_wait
   addfloat("?",m.x*8+2,m.y*8,10)
  else
   --move to player
   local bdst,cand=999,{}
   calcdist(m.tx,m.ty)
   for i=1,4 do
    local dx,dy=dirx[i],diry[i]
    local tx,ty=m.x+dx,m.y+dy
    if iswalkable(tx,ty,"checkmobs") then
     local dst=distmap[tx][ty]
     if dst<bdst then
      cand={}
      bdst=dst
     end

     if dst==bdst then
      add(cand,i)
     end
    end
   end
   if #cand>0 then
    local c=getrnd(cand)
    mobwalk(m,dirx[c],diry[c])
    return true
   end
  end
 end
 return false
end

function cansee(m1,m2)
 return dist(m1.x,m1.y,m2.x,m2.y)<=m1.los and los(m1.x,m1.y,m2.x,m2.y)
end

function spawnmobs()
 minmons=4
 local placed,rpot=0,{}

 for r in all(rooms) do
  add(rpot,r)
 end

 repeat
  local r=getrnd(rpot)
  placed+=infestroom(r)
  del(rpot,r)
 until #rpot==0 or placed>minmons
end

function infestroom(r)
 local target=2+flr(rnd(3))
 local x,y

 for i=1,target do
  repeat
   x=r.x+flr(rnd(r.w))
   y=r.y+flr(rnd(r.h))
  until iswalkable(x,y,"checkmobs")
  addmob(2,x,y)
 end

 return target
end

-----------------------
--items
-----------------------

function takeitem(itm)
 local i=freeinvslot()
 if i==0 then return false end
 inv[i]=itm
 return true
end

function freeinvslot()
 for i=1,6 do
  if not inv[i] then
   return i
  end
 end
 return 0
end

-->8
--gen
function genfloor(f)
 floor=f

 -- clear mobs
 mob={}
 add(mob,p_mob)

 if floor==0 then
  copymap(16,0)
 elseif floor==winfloor then
  copymap(32,0)
 else
  mapgen()
 end
end

function mapgen()
 --fill map with obstacles
 copymap(48,0)

 --globals
 rooms={}
 roomap=blankmap(0)
 doors={}

 --generate!
 genrooms()
 mazeworm()
 placeflags()
 carvedoors()
 carvescuts()
 startend()
 fillends()
 placedoors()
 spawnmobs()
end

function snapshot()
 cls()
 map()
 for i=0,3 do
  flip()
 end
end

----------------
--rooms
----------------

function genrooms()
 local fmax,rmax,mw,mh=5,5,6,6
 local xbase,ybase=flr(rnd(2)),flr(rnd(2))
 repeat
  local r=rndroom(mw,mh)
  if placeroom(r,xbase,ybase) then
   rmax-=1
   snapshot()
  else
   fmax-=1
   if r.w>r.h then
    mw=max(mw-1,3)
   else
    mh=max(mh-1,3)
   end
  end
 until fmax<=0 or rmax<=0
end

function rndroom(mw,mh)
 local w=3+flr(rnd(mw-2))
 --all rooms have odd x,y
 if (w%2==0) then
  w-=1
 end

 mh=mid(35/w,3,mh)
 local h=3+flr(rnd(mh-2))

 if (h%2==0) then
  h-=1
 end

 return {
  x=0,
  y=0,
  w=w,
  h=h
 }
end

function placeroom(r,xbase,ybase)
 local cand,c={}
 local odd=flr(rnd(2))
 visit(function(x,y)

   if x%2!=xbase and y%2!=ybase and doesroomfit(r,x,y) then
    add(cand,{x=x,y=y})
   end
  end,
  0,16-r.w,0,16-r.h)

 if #cand==0 then return false end
 c=getrnd(cand)
 r.x=c.x
 r.y=c.y

 add(rooms,r)
 visit(function(x,y)
   mset(x+r.x,y+r.y,1)
   roomap[x+r.x][y+r.y]=#rooms
  end,
  0,r.w-1,0,r.h-1)

 return true
end

function doesroomfit(r,x,y)
 for _x=-1,r.w do
  for _y=-1,r.h do
   if iswalkable(_x+x,_y+y) then
    return false
   end
  end
 end
 return true
end

----------------
-- maze
----------------

function mazeworm()
 repeat
	 local cand={}
	 visbrd(
	  function(x,y)
	   if cancarve(x,y,false) and not nexttoroom(x,y) then
	    add(cand,{x=x,y=y})
	   end
	  end)

	 if #cand>0 then
	  local c=getrnd(cand)
	  digworm(c.x,c.y)
	 end
 until #cand<=1

 --carve out excess chunks
 repeat
  local cand={}
  visbrd(function(x,y)
   if cancarve(x,y,false) and not nexttoroom(x,y) then
    add(cand,{x=x,y=y})
   end
  end)
  if #cand>0 then
	  local c=getrnd(cand)
	  mset(c.x,c.y,1)
	 end
 until #cand==0
end

function digworm(x,y)
 local dr,step=1+flr(rnd(4)),0

 repeat
  mset(x,y,1)
  snapshot()
  if not cancarve(x+dirx[dr],y+diry[dr],false) or (rnd()<0.5 and step>=2) then
   local cand={}
   for i=1,4 do
    if cancarve(x+dirx[i],y+diry[i],false) then
     add(cand,i)
    end
   end
   if #cand==0 then
    dr=8
   else
    step=0
    dr=getrnd(cand)
   end
  end
  x+=dirx[dr]
  y+=diry[dr]
  step+=1
 until dr==8

end

function cancarve(x,y,walk)
 if not inbounds(x,y) then return false end
 local walkable=iswalkable(x,y)
 local walk=walk==nil and walkable or walk

 if walkable==walk then
  local sig=getsig(x,y)
  for i=1,#crv_sig do
   if bcomp(sig,crv_sig[i],crv_msk[i]) then
    return true
   end
  end
 end
 return false
end

function bcomp(sig,match,mask)
 local mask=mask or 0
 return sig|mask==match|mask
end

function getsig(x,y)
 --binary digit 4 some reason
 local sig, digit=0
 for i=1,8 do
  local dx,dy=x+dirx[i],y+diry[i]
  if iswalkable(dx,dy) then
   digit=0
  else
   digit=1
  end
  sig=bor(sig,shl(digit,8-i))
 end
 return sig
end

----------------
-- doorways
----------------

function placeflags()
 local curf=1
 flgs=blankmap(0)
 visbrd(function(x,y)
  if iswalkable(x,y) and flgs[x][y]==0 then
   growflag(x,y,curf)
   curf+=1
  end
 end)
end

function growflag(x,y,flg)
 local cand,candnew={{x=x,y=y}}
 flgs[x][y]=flg

 repeat
  candnew={}
  for c in all(cand) do
   flgs[c.x][c.y]=flg
   for d=1,4 do
    local dx,dy=c.x+dirx[d],c.y+diry[d]
    if iswalkable(dx,dy) and flgs[dx][dy]!=flg then
     flgs[dx][dy]=flg
     add(candnew,{x=dx,y=dy})
    end
   end
  end
  cand=candnew
 until #cand==0
end

function carvedoors()
 local x1,y1,x2,y2,found,drs,f1,f2=1,1,1,1

 repeat
  drs={}
  visbrd(function(x,y)
   if not iswalkable(x,y) then
    local sig=getsig(x,y)
    found=false
    --is 1 space gap btwn rooms
    if bcomp(sig,0b11000000,0b00001111) then
     x1,y1,x2,y2,found=x,y-1,x,y+1,true
    elseif bcomp(sig,0b00110000,0b00000000) then
     x1,y1,x2,y2,found=x+1,y,x-1,y,true
    end
    f1=flgs[x1][y1]
    f2=flgs[x2][y2]

    if found and f1!=f2 then
     add(drs,{x=x,y=y,f=f1})
    end
   end
  end)

	 if #drs>0 then
	  local d=getrnd(drs)
	  if isdoor(d.x,d.y) then
 	  add(doors,d)
   end
   mset(d.x,d.y,1)
   snapshot()
	  growflag(d.x,d.y,d.f)
	 end
 until #drs==0

end

function carvescuts()
 local x1,y1,x2,y2,found,cut,drs=1,1,1,1,false,0,{}

 repeat
  drs={}
  visbrd(function(x,y)
   if not iswalkable(x,y) then
    local sig=getsig(x,y)
    found=false
    --is 1 space gap btwn rooms?
    if bcomp(sig,0b11000000,0b00001111) then
     x1,y1,x2,y2,found=x,y-1,x,y+1,true
    elseif bcomp(sig,0b00110000,0b00000000) then
     x1,y1,x2,y2,found=x+1,y,x-1,y,true
    end

    if found then
     calcdist(x1,y1)
     if distmap[x2][y2]>20 then
      add(drs,{x=x,y=y})
     end
    end
   end
  end)

	 if #drs>0 then
	  local d=getrnd(drs)
	  if isdoor(d.x,d.y) then
 	  add(doors,d)
   end
   mset(d.x,d.y,1)
   snapshot()
   cut+=1
	 end
 until #drs==0 or cut>=3
end

function fillends()
 local filled,tle
 repeat
 	filled=false

  visbrd(function(x,y)
   local tle=mget(x,y)
   if cancarve(x,y,true) and tle!=14 and tle!=15 then
    filled=true
    mset(x,y,2)
    snapshot()
   end
  end)
 until not filled
end

function isdoor(x,y)
 local sig=getsig(x,y)
 if bcomp(sig,0b11000000,0b00001111) or bcomp(sig,0b00110000,0b00001111) then
  return nexttoroom(x,y)
 end
 return false
end

function nexttoroom(x,y)
	for i=1,4 do
	 if inbounds(x+dirx[i],y+diry[i]) and
	    roomap[x+dirx[i]][y+diry[i]]!=0 then
 	 return true
	 end
 end
 return false
end

function placedoors()
 for d in all(doors) do
  if mget(d.x,d.y)==1 and isdoor(d.x,d.y) then
   mset(d.x,d.y,13)
  end
 end
end

----------------
-- decoration
----------------

function startend()
 local high,low,px,py=0,9999

 repeat
  px,py=flr(rnd(16)),flr(rnd(16))
 until iswalkable(px,py)

 calcdist(px,py)
 visbrd(function(x,y)
  local tmp=distmap[x][y]
  if iswalkable(x,y) and tmp>high then
   px,py,high=x,y,tmp
  end
 end)

 calcdist(px,py)
 high=0
 visbrd(function(x,y)
  local tmp=distmap[x][y]
  if tmp>high and cancarve(x,y) then
   ex,ey,high=x,y,tmp
  end
 end)
 mset(ex,ey,14)

 visbrd(function(x,y)
  local tmp=distmap[x][y]
  if tmp>=0 and tmp<low and cancarve(x,y) then
   px,py,low=x,y,tmp
  end
 end)
 mset(px,py,15)

 p_mob.x=px
 p_mob.y=py
end
__gfx__
00000000000000000000000000f2f00000000000000000000aaaaa0000aaa00000aaa00000000000000000000000000000a9a0000aaaaa000aaaaa0001111110
00000000001000000b303b000f2e2f0000b0b000000000009aaaaaa00a000a000a000a000666660000aaa0006666666099aaa9a0900000a0900000a010000000
007007000000000000b0b00000f2f000000b000000000000900000a00a000a000a000a0006000600099a9a0060000060900000a0909aa0a0900000a010000000
0007700000001000b30b03b0b30b03b0b00300b000000000009a900009aaa00099aaa0a00666660009aaaa0060000060900900a09099a0a0900000a010000010
00077000000000000b030b000b0b0b000b030b000b030b00900000a00a99aa009a99aaa00000000000000000666666609aa0aaa0909aa0a0900009a010000110
007007000100000000b3b00000b3b00000b3b00000b0b00090a9a0a009aaaa0009aaaa000666660009aaaa0000000000000000009099a0a0900099a010001110
0000000000000100000300000003000000030000000b0000900000a0009aa000009aa0000666660009aaaa00666666609aaaaaa0909aa0a0900999a001111110
00000000000000000000000000000000000000000000000009aaaa00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000008000000090000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000c00000000c0000000000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ccc000000cc000000c000000cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccccc0000cccc0000ccc0000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc0c0cc00ccc0cc00ccccc00cc0ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc0ccc0ccc0ccc0cc0c0cc0ccc0ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccccc0ccccccc0ccc0ccc0ccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ccccc000ccccc000ccccc000ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000cc00000000000000cc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
00cc00000c00c00000cc00000c00c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
0c00c0000c00c0000c00c0000c00c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000
0c00c0c00cccc0c00c00c0c00cccc0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
0cccc0c00cccc0c00cccc0c00cccc0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000
ccccccc00cccccc00cccccc0ccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccccc0c00cccc0c00ccc00c0cccc00c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000050505000303030303030307020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000003020405000000010100000001040203030204050000000101000000010402030202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002040100000000000001000001050402020401000000000000010000010504020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000004050100000000000000000001010104040501000002020202020200010101040202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000005010000000000000000000001000101050100000303030303030303010001010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000100000001040401010000000000000001030401010101010104030000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000101020e0202010000010000000000030101010601010101030100000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000010407010101040100000000000000030101010101010101030000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000050401010608040501000000000000030501010101010105030000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000010401010101040101000000000000000304010101010403010000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000010000010408070f0104050100000000010000010402010f020405010000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000402020202040105000000000000000004020202020401050000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000104040404010100000000000000000001040404040101000000000202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001000105000000010100000000000101010001050000000101000000000001010202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000004050100000000000000000001000504040501000000000000000000010005040202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002040501000000010000000000050402020405010000000100000000000504020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000003020401000000000000000001040203030204010000000000000000010402030202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000211102114015140271300f6300f6101c610196001761016600156100f6000c61009600076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001b61006540065401963018630116100e6100c610096100861000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f5302b5302e5302e5303250032500395002751027510285102a510005000050000500275102951029510005000050000500005002451024510245102751029510005000050000500005000050000500
0001000024030240301c0301c0302a2302823025210212101e2101b2101b21016210112100d2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100020000200
0001000024030240301c0301c03039010390103a0103001030010300102d010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000210302703025040230301a030190100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000d720137200d7100c40031200312000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
