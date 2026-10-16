import { common } from '@kit.AbilityKit';
import deviceInfo from '@ohos.deviceInfo';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Theme } from '../common/Theme';
import { CardFrame, InfoLine } from '../components/UiParts';
import { Note } from '../model/NoteTypes';
import { NoteQuery } from '../model/NoteQuery';
import { NoteStore } from '../model/NoteStore';

const DOMAIN: number = 0x4C4E;
const RELATIVE_PATH: string = 'files/lakeside-notes.json';
const PHASE_LOADING: string = 'loading';
const PHASE_READY: string = 'ready';
const PHASE_FAILED: string = 'failed';
const CONTEXT_RETRY_LIMIT: number = 20;
const CONTEXT_RETRY_MS: number = 50;

@Component
export struct SelfCheckView {
  @Prop @Watch('onPageShow') pageShowSeq: number = 0;
  @State private loaded: Note[] = [];
  @State private phase: string = PHASE_LOADING;
  private alive: boolean = true;
  private loadTicket: number = 0;
  private contextTries: number = 0;
  private retryId: number = -1;

  aboutToAppear(): void {
    this.alive = true;
    this.contextTries = 0;
    this.applySnapshot();
    this.reload();
  }

  aboutToDisappear(): void {
    this.alive = false;
    this.loadTicket++;
    this.cancelRetry();
  }

  onPageShow(): void {
    this.contextTries = 0;
    this.applySnapshot();
    this.reload();
  }

  build() {
    Scroll() {
      Column() {
        CardFrame() {
          Column() {
            Text('笔记总数')
              .width('100%')
              .fontSize(12)
              .fontColor(Theme.muted)
            Text(this.countText())
              .width('100%')
              .fontSize(16)
              .fontColor(Theme.text)
              .margin({ top: 2, bottom: 10 })
            InfoLine({ label: '存放路径', value: RELATIVE_PATH })
            Text('最近更新')
              .width('100%')
              .fontSize(12)
              .fontColor(Theme.muted)
            Text(this.updatedText())
              .width('100%')
              .fontSize(16)
              .fontColor(Theme.text)
              .margin({ top: 2 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }

        CardFrame() {
          Column() {
            Text('系统版本')
              .width('100%')
              .fontSize(12)
              .fontColor(Theme.muted)
            Text(this.systemName())
              .width('100%')
              .fontSize(16)
              .fontColor(Theme.text)
              .margin({ top: 2 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.TopStart)
    .backgroundColor(Theme.page)
  }

  private countText(): string {
    if (this.phase === PHASE_FAILED) {
      return '没读上来';
    }
    if (this.phase !== PHASE_READY) {
      return '';
    }
    return NoteStore.count(this.loaded).toString();
  }

  private updatedText(): string {
    if (this.phase !== PHASE_READY) {
      return '';
    }
    return NoteQuery.latestUpdatedAt(this.loaded);
  }

  private systemName(): string {
    return deviceInfo.osFullName;
  }

  private applySnapshot(): void {
    if (!this.alive) {
      return;
    }
    let host = this.getUIContext().getHostContext();
    if (host === undefined) {
      return;
    }
    this.loaded = NoteStore.readCurrent(host as common.UIAbilityContext);
    this.phase = PHASE_READY;
  }

  private reload(): void {
    if (!this.alive) {
      return;
    }
    let host = this.getUIContext().getHostContext();
    if (host === undefined) {
      this.scheduleRetry();
      return;
    }
    this.cancelRetry();
    this.contextTries = 0;
    let ctx = host as common.UIAbilityContext;
    let ticket = ++this.loadTicket;
    NoteStore.load(ctx).then((loaded: Note[]) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      this.loaded = loaded;
      this.phase = PHASE_READY;
    }).catch((err: Object) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      hilog.error(DOMAIN, 'check', 'load %{public}s', JSON.stringify(err));
      this.phase = PHASE_FAILED;
    });
  }

  private scheduleRetry(): void {
    if (!this.alive) {
      return;
    }
    if (this.contextTries >= CONTEXT_RETRY_LIMIT) {
      this.phase = PHASE_FAILED;
      return;
    }
    this.contextTries++;
    this.cancelRetry();
    this.retryId = setTimeout(() => {
      this.retryId = -1;
      this.reload();
    }, CONTEXT_RETRY_MS);
  }

  private cancelRetry(): void {
    if (this.retryId < 0) {
      return;
    }
    clearTimeout(this.retryId);
    this.retryId = -1;
  }
}
