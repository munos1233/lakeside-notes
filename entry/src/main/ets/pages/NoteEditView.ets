import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Theme } from '../common/Theme';
import { CardFrame, GoldButton } from '../components/UiParts';
import { Note, localIso, newNoteId } from '../model/NoteTypes';
import { NoteStore } from '../model/NoteStore';

const DOMAIN: number = 0x4C4E;
const TITLE_LIMIT: number = 30;
const PHASE_LOADING: string = 'loading';
const PHASE_READY: string = 'ready';
const PHASE_FAILED: string = 'failed';
const CONTEXT_RETRY_LIMIT: number = 20;
const CONTEXT_RETRY_MS: number = 50;

@Component
export struct NoteEditView {
  @Prop noteId: string = '';
  @Prop @Watch('onLeaveRequest') leaveSeq: number = 0;
  @Prop pendingTab: number = 0;
  @State private title: string = '';
  @State private body: string = '';
  @State private pinned: boolean = false;
  @State private phase: string = PHASE_LOADING;
  @State private notice: string = '';
  @State private busy: boolean = false;
  private createdAt: string = '';
  private baseTitle: string = '';
  private baseBody: string = '';
  private basePinned: boolean = false;
  private appliedLeave: number = 0;
  private leaveQueued: boolean = false;
  private saveWaiting: boolean = false;
  private deleteWaiting: boolean = false;
  private alive: boolean = true;
  private loadTicket: number = 0;
  private contextTries: number = 0;
  private retryId: number = -1;
  onDone: () => void = () => {
  };
  onLeave: (next: number) => void = (next: number): void => {
    hilog.info(DOMAIN, 'edit', 'leave %{public}d', next);
  };

  aboutToAppear(): void {
    this.alive = true;
    this.contextTries = 0;
    if (this.noteId.length === 0) {
      this.title = '';
      this.body = '';
      this.pinned = false;
      this.createdAt = '';
      this.captureBase();
      this.phase = PHASE_READY;
      return;
    }
    this.phase = PHASE_LOADING;
    this.loadNote();
  }

  aboutToDisappear(): void {
    this.alive = false;
    this.loadTicket++;
    this.cancelRetry();
  }

  onLeaveRequest(): void {
    if (!this.alive || this.leaveSeq === 0 || this.leaveSeq === this.appliedLeave) {
      return;
    }
    this.appliedLeave = this.leaveSeq;
    this.tryLeave();
  }

