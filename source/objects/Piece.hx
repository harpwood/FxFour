package objects;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;

class Piece extends FlxSprite
{
	public function new(player:Int, ?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset)
	{
		super(X, Y, SimpleGraphic);

		var col:String = player == 1 ? "red" : "yellow";
		loadGraphic("assets/images/" + col + ".png", false, 50, 50);
	}
}
