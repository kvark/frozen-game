namespace frozen

public class BehAir( kri.part.Behavior ):
	public final pNode	= kri.lib.par.spa.Linked('s_heli')
	public def constructor(node as kri.Node):
		super('text/beh/grass_v')
		pNode.activate(node)
	public override def link(d as kri.shade.par.Dict) as void:
		(pNode as kri.meta.IBase).link(d)