  build() {
    Scroll() {
      Column() {
        if (this.phase === PHASE_FAILED) {
          Text('没读上来')
            .width('100%')
            .fontSize(16)
            .fontColor(Theme.muted)
            .margin({ bottom: 12 })
          GoldButton({
            label: '重试',
            canTap: !this.busy,
            onTap: (): void => {
              this.retryLoad();
            }
          })
        }

        if (this.phase === PHASE_READY) {
          CardFrame() {
            Column() {
              Row() {
                Text('标题')
                  .fontSize(12)
                  .fontColor(Theme.muted)
                  .layoutWeight(1)
                Text(this.title.length.toString() + '/' + TITLE_LIMIT.toString())
                  .fontSize(12)
                  .fontColor(Theme.gold)
              }
              .width('100%')

              TextInput({ text: this.title, placeholder: '标题' })
                .width('100%')
                .height(44)
                .maxLength(TITLE_LIMIT)
                .margin({ top: 6 })
                .fontSize(16)
                .fontColor(Theme.text)
                .placeholderColor(Theme.muted)
                .backgroundColor(Theme.page)
                .borderRadius(10)
                .padding({ left: 12, right: 12 })
                .enabled(!this.busy)
                .onChange((value: string) => {
                  if (this.busy) {
                    return;
                  }
                  this.title = this.limitTitle(value);
                  this.notice = '';
                })

              Text('正文')
                .width('100%')
                .fontSize(12)
                .fontColor(Theme.muted)
                .margin({ top: 12 })

              TextArea({ text: this.body, placeholder: '正文' })
                .width('100%')
                .height(180)
                .margin({ top: 6 })
                .fontSize(16)
                .fontColor(Theme.text)
                .placeholderColor(Theme.muted)
                .backgroundColor(Theme.page)
                .borderRadius(10)
                .enabled(!this.busy)
                .onChange((value: string) => {
                  if (this.busy) {
                    return;
                  }
                  this.body = value;
                  this.notice = '';
                })

              Row() {
                Text('置顶')
                  .fontSize(16)
                  .fontColor(Theme.text)
                  .layoutWeight(1)
                Toggle({ type: ToggleType.Switch, isOn: this.pinned })
                  .enabled(!this.busy)
                  .selectedColor(Theme.gold)
                  .onChange((isOn: boolean) => {
                    if (this.busy) {
                      return;
                    }
                    this.pinned = isOn;
                    this.notice = '';
                  })
              }
              .width('100%')
              .margin({ top: 12 })
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }

          if (this.notice.length > 0) {
            Text(this.notice)
              .width('100%')
              .fontSize(14)
              .fontColor(Theme.danger)
              .margin({ bottom: 12 })
          }

          GoldButton({
            label: '保存',
            canTap: !this.busy,
            onTap: (): void => {
              this.saveNote();
            }
          })
          .margin({ bottom: 12 })

          GoldButton({
            label: '删除',
            canTap: !this.busy,
            onTap: (): void => {
              this.askDelete();
            }
          })
        }
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.page)
    .align(Alignment.TopStart)
  }

  private captureBase(): void {
    this.baseTitle = this.title;
    this.baseBody = this.body;
    this.basePinned = this.pinned;
  }

  private dirty(): boolean {
    if (this.phase !== PHASE_READY) {
      return false;
    }
    return this.title !== this.baseTitle || this.body !== this.baseBody || this.pinned !== this.basePinned;
  }

  private limitTitle(value: string): string {
    if (value.length <= TITLE_LIMIT) {
      return value;
    }
    return value.substring(0, TITLE_LIMIT);
  }

  private tryLeave(): void {
    if (!this.alive) {
      return;
    }
    if (this.busy) {
      this.leaveQueued = true;
      return;
    }
    if (!this.dirty()) {
      this.onLeave(this.pendingTab);
      return;
    }
    this.getUIContext().getPromptAction().showDialog({
      message: '放弃未保存的修改？',
      buttons: [
        { text: '取消', color: Theme.muted },
        { text: '放弃', color: Theme.danger }
      ]
    }).then((result) => {
      if (!this.alive || result.index !== 1) {
        return;
      }
      this.onLeave(this.pendingTab);
    }).catch((err: Object) => {
      hilog.error(DOMAIN, 'edit', 'leave dialog %{public}s', JSON.stringify(err));
    });
  }

  private askDelete(): void {
    if (this.busy || this.phase !== PHASE_READY) {
      return;
    }
    this.getUIContext().getPromptAction().showDialog({
      message: '删除这条笔记？',
      buttons: [
        { text: '取消', color: Theme.muted },
        { text: '删除', color: Theme.danger }
      ]
    }).then((result) => {
      if (!this.alive || result.index !== 1) {
        return;
      }
      this.deleteNote();
    }).catch((err: Object) => {
      hilog.error(DOMAIN, 'edit', 'delete dialog %{public}s', JSON.stringify(err));
    });
  }

  private loadNote(): void {
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
    let targetId = this.noteId;
    NoteStore.load(ctx).then((notes: Note[]) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      let found: Note | undefined = undefined;
      for (let i = 0; i < notes.length; i++) {
        if (notes[i].id === targetId) {
          found = notes[i];
          break;
        }
      }
      if (found === undefined) {
        this.phase = PHASE_FAILED;
        return;
      }
      this.title = found.title;
      this.body = found.body;
      this.pinned = found.pinned;
      this.createdAt = found.createdAt;
      this.captureBase();
      this.phase = PHASE_READY;
    }).catch((err: Object) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      hilog.error(DOMAIN, 'edit', 'load %{public}s', JSON.stringify(err));
      this.phase = PHASE_FAILED;
    });
  }

  private retryLoad(): void {
    if (!this.alive || this.busy) {
      return;
    }
    if (this.noteId.length === 0) {
      this.phase = PHASE_READY;
      return;
    }
    this.notice = '';
    this.contextTries = 0;
    this.phase = PHASE_LOADING;
    this.loadNote();
  }

  private saveNote(): void {
    if (!this.alive || this.busy || this.phase !== PHASE_READY) {
      return;
    }
    this.busy = true;
    this.notice = '';
    this.saveWaiting = true;
    this.contextTries = 0;
    this.dispatchSave();
  }

  private dispatchSave(): void {
    if (!this.alive || !this.saveWaiting) {
      return;
    }
    let host = this.getUIContext().getHostContext();
    if (host === undefined) {
      this.scheduleRetry();
      return;
    }
    this.cancelRetry();
    this.contextTries = 0;
    this.saveWith(host as common.UIAbilityContext);
  }

