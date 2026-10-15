import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { Theme } from '../common/Theme';
import { NoteStore } from '../model/NoteStore';

const DOMAIN: number = 0x4C4E;
const TAG: string = 'LakesideNotes';

export default class EntryAbility extends UIAbility {
  private seedReady: Promise<void> = Promise.resolve();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    let bundleName = this.context.applicationInfo.name;
    if (typeof want.bundleName === 'string' && want.bundleName.length > 0) {
      bundleName = want.bundleName;
    }
    hilog.info(DOMAIN, TAG, 'onCreate %{public}s/%{public}s', bundleName,
      launchParam.launchReason.toString());
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'colorMode %{public}s', JSON.stringify(err));
    }
    this.seedReady = NoteStore.seedIfNeeded(this.context).then(() => {
      hilog.info(DOMAIN, TAG, 'seed ready');
    }).catch((err: Object) => {
      hilog.error(DOMAIN, TAG, 'seed %{public}s', JSON.stringify(err));
    });
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate');
    this.paintWindow(windowStage);
    this.seedReady.then(() => {
      windowStage.loadContent('pages/Index', (err) => {
        if (err && err.code) {
          hilog.error(DOMAIN, TAG, 'loadContent %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, TAG, 'loadContent ok');
      });
    });
  }

  private paintWindow(windowStage: window.WindowStage): void {
    let color = '#FF0E2244';
    if (Theme.page.length === 7 && Theme.page.startsWith('#')) {
      color = '#FF' + Theme.page.substring(1);
    }
    windowStage.getMainWindow().then((win: window.Window) => {
      win.setWindowBackgroundColor(color);
    }).catch((err: Error) => {
      hilog.error(DOMAIN, TAG, 'window %{public}s', JSON.stringify(err));
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');
  }
}
