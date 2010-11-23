namespace frozen.ani

import System
import OpenTK
import OpenTK.Input


class Vint( kri.ani.IBase ):
	private final node	as kri.Node	= null
	public def constructor(n as kri.Node):
		node = n
	def kri.ani.IBase.onFrame(time as double) as uint:
		node.local.rot = Quaternion.FromAxisAngle(Vector3.UnitZ, 20.0*time)
		node.touch()
		return 0


class Control( kri.ani.Delta ):
	private final kb		as KeyboardDevice
	private final noHeli	as kri.Node	= null
	private final noDummy	as kri.Node	= null
	private roll = Vector2(0f,0f)
	private final rollSpeed	= 0.8f
	private final rollBack	= 0.4f
	private final moveSpeed = 3f
	private final limits	= (0.6f,0.3f,0.4f)
	
	public def constructor(kdev as KeyboardDevice, n as kri.Node):
		kb = kdev
		noHeli = n
		noDummy = n.Parent
		noDummy.local.scale = 0.1f
	protected override def onDelta(delta as double) as uint:
		# gather
		kr = Vector3.Zero
		if kb.Item[Key.A]:	kr.Y += 1f
		if kb.Item[Key.D]:	kr.Y -= 1f
		if kb.Item[Key.W]:	kr.X -= 1f
		if kb.Item[Key.S]:	kr.X += 1f
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
		if (sp.pos.Z < -10f and het<0f) or (sp.pos.Z>50f and het>0f):
			het = 0f
		qaxis = Vector3(X:Math.Sin(roll.X), Y:-Math.Sin(roll.Y), Z:het)
		noDummy.local.pos += Vector3.Transform(qaxis * (delta*moveSpeed), sp.rot)
		noDummy.touch()
		return 0


class CamFollow( kri.ani.Delta ):
	private final ncam	as kri.Node	= null
	private final nobj	as kri.Node	= null
	private final soff	as kri.Spatial
	private final speed = -4f
	public def constructor(nc as kri.Node, no as kri.Node):
		assert nc.Parent == no.Parent
		ncam,nobj = nc,no
		s0 = nobj.local
		s0.inverse()
		soff.combine( ncam.local, s0 )	//cam->object
	protected override def onDelta(delta as double) as uint:
		starg as kri.Spatial
		s1 = soff
		starg.combine( s1, nobj.local )
		s1 = ncam.local
		kf = Math.Exp( speed*delta )
		ncam.local.lerpDq( starg, s1, kf )
		ncam.touch()
		return 0


class Turret( kri.ani.Delta ):
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