  private saveWith(ctx: common.UIAbilityContext): void {
    let ticket = ++this.loadTicket;
    let targetId = this.noteId;
    let title = this.limitTitle(this.title);
    let body = this.body;
    let pinned = this.pinned;
    let createdAt = this.createdAt;
    NoteStore.load(ctx).then((notes: Note[]) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return Promise.resolve(false);
      }
      let next: Note[] = [];
      let used: string[] = [];
      let found = false;
      for (let i = 0; i < notes.length; i++) {
        used.push(notes[i].id);
        if (targetId.length > 0 && notes[i].id === targetId) {
          found = true;
        } else {
          next.push(notes[i]);
        }
      }
      if (targetId.length > 0 && !found) {
        return Promise.resolve(false);
      }
      let draft = new Note();
      draft.title = title;
      draft.body = body;
      draft.pinned = pinned;
      let stamp = localIso(new Date());
      if (targetId.length === 0) {
        draft.id = newNoteId(used);
        draft.createdAt = stamp;
        draft.updatedAt = stamp;
      } else {
        draft.id = targetId;
        draft.createdAt = createdAt;
        draft.updatedAt = stamp;
      }
      next.push(draft);
      return NoteStore.save(ctx, next);
    }).then((saved: boolean) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      this.busy = false;
      this.saveWaiting = false;
      if (!saved) {
        this.notice = '没保存上';
        this.leaveQueued = false;
        return;
      }
      this.baseTitle = title;
      this.baseBody = body;
      this.basePinned = pinned;
      if (this.title !== title || this.body !== body || this.pinned !== pinned) {
        this.flushQueuedLeave();
        return;
      }
      this.leaveQueued = false;
      this.onDone();
    }).catch((err: Object) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      hilog.error(DOMAIN, 'edit', 'save %{public}s', JSON.stringify(err));
      this.busy = false;
      this.saveWaiting = false;
      this.notice = '没保存上';
      this.leaveQueued = false;
    });
  }

  private deleteNote(): void {
    if (!this.alive || this.busy || this.phase !== PHASE_READY) {
      return;
    }
    if (this.noteId.length === 0) {
      this.captureBase();
      this.onDone();
      return;
    }
    this.busy = true;
    this.notice = '';
    this.deleteWaiting = true;
    this.contextTries = 0;
    this.dispatchDelete();
  }

  private dispatchDelete(): void {
    if (!this.alive || !this.deleteWaiting) {
      return;
    }
    let host = this.getUIContext().getHostContext();
    if (host === undefined) {
      this.scheduleRetry();
      return;
    }
    this.cancelRetry();
    this.contextTries = 0;
    this.deleteWith(host as common.UIAbilityContext);
  }

  private deleteWith(ctx: common.UIAbilityContext): void {
    let ticket = ++this.loadTicket;
    let targetId = this.noteId;
    NoteStore.load(ctx).then((notes: Note[]) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return Promise.resolve(false);
      }
      let next: Note[] = [];
      let found = false;
      for (let i = 0; i < notes.length; i++) {
        if (notes[i].id === targetId) {
          found = true;
          continue;
        }
        next.push(notes[i]);
      }
      if (!found) {
        return Promise.resolve(false);
      }
      return NoteStore.save(ctx, next);
    }).then((saved: boolean) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      this.busy = false;
      this.deleteWaiting = false;
      if (!saved) {
        this.notice = '没保存上';
        this.leaveQueued = false;
        return;
      }
      this.captureBase();
      this.leaveQueued = false;
      this.onDone();
    }).catch((err: Object) => {
      if (!this.alive || ticket !== this.loadTicket) {
        return;
      }
      hilog.error(DOMAIN, 'edit', 'delete %{public}s', JSON.stringify(err));
      this.busy = false;
      this.deleteWaiting = false;
      this.notice = '没保存上';
      this.leaveQueued = false;
    });
  }

  private flushQueuedLeave(): void {
    if (!this.leaveQueued) {
      return;
    }
    this.leaveQueued = false;
    this.tryLeave();
  }

  private scheduleRetry(): void {
    if (!this.alive) {
      return;
    }
    if (this.contextTries >= CONTEXT_RETRY_LIMIT) {
      this.failWaitingAction();
      return;
    }
    this.contextTries++;
    this.cancelRetry();
    this.retryId = setTimeout(() => {
      this.retryId = -1;
      if (this.saveWaiting) {
        this.dispatchSave();
        return;
      }
      if (this.deleteWaiting) {
        this.dispatchDelete();
        return;
      }
      this.loadNote();
    }, CONTEXT_RETRY_MS);
  }

  private failWaitingAction(): void {
    if (this.saveWaiting || this.deleteWaiting) {
      this.saveWaiting = false;
      this.deleteWaiting = false;
      this.busy = false;
      this.leaveQueued = false;
      this.notice = '没保存上';
      return;
    }
    if (this.phase === PHASE_LOADING) {
      this.phase = PHASE_FAILED;
    }
  }

  private cancelRetry(): void {
    if (this.retryId < 0) {
      return;
    }
    clearTimeout(this.retryId);
    this.retryId = -1;
  }
}
