namespace frozen

import System
import OpenTK
import OpenTK.Input


class AniVint( kri.ani.IBase ):
	private final node	as kri.Node	= null
	public def constructor(n as kri.Node):
		node = n
	def kri.ani.IBase.onFrame(time as double) as uint:
		node.local.rot = Quaternion.FromAxisAngle(Vector3.UnitZ, 10.0*time)
		node.touch()
		return 0


class AniControl( kri.ani.Delta ):
	private final noHeli	as kri.Node	= null
	private final noDummy	as kri.Node	= null
	private roll = Vector2(0f,0f)
	private final rollSpeed	= 0.8f
	private final rollBack	= 0.4f
	private final moveSpeed = 100.0f
	private final limits	= (0.6f,0.3f,0.4f)
	public def constructor(n as kri.Node):
		noHeli = n
		noDummy = n.Parent
	protected override def onDelta(delta as double) as uint:
		# gather
		kr = Vector3(0f,0f,0f)
		kb = kri.Ant.Inst.Keyboard
		if kb.Item[Key.W]:	kr.X += 1f
		if kb.Item[Key.S]:	kr.X -= 1f
		if kb.Item[Key.A]:	kr.Y -= 1f
		if kb.Item[Key.D]:	kr.Y += 1f
		if kb.Item[Key.Q]:	kr.Z -= 1f
		if kb.Item[Key.E]:	kr.Z += 1f
		# roll calc
		vs = Vector2( Math.Sign(roll.X), Math.Sign(roll.Y) )
		vs = roll + delta*rollSpeed*kr.Xy - delta*rollBack*vs
		roll = Vector2.Clamp(vs, Vector2(-limits[1],-limits[2]), Vector2(limits[0],limits[2]) )
		# roll apply
		noHeli.local.rot =\
			Quaternion.FromAxisAngle(Vector3.UnitY, roll.X)*\
			Quaternion.FromAxisAngle(Vector3.UnitX, roll.Y)
		noHeli.touch()
		# move
		sp = noDummy.local
		het = 0.1f * kr.Z
		if (sp.pos.Z < 10f and het<0f) or (sp.pos.Z>50f and het>0f):
			het = 0f
		qaxis = Vector3(X:Math.Sin(roll.X), Y:-Math.Sin(roll.Y), Z:het)
		noDummy.local.pos += Vector3.Transform(qaxis * (delta*moveSpeed), sp.rot)
		noDummy.touch()
		return 0


class AniCamFollow( kri.ani.Delta ):
	private final ncam	as kri.Node	= null
	private final nobj	as kri.Node	= null
	private final soff	as kri.Spatial
	private final speed = -4f
	public def constructor(*n as (kri.Node)):
		ncam,nobj = n[0],n[1]
		(s0 = nobj.local).inverse()
		soff.combine( ncam.local, s0 )
	protected override def onDelta(delta as double) as uint:
		starg as kri.Spatial
		s1 = soff
		starg.combine( s1, nobj.local )
		s1 = ncam.local
		kf = Math.Exp( speed*delta )
		ncam.local.lerpDq( starg, s1, kf )
		ncam.touch()
		return 0


class AniTurret( kri.ani.Delta ):
	private final ntur	as kri.Node	= null
	private final nobj	as kri.Node	= null
	private final speed = (0.1f,0.1f)
	private ang	= (0f,0f)	#z,x
	public def constructor(*n as (kri.Node)):
		ntur,nobj = n[0],n[1]
	protected override def onDelta(delta as double) as uint:
		sturret = ntur.Parent.World
		sturret.inverse()
		pos = nobj.World.pos
		pos = sturret.byPoint(pos)
		proj = Vector3(Xy: pos.Xy, Z:0.0)
		vax = Vector3.UnitY
		qz as Quaternion
		qz.Xyz = Vector3.Cross(vax,proj)
		qz.W = proj.LengthFast + Vector3.Dot(vax,proj)
		qz.Normalize()
		ntur.local.rot = qz
		ntur.touch()
		return 0


[STAThread]
def Main(argv as (string)):
	using ant = kri.Ant(1,400,300,0):
		view = kri.ViewScreen(16,0)
		rchain = kri.rend.Chain()
		ant.views.Add( view )
		ant.VSync = VSyncMode.On
		
		ln = kri.load.Native()
		at = ln.read('res/object.scene')
		level = ln.read('res/level-1.scene')
		turret = ln.read('res/turret.scene')
		
		view.scene = at.scene
		view.scene.entities.AddRange( level.scene.entities )
		view.scene.entities.AddRange( turret.scene.entities )
		view.cam = at.scene.cameras[0]
		view.scene.lights[0].makeDirectional(100f)
		
		licon = kri.rend.light.Context(1,10)
		licon.setExpo(120f, 0.5f)
		view.ren = rchain
		rlis = rchain.renders
		
		rlis.Add( kri.kit.skin.Update(true) )
		rlis.Add( kri.rend.EarlyZ() )
		rlis.Add( kri.rend.Emission() )
		rlis.Add( kri.rend.light.Fill(licon) )
		rlis.Add( kri.rend.light.Apply(licon) )
		#rlis.Add( kri.rend.debug.MapLight(-1,at.scene.lights[0]) )
		
		ant.anim = al = kri.ani.Scheduler()
		nvin = at.nodes['Vint']
		nheli = nvin.Parent
		ncam = at.nodes['FollowCam']
		al.add( AniVint(nvin) )
		al.add( AniControl(nheli) )
		al.add( AniCamFollow(ncam, nheli.Parent) )
		al.add( AniTurret(turret.nodes['Cube.001'], nheli) )
		ant.Run(30.0,30.0)
