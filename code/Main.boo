namespace frozen

import System
import OpenTK
#import OpenTK.Graphics


[STAThread]
def Main(argv as (string)):
	using win = kri.Window('kri.conf',0):
		ce = win.core.extensions
		ce.Add( support.skin.Extra() )
		ce.Add( support.mirror.Extra() )
		ce.Add( corp = support.corp.Extra() )
		corp.bake.filt = true
		view = kri.ViewScreen(0,0,8,0)
		rchain = kri.rend.Chain()
		win.views.Add( view )
		win.VSync = VSyncMode.On
		
		ln = kri.load.Native()
		heli	= ln.read('res/helicopter.scene')
		level	= ln.read('res/terrain.scene')
		turret	= ln.read('res/turret.scene')
		turret	= null
		
		view.scene = level.scene
		view.scene.entities.AddRange( heli.scene.entities )
		view.cam = level.scene.cameras[0]
		view.cam.setRanges(3f,30f)
		lit = view.scene.lights[0]
		lit.makeOrtho(100f)
		
		licon = kri.rend.light.Context(1,10)
		licon.setExpo(120f, 0.5f)
		view.ren = rchain
		rlis = rchain.renders
		
		rlis.Add( support.skin.Update(true) )
		rlis.Add( support.bake.surf.Update(0,corp.bake.filt) )
		rlis.Add( kri.rend.EarlyZ() )
		rlis.Add( kri.rend.Emission() )
		rlis.Add( kri.rend.light.Fill(licon) )
		rlis.Add( kri.rend.light.Apply(licon) )
		rlis.Add( kri.rend.part.Standard( corp.con ) )
		#rlis.Add( kri.rend.light.omni.Apply(false) )
		rlis.Add( support.mirror.Render() )
		#rlis.Add( kri.rend.debug.MapLight(-1,at.scene.lights[0]) )
		
		win.core.anim = al = kri.ani.Scheduler()
		nvin = heli.nodes['gazelle-rotor']
		nheli = nvin.Parent
		dummy = nheli.Parent
		ncam = view.cam.node
		ncam.local.pos = dummy.local.pos + Vector3(3f,0f,3f)
		ncam.local.rot =\
			Quaternion.FromAxisAngle(Vector3.UnitY, Math.PI*0.3f)*\
			Quaternion.FromAxisAngle(Vector3.UnitZ, 0.5f*Math.PI)
		ncam.touch()
		al.add( ani.Vint(nvin) )
		al.add( ani.Control( win.Keyboard, nheli ))
		al.add( ani.CamFollow( ncam, dummy ))
		#al.add( ani.Turret(at.nodes['node-turtB_main'], nheli) )
		if 'Grass':
			man = level.scene.particles[0].owner
			man.behos.Add( BehAir(nheli) )
			man.init( corp.con )
			for pe in level.scene.particles:
				al.add( kri.ani.Particle(pe) )
			rlis.Add( support.hair.Bake(corp.con) )
			rlis.Add( support.hair.Draw(null) )
		win.Run(30.0,30.0)
