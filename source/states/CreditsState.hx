package states;

import flixel.util.FlxStringUtil;
import progress.Collected;
import flixel.math.FlxMath;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxBitmapText;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIState;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxefmod.flixel.FmodFlxUtilities;
import config.Configure;
import helpers.UiHelpers;
import misc.FlxTextFactory;

using states.FlxStateExt;

class CreditsState extends FlxUIState {
	var _allCreditElements:Array<FlxSprite>;

	// var _btnMainMenu:FlxButton;

	var _txtCreditsTitle:FlxBitmapText;
	var _txtThankYou:FlxBitmapText;
	var _txtRole:Array<FlxBitmapText>;
	var _txtCreator:Array<FlxBitmapText>;

	// Quick appearance variables
	private var backgroundColor = FlxColor.BLACK;

	static inline var entryLeftMargin = 12;
	static inline var entryRightMargin = 12;
	static inline var entryVerticalSpacing = 25;

	var toolingImages = [
		AssetPaths.FLStudioLogo__png,
		AssetPaths.FmodLogoWhite__png,
		AssetPaths.HaxeFlixelLogo__png,
		AssetPaths.pyxel_edit__png
	];

	override public function create():Void {
		super.create();
		bgColor = backgroundColor;
		camera.pixelPerfectRender = true;

		Collected.addTime(PlayState.ME.levelTime);

		// Credits

		_allCreditElements = new Array<FlxSprite>();

		var creditTitleX = FlxG.width / 4;
		creditTitleX -= creditTitleX % 4;
		_txtCreditsTitle = FlxTextFactory.make("Credits", creditTitleX, FlxG.height / 2, 36, FlxTextAlign.LEFT);
		center(_txtCreditsTitle);
		add(_txtCreditsTitle);

		_txtRole = new Array<FlxBitmapText>();
		_txtCreator = new Array<FlxBitmapText>();

		_allCreditElements.push(_txtCreditsTitle);

		for (entry in Configure.getCredits()) {
			AddSectionToCreditsTextArrays(entry.sectionName, entry.names, _txtRole, _txtCreator);
		}

		var creditsVerticalOffset = FlxG.height;

		for (flxText in _txtRole) {
			flxText.setPosition(entryLeftMargin, creditsVerticalOffset);
			creditsVerticalOffset += entryVerticalSpacing * 2;
		}

		creditsVerticalOffset = FlxG.height + entryVerticalSpacing + 5;

		for (flxText in _txtCreator) {
			var xPos = FlxG.width - flxText.width - entryRightMargin;
			xPos -= xPos % 4;
			flxText.setPosition(xPos, creditsVerticalOffset);
			creditsVerticalOffset += entryVerticalSpacing * 2;
		}

		for (toolImg in toolingImages) {
			var display = new FlxSprite();
			display.loadGraphic(toolImg);
			// scale them to be about 1/2 of the width of the screen
			var scale = (FlxG.width / 2 - 10) / display.height;
			if (display.width * scale > FlxG.width + 10) {
				// in case that's too wide, adjust accordingly with a bit of a margin
				scale = (FlxG.width - 10) / display.width;
			}
			display.scale.set(scale, scale);
			display.updateHitbox();
			display.setPosition(0, creditsVerticalOffset);
			center(display);
			add(display);
			creditsVerticalOffset += Math.ceil(display.height) + entryVerticalSpacing;
			_allCreditElements.push(display);
		}

		_txtThankYou = FlxTextFactory.make("Thank you!", FlxG.width / 2, creditsVerticalOffset + FlxG.height / 2, 36, FlxTextAlign.CENTER);
		_txtThankYou.alignment = FlxTextAlign.CENTER;
		center(_txtThankYou);
		add(_txtThankYou);
		_allCreditElements.push(_txtThankYou);

		var _txtTime = FlxTextFactory.make('Time: ${getFormattedTime()}', FlxG.width / 2, creditsVerticalOffset + FlxG.height * .75, 36, FlxTextAlign.CENTER);
		_txtTime.color = FlxColor.GRAY;
		center(_txtTime);
		_txtTime.x -= _txtTime.x % 4;
		add(_txtTime);
		_allCreditElements.push(_txtTime);

		var _txtDeath = FlxTextFactory.make('Deaths: ${Collected.getDeathCount()}', FlxG.width / 2, _txtTime.y + 40, 36, FlxTextAlign.CENTER);
		_txtDeath.color = FlxColor.GRAY;
		center(_txtDeath);
		_txtDeath.x -= _txtDeath.x % 4;
		add(_txtDeath);
		_allCreditElements.push(_txtDeath);

		Collected.gameComplete();
	}

	private function getFormattedTime():String {
		var rawTime = Collected.getTime();
		return FlxStringUtil.formatTime(rawTime, true);
	}

	private function AddSectionToCreditsTextArrays(role:String, creators:Array<String>, finalRoleArray:Array<FlxBitmapText>,
			finalCreatorsArray:Array<FlxBitmapText>) {
		var roleText = FlxTextFactory.make(role, 0, 0, 36, LEFT);
		add(roleText);
		finalRoleArray.push(roleText);
		_allCreditElements.push(roleText);

		if (finalCreatorsArray.length != 0) {
			finalCreatorsArray.push(new FlxBitmapText(""));
		}

		for (creator in creators) {
			// Make an offset entry for the roles array
			finalRoleArray.push(FlxTextFactory.make(" ", 0, 0, 40));

			var creatorText = FlxTextFactory.make(creator, 0, 0, 36, FlxTextAlign.RIGHT);
			add(creatorText);
			finalCreatorsArray.push(creatorText);
			_allCreditElements.push(creatorText);
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		// Stop scrolling when "Thank You" text is in the center of the screen
		if (_txtThankYou.y + _txtThankYou.height / 2 < FlxG.height / 2) {
			return;
		}

		for (element in _allCreditElements) {
			if (FlxG.keys.pressed.SPACE || FlxG.mouse.pressed) {
				element.y -= FlxG.height * elapsed;
			} else {
				element.y -= FlxG.height / 4 * elapsed;
			}
		}
	}

	private function center(o:FlxObject) {
		o.x = (FlxG.width - o.width) / 2;
	}

	function clickMainMenu():Void {
		FmodFlxUtilities.TransitionToState(new MainMenuState());
	}

	override public function onFocusLost() {
		super.onFocusLost();
		this.handleFocusLost();
	}

	override public function onFocus() {
		super.onFocus();
		this.handleFocus();
	}
}
