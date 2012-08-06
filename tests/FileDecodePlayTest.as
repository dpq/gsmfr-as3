package {

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	/**
	 * @author Humanoid
	 */
	[SWF(backgroundColor="#000000", frameRate="60", width="640", height="480")]
	public class FileDecodePlayTest extends Sprite {

		private var bitmap: BitmapData;

		public function FileDecodePlayTest() {
			try {
				initStage();
				initView();
				initSound();
				initDecoder();
			} catch (error: *) {
				trace(error);
			}
		}

		private function initDecoder(): void {
		}

		private function initSound(): void {
		}

		private function initStage(): void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.showDefaultContextMenu = false;
			stage.stageFocusRect = false;
			stage.frameRate = 60;
		}

		private function initView(): void {
			addChild(new Bitmap(bitmap = new BitmapData(stage.stageWidth, 256, false, 0)));
		}

	}
}
