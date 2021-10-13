package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import objects.Piece;

// TODO: comments
class PlayState extends FlxState
{
	static inline final SLOT_SIZE = 60;
	static inline final H_OFFSET = 70;
	static inline final V_OFFSET = 15;

	// debug vars
	private var canDebug:Bool = false;
	private var statusText:FlxText;
	private var square:FlxSprite;

	private var boardFront:FlxSprite;
	private var boardData:Array<Array<Int>>;
	private var pieces:FlxGroup = new FlxGroup(42);
	private var currentRow:Int;
	private var currentCol:Int;

	private var piece:Piece;
	private var currentPlayer:Int = 0;
	private var canPlay:Bool = false;
	private var winText:String = "";

	override public function create()
	{
		super.create();

		init();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// display info via status text
		if (winText == "")
			statusText.text = currentPlayer == 1 ? "Player's turn" : "Computer's turn" // "Player: " + Std.string(currentPlayer) + " Column: " + Std.string(currentCol + 1);
		else
			statusText.text = winText;
		if (canDebug)
			statusText.text += "\n" + Std.string(FlxG.mouse.getWorldPosition());

		if (canPlay)
		{
			movePiece();
			var validMoves = findValidMoves();
			if ((FlxG.mouse.justPressed) && (validMoves.indexOf(currentCol) != -1))
				dropPiece();
		}

		if (FlxG.keys.justPressed.R)
			FlxG.resetGame();
	}

	private function init()
	{
		bgColor = FlxColor.WHITE;

		// add semi transparent square for status text
		square = new FlxSprite();
		square.makeGraphic(FlxG.width, 35, FlxColor.WHITE);
		square.x = 0;
		square.y = 0;
		square.alpha = .75;
		add(square);

		// add the status text
		statusText = new FlxText(0, 0, FlxG.width, "Hello from HaxeFlixel!", 24);
		statusText.color = FlxColor.RED;
		statusText.alignment = FlxTextAlign.CENTER;
		add(statusText);

		// place the back of the board
		var boardBack:FlxSprite = new FlxSprite();
		boardBack.loadGraphic(AssetPaths.BoardBack__png, false);
		boardBack.x = (FlxG.width - boardBack.width) / 2;
		boardBack.y = FlxG.height - boardBack.height - 10;
		add(boardBack);

		// place the pieces sprites group
		add(pieces);

		// place the front of the board
		boardFront = new FlxSprite();
		boardFront.loadGraphic(AssetPaths.BoardFront__png, false);
		boardFront.x = (FlxG.width - boardFront.width) / 2;
		boardFront.y = FlxG.height - boardFront.height - 10;
		add(boardFront);

		// create the board data
		boardData = new Array();
		for (i in 0...6)
		{
			boardData[i] = new Array();
			for (j in 0...7)
			{
				boardData[i].push(0);
			}
		}
		// canDebug = true;
		nextTurn();
	}

	private function nextTurn()
	{
		if (currentPlayer == 1)
		{
			currentPlayer = 2;
		}
		else
		{
			currentPlayer = 1;
		}

		piece = new Piece(currentPlayer);
		piece.x = -piece.width;
		piece.y = -piece.health;
		pieces.add(piece);

		if (currentPlayer == 1)
		{
			canPlay = true;
		}
		else
		{
			computerTurn();
		}
	}

	private function computerTurn()
	{
		var possibleMoves:Array<Int> = basicAI();
		// improved AI is outside the scope of this prototype
		var cpuMove:Int = Math.floor(Math.random() * possibleMoves.length);
		trace("possible moves: " + possibleMoves);
		currentCol = possibleMoves[cpuMove];
		piece.x = boardFront.x + H_OFFSET + SLOT_SIZE * currentCol;

		dropPiece();
	}

	private function basicAI():Array<Int>
	{
		var possibleMoves:Array<Int> = findValidMoves();
		var aiMoves:Array<Int> = new Array();
		var defensingMove:Int;
		var bestDefensingMove:Int = 0;
		var jj:Int = 0;

		for (i in 0...possibleMoves.length)
		{
			for (j in 0...6)
			{
				jj = j;
				if (boardData[j][possibleMoves[i]] != 0)
				{
					break;
				}
			}
			boardData[jj - 1][possibleMoves[i]] = 1;
			defensingMove = getAdjustmentSlot(jj - 1, possibleMoves[i], 0, 1) + getAdjustmentSlot(jj - 1, possibleMoves[i], 0, -1);
			defensingMove = Std.int(Math.max(defensingMove, getAdjustmentSlot(jj - 1, possibleMoves[i], 1, 0)));
			defensingMove = Std.int(Math.max(defensingMove,
				getAdjustmentSlot(jj - 1, possibleMoves[i], -1, 1) + getAdjustmentSlot(jj - 1, possibleMoves[i], 1, -1)));
			defensingMove = Std.int(Math.max(defensingMove,
				getAdjustmentSlot(jj - 1, possibleMoves[i], 1, 1) + getAdjustmentSlot(jj - 1, possibleMoves[i], -1, -1)));
			if (defensingMove >= bestDefensingMove)
			{
				if (defensingMove > bestDefensingMove)
				{
					bestDefensingMove = defensingMove;
					aiMoves = new Array();
				}
				aiMoves.push(possibleMoves[i]);
			}
			boardData[jj - 1][possibleMoves[i]] = 0;
		}
		return aiMoves;
	}

	private function movePiece()
	{
		currentCol = Math.floor((FlxG.mouse.x - Std.int(boardFront.x + H_OFFSET)) / SLOT_SIZE);
		if (currentCol < 0)
			currentCol = 0;

		if (currentCol > 6)
			currentCol = 6;

		piece.x = boardFront.x + H_OFFSET + SLOT_SIZE * currentCol;
		piece.y = boardFront.y + V_OFFSET - SLOT_SIZE;
	}

	private function dropPiece():Void
	{
		currentRow = findTopFreeCell(currentCol);

		canPlay = false;

		var tweenType = FlxTweenType.ONESHOT;
		var options:TweenOptions = {onComplete: onDropCompleted.bind(_), ease: FlxEase.linear, type: tweenType}

		FlxTween.tween(piece, {y: boardFront.y + 10 + currentRow * SLOT_SIZE}, .25, options);
	}

	private function onDropCompleted(tween:FlxTween)
	{
		haxe.Timer.delay(function()
		{
			checkForWin();
		}, 100);
	}

	private function checkForWin()
	{
		if (floodFill(currentRow, currentCol))
		{
			winText = currentPlayer == 1 ? "Player won" : "Computer won"; // "Player " + Std.string(currentPlayer) + " wins!!!";
			trace(winText);
			// trace("Player " + currentPlayer + " wins!!!");
		}
		else
		{
			nextTurn();
		}
	}

	public function findValidMoves():Array<Int>
	{
		var validMoves = new Array();
		for (i in 0...7)
		{
			if (boardData[0][i] == 0)
			{
				validMoves.push(i);
			}
		}
		return validMoves;
	}

	public function findTopFreeCell(column:Int):Int
	{
		var j:Int = 0;
		for (i in 0...7)
		{
			j = i;
			// trace("j: " + j);
			if (i < boardData.length)
				if (boardData[i][column] != 0)
					break;
		}

		// udate the doard data
		boardData[j - 1][column] = currentPlayer;
		// trace(boardData);
		return j - 1;
	}

	private function getSlotValueFrom(row:Int, col:Int):Int
	{
		if (row < 0 || row >= boardData.length || col >= boardData[row].length)
			return -1;
		else
			return boardData[row][col];
	}

	private function getAdjustmentSlot(row:Int, col:Int, nextRow:Int, nextCol:Int):Int
	{
		if (getSlotValueFrom(row, col) == getSlotValueFrom(row + nextRow, col + nextCol))
			return 1 + getAdjustmentSlot(row + nextRow, col + nextCol, nextRow, nextCol);
		else
			return 0;
	}

	public function floodFill(row:Int, col:Int):Bool
	{
		if (getAdjustmentSlot(row, col, 0, 1) + getAdjustmentSlot(row, col, 0, -1) > 2)
			return true;
		else
		{
			if (getAdjustmentSlot(row, col, 1, 0) > 2)
				return true;
			else
			{
				if (getAdjustmentSlot(row, col, -1, 1) + getAdjustmentSlot(row, col, 1, -1) > 2)
					return true;
				else
				{
					if (getAdjustmentSlot(row, col, 1, 1) + getAdjustmentSlot(row, col, -1, -1) > 2)
						return true;
					else
						return false;
				}
			}
		}
	}
}